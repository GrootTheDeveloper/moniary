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
    required this.previousMonthExpense,
    required this.highestSpendDate,
    required this.highestDayAmount,
    required this.topCategories,
  });

  final DateTime month;
  final List<TransactionEntry> transactions;
  final double totalExpense;
  final double previousMonthExpense;
  final DateTime? highestSpendDate;
  final double highestDayAmount;
  final List<JournalCategoryTotal> topCategories;

  int get expenseCount =>
      transactions.where((transaction) => transaction.isExpense).length;

  double get monthChange {
    if (previousMonthExpense <= 0) return 0;
    return (totalExpense - previousMonthExpense) / previousMonthExpense;
  }
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
