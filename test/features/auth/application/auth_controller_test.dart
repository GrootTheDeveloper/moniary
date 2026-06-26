import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moniary/core/constants/app_constants.dart';
import 'package:moniary/core/preferences/preferences_providers.dart';
import 'package:moniary/core/supabase/supabase_providers.dart';
import 'package:moniary/features/auth/application/auth_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('signInAnonymously completes controller state in mock mode', () async {
    if (AppConstants.hasSupabaseConfig) {
      markTestSkipped('Mock mode test requires missing Supabase config.');
      return;
    }

    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final container = ProviderContainer(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
    );
    addTearDown(container.dispose);

    await container.read(authControllerProvider.notifier).signInAnonymously();

    final authState = container.read(authControllerProvider);
    expect(authState.isLoading, isFalse);
    expect(authState.hasError, isFalse);
    expect(prefs.getBool('mock_logged_in'), isNull);
    expect(container.read(mockSessionProvider), isNotNull);
  });

  test('startGuestSession sets guest session state', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final container = ProviderContainer(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
    );
    addTearDown(container.dispose);

    await container.read(authControllerProvider.notifier).startGuestSession();

    final authState = container.read(authControllerProvider);
    expect(authState.isLoading, isFalse);
    expect(authState.hasError, isFalse);
    expect(prefs.getBool('guest_mode_enabled'), isNull);
    expect(container.read(mockSessionProvider)?.user.id, 'mock-user-id');
  });
}
