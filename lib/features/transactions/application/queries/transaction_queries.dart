import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../calendar/application/month/calendar_filter_provider.dart';
import '../../data/repositories/transaction_repository.dart';
import '../../domain/models/transaction_entry.dart';

final transactionsForDayProvider =
    FutureProvider.family<List<TransactionEntry>, DateTime>((ref, day) async {
      final filters = ref.watch(calendarFilterProvider);
      return ref
          .watch(transactionRepositoryProvider)
          .fetchTransactionsForDay(
            day,
            walletId: filters.walletId,
            categoryId: filters.categoryId,
          );
    });

final transactionByIdProvider = FutureProvider.family<TransactionEntry, String>(
  (ref, transactionId) async {
    return ref
        .watch(transactionRepositoryProvider)
        .fetchTransactionById(transactionId);
  },
);

final starredTransactionsProvider = FutureProvider<List<TransactionEntry>>((
  ref,
) async {
  return ref.watch(transactionRepositoryProvider).fetchStarredTransactions();
});

final transactionSearchProvider =
    FutureProvider.family<List<TransactionEntry>, String>((ref, query) async {
      return ref
          .watch(transactionRepositoryProvider)
          .searchTransactions(query);
    });
