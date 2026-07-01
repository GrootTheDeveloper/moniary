import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moniary/core/constants/app_constants.dart';
import 'package:moniary/core/preferences/preferences_providers.dart';
import 'package:moniary/core/supabase/supabase_providers.dart';
import 'package:moniary/features/auth/application/auth_controller.dart';
import 'package:moniary/features/auth/data/auth_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Session _mockSession() {
  const user = User(
    id: 'mock-user-id',
    appMetadata: {},
    userMetadata: {},
    aud: 'authenticated',
    createdAt: '2026-05-28T00:00:00Z',
  );
  return Session(
    accessToken: 'mockAccessToken',
    tokenType: 'bearer',
    expiresIn: 3600,
    user: user,
  );
}

class FakeAuthRepository extends AuthRepository {
  FakeAuthRepository({this.emailSession, this.googleSession, this.appleSession})
    : super(null, useMockData: true);

  final Session? emailSession;
  final Session? googleSession;
  final Session? appleSession;
  var signOutCount = 0;

  @override
  Future<void> signOut() async {
    signOutCount++;
  }

  @override
  Future<Session?> signInWithEmail({
    required String email,
    required String password,
  }) async {
    return emailSession;
  }

  @override
  Future<Session?> signInWithGoogle() async {
    return googleSession;
  }

  @override
  Future<Session?> signInWithApple() async {
    return appleSession;
  }
}

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

  test('signInWithEmail applies returned mock session', () async {
    final repository = FakeAuthRepository(emailSession: _mockSession());
    final container = ProviderContainer(
      overrides: [authRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);

    await container
        .read(authControllerProvider.notifier)
        .signInWithEmail(email: 'bee@moniary.app', password: 'password123');

    expect(container.read(authControllerProvider).isLoading, isFalse);
    expect(container.read(authControllerProvider).hasError, isFalse);
    expect(container.read(mockSessionProvider)?.user.id, 'mock-user-id');
  });

  test('signInWithGoogle applies returned mock session', () async {
    final repository = FakeAuthRepository(googleSession: _mockSession());
    final container = ProviderContainer(
      overrides: [authRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);

    await container.read(authControllerProvider.notifier).signInWithGoogle();

    expect(repository.signOutCount, 1);
    expect(container.read(authControllerProvider).isLoading, isFalse);
    expect(container.read(authControllerProvider).hasError, isFalse);
    expect(container.read(mockSessionProvider)?.user.id, 'mock-user-id');
  });

  test('signInWithApple applies returned mock session', () async {
    final repository = FakeAuthRepository(appleSession: _mockSession());
    final container = ProviderContainer(
      overrides: [authRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);

    await container.read(authControllerProvider.notifier).signInWithApple();

    expect(container.read(authControllerProvider).isLoading, isFalse);
    expect(container.read(authControllerProvider).hasError, isFalse);
    expect(container.read(mockSessionProvider)?.user.id, 'mock-user-id');
  });

  test(
    'signInWithGoogle stays ready when OAuth returns no immediate session',
    () async {
      final repository = FakeAuthRepository();
      final container = ProviderContainer(
        overrides: [authRepositoryProvider.overrideWithValue(repository)],
      );
      addTearDown(container.dispose);

      await container.read(authControllerProvider.notifier).signInWithGoogle();

      expect(repository.signOutCount, 1);
      expect(container.read(authControllerProvider).isLoading, isFalse);
      expect(container.read(authControllerProvider).hasError, isFalse);
      expect(container.read(mockSessionProvider), isNull);
    },
  );
}
