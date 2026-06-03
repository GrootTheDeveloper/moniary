import 'package:flutter_test/flutter_test.dart';
import 'package:moniary/features/categories/domain/models/category.dart';
import 'package:moniary/features/transactions/data/repositories/transaction_repository.dart';
import 'package:moniary/features/transactions/domain/models/transaction_entry.dart';
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
    final noteResults = await repository.searchTransactions('coffee');
    final categoryResults = await repository.searchTransactions('SHOP');

    expect(noteResults.map((transaction) => transaction.id), ['tx-3', 'tx-1']);
    expect(categoryResults.map((transaction) => transaction.id), ['tx-2']);
  });

  test('searchTransactions returns empty list for blank queries', () async {
    final results = await repository.searchTransactions('   ');

    expect(results, isEmpty);
  });
}
