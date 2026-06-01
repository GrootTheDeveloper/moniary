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

class SupabaseNotificationSettingsRepository
    implements NotificationSettingsRepository {
  SupabaseNotificationSettingsRepository(this._supabase);

  final SupabaseClient _supabase;

  @override
  Future<NotificationSettings> getSettings() async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      throw const AppException('User is not logged in', code: 'AUTH_REQUIRED');
    }

    final data = await _supabase
        .from('notification_settings')
        .select()
        .eq('user_id', user.id)
        .maybeSingle();

    if (data == null) {
      // If no settings exist yet, return default
      return const NotificationSettings();
    }

    return NotificationSettings.fromJson(data);
  }

  @override
  Future<void> updateSettings(NotificationSettings settings) async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      throw const AppException('User is not logged in', code: 'AUTH_REQUIRED');
    }

    try {
      await _supabase
          .from('notification_settings')
          .upsert(
            buildSettingsPayload(user.id, settings),
            onConflict: 'user_id',
          );
    } catch (e, st) {
      AppLogger.error('Failed to update notification settings', e, st);
      rethrow;
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
        return SupabaseNotificationSettingsRepository(Supabase.instance.client);
      } else {
        return MockNotificationSettingsRepository();
      }
    });
