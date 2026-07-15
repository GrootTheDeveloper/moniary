import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/supabase/app_exception.dart';
import '../../../core/supabase/supabase_providers.dart';
import '../../../shared/utils/app_logger.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(ref.watch(supabaseClientProvider));
});

class AuthRepository {
  AuthRepository(this._client);

  final SupabaseClient _client;

  Future<void> signOut() async {
    try {
      await _client.auth.signOut();
    } catch (e, st) {
      AppLogger.error('Sign-out failed', e, st);
      if (e is AppException) rethrow;
      throw const AppException('errorGeneric', code: 'AUTH_SIGN_OUT_FAILED');
    }
  }

  Future<void> linkEmailAccount({
    required String email,
    required String password,
  }) async {
    try {
      await _client.auth.updateUser(
        UserAttributes(email: email, password: password),
      );
      await _initializeUserIfPossible();
      await _updateProfileLoginProvider(email: email, loginProvider: 'email');
    } catch (e, st) {
      AppLogger.error('Email account linking failed', e, st);
      if (e is AppException) rethrow;
      throw const AppException('errorGeneric', code: 'AUTH_LINK_EMAIL_FAILED');
    }
  }

  Future<void> linkGoogleAccount() async {
    try {
      await _client.auth.linkIdentity(OAuthProvider.google);
      // Wait a moment for identity to be linked and metadata updated
      await Future.delayed(const Duration(seconds: 1));
      await _initializeUserIfPossible();
    } catch (e, st) {
      AppLogger.error('Google account linking failed', e, st);
      if (e is AppException) rethrow;
      throw const AppException('errorGeneric', code: 'AUTH_LINK_GOOGLE_FAILED');
    }
  }

  Future<void> linkAppleAccount() async {
    try {
      await _client.auth.linkIdentity(OAuthProvider.apple);
    } catch (e, st) {
      AppLogger.error('Apple account linking failed', e, st);
      if (e is AppException) rethrow;
      throw const AppException('errorGeneric', code: 'AUTH_LINK_APPLE_FAILED');
    }
  }

  Future<void> linkFacebookAccount() async {
    try {
      await _client.auth.linkIdentity(OAuthProvider.facebook);
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
    try {
      // Clear any existing verifier to avoid bad_code_verifier if a previous flow was stale
      await _client.auth.signOut(scope: SignOutScope.local);

      await _client.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: kIsWeb ? null : 'io.supabase.moniary://login-callback',
      );
      return null;
    } catch (e, st) {
      AppLogger.error('Google sign-in failed', e, st);
      throw const AppException('errorGeneric', code: 'AUTH_SIGN_IN_FAILED');
    }
  }

  Future<Session?> signInWithApple() async {
    try {
      await _client.auth.signInWithOAuth(
        OAuthProvider.apple,
        redirectTo: kIsWeb ? null : 'io.supabase.moniary://login-callback',
      );
      return null;
    } catch (e, st) {
      AppLogger.error('Apple sign-in failed', e, st);
      throw const AppException('errorGeneric', code: 'AUTH_SIGN_IN_FAILED');
    }
  }

  Future<Session?> signInWithFacebook() async {
    try {
      await _client.auth.signInWithOAuth(
        OAuthProvider.facebook,
        redirectTo: kIsWeb ? null : 'io.supabase.moniary://login-callback',
      );
      return null;
    } catch (e, st) {
      AppLogger.error('Facebook sign-in failed', e, st);
      throw const AppException('errorGeneric', code: 'AUTH_SIGN_IN_FAILED');
    }
  }

  Future<Session?> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      AppLogger.info('Attempting email sign-in for $email');
      final response = await _client.auth.signInWithPassword(
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

  Future<void> signUpWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      await _client.auth.signUp(
        email: email,
        password: password,
        emailRedirectTo: 'io.supabase.moniary://login-callback',
      );
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

  Future<void> requestPasswordReset(String email) async {
    try {
      await _client.auth.resetPasswordForEmail(
        email,
        redirectTo: kIsWeb ? null : 'io.supabase.moniary://reset-password',
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

  Future<void> updatePassword(String newPassword) async {
    try {
      await _client.auth.updateUser(UserAttributes(password: newPassword));
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
