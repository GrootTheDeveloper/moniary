import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../settings/data/account/account_repository.dart';
import '../../settings/domain/account/account_deletion_status.dart';

final accountStatusControllerProvider =
    AsyncNotifierProvider<AccountStatusController, AccountDeletionStatus>(
      AccountStatusController.new,
    );

class AccountStatusController extends AsyncNotifier<AccountDeletionStatus> {
  @override
  Future<AccountDeletionStatus> build() async {
    return ref.watch(accountRepositoryProvider).fetchAccountDeletionStatus();
  }

  Future<void> restoreAccount() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(accountRepositoryProvider).restoreAccount();
      return AccountDeletionStatus.active;
    });
  }
}
