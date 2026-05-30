import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/constants/app_constants.dart';
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
      throw Exception('User is not logged in');
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
      throw Exception('User is not logged in');
    }

    await _supabase
        .from('notification_settings')
        .update(settings.toJson())
        .eq('user_id', user.id);
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
