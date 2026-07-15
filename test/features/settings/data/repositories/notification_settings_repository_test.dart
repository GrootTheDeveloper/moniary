import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moniary/core/supabase/app_exception.dart';
import 'package:moniary/features/settings/data/repositories/notification_settings_repository.dart';
import 'package:moniary/features/settings/domain/models/notification_settings.dart';

class FakeNotificationSettingsDataSource
    implements NotificationSettingsDataSource {
  FakeNotificationSettingsDataSource({
    this.currentUserId = 'user-1',
    this.onFetchSettings,
    this.onUpsertSettings,
  });

  @override
  final String? currentUserId;

  final Future<Map<String, dynamic>?> Function(String userId)? onFetchSettings;
  final Future<void> Function(Map<String, dynamic> payload)? onUpsertSettings;

  @override
  Future<Map<String, dynamic>?> fetchSettings(String userId) {
    return onFetchSettings?.call(userId) ?? Future.value(null);
  }

  @override
  Future<void> upsertSettings(Map<String, dynamic> payload) {
    return onUpsertSettings?.call(payload) ?? Future.value();
  }
}

class InMemoryNotificationSettingsRepository
    implements NotificationSettingsRepository {
  NotificationSettings _settings = const NotificationSettings();

  @override
  Future<NotificationSettings> getSettings() async => _settings;

  @override
  Future<void> updateSettings(NotificationSettings settings) async {
    _settings = settings.normalized();
  }
}

void main() {
  group('SupabaseNotificationSettingsRepository', () {
    test('buildSettingsPayload includes user_id for upsert', () {
      const settings = NotificationSettings(
        dailyReminderEnabled: true,
        weeklySummaryEnabled: true,
        monthlySummaryEnabled: false,
        yearlySummaryEnabled: true,
      );

      final payload =
          SupabaseNotificationSettingsRepository.buildSettingsPayload(
            'user-1',
            settings,
          );

      expect(payload['user_id'], 'user-1');
      expect(payload['daily_reminder_enabled'], isTrue);
      expect(payload['weekly_summary_enabled'], isTrue);
      expect(payload['monthly_summary_enabled'], isFalse);
      expect(payload['yearly_summary_enabled'], isTrue);
    });

    test(
      'NotificationSettings.normalized() normalizes dailyReminderTime to 20:00 when enabled and null',
      () {
        const settings = NotificationSettings(
          dailyReminderEnabled: true,
          dailyReminderTime: null,
        );

        final normalized = settings.normalized();
        final payload =
            SupabaseNotificationSettingsRepository.buildSettingsPayload(
              'user-1',
              normalized,
            );

        expect(payload['daily_reminder_enabled'], isTrue);
        expect(payload['daily_reminder_time'], '20:00:00');
      },
    );

    test('getSettings returns defaults when no settings exist', () async {
      final repository = SupabaseNotificationSettingsRepository(
        FakeNotificationSettingsDataSource(),
      );

      final settings = await repository.getSettings();

      expect(settings.dailyReminderEnabled, isFalse);
      expect(settings.weeklySummaryEnabled, isFalse);
      expect(settings.monthlySummaryEnabled, isFalse);
      expect(settings.yearlySummaryEnabled, isFalse);
    });

    test('getSettings wraps data source failures as AppException', () async {
      final repository = SupabaseNotificationSettingsRepository(
        FakeNotificationSettingsDataSource(
          onFetchSettings: (_) => throw Exception('database unavailable'),
        ),
      );

      await expectLater(
        repository.getSettings(),
        throwsA(
          isA<AppException>().having(
            (e) => e.code,
            'code',
            'NOTIFICATION_SETTINGS_READ_ERROR',
          ),
        ),
      );
    });

    test('updateSettings wraps data source failures as AppException', () async {
      final repository = SupabaseNotificationSettingsRepository(
        FakeNotificationSettingsDataSource(
          onUpsertSettings: (_) => throw Exception('upsert failed'),
        ),
      );

      await expectLater(
        repository.updateSettings(const NotificationSettings()),
        throwsA(
          isA<AppException>().having(
            (e) => e.code,
            'code',
            'NOTIFICATION_SETTINGS_UPDATE_ERROR',
          ),
        ),
      );
    });

    test('getSettings requires a signed-in user', () async {
      final repository = SupabaseNotificationSettingsRepository(
        FakeNotificationSettingsDataSource(currentUserId: null),
      );

      await expectLater(
        repository.getSettings(),
        throwsA(
          isA<AppException>().having((e) => e.code, 'code', 'AUTH_REQUIRED'),
        ),
      );
    });
  });

  group('InMemoryNotificationSettingsRepository', () {
    late InMemoryNotificationSettingsRepository repository;

    setUp(() {
      repository = InMemoryNotificationSettingsRepository();
    });

    test('getSettings returns default initially', () async {
      final settings = await repository.getSettings();
      expect(settings.dailyReminderEnabled, isFalse);
      expect(settings.weeklySummaryEnabled, isFalse);
      expect(settings.monthlySummaryEnabled, isFalse);
      expect(settings.yearlySummaryEnabled, isFalse);
    });

    test('updateSettings saves new settings', () async {
      const newSettings = NotificationSettings(
        dailyReminderEnabled: true,
        dailyReminderTime: TimeOfDay(hour: 10, minute: 30),
        weeklySummaryEnabled: true,
        monthlySummaryEnabled: true,
        yearlySummaryEnabled: true,
      );

      await repository.updateSettings(newSettings);
      final fetched = await repository.getSettings();

      expect(fetched.dailyReminderEnabled, isTrue);
      expect(fetched.dailyReminderTime, const TimeOfDay(hour: 10, minute: 30));
      expect(fetched.weeklySummaryEnabled, isTrue);
      expect(fetched.monthlySummaryEnabled, isTrue);
      expect(fetched.yearlySummaryEnabled, isTrue);
    });

    test(
      'updateSettings normalizes time to 20:00 when enabled without time',
      () async {
        const newSettings = NotificationSettings(
          dailyReminderEnabled: true,
          dailyReminderTime: null,
        );

        await repository.updateSettings(newSettings);
        final fetched = await repository.getSettings();

        expect(fetched.dailyReminderEnabled, isTrue);
        expect(fetched.dailyReminderTime, const TimeOfDay(hour: 20, minute: 0));
      },
    );
  });
}
