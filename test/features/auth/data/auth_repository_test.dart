import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:moniary/core/constants/app_constants.dart';
import 'package:moniary/core/supabase/supabase_providers.dart';
import 'package:moniary/features/auth/data/auth_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class FakeSupabaseClient extends Fake implements SupabaseClient {}

void main() {
  test('signInAnonymously returns mock session in mock mode', () async {
    if (AppConstants.hasSupabaseConfig) {
      markTestSkipped('Mock mode test requires missing Supabase config.');
      return;
    }

    SharedPreferences.setMockInitialValues({});
    final repository = AuthRepository(FakeSupabaseClient());

    final session = await repository.signInAnonymously();

    expect(session?.user.id, 'mock-user-id');
  });

  test('signOut completes in mock mode', () async {
    if (AppConstants.hasSupabaseConfig) {
      markTestSkipped('Mock mode test requires missing Supabase config.');
      return;
    }

    SharedPreferences.setMockInitialValues({'mock_logged_in': true});
    final repository = AuthRepository(FakeSupabaseClient());

    await repository.signOut();
  });

  test('startGuestSession returns an in-memory guest session', () async {
    SharedPreferences.setMockInitialValues({});
    final repository = AuthRepository(FakeSupabaseClient());

    final session = await repository.startGuestSession();

    expect(session.user.id, 'mock-user-id');
  });

  test('legacy persisted guest flags do not restore a session', () async {
    if (AppConstants.hasSupabaseConfig) {
      markTestSkipped('Mock mode test requires missing Supabase config.');
      return;
    }

    SharedPreferences.setMockInitialValues({
      'guest_mode_enabled': true,
      'mock_logged_in': true,
    });
    final container = ProviderContainer();
    addTearDown(container.dispose);

    expect(container.read(currentSessionProvider), isNull);
    expect(container.read(guestModeEnabledProvider), isFalse);
  });

  test('mock Google sign-in creates a session only when selected', () async {
    if (AppConstants.hasSupabaseConfig) {
      markTestSkipped('Mock mode test requires missing Supabase config.');
      return;
    }

    final repository = AuthRepository(FakeSupabaseClient());

    final session = await repository.signInWithGoogle();

    expect(session?.user.id, 'mock-user-id');
  });

  test('linkEmailAccount reports mock profile update in mock mode', () async {
    if (AppConstants.hasSupabaseConfig) {
      markTestSkipped('Mock mode test requires missing Supabase config.');
      return;
    }

    SharedPreferences.setMockInitialValues({});
    final repository = AuthRepository(FakeSupabaseClient());

    final usesMockProfile = await repository.linkEmailAccount(
      email: 'bee@moniary.app',
      password: 'password123',
    );

    expect(usesMockProfile, isTrue);
  });

  test('linkGoogleAccount reports mock profile update in mock mode', () async {
    if (AppConstants.hasSupabaseConfig) {
      markTestSkipped('Mock mode test requires missing Supabase config.');
      return;
    }

    SharedPreferences.setMockInitialValues({});
    final repository = AuthRepository(FakeSupabaseClient());

    final usesMockProfile = await repository.linkGoogleAccount();

    expect(usesMockProfile, isTrue);
  });

  test(
    'linkFacebookAccount reports mock profile update in mock mode',
    () async {
      if (AppConstants.hasSupabaseConfig) {
        markTestSkipped('Mock mode test requires missing Supabase config.');
        return;
      }

      SharedPreferences.setMockInitialValues({});
      final repository = AuthRepository(FakeSupabaseClient());

      final usesMockProfile = await repository.linkFacebookAccount();

      expect(usesMockProfile, isTrue);
    },
  );

  test('mock Facebook sign-in creates a session only when selected', () async {
    if (AppConstants.hasSupabaseConfig) {
      markTestSkipped('Mock mode test requires missing Supabase config.');
      return;
    }

    final repository = AuthRepository(FakeSupabaseClient());

    final session = await repository.signInWithFacebook();

    expect(session?.user.id, 'mock-user-id');
  });

  test(
    'signUpWithEmail completes without a network call in mock mode',
    () async {
      if (AppConstants.hasSupabaseConfig) {
        markTestSkipped('Mock mode test requires missing Supabase config.');
        return;
      }

      final repository = AuthRepository(FakeSupabaseClient());

      await repository.signUpWithEmail(
        email: 'bee@moniary.app',
        password: 'password123',
      );
    },
  );

  test(
    'requestPasswordReset completes without a network call in mock mode',
    () async {
      if (AppConstants.hasSupabaseConfig) {
        markTestSkipped('Mock mode test requires missing Supabase config.');
        return;
      }

      final repository = AuthRepository(FakeSupabaseClient());

      await repository.requestPasswordReset('bee@moniary.app');
    },
  );

  test(
    'updatePassword completes without a network call in mock mode',
    () async {
      if (AppConstants.hasSupabaseConfig) {
        markTestSkipped('Mock mode test requires missing Supabase config.');
        return;
      }

      final repository = AuthRepository(FakeSupabaseClient());

      await repository.updatePassword('newPassword123');
    },
  );
}
