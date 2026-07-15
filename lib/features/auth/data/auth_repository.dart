import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/supabase/app_exception.dart';
import '../../../core/supabase/supabase_providers.dart';
import '../../../shared/utils/app_logger.dart';
import '../domain/email_account_link.dart';
import '../domain/facebook_account_link.dart';
import '../domain/google_account_link.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(ref.watch(supabaseClientProvider));
});

class AuthRepository {
  AuthRepository(this._client);

  final SupabaseClient _client;

  Future<Session?> signInAnonymously({String? captchaToken}) async {
    final normalizedCaptchaToken = _requireCaptchaToken(captchaToken);

    try {
      final response = await _client.auth.signInAnonymously(
        captchaToken: normalizedCaptchaToken,
      );
      await _initializeUserIfPossible();
      return response.session;
    } on AuthException catch (e, st) {
      AppLogger.error('Anonymous sign-in failed', e, st);
      throw _mapAuthException(e);
    } catch (e, st) {
      AppLogger.error('Anonymous sign-in failed', e, st);
      if (e is AppException) rethrow;
      throw const AppException('errorGeneric', code: 'AUTH_SIGN_IN_FAILED');
    }
  }

  Future<void> signOut() async {
    try {
      await _client.auth.signOut();
    } catch (e, st) {
      AppLogger.error('Sign-out failed', e, st);
      if (e is AppException) rethrow;
      throw const AppException('errorGeneric', code: 'AUTH_SIGN_OUT_FAILED');
    }
  }

  Future<EmailAccountLinkStatus> beginEmailAccountLink({
    required String email,
  }) async {
    try {
      final response = await _client.auth.updateUser(
        UserAttributes(email: email),
        emailRedirectTo: AppConstants.supabaseLoginCallbackUrl,
      );
      final user = response.user;
      final emailIsConfirmed =
          user != null &&
          !user.isAnonymous &&
          user.email?.trim().toLowerCase() == email.trim().toLowerCase();
      return emailIsConfirmed
          ? EmailAccountLinkStatus.readyToSetPassword
          : EmailAccountLinkStatus.confirmationRequired;
    } catch (e, st) {
      AppLogger.error('Starting email account linking failed', e, st);
      if (e is AppException) rethrow;
      throw const AppException('errorGeneric', code: 'AUTH_LINK_EMAIL_FAILED');
    }
  }

  Future<void> completeEmailAccountLink({required String password}) async {
    try {
      final user = (await _client.auth.getUser()).user;
      final email = user?.email?.trim();
      if (user == null || user.isAnonymous || email == null || email.isEmpty) {
        throw const AppException(
          'Email confirmation is required before setting a password',
          code: 'AUTH_LINK_EMAIL_NOT_CONFIRMED',
        );
      }

      await _client.auth.updateUser(UserAttributes(password: password));
      await _initializeUserIfPossible();
      await _updateProfileLoginProvider(email: email, loginProvider: 'email');
    } on AuthException catch (e, st) {
      AppLogger.error('Completing email account linking failed', e, st);
      throw _mapAuthException(e);
    } on AppException {
      rethrow;
    } catch (e, st) {
      AppLogger.error('Completing email account linking failed', e, st);
      if (_isNetworkError(e)) {
        throw const AppException('errorConnection', code: 'AUTH_NETWORK_ERROR');
      }
      throw const AppException('errorGeneric', code: 'AUTH_LINK_EMAIL_FAILED');
    }
  }

