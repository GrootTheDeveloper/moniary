import '../../../transactions/domain/models/transaction_entry.dart';

class CalendarDayData {
  CalendarDayData({
    required this.date,
    required this.isCurrentMonth,
    required this.transactions,
  });

  final DateTime date;
  final bool isCurrentMonth;
  final List<TransactionEntry> transactions;

  bool get isToday {
    final now = DateTime.now();
    return now.year == date.year &&
        now.month == date.month &&
        now.day == date.day;
  }

  late final double incomeTotal = transactions
      .where((transaction) => transaction.isIncome)
      .fold(0, (sum, transaction) => sum + transaction.amount);

  late final double expenseTotal = transactions
      .where((transaction) => transaction.isExpense)
      .fold(0, (sum, transaction) => sum + transaction.amount);
}

class CalendarMonthData {
  CalendarMonthData({
    required this.month,
    required this.weeks,
    required this.transactions,
  });

  final DateTime month;
  final List<List<CalendarDayData>> weeks;
  final List<TransactionEntry> transactions;

  double get totalIncome => transactions
      .where((transaction) => transaction.isIncome)
      .fold(0, (sum, transaction) => sum + transaction.amount);

  double get totalExpense => transactions
      .where((transaction) => transaction.isExpense)
      .fold(0, (sum, transaction) => sum + transaction.amount);

  int get transactionCount => transactions.length;

  late final int activeDays = weeks
      .expand((week) => week)
      .where((day) => day.transactions.isNotEmpty)
      .length;

  bool get isEmpty => transactions.isEmpty;
}
