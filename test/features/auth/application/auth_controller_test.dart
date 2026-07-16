import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moniary/core/notifications/fcm_push_notification_service.dart';
import 'package:moniary/core/notifications/local_notification_service.dart';
import 'package:moniary/core/notifications/notification_providers.dart';
import 'package:moniary/core/preferences/preferences_providers.dart';
import 'package:moniary/core/supabase/supabase_providers.dart';
import 'package:moniary/core/supabase/app_exception.dart';
import 'package:moniary/features/auth/application/auth_controller.dart';
import 'package:moniary/features/auth/application/pending_email_link_controller.dart';
import 'package:moniary/features/auth/application/pending_google_link_controller.dart';
import 'package:moniary/features/auth/data/auth_repository.dart';
import 'package:moniary/features/auth/domain/email_account_link.dart';
import 'package:moniary/features/auth/domain/google_account_link.dart';
import 'package:moniary/features/notifications/data/repositories/notification_repository_impl.dart';
import 'package:moniary/features/notifications/domain/repositories/notification_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class _FakeSupabaseClient extends Fake implements SupabaseClient {}

class _FakeNotificationRepository extends Fake
    implements NotificationRepository {
  final unregisteredTokens = <String>[];

  @override
  Future<void> unregisterDevice(String token) async {
    unregisteredTokens.add(token);
  }
}

class _FakePushService extends FcmPushNotificationService {
  _FakePushService()
    : super(LocalNotificationService.instance, firebaseConfigured: false);

  var unregisterCount = 0;

  @override
  Future<void> unregisterCurrentToken({
    required Future<void> Function(String token) onToken,
  }) async {
    unregisterCount++;
    await onToken('device-token');
  }
}

class _FakeAuthRepository extends AuthRepository {
  _FakeAuthRepository({
    this.emailSession,
    this.signUpSession,
    this.emailLinkStatus = EmailAccountLinkStatus.confirmationRequired,
  }) : super(_FakeSupabaseClient());

  final Session? emailSession;
  final Session? signUpSession;
  final EmailAccountLinkStatus emailLinkStatus;

  var signOutCount = 0;
  var completeEmailLinkCount = 0;
  var completeGoogleLinkCount = 0;
  var cancelRecoveryCount = 0;
  String? anonymousCaptchaToken;
  String? emailCaptchaToken;
  String? signUpCaptchaToken;
  String? resetCaptchaToken;
  String? updatedPassword;

  @override
  Future<Session?> signInAnonymously({String? captchaToken}) async {
    anonymousCaptchaToken = captchaToken;
    return _session();
  }

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
    emailCaptchaToken = captchaToken;
    return emailSession;
  }

  @override
  Future<Session?> signUpWithEmail({
    required String email,
    required String password,
    String? captchaToken,
  }) async {
    signUpCaptchaToken = captchaToken;
    return signUpSession;
  }

  @override
  Future<void> requestPasswordReset(
    String email, {
    String? captchaToken,
  }) async {
    resetCaptchaToken = captchaToken;
  }

  @override
  Future<void> updatePassword(String password) async {
    updatedPassword = password;
  }

  @override
  Future<void> cancelPasswordRecovery() async {
    cancelRecoveryCount++;
  }

  @override
  Future<EmailAccountLinkStatus> beginEmailAccountLink({
    required String email,
  }) async {
    return emailLinkStatus;
  }

  @override
  Future<void> completeEmailAccountLink({required String password}) async {
    completeEmailLinkCount++;
    updatedPassword = password;
  }

  @override
  Future<GoogleAccountLinkStatus> beginGoogleAccountLink() async {
    return GoogleAccountLinkStatus.browserOpened;
  }

  @override
  Future<void> completeGoogleAccountLink() async {
    completeGoogleLinkCount++;
  }
}

