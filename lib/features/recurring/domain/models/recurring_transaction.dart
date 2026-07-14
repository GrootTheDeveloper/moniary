import '../../../categories/domain/models/category.dart';

enum RecurringFrequency { daily, weekly, monthly, yearly }

extension RecurringFrequencyX on RecurringFrequency {
  String get value => switch (this) {
    RecurringFrequency.daily => 'daily',
    RecurringFrequency.weekly => 'weekly',
    RecurringFrequency.monthly => 'monthly',
    RecurringFrequency.yearly => 'yearly',
  };

  static RecurringFrequency fromValue(String value) {
    return RecurringFrequency.values.firstWhere(
      (frequency) => frequency.value == value,
      orElse: () => RecurringFrequency.monthly,
    );
  }
}

/// A rule that repeatedly produces income/expense transactions —
/// subscriptions, salary, rent, loan payments. Drives reminders and
/// cash-flow projection; may auto-post into `transactions` when [autoPost].
class RecurringTransaction {
  const RecurringTransaction({
    required this.id,
    required this.amount,
    required this.type,
    required this.note,
    required this.walletId,
    required this.walletName,
    required this.walletColor,
    required this.categoryId,
    required this.categoryName,
    required this.categoryColor,
    required this.frequency,
    required this.interval,
    required this.startDate,
    required this.nextRunDate,
    required this.endDate,
    required this.autoPost,
    required this.isActive,
    required this.lastRunDate,
  });

  final String id;
  final double amount;
  final TransactionType type;
  final String? note;
  final String walletId;
  final String walletName;
  final String? walletColor;
  final String categoryId;
  final String categoryName;
  final String? categoryColor;
  final RecurringFrequency frequency;
  final int interval;
  final DateTime startDate;
  final DateTime nextRunDate;
  final DateTime? endDate;
  final bool autoPost;
  final bool isActive;
  final DateTime? lastRunDate;

  bool get isExpense => type == TransactionType.expense;
  bool get isIncome => type == TransactionType.income;

  static DateTime _parseDate(String value) =>
      DateTime.parse(value).toLocal();

  factory RecurringTransaction.fromMap(Map<String, dynamic> map) {
    final wallet = map['wallet'] as Map<String, dynamic>? ?? const {};
    final category = map['category'] as Map<String, dynamic>? ?? const {};

    return RecurringTransaction(
      id: map['id'] as String,
      amount: (map['amount'] as num).toDouble(),
      type: TransactionTypeX.fromValue(map['type'] as String),
      note: map['note'] as String?,
      walletId: (wallet['id'] ?? map['wallet_id'] ?? '') as String,
      walletName: (wallet['name'] ?? '') as String,
      walletColor: wallet['color'] as String?,
      categoryId: (category['id'] ?? map['category_id'] ?? '') as String,
      categoryName: (category['name'] ?? '') as String,
      categoryColor: category['color'] as String?,
      frequency: RecurringFrequencyX.fromValue(map['frequency'] as String),
      interval: (map['interval'] as num?)?.toInt() ?? 1,
      startDate: _parseDate(map['start_date'] as String),
      nextRunDate: _parseDate(map['next_run_date'] as String),
      endDate: map['end_date'] == null
          ? null
          : _parseDate(map['end_date'] as String),
      autoPost: map['auto_post'] as bool? ?? false,
      isActive: map['is_active'] as bool? ?? true,
      lastRunDate: map['last_run_date'] == null
          ? null
          : _parseDate(map['last_run_date'] as String),
    );
  }
}