  Future<GoogleAccountLinkStatus> beginGoogleAccountLink() async {
    try {
      final launched = await _client.auth.linkIdentity(
        OAuthProvider.google,
        redirectTo: kIsWeb ? null : AppConstants.supabaseLoginCallbackUrl,
        authScreenLaunchMode: kIsWeb
            ? LaunchMode.platformDefault
            : LaunchMode.externalApplication,
      );
      if (!launched) {
        throw const AppException(
          'OAuth browser could not be opened',
          code: 'AUTH_OAUTH_LAUNCH_FAILED',
        );
      }
      return GoogleAccountLinkStatus.browserOpened;
    } on AuthException catch (e, st) {
      AppLogger.error('Starting Google account linking failed', e, st);
      throw _mapAuthException(e);
    } on AppException {
      rethrow;
    } catch (e, st) {
      AppLogger.error('Starting Google account linking failed', e, st);
      if (_isNetworkError(e)) {
        throw const AppException('errorConnection', code: 'AUTH_NETWORK_ERROR');
      }
      throw const AppException('errorGeneric', code: 'AUTH_LINK_GOOGLE_FAILED');
    }
  }

  Future<void> completeGoogleAccountLink() async {
    try {
      final user = (await _client.auth.getUser()).user;
      final hasGoogleIdentity =
          user?.identities?.any((identity) => identity.provider == 'google') ??
          false;
      final email = user?.email?.trim();
      if (!hasGoogleIdentity || email == null || email.isEmpty) {
        throw const AppException(
          'Google identity linking has not completed',
          code: 'AUTH_LINK_GOOGLE_NOT_COMPLETED',
        );
      }
      await _initializeUserIfPossible();
      await _updateProfileLoginProvider(email: email, loginProvider: 'google');
    } on AuthException catch (e, st) {
      AppLogger.error('Completing Google account linking failed', e, st);
      throw _mapAuthException(e);
    } on AppException {
      rethrow;
    } catch (e, st) {
      AppLogger.error('Completing Google account linking failed', e, st);
      if (_isNetworkError(e)) {
        throw const AppException('errorConnection', code: 'AUTH_NETWORK_ERROR');
      }
      throw const AppException('errorGeneric', code: 'AUTH_LINK_GOOGLE_FAILED');
    }
  }

  Future<FacebookAccountLinkStatus> beginFacebookAccountLink() async {
    try {
      final launched = await _client.auth.linkIdentity(
        OAuthProvider.facebook,
        redirectTo: kIsWeb ? null : AppConstants.supabaseLoginCallbackUrl,
        authScreenLaunchMode: kIsWeb
            ? LaunchMode.platformDefault
            : LaunchMode.externalApplication,
      );
      if (!launched) {
        throw const AppException(
          'OAuth browser could not be opened',
          code: 'AUTH_OAUTH_LAUNCH_FAILED',
        );
      }
      return FacebookAccountLinkStatus.browserOpened;
    } on AuthException catch (e, st) {
      AppLogger.error('Starting Facebook account linking failed', e, st);
      throw _mapAuthException(e);
    } on AppException {
      rethrow;
    } catch (e, st) {
      AppLogger.error('Starting Facebook account linking failed', e, st);
      if (_isNetworkError(e)) {
        throw const AppException('errorConnection', code: 'AUTH_NETWORK_ERROR');
      }
      throw const AppException(
        'errorGeneric',
        code: 'AUTH_LINK_FACEBOOK_FAILED',
      );
    }
  }

  Future<void> completeFacebookAccountLink() async {
    try {
      final user = (await _client.auth.getUser()).user;
      final facebookIdentity = user?.identities
          ?.where((identity) => identity.provider == 'facebook')
          .firstOrNull;
      final identityEmailValue = facebookIdentity?.identityData?['email'];
      final identityEmail = identityEmailValue is String
          ? identityEmailValue
          : null;
      final email = user?.email?.trim().isNotEmpty == true
          ? user!.email!.trim()
          : identityEmail?.trim();
      if (facebookIdentity == null || email == null || email.isEmpty) {
        throw const AppException(
          'Facebook identity linking has not completed',
          code: 'AUTH_LINK_FACEBOOK_NOT_COMPLETED',
        );
      }
      await _initializeUserIfPossible();
      await _updateProfileLoginProvider(
        email: email,
        loginProvider: 'facebook',
      );
    } on AuthException catch (e, st) {
      AppLogger.error('Completing Facebook account linking failed', e, st);
      throw _mapAuthException(e);
    } on AppException {
      rethrow;
    } catch (e, st) {
      AppLogger.error('Completing Facebook account linking failed', e, st);
      if (_isNetworkError(e)) {
        throw const AppException('errorConnection', code: 'AUTH_NETWORK_ERROR');
      }
      throw const AppException(
        'errorGeneric',
        code: 'AUTH_LINK_FACEBOOK_FAILED',
      );
    }
  }

