import 'package:flutter_test/flutter_test.dart';
import 'package:moniary/features/budgets/data/budget_limit_data_source.dart';
import 'package:moniary/features/budgets/domain/monthly_budget.dart';

void main() {
  group('MonthlyBudget', () {
    test('calculates totals and clamped progress', () {
      final budget = MonthlyBudget(
        month: DateTime(2026, 7),
        categories: const [
          CategoryBudget(
            categoryId: 'food',
            categoryName: 'Food',
            spentAmount: 900,
            limitAmount: 1000,
          ),
          CategoryBudget(
            categoryId: 'travel',
            categoryName: 'Travel',
            spentAmount: 1600,
            limitAmount: 1000,
          ),
        ],
        unbudgetedCategories: const [],
      );

      expect(budget.totalSpent, 2500);
      expect(budget.totalLimit, 2000);
      expect(budget.progress, 1);
      expect(budget.categories.first.isNearLimit, isTrue);
      expect(budget.categories.last.isOverLimit, isTrue);
    });
  });

  group('MockBudgetLimitDataSource', () {
    setUp(MockBudgetLimitDataSource.clear);

    test('stores limits per month and removes zero limits', () async {
      final source = MockBudgetLimitDataSource();
      final july = DateTime(2026, 7);
      final august = DateTime(2026, 8);

      await source.setLimit(
        month: july,
        categoryId: 'food',
        amount: 2000000,
        warningRatio: 0.8,
      );
      await source.setLimit(
        month: august,
        categoryId: 'food',
        amount: 3000000,
        warningRatio: 0.9,
      );

      expect((await source.fetchLimits(july))['food']?.limitAmount, 2000000);
      expect((await source.fetchLimits(july))['food']?.warningRatio, 0.8);
      expect((await source.fetchLimits(august))['food']?.limitAmount, 3000000);

      await source.setLimit(
        month: july,
        categoryId: 'food',
        amount: 0,
        warningRatio: 0.8,
      );
      expect(await source.fetchLimits(july), isEmpty);
    });
  });
}
