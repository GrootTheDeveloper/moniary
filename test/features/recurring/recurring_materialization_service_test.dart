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
  late RecurringTransactionRepository recurringRepo;
  late TransactionRepository transactionRepo;
  late RecurringMaterializationService service;
  final client = _FakeSupabaseClient();

  setUp(() {
    // AppConstants.hasSupabaseConfig is false under test → mock mode.
    recurringRepo = RecurringTransactionRepository(client, useMockData: true);
    transactionRepo = TransactionRepository(client, useMockData: true);
    service = RecurringMaterializationService(recurringRepo, transactionRepo);
  });

  Future<RecurringTransaction> ruleByNote(String note) async {
    final rules = await recurringRepo.fetchRecurringTransactions();
    return rules.firstWhere((r) => r.note == note);
  }

  test(
    'daily auto-post catches up every missed occurrence through today',
    () async {
      final today = _dateOnly(DateTime.now());
      final before = TransactionRepository.mockTransactions.length;

      await recurringRepo.createRecurringTransaction(
        amount: 10000,
        type: TransactionType.expense,
        walletId: 'w1',
        categoryId: 'mock-cat-food',
        frequency: RecurringFrequency.daily,
        interval: 1,
        startDate: today.subtract(const Duration(days: 3)),
        nextRunDate: today.subtract(const Duration(days: 3)),
        note: 'daily-catchup',
        autoPost: true,
      );

      final posted = await service.run();

      // Occurrences due: today-3, -2, -1, 0 => 4 posts.
      expect(posted, 4);
      expect(TransactionRepository.mockTransactions.length, before + 4);

      final rule = await ruleByNote('daily-catchup');
      expect(rule.nextRunDate, today.add(const Duration(days: 1)));
      expect(rule.lastRunDate, today);
      expect(rule.isActive, isTrue);
    },
  );

  test('future-dated rule posts nothing and is unchanged', () async {
    final today = _dateOnly(DateTime.now());
    final future = today.add(const Duration(days: 5));
    final before = TransactionRepository.mockTransactions.length;

    await recurringRepo.createRecurringTransaction(
      amount: 5000,
      type: TransactionType.expense,
      walletId: 'w1',
      categoryId: 'mock-cat-food',
      frequency: RecurringFrequency.monthly,
      interval: 1,
      startDate: future,
      nextRunDate: future,
      note: 'future-rule',
      autoPost: true,
    );

    final posted = await service.run();

    expect(posted, 0);
    expect(TransactionRepository.mockTransactions.length, before);
    final rule = await ruleByNote('future-rule');
    expect(rule.nextRunDate, future);
  });

  test('non-auto-post rule is never materialized', () async {
    final today = _dateOnly(DateTime.now());
    final before = TransactionRepository.mockTransactions.length;

    await recurringRepo.createRecurringTransaction(
      amount: 7000,
      type: TransactionType.expense,
      walletId: 'w1',
      categoryId: 'mock-cat-food',
      frequency: RecurringFrequency.daily,
      interval: 1,
      startDate: today.subtract(const Duration(days: 10)),
      nextRunDate: today.subtract(const Duration(days: 10)),
      note: 'manual-reminder',
      autoPost: false,
    );

    final posted = await service.run();

    expect(posted, 0);
    expect(TransactionRepository.mockTransactions.length, before);
  });

  test('rule is deactivated once it steps past its end date', () async {
    final today = _dateOnly(DateTime.now());
    final before = TransactionRepository.mockTransactions.length;

    await recurringRepo.createRecurringTransaction(
      amount: 3000,
      type: TransactionType.expense,
      walletId: 'w1',
      categoryId: 'mock-cat-food',
      frequency: RecurringFrequency.daily,
      interval: 1,
      startDate: today.subtract(const Duration(days: 2)),
      nextRunDate: today.subtract(const Duration(days: 2)),
      endDate: today.subtract(const Duration(days: 1)),
      note: 'ends-yesterday',
      autoPost: true,
    );

    final posted = await service.run();

    // Only today-2 and today-1 are on/before the end date => 2 posts.
    expect(posted, 2);
    expect(TransactionRepository.mockTransactions.length, before + 2);
    final rule = await ruleByNote('ends-yesterday');
    expect(rule.isActive, isFalse);
  });
}
