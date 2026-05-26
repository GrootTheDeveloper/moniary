import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/account_repository.dart';

final accountActionsControllerProvider =
    AsyncNotifierProvider<AccountActionsController, void>(
  AccountActionsController.new,
);

class AccountActionsController extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<void> deleteAccount() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(accountRepositoryProvider).deleteAccount(),
    );
  }
}
