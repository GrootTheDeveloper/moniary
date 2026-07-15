import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/supabase/app_exception.dart';
import '../../../core/supabase/supabase_providers.dart';
import '../../../shared/utils/app_logger.dart';
import '../domain/profile_update_result.dart';
import '../domain/user_profile.dart';

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return ProfileRepository(ref.watch(supabaseClientProvider));
});

class ProfileRepository {
  ProfileRepository(this._client);

  final SupabaseClient _client;

  String get _userId {
    final uid = _client.auth.currentSession?.user.id;
    if (uid == null) {
      throw const AppException('User not logged in', code: 'AUTH_REQUIRED');
    }
    return uid;
  }

  Future<UserProfile?> fetchCurrentProfile() async {
    try {
      final uid = _userId;

      final row = await _client
          .from('profiles')
          .select()
          .eq('id', uid)
          .maybeSingle();

      if (row == null) {
        // Fallback: If profile record hasn't been created yet, attempt to initialize it
        try {
          await _client.rpc('initialize_user');
          final retryRow = await _client
              .from('profiles')
              .select()
              .eq('id', uid)
              .maybeSingle();
          if (retryRow != null) {
            return await _profileWithConfirmedAuthEmail(retryRow);
          }
        } catch (e, st) {
          AppLogger.error('Failed to auto-initialize profile', e, st);
        }
        return null;
      }
      return await _profileWithConfirmedAuthEmail(row);
    } on PostgrestException catch (e, st) {
      AppLogger.error('Lỗi cơ sở dữ liệu', e, st);
      throw AppException(e.message, code: e.code);
    } catch (e, st) {
      if (e is AppException) rethrow;
      AppLogger.error('Lỗi kết nối', e, st);
      throw const AppException('errorConnection');
    }
  }

  Future<ProfileUpdateResult> upsertProfile({
    required String fullName,
    required String username,
    required String timezone,
    String? email,
    String? avatarImagePath,
  }) async {
    String? uploadedAvatarPath;
    var createdAvatarObject = false;
    var profilePersisted = false;

    try {
      final uid = _userId;
      final currentUser = _client.auth.currentUser;
      if (currentUser == null) {
        throw const AppException('User not logged in', code: 'AUTH_REQUIRED');
      }

      final requestedEmail = _normalizeEmail(email);
      var confirmedEmail = _normalizeEmail(currentUser.email);
      String? pendingEmail;
      final emailChangeRequested =
          requestedEmail != null &&
          requestedEmail.toLowerCase() != confirmedEmail?.toLowerCase();

      if (emailChangeRequested && currentUser.isAnonymous) {
        throw const AppException(
          'Anonymous accounts must be linked before changing email',
          code: 'PROFILE_EMAIL_LINK_REQUIRED',
        );
      }

      String? previousAvatarPath;
      if (avatarImagePath != null) {
        final previousRow = await _client
            .from('profiles')
            .select('avatar_url')
            .eq('id', uid)
            .maybeSingle();
        previousAvatarPath = previousRow?['avatar_url'] as String?;
        uploadedAvatarPath = await _uploadAvatarImage(
          uid: uid,
          imagePath: avatarImagePath,
        );
        createdAvatarObject = _isLocalImagePath(avatarImagePath);
      }

      final values = <String, dynamic>{
        'id': uid,
        'full_name': fullName,
        'username': username,
        'timezone': timezone,
      };
      if (confirmedEmail != null) values['email'] = confirmedEmail;
      if (uploadedAvatarPath != null) {
        values['avatar_url'] = uploadedAvatarPath;
      }

      var persistedRow = await _client
          .from('profiles')
          .upsert(values)
          .select()
          .single();
      profilePersisted = true;

      var authMetadataSynced = false;
      try {
        final authMeta = <String, dynamic>{
          'full_name': fullName,
          'username': username,
        };
        if (uploadedAvatarPath != null) {
          authMeta['avatar_url'] = uploadedAvatarPath;
        }
        await _client.auth.updateUser(UserAttributes(data: authMeta));
        authMetadataSynced = true;
      } catch (e, st) {
        AppLogger.error('Failed to sync auth metadata (non-blocking)', e, st);
      }

      if (authMetadataSynced &&
          uploadedAvatarPath != null &&
          previousAvatarPath != uploadedAvatarPath) {
        await _removeOwnedAvatar(uid: uid, avatarPath: previousAvatarPath);
      }

      if (emailChangeRequested) {
        final response = await _client.auth.updateUser(
          UserAttributes(email: requestedEmail),
          emailRedirectTo: kIsWeb
              ? null
              : AppConstants.supabaseLoginCallbackUrl,
        );
        final updatedUser = response.user;
        if (updatedUser == null) {
          throw const AppException(
            'Supabase returned no user after the email change',
            code: 'PROFILE_EMAIL_UPDATE_FAILED',
          );
        }
        confirmedEmail = _normalizeEmail(updatedUser.email);
        final responsePendingEmail = _normalizeEmail(updatedUser.newEmail);

        if (confirmedEmail?.toLowerCase() != requestedEmail.toLowerCase()) {
          if (responsePendingEmail?.toLowerCase() ==
              requestedEmail.toLowerCase()) {
            pendingEmail = requestedEmail;
          } else {
            throw const AppException(
              'Supabase did not accept the email change',
              code: 'PROFILE_EMAIL_UPDATE_FAILED',
            );
          }
        } else if (_normalizeEmail(
              persistedRow['email'] as String?,
            )?.toLowerCase() !=
            confirmedEmail?.toLowerCase()) {
          persistedRow = await _client
              .from('profiles')
              .update({'email': confirmedEmail})
              .eq('id', uid)
              .select()
              .single();
        }
      }

      return ProfileUpdateResult(
        profile: UserProfile.fromMap(persistedRow),
        pendingEmail: pendingEmail,
      );
    } on AuthException catch (e, st) {
      if (createdAvatarObject && !profilePersisted) {
        await _removeOwnedAvatar(
          uid: _client.auth.currentUser?.id,
          avatarPath: uploadedAvatarPath,
        );
      }
      AppLogger.error('Failed to update profile authentication data', e, st);
      throw AppException(e.message, code: e.code);
    } on StorageException catch (e, st) {
      AppLogger.error('Failed to update profile avatar', e, st);
      throw AppException(e.message, code: e.statusCode);
    } on PostgrestException catch (e, st) {
      if (createdAvatarObject && !profilePersisted) {
        await _removeOwnedAvatar(
          uid: _client.auth.currentUser?.id,
          avatarPath: uploadedAvatarPath,
        );
      }
      AppLogger.error('Lỗi cơ sở dữ liệu', e, st);
      throw AppException(e.message, code: e.code);
    } catch (e, st) {
      if (createdAvatarObject && !profilePersisted) {
        await _removeOwnedAvatar(
          uid: _client.auth.currentUser?.id,
          avatarPath: uploadedAvatarPath,
        );
      }
      if (e is AppException) rethrow;
      AppLogger.error('Lỗi kết nối', e, st);
      throw const AppException('errorConnection');
    }
  }

