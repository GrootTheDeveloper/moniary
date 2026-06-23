import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/preferences/preferences_providers.dart';
import '../../../../shared/utils/app_logger.dart';
import '../../domain/theme/app_theme_settings.dart';

final themeSettingsRepositoryProvider = Provider<ThemeSettingsRepository>((
  ref,
) {
  return ThemeSettingsRepository(ref.watch(sharedPreferencesProvider));
});

class ThemeSettingsRepository {
  ThemeSettingsRepository(this._prefs);

  final SharedPreferences _prefs;

  static const _key = 'custom_theme_settings_v1';

  AppThemeSettings loadSettings() {
    final raw = _prefs.getString(_key);
    if (raw == null || raw.isEmpty) {
      return AppThemeSettings.defaults;
    }

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) {
        AppLogger.warning('Stored theme settings are not a JSON object.');
        return AppThemeSettings.defaults;
      }
      return AppThemeSettings.fromJson(decoded);
    } catch (error, stackTrace) {
      AppLogger.error(
        'Failed to read stored theme settings',
        error,
        stackTrace,
      );
      return AppThemeSettings.defaults;
    }
  }

  Future<void> saveSettings(AppThemeSettings settings) async {
    final encoded = jsonEncode(settings.toJson());
    await _prefs.setString(_key, encoded);
  }

  Future<void> resetSettings() async {
    await _prefs.remove(_key);
  }
}
