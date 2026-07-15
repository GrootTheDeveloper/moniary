import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/supabase/app_exception.dart';
import '../../../core/supabase/supabase_providers.dart';
import '../../../shared/utils/app_logger.dart';
import '../data/auth_repository.dart';
import '../domain/email_account_link.dart';
import '../domain/google_account_link.dart';
import 'pending_email_link_controller.dart';
import 'pending_google_link_controller.dart';
import '../../profile/data/profile_repository.dart';
import '../../profile/application/profile_setup_controller.dart';

final authControllerProvider = AsyncNotifierProvider<AuthController, void>(
  AuthController.new,
);

class AuthController extends AsyncNotifier<void> {
  bool _isProcessing = false;

  @override
  Future<void> build() async {
    ref.listen(currentSessionProvider, (previous, next) {
      if (next != null) {
        _isProcessing = false;
        state = const AsyncData(null);
      }
    });

    ref.onDispose(() {
      _isProcessing = false;
    });
  }

  Future<void> signInAnonymously({String? captchaToken}) async {
    if (_isProcessing) return;
    _isProcessing = true;
    state = const AsyncLoading();
    try {
      final session = await ref
          .read(authRepositoryProvider)
          .signInAnonymously(captchaToken: captchaToken);

      _applySignedInSession(session);
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    } finally {
      _isProcessing = false;
    }
  }

  Future<void> startGuestSession() async {
    if (_isProcessing) return;
    _isProcessing = true;
    state = const AsyncLoading();
    try {
      final mockSession = await ref
          .read(authRepositoryProvider)
          .startGuestSession();
      ref.read(mockSessionProvider.notifier).setSession(mockSession);
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    } finally {
      _isProcessing = false;
    }
  }

  Future<void> startDemoSession() async {
    if (_isProcessing) return;
    _isProcessing = true;
    state = const AsyncLoading();
    try {
      final mockSession = await ref
          .read(authRepositoryProvider)
          .startGuestSession();
      ref.read(mockSessionProvider.notifier).setSession(mockSession);

      final profileRepository = ref.read(profileRepositoryProvider);
      await profileRepository.upsertProfile(
        fullName: 'Minh Anh',
        username: 'minhanh',
        timezone: AppConstants.defaultTimezone,
      );
      await profileRepository.completeSurvey(
        occupation: 'demo',
        preferredCurrency: 'VND',
      );

      ref.invalidate(currentProfileProvider);
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    } finally {
      _isProcessing = false;
    }
  }

  Future<void> signOut() async {
    if (_isProcessing) return;
    _isProcessing = true;
    state = const AsyncLoading();
    try {
      await ref.read(authRepositoryProvider).signOut();
      ref.read(mockSessionProvider.notifier).setSession(null);
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    } finally {
      _isProcessing = false;
    }
  }

  Future<EmailAccountLinkStatus> beginEmailAccountLink({
    required String email,
  }) async {
    if (_isProcessing) {
      return EmailAccountLinkStatus.confirmationRequired;
    }
    _isProcessing = true;
    state = const AsyncLoading();
    try {
      final session = ref.read(currentSessionProvider);
      if (session == null) {
        throw const AppException('errorNotLoggedIn', code: 'AUTH_REQUIRED');
      }
      final result = await ref
          .read(authRepositoryProvider)
          .beginEmailAccountLink(email: email);
      await ref
          .read(pendingEmailAccountLinkProvider.notifier)
          .save(userId: session.user.id, email: email);
      state = const AsyncData(null);
      return result;
    } catch (e, st) {
      AppLogger.error('beginEmailAccountLink failed', e, st);
      state = AsyncError(e, st);
      rethrow;
    } finally {
      _isProcessing = false;
    }
  }

