import 'package:flutter_test/flutter_test.dart';
import 'package:moniary/features/settings/data/repositories/notification_settings_repository.dart';
import 'package:moniary/features/settings/domain/models/notification_settings.dart';

void main() {
  group('MockNotificationSettingsRepository', () {
    late MockNotificationSettingsRepository repository;

    setUp(() {
      repository = MockNotificationSettingsRepository();
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
        weeklySummaryEnabled: true,
        monthlySummaryEnabled: true,
        yearlySummaryEnabled: true,
      );

      await repository.updateSettings(newSettings);
      final fetched = await repository.getSettings();

      expect(fetched.dailyReminderEnabled, isTrue);
      expect(fetched.weeklySummaryEnabled, isTrue);
      expect(fetched.monthlySummaryEnabled, isTrue);
      expect(fetched.yearlySummaryEnabled, isTrue);
    });
  });
}
