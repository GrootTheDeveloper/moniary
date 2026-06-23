import 'package:flutter_test/flutter_test.dart';
import 'package:moniary/features/settings/domain/theme/app_theme_settings.dart';

void main() {
  group('AppThemeSettings', () {
    test('round-trips through json', () {
      const settings = AppThemeSettings(
        presetId: AppThemeSettings.customPresetId,
        primaryColor: 0xFF112233,
        secondaryColor: 0xFF445566,
        backgroundColor: 0xFF000000,
        surfaceColor: 0xFF101010,
        textPrimaryColor: 0xFFFFFFFF,
        textSecondaryColor: 0xFFCCCCCC,
        buttonColor: 0xFF778899,
        iconColor: 0xFFFFFFFF,
        appBarColor: 0xFF010203,
        navigationBarColor: 0xFF040506,
      );

      final decoded = AppThemeSettings.fromJson(settings.toJson());

      expect(decoded.toJson(), settings.toJson());
    });

    test('parses six and eight digit hex colors', () {
      expect(AppThemeSettings.parseColorString('#112233'), 0xFF112233);
      expect(AppThemeSettings.parseColorString('80112233'), 0x80112233);
    });

    test('falls back for invalid color values', () {
      final settings = AppThemeSettings.fromJson({
        'presetId': '',
        'primaryColor': 'not-a-color',
      });

      expect(settings.presetId, AppThemeSettings.defaultPresetId);
      expect(settings.primaryColor, AppThemeSettings.defaults.primaryColor);
    });
  });
}
