import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../categories/domain/models/category.dart';
import '../../transactions/data/repositories/transaction_repository.dart';
import '../data/repositories/recurring_transaction_repository.dart';
import '../domain/models/recurring_transaction.dart';

final recurringControllerProvider =
    AsyncNotifierProvider<RecurringController, List<RecurringTransaction>>(
      RecurringController.new,
    );

class RecurringController extends AsyncNotifier<List<RecurringTransaction>> {
  RecurringTransactionRepository get _repository =>
      ref.read(recurringTransactionRepositoryProvider);

  @override
  Future<List<RecurringTransaction>> build() {
    return _repository.fetchRecurringTransactions();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_repository.fetchRecurringTransactions);
  }

  Future<void> createRecurring({
    required double amount,
    required TransactionType type,
    required String walletId,
    required String categoryId,
    required RecurringFrequency frequency,
    required int interval,
    required DateTime startDate,
    required DateTime nextRunDate,
    DateTime? endDate,
    String? note,
    bool autoPost = false,
  }) async {
    state = const AsyncLoading();
    try {
      await _repository.createRecurringTransaction(
        amount: amount,
        type: type,
        walletId: walletId,
        categoryId: categoryId,
        frequency: frequency,
        interval: interval,
        startDate: startDate,
        nextRunDate: nextRunDate,
        endDate: endDate,
        note: note,
        autoPost: autoPost,
      );
      state = AsyncData(await _repository.fetchRecurringTransactions());
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      rethrow;
    }
  }

  Future<void> updateRecurring({
    required String id,
    required double amount,
    required TransactionType type,
    required String walletId,
    required String categoryId,
    required RecurringFrequency frequency,
    required int interval,
    required DateTime startDate,
    required DateTime nextRunDate,
    required bool isActive,
    DateTime? endDate,
    String? note,
    bool autoPost = false,
    RecurringApplyMode applyMode = RecurringApplyMode.futureOnly,
  }) async {
    state = const AsyncLoading();
    try {
      await _repository.updateRecurringTransaction(
        id: id,
        amount: amount,
        type: type,
        walletId: walletId,
        categoryId: categoryId,
        frequency: frequency,
        interval: interval,
        startDate: startDate,
        nextRunDate: nextRunDate,
        isActive: isActive,
        endDate: endDate,
        note: note,
        autoPost: autoPost,
      );

      switch (applyMode) {
        case RecurringApplyMode.futureOnly:
          break;
        case RecurringApplyMode.updateExisting:
          await ref
              .read(transactionRepositoryProvider)
              .updateGeneratedTransactions(
                recurringTransactionId: id,
                amount: amount,
                type: type,
                walletId: walletId,
                categoryId: categoryId,
                note: note,
              );
        case RecurringApplyMode.deleteAndRegenerate:
          await ref
              .read(transactionRepositoryProvider)
              .deleteGeneratedTransactions(id);
          // Rewind the schedule so materialization reposts from the start.
          await _repository.advanceSchedule(
            id: id,
            nextRunDate: startDate,
            lastRunDate: null,
            isActive: isActive,
          );
      }

      state = AsyncData(await _repository.fetchRecurringTransactions());
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      rethrow;
    }
  }

  Future<int> generatedTransactionCount(String id) {
    return ref
        .read(transactionRepositoryProvider)
        .countGeneratedTransactions(id);
  }

  Future<void> deleteRecurring(
    String id, {
    bool deleteGeneratedTransactions = false,
  }) async {
    state = const AsyncLoading();
    try {
      if (deleteGeneratedTransactions) {
        await ref
            .read(transactionRepositoryProvider)
            .deleteGeneratedTransactions(id);
      }
      await _repository.deleteRecurringTransaction(id);
      state = AsyncData(await _repository.fetchRecurringTransactions());
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      rethrow;
    }
  }
}
