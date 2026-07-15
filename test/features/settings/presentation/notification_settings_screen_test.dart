import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moniary/app/app_theme.dart';
import 'package:moniary/core/preferences/preferences_providers.dart';
import 'package:moniary/features/notifications/data/repositories/notification_delivery_preferences_repository_impl.dart';
import 'package:moniary/features/notifications/domain/entities/notification_delivery_preferences.dart';
import 'package:moniary/features/notifications/domain/repositories/notification_delivery_preferences_repository.dart';
import 'package:moniary/features/settings/data/repositories/notification_settings_repository.dart';
import 'package:moniary/features/settings/domain/models/notification_settings.dart';
import 'package:moniary/features/settings/presentation/notifications/notification_settings_screen.dart';
import 'package:moniary/l10n/gen_l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('system push preference is visible and persisted', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    final pushRepository = _FakePushPreferencesRepository();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(preferences),
          notificationDeliveryPreferencesRepositoryProvider.overrideWithValue(
            pushRepository,
          ),
          notificationSettingsRepositoryProvider.overrideWithValue(
            _FakeNotificationSettingsRepository(),
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          locale: const Locale('vi'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const NotificationSettingsScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final systemLabel = find.text('Hệ thống');
    await tester.scrollUntilVisible(systemLabel, 150);
    final systemTile = find.ancestor(
      of: systemLabel,
      matching: find.byType(InkWell),
    );
    final systemSwitch = find.descendant(
      of: systemTile,
      matching: find.byType(Switch),
    );

    expect(systemSwitch, findsOneWidget);
    await tester.tap(systemSwitch);
    await tester.pumpAndSettle();

    expect(pushRepository.updated.single.systemEnabled, isFalse);
  });
}

class _FakePushPreferencesRepository
    implements NotificationDeliveryPreferencesRepository {
  final updated = <NotificationDeliveryPreferences>[];

  @override
  Future<NotificationDeliveryPreferences> getPreferences() async =>
      const NotificationDeliveryPreferences();

  @override
  Future<void> updatePreferences(
    NotificationDeliveryPreferences preferences,
  ) async {
    updated.add(preferences);
  }
}

class _FakeNotificationSettingsRepository
    implements NotificationSettingsRepository {
  @override
  Future<NotificationSettings> getSettings() async =>
      const NotificationSettings();

  @override
  Future<void> updateSettings(NotificationSettings settings) async {}
}
