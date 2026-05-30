import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/preferences/preferences_providers.dart';

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
    await _prefs.setBool(_keyIsAppLocked, value);
  }

  bool getIsBalancesHidden() {
    return _prefs.getBool(_keyIsBalancesHidden) ?? false;
  }

  Future<void> setIsBalancesHidden(bool value) async {
    await _prefs.setBool(_keyIsBalancesHidden, value);
  }
}
