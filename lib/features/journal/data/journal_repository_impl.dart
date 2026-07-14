import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/supabase/supabase_providers.dart';
import '../../transactions/data/repositories/transaction_repository.dart';
import '../../transactions/domain/models/transaction_entry.dart';
import '../domain/journal_models.dart';
import '../domain/journal_repository.dart';
import 'journal_collection_data_source.dart';

final journalRepositoryProvider = Provider<JournalRepository>((ref) {
  return JournalRepositoryImpl.forEnvironment(
    client: ref.watch(supabaseClientProvider),
    useMockData: ref.watch(useMockDataModeProvider),
    transactionRepository: ref.watch(transactionRepositoryProvider),
  );
});

class JournalRepositoryImpl implements JournalRepository {
  factory JournalRepositoryImpl.forEnvironment({
    required SupabaseClient client,
    required bool useMockData,
    required TransactionRepository transactionRepository,
  }) {
    final shouldUseMockData = useMockData || !AppConstants.hasSupabaseConfig;
    return JournalRepositoryImpl(
      collectionDataSource: shouldUseMockData
          ? MockJournalCollectionDataSource()
          : SupabaseJournalCollectionDataSource(client),
      transactionRepository: transactionRepository,
    );
  }

  JournalRepositoryImpl({
    required JournalCollectionDataSource collectionDataSource,
    required TransactionRepository transactionRepository,
  }) : _collections = collectionDataSource,
       _transactions = transactionRepository;

  final JournalCollectionDataSource _collections;
  final TransactionRepository _transactions;

  @override
  Future<MonthlyRecap> fetchMonthlyRecap(DateTime month) async {
    final normalizedMonth = DateTime(month.year, month.month);
    final previousMonth = DateTime(month.year, month.month - 1);
    final results = await Future.wait([
      _transactions.fetchTransactionsForMonth(normalizedMonth),
      _transactions.fetchTransactionsForMonth(previousMonth),
    ]);
    final transactions = results[0];
    final previousTransactions = results[1];
    final expenses = transactions
        .where((transaction) => transaction.isExpense)
        .toList();
    final previousExpense = previousTransactions
        .where((transaction) => transaction.isExpense)
        .fold<double>(0, (sum, transaction) => sum + transaction.amount);
    final totalIncome = transactions
        .where((transaction) => transaction.isIncome)
        .fold<double>(0, (sum, transaction) => sum + transaction.amount);
    final previousIncome = previousTransactions
        .where((transaction) => transaction.isIncome)
        .fold<double>(0, (sum, transaction) => sum + transaction.amount);
    final totalExpense = expenses.fold<double>(
      0,
      (sum, transaction) => sum + transaction.amount,
    );

    final perDay = <DateTime, double>{};
    final recordedDays = <DateTime>{
      for (final transaction in transactions)
        DateTime(
          transaction.transactionDate.year,
          transaction.transactionDate.month,
          transaction.transactionDate.day,
        ),
    };
    final perCategory = <String, JournalCategoryTotal>{};
    var weekendExpense = 0.0;
    for (final transaction in expenses) {
      final day = DateTime(
        transaction.transactionDate.year,
        transaction.transactionDate.month,
        transaction.transactionDate.day,
      );
      perDay[day] = (perDay[day] ?? 0) + transaction.amount;
      if (transaction.transactionDate.weekday == DateTime.saturday ||
          transaction.transactionDate.weekday == DateTime.sunday) {
        weekendExpense += transaction.amount;
      }
      final current = perCategory[transaction.categoryName];
      perCategory[transaction.categoryName] = JournalCategoryTotal(
        name: transaction.categoryName,
        amount: (current?.amount ?? 0) + transaction.amount,
        color: transaction.categoryColor ?? current?.color,
      );
    }
    final highestDay = perDay.entries.isEmpty
        ? null
        : perDay.entries.reduce((a, b) => a.value >= b.value ? a : b);
    final topCategories = perCategory.values.toList()
      ..sort((a, b) => b.amount.compareTo(a.amount));
    final insights = _buildInsights(
      totalExpense: totalExpense,
      previousExpense: previousExpense,
      topCategories: topCategories,
      weekendExpense: weekendExpense,
      activeRecordingDays: recordedDays.length,
    );

    return MonthlyRecap(
      month: normalizedMonth,
      transactions: transactions,
      totalExpense: totalExpense,
      totalIncome: totalIncome,
      previousMonthExpense: previousExpense,
      previousMonthIncome: previousIncome,
      highestSpendDate: highestDay?.key,
      highestDayAmount: highestDay?.value ?? 0,
      activeRecordingDays: recordedDays.length,
      topCategories: topCategories.take(3).toList(),
      insights: insights,
    );
  }