  Future<void> completeEmailAccountLink({required String password}) async {
    if (_isProcessing) return;
    _isProcessing = true;
    state = const AsyncLoading();
    try {
      final pendingLink = ref.read(pendingEmailAccountLinkProvider);
      if (pendingLink == null) {
        throw const AppException(
          'Email account linking is not pending',
          code: 'AUTH_LINK_EMAIL_NOT_PENDING',
        );
      }
      final usesMockProfile = await ref
          .read(authRepositoryProvider)
          .completeEmailAccountLink(password: password);
      if (usesMockProfile) {
        ref
            .read(profileRepositoryProvider)
            .setMockEmailAndProvider(
              email: pendingLink.email,
              loginProvider: 'email',
            );
      }
      await ref.read(pendingEmailAccountLinkProvider.notifier).clear();
      ref.invalidate(currentProfileProvider);
      state = const AsyncData(null);
    } catch (e, st) {
      AppLogger.error('completeEmailAccountLink failed', e, st);
      state = AsyncError(e, st);
      rethrow;
    } finally {
      _isProcessing = false;
    }
  }

  Future<GoogleAccountLinkStatus> beginGoogleAccountLink() async {
    if (_isProcessing) return GoogleAccountLinkStatus.browserOpened;
    _isProcessing = true;
    state = const AsyncLoading();
    try {
      final session = ref.read(currentSessionProvider);
      if (session == null) {
        throw const AppException('errorNotLoggedIn', code: 'AUTH_REQUIRED');
      }
      final result = await ref
          .read(authRepositoryProvider)
          .beginGoogleAccountLink();
      if (result == GoogleAccountLinkStatus.completed) {
        ref
            .read(profileRepositoryProvider)
            .setMockEmailAndProvider(
              email: 'mock-google@gmail.com',
              loginProvider: 'google',
            );
        ref.invalidate(currentProfileProvider);
        ref
            .read(accountLinkNoticeProvider.notifier)
            .show(AccountLinkNotice.googleSuccess);
      } else {
        await ref
            .read(pendingGoogleAccountLinkProvider.notifier)
            .save(session.user.id);
      }
      state = const AsyncData(null);
      return result;
    } catch (e, st) {
      AppLogger.error('beginGoogleAccountLink failed', e, st);
      state = AsyncError(e, st);
      rethrow;
    } finally {
      _isProcessing = false;
    }
  }

  Future<void> completePendingGoogleAccountLink() async {
    if (_isProcessing) return;
    _isProcessing = true;
    state = const AsyncLoading();
    try {
      final pendingLink = ref.read(pendingGoogleAccountLinkProvider);
      final session = ref.read(currentSessionProvider);
      final hasGoogleIdentity =
          session?.user.identities?.any(
            (identity) => identity.provider == 'google',
          ) ??
          false;
      if (pendingLink == null ||
          session == null ||
          !pendingLink.matches(
            userId: session.user.id,
            hasGoogleIdentity: hasGoogleIdentity,
          )) {
        throw const AppException(
          'Google identity linking has not completed',
          code: 'AUTH_LINK_GOOGLE_NOT_COMPLETED',
        );
      }

      await ref.read(authRepositoryProvider).completeGoogleAccountLink();
      await ref.read(pendingGoogleAccountLinkProvider.notifier).clear();
      ref.invalidate(currentProfileProvider);
      ref
          .read(accountLinkNoticeProvider.notifier)
          .show(AccountLinkNotice.googleSuccess);
      state = const AsyncData(null);
    } catch (e, st) {
      AppLogger.error('completePendingGoogleAccountLink failed', e, st);
      ref
          .read(accountLinkNoticeProvider.notifier)
          .show(AccountLinkNotice.googleFailure);
      state = AsyncError(e, st);
      rethrow;
    } finally {
      _isProcessing = false;
    }
  }

