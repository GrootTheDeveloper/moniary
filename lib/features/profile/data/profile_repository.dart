import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../core/supabase/app_exception.dart';
import '../../../core/supabase/supabase_providers.dart';
import '../../../../shared/utils/app_logger.dart';
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
            return UserProfile.fromMap(retryRow);
          }
        } catch (e, st) {
          AppLogger.error('Failed to auto-initialize profile', e, st);
        }
        return null;
      }
      return UserProfile.fromMap(row);
    } on PostgrestException catch (e, st) {
      AppLogger.error('Lỗi cơ sở dữ liệu', e, st);
      throw AppException(e.message, code: e.code);
    } catch (e, st) {
      if (e is AppException) rethrow;
      AppLogger.error('Lỗi kết nối', e, st);
      throw const AppException('errorConnection');
    }
  }

  Future<UserProfile> upsertProfile({
    required String fullName,
    required String username,
    required String timezone,
    String? avatarImagePath,
  }) async {
    try {
      final uid = _userId;
      final avatarUrl = avatarImagePath == null
          ? null
          : await _uploadAvatarImage(uid: uid, imagePath: avatarImagePath);

      final values = <String, dynamic>{
        'id': uid,
        'full_name': fullName,
        'username': username,
        'timezone': timezone,
      };
      if (avatarUrl != null) values['avatar_url'] = avatarUrl;

      final row = await _client
          .from('profiles')
          .upsert(values)
          .select()
          .single();

      // Fix for Problem 3: Also update Supabase Auth metadata so login doesn't reset full_name
      try {
        final authMeta = <String, dynamic>{
          'full_name': fullName,
          'username': username,
        };
        if (avatarUrl != null) authMeta['avatar_url'] = avatarUrl;
        await _client.auth.updateUser(UserAttributes(data: authMeta));
      } catch (e, st) {
        AppLogger.error('Failed to sync auth metadata (non-blocking)', e, st);
      }

      return UserProfile.fromMap(row);
    } on PostgrestException catch (e, st) {
      AppLogger.error('Lỗi cơ sở dữ liệu', e, st);
      throw AppException(e.message, code: e.code);
    } catch (e, st) {
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
      final path = 'avatars/$uid/avatar.jpg';

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
