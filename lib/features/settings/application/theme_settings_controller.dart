import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/repositories/theme_settings_repository.dart';
import '../domain/theme/app_theme_settings.dart';

final themeSettingsControllerProvider =
    NotifierProvider<ThemeSettingsController, AppThemeSettings>(
      ThemeSettingsController.new,
    );

class ThemeSettingsController extends Notifier<AppThemeSettings> {
  @override
  AppThemeSettings build() {
    return ref.read(themeSettingsRepositoryProvider).loadSettings();
  }

  Future<void> save(AppThemeSettings settings) async {
    state = settings;
    await ref.read(themeSettingsRepositoryProvider).saveSettings(settings);
  }

  Future<void> applyPreset(AppThemeSettings preset) {
    return save(preset);
  }

  Future<void> resetToDefault() async {
    await ref.read(themeSettingsRepositoryProvider).resetSettings();
    state = AppThemeSettings.defaults;
  }
}