  Future<void> linkFacebookAccount() async {
    if (_isProcessing) return;
    _isProcessing = true;
    state = const AsyncLoading();
    try {
      final usesMockProfile = await ref
          .read(authRepositoryProvider)
          .linkFacebookAccount();

      ref.invalidate(currentProfileProvider);

      if (usesMockProfile) {
        ref
            .read(profileRepositoryProvider)
            .setMockEmailAndProvider(
              email: 'mock-facebook@facebook.com',
              loginProvider: 'facebook',
            );
      }
      state = const AsyncData(null);
    } catch (e, st) {
      AppLogger.error('linkFacebookAccount failed', e, st);
      state = AsyncError(e, st);
      rethrow;
    } finally {
      _isProcessing = false;
    }
  }

  Future<void> signInWithGoogle() async {
    if (_isProcessing) return;
    _isProcessing = true;
    state = const AsyncLoading();
    try {
      final session = await ref.read(authRepositoryProvider).signInWithGoogle();

      _applySignedInSession(session);
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    } finally {
      _isProcessing = false;
    }
  }

  Future<void> signInWithFacebook() async {
    if (_isProcessing) return;
    _isProcessing = true;
    state = const AsyncLoading();
    try {
      final session = await ref
          .read(authRepositoryProvider)
          .signInWithFacebook();
      _applySignedInSession(session);
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    } finally {
      _isProcessing = false;
    }
  }

  Future<void> signInWithEmail({
    required String email,
    required String password,
    String? captchaToken,
  }) async {
    if (_isProcessing) return;
    _isProcessing = true;
    state = const AsyncLoading();
    try {
      final session = await ref
          .read(authRepositoryProvider)
          .signInWithEmail(
            email: email,
            password: password,
            captchaToken: captchaToken,
          );

      _applySignedInSession(session);
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    } finally {
      _isProcessing = false;
    }
  }

  Future<bool> signUpWithEmail({
    required String email,
    required String password,
    String? captchaToken,
  }) async {
    if (_isProcessing) return true;
    _isProcessing = true;
    state = const AsyncLoading();
    try {
      final session = await ref
          .read(authRepositoryProvider)
          .signUpWithEmail(
            email: email,
            password: password,
            captchaToken: captchaToken,
          );
      _applySignedInSession(session);
      state = const AsyncData(null);
      return session == null;
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    } finally {
      _isProcessing = false;
    }
  }

  Future<bool> requestPasswordReset(
    String email, {
    String? captchaToken,
  }) async {
    if (_isProcessing) return false;
    _isProcessing = true;
    state = const AsyncLoading();
    try {
      final opensRecoveryLocally = await ref
          .read(authRepositoryProvider)
          .requestPasswordReset(email, captchaToken: captchaToken);
      state = const AsyncData(null);
      return opensRecoveryLocally;
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    } finally {
      _isProcessing = false;
    }
  }

  Future<void> completePasswordRecovery(String password) async {
    if (_isProcessing) return;
    _isProcessing = true;
    state = const AsyncLoading();
    try {
      await ref.read(authRepositoryProvider).updatePassword(password);
      ref.read(mockSessionProvider.notifier).setSession(null);
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    } finally {
      _isProcessing = false;
    }
  }

  Future<void> cancelPasswordRecovery() async {
    if (_isProcessing) return;
    _isProcessing = true;
    state = const AsyncLoading();
    try {
      await ref.read(authRepositoryProvider).cancelPasswordRecovery();
      ref.read(mockSessionProvider.notifier).setSession(null);
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    } finally {
      _isProcessing = false;
    }
  }

  Future<void> updatePassword(String newPassword) async {
    if (_isProcessing) return;
    _isProcessing = true;
    state = const AsyncLoading();
    try {
      await ref.read(authRepositoryProvider).updatePassword(newPassword);
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    } finally {
      _isProcessing = false;
    }
  }

  void _applySignedInSession(Session? session) {
    if (session == null) return;

    if (session.user.id == 'mock-user-id') {
      ref.read(mockSessionProvider.notifier).setSession(session);
    }
    ref.invalidate(currentProfileProvider);
  }
}
