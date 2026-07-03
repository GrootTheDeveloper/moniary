import 'package:flutter_test/flutter_test.dart';
import 'package:moniary/features/assistant/application/assistant_controller.dart';
import 'package:moniary/features/assistant/data/assistant_repository_impl.dart';
import 'package:moniary/features/assistant/domain/assistant_models.dart';
import 'package:moniary/features/categories/domain/models/category.dart';
import 'package:moniary/features/transactions/data/repositories/transaction_repository.dart';
import 'package:moniary/features/transactions/domain/models/transaction_entry.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class _FakeSupabaseClient extends Fake implements SupabaseClient {}

void main() {
  group('assistant question classification', () {
    test('maps Vietnamese prompts to the matching analysis', () {
      expect(
        classifyAssistantQuestion('Chi tiêu tuần này ra sao?'),
        AssistantQuestionKind.weeklyComparison,
      );
      expect(
        classifyAssistantQuestion('Có khoản nào lặp lại nhiều lần?'),
        AssistantQuestionKind.recurringExpenses,
      );
      expect(
        classifyAssistantQuestion('Cắt giảm ở đâu để tiết kiệm?'),
        AssistantQuestionKind.savingSuggestion,
      );
    });
  });

  group('AssistantRepositoryImpl', () {
    late TransactionRepository transactions;

    setUp(() async {
      SharedPreferences.setMockInitialValues({
        'assistant_intro_seen': true,
        'assistant_enabled': true,
        'assistant_access_transactions': true,
      });
      transactions = TransactionRepository(_FakeSupabaseClient());
      TransactionRepository.mockTransactions.clear();
    });

    tearDown(TransactionRepository.mockTransactions.clear);

    test('builds analysis from current transaction data', () async {
      final now = DateTime(2026, 7, 20);
      TransactionRepository.mockTransactions.addAll([
        _expense(
          id: '1',
          amount: 200000,
          note: 'Coffee',
          category: 'Food',
          date: now,
        ),
        _expense(
          id: '2',
          amount: 300000,
          note: 'Coffee',
          category: 'Food',
          date: now.subtract(const Duration(days: 1)),
        ),
        _expense(
          id: '3',
          amount: 100000,
          note: 'Bus',
          category: 'Travel',
          date: now.subtract(const Duration(days: 2)),
        ),
      ]);
      final repository = AssistantRepositoryImpl(
        preferences: await SharedPreferences.getInstance(),
        transactionRepository: transactions,
      );

      final snapshot = await repository.buildSnapshot(now);

      expect(snapshot.monthlyExpense, 600000);
      expect(snapshot.topCategoryName, 'Food');
      expect(snapshot.topCategoryAmount, 500000);
      expect(snapshot.recurringLabel, 'Coffee');
      expect(snapshot.recurringCount, 2);
    });

    test('returns no financial data when transaction access is off', () async {
      SharedPreferences.setMockInitialValues({
        'assistant_intro_seen': true,
        'assistant_enabled': true,
        'assistant_access_transactions': false,
      });
      final repository = AssistantRepositoryImpl(
        preferences: await SharedPreferences.getInstance(),
        transactionRepository: transactions,
      );

      final snapshot = await repository.buildSnapshot(DateTime.now());

      expect(snapshot.monthlyExpense, 0);
      expect(snapshot.topCategoryName, isNull);
    });
  });
}

TransactionEntry _expense({
  required String id,
  required double amount,
  required String note,
  required String category,
  required DateTime date,
}) {
  return TransactionEntry(
    id: id,
    amount: amount,
    type: TransactionType.expense,
    note: note,
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
