import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../shared/utils/currency_formatter.dart';
import 'preferences_bootstrap.dart';

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  return appPreferences;
});

final onboardingSeenProvider = NotifierProvider<OnboardingSeenNotifier, bool>(
  OnboardingSeenNotifier.new,
);

final preferredCurrencyProvider =
    NotifierProvider<PreferredCurrencyNotifier, String>(
      PreferredCurrencyNotifier.new,
    );

class OnboardingSeenNotifier extends Notifier<bool> {
  static const _key = 'onboarding_seen';

  @override
  bool build() {
    return ref.read(sharedPreferencesProvider).getBool(_key) ?? false;
  }

  Future<void> markSeen() async {
    state = true;
    await ref.read(sharedPreferencesProvider).setBool(_key, true);
  }
}

class PreferredCurrencyNotifier extends Notifier<String> {
  static const _key = 'preferred_currency';

  @override
  String build() {
    final value = ref.read(sharedPreferencesProvider).getString(_key) ?? 'VND';
    setActiveCurrencyCode(value);
    return value;
  }

  Future<void> setCurrency(String value) async {
    state = value;
    setActiveCurrencyCode(value);
    await ref.read(sharedPreferencesProvider).setString(_key, value);
  }
}
