import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../settings/data/account/account_repository.dart';

final accountStatusControllerProvider =
    AsyncNotifierProvider<AccountStatusController, bool>(
      AccountStatusController.new,
    );

class AccountStatusController extends AsyncNotifier<bool> {
  @override
  Future<bool> build() async {
    return ref.watch(accountRepositoryProvider).isAccountPendingDeletion();
  }

  Future<void> restoreAccount() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(accountRepositoryProvider).restoreAccount();
      return false;
    });
  }
}
