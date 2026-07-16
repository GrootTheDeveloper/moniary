import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/supabase/app_exception.dart';
import '../../../../core/supabase/supabase_providers.dart';
import '../../../../shared/utils/app_logger.dart';
import '../../domain/entities/notification_delivery_preferences.dart';
import '../../domain/repositories/notification_delivery_preferences_repository.dart';

final notificationDeliveryPreferencesRepositoryProvider =
    Provider<NotificationDeliveryPreferencesRepository>((ref) {
      if (ref.watch(useMockDataModeProvider)) {
        return MockNotificationDeliveryPreferencesRepository();
      }
      return SupabaseNotificationDeliveryPreferencesRepository(
        ref.watch(supabaseClientProvider),
      );
    });

class MockNotificationDeliveryPreferencesRepository
    implements NotificationDeliveryPreferencesRepository {
  NotificationDeliveryPreferences _preferences =
      const NotificationDeliveryPreferences();

  @override
  Future<NotificationDeliveryPreferences> getPreferences() async =>
      _preferences;

  @override
  Future<void> updatePreferences(
    NotificationDeliveryPreferences preferences,
  ) async {
    _preferences = preferences;
  }
}

class SupabaseNotificationDeliveryPreferencesRepository
    implements NotificationDeliveryPreferencesRepository {
  SupabaseNotificationDeliveryPreferencesRepository(this._client);

  final SupabaseClient _client;

  @override
  Future<NotificationDeliveryPreferences> getPreferences() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw const AppException('User is not logged in', code: 'AUTH_REQUIRED');
    }
    try {
      final row = await _client
          .from('notification_delivery_preferences')
          .select()
          .eq('user_id', userId)
          .maybeSingle();
      return row == null
          ? const NotificationDeliveryPreferences()
          : NotificationDeliveryPreferences.fromJson(row);
    } catch (error, stackTrace) {
      AppLogger.error('Failed to load push preferences', error, stackTrace);
      throw const AppException(
        'Failed to load push preferences',
        code: 'NOTIFICATION_PREFERENCES_READ_ERROR',
      );
    }
  }

  @override
  Future<void> updatePreferences(
    NotificationDeliveryPreferences preferences,
  ) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw const AppException('User is not logged in', code: 'AUTH_REQUIRED');
    }
    try {
      await _client.from('notification_delivery_preferences').upsert({
        'user_id': userId,
        ...preferences.toJson(),
      }, onConflict: 'user_id');
    } catch (error, stackTrace) {
      AppLogger.error('Failed to update push preferences', error, stackTrace);
      throw const AppException(
        'Failed to update push preferences',
        code: 'NOTIFICATION_PREFERENCES_UPDATE_ERROR',
      );
    }
  }
}
