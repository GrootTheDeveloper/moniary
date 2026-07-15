import 'dart:math' as math;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/preferences/preferences_providers.dart';
import '../../../core/supabase/app_exception.dart';
import '../../../core/supabase/supabase_providers.dart';
import '../../../shared/utils/app_logger.dart';
import '../../budgets/data/budget_repository_impl.dart';
import '../../budgets/domain/budget_repository.dart';
import '../../budgets/domain/monthly_budget.dart';
import '../../transactions/data/repositories/transaction_repository.dart';
import '../../transactions/domain/models/transaction_entry.dart';
import '../../wallets/data/repositories/wallet_repository.dart';
import '../domain/assistant_models.dart';
import '../domain/assistant_repository.dart';

final assistantRepositoryProvider = Provider<AssistantRepository>((ref) {
  return AssistantRepositoryImpl(
    preferences: ref.watch(sharedPreferencesProvider),
    transactionRepository: ref.watch(transactionRepositoryProvider),
    walletRepository: ref.watch(walletRepositoryProvider),
    budgetRepository: ref.watch(budgetRepositoryProvider),
    client: ref.watch(supabaseClientProvider),
    useMockData: ref.watch(useMockDataModeProvider),
  );
});

class AssistantRepositoryImpl implements AssistantRepository {
  AssistantRepositoryImpl({
    required SharedPreferences preferences,
    required TransactionRepository transactionRepository,
    required WalletRepository walletRepository,
    required BudgetRepository budgetRepository,
    required SupabaseClient client,
    bool useMockData = false,
  }) : _preferences = preferences,
       _transactions = transactionRepository,
       _wallets = walletRepository,
       _budgets = budgetRepository,
       _client = client,
       _useMockData = useMockData;

  static const _introSeenKey = 'assistant_intro_seen';
  static const _enabledKey = 'assistant_enabled';
  static const _transactionsKey = 'assistant_access_transactions';
  static const _walletsKey = 'assistant_access_wallets';
  static const _budgetsKey = 'assistant_access_budgets';

  final SharedPreferences _preferences;
  final TransactionRepository _transactions;
  final WalletRepository _wallets;
  final BudgetRepository _budgets;
  final SupabaseClient _client;
  final bool _useMockData;

  @override
  Future<AssistantAccess> loadAccess() async {
    if (_useMockData || _session == null) {
      return _loadLocalAccess(allowLegacyFallback: true);
    }

    try {
      final row = await _client
          .from('assistant_preferences')
          .select()
          .eq('user_id', _session!.user.id)
          .maybeSingle();
      if (row == null) return _loadLocalAccess(allowLegacyFallback: false);
      return _accessFromRow(row);
    } on PostgrestException catch (error, stackTrace) {
      AppLogger.error(
        'Failed to load assistant preferences',
        error,
        stackTrace,
      );
      return _loadLocalAccess(allowLegacyFallback: false);
    }
  }

  @override
  Future<void> saveAccess(AssistantAccess access) async {
    await _saveLocalAccess(access);
    if (_useMockData || _session == null) return;

    final userId = _session!.user.id;
    try {
      await _client.from('assistant_preferences').upsert({
        'user_id': userId,
        'intro_seen': access.introSeen,
        'enabled': access.enabled,
        'transactions': access.transactions,
        'wallets': access.wallets,
        'budgets': access.budgets,
        'consented_at': access.enabled
            ? DateTime.now().toUtc().toIso8601String()
            : null,
      }, onConflict: 'user_id');
    } on PostgrestException catch (error, stackTrace) {
      AppLogger.error(
        'Failed to save assistant preferences',
        error,
        stackTrace,
      );
      throw AppException(error.message, code: error.code);
    }
  }