  List<MonthlyRecapInsight> _buildInsights({
    required double totalExpense,
    required double previousExpense,
    required List<JournalCategoryTotal> topCategories,
    required double weekendExpense,
    required int activeRecordingDays,
  }) {
    final insights = <MonthlyRecapInsight>[];

    if (previousExpense > 0 && totalExpense > 0) {
      final change = (totalExpense - previousExpense) / previousExpense;
      if (change <= -0.05) {
        insights.add(
          MonthlyRecapInsight(
            type: MonthlyRecapInsightType.spendingDown,
            value: change.abs(),
          ),
        );
      } else if (change >= 0.05) {
        insights.add(
          MonthlyRecapInsight(
            type: MonthlyRecapInsightType.spendingUp,
            value: change,
          ),
        );
      }
    }

    if (totalExpense > 0 && topCategories.isNotEmpty) {
      final topCategory = topCategories.first;
      final share = topCategory.amount / totalExpense;
      if (share >= 0.25) {
        insights.add(
          MonthlyRecapInsight(
            type: MonthlyRecapInsightType.topCategoryShare,
            value: share,
            categoryName: topCategory.name,
          ),
        );
      }
    }

    if (totalExpense > 0) {
      final weekendShare = weekendExpense / totalExpense;
      if (weekendShare >= 0.35) {
        insights.add(
          MonthlyRecapInsight(
            type: MonthlyRecapInsightType.weekendHeavy,
            value: weekendShare,
          ),
        );
      }
    }

    if (activeRecordingDays >= 12) {
      insights.add(
        MonthlyRecapInsight(
          type: MonthlyRecapInsightType.recordingRhythm,
          value: activeRecordingDays.toDouble(),
        ),
      );
    }

    if (insights.isEmpty) {
      insights.add(
        MonthlyRecapInsight(
          type: MonthlyRecapInsightType.quietMonth,
          value: totalExpense,
        ),
      );
    }

    return insights.take(4).toList();
  }

  @override
  Future<RecordingStreak> fetchRecordingStreak(DateTime today) async {
    final normalizedToday = DateTime(today.year, today.month, today.day);
    final months = List.generate(
      12,
      (index) => DateTime(today.year, today.month - index),
    );
    final monthlyTransactions = await Future.wait(
      months.map(_transactions.fetchTransactionsForMonth),
    );
    final days = <DateTime>{
      for (final transaction in monthlyTransactions.expand((items) => items))
        DateTime(
          transaction.transactionDate.year,
          transaction.transactionDate.month,
          transaction.transactionDate.day,
        ),
    };

    var currentDays = 0;
    var cursor = normalizedToday;
    if (!days.contains(cursor)) {
      cursor = cursor.subtract(const Duration(days: 1));
    }
    while (days.contains(cursor)) {
      currentDays++;
      cursor = cursor.subtract(const Duration(days: 1));
    }

    var longest = 0;
    var running = 0;
    final sorted = days.toList()..sort();
    DateTime? previous;
    for (final day in sorted) {
      if (previous != null && day.difference(previous).inDays == 1) {
        running++;
      } else {
        running = 1;
      }
      if (running > longest) longest = running;
      previous = day;
    }
    return RecordingStreak(
      currentDays: currentDays,
      longestDays: longest,
      recordedDays: days,
    );
  }

  @override
  Future<List<JournalCollectionSummary>> fetchCollections() async {
    final records = await _collections.fetchCollections();
    return Future.wait(records.map(_hydrateCollection));
  }

  @override
  Future<JournalCollectionSummary> fetchCollection(String collectionId) async {
    return _hydrateCollection(await _collections.fetchCollection(collectionId));
  }

  @override
  Future<String> createCollection({
    required String name,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    return _collections.createCollection(
      name: name,
      startDate: startDate,
      endDate: endDate,
    );
  }

  @override
  Future<void> addTransaction({
    required String collectionId,
    required String transactionId,
  }) {
    return _collections.addTransaction(
      collectionId: collectionId,
      transactionId: transactionId,
    );
  }

  Future<JournalCollectionSummary> _hydrateCollection(
    JournalCollectionRecord record,
  ) async {
    final transactions = <TransactionEntry>[];
    for (final id in record.transactionIds) {
      transactions.add(await _transactions.fetchTransactionById(id));
    }
    transactions.sort((a, b) => b.transactionDate.compareTo(a.transactionDate));
    return JournalCollectionSummary(
      id: record.id,
      name: record.name,
      createdAt: record.createdAt,
      startDate: record.startDate,
      endDate: record.endDate,
      transactions: transactions,
    );
  }
}
