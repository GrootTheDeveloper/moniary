import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moniary/core/constants/app_constants.dart';
import 'package:moniary/core/preferences/preferences_providers.dart';
import 'package:moniary/core/supabase/supabase_providers.dart';
import 'package:moniary/features/auth/application/auth_controller.dart';
import 'package:moniary/features/auth/data/auth_repository.dart';
import 'package:moniary/features/profile/application/profile_setup_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class _FakeSupabaseClient extends Fake implements SupabaseClient {}

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
  FakeAuthRepository({
    this.emailSession,
    this.signUpSession,
    this.googleSession,
    this.facebookSession,
    this.opensRecoveryLocally = false,
  }) : super(null, useMockData: true);

  final Session? emailSession;
  final Session? signUpSession;
  final Session? googleSession;
  final Session? facebookSession;
  final bool opensRecoveryLocally;
  var signOutCount = 0;
  var cancelPasswordRecoveryCount = 0;
  String? updatedPassword;

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
  Future<Session?> signUpWithEmail({
    required String email,
    required String password,
  }) async {
    return signUpSession;
  }

  @override
  Future<Session?> signInWithFacebook() async {
    return facebookSession;
  }

  @override
  Future<bool> requestPasswordReset(String email) async {
    return opensRecoveryLocally;
  }

  @override
  Future<void> updatePassword(String password) async {
    updatedPassword = password;
  }

  @override
  Future<void> cancelPasswordRecovery() async {
    cancelPasswordRecoveryCount++;
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
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        supabaseClientProvider.overrideWithValue(_FakeSupabaseClient()),
      ],
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
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        supabaseClientProvider.overrideWithValue(_FakeSupabaseClient()),
      ],
    );
    addTearDown(container.dispose);

    await container.read(authControllerProvider.notifier).startGuestSession();

    final authState = container.read(authControllerProvider);
    expect(authState.isLoading, isFalse);
    expect(authState.hasError, isFalse);
    expect(prefs.getBool('guest_mode_enabled'), isNull);
    expect(container.read(mockSessionProvider)?.user.id, 'mock-user-id');
  });

  test('startDemoSession seeds a ready mock profile', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        supabaseClientProvider.overrideWithValue(_FakeSupabaseClient()),
      ],
    );
    addTearDown(container.dispose);

    await container.read(authControllerProvider.notifier).startDemoSession();

    final authState = container.read(authControllerProvider);
    final profile = await container.read(currentProfileProvider.future);
    expect(authState.isLoading, isFalse);
    expect(authState.hasError, isFalse);
    expect(container.read(mockSessionProvider)?.user.id, 'mock-user-id');
    expect(profile?.fullName, 'Minh Anh');
    expect(profile?.needsSetup, isFalse);
    expect(profile?.needsSurvey, isFalse);
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

    expect(repository.signOutCount, 0);
    expect(container.read(authControllerProvider).isLoading, isFalse);
    expect(container.read(authControllerProvider).hasError, isFalse);
    expect(container.read(mockSessionProvider)?.user.id, 'mock-user-id');
  });

  test('signInWithFacebook applies returned mock session', () async {
    final repository = FakeAuthRepository(facebookSession: _mockSession());
    final container = ProviderContainer(
      overrides: [authRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);

    await container.read(authControllerProvider.notifier).signInWithFacebook();

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

      expect(repository.signOutCount, 0);
      expect(container.read(authControllerProvider).isLoading, isFalse);
      expect(container.read(authControllerProvider).hasError, isFalse);
      expect(container.read(mockSessionProvider), isNull);
    },
  );

  test('signUpWithEmail applies an immediate session', () async {
    final repository = FakeAuthRepository(signUpSession: _mockSession());
    final container = ProviderContainer(
      overrides: [authRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);

    final requiresConfirmation = await container
        .read(authControllerProvider.notifier)
        .signUpWithEmail(email: 'bee@moniary.app', password: 'password123');

    expect(requiresConfirmation, isFalse);
    expect(container.read(authControllerProvider).hasError, isFalse);
    expect(container.read(mockSessionProvider)?.user.id, 'mock-user-id');
  });

  test('signUpWithEmail reports when confirmation is required', () async {
    final repository = FakeAuthRepository();
    final container = ProviderContainer(
      overrides: [authRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);

    final requiresConfirmation = await container
        .read(authControllerProvider.notifier)
        .signUpWithEmail(email: 'bee@moniary.app', password: 'password123');

    expect(requiresConfirmation, isTrue);
    expect(container.read(authControllerProvider).hasError, isFalse);
    expect(container.read(mockSessionProvider), isNull);
  });

  test(
    'requestPasswordReset completes controller state in mock mode',
    () async {
      final repository = FakeAuthRepository();
      final container = ProviderContainer(
        overrides: [authRepositoryProvider.overrideWithValue(repository)],
      );
      addTearDown(container.dispose);

      await container
          .read(authControllerProvider.notifier)
          .requestPasswordReset('bee@moniary.app');

      expect(container.read(authControllerProvider).isLoading, isFalse);
      expect(container.read(authControllerProvider).hasError, isFalse);
    },
  );

  test('updatePassword completes controller state in mock mode', () async {
    final repository = FakeAuthRepository();
    final container = ProviderContainer(
      overrides: [authRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);

    await container
        .read(authControllerProvider.notifier)
        .updatePassword('newPassword123');

    expect(container.read(authControllerProvider).isLoading, isFalse);
    expect(container.read(authControllerProvider).hasError, isFalse);
  });

  test(
    'linkFacebookAccount reports mock profile update in mock mode',
    () async {
      final repository = FakeAuthRepository();
      final container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(repository),
          supabaseClientProvider.overrideWithValue(_FakeSupabaseClient()),
        ],
      );
      addTearDown(container.dispose);

      await container
          .read(authControllerProvider.notifier)
          .linkFacebookAccount();

      expect(container.read(authControllerProvider).isLoading, isFalse);
      expect(container.read(authControllerProvider).hasError, isFalse);
    },
  );

  test('mock repository supports every direct and social auth path', () async {
    final repository = AuthRepository(null, useMockData: true);

    expect(
      (await repository.signInWithEmail(
        email: 'bee@moniary.app',
        password: 'password123',
      ))?.user.id,
      'mock-user-id',
    );
    expect(
      (await repository.signUpWithEmail(
        email: 'bee@moniary.app',
        password: 'password123',
      ))?.user.id,
      'mock-user-id',
    );
    expect((await repository.signInWithGoogle())?.user.id, 'mock-user-id');
    expect((await repository.signInWithFacebook())?.user.id, 'mock-user-id');
  });

  test('requestPasswordReset reports mock recovery navigation', () async {
    final repository = FakeAuthRepository(opensRecoveryLocally: true);
    final container = ProviderContainer(
      overrides: [authRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);

    final opensRecoveryLocally = await container
        .read(authControllerProvider.notifier)
        .requestPasswordReset('bee@moniary.app');

    expect(opensRecoveryLocally, isTrue);
    expect(container.read(authControllerProvider).hasError, isFalse);
  });

  test(
    'completePasswordRecovery updates password and clears mock session',
    () async {
      final repository = FakeAuthRepository();
      final container = ProviderContainer(
        overrides: [authRepositoryProvider.overrideWithValue(repository)],
      );
      addTearDown(container.dispose);
      container.read(mockSessionProvider.notifier).setSession(_mockSession());

      await container
          .read(authControllerProvider.notifier)
          .completePasswordRecovery('new-password-123');

      expect(repository.updatedPassword, 'new-password-123');
      expect(container.read(mockSessionProvider), isNull);
      expect(container.read(authControllerProvider).hasError, isFalse);
    },
  );

  test('cancelPasswordRecovery clears recovery session', () async {
    final repository = FakeAuthRepository();
    final container = ProviderContainer(
      overrides: [authRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);
    container.read(mockSessionProvider.notifier).setSession(_mockSession());

    await container
        .read(authControllerProvider.notifier)
        .cancelPasswordRecovery();

    expect(repository.cancelPasswordRecoveryCount, 1);
    expect(container.read(mockSessionProvider), isNull);
  });
}