  @override
  Future<FinancialAssistantSnapshot> buildSnapshot(
    AssistantSnapshotWindow window,
  ) async {
    final access = await loadAccess();
    if (!access.enabled || !access.transactions) {
      return const FinancialAssistantSnapshot.empty();
    }

    final all = await _transactions.fetchTransactionsForRange(
      start: window.previousMonthStart,
      end: window.nextMonthStart,
    );
    final visibleTransactions = all
        .where((entry) => !entry.transactionDate.isAfter(window.now))
        .toList();
    final currentMonthTransactions = visibleTransactions.where((entry) {
      return !entry.transactionDate.isBefore(window.currentMonthStart) &&
          entry.transactionDate.isBefore(window.nextMonthStart);
    }).toList();
    final previousMonthTransactions = visibleTransactions.where((entry) {
      return !entry.transactionDate.isBefore(window.previousMonthStart) &&
          entry.transactionDate.isBefore(window.currentMonthStart);
    }).toList();

    final currentExpenses = currentMonthTransactions
        .where((entry) => entry.isExpense)
        .toList();
    final previousExpenses = previousMonthTransactions
        .where((entry) => entry.isExpense)
        .toList();
    final currentIncome = currentMonthTransactions
        .where((entry) => entry.isIncome)
        .toList();

    final monthExpense = _sum(currentExpenses);
    final previousMonthExpense = _sum(previousExpenses);
    final monthIncome = _sum(currentIncome);
    final currentWeekExpense = _sum(
      visibleTransactions.where((entry) {
        return entry.isExpense &&
            !entry.transactionDate.isBefore(window.currentWeekStart);
      }),
    );
    final previousWeekExpense = _sum(
      visibleTransactions.where((entry) {
        return entry.isExpense &&
            !entry.transactionDate.isBefore(window.previousWeekStart) &&
            entry.transactionDate.isBefore(window.currentWeekStart);
      }),
    );

    final topCategory = _topExpenseCategory(currentExpenses);
    final recurring =
        await _configuredRecurringCandidate() ??
        _recurringCandidateFromTransactions(visibleTransactions);
    final daysElapsed = math.max(1, window.daysElapsed);
    final suggestedSaving = topCategory == null
        ? 0.0
        : math.min(topCategory.value * 0.15, monthExpense * 0.1);
    final walletSummary = access.wallets
        ? await _walletSummary()
        : const _WalletSummary.empty();
    final budgetSummary = access.budgets
        ? await _budgetSummary(window.budgetMonth)
        : const _BudgetSummary.empty();

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
      recurringLabel: recurring?.label,
      recurringCount: recurring?.count ?? 0,
      recurringAmount: recurring?.amount ?? 0,
      suggestedSaving: suggestedSaving,
      monthlyIncome: monthIncome,
      walletsIncluded: walletSummary.included,
      totalWalletBalance: walletSummary.totalBalance,
      activeWalletCount: walletSummary.activeCount,
      budgetsIncluded: budgetSummary.included,
      budgetLimit: budgetSummary.totalLimit,
      budgetSpent: budgetSummary.totalSpent,
      budgetProgress: budgetSummary.progress,
      overBudgetCategoryName: budgetSummary.overBudgetCategoryName,
      overBudgetAmount: budgetSummary.overBudgetAmount,
    );
  }

  @override
  Future<String?> generateAnswer({
    required String question,
    required AssistantQuestionKind kind,
    required String locale,
    required String currencyCode,
    required List<AssistantMessage> history,
    FinancialAssistantSnapshot? snapshot,
    String? profileName,
  }) async {
    if (_useMockData || _session == null) return null;

    try {
      final response = await _client.functions.invoke(
        'assistant-chat',
        body: {
          'question': question,
          'kind': kind.name,
          'locale': locale,
          'currencyCode': currencyCode,
          'profileName': profileName,
          'snapshot': snapshot?.toJson(),
          'history': history
              .map((message) => message.toHistoryJson())
              .whereType<Map<String, String>>()
              .toList(),
        },
      );
      final data = response.data;
      if (data is! Map<String, dynamic>) return null;
      final answer = data['answer'];
      return answer is String && answer.trim().isNotEmpty
          ? answer.trim()
          : null;
    } catch (error, stackTrace) {
      AppLogger.error(
        'Assistant Edge Function request failed',
        error,
        stackTrace,
      );
      return null;
    }
  }

  Session? get _session => _client.auth.currentSession;

  AssistantAccess _accessFromRow(Map<String, dynamic> row) {
    return AssistantAccess(
      introSeen: row['intro_seen'] as bool? ?? false,
      enabled: row['enabled'] as bool? ?? false,
      transactions: row['transactions'] as bool? ?? true,
      wallets: row['wallets'] as bool? ?? true,
      budgets: row['budgets'] as bool? ?? false,
    );
  }

  AssistantAccess _loadLocalAccess({required bool allowLegacyFallback}) {
    bool readBool(String key, bool fallback) {
      return _preferences.getBool(_scopedKey(key)) ??
          (allowLegacyFallback ? _preferences.getBool(key) : null) ??
          fallback;
    }

    return AssistantAccess(
      introSeen: readBool(_introSeenKey, false),
      enabled: readBool(_enabledKey, false),
      transactions: readBool(_transactionsKey, true),
      wallets: readBool(_walletsKey, true),
      budgets: readBool(_budgetsKey, false),
    );
  }

  Future<void> _saveLocalAccess(AssistantAccess access) {
    return Future.wait([
      _preferences.setBool(_scopedKey(_introSeenKey), access.introSeen),
      _preferences.setBool(_scopedKey(_enabledKey), access.enabled),
      _preferences.setBool(_scopedKey(_transactionsKey), access.transactions),
      _preferences.setBool(_scopedKey(_walletsKey), access.wallets),
      _preferences.setBool(_scopedKey(_budgetsKey), access.budgets),
    ]);
  }

  String _scopedKey(String key) {
    final userId = _useMockData ? 'guest' : (_session?.user.id ?? 'guest');
    return 'assistant.$userId.$key';
  }

  MapEntry<String, double>? _topExpenseCategory(
    Iterable<TransactionEntry> expenses,
  ) {
    final totals = <String, double>{};
    for (final entry in expenses) {
      totals[entry.categoryName] =
          (totals[entry.categoryName] ?? 0) + entry.amount;
    }
    return totals.entries.isEmpty
        ? null
        : totals.entries.reduce((a, b) => a.value >= b.value ? a : b);
  }

  Future<_RecurringCandidate?> _configuredRecurringCandidate() async {
    if (_useMockData || _session == null) return null;
    try {
      final rows = await _client
          .from('recurring_transactions')
          .select('note, amount, category:categories!inner(name)')
          .eq('user_id', _session!.user.id)
          .eq('is_active', true)
          .eq('type', 'expense')
          .order('amount', ascending: false)
          .limit(1);
      final list = (rows as List<dynamic>).cast<Map<String, dynamic>>();
      if (list.isEmpty) return null;
      final row = list.first;
      final category = row['category'] as Map<String, dynamic>? ?? const {};
      final label =
          ((row['note'] as String?)?.trim().isNotEmpty == true
                  ? row['note'] as String
                  : category['name'] as String?)
              ?.trim();
      final amount = (row['amount'] as num?)?.toDouble() ?? 0;
      if (label == null || label.isEmpty || amount <= 0) return null;
      return _RecurringCandidate(label: label, count: 1, amount: amount);
    } catch (error, stackTrace) {
      AppLogger.warning('Failed to load configured recurring transactions');
      AppLogger.error('Recurring transaction lookup failed', error, stackTrace);
      return null;
    }
  }

  _RecurringCandidate? _recurringCandidateFromTransactions(
    Iterable<TransactionEntry> transactions,
  ) {
    final repeated = <String, List<TransactionEntry>>{};
    for (final entry in transactions.where((entry) => entry.isExpense)) {
      final label =
          (entry.note?.trim().isNotEmpty == true
                  ? entry.note!
                  : entry.categoryName)
              .trim()
              .toLowerCase();
      final roundedAmount = entry.amount.round();
      repeated.putIfAbsent('$label|$roundedAmount', () => []).add(entry);
    }

    final recurring = repeated.entries
        .where((entry) => entry.value.length >= 3)
        .fold<MapEntry<String, List<TransactionEntry>>?>(
          null,
          (best, entry) =>
              best == null || entry.value.length > best.value.length
              ? entry
              : best,
        );
    if (recurring == null) return null;

    final first = recurring.value.first;
    final label = first.note?.trim().isNotEmpty == true
        ? first.note!.trim()
        : first.categoryName;
    return _RecurringCandidate(
      label: label,
      count: recurring.value.length,
      amount: _sum(recurring.value),
    );
  }

  Future<_WalletSummary> _walletSummary() async {
    try {
      final wallets = await _wallets.fetchWallets();
      final active = wallets.where((wallet) => wallet.isActive).toList();
      return _WalletSummary(
        included: true,
        totalBalance: active.fold(
          0,
          (sum, wallet) => sum + wallet.initialBalance,
        ),
        activeCount: active.length,
      );
    } catch (error, stackTrace) {
      AppLogger.error(
        'Failed to build assistant wallet summary',
        error,
        stackTrace,
      );
      return const _WalletSummary.empty();
    }
  }

  Future<_BudgetSummary> _budgetSummary(DateTime month) async {
    try {
      final budget = await _budgets.fetchMonthlyBudget(month);
      final overBudget = budget.categories
          .where((category) => category.isOverLimit)
          .fold<CategoryBudget?>(
            null,
            (best, category) =>
                best == null ||
                    category.spentAmount - category.limitAmount >
                        best.spentAmount - best.limitAmount
                ? category
                : best,
          );
      return _BudgetSummary(
        included: true,
        totalLimit: budget.totalLimit,
        totalSpent: budget.totalSpent,
        progress: budget.progress,
        overBudgetCategoryName: overBudget?.categoryName,
        overBudgetAmount: overBudget == null
            ? 0
            : overBudget.spentAmount - overBudget.limitAmount,
      );
    } catch (error, stackTrace) {
      AppLogger.error(
        'Failed to build assistant budget summary',
        error,
        stackTrace,
      );
      return const _BudgetSummary.empty();
    }
  }

  double _sum(Iterable<TransactionEntry> entries) {
    return entries.fold(0, (sum, entry) => sum + entry.amount);
  }
}

class _RecurringCandidate {
  const _RecurringCandidate({
    required this.label,
    required this.count,
    required this.amount,
  });

  final String label;
  final int count;
  final double amount;
}

class _WalletSummary {
  const _WalletSummary({
    required this.included,
    required this.totalBalance,
    required this.activeCount,
  });

  const _WalletSummary.empty()
    : included = false,
      totalBalance = 0,
      activeCount = 0;

  final bool included;
  final double totalBalance;
  final int activeCount;
}

class _BudgetSummary {
  const _BudgetSummary({
    required this.included,
    required this.totalLimit,
    required this.totalSpent,
    required this.progress,
    this.overBudgetCategoryName,
    this.overBudgetAmount = 0,
  });

  const _BudgetSummary.empty()
    : included = false,
      totalLimit = 0,
      totalSpent = 0,
      progress = 0,
      overBudgetCategoryName = null,
      overBudgetAmount = 0;

  final bool included;
  final double totalLimit;
  final double totalSpent;
  final double progress;
  final String? overBudgetCategoryName;
  final double overBudgetAmount;
}
