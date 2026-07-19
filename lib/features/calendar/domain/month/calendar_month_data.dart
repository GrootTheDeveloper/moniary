import '../../../../shared/utils/exchange_rates.dart';
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

  /// Sums income converted to [currency]. Pass null for [rates] (e.g. rates
  /// still loading) to get the raw, unconverted sum instead.
  double incomeTotal(String currency, ExchangeRates? rates) {
    return transactions
        .where((transaction) => transaction.isIncome)
        .fold(
          0,
          (sum, transaction) =>
              sum +
              (rates == null
                  ? transaction.amount
                  : transaction.amountIn(currency, rates)),
        );
  }

  double expenseTotal(String currency, ExchangeRates? rates) {
    return transactions
        .where((transaction) => transaction.isExpense)
        .fold(
          0,
          (sum, transaction) =>
              sum +
              (rates == null
                  ? transaction.amount
                  : transaction.amountIn(currency, rates)),
        );
  }

  bool get hasImportant => transactions.any((t) => t.isImportant);
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

  /// Sums income converted to [currency]. Pass null for [rates] (e.g. rates
  /// still loading) to get the raw, unconverted sum instead.
  double totalIncome(String currency, ExchangeRates? rates) {
    return transactions
        .where((transaction) => transaction.isIncome)
        .fold(
          0,
          (sum, transaction) =>
              sum +
              (rates == null
                  ? transaction.amount
                  : transaction.amountIn(currency, rates)),
        );
  }

  double totalExpense(String currency, ExchangeRates? rates) {
    return transactions
        .where((transaction) => transaction.isExpense)
        .fold(
          0,
          (sum, transaction) =>
              sum +
              (rates == null
                  ? transaction.amount
                  : transaction.amountIn(currency, rates)),
        );
  }

  int get transactionCount => transactions.length;

  late final int activeDays = weeks
      .expand((week) => week)
      .where((day) => day.transactions.isNotEmpty)
      .length;

  bool get isEmpty => transactions.isEmpty;
}
