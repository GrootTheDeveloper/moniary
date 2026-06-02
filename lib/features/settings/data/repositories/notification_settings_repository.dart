import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/supabase/app_exception.dart';
import '../../../../shared/utils/app_logger.dart';
import '../../domain/models/notification_settings.dart';

abstract class NotificationSettingsRepository {
  Future<NotificationSettings> getSettings();
  Future<void> updateSettings(NotificationSettings settings);
}

abstract class NotificationSettingsDataSource {
  String? get currentUserId;
  Future<Map<String, dynamic>?> fetchSettings(String userId);
  Future<void> upsertSettings(Map<String, dynamic> payload);
}

class SupabaseNotificationSettingsDataSource
    implements NotificationSettingsDataSource {
  SupabaseNotificationSettingsDataSource(this._supabase);

  final SupabaseClient _supabase;

  @override
  String? get currentUserId => _supabase.auth.currentUser?.id;

  @override
  Future<Map<String, dynamic>?> fetchSettings(String userId) {
    return _supabase
        .from('notification_settings')
        .select()
        .eq('user_id', userId)
        .maybeSingle();
  }

  @override
  Future<void> upsertSettings(Map<String, dynamic> payload) {
    return _supabase
        .from('notification_settings')
        .upsert(payload, onConflict: 'user_id');
  }
}

class SupabaseNotificationSettingsRepository
    implements NotificationSettingsRepository {
  SupabaseNotificationSettingsRepository(this._dataSource);

  final NotificationSettingsDataSource _dataSource;

  @override
  Future<NotificationSettings> getSettings() async {
    final userId = _dataSource.currentUserId;
    if (userId == null) {
      throw const AppException('User is not logged in', code: 'AUTH_REQUIRED');
    }

    try {
      final data = await _dataSource.fetchSettings(userId);

      if (data == null) {
        return const NotificationSettings();
      }

      return NotificationSettings.fromJson(data);
    } catch (e, st) {
      AppLogger.error('Failed to load notification settings', e, st);
      throw const AppException(
        'Failed to load notification settings',
        code: 'NOTIFICATION_SETTINGS_READ_ERROR',
      );
    }
  }

  @override
  Future<void> updateSettings(NotificationSettings settings) async {
    final userId = _dataSource.currentUserId;
    if (userId == null) {
      throw const AppException('User is not logged in', code: 'AUTH_REQUIRED');
    }

    try {
      await _dataSource.upsertSettings(buildSettingsPayload(userId, settings));
    } catch (e, st) {
      AppLogger.error('Failed to update notification settings', e, st);
      throw const AppException(
        'Failed to update notification settings',
        code: 'NOTIFICATION_SETTINGS_UPDATE_ERROR',
      );
    }
  }

  static Map<String, dynamic> buildSettingsPayload(
    String userId,
    NotificationSettings settings,
  ) {
    return {'user_id': userId, ...settings.toJson()};
  }
}

class MockNotificationSettingsRepository
    implements NotificationSettingsRepository {
  NotificationSettings _settings = const NotificationSettings();

  @override
  Future<NotificationSettings> getSettings() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return _settings;
  }

  @override
  Future<void> updateSettings(NotificationSettings settings) async {
    await Future.delayed(const Duration(milliseconds: 300));
    _settings = settings;
  }
}

final notificationSettingsRepositoryProvider =
    Provider<NotificationSettingsRepository>((ref) {
      if (AppConstants.hasSupabaseConfig) {
        return SupabaseNotificationSettingsRepository(
          SupabaseNotificationSettingsDataSource(Supabase.instance.client),
        );
      } else {
        return MockNotificationSettingsRepository();
      }
    });
