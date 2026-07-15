import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moniary/features/settings/application/notification_settings_controller.dart';
import 'package:moniary/features/settings/data/repositories/notification_settings_repository.dart';
import 'package:moniary/features/settings/domain/models/notification_settings.dart';

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
  group('NotificationSettingsController', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer(
        overrides: [
          notificationSettingsRepositoryProvider.overrideWithValue(
            InMemoryNotificationSettingsRepository(),
          ),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    test('initial state is loaded from repository', () async {
      final state = await container.read(
        notificationSettingsControllerProvider.future,
      );
      expect(state.dailyReminderEnabled, isFalse);
    });

    test('updateDailyReminder updates state and repository', () async {
      await container.read(notificationSettingsControllerProvider.future);
      final controller = container.read(
        notificationSettingsControllerProvider.notifier,
      );
      await controller.updateDailyReminder(true);

      final state = await container.read(
        notificationSettingsControllerProvider.future,
      );
      expect(state.dailyReminderEnabled, isTrue);
    });

    test('updateMonthlySummary updates state and repository', () async {
      await container.read(notificationSettingsControllerProvider.future);
      final controller = container.read(
        notificationSettingsControllerProvider.notifier,
      );
      await controller.updateMonthlySummary(true);

      final state = await container.read(
        notificationSettingsControllerProvider.future,
      );
      expect(state.monthlySummaryEnabled, isTrue);
    });
  });
}
