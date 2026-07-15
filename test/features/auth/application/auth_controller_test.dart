import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moniary/core/constants/app_constants.dart';
import 'package:moniary/core/preferences/preferences_providers.dart';
import 'package:moniary/core/supabase/supabase_providers.dart';
import 'package:moniary/features/auth/application/auth_controller.dart';
import 'package:moniary/features/auth/data/auth_repository.dart';
import 'package:moniary/features/auth/domain/email_account_link.dart';
import 'package:moniary/features/auth/application/pending_email_link_controller.dart';
import 'package:moniary/features/auth/application/pending_facebook_link_controller.dart';
import 'package:moniary/features/auth/application/pending_google_link_controller.dart';
import 'package:moniary/features/auth/domain/facebook_account_link.dart';
import 'package:moniary/features/auth/domain/google_account_link.dart';
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

Session _googleLinkedSession() {
  const identity = UserIdentity(
    id: 'google-identity-id',
    userId: 'mock-user-id',
    identityData: {'email': 'bee@gmail.com'},
    identityId: 'google-subject-id',
    provider: 'google',
    createdAt: '2026-07-15T00:00:00Z',
    lastSignInAt: '2026-07-15T00:00:00Z',
  );
  const user = User(
    id: 'mock-user-id',
    appMetadata: {'provider': 'google'},
    userMetadata: {},
    aud: 'authenticated',
    email: 'bee@gmail.com',
    identities: [identity],
    createdAt: '2026-05-28T00:00:00Z',
  );
  return Session(
    accessToken: 'mockAccessToken',
    tokenType: 'bearer',
    expiresIn: 3600,
    user: user,
  );
}

Session _facebookLinkedSession() {
  const identity = UserIdentity(
    id: 'facebook-identity-id',
    userId: 'mock-user-id',
    identityData: {'email': 'bee@facebook.com'},
    identityId: 'facebook-subject-id',
    provider: 'facebook',
    createdAt: '2026-07-15T00:00:00Z',
    lastSignInAt: '2026-07-15T00:00:00Z',
  );
  const user = User(
    id: 'mock-user-id',
    appMetadata: {'provider': 'facebook'},
    userMetadata: {},
    aud: 'authenticated',
    email: 'bee@facebook.com',
    identities: [identity],
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
    this.emailLinkStatus = EmailAccountLinkStatus.confirmationRequired,
    this.emailLinkUsesMockProfile = false,
    this.googleLinkStatus = GoogleAccountLinkStatus.browserOpened,
    this.facebookLinkStatus = FacebookAccountLinkStatus.browserOpened,
  }) : super(null, useMockData: true);

  final Session? emailSession;
  final Session? signUpSession;
  final Session? googleSession;
  final Session? facebookSession;
  final bool opensRecoveryLocally;
  final EmailAccountLinkStatus emailLinkStatus;
  final bool emailLinkUsesMockProfile;
  final GoogleAccountLinkStatus googleLinkStatus;
  final FacebookAccountLinkStatus facebookLinkStatus;
  var signOutCount = 0;
  var cancelPasswordRecoveryCount = 0;
  String? updatedPassword;
  String? linkedEmail;
  String? linkedEmailPassword;
  String? emailSignInCaptchaToken;
  String? emailSignUpCaptchaToken;
  String? passwordResetCaptchaToken;
  var completeGoogleLinkCount = 0;
  var completeFacebookLinkCount = 0;

  @override
  Future<void> signOut() async {
    signOutCount++;
  }

  @override
  Future<Session?> signInWithEmail({
    required String email,
    required String password,
    String? captchaToken,
  }) async {
    emailSignInCaptchaToken = captchaToken;
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
    String? captchaToken,
  }) async {
    emailSignUpCaptchaToken = captchaToken;
    return signUpSession;
  }

  @override
  Future<Session?> signInWithFacebook() async {
    return facebookSession;
  }

  @override
  Future<bool> requestPasswordReset(
    String email, {
    String? captchaToken,
  }) async {
    passwordResetCaptchaToken = captchaToken;
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

  @override
  Future<EmailAccountLinkStatus> beginEmailAccountLink({
    required String email,
  }) async {
    linkedEmail = email;
    return emailLinkStatus;
  }

  @override
  Future<bool> completeEmailAccountLink({required String password}) async {
    linkedEmailPassword = password;
    return emailLinkUsesMockProfile;
  }

  @override
  Future<GoogleAccountLinkStatus> beginGoogleAccountLink() async {
    return googleLinkStatus;
  }

  @override
  Future<bool> completeGoogleAccountLink() async {
    completeGoogleLinkCount++;
    return false;
  }

  @override
  Future<FacebookAccountLinkStatus> beginFacebookAccountLink() async {
    return facebookLinkStatus;
  }

  @override
  Future<bool> completeFacebookAccountLink() async {
    completeFacebookLinkCount++;
    return false;
  }
}

