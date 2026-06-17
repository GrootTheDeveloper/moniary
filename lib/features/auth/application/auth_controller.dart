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
  @override
  Future<void> build() async {}

  Future<void> signInAnonymously() async {
    state = const AsyncLoading();
    try {
      final mockSession = await ref
          .read(authRepositoryProvider)
          .signInAnonymously();
      if (mockSession != null) {
        ref.read(mockSessionProvider.notifier).setSession(mockSession);
      }
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }

  Future<void> startGuestSession() async {
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
    }
  }

  Future<void> signOut() async {
    state = const AsyncLoading();
    try {
      await ref.read(authRepositoryProvider).signOut();
      ref.read(mockSessionProvider.notifier).setSession(null);
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
    }
  }

  Future<void> linkGoogleAccount() async {
    state = const AsyncLoading();
    try {
      final usesMockProfile = await ref
          .read(authRepositoryProvider)
          .linkGoogleAccount();
      if (usesMockProfile) {
        ref
            .read(profileRepositoryProvider)
            .setMockEmailAndProvider(
              email: 'mock-google@gmail.com',
              loginProvider: 'google',
            );
      } else {
        // If real linking happened, ensure the local profile provider is refreshed
        ref.invalidate(currentProfileProvider);
      }
      state = const AsyncData(null);
    } catch (e, st) {
      AppLogger.error('linkGoogleAccount failed', e, st);
      state = AsyncError(e, st);
      rethrow;
    }
  }

  Future<void> linkAppleAccount() async {
    state = const AsyncLoading();
    try {
      final usesMockProfile = await ref
          .read(authRepositoryProvider)
          .linkAppleAccount();
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
    }
  }

  Future<void> signInWithGoogle() async {
    state = const AsyncLoading();
    try {
      await ref.read(authRepositoryProvider).signInWithGoogle();
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }

  Future<void> signInWithApple() async {
    state = const AsyncLoading();
    try {
      await ref.read(authRepositoryProvider).signInWithApple();
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }
}
