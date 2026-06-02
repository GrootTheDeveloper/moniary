import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/preferences/preferences_providers.dart';
import '../../../core/supabase/app_exception.dart';
import '../../../core/supabase/supabase_providers.dart';
import '../../../shared/utils/app_logger.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final client = AppConstants.hasSupabaseConfig
      ? ref.watch(supabaseClientProvider)
      : null;
  return AuthRepository(client, ref.watch(sharedPreferencesProvider));
});

class AuthRepository {
  AuthRepository(this._client, this._preferences);

  final SupabaseClient? _client;
  final SharedPreferences _preferences;

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
    if (!AppConstants.hasSupabaseConfig) {
      await _preferences.setBool('mock_logged_in', true);
      return _mockSession();
    }

    try {
      await _requiredClient.auth.signInAnonymously();
      await _initializeUserIfPossible();
      return null;
    } catch (e, st) {
      AppLogger.error('Anonymous sign-in failed', e, st);
      if (e is AppException) rethrow;
      throw AppException(e.toString(), code: 'AUTH_SIGN_IN_FAILED');
    }
  }

  Future<void> signOut() async {
    if (!AppConstants.hasSupabaseConfig) {
      await _preferences.setBool('mock_logged_in', false);
      return;
    }

    try {
      await _requiredClient.auth.signOut();
    } catch (e, st) {
      AppLogger.error('Sign-out failed', e, st);
      if (e is AppException) rethrow;
      throw AppException(e.toString(), code: 'AUTH_SIGN_OUT_FAILED');
    }
  }

  Future<bool> linkEmailAccount({
    required String email,
    required String password,
  }) async {
    if (!AppConstants.hasSupabaseConfig) {
      return true;
    }

    try {
      await _requiredClient.auth.updateUser(
        UserAttributes(email: email, password: password),
      );
      await _initializeUserIfPossible();
      await _updateProfileLoginProvider(email: email, loginProvider: 'email');
      return false;
    } catch (e, st) {
      AppLogger.error('Email account linking failed', e, st);
      if (e is AppException) rethrow;
      throw AppException(e.toString(), code: 'AUTH_LINK_EMAIL_FAILED');
    }
  }

  Future<bool> linkGoogleAccount() async {
    if (!AppConstants.hasSupabaseConfig) {
      return true;
    }

    try {
      await _requiredClient.auth.linkIdentity(OAuthProvider.google);
      return false;
    } catch (e, st) {
      AppLogger.error('Google account linking failed', e, st);
      if (e is AppException) rethrow;
      throw AppException(e.toString(), code: 'AUTH_LINK_GOOGLE_FAILED');
    }
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
