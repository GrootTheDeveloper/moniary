import 'package:flutter/foundation.dart';
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
  return AuthRepository(
    client,
    ref.watch(sharedPreferencesProvider),
    useMockData: ref.watch(useMockDataModeProvider),
  );
});

class AuthRepository {
  AuthRepository(this._client, this._preferences, {bool useMockData = false})
    : _useMockData = useMockData || !AppConstants.hasSupabaseConfig;

  final SupabaseClient? _client;
  final SharedPreferences _preferences;
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
      await _preferences.setBool(mockLoggedInPreferenceKey, true);
      return _mockSession();
    }

    try {
      await _requiredClient.auth.signInAnonymously();
      await _preferences.setBool(guestModePreferenceKey, false);
      await _preferences.setBool(mockLoggedInPreferenceKey, false);
      await _initializeUserIfPossible();
      return null;
    } catch (e, st) {
      AppLogger.error('Anonymous sign-in failed', e, st);
      if (e is AppException) rethrow;
      throw const AppException('errorGeneric', code: 'AUTH_SIGN_IN_FAILED');
    }
  }

  Future<Session> startGuestSession() async {
    await _preferences.setBool(guestModePreferenceKey, true);
    await _preferences.setBool(mockLoggedInPreferenceKey, true);
    return _mockSession();
  }

  Future<void> signOut() async {
    await _preferences.setBool(guestModePreferenceKey, false);
    if (_useMockData) {
      await _preferences.setBool(mockLoggedInPreferenceKey, false);
      return;
    }

    try {
      await _requiredClient.auth.signOut();
      await _preferences.setBool(mockLoggedInPreferenceKey, false);
    } catch (e, st) {
      AppLogger.error('Sign-out failed', e, st);
      if (e is AppException) rethrow;
      throw const AppException('errorGeneric', code: 'AUTH_SIGN_OUT_FAILED');
    }
  }

  Future<bool> linkEmailAccount({
    required String email,
    required String password,
  }) async {
    if (_useMockData) {
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
      throw const AppException('errorGeneric', code: 'AUTH_LINK_EMAIL_FAILED');
    }
  }

  Future<bool> linkGoogleAccount() async {
    if (_useMockData) {
      return true;
    }

    try {
      await _requiredClient.auth.linkIdentity(OAuthProvider.google);
      return false;
    } catch (e, st) {
      AppLogger.error('Google account linking failed', e, st);
      if (e is AppException) rethrow;
      throw const AppException('errorGeneric', code: 'AUTH_LINK_GOOGLE_FAILED');
    }
  }

  Future<bool> linkAppleAccount() async {
    if (_useMockData) {
      return true;
    }

    try {
      await _requiredClient.auth.linkIdentity(OAuthProvider.apple);
      return false;
    } catch (e, st) {
      AppLogger.error('Apple account linking failed', e, st);
      if (e is AppException) rethrow;
      throw const AppException('errorGeneric', code: 'AUTH_LINK_APPLE_FAILED');
    }
  }

  Future<void> signInWithGoogle() async {
    if (_useMockData) {
      await _preferences.setBool(mockLoggedInPreferenceKey, true);
      return;
    }
    try {
      await _requiredClient.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: kIsWeb ? null : 'io.supabase.moniary://login-callback',
      );
    } catch (e, st) {
      AppLogger.error('Google sign-in failed', e, st);
      throw const AppException('errorGeneric', code: 'AUTH_SIGN_IN_FAILED');
    }
  }

  Future<void> signInWithApple() async {
    if (_useMockData) {
      await _preferences.setBool(mockLoggedInPreferenceKey, true);
      return;
    }
    try {
      await _requiredClient.auth.signInWithOAuth(
        OAuthProvider.apple,
        redirectTo: kIsWeb ? null : 'io.supabase.moniary://login-callback',
      );
    } catch (e, st) {
      AppLogger.error('Apple sign-in failed', e, st);
      throw const AppException('errorGeneric', code: 'AUTH_SIGN_IN_FAILED');
    }
  }

  Future<void> signInWithEmail({
    required String email,
    required String password,
  }) async {
    if (_useMockData) {
      await _preferences.setBool(mockLoggedInPreferenceKey, true);
      return;
    }
    try {
      await _requiredClient.auth.signInWithPassword(
        email: email,
        password: password,
      );
      await _initializeUserIfPossible();
    } catch (e, st) {
      AppLogger.error('Email sign-in failed', e, st);
      throw const AppException('errorGeneric', code: 'AUTH_SIGN_IN_FAILED');
    }
  }

  Future<void> signUpWithEmail({
    required String email,
    required String password,
  }) async {
    if (_useMockData) return;
    try {
      await _requiredClient.auth.signUp(
        email: email,
        password: password,
      );
    } catch (e, st) {
      AppLogger.error('Email sign-up failed', e, st);
      throw const AppException('errorGeneric', code: 'AUTH_SIGN_UP_FAILED');
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
