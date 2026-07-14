import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../../features/budgets/domain/monthly_budget.dart';
import '../../features/transactions/domain/models/transaction_entry.dart';
import '../../l10n/l10n_extension.dart';

/// Pure logic class that selects a mascot dialogue string.
///
/// Priority cascade (highest → lowest):
///   0. No transactions ever (empty app state) → encourage first log
///   1. Any budget category is over limit → over-budget warning
///   2. Any budget category is near limit → near-budget warning
///   3. No spending recorded today (but past data exists) → praise
///   4. Good savings rate (>25%) this month → celebrate
///   5. Fallback → rotate through 5 fun quotes
class MascotDialogueGenerator {
  MascotDialogueGenerator._();

  static final math.Random _rng = math.Random();

  // Index used to rotate fun quotes deterministically across taps.
  static int _funQuoteIndex = 0;

  /// Returns a localised dialogue string based on the provided data.
  ///
  /// [allTimeEmpty]  – true when the user has never recorded any transaction.
  /// [budgetCategories] – categories with budget limits for the current month.
  /// [todayTransactions] – transactions recorded today (may be empty).
  /// [monthTransactions] – all transactions for the current month.
  static String generate(
    BuildContext context, {
    required bool allTimeEmpty,
    required List<CategoryBudget> budgetCategories,
    required List<TransactionEntry> todayTransactions,
    required List<TransactionEntry> monthTransactions,
  }) {
    final l10n = context.l10n;

    // 0. No data at all → encourage first transaction
    if (allTimeEmpty) {
      return l10n.mascotFirstTransaction;
    }

    // 1. Over-budget category
    final overLimit = budgetCategories.where((c) => c.isOverLimit).toList();
    if (overLimit.isNotEmpty) {
      return l10n.mascotOverBudget(overLimit.first.categoryName);
    }

    // 2. Near-budget category
    final nearLimit = budgetCategories.where((c) => c.isNearLimit).toList();
    if (nearLimit.isNotEmpty) {
      return l10n.mascotNearBudget(nearLimit.first.categoryName);
    }

    // 3. No spending today (but user has past data)
    final todayExpenses = todayTransactions.where((t) => t.isExpense).toList();
    if (todayExpenses.isEmpty) {
      return l10n.mascotZeroExpenseToday;
    }

    // 4. Good savings rate this month (>25%)
    final income = monthTransactions
        .where((t) => t.isIncome)
        .fold<double>(0, (sum, t) => sum + t.amount);
    final expense = monthTransactions
        .where((t) => t.isExpense)
        .fold<double>(0, (sum, t) => sum + t.amount);
    if (income > 0) {
      final savingsRate = ((income - expense) / income) * 100;
      if (savingsRate > 25) {
        return l10n.mascotGoodSavings(savingsRate.toStringAsFixed(0));
      }
    }

    // 5. Rotate fun quotes
    final quotes = [
      l10n.mascotFunQuote1,
      l10n.mascotFunQuote2,
      l10n.mascotFunQuote3,
      l10n.mascotFunQuote4,
      l10n.mascotFunQuote5,
    ];
    final quote = quotes[_funQuoteIndex % quotes.length];
    _funQuoteIndex = (_funQuoteIndex + 1) % quotes.length;
    return quote;
  }

  /// Returns a random fun quote without advancing the rotation index.
  /// Useful for an idle/greeting bubble.
  static String randomFunQuote(BuildContext context) {
    final l10n = context.l10n;
    final quotes = [
      l10n.mascotFunQuote1,
      l10n.mascotFunQuote2,
      l10n.mascotFunQuote3,
      l10n.mascotFunQuote4,
      l10n.mascotFunQuote5,
    ];
    return quotes[_rng.nextInt(quotes.length)];
  }
}
