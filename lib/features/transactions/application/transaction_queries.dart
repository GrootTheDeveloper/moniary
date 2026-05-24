import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/transaction_repository.dart';
import '../domain/transaction_entry.dart';

final transactionsForDayProvider =
    FutureProvider.family<List<TransactionEntry>, DateTime>((ref, day) async {
  return ref.watch(transactionRepositoryProvider).fetchTransactionsForDay(day);
});

final transactionByIdProvider =
    FutureProvider.family<TransactionEntry, String>((ref, transactionId) async {
  return ref.watch(transactionRepositoryProvider).fetchTransactionById(transactionId);
});
