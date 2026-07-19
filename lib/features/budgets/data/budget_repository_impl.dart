import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/currency/exchange_rate_repository.dart';
import '../../../core/preferences/preferences_providers.dart';
import '../../../core/supabase/supabase_providers.dart';
import '../../../shared/utils/exchange_rates.dart';
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
    exchangeRates: ref.watch(exchangeRatesProvider).value,
    preferredCurrency: ref.watch(preferredCurrencyProvider),
  );
});

class BudgetRepositoryImpl implements BudgetRepository {
  BudgetRepositoryImpl({
    required BudgetLimitDataSource dataSource,
    required CategoryRepository categoryRepository,
    required TransactionRepository transactionRepository,
    ExchangeRates? exchangeRates,
    required String preferredCurrency,
  }) : _dataSource = dataSource,
       _categoryRepository = categoryRepository,
       _transactionRepository = transactionRepository,
       _exchangeRates = exchangeRates,
       _preferredCurrency = preferredCurrency;

  final BudgetLimitDataSource _dataSource;
  final CategoryRepository _categoryRepository;
  final TransactionRepository _transactionRepository;
  // Budget limits are always entered by the user in their preferred currency
  // (see budget_limit_editor.dart), so spending must be converted to the same
  // currency to stay comparable — same amountIn() pattern as phase 1.
  final ExchangeRates? _exchangeRates;
  final String _preferredCurrency;

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
            (spentByCategory[categoryId] ?? 0) + _amountOf(transaction);
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

  /// [transaction.amount] converted to the preferred currency, falling back
  /// to the raw amount when a required rate isn't available yet.
  double _amountOf(TransactionEntry transaction) {
    return _exchangeRates == null
        ? transaction.amount
        : transaction.amountIn(_preferredCurrency, _exchangeRates);
  }
}
