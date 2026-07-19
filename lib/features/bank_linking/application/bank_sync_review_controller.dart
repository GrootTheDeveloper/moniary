import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../transactions/application/composer/transaction_composer_controller.dart';
import '../data/repositories/bank_link_repository_impl.dart';
import '../domain/models/pending_synced_transaction.dart';

final bankSyncReviewControllerProvider =
    AsyncNotifierProvider<
      BankSyncReviewController,
      List<PendingSyncedTransaction>
    >(BankSyncReviewController.new);

class BankSyncReviewController
    extends AsyncNotifier<List<PendingSyncedTransaction>> {
  @override
  Future<List<PendingSyncedTransaction>> build() {
    return ref
        .watch(bankLinkRepositoryProvider)
        .fetchPendingSyncedTransactions();
  }

  Future<void> confirm({
    required String pendingId,
    required String walletId,
    required String categoryId,
  }) async {
    state = const AsyncLoading();
    try {
      final repo = ref.read(bankLinkRepositoryProvider);
      final pending = (await repo.fetchPendingSyncedTransactions()).firstWhere(
        (item) => item.id == pendingId,
      );
      final result = await ref
          .read(transactionComposerProvider.notifier)
          .createTransaction(
            amount: pending.amount,
            type: pending.type,
            walletId: walletId,
            categoryId: categoryId,
            transactionDate: pending.transactionDate,
            merchantName: pending.merchantName,
            source: 'bank_sync',
          );
      await repo.markSyncedTransactionConfirmed(
        pendingId: pendingId,
        transactionId: result.transactionId,
      );
      state = AsyncData(await repo.fetchPendingSyncedTransactions());
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      rethrow;
    }
  }

  Future<void> dismiss(String pendingId) async {
    state = const AsyncLoading();
    try {
      final repo = ref.read(bankLinkRepositoryProvider);
      await repo.dismissSyncedTransaction(pendingId);
      state = AsyncData(await repo.fetchPendingSyncedTransactions());
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      rethrow;
    }
  }
}
