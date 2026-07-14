import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/supabase/app_exception.dart';
import '../../../core/supabase/supabase_providers.dart';
import '../../../shared/utils/app_logger.dart';
import '../domain/email_account_link.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final client = AppConstants.hasSupabaseConfig
      ? ref.watch(supabaseClientProvider)
      : null;
  return AuthRepository(
    client,
    useMockData: ref.watch(useMockDataModeProvider),
  );
});

class AuthRepository {
  AuthRepository(this._client, {bool useMockData = false})
    : _useMockData = useMockData || !AppConstants.hasSupabaseConfig;

  final SupabaseClient? _client;
  final bool _useMockData;

  SupabaseClient get _requiredClient {
    final client = _client;
    if (client == null) {
      throw const AppException(
        'Supabase client is not available',
        code: 'SUPABASE_CLIENT_UNAVAILABLE',
      );
    }
    return client;
  }

  Future<Session?> signInAnonymously() async {
    if (_useMockData) {
      return _mockSession();
    }

    try {
      await _requiredClient.auth.signInAnonymously();
      await _initializeUserIfPossible();
      return null;
    } catch (e, st) {
      AppLogger.error('Anonymous sign-in failed', e, st);
      if (e is AppException) rethrow;
      throw const AppException('errorGeneric', code: 'AUTH_SIGN_IN_FAILED');
    }
  }

  Future<Session> startGuestSession() async {
    return _mockSession();
  }

  Future<void> signOut() async {
    if (_useMockData) return;

    try {
      await _requiredClient.auth.signOut();
    } catch (e, st) {
      AppLogger.error('Sign-out failed', e, st);
      if (e is AppException) rethrow;
      throw const AppException('errorGeneric', code: 'AUTH_SIGN_OUT_FAILED');
    }
  }

  Future<EmailAccountLinkStatus> beginEmailAccountLink({
    required String email,
  }) async {
    if (_useMockData) {
      return EmailAccountLinkStatus.readyToSetPassword;
    }

    try {
      final response = await _requiredClient.auth.updateUser(
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

  Future<bool> completeEmailAccountLink({required String password}) async {
    if (_useMockData) return true;

    try {
      final user = (await _requiredClient.auth.getUser()).user;
      final email = user?.email?.trim();
      if (user == null || user.isAnonymous || email == null || email.isEmpty) {
        throw const AppException(
          'Email confirmation is required before setting a password',
          code: 'AUTH_LINK_EMAIL_NOT_CONFIRMED',
        );
      }

      await _requiredClient.auth.updateUser(UserAttributes(password: password));
      await _initializeUserIfPossible();
      await _updateProfileLoginProvider(email: email, loginProvider: 'email');
      return false;
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

  Future<bool> linkGoogleAccount() async {
    if (_useMockData) {
      return true;
    }

    try {
      await _requiredClient.auth.linkIdentity(OAuthProvider.google);
      // Wait a moment for identity to be linked and metadata updated
      await Future.delayed(const Duration(seconds: 1));
      await _initializeUserIfPossible();
      return false;
    } catch (e, st) {
      AppLogger.error('Google account linking failed', e, st);
      if (e is AppException) rethrow;
      throw const AppException('errorGeneric', code: 'AUTH_LINK_GOOGLE_FAILED');
    }
  }

  Future<bool> linkFacebookAccount() async {
    if (_useMockData) {
      return true;
    }

    try {
      await _requiredClient.auth.linkIdentity(OAuthProvider.facebook);
      return false;
    } catch (e, st) {
      AppLogger.error('Facebook account linking failed', e, st);
      if (e is AppException) rethrow;
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
    if (_useMockData) {
      return _mockSession();
    }
    try {
      // Clear a verifier left behind by an interrupted PKCE flow before
      // starting a fresh browser session.
      await _requiredClient.auth.signOut(scope: SignOutScope.local);

      final launched = await _requiredClient.auth.signInWithOAuth(
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
  }) async {
    if (_useMockData) {
      return _mockSession();
    }
    try {
      AppLogger.info('Attempting email sign-in');
      final response = await _requiredClient.auth.signInWithPassword(
        email: email,
        password: password,
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
  }) async {
    if (_useMockData) return _mockSession();
    try {
      final response = await _requiredClient.auth.signUp(
        email: email,
        password: password,
        emailRedirectTo: AppConstants.supabaseLoginCallbackUrl,
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

  Future<bool> requestPasswordReset(String email) async {
    if (_useMockData) return true;
    try {
      await _requiredClient.auth.resetPasswordForEmail(
        email,
        redirectTo: kIsWeb
            ? null
            : AppConstants.supabasePasswordResetCallbackUrl,
      );
      return false;
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
    if (_useMockData) return;

    try {
      await _requiredClient.auth.updateUser(UserAttributes(password: password));
      await _requiredClient.auth.signOut(scope: SignOutScope.local);
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
    if (_useMockData) return;

    try {
      await _requiredClient.auth.signOut(scope: SignOutScope.local);
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
      await _requiredClient.rpc('initialize_user');
    } catch (e, st) {
      AppLogger.error('initialize_user RPC failed (non-blocking)', e, st);
    }
  }

  Future<void> _updateProfileLoginProvider({
    required String email,
    required String loginProvider,
  }) async {
    final userId = _requiredClient.auth.currentUser?.id;
    if (userId == null) {
      throw const AppException('Missing auth user', code: 'AUTH_REQUIRED');
    }

    await _requiredClient
        .from('profiles')
        .update({'email': email, 'login_provider': loginProvider})
        .eq('id', userId);
  }

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
}
