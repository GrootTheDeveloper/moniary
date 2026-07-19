import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:moniary/features/budgets/data/budget_limit_data_source.dart';
import 'package:moniary/features/budgets/data/budget_repository_impl.dart';
import 'package:moniary/features/categories/data/repositories/category_repository.dart';
import 'package:moniary/features/categories/domain/models/category.dart';
import 'package:moniary/features/transactions/data/repositories/transaction_repository.dart';
import 'package:moniary/features/transactions/domain/models/transaction_entry.dart';
import 'package:moniary/shared/utils/exchange_rates.dart';

class _FakeSupabaseClient extends Fake implements SupabaseClient {}

class _FakeBudgetLimitDataSource implements BudgetLimitDataSource {
  _FakeBudgetLimitDataSource(this._limits);

  final Map<String, BudgetLimitRecord> _limits;

  @override
  Future<Map<String, BudgetLimitRecord>> fetchLimits(DateTime month) async {
    return _limits;
  }

  @override
  Future<void> setLimit({
    required DateTime month,
    required String categoryId,
    required double amount,
    required double warningRatio,
  }) async {}
}

class _FixedTransactionRepository extends TransactionRepository {
  _FixedTransactionRepository(this._transactions)
    : super(_FakeSupabaseClient());

  final List<TransactionEntry> _transactions;

  @override
  Future<List<TransactionEntry>> fetchTransactionsForMonth(
    DateTime month, {
    String? walletId,
    String? categoryId,
  }) async {
    return _transactions;
  }
}

TransactionEntry _foodExpense({
  required double amount,
  required String walletCurrency,
}) {
  return TransactionEntry(
    id: 'tx-$amount-$walletCurrency',
    amount: amount,
    type: TransactionType.expense,
    note: null,
    imagePath: null,
    transactionDate: DateTime(2026, 7, 19),
    walletId: 'wallet-1',
    walletName: 'Wallet',
    walletColor: null,
    walletCurrency: walletCurrency,
    categoryId: 'mock-category-food',
    categoryName: 'Ăn uống',
    categoryColor: null,
  );
}

void main() {
  // Budget limits are always entered by the user in their preferred currency
  // (see budget_limit_editor.dart), so spending in other wallet currencies
  // must be converted before it's comparable to the limit.
  final rates = ExchangeRates([
    ExchangeRateEntry(
      date: DateTime(2026, 7, 19),
      currencyCode: 'VND',
      rateToUsd: 1 / 25000,
    ),
    ExchangeRateEntry(
      date: DateTime(2026, 7, 19),
      currencyCode: 'USD',
      rateToUsd: 1,
    ),
  ]);

  test(
    'converts spending from a foreign-currency wallet into the preferred currency',
    () async {
      final repo = BudgetRepositoryImpl(
        dataSource: _FakeBudgetLimitDataSource({
          'mock-category-food': const BudgetLimitRecord(limitAmount: 10),
        }),
        categoryRepository: CategoryRepository.mock(),
        transactionRepository: _FixedTransactionRepository([
          // 25,000 VND == 1 USD.
          _foodExpense(amount: 25000, walletCurrency: 'VND'),
        ]),
        exchangeRates: rates,
        preferredCurrency: 'USD',
      );

      final budget = await repo.fetchMonthlyBudget(DateTime(2026, 7));
      final food = budget.categories.firstWhere(
        (category) => category.categoryId == 'mock-category-food',
      );

      expect(food.spentAmount, closeTo(1, 1e-9));
      expect(food.limitAmount, 10);
      expect(food.isOverLimit, isFalse);
    },
  );

  test(
    'falls back to the raw amount when rates are unavailable (null)',
    () async {
      final repo = BudgetRepositoryImpl(
        dataSource: _FakeBudgetLimitDataSource({
          'mock-category-food': const BudgetLimitRecord(limitAmount: 10),
        }),
        categoryRepository: CategoryRepository.mock(),
        transactionRepository: _FixedTransactionRepository([
          _foodExpense(amount: 25000, walletCurrency: 'VND'),
        ]),
        exchangeRates: null,
        preferredCurrency: 'USD',
      );

      final budget = await repo.fetchMonthlyBudget(DateTime(2026, 7));
      final food = budget.categories.firstWhere(
        (category) => category.categoryId == 'mock-category-food',
      );

      expect(food.spentAmount, 25000);
    },
  );
}
