import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/notifications/notification_providers.dart';
import '../../../core/preferences/preferences_providers.dart';
import '../domain/models/reminder_settings.dart';

/// Drives the local daily logging reminder: persists the preference and keeps
/// the scheduled OS notification in sync.
class ReminderController extends Notifier<ReminderSettings> {
  static const _enabledKey = 'local_reminder_enabled';
  static const _hourKey = 'local_reminder_hour';
  static const _minuteKey = 'local_reminder_minute';

  @override
  ReminderSettings build() {
    final prefs = ref.read(sharedPreferencesProvider);
    return ReminderSettings(
      enabled: prefs.getBool(_enabledKey) ?? false,
      hour: prefs.getInt(_hourKey) ?? 20,
      minute: prefs.getInt(_minuteKey) ?? 0,
    );
  }

  /// Enables the reminder. Returns `false` (and changes nothing) when the OS
  /// denies notification permission, so the UI can keep the switch off.
  Future<bool> enable({required String title, required String body}) async {
    final service = ref.read(localNotificationServiceProvider);
    final granted = await service.requestPermission();
    if (!granted) return false;

    await service.scheduleDailyReminder(
      hour: state.hour,
      minute: state.minute,
      title: title,
      body: body,
    );
    await _persist(state.copyWith(enabled: true));
    return true;
  }

  Future<void> disable() async {
    await ref.read(localNotificationServiceProvider).cancelDailyReminder();
    await _persist(state.copyWith(enabled: false));
  }

  /// Updates the reminder time, re-scheduling when the reminder is on.
  Future<void> setTime({
    required int hour,
    required int minute,
    required String title,
    required String body,
  }) async {
    final updated = state.copyWith(hour: hour, minute: minute);
    if (updated.enabled) {
      await ref
          .read(localNotificationServiceProvider)
          .scheduleDailyReminder(
            hour: hour,
            minute: minute,
            title: title,
            body: body,
          );
    }
    await _persist(updated);
  }

  Future<void> _persist(ReminderSettings settings) async {
    state = settings;
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setBool(_enabledKey, settings.enabled);
    await prefs.setInt(_hourKey, settings.hour);
    await prefs.setInt(_minuteKey, settings.minute);
  }
}

final reminderControllerProvider =
    NotifierProvider<ReminderController, ReminderSettings>(
      ReminderController.new,
    );
