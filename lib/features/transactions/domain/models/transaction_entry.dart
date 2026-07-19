import '../../../../shared/utils/exchange_rates.dart';
import '../../../categories/domain/models/category.dart';

class TransactionEntry {
  const TransactionEntry({
    required this.id,
    required this.amount,
    required this.type,
    required this.note,
    required this.imagePath,
    required this.transactionDate,
    required this.walletId,
    required this.walletName,
    required this.walletColor,
    required this.walletCurrency,
    required this.categoryId,
    required this.categoryName,
    required this.categoryColor,
    this.isImportant = false,
    this.recurringTransactionId,
  });

  final String id;
  final double amount;
  final TransactionType type;
  final String? note;
  final String? imagePath;
  final DateTime transactionDate;
  final String walletId;
  final String walletName;
  final String? walletColor;
  final String walletCurrency;
  final String categoryId;
  final String categoryName;
  final String? categoryColor;
  final bool isImportant;

  /// Set when this transaction was auto-posted from a recurring rule.
  final String? recurringTransactionId;

  bool get isExpense => type == TransactionType.expense;
  bool get isIncome => type == TransactionType.income;

  /// [amount] converted to [targetCurrency] using the rate for
  /// [transactionDate]. Falls back to the raw [amount] when a required rate
  /// isn't available yet, rather than dropping the transaction from a total.
  double amountIn(String targetCurrency, ExchangeRates rates) {
    return rates.convert(
          amount: amount,
          from: walletCurrency,
          to: targetCurrency,
          date: transactionDate,
        ) ??
        amount;
  }

  factory TransactionEntry.fromMap(Map<String, dynamic> map) {
    final wallet = map['wallet'] as Map<String, dynamic>? ?? const {};
    final category = map['category'] as Map<String, dynamic>? ?? const {};

    return TransactionEntry(
      id: map['id'] as String,
      amount: (map['amount'] as num).toDouble(),
      type: TransactionTypeX.fromValue(map['type'] as String),
      note: map['note'] as String?,
      imagePath: map['image_path'] as String?,
      transactionDate: DateTime.parse(
        map['transaction_date'] as String,
      ).toLocal(),
      walletId: (wallet['id'] ?? '') as String,
      walletName: (wallet['name'] ?? '') as String,
      walletColor: wallet['color'] as String?,
      walletCurrency: (wallet['currency'] ?? 'VND') as String,
      categoryId: (category['id'] ?? '') as String,
      categoryName: (category['name'] ?? '') as String,
      categoryColor: category['color'] as String?,
      isImportant: map['is_important'] as bool? ?? false,
      recurringTransactionId: map['recurring_transaction_id'] as String?,
    );
  }
}