  Future<UserProfile> completeSurvey({
    required String occupation,
    required String preferredCurrency,
  }) async {
    try {
      final uid = _userId;
      try {
        await _client.rpc('initialize_user');
      } catch (e, st) {
        AppLogger.error('initialize_user RPC failed before survey', e, st);
      }

      final row = await _client
          .from('profiles')
          .upsert({
            'id': uid,
            'occupation': occupation,
            'preferred_currency': preferredCurrency,
            'survey_completed_at': DateTime.now().toUtc().toIso8601String(),
          }, onConflict: 'id')
          .select()
          .single();
      return UserProfile.fromMap(row);
    } on PostgrestException catch (e, st) {
      AppLogger.error('Failed to complete profile survey', e, st);
      throw AppException(e.message, code: e.code);
    } catch (e, st) {
      if (e is AppException) rethrow;
      AppLogger.error('Failed to complete profile survey', e, st);
      throw const AppException(
        'errorConnection',
        code: 'PROFILE_SURVEY_FAILED',
      );
    }
  }

  Future<UserProfile> completeSurveySetup({
    required String occupation,
    required String preferredCurrency,
    required String walletName,
    required double initialBalance,
  }) async {
    try {
      final row = await _client.rpc(
        'complete_profile_survey',
        params: {
          'p_occupation': occupation,
          'p_preferred_currency': preferredCurrency,
          'p_wallet_name': walletName,
          'p_initial_balance': initialBalance,
        },
      );
      return UserProfile.fromMap(
        (row as Map<dynamic, dynamic>).cast<String, dynamic>(),
      );
    } on PostgrestException catch (e, st) {
      AppLogger.error('Failed to complete profile survey setup', e, st);
      throw AppException(e.message, code: e.code);
    } catch (e, st) {
      if (e is AppException) rethrow;
      AppLogger.error('Failed to complete profile survey setup', e, st);
      throw const AppException(
        'errorConnection',
        code: 'PROFILE_SURVEY_FAILED',
      );
    }
  }

  Future<UserProfile> savePaymentQrImage(String imagePath) async {
    try {
      final uid = _userId;
      final qrPath = await _uploadPaymentQrImage(
        uid: uid,
        imagePath: imagePath,
      );
      final row = await _client
          .from('profiles')
          .update({'payment_qr_path': qrPath})
          .eq('id', uid)
          .select()
          .single();
      return UserProfile.fromMap(row);
    } on PostgrestException catch (e, st) {
      AppLogger.error('Failed to save payment QR profile', e, st);
      throw AppException(e.message, code: e.code);
    } catch (e, st) {
      if (e is AppException) rethrow;
      AppLogger.error('Failed to save payment QR profile', e, st);
      throw const AppException(
        'Failed to save payment QR',
        code: 'PAYMENT_QR_SAVE_FAILED',
      );
    }
  }

