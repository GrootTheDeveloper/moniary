import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:moniary/features/categories/domain/models/category.dart';
import 'package:moniary/features/recurring/application/recurring_materialization_service.dart';
import 'package:moniary/features/recurring/data/repositories/recurring_transaction_repository.dart';
import 'package:moniary/features/recurring/domain/models/recurring_transaction.dart';
import 'package:moniary/features/transactions/data/repositories/transaction_repository.dart';

class _FakeSupabaseClient extends Mock implements SupabaseClient {}

DateTime _dateOnly(DateTime date) => DateTime(date.year, date.month, date.day);

void main() {
  final client = _FakeSupabaseClient();
  late RecurringTransactionRepository recurringRepo;
  late TransactionRepository transactionRepo;
  late RecurringMaterializationService service;

  setUp(() {
    recurringRepo = RecurringTransactionRepository(client, useMockData: true);
    transactionRepo = TransactionRepository(client, useMockData: true);
    service = RecurringMaterializationService(recurringRepo, transactionRepo);
    TransactionRepository.mockTransactions.clear();
  });

  Future<String> seedDailyRule() async {
    final today = _dateOnly(DateTime.now());
    return recurringRepo.createRecurringTransaction(
      amount: 10000,
      type: TransactionType.expense,
      walletId: 'w1',
      categoryId: 'mock-cat-food',
      frequency: RecurringFrequency.daily,
      interval: 1,
      startDate: today.subtract(const Duration(days: 2)),
      nextRunDate: today.subtract(const Duration(days: 2)),
      note: 'gym',
      autoPost: true,
    );
  }

  test('materialized transactions are linked to their rule', () async {
    final id = await seedDailyRule();
    await service.run();

    expect(await transactionRepo.countGeneratedTransactions(id), 3);
    expect(
      TransactionRepository.mockTransactions.every(
        (t) => t.recurringTransactionId == id,
      ),
      isTrue,
    );
  });

  test(
    'updateGeneratedTransactions rewrites shared fields, keeps dates',
    () async {
      final id = await seedDailyRule();
      await service.run();
      final datesBefore = TransactionRepository.mockTransactions
          .map((t) => t.transactionDate)
          .toSet();

      await transactionRepo.updateGeneratedTransactions(
        recurringTransactionId: id,
        amount: 55000,
        type: TransactionType.income,
        walletId: 'w1',
        categoryId: 'mock-cat-salary',
        note: 'salary',
      );

      final generated = TransactionRepository.mockTransactions
          .where((t) => t.recurringTransactionId == id)
          .toList();
      expect(generated.every((t) => t.amount == 55000), isTrue);
      expect(generated.every((t) => t.type == TransactionType.income), isTrue);
      expect(generated.every((t) => t.note == 'salary'), isTrue);
      // Dates preserved.
      expect(generated.map((t) => t.transactionDate).toSet(), datesBefore);
    },
  );

  test(
    'deleteGeneratedTransactions removes only that rule\'s transactions',
    () async {
      final id = await seedDailyRule();
      await service.run();
      // An unrelated manual transaction must survive.
      await transactionRepo.createTransaction(
        amount: 1000,
        type: TransactionType.expense,
        walletId: 'w1',
        categoryId: 'mock-cat-food',
        transactionDate: DateTime.now(),
      );

      await transactionRepo.deleteGeneratedTransactions(id);

      expect(await transactionRepo.countGeneratedTransactions(id), 0);
      expect(TransactionRepository.mockTransactions, hasLength(1));
      expect(
        TransactionRepository.mockTransactions.single.recurringTransactionId,
        isNull,
      );
    },
  );
}
