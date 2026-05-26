import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/account_repository.dart';
import '../domain/export_filters.dart';

final accountActionsControllerProvider =
    AsyncNotifierProvider<AccountActionsController, void>(
  AccountActionsController.new,
);

class AccountActionsController extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<File?> exportCsv({ExportFilters filters = const ExportFilters()}) async {
    state = const AsyncLoading();
    File? exportedFile;
    state = await AsyncValue.guard(() async {
      exportedFile = await ref.read(accountRepositoryProvider).exportTransactionsCsv(
            filters: filters,
          );
    });
    return exportedFile;
  }

  Future<File?> exportXlsx({ExportFilters filters = const ExportFilters()}) async {
    state = const AsyncLoading();
    File? exportedFile;
    state = await AsyncValue.guard(() async {
      exportedFile = await ref.read(accountRepositoryProvider).exportTransactionsXlsx(
            filters: filters,
          );
    });
    return exportedFile;
  }

  Future<File?> exportPdf({ExportFilters filters = const ExportFilters()}) async {
    state = const AsyncLoading();
    File? exportedFile;
    state = await AsyncValue.guard(() async {
      exportedFile = await ref.read(accountRepositoryProvider).exportTransactionsPdf(
            filters: filters,
          );
    });
    return exportedFile;
  }

  Future<void> deleteAccount() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(accountRepositoryProvider).deleteAccount(),
    );
  }

  Future<File?> createDeletionRequest({required String reason}) async {
    state = const AsyncLoading();
    File? requestFile;
    state = await AsyncValue.guard(() async {
      requestFile = await ref.read(accountRepositoryProvider).createDeletionRequest(
            reason: reason,
          );
    });
    return requestFile;
  }
}
