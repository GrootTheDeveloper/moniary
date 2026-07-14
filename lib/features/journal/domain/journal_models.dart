import '../../transactions/domain/models/transaction_entry.dart';

class JournalCategoryTotal {
  const JournalCategoryTotal({
    required this.name,
    required this.amount,
    required this.color,
  });

  final String name;
  final double amount;
  final String? color;
}

class MonthlyRecap {
  const MonthlyRecap({
    required this.month,
    required this.transactions,
    required this.totalExpense,
    required this.totalIncome,
    required this.previousMonthExpense,
    required this.previousMonthIncome,
    required this.highestSpendDate,
    required this.highestDayAmount,
    required this.activeRecordingDays,
    required this.topCategories,
    required this.insights,
  });

  final DateTime month;
  final List<TransactionEntry> transactions;
  final double totalExpense;
  final double totalIncome;
  final double previousMonthExpense;
  final double previousMonthIncome;
  final DateTime? highestSpendDate;
  final double highestDayAmount;
  final int activeRecordingDays;
  final List<JournalCategoryTotal> topCategories;
  final List<MonthlyRecapInsight> insights;

  int get expenseCount =>
      transactions.where((transaction) => transaction.isExpense).length;

  double get netAmount => totalIncome - totalExpense;

  double get previousNetAmount => previousMonthIncome - previousMonthExpense;

  double get averageDailyExpense {
    if (activeRecordingDays == 0) return 0;
    return totalExpense / activeRecordingDays;
  }

  double get topCategoryShare {
    if (totalExpense <= 0 || topCategories.isEmpty) return 0;
    return topCategories.first.amount / totalExpense;
  }

  double get monthChange {
    if (previousMonthExpense <= 0) return 0;
    return (totalExpense - previousMonthExpense) / previousMonthExpense;
  }
}

enum MonthlyRecapInsightType {
  spendingDown,
  spendingUp,
  topCategoryShare,
  weekendHeavy,
  recordingRhythm,
  quietMonth,
}

class MonthlyRecapInsight {
  const MonthlyRecapInsight({
    required this.type,
    required this.value,
    this.categoryName,
  });

  final MonthlyRecapInsightType type;
  final double value;
  final String? categoryName;
}

class RecordingStreak {
  const RecordingStreak({
    required this.currentDays,
    required this.longestDays,
    required this.recordedDays,
  });

  final int currentDays;
  final int longestDays;
  final Set<DateTime> recordedDays;
}

class JournalCollectionSummary {
  const JournalCollectionSummary({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.transactions,
    this.startDate,
    this.endDate,
  });

  final String id;
  final String name;
  final DateTime createdAt;
  final DateTime? startDate;
  final DateTime? endDate;
  final List<TransactionEntry> transactions;

  int get transactionCount => transactions.length;

  double get totalExpense => transactions
      .where((transaction) => transaction.isExpense)
      .fold(0, (sum, transaction) => sum + transaction.amount);

  String? get coverImagePath {
    for (final transaction in transactions) {
      final path = transaction.imagePath;
      if (path != null && path.isNotEmpty) return path;
    }
    return null;
  }
}
