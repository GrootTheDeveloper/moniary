import 'package:flutter_test/flutter_test.dart';
import 'package:moniary/features/categories/domain/models/category.dart';
import 'package:moniary/features/journal/data/journal_collection_data_source.dart';
import 'package:moniary/features/journal/data/journal_repository_impl.dart';
import 'package:moniary/features/transactions/data/repositories/transaction_repository.dart';
import 'package:moniary/features/transactions/domain/models/transaction_entry.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class _FakeSupabaseClient extends Fake implements SupabaseClient {}

void main() {
  late TransactionRepository transactions;
  late MockJournalCollectionDataSource collections;
  late JournalRepositoryImpl repository;

  setUp(() {
    TransactionRepository.mockTransactions.clear();
    MockJournalCollectionDataSource.clear();
    transactions = TransactionRepository(_FakeSupabaseClient());
    collections = MockJournalCollectionDataSource();
    repository = JournalRepositoryImpl(
      collectionDataSource: collections,
      transactionRepository: transactions,
    );
  });

  tearDown(() {
    TransactionRepository.mockTransactions.clear();
    MockJournalCollectionDataSource.clear();
  });

  test('monthly recap calculates totals, highest day and categories', () async {
    TransactionRepository.mockTransactions.addAll([
      _expense('a', 200000, DateTime(2026, 7, 10), 'Food'),
      _expense('b', 500000, DateTime(2026, 7, 10), 'Travel'),
      _expense('c', 100000, DateTime(2026, 7, 11), 'Food'),
      _expense('d', 400000, DateTime(2026, 6, 4), 'Food'),
    ]);

    final recap = await repository.fetchMonthlyRecap(DateTime(2026, 7));

    expect(recap.totalExpense, 800000);
    expect(recap.previousMonthExpense, 400000);
    expect(recap.highestSpendDate, DateTime(2026, 7, 10));
    expect(recap.highestDayAmount, 700000);
    expect(recap.topCategories.first.name, 'Travel');
  });

  test('recording streak counts consecutive days and longest run', () async {
    TransactionRepository.mockTransactions.addAll([
      _expense('a', 10000, DateTime(2026, 7, 20), 'Food'),
      _expense('b', 10000, DateTime(2026, 7, 19), 'Food'),
      _expense('c', 10000, DateTime(2026, 7, 18), 'Food'),
      _expense('d', 10000, DateTime(2026, 7, 10), 'Food'),
    ]);

    final streak = await repository.fetchRecordingStreak(DateTime(2026, 7, 20));

    expect(streak.currentDays, 3);
    expect(streak.longestDays, 3);
  });

  test('mock collections persist transaction membership', () async {
    TransactionRepository.mockTransactions.add(
      _expense('a', 100000, DateTime(2026, 7, 20), 'Food'),
    );
    final id = await repository.createCollection(name: 'Trip');
    await repository.addTransaction(collectionId: id, transactionId: 'a');

    final collection = await repository.fetchCollection(id);

    expect(collection.name, 'Trip');
    expect(collection.transactionCount, 1);
    expect(collection.totalExpense, 100000);
  });
}

TransactionEntry _expense(
  String id,
  double amount,
  DateTime date,
  String category,
) {
  return TransactionEntry(
    id: id,
    amount: amount,
    type: TransactionType.expense,
    note: category,
    imagePath: null,
    transactionDate: date,
    walletId: 'wallet',
    walletName: 'Cash',
    walletColor: null,
    categoryId: category,
    categoryName: category,
    categoryColor: null,
  );
}
