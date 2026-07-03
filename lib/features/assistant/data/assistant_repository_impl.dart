import 'dart:math' as math;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/preferences/preferences_providers.dart';
import '../../transactions/data/repositories/transaction_repository.dart';
import '../../transactions/domain/models/transaction_entry.dart';
import '../domain/assistant_models.dart';
import '../domain/assistant_repository.dart';

final assistantRepositoryProvider = Provider<AssistantRepository>((ref) {
  return AssistantRepositoryImpl(
    preferences: ref.watch(sharedPreferencesProvider),
    transactionRepository: ref.watch(transactionRepositoryProvider),
  );
});

class AssistantRepositoryImpl implements AssistantRepository {
  AssistantRepositoryImpl({
    required SharedPreferences preferences,
    required TransactionRepository transactionRepository,
  }) : _preferences = preferences,
       _transactions = transactionRepository;

  static const _introSeenKey = 'assistant_intro_seen';
  static const _enabledKey = 'assistant_enabled';
  static const _transactionsKey = 'assistant_access_transactions';
  static const _walletsKey = 'assistant_access_wallets';
  static const _budgetsKey = 'assistant_access_budgets';

  final SharedPreferences _preferences;
  final TransactionRepository _transactions;

  @override
  Future<AssistantAccess> loadAccess() async {
    return AssistantAccess(
      introSeen: _preferences.getBool(_introSeenKey) ?? false,
      enabled: _preferences.getBool(_enabledKey) ?? false,
      transactions: _preferences.getBool(_transactionsKey) ?? true,
      wallets: _preferences.getBool(_walletsKey) ?? true,
      budgets: _preferences.getBool(_budgetsKey) ?? true,
    );
  }

  @override
  Future<void> saveAccess(AssistantAccess access) async {
    await Future.wait([
      _preferences.setBool(_introSeenKey, access.introSeen),
      _preferences.setBool(_enabledKey, access.enabled),
      _preferences.setBool(_transactionsKey, access.transactions),
      _preferences.setBool(_walletsKey, access.wallets),
      _preferences.setBool(_budgetsKey, access.budgets),
    ]);
  }

  @override
  Future<FinancialAssistantSnapshot> buildSnapshot(DateTime now) async {
    final access = await loadAccess();
    if (!access.enabled || !access.transactions) {
      return const FinancialAssistantSnapshot(
        monthlyExpense: 0,
        previousMonthExpense: 0,
        currentWeekExpense: 0,
        previousWeekExpense: 0,
        dailyAverage: 0,
        topCategoryName: null,
        topCategoryAmount: 0,
        topCategoryShare: 0,
        recurringLabel: null,
        recurringCount: 0,
        recurringAmount: 0,
        suggestedSaving: 0,
      );
    }
    final currentMonth = DateTime(now.year, now.month);
    final previousMonth = DateTime(now.year, now.month - 1);
    final results = await Future.wait([
      _transactions.fetchTransactionsForMonth(currentMonth),
      _transactions.fetchTransactionsForMonth(previousMonth),
    ]);
    final current = results[0].where((entry) => entry.isExpense).toList();
    final previous = results[1].where((entry) => entry.isExpense).toList();

    final monthExpense = _sum(current);
    final previousMonthExpense = _sum(previous);
    final today = DateTime(now.year, now.month, now.day);
    final currentWeekStart = today.subtract(
      Duration(days: today.weekday - DateTime.monday),
    );
    final previousWeekStart = currentWeekStart.subtract(
      const Duration(days: 7),
    );
    final currentWeekExpense = _sum(
      current.where(
        (entry) => !entry.transactionDate.isBefore(currentWeekStart),
      ),
    );
    final previousWeekExpense = _sum(
      [...current, ...previous].where((entry) {
        return !entry.transactionDate.isBefore(previousWeekStart) &&
            entry.transactionDate.isBefore(currentWeekStart);
      }),
    );

    final categoryTotals = <String, double>{};
    for (final entry in current) {
      categoryTotals[entry.categoryName] =
          (categoryTotals[entry.categoryName] ?? 0) + entry.amount;
    }
    final topCategory = categoryTotals.entries.isEmpty
        ? null
        : categoryTotals.entries.reduce((a, b) => a.value >= b.value ? a : b);

    final repeated = <String, List<TransactionEntry>>{};
    for (final entry in current) {
      final label =
          (entry.note?.trim().isNotEmpty == true
                  ? entry.note!
                  : entry.categoryName)
              .trim()
              .toLowerCase();
      repeated.putIfAbsent(label, () => []).add(entry);
    }
    final recurring = repeated.entries
        .where((entry) => entry.value.length >= 2)
        .fold<MapEntry<String, List<TransactionEntry>>?>(
          null,
          (best, entry) =>
              best == null || entry.value.length > best.value.length
              ? entry
              : best,
        );

    final daysElapsed = math.max(1, now.day);
    final suggestedSaving = topCategory == null
        ? 0.0
        : math.min(topCategory.value * 0.15, monthExpense * 0.1);

    return FinancialAssistantSnapshot(
      monthlyExpense: monthExpense,
      previousMonthExpense: previousMonthExpense,
      currentWeekExpense: currentWeekExpense,
      previousWeekExpense: previousWeekExpense,
      dailyAverage: monthExpense / daysElapsed,
      topCategoryName: topCategory?.key,
      topCategoryAmount: topCategory?.value ?? 0,
      topCategoryShare: monthExpense <= 0
          ? 0
          : (topCategory?.value ?? 0) / monthExpense,
      recurringLabel: recurring?.value.first.note?.trim().isNotEmpty == true
          ? recurring!.value.first.note!.trim()
          : recurring?.value.first.categoryName,
      recurringCount: recurring?.value.length ?? 0,
      recurringAmount: recurring == null ? 0 : _sum(recurring.value),
      suggestedSaving: suggestedSaving,
    );
  }

  double _sum(Iterable<TransactionEntry> entries) {
    return entries.fold(0, (sum, entry) => sum + entry.amount);
  }
}
