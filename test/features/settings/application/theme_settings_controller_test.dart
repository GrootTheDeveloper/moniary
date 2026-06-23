import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moniary/core/preferences/preferences_providers.dart';
import 'package:moniary/features/settings/application/theme_settings_controller.dart';
import 'package:moniary/features/settings/domain/theme/app_theme_settings.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('ThemeSettingsController', () {
    Future<ProviderContainer> makeContainer() async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      return ProviderContainer(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      );
    }

    test('initializes from defaults', () async {
      final container = await makeContainer();
      addTearDown(container.dispose);

      final state = container.read(themeSettingsControllerProvider);

      expect(state.toJson(), AppThemeSettings.defaults.toJson());
    });

    test('save updates state', () async {
      final container = await makeContainer();
      addTearDown(container.dispose);
      final controller = container.read(
        themeSettingsControllerProvider.notifier,
      );
      final settings = AppThemeSettings.defaults.copyWith(
        presetId: AppThemeSettings.customPresetId,
        primaryColor: 0xFFABCDEF,
      );

      await controller.save(settings);

      expect(
        container.read(themeSettingsControllerProvider).primaryColor,
        0xFFABCDEF,
      );
    });

    test('reset restores defaults', () async {
      final container = await makeContainer();
      addTearDown(container.dispose);
      final controller = container.read(
        themeSettingsControllerProvider.notifier,
      );

      await controller.save(
        AppThemeSettings.defaults.copyWith(primaryColor: 0xFFABCDEF),
      );
      await controller.resetToDefault();

      expect(
        container.read(themeSettingsControllerProvider).toJson(),
        AppThemeSettings.defaults.toJson(),
      );
    });
  });
}
