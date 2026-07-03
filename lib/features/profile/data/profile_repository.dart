import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../core/supabase/app_exception.dart';
import '../../../core/supabase/supabase_providers.dart';
import '../../../../shared/utils/app_logger.dart';
import '../domain/user_profile.dart';

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return ProfileRepository(
    ref.watch(supabaseClientProvider),
    useMockData: ref.watch(useMockDataModeProvider),
  );
});

class ProfileRepository {
  ProfileRepository(this._client, {bool useMockData = false})
    : _useMockData = useMockData || !AppConstants.hasSupabaseConfig;

  final SupabaseClient _client;
  final bool _useMockData;

  static UserProfile? _mockProfile;

  void resetMockProfile() {
    if (_useMockData) _mockProfile = null;
  }

  String get _userId {
    if (_useMockData) {
      return 'mock-user-id';
    }
    final uid = _client.auth.currentSession?.user.id;
    if (uid == null) {
      throw const AppException('User not logged in', code: 'AUTH_REQUIRED');
    }
    return uid;
  }

  Future<UserProfile?> fetchCurrentProfile() async {
    if (_useMockData) {
      _mockProfile ??= UserProfile(
        id: 'mock-user-id',
        fullName: '',
        email: 'guest@moniary.app',
        avatarUrl: null,
        loginProvider: 'anonymous',
        timezone: AppConstants.defaultTimezone,
        username: 'mock-user',
        surveyCompleted: false,
      );
      return _mockProfile;
    }
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
    if (_useMockData) {
      _mockProfile = UserProfile(
        id: 'mock-user-id',
        fullName: fullName,
        email: _mockProfile?.email ?? 'guest@moniary.app',
        avatarUrl: avatarImagePath ?? _mockProfile?.avatarUrl,
        loginProvider: _mockProfile?.loginProvider ?? 'anonymous',
        timezone: timezone,
        username: username,
        occupation: _mockProfile?.occupation,
        preferredCurrency: _mockProfile?.preferredCurrency ?? 'VND',
        surveyCompleted: _mockProfile?.surveyCompleted ?? false,
      );
      return _mockProfile!;
    }
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
    if (_useMockData) {
      final profile = _mockProfile ?? await fetchCurrentProfile();
      if (profile == null) {
        throw const AppException(
          'Profile is not available',
          code: 'PROFILE_NOT_FOUND',
        );
      }
      _mockProfile = UserProfile(
        id: profile.id,
        fullName: profile.fullName,
        email: profile.email,
        avatarUrl: profile.avatarUrl,
        loginProvider: profile.loginProvider,
        timezone: profile.timezone,
        username: profile.username,
        occupation: occupation,
        preferredCurrency: preferredCurrency,
        surveyCompleted: true,
      );
      return _mockProfile!;
    }

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

  void setMockEmailAndProvider({
    required String email,
    required String loginProvider,
  }) {
    _mockProfile = UserProfile(
      id: 'mock-user-id',
      fullName: _mockProfile?.fullName ?? '',
      email: email,
      avatarUrl: _mockProfile?.avatarUrl,
      loginProvider: loginProvider,
      timezone: _mockProfile?.timezone ?? AppConstants.defaultTimezone,
      username: _mockProfile?.username ?? 'mock-user',
      occupation: _mockProfile?.occupation,
      preferredCurrency: _mockProfile?.preferredCurrency ?? 'VND',
      surveyCompleted: _mockProfile?.surveyCompleted ?? false,
    );
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
}