void main() {
  test('pending email link only matches the originating confirmed user', () {
    const pending = PendingEmailAccountLink(
      userId: 'anonymous-user-id',
      email: 'bee@moniary.app',
    );

    expect(
      pending.matches(
        userId: 'anonymous-user-id',
        email: 'BEE@MONIARY.APP',
        isAnonymous: false,
      ),
      isTrue,
    );
    expect(
      pending.matches(
        userId: 'different-user-id',
        email: 'bee@moniary.app',
        isAnonymous: false,
      ),
      isFalse,
    );
    expect(
      pending.matches(
        userId: 'anonymous-user-id',
        email: 'bee@moniary.app',
        isAnonymous: true,
      ),
      isFalse,
    );
  });

  test('pending Google link requires the originating user and identity', () {
    const pending = PendingGoogleAccountLink(userId: 'anonymous-user-id');

    expect(
      pending.matches(userId: 'anonymous-user-id', hasGoogleIdentity: true),
      isTrue,
    );
    expect(
      pending.matches(userId: 'different-user-id', hasGoogleIdentity: true),
      isFalse,
    );
    expect(
      pending.matches(userId: 'anonymous-user-id', hasGoogleIdentity: false),
      isFalse,
    );
  });

  test('pending Facebook link requires the originating user and identity', () {
    const pending = PendingFacebookAccountLink(userId: 'anonymous-user-id');

    expect(
      pending.matches(userId: 'anonymous-user-id', hasFacebookIdentity: true),
      isTrue,
    );
    expect(
      pending.matches(userId: 'different-user-id', hasFacebookIdentity: true),
      isFalse,
    );
    expect(
      pending.matches(userId: 'anonymous-user-id', hasFacebookIdentity: false),
      isFalse,
    );
  });

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
        .signInWithEmail(
          email: 'bee@moniary.app',
          password: 'password123',
          captchaToken: 'email-sign-in-token',
        );

    expect(repository.emailSignInCaptchaToken, 'email-sign-in-token');
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
        .signUpWithEmail(
          email: 'bee@moniary.app',
          password: 'password123',
          captchaToken: 'email-sign-up-token',
        );

    expect(requiresConfirmation, isFalse);
    expect(repository.emailSignUpCaptchaToken, 'email-sign-up-token');
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
          .requestPasswordReset(
            'bee@moniary.app',
            captchaToken: 'password-reset-token',
          );

      expect(repository.passwordResetCaptchaToken, 'password-reset-token');
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

  test('Facebook linking completes immediately in mock mode', () async {
    final repository = FakeAuthRepository(
      facebookLinkStatus: FacebookAccountLinkStatus.completed,
    );
    final container = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(repository),
        supabaseClientProvider.overrideWithValue(_FakeSupabaseClient()),
      ],
    );
    addTearDown(container.dispose);
    container.read(mockSessionProvider.notifier).setSession(_mockSession());

    final status = await container
        .read(authControllerProvider.notifier)
        .beginFacebookAccountLink();

    expect(status, FacebookAccountLinkStatus.completed);
    expect(container.read(authControllerProvider).isLoading, isFalse);
    expect(container.read(authControllerProvider).hasError, isFalse);
    expect(
      container.read(accountLinkNoticeProvider),
      AccountLinkNotice.facebookSuccess,
    );
  });

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

  test(
    'email linking persists the matching user and completes later',
    () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final repository = FakeAuthRepository(
        emailLinkStatus: EmailAccountLinkStatus.readyToSetPassword,
        emailLinkUsesMockProfile: true,
      );
      final container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(repository),
          sharedPreferencesProvider.overrideWithValue(prefs),
          supabaseClientProvider.overrideWithValue(_FakeSupabaseClient()),
        ],
      );
      addTearDown(container.dispose);
      container.read(mockSessionProvider.notifier).setSession(_mockSession());

      final result = await container
          .read(authControllerProvider.notifier)
          .beginEmailAccountLink(email: 'Bee@Moniary.app');

      expect(result, EmailAccountLinkStatus.readyToSetPassword);
      expect(repository.linkedEmail, 'Bee@Moniary.app');
      expect(
        container.read(pendingEmailAccountLinkProvider)?.email,
        'bee@moniary.app',
      );

      await container
          .read(authControllerProvider.notifier)
          .completeEmailAccountLink(password: 'password123');

      expect(repository.linkedEmailPassword, 'password123');
      expect(container.read(pendingEmailAccountLinkProvider), isNull);
      expect(prefs.getString('pending_email_account_link_email'), isNull);
    },
  );

  test(
    'Google linking waits for callback identity before completion',
    () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final repository = FakeAuthRepository();
      final container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(repository),
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
      );
      addTearDown(container.dispose);
      container.read(mockSessionProvider.notifier).setSession(_mockSession());

      final status = await container
          .read(authControllerProvider.notifier)
          .beginGoogleAccountLink();

      expect(status, GoogleAccountLinkStatus.browserOpened);
      expect(
        container.read(pendingGoogleAccountLinkProvider)?.userId,
        'mock-user-id',
      );
      expect(repository.completeGoogleLinkCount, 0);

      container
          .read(mockSessionProvider.notifier)
          .setSession(_googleLinkedSession());
      await container
          .read(authControllerProvider.notifier)
          .completePendingGoogleAccountLink();

      expect(repository.completeGoogleLinkCount, 1);
      expect(container.read(pendingGoogleAccountLinkProvider), isNull);
      expect(
        container.read(accountLinkNoticeProvider),
        AccountLinkNotice.googleSuccess,
      );
    },
  );

  test('Google linking completes immediately in mock mode', () async {
    final repository = FakeAuthRepository(
      googleLinkStatus: GoogleAccountLinkStatus.completed,
    );
    final container = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(repository),
        supabaseClientProvider.overrideWithValue(_FakeSupabaseClient()),
      ],
    );
    addTearDown(container.dispose);
    container.read(mockSessionProvider.notifier).setSession(_mockSession());

    final status = await container
        .read(authControllerProvider.notifier)
        .beginGoogleAccountLink();

    expect(status, GoogleAccountLinkStatus.completed);
    expect(
      container.read(accountLinkNoticeProvider),
      AccountLinkNotice.googleSuccess,
    );
  });

  test(
    'Facebook linking waits for callback identity before completion',
    () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final repository = FakeAuthRepository();
      final container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(repository),
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
      );
      addTearDown(container.dispose);
      container.read(mockSessionProvider.notifier).setSession(_mockSession());

      final status = await container
          .read(authControllerProvider.notifier)
          .beginFacebookAccountLink();

      expect(status, FacebookAccountLinkStatus.browserOpened);
      expect(
        container.read(pendingFacebookAccountLinkProvider)?.userId,
        'mock-user-id',
      );
      expect(repository.completeFacebookLinkCount, 0);

      container
          .read(mockSessionProvider.notifier)
          .setSession(_facebookLinkedSession());
      await container
          .read(authControllerProvider.notifier)
          .completePendingFacebookAccountLink();

      expect(repository.completeFacebookLinkCount, 1);
      expect(container.read(pendingFacebookAccountLinkProvider), isNull);
      expect(
        container.read(accountLinkNoticeProvider),
        AccountLinkNotice.facebookSuccess,
      );
    },
  );
}
