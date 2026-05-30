import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/models/notification_settings.dart';
import '../data/repositories/notification_settings_repository.dart';

class NotificationSettingsController
    extends AsyncNotifier<NotificationSettings> {
  @override
  FutureOr<NotificationSettings> build() {
    return ref.read(notificationSettingsRepositoryProvider).getSettings();
  }

  Future<void> updateDailyReminder(bool enabled, [TimeOfDay? time]) async {
    final current = state.value;
    if (current == null) return;

    final updated = current.copyWith(
      dailyReminderEnabled: enabled,
      dailyReminderTime: time,
    );

    await _update(updated);
  }

  Future<void> updateWeeklySummary(bool enabled) async {
    final current = state.value;
    if (current == null) return;

    final updated = current.copyWith(weeklySummaryEnabled: enabled);
    await _update(updated);
  }

  Future<void> updateMonthlySummary(bool enabled) async {
    final current = state.value;
    if (current == null) return;

    final updated = current.copyWith(monthlySummaryEnabled: enabled);
    await _update(updated);
  }

  Future<void> updateYearlySummary(bool enabled) async {
    final current = state.value;
    if (current == null) return;

    final updated = current.copyWith(yearlySummaryEnabled: enabled);
    await _update(updated);
  }

  Future<void> _update(NotificationSettings newSettings) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref
          .read(notificationSettingsRepositoryProvider)
          .updateSettings(newSettings);
      return newSettings;
    });
  }
}

final notificationSettingsControllerProvider =
    AsyncNotifierProvider<NotificationSettingsController, NotificationSettings>(
      NotificationSettingsController.new,
    );
