import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/preferences/preferences_providers.dart';
import '../../../core/supabase/supabase_providers.dart';
import '../../../shared/utils/app_logger.dart';
import '../../profile/data/profile_repository.dart';

final authControllerProvider = AsyncNotifierProvider<AuthController, void>(
  AuthController.new,
);

class AuthController extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<void> signInAnonymously() async {
    state = const AsyncLoading();
    try {
      if (!AppConstants.hasSupabaseConfig) {
        final prefs = ref.read(sharedPreferencesProvider);
        await prefs.setBool('mock_logged_in', true);
        const user = User(
          id: 'mock-user-id',
          appMetadata: {},
          userMetadata: {},
          aud: 'authenticated',
          createdAt: '2026-05-28T00:00:00Z',
        );
        final mockSession = Session(
          accessToken: 'mockAccessToken',
          tokenType: 'bearer',
          expiresIn: 3600,
          user: user,
        );
        ref.read(mockSessionProvider.notifier).setSession(mockSession);
        return;
      }

      final client = ref.read(supabaseClientProvider);

      await client.auth.signInAnonymously();

      try {
        await client.rpc('initialize_user');
      } on PostgrestException catch (error) {
        // Allow auth to succeed even if the database migration/RPC is not ready yet.
        debugPrint('initialize_user() failed (non-blocking): ${error.message}');
      }
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }

  Future<void> signOut() async {
    state = const AsyncLoading();
    try {
      if (!AppConstants.hasSupabaseConfig) {
        final prefs = ref.read(sharedPreferencesProvider);
        await prefs.setBool('mock_logged_in', false);
        ref.read(mockSessionProvider.notifier).setSession(null);
        state = const AsyncData(null);
        return;
      }
      final client = ref.read(supabaseClientProvider);
      await client.auth.signOut();
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }

  Future<void> linkEmailAccount({
    required String email,
    required String password,
  }) async {
    state = const AsyncLoading();
    try {
      if (!AppConstants.hasSupabaseConfig) {
        ref
            .read(profileRepositoryProvider)
            .setMockEmailAndProvider(email: email, loginProvider: 'email');
        state = const AsyncData(null);
        return;
      }
      final client = ref.read(supabaseClientProvider);

      // 1. Update user credentials in Auth
      await client.auth.updateUser(
        UserAttributes(email: email, password: password),
      );

      // 2. Call RPC to sync profile with database profiles table
      try {
        await client.rpc('initialize_user');
      } catch (e, st) {
        AppLogger.error('linkEmailAccount RPC failed (non-blocking)', e, st);
      }

      final userId = client.auth.currentUser?.id;
      if (userId != null) {
        await client
            .from('profiles')
            .update({'email': email, 'login_provider': 'email'})
            .eq('id', userId);
      }
      state = const AsyncData(null);
    } catch (e, st) {
      AppLogger.error('linkEmailAccount failed', e, st);
      state = AsyncError(e, st);
      rethrow;
    }
  }

  Future<void> linkGoogleAccount() async {
    state = const AsyncLoading();
    try {
      if (!AppConstants.hasSupabaseConfig) {
        ref
            .read(profileRepositoryProvider)
            .setMockEmailAndProvider(
              email: 'mock-google@gmail.com',
              loginProvider: 'google',
            );
        state = const AsyncData(null);
        return;
      }
      final client = ref.read(supabaseClientProvider);
      await client.auth.linkIdentity(OAuthProvider.google);
      state = const AsyncData(null);
    } catch (e, st) {
      AppLogger.error('linkGoogleAccount failed', e, st);
      state = AsyncError(e, st);
      rethrow;
    }
  }
}
