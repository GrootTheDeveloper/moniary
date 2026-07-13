import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/budget_repository_impl.dart';
import '../domain/monthly_budget.dart';

final monthlyBudgetProvider = FutureProvider.family<MonthlyBudget, DateTime>((
  ref,
  month,
) {
  return ref.watch(budgetRepositoryProvider).fetchMonthlyBudget(month);
});

final budgetActionControllerProvider =
    AsyncNotifierProvider<BudgetActionController, void>(
      BudgetActionController.new,
    );

class BudgetActionController extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<void> setLimit({
    required DateTime month,
    required String categoryId,
    required double amount,
    required double warningRatio,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref
          .read(budgetRepositoryProvider)
          .setCategoryLimit(
            month: month,
            categoryId: categoryId,
            amount: amount,
            warningRatio: warningRatio,
          );
      ref.invalidate(monthlyBudgetProvider(month));
    });
    if (state.hasError) {
      Error.throwWithStackTrace(state.error!, state.stackTrace!);
    }
  }
}
