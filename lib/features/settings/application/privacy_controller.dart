import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/repositories/privacy_repository.dart';
import 'package:local_auth/local_auth.dart';
import '../../../../shared/utils/app_logger.dart';

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

  Future<void> toggleAppLock(bool value, {required String reason}) async {
    // If trying to turn on lock, verify identity first
    if (value) {
      final success = await authenticateUser(reason);
      if (!success) return;
    }

    await ref.read(privacyRepositoryProvider).setIsAppLocked(value);
    state = state.copyWith(isAppLocked: value, isAuthenticated: true);
  }

  Future<void> toggleHideBalances(bool value) async {
    await ref.read(privacyRepositoryProvider).setIsBalancesHidden(value);
    state = state.copyWith(isBalancesHidden: value);
  }

  /// Triggers Face ID / Touch ID or fallback to PIN
  Future<bool> authenticateUser(String reason) async {
    try {
      final auth = ref.read(localAuthProvider);
      final bool canAuthenticateWithBiometrics = await auth.canCheckBiometrics;
      final bool canAuthenticate =
          canAuthenticateWithBiometrics || await auth.isDeviceSupported();

      if (!canAuthenticate) {
        // If device has no biometrics/PIN setup, we bypass or fail depending on security policy.
        // For now, we return true if unsupported to not brick the app, but log it.
        AppLogger.warning('Device does not support local auth');
        return true;
      }

      final didAuthenticate = await auth.authenticate(localizedReason: reason);

      if (didAuthenticate) {
        state = state.copyWith(isAuthenticated: true);
      }
      return didAuthenticate;
    } catch (e) {
      AppLogger.error('Biometric Auth Error: $e');
      return false;
    }
  }

  /// Call this when app goes to background
  void lockApp() {
    if (state.isAppLocked) {
      state = state.copyWith(isAuthenticated: false);
    }
  }
}
