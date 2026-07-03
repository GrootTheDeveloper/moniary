import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/preferences/preferences_providers.dart';
import '../../wallets/data/repositories/wallet_repository.dart';
import '../../wallets/domain/models/wallet.dart';
import '../application/profile_setup_controller.dart';
import '../data/profile_repository.dart';

final profileSurveyControllerProvider =
    AsyncNotifierProvider<ProfileSurveyController, void>(
      ProfileSurveyController.new,
    );

class ProfileSurveyController extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<void> complete({
    required String occupation,
    required String preferredCurrency,
    required String walletName,
    required double initialBalance,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final walletRepository = ref.read(walletRepositoryProvider);
      final wallets = await walletRepository.fetchWallets();
      final defaultWallet = _defaultWallet(wallets);

      if (defaultWallet == null) {
        await walletRepository.createWallet(
          name: walletName,
          type: WalletType.cash,
          initialBalance: initialBalance,
          isDefault: true,
        );
      } else {
        await walletRepository.updateWallet(
          walletId: defaultWallet.id,
          name: walletName,
          type: defaultWallet.type,
          initialBalance: initialBalance,
          isDefault: true,
          isActive: true,
        );
      }

      await ref
          .read(profileRepositoryProvider)
          .completeSurvey(
            occupation: occupation,
            preferredCurrency: preferredCurrency,
          );
      await ref
          .read(preferredCurrencyProvider.notifier)
          .setCurrency(preferredCurrency);

      ref.invalidate(currentProfileProvider);
    });
  }

  Wallet? _defaultWallet(List<Wallet> wallets) {
    for (final wallet in wallets) {
      if (wallet.isDefault) return wallet;
    }
    return wallets.isEmpty ? null : wallets.first;
  }
}
