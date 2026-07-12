import '../../transactions/domain/models/transaction_entry.dart';

class CategoryBudget {
  const CategoryBudget({
    required this.categoryId,
    required this.categoryName,
    required this.spentAmount,
    required this.limitAmount,
    this.categoryColor,
    this.warningRatio = 0.9,
    this.transactions = const [],
  });

  final String categoryId;
  final String categoryName;
  final String? categoryColor;
  final double spentAmount;
  final double limitAmount;
  final double warningRatio;
  final List<TransactionEntry> transactions;

  double get progress =>
      limitAmount <= 0 ? 0 : (spentAmount / limitAmount).clamp(0, 1);

  bool get isNearLimit =>
      limitAmount > 0 &&
      spentAmount < limitAmount &&
      spentAmount / limitAmount >= warningRatio;

  bool get isOverLimit => limitAmount > 0 && spentAmount > limitAmount;
}

class MonthlyBudget {
  const MonthlyBudget({
    required this.month,
    required this.categories,
    required this.unbudgetedCategories,
  });

  final DateTime month;
  final List<CategoryBudget> categories;
  final List<CategoryBudget> unbudgetedCategories;

  double get totalLimit =>
      categories.fold(0, (sum, category) => sum + category.limitAmount);

  double get totalSpent =>
      categories.fold(0, (sum, category) => sum + category.spentAmount);

  double get progress =>
      totalLimit <= 0 ? 0 : (totalSpent / totalLimit).clamp(0, 1);
}
