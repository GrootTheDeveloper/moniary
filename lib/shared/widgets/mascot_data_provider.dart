import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/budgets/application/budget_controller.dart';
import '../../features/budgets/domain/monthly_budget.dart';
import '../../features/journal/application/journal_controller.dart';
import '../../features/transactions/application/queries/transaction_queries.dart';
import '../../features/transactions/data/repositories/transaction_repository.dart';
import '../../features/transactions/domain/models/transaction_entry.dart';

/// Aggregated data snapshot consumed by [MascotOverlay] to pick dialogue.
class MascotData {
  const MascotData({
    required this.allTimeEmpty,
    required this.budgetCategories,
    required this.todayTransactions,
    required this.monthTransactions,
    required this.streakDays,
  });

  final bool allTimeEmpty;
  final List<CategoryBudget> budgetCategories;
  final List<TransactionEntry> todayTransactions;
  final List<TransactionEntry> monthTransactions;
  final int streakDays;
}

/// Provides [MascotData] by combining existing providers.
/// Uses `.when()` with `skipLoadingOnRefresh: false` so that stale data
/// is shown while refreshing instead of showing a loading state.
final mascotDataProvider = FutureProvider<MascotData>((ref) async {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);

  // Re-use providers that are already cached by the app.
  final monthAsyncValue = ref.watch(
    monthlyBudgetProvider(DateTime(now.year, now.month)),
  );
  final todayAsyncValue = ref.watch(transactionsForDayProvider(today));

  // Watch the recording streak of the user
  final streakAsyncValue = ref.watch(recordingStreakProvider);
  final streakDays =
      streakAsyncValue.whenOrNull(data: (s) => s.currentDays) ?? 0;

  // Fetch full month transactions for savings-rate calculation.
  final monthTransactions = await ref
      .watch(transactionRepositoryProvider)
      .fetchTransactionsForMonth(DateTime(now.year, now.month));

  final budgetCategories =
      monthAsyncValue.whenOrNull(data: (b) => b.categories) ??
      const <CategoryBudget>[];

  final todayTransactions =
      todayAsyncValue.whenOrNull(data: (list) => list) ??
      const <TransactionEntry>[];

  final hasTx = await ref
      .watch(transactionRepositoryProvider)
      .hasAnyTransactions();
  final allTimeEmpty = !hasTx;

  return MascotData(
    allTimeEmpty: allTimeEmpty,
    budgetCategories: budgetCategories,
    todayTransactions: todayTransactions,
    monthTransactions: monthTransactions,
    streakDays: streakDays,
  );
});