  Future<UserProfile> clearPaymentQrImage() async {
    try {
      final uid = _userId;
      final row = await _client
          .from('profiles')
          .update({'payment_qr_path': null})
          .eq('id', uid)
          .select()
          .single();
      return UserProfile.fromMap(row);
    } on PostgrestException catch (e, st) {
      AppLogger.error('Failed to clear payment QR profile', e, st);
      throw AppException(e.message, code: e.code);
    } catch (e, st) {
      if (e is AppException) rethrow;
      AppLogger.error('Failed to clear payment QR profile', e, st);
      throw const AppException(
        'Failed to clear payment QR',
        code: 'PAYMENT_QR_CLEAR_FAILED',
      );
    }
  }

  Future<String> _uploadAvatarImage({
    required String uid,
    required String imagePath,
  }) async {
    if (imagePath.startsWith('avatars/') || imagePath.startsWith('http')) {
      return imagePath;
    }

    try {
      final bytes = await File(imagePath).readAsBytes();
      final version = DateTime.now().toUtc().microsecondsSinceEpoch;
      final path = 'avatars/$uid/avatar_$version.jpg';

      await _client.storage
          .from(AppConstants.storageBucket)
          .uploadBinary(
            path,
            bytes,
            fileOptions: const FileOptions(contentType: 'image/jpeg'),
          );

      return path;
    } on PostgrestException catch (e, st) {
      AppLogger.error('Failed to upload profile avatar', e, st);
      throw AppException(e.message, code: e.code);
    } catch (e, st) {
      if (e is AppException) rethrow;
      AppLogger.error('Failed to upload profile avatar', e, st);
      throw const AppException(
        'Failed to upload profile avatar',
        code: 'AVATAR_UPLOAD_FAILED',
      );
    }
  }

  Future<UserProfile> _profileWithConfirmedAuthEmail(
    Map<String, dynamic> row,
  ) async {
    final confirmedEmail = _normalizeEmail(_client.auth.currentUser?.email);
    final storedEmail = _normalizeEmail(row['email'] as String?);
    if (confirmedEmail == null ||
        storedEmail?.toLowerCase() == confirmedEmail.toLowerCase()) {
      return UserProfile.fromMap(row);
    }

    final visibleRow = Map<String, dynamic>.from(row)
      ..['email'] = confirmedEmail;
    try {
      final updatedRow = await _client
          .from('profiles')
          .update({'email': confirmedEmail})
          .eq('id', _userId)
          .select()
          .single();
      return UserProfile.fromMap(updatedRow);
    } catch (e, st) {
      AppLogger.error('Failed to sync confirmed auth email to profile', e, st);
      return UserProfile.fromMap(visibleRow);
    }
  }

  String? _normalizeEmail(String? value) {
    final normalized = value?.trim();
    return normalized == null || normalized.isEmpty ? null : normalized;
  }

  bool _isLocalImagePath(String path) {
    return !path.startsWith('avatars/') && !path.startsWith('http');
  }

  Future<void> _removeOwnedAvatar({
    required String? uid,
    required String? avatarPath,
  }) async {
    if (uid == null ||
        avatarPath == null ||
        !avatarPath.startsWith('avatars/$uid/')) {
      return;
    }

    try {
      await _client.storage.from(AppConstants.storageBucket).remove([
        avatarPath,
      ]);
    } catch (e, st) {
      AppLogger.error('Failed to clean up previous profile avatar', e, st);
    }
  }

  Future<String> _uploadPaymentQrImage({
    required String uid,
    required String imagePath,
  }) async {
    if (imagePath.startsWith('payment-qr/') || imagePath.startsWith('http')) {
      return imagePath;
    }

    try {
      final bytes = await File(imagePath).readAsBytes();
      const fileName = 'qr.jpg';
      final path = 'payment-qr/$uid/$fileName';
      await _client.storage
          .from(AppConstants.storageBucket)
          .uploadBinary(
            path,
            bytes,
            fileOptions: const FileOptions(
              contentType: 'image/jpeg',
              upsert: true,
            ),
          );
      return path;
    } on StorageException catch (e, st) {
      AppLogger.error('Failed to upload payment QR', e, st);
      throw AppException(e.message, code: e.statusCode);
    } catch (e, st) {
      if (e is AppException) rethrow;
      AppLogger.error('Failed to upload payment QR', e, st);
      throw const AppException(
        'Failed to upload payment QR',
        code: 'PAYMENT_QR_UPLOAD_FAILED',
      );
    }
  }
}
