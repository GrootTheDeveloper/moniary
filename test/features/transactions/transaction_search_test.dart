import 'package:flutter_test/flutter_test.dart';
import 'package:moniary/features/categories/domain/models/category.dart';
import 'package:moniary/features/transactions/data/repositories/transaction_repository.dart';
import 'package:moniary/features/transactions/domain/models/transaction_entry.dart';
import 'package:moniary/features/transactions/domain/models/transaction_search_filter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MockSupabaseClient extends Fake implements SupabaseClient {}

void main() {
  late TransactionRepository repository;
  late MockSupabaseClient mockSupabaseClient;

  setUp(() {
    mockSupabaseClient = MockSupabaseClient();
    repository = TransactionRepository(mockSupabaseClient);
    TransactionRepository.mockTransactions
      ..clear()
      ..addAll([
        TransactionEntry(
          id: 'tx-1',
          amount: 45000,
          type: TransactionType.expense,
          note: 'Morning coffee',
          imagePath: null,
          transactionDate: DateTime(2026, 5, 1, 8),
          walletId: 'w1',
          walletName: 'Cash',
          walletColor: null,
          categoryId: 'c1',
          categoryName: 'Food',
          categoryColor: null,
        ),
        TransactionEntry(
          id: 'tx-2',
          amount: 120000,
          type: TransactionType.expense,
          note: 'New shirt',
          imagePath: null,
          transactionDate: DateTime(2026, 5, 2, 9),
          walletId: 'w1',
          walletName: 'Cash',
          walletColor: null,
          categoryId: 'c2',
          categoryName: 'Shopping',
          categoryColor: null,
        ),
        TransactionEntry(
          id: 'tx-3',
          amount: 60000,
          type: TransactionType.expense,
          note: 'Coffee beans',
          imagePath: null,
          transactionDate: DateTime(2026, 5, 3, 10),
          walletId: 'w1',
          walletName: 'Cash',
          walletColor: null,
          categoryId: 'c1',
          categoryName: 'Food',
          categoryColor: null,
        ),
      ]);
  });

  test('searchTransactions matches note and category in mock mode', () async {
    final noteResults = await repository.searchTransactions(
      const TransactionSearchFilter(query: 'coffee'),
    );
    final categoryResults = await repository.searchTransactions(
      const TransactionSearchFilter(query: 'SHOP'),
    );

    expect(noteResults.map((transaction) => transaction.id), ['tx-3', 'tx-1']);
    expect(categoryResults.map((transaction) => transaction.id), ['tx-2']);
  });

  test('searchTransactions matches wallet name and amount', () async {
    final walletResults = await repository.searchTransactions(
      const TransactionSearchFilter(query: 'cash'),
    );
    final amountResults = await repository.searchTransactions(
      const TransactionSearchFilter(query: '120000'),
    );

    expect(walletResults, hasLength(3));
    expect(amountResults.map((transaction) => transaction.id), ['tx-2']);
  });

  test('searchTransactions returns all transactions for a blank filter',
      () async {
    final results = await repository.searchTransactions(
      const TransactionSearchFilter(query: '   '),
    );

    expect(results, hasLength(3));
  });

  test('searchTransactions filters not-important only', () async {
    TransactionRepository.mockTransactions[0] = TransactionEntry(
      id: 'tx-1',
      amount: 45000,
      type: TransactionType.expense,
      note: 'Morning coffee',
      imagePath: null,
      transactionDate: DateTime(2026, 5, 1, 8),
      walletId: 'w1',
      walletName: 'Cash',
      walletColor: null,
      categoryId: 'c1',
      categoryName: 'Food',
      categoryColor: null,
      isImportant: true,
    );

    final important = await repository.searchTransactions(
      const TransactionSearchFilter(
        importance: TransactionImportanceFilter.important,
      ),
    );
    final notImportant = await repository.searchTransactions(
      const TransactionSearchFilter(
        importance: TransactionImportanceFilter.notImportant,
      ),
    );

    expect(important.map((t) => t.id), ['tx-1']);
    expect(notImportant.map((t) => t.id).toSet(), {'tx-2', 'tx-3'});
  });

  test('searchTransactions filters by category without text', () async {
    final results = await repository.searchTransactions(
      const TransactionSearchFilter(categoryId: 'c1'),
    );

    expect(results.map((transaction) => transaction.id), ['tx-3', 'tx-1']);
  });

  test('searchTransactions filters by amount range', () async {
    final results = await repository.searchTransactions(
      const TransactionSearchFilter(minAmount: 50000, maxAmount: 130000),
    );

    expect(
      results.map((transaction) => transaction.id).toSet(),
      {'tx-2', 'tx-3'},
    );
  });

  test('searchTransactions filters by subscription facet', () async {
    // Seeded transactions have no recurring link.
    final subs = await repository.searchTransactions(
      const TransactionSearchFilter(
        subscription: TransactionSubscriptionFilter.subscription,
      ),
    );
    final nonSubs = await repository.searchTransactions(
      const TransactionSearchFilter(
        subscription: TransactionSubscriptionFilter.nonSubscription,
      ),
    );

    expect(subs, isEmpty);
    expect(nonSubs, hasLength(3));
  });

  test('searchTransactions filters by date range', () async {
    final results = await repository.searchTransactions(
      TransactionSearchFilter(
        dateFrom: DateTime(2026, 5, 2),
        dateTo: DateTime(2026, 5, 2),
      ),
    );

    expect(results.map((transaction) => transaction.id), ['tx-2']);
  });
}
