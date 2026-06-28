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
    required this.categoryId,
    required this.categoryName,
    required this.categoryColor,
    this.isImportant = false,
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
  final String categoryId;
  final String categoryName;
  final String? categoryColor;
  final bool isImportant;

  bool get isExpense => type == TransactionType.expense;
  bool get isIncome => type == TransactionType.income;

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
      walletName: (wallet['name'] ?? 'Wallet') as String,
      walletColor: wallet['color'] as String?,
      categoryId: (category['id'] ?? '') as String,
      categoryName: (category['name'] ?? '') as String,
      categoryColor: category['color'] as String?,
      isImportant: map['is_important'] as bool? ?? false,
    );
  }
}
