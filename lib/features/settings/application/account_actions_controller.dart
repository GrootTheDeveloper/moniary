import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/account_repository.dart';

final accountActionsControllerProvider =
    AsyncNotifierProvider<AccountActionsController, void>(
  AccountActionsController.new,
);

class AccountActionsController extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<File?> exportCsv() async {
    state = const AsyncLoading();
    File? exportedFile;
    state = await AsyncValue.guard(() async {
      exportedFile = await ref.read(accountRepositoryProvider).exportTransactionsCsv();
    });
    return exportedFile;
  }

  Future<File?> exportXlsx() async {
    state = const AsyncLoading();
    File? exportedFile;
    state = await AsyncValue.guard(() async {
      exportedFile = await ref.read(accountRepositoryProvider).exportTransactionsXlsx();
    });
    return exportedFile;
  }

  Future<File?> exportPdf() async {
    state = const AsyncLoading();
    File? exportedFile;
    state = await AsyncValue.guard(() async {
      exportedFile = await ref.read(accountRepositoryProvider).exportTransactionsPdf();
    });
    return exportedFile;
  }

  Future<void> deleteAccount() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(accountRepositoryProvider).deleteAccount(),
    );
  }
}
