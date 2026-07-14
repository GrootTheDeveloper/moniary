import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'preferences_bootstrap.dart';

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  return appPreferences;
});

final onboardingSeenProvider = NotifierProvider<OnboardingSeenNotifier, bool>(
  OnboardingSeenNotifier.new,
);

final preferredLocaleProvider =
    NotifierProvider<PreferredLocaleNotifier, String>(
      PreferredLocaleNotifier.new,
    );

final preferredCurrencyProvider =
    NotifierProvider<PreferredCurrencyNotifier, String>(
      PreferredCurrencyNotifier.new,
    );

final mascotEnabledProvider = NotifierProvider<MascotEnabledNotifier, bool>(
  MascotEnabledNotifier.new,
);

final firstDayOfWeekProvider = NotifierProvider<FirstDayOfWeekNotifier, int>(
  FirstDayOfWeekNotifier.new,
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
    return ref.read(sharedPreferencesProvider).getString(_key) ?? 'VND';
  }

  Future<void> setCurrency(String value) async {
    state = value;
    await ref.read(sharedPreferencesProvider).setString(_key, value);
  }
}

class PreferredLocaleNotifier extends Notifier<String> {
  static const _key = 'preferred_locale';

  @override
  String build() {
    return ref.read(sharedPreferencesProvider).getString(_key) ?? 'vi';
  }

  Future<void> setLocale(String value) async {
    state = value;
    await ref.read(sharedPreferencesProvider).setString(_key, value);
  }
}

class MascotEnabledNotifier extends Notifier<bool> {
  static const _key = 'mascot_enabled';

  @override
  bool build() {
    return ref.read(sharedPreferencesProvider).getBool(_key) ?? true;
  }

  Future<void> setEnabled(bool value) async {
    state = value;
    await ref.read(sharedPreferencesProvider).setBool(_key, value);
  }
}

class FirstDayOfWeekNotifier extends Notifier<int> {
  static const _key = 'first_day_of_week';

  @override
  int build() {
    // 1 represents Monday (default), 7 represents Sunday
    return ref.read(sharedPreferencesProvider).getInt(_key) ?? 1;
  }

  Future<void> setFirstDayOfWeek(int value) async {
    state = value;
    await ref.read(sharedPreferencesProvider).setInt(_key, value);
  }
}