Session _session({
  bool googleLinked = false,
  String? email,
  bool isAnonymous = false,
}) {
  final identities = googleLinked
      ? const [
          UserIdentity(
            id: 'google-identity-id',
            userId: 'user-id',
            identityData: {'email': 'bee@gmail.com'},
            identityId: 'google-subject-id',
            provider: 'google',
            createdAt: '2026-07-15T00:00:00Z',
            lastSignInAt: '2026-07-15T00:00:00Z',
          ),
        ]
      : const <UserIdentity>[];
  final user = User(
    id: 'user-id',
    appMetadata: const {},
    userMetadata: const {},
    aud: 'authenticated',
    email: email ?? (googleLinked ? 'bee@gmail.com' : null),
    identities: identities,
    createdAt: '2026-05-28T00:00:00Z',
    isAnonymous: isAnonymous,
  );
  return Session(
    accessToken: 'access-token',
    tokenType: 'bearer',
    expiresIn: 3600,
    user: user,
  );
}

void main() {
  test('pending account links only match their originating identity', () {
    const email = PendingEmailAccountLink(
      userId: 'user-id',
      email: 'bee@moniary.app',
    );
    const google = PendingGoogleAccountLink(userId: 'user-id');

    expect(
      email.matches(
        userId: 'user-id',
        email: 'BEE@MONIARY.APP',
        isAnonymous: false,
      ),
      isTrue,
    );
    expect(
      email.matches(
        userId: 'user-id',
        email: 'bee@moniary.app',
        isAnonymous: true,
      ),
      isFalse,
    );
    expect(google.matches(userId: 'user-id', hasGoogleIdentity: true), isTrue);
    expect(
      google.matches(userId: 'other-user', hasGoogleIdentity: true),
      isFalse,
    );
  });

  test(
    'auth actions forward CAPTCHA tokens without creating mock state',
    () async {
      final repository = _FakeAuthRepository(emailSession: _session());
      final container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(repository),
          currentSessionProvider.overrideWithValue(null),
        ],
      );
      addTearDown(container.dispose);

      await container
          .read(authControllerProvider.notifier)
          .signInAnonymously(captchaToken: 'anonymous-token');
      await container
          .read(authControllerProvider.notifier)
          .signInWithEmail(
            email: 'bee@moniary.app',
            password: 'password123',
            captchaToken: 'email-token',
          );
      await container
          .read(authControllerProvider.notifier)
          .requestPasswordReset('bee@moniary.app', captchaToken: 'reset-token');

      expect(repository.anonymousCaptchaToken, 'anonymous-token');
      expect(repository.emailCaptchaToken, 'email-token');
      expect(repository.resetCaptchaToken, 'reset-token');
      expect(container.read(authControllerProvider).hasError, isFalse);
    },
  );

  test(
    'sign-up reports whether Supabase returned an immediate session',
    () async {
      final immediateRepository = _FakeAuthRepository(
        signUpSession: _session(),
      );
      final immediateContainer = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(immediateRepository),
          currentSessionProvider.overrideWithValue(null),
        ],
      );
      addTearDown(immediateContainer.dispose);

      final immediateRequiresConfirmation = await immediateContainer
          .read(authControllerProvider.notifier)
          .signUpWithEmail(
            email: 'bee@moniary.app',
            password: 'password123',
            captchaToken: 'signup-token',
          );

      expect(immediateRequiresConfirmation, isFalse);
      expect(immediateRepository.signUpCaptchaToken, 'signup-token');

      final confirmationRepository = _FakeAuthRepository();
      final confirmationContainer = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(confirmationRepository),
          currentSessionProvider.overrideWithValue(null),
        ],
      );
      addTearDown(confirmationContainer.dispose);

      final requiresConfirmation = await confirmationContainer
          .read(authControllerProvider.notifier)
          .signUpWithEmail(
            email: 'bee@moniary.app',
            password: 'password123',
            captchaToken: 'signup-token',
          );
      expect(requiresConfirmation, isTrue);
    },
  );

  test(
    'sign-out unregisters the push token before ending the session',
    () async {
      final repository = _FakeAuthRepository();
      final notificationRepository = _FakeNotificationRepository();
      final pushService = _FakePushService();
      final container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(repository),
          currentSessionProvider.overrideWithValue(
            _session(email: 'Bee@Moniary.app'),
          ),
          notificationRepositoryProvider.overrideWithValue(
            notificationRepository,
          ),
          fcmPushNotificationServiceProvider.overrideWithValue(pushService),
        ],
      );
      addTearDown(container.dispose);

      await container.read(authControllerProvider.notifier).signOut();

      expect(pushService.unregisterCount, 1);
      expect(notificationRepository.unregisteredTokens, ['device-token']);
      expect(repository.signOutCount, 1);
    },
  );

  test(
    'email account upgrade refuses a pending link from another session',
    () async {
      SharedPreferences.setMockInitialValues({
        'pending_email_account_link_user_id': 'user-id',
        'pending_email_account_link_email': 'bee@moniary.app',
      });
      final preferences = await SharedPreferences.getInstance();
      final repository = _FakeAuthRepository();
      final container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(repository),
          currentSessionProvider.overrideWithValue(
            _session(email: 'other@moniary.app'),
          ),
          sharedPreferencesProvider.overrideWithValue(preferences),
        ],
      );
      addTearDown(container.dispose);

      await expectLater(
        container
            .read(authControllerProvider.notifier)
            .completeEmailAccountLink(password: 'password123'),
        throwsA(
          isA<AppException>().having(
            (error) => error.code,
            'code',
            'AUTH_LINK_EMAIL_SESSION_MISMATCH',
          ),
        ),
      );
      expect(repository.completeEmailLinkCount, 0);
      expect(container.read(pendingEmailAccountLinkProvider), isNotNull);
    },
  );

  test(
    'email account upgrade persists then clears its pending state',
    () async {
      SharedPreferences.setMockInitialValues({});
      final preferences = await SharedPreferences.getInstance();
      final repository = _FakeAuthRepository(
        emailLinkStatus: EmailAccountLinkStatus.readyToSetPassword,
      );
      final container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(repository),
          currentSessionProvider.overrideWithValue(
            _session(email: 'Bee@Moniary.app'),
          ),
          sharedPreferencesProvider.overrideWithValue(preferences),
        ],
      );
      addTearDown(container.dispose);

      final status = await container
          .read(authControllerProvider.notifier)
          .beginEmailAccountLink(email: 'Bee@Moniary.app');
      expect(status, EmailAccountLinkStatus.readyToSetPassword);
      expect(
        container.read(pendingEmailAccountLinkProvider)?.email,
        'bee@moniary.app',
      );

      await container
          .read(authControllerProvider.notifier)
          .completeEmailAccountLink(password: 'password123');
      expect(repository.completeEmailLinkCount, 1);
      expect(container.read(pendingEmailAccountLinkProvider), isNull);
    },
  );

  test(
    'Google upgrade completes only after the linked identity returns',
    () async {
      SharedPreferences.setMockInitialValues({
        'pending_google_account_link_user_id': 'user-id',
      });
      final preferences = await SharedPreferences.getInstance();
      final repository = _FakeAuthRepository();
      final container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(repository),
          currentSessionProvider.overrideWithValue(
            _session(googleLinked: true),
          ),
          sharedPreferencesProvider.overrideWithValue(preferences),
        ],
      );
      addTearDown(container.dispose);

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

  test(
    'password recovery completes or cancels the real auth session',
    () async {
      final repository = _FakeAuthRepository();
      final container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(repository),
          currentSessionProvider.overrideWithValue(null),
        ],
      );
      addTearDown(container.dispose);

      await container
          .read(authControllerProvider.notifier)
          .completePasswordRecovery('new-password-123');
      await container
          .read(authControllerProvider.notifier)
          .cancelPasswordRecovery();

      expect(repository.updatedPassword, 'new-password-123');
      expect(repository.cancelRecoveryCount, 1);
    },
  );
}
