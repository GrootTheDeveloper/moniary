import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/constants/app_constants.dart';
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
  }) async {
    if (_isProcessing) return;
    _isProcessing = true;
    state = const AsyncLoading();
    try {
      final session = await ref
          .read(authRepositoryProvider)
          .signInWithEmail(email: email, password: password);

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
  }) async {
    if (_isProcessing) return true;
    _isProcessing = true;
    state = const AsyncLoading();
    try {
      final session = await ref
          .read(authRepositoryProvider)
          .signUpWithEmail(email: email, password: password);
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

  Future<void> requestPasswordReset(String email) async {
    if (_isProcessing) return;
    _isProcessing = true;
    state = const AsyncLoading();
    try {
      await ref.read(authRepositoryProvider).requestPasswordReset(email);
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
