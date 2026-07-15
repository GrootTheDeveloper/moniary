import 'package:flutter_test/flutter_test.dart';
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
}