  Future<Session?> signInWithGoogle() async {
    return _signInWithOAuth(OAuthProvider.google, providerName: 'Google');
  }

  Future<Session?> signInWithFacebook() async {
    return _signInWithOAuth(OAuthProvider.facebook, providerName: 'Facebook');
  }

  Future<Session?> _signInWithOAuth(
    OAuthProvider provider, {
    required String providerName,
  }) async {
    try {
      // Clear a verifier left behind by an interrupted PKCE flow before
      // starting a fresh browser session.
      await _client.auth.signOut(scope: SignOutScope.local);

      final launched = await _client.auth.signInWithOAuth(
        provider,
        redirectTo: kIsWeb ? null : AppConstants.supabaseLoginCallbackUrl,
        authScreenLaunchMode: kIsWeb
            ? LaunchMode.platformDefault
            : LaunchMode.externalApplication,
      );

      if (!launched) {
        throw const AppException(
          'OAuth browser could not be opened',
          code: 'AUTH_OAUTH_LAUNCH_FAILED',
        );
      }
      return null;
    } on AuthException catch (e, st) {
      AppLogger.error('$providerName sign-in failed', e, st);
      throw _mapAuthException(e);
    } on AppException {
      rethrow;
    } catch (e, st) {
      AppLogger.error('$providerName sign-in failed', e, st);
      if (_isNetworkError(e)) {
        throw const AppException('errorConnection', code: 'AUTH_NETWORK_ERROR');
      }
      throw const AppException('errorGeneric', code: 'AUTH_SIGN_IN_FAILED');
    }
  }

  Future<Session?> signInWithEmail({
    required String email,
    required String password,
    String? captchaToken,
  }) async {
    final normalizedCaptchaToken = _requireCaptchaToken(captchaToken);
    try {
      AppLogger.info('Attempting email sign-in');
      final response = await _client.auth.signInWithPassword(
        email: email,
        password: password,
        captchaToken: normalizedCaptchaToken,
      );
      AppLogger.info('Email sign-in RPC success, initializing user...');
      await _initializeUserIfPossible();
      return response.session;
    } on AuthException catch (e, st) {
      AppLogger.error('Supabase AuthException during sign-in', e, st);
      throw _mapAuthException(e);
    } catch (e, st) {
      AppLogger.error('Unexpected error during email sign-in', e, st);
      if (_isNetworkError(e)) {
        throw const AppException('errorConnection', code: 'AUTH_NETWORK_ERROR');
      }
      throw const AppException('errorGeneric', code: 'AUTH_SIGN_IN_FAILED');
    }
  }

  Future<Session?> signUpWithEmail({
    required String email,
    required String password,
    String? captchaToken,
  }) async {
    final normalizedCaptchaToken = _requireCaptchaToken(captchaToken);
    try {
      final response = await _client.auth.signUp(
        email: email,
        password: password,
        emailRedirectTo: AppConstants.supabaseLoginCallbackUrl,
        captchaToken: normalizedCaptchaToken,
      );

      if (response.session != null) {
        await _initializeUserIfPossible();
      }
      return response.session;
    } on AuthException catch (e, st) {
      AppLogger.error('Email sign-up failed', e, st);
      throw _mapAuthException(e);
    } catch (e, st) {
      AppLogger.error('Email sign-up failed (unexpected)', e, st);
      if (_isNetworkError(e)) {
        throw const AppException('errorConnection', code: 'AUTH_NETWORK_ERROR');
      }
      throw const AppException('errorGeneric', code: 'AUTH_SIGN_UP_FAILED');
    }
  }

