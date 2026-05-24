import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../calendar/application/calendar_filter_provider.dart';
import '../data/transaction_repository.dart';
import '../domain/transaction_entry.dart';

final transactionsForDayProvider =
    FutureProvider.family<List<TransactionEntry>, DateTime>((ref, day) async {
  final filters = ref.watch(calendarFilterProvider);
  return ref.watch(transactionRepositoryProvider).fetchTransactionsForDay(
        day,
        walletId: filters.walletId,
        categoryId: filters.categoryId,
      );
});

final transactionByIdProvider =
    FutureProvider.family<TransactionEntry, String>((ref, transactionId) async {
  return ref.watch(transactionRepositoryProvider).fetchTransactionById(transactionId);
});
