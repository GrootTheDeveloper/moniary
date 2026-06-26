import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/supabase/supabase_providers.dart';
import '../../../shared/utils/app_logger.dart';
import '../data/auth_repository.dart';
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

  Future<void> signInAnonymously() async {
    if (_isProcessing) return;
    _isProcessing = true;
    state = const AsyncLoading();
    try {
      final session = await ref
          .read(authRepositoryProvider)
          .signInAnonymously();
      
      if (session != null) {
        ref.read(mockSessionProvider.notifier).setSession(session);
      }
      
      // Always invalidate profile when auth state changes
      ref.invalidate(currentProfileProvider);

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

  Future<void> linkEmailAccount({
    required String email,
    required String password,
  }) async {
    if (_isProcessing) return;
    _isProcessing = true;
    state = const AsyncLoading();
    try {
      final usesMockProfile = await ref
          .read(authRepositoryProvider)
          .linkEmailAccount(email: email, password: password);
      if (usesMockProfile) {
        ref
            .read(profileRepositoryProvider)
            .setMockEmailAndProvider(email: email, loginProvider: 'email');
      }
      state = const AsyncData(null);
    } catch (e, st) {
      AppLogger.error('linkEmailAccount failed', e, st);
      state = AsyncError(e, st);
      rethrow;
    } finally {
      _isProcessing = false;
    }
  }

  Future<void> linkGoogleAccount() async {
    if (_isProcessing) return;
    _isProcessing = true;
    state = const AsyncLoading();
    try {
      final usesMockProfile = await ref
          .read(authRepositoryProvider)
          .linkGoogleAccount();
      
      // Always invalidate to catch the new login_provider value
      ref.invalidate(currentProfileProvider);

      if (usesMockProfile) {
        ref
            .read(profileRepositoryProvider)
            .setMockEmailAndProvider(
              email: 'mock-google@gmail.com',
              loginProvider: 'google',
            );
      }
      state = const AsyncData(null);
    } catch (e, st) {
      AppLogger.error('linkGoogleAccount failed', e, st);
      state = AsyncError(e, st);
      rethrow;
    } finally {
      _isProcessing = false;
    }
  }

  Future<void> linkAppleAccount() async {
    if (_isProcessing) return;
    _isProcessing = true;
    state = const AsyncLoading();
    try {
      final usesMockProfile = await ref
          .read(authRepositoryProvider)
          .linkAppleAccount();
      
      ref.invalidate(currentProfileProvider);

      if (usesMockProfile) {
        ref
            .read(profileRepositoryProvider)
            .setMockEmailAndProvider(
              email: 'mock-apple@apple.com',
              loginProvider: 'apple',
            );
      }
      state = const AsyncData(null);
    } catch (e, st) {
      AppLogger.error('linkAppleAccount failed', e, st);
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
      // Clear any existing verifier to avoid bad_code_verifier if a previous flow was stale
      await ref.read(authRepositoryProvider).signOut();

      final session = await ref.read(authRepositoryProvider).signInWithGoogle();
      
      if (session != null) {
        ref.invalidate(currentProfileProvider);
      }

      // Reset _isProcessing after a delay because signInWithOAuth returns immediately 
      // on mobile and the redirect happens in browser. 
      // If we don't reset, and user cancels browser, button stays disabled.
      Future.delayed(const Duration(seconds: 10), () {
        _isProcessing = false;
      });
    } catch (e, st) {
      _isProcessing = false;
      state = AsyncError(e, st);
      rethrow;
    }
  }

  Future<void> signInWithApple() async {
    if (_isProcessing) return;
    _isProcessing = true;
    state = const AsyncLoading();
    try {
      await ref.read(authRepositoryProvider).signInWithApple();
    } catch (e, st) {
      _isProcessing = false;
      state = AsyncError(e, st);
      rethrow;
    }
  }

  Future<void> signInWithEmail({
    required String email,
    required String password,
  }) async {
    if (_isProcessing) return;
    _isProcessing = true;
    state = const AsyncLoading();
    try {
      final session = await ref.read(authRepositoryProvider).signInWithEmail(
            email: email,
            password: password,
          );
      
      // If we got a session, we should invalidate the current profile to ensure
      // the next fetch gets the real data from Supabase
      if (session != null) {
        ref.invalidate(currentProfileProvider);
      }

      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    } finally {
      _isProcessing = false;
    }
  }
}
