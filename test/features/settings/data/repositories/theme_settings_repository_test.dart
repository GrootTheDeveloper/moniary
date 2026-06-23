import 'package:flutter_test/flutter_test.dart';
import 'package:moniary/features/settings/data/repositories/theme_settings_repository.dart';
import 'package:moniary/features/settings/domain/theme/app_theme_settings.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('ThemeSettingsRepository', () {
    test('returns defaults when no settings are stored', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final repository = ThemeSettingsRepository(prefs);

      expect(
        repository.loadSettings().toJson(),
        AppThemeSettings.defaults.toJson(),
      );
    });

    test('saves and loads settings', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final repository = ThemeSettingsRepository(prefs);
      final settings = AppThemeSettings.defaults.copyWith(
        presetId: AppThemeSettings.customPresetId,
        primaryColor: 0xFFABCDEF,
      );

      await repository.saveSettings(settings);

      expect(repository.loadSettings().toJson(), settings.toJson());
    });

    test('returns defaults for corrupt stored settings', () async {
      SharedPreferences.setMockInitialValues({
        'custom_theme_settings_v1': '{bad json',
      });
      final prefs = await SharedPreferences.getInstance();
      final repository = ThemeSettingsRepository(prefs);

      expect(
        repository.loadSettings().toJson(),
        AppThemeSettings.defaults.toJson(),
      );
    });
  });
}
