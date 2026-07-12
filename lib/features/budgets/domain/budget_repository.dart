import 'monthly_budget.dart';

abstract interface class BudgetRepository {
  Future<MonthlyBudget> fetchMonthlyBudget(DateTime month);

  Future<void> setCategoryLimit({
    required DateTime month,
    required String categoryId,
    required double amount,
    required double warningRatio,
  });
}
