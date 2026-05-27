import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/repositories/wallet_repository.dart';
import '../domain/models/wallet.dart';

final walletsControllerProvider =
    AsyncNotifierProvider<WalletsController, List<Wallet>>(
      WalletsController.new,
    );

class WalletsController extends AsyncNotifier<List<Wallet>> {
  @override
  Future<List<Wallet>> build() {
    return ref.read(walletRepositoryProvider).fetchWallets();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(walletRepositoryProvider).fetchWallets(),
    );
  }

  Future<void> createWallet({
    required String name,
    required WalletType type,
    required double initialBalance,
    required bool isDefault,
  }) async {
    state = const AsyncLoading();

    try {
      await ref
          .read(walletRepositoryProvider)
          .createWallet(
            name: name,
            type: type,
            initialBalance: initialBalance,
            isDefault: isDefault,
          );
      state = AsyncData(
        await ref.read(walletRepositoryProvider).fetchWallets(),
      );
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      rethrow;
    }
  }

  Future<void> updateWallet({
    required String walletId,
    required String name,
    required WalletType type,
    required double initialBalance,
    required bool isDefault,
    required bool isActive,
  }) async {
    state = const AsyncLoading();

    try {
      await ref
          .read(walletRepositoryProvider)
          .updateWallet(
            walletId: walletId,
            name: name,
            type: type,
            initialBalance: initialBalance,
            isDefault: isDefault,
            isActive: isActive,
          );
      state = AsyncData(
        await ref.read(walletRepositoryProvider).fetchWallets(),
      );
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      rethrow;
    }
  }
}
