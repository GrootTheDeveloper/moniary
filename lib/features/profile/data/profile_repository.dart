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

  static UserProfile? _mockProfile;

  String get _userId {
    if (!AppConstants.hasSupabaseConfig) {
      return 'mock-user-id';
    }
    final uid = _client.auth.currentSession?.user.id;
    if (uid == null) throw const AppException('Bạn chưa đăng nhập.');
    return uid;
  }

  Future<UserProfile?> fetchCurrentProfile() async {
    if (!AppConstants.hasSupabaseConfig) {
      _mockProfile ??= UserProfile(
        id: 'mock-user-id',
        fullName: '',
        email: 'guest@moniary.app',
        avatarUrl: null,
        loginProvider: 'anonymous',
        timezone: AppConstants.defaultTimezone,
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

      if (row == null) return null;
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
    required String timezone,
  }) async {
    if (!AppConstants.hasSupabaseConfig) {
      _mockProfile = UserProfile(
        id: 'mock-user-id',
        fullName: fullName,
        email: 'guest@moniary.app',
        avatarUrl: null,
        loginProvider: 'anonymous',
        timezone: timezone,
      );
      return _mockProfile!;
    }
    try {
      final uid = _userId;

      final row = await _client
          .from('profiles')
          .upsert({'id': uid, 'full_name': fullName, 'timezone': timezone})
          .select()
          .single();

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
}
