import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/repositories/privacy_repository.dart';
import 'package:local_auth/local_auth.dart';
import '../../../core/supabase/app_exception.dart';
import '../../../shared/utils/app_logger.dart';

class PrivacyState {
  final bool isAppLocked;
  final bool isBalancesHidden;
  final bool
  isAuthenticated; // True if the user has successfully passed biometric auth in this session

  PrivacyState({
    this.isAppLocked = false,
    this.isBalancesHidden = false,
    this.isAuthenticated = false,
  });

  PrivacyState copyWith({
    bool? isAppLocked,
    bool? isBalancesHidden,
    bool? isAuthenticated,
  }) {
    return PrivacyState(
      isAppLocked: isAppLocked ?? this.isAppLocked,
      isBalancesHidden: isBalancesHidden ?? this.isBalancesHidden,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
    );
  }
}

final localAuthProvider = Provider<LocalAuthentication>((ref) {
  return LocalAuthentication();
});

final privacyControllerProvider =
    NotifierProvider<PrivacyController, PrivacyState>(PrivacyController.new);

class PrivacyController extends Notifier<PrivacyState> {
  @override
  PrivacyState build() {
    final repository = ref.watch(privacyRepositoryProvider);
    return PrivacyState(
      isAppLocked: repository.getIsAppLocked(),
      isBalancesHidden: repository.getIsBalancesHidden(),
      isAuthenticated: !repository.getIsAppLocked(),
    );
  }

  Future<bool> toggleAppLock(bool value, {required String reason}) async {
    if (value == state.isAppLocked) return true;

    final success = await authenticateUser(reason);
    if (!success) return false;

    await ref.read(privacyRepositoryProvider).setIsAppLocked(value);
    state = state.copyWith(isAppLocked: value, isAuthenticated: true);
    return true;
  }

  Future<void> toggleHideBalances(bool value) async {
    await ref.read(privacyRepositoryProvider).setIsBalancesHidden(value);
    state = state.copyWith(isBalancesHidden: value);
  }

  /// Triggers Face ID / Touch ID or the device credential configured by the OS.
  Future<bool> authenticateUser(
    String reason, {
    bool allowUnavailable = false,
  }) async {
    try {
      final auth = ref.read(localAuthProvider);
      final bool canAuthenticateWithBiometrics = await auth.canCheckBiometrics;
      final bool canAuthenticate =
          canAuthenticateWithBiometrics || await auth.isDeviceSupported();

      if (!canAuthenticate) {
        AppLogger.warning('Device does not support local auth');
        if (allowUnavailable) return true;
        throw const AppException(
          'Device authentication is unavailable',
          code: 'LOCAL_AUTH_UNAVAILABLE',
        );
      }

      final didAuthenticate = await auth.authenticate(localizedReason: reason);

      if (didAuthenticate) {
        state = state.copyWith(isAuthenticated: true);
      }
      return didAuthenticate;
    } on AppException {
      rethrow;
    } catch (e, st) {
      AppLogger.error('Biometric Auth Error', e, st);
      throw const AppException(
        'Device authentication failed',
        code: 'LOCAL_AUTH_FAILED',
      );
    }
  }

  /// Call this when app goes to background
  void lockApp() {
    if (state.isAppLocked) {
      state = state.copyWith(isAuthenticated: false);
    }
  }
}