  Future<void> requestPasswordReset(
    String email, {
    String? captchaToken,
  }) async {
    final normalizedCaptchaToken = _requireCaptchaToken(captchaToken);
    try {
      await _client.auth.resetPasswordForEmail(
        email,
        redirectTo: kIsWeb
            ? null
            : AppConstants.supabasePasswordResetCallbackUrl,
        captchaToken: normalizedCaptchaToken,
      );
    } on AuthException catch (e, st) {
      AppLogger.error('Password reset request failed', e, st);
      throw _mapAuthException(e);
    } catch (e, st) {
      AppLogger.error('Password reset request failed (unexpected)', e, st);
      if (_isNetworkError(e)) {
        throw const AppException('errorConnection', code: 'AUTH_NETWORK_ERROR');
      }
      throw const AppException(
        'errorGeneric',
        code: 'AUTH_PASSWORD_RESET_FAILED',
      );
    }
  }

  Future<void> updatePassword(String password) async {
    try {
      await _client.auth.updateUser(UserAttributes(password: password));
      await _client.auth.signOut(scope: SignOutScope.local);
    } on AuthException catch (e, st) {
      AppLogger.error('Password update failed', e, st);
      throw _mapAuthException(e);
    } catch (e, st) {
      AppLogger.error('Password update failed (unexpected)', e, st);
      if (_isNetworkError(e)) {
        throw const AppException('errorConnection', code: 'AUTH_NETWORK_ERROR');
      }
      throw const AppException(
        'errorGeneric',
        code: 'AUTH_PASSWORD_UPDATE_FAILED',
      );
    }
  }

  Future<void> cancelPasswordRecovery() async {
    try {
      await _client.auth.signOut(scope: SignOutScope.local);
    } catch (e, st) {
      AppLogger.error('Password recovery cancellation failed', e, st);
      if (e is AppException) rethrow;
      throw const AppException(
        'errorGeneric',
        code: 'AUTH_PASSWORD_RECOVERY_CANCEL_FAILED',
      );
    }
  }

  AppException _mapAuthException(AuthException error) {
    if (_isNetworkError(error)) {
      return const AppException('errorConnection', code: 'AUTH_NETWORK_ERROR');
    }
    return AppException(error.message, code: error.code);
  }

  bool _isNetworkError(Object error) {
    final message = error.toString().toLowerCase();
    return message.contains('socketexception') ||
        message.contains('clientexception') ||
        message.contains('failed host lookup') ||
        message.contains('connection refused') ||
        message.contains('connection reset') ||
        message.contains('network is unreachable') ||
        message.contains('connection timed out');
  }

  Future<void> _initializeUserIfPossible() async {
    try {
      await _client.rpc('initialize_user');
    } catch (e, st) {
      AppLogger.error('initialize_user RPC failed (non-blocking)', e, st);
    }
  }

  String _requireCaptchaToken(String? captchaToken) {
    final normalizedCaptchaToken = captchaToken?.trim();
    if (normalizedCaptchaToken == null || normalizedCaptchaToken.isEmpty) {
      throw const AppException(
        'CAPTCHA is required for this authentication action',
        code: 'AUTH_CAPTCHA_REQUIRED',
      );
    }
    return normalizedCaptchaToken;
  }

  Future<void> _updateProfileLoginProvider({
    required String email,
    required String loginProvider,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw const AppException('Missing auth user', code: 'AUTH_REQUIRED');
    }

    await _client
        .from('profiles')
        .update({'email': email, 'login_provider': loginProvider})
        .eq('id', userId);
  }
}
