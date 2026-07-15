import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/supabase/supabase_providers.dart';
import '../../categories/data/repositories/category_repository.dart';
import '../../categories/domain/models/category.dart';
import '../../transactions/data/repositories/transaction_repository.dart';
import '../../transactions/domain/models/transaction_entry.dart';
import '../domain/budget_repository.dart';
import '../domain/monthly_budget.dart';
import 'budget_limit_data_source.dart';

final budgetRepositoryProvider = Provider<BudgetRepository>((ref) {
  return BudgetRepositoryImpl(
    dataSource: SupabaseBudgetLimitDataSource(
      ref.watch(supabaseClientProvider),
    ),
    categoryRepository: ref.watch(categoryRepositoryProvider),
    transactionRepository: ref.watch(transactionRepositoryProvider),
  );
});

class BudgetRepositoryImpl implements BudgetRepository {
  BudgetRepositoryImpl({
    required BudgetLimitDataSource dataSource,
    required CategoryRepository categoryRepository,
    required TransactionRepository transactionRepository,
  }) : _dataSource = dataSource,
       _categoryRepository = categoryRepository,
       _transactionRepository = transactionRepository;

  final BudgetLimitDataSource _dataSource;
  final CategoryRepository _categoryRepository;
  final TransactionRepository _transactionRepository;

  @override
  Future<MonthlyBudget> fetchMonthlyBudget(DateTime month) async {
    final normalizedMonth = DateTime(month.year, month.month);
    final results = await Future.wait([
      _dataSource.fetchLimits(normalizedMonth),
      _categoryRepository.fetchCategories(),
      _transactionRepository.fetchTransactionsForMonth(normalizedMonth),
    ]);
    final limits = results[0] as Map<String, BudgetLimitRecord>;
    final categories = (results[1] as List<Category>)
        .where((category) => category.type == TransactionType.expense)
        .toList();
    final transactions = results[2] as List<TransactionEntry>;
    final spentByCategory = <String, double>{};
    final transactionsByCategory = <String, List<TransactionEntry>>{};
    for (final transaction in transactions) {
      if (transaction.isExpense) {
        final categoryId = transaction.categoryId;
        spentByCategory[categoryId] =
            (spentByCategory[categoryId] ?? 0) + transaction.amount;
        transactionsByCategory
            .putIfAbsent(categoryId, () => <TransactionEntry>[])
            .add(transaction);
      }
    }

    final budgeted = <CategoryBudget>[];
    final unbudgeted = <CategoryBudget>[];
    for (final category in categories) {
      final limit = limits[category.id];
      final item = CategoryBudget(
        categoryId: category.id,
        categoryName: category.name,
        categoryColor: category.color,
        spentAmount: spentByCategory[category.id] ?? 0,
        limitAmount: limit?.limitAmount ?? 0,
        warningRatio: limit?.warningRatio ?? 0.9,
        transactions: transactionsByCategory[category.id] ?? const [],
      );
      if (item.limitAmount > 0) {
        budgeted.add(item);
      } else {
        unbudgeted.add(item);
      }
    }
    budgeted.sort((a, b) => b.progress.compareTo(a.progress));
    unbudgeted.sort((a, b) => a.categoryName.compareTo(b.categoryName));

    return MonthlyBudget(
      month: normalizedMonth,
      categories: budgeted,
      unbudgetedCategories: unbudgeted,
    );
  }

  @override
  Future<void> setCategoryLimit({
    required DateTime month,
    required String categoryId,
    required double amount,
    required double warningRatio,
  }) {
    return _dataSource.setLimit(
      month: DateTime(month.year, month.month),
      categoryId: categoryId,
      amount: amount,
      warningRatio: warningRatio,
    );
  }
}
