import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:moniary/features/categories/domain/models/category.dart';
import 'package:moniary/features/transactions/application/composer/transaction_composer_controller.dart';
import 'package:moniary/features/transactions/data/repositories/transaction_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Mock SupabaseClient to satisfy transaction repository constructor requirements
class MockSupabaseClient extends Fake implements SupabaseClient {}

void main() {
  late TransactionRepository repository;
  late MockSupabaseClient mockSupabaseClient;

  setUp(() {
    mockSupabaseClient = MockSupabaseClient();
    repository = TransactionRepository(mockSupabaseClient);
    TransactionRepository.mockTransactions.clear();
  });

  group('TransactionRepository - Importance tests (Mock Mode)', () {
    test(
      'creates transaction with isImportant set to false by default',
      () async {
        final id = await repository.createTransaction(
          amount: 50000,
          type: TransactionType.expense,
          walletId: 'wallet-1',
          categoryId: 'category-1',
          transactionDate: DateTime(2026, 5, 29),
          note: 'Buying coffee',
        );

        expect(id, isNotEmpty);
        expect(TransactionRepository.mockTransactions.length, 1);
        final tx = TransactionRepository.mockTransactions.first;
        expect(tx.id, id);
        expect(tx.isImportant, isFalse);
      },
    );

    test(
      'creates transaction with isImportant set to true explicitly',
      () async {
        final id = await repository.createTransaction(
          amount: 1500000,
          type: TransactionType.expense,
          walletId: 'wallet-1',
          categoryId: 'category-1',
          transactionDate: DateTime(2026, 5, 29),
          note: 'Rent payment',
          isImportant: true,
        );

        expect(id, isNotEmpty);
        expect(TransactionRepository.mockTransactions.length, 1);
        final tx = TransactionRepository.mockTransactions.first;
        expect(tx.id, id);
        expect(tx.isImportant, isTrue);
      },
    );

    test('updates transaction details including isImportant', () async {
      final id = await repository.createTransaction(
        amount: 20000,
        type: TransactionType.expense,
        walletId: 'wallet-1',
        categoryId: 'category-1',
        transactionDate: DateTime(2026, 5, 29),
        note: 'Snack',
        isImportant: false,
      );

      await repository.updateTransaction(
        transactionId: id,
        amount: 25000,
        type: TransactionType.expense,
        walletId: 'wallet-1',
        categoryId: 'category-1',
        transactionDate: DateTime(2026, 5, 29),
        note: 'Snack updated',
        isImportant: true,
      );

      final tx = TransactionRepository.mockTransactions.first;
      expect(tx.amount, 25000);
      expect(tx.note, 'Snack updated');
      expect(tx.isImportant, isTrue);
    });

    test('toggles transaction importance independently', () async {
      final id = await repository.createTransaction(
        amount: 80000,
        type: TransactionType.income,
        walletId: 'wallet-1',
        categoryId: 'category-1',
        transactionDate: DateTime(2026, 5, 29),
        note: 'Freelance work',
        isImportant: false,
      );

      await repository.toggleTransactionImportance(id, true);

      var tx = TransactionRepository.mockTransactions.first;
      expect(tx.isImportant, isTrue);
      // Verify other fields did not change
      expect(tx.amount, 80000);
      expect(tx.note, 'Freelance work');

      await repository.toggleTransactionImportance(id, false);

      tx = TransactionRepository.mockTransactions.first;
      expect(tx.isImportant, isFalse);
    });
  });

  group(
    'TransactionComposerController - Importance integration tests (Mock Mode)',
    () {
      test(
        'creates transaction with isImportant via TransactionComposerController',
        () async {
          final container = ProviderContainer(
            overrides: [
              transactionRepositoryProvider.overrideWithValue(repository),
            ],
          );
          addTearDown(container.dispose);

          final controller = container.read(
            transactionComposerProvider.notifier,
          );

          await controller.createTransaction(
            amount: 99000,
            type: TransactionType.expense,
            walletId: 'wallet-1',
            categoryId: 'category-1',
            transactionDate: DateTime(2026, 5, 29),
            note: 'Composer test transaction',
            isImportant: true,
          );

          expect(TransactionRepository.mockTransactions.length, 1);
          final tx = TransactionRepository.mockTransactions.first;
          expect(tx.amount, 99000);
          expect(tx.isImportant, isTrue);
        },
      );

      test(
        'updates transaction with isImportant via TransactionComposerController',
        () async {
          final id = await repository.createTransaction(
            amount: 10000,
            type: TransactionType.expense,
            walletId: 'wallet-1',
            categoryId: 'category-1',
            transactionDate: DateTime(2026, 5, 29),
            note: 'Initial transaction',
            isImportant: false,
          );

          final container = ProviderContainer(
            overrides: [
              transactionRepositoryProvider.overrideWithValue(repository),
            ],
          );
          addTearDown(container.dispose);

          final controller = container.read(
            transactionComposerProvider.notifier,
          );

          await controller.updateTransaction(
            transactionId: id,
            amount: 12000,
            type: TransactionType.expense,
            walletId: 'wallet-1',
            categoryId: 'category-1',
            transactionDate: DateTime(2026, 5, 29),
            note: 'Updated transaction',
            isImportant: true,
          );

          final tx = TransactionRepository.mockTransactions.first;
          expect(tx.amount, 12000);
          expect(tx.note, 'Updated transaction');
          expect(tx.isImportant, isTrue);
        },
      );
    },
  );
}
