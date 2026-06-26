import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/preferences/preferences_providers.dart';
import '../../../../core/supabase/app_exception.dart';

final privacyRepositoryProvider = Provider<PrivacyRepository>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return PrivacyRepository(prefs);
});

class PrivacyRepository {
  final SharedPreferences _prefs;

  static const String _keyIsAppLocked = 'is_app_locked';
  static const String _keyIsBalancesHidden = 'is_balances_hidden';

  PrivacyRepository(this._prefs);

  bool getIsAppLocked() {
    return _prefs.getBool(_keyIsAppLocked) ?? false;
  }

  Future<void> setIsAppLocked(bool value) async {
    final saved = await _prefs.setBool(_keyIsAppLocked, value);
    if (!saved) {
      throw const AppException(
        'Failed to save app lock preference',
        code: 'PRIVACY_PREFERENCE_SAVE_FAILED',
      );
    }
  }

  bool getIsBalancesHidden() {
    return _prefs.getBool(_keyIsBalancesHidden) ?? false;
  }

  Future<void> setIsBalancesHidden(bool value) async {
    final saved = await _prefs.setBool(_keyIsBalancesHidden, value);
    if (!saved) {
      throw const AppException(
        'Failed to save balance visibility preference',
        code: 'PRIVACY_PREFERENCE_SAVE_FAILED',
      );
    }
  }

  Future<void> resetUserPreferences() async {
    await _prefs.remove(_keyIsAppLocked);
    await _prefs.remove(_keyIsBalancesHidden);
  }
}
