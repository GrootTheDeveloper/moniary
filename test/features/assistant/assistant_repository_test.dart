import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moniary/core/preferences/preferences_providers.dart';
import 'package:moniary/core/supabase/app_exception.dart';
import 'package:moniary/core/supabase/supabase_providers.dart';
import 'package:moniary/features/assistant/application/assistant_controller.dart';
import 'package:moniary/features/assistant/data/assistant_repository_impl.dart';
import 'package:moniary/features/assistant/domain/assistant_language_config.dart';
import 'package:moniary/features/assistant/domain/assistant_models.dart';
import 'package:moniary/features/assistant/domain/assistant_repository.dart';
import 'package:moniary/features/budgets/domain/budget_repository.dart';
import 'package:moniary/features/budgets/domain/monthly_budget.dart';
import 'package:moniary/features/categories/domain/models/category.dart';
import 'package:moniary/features/transactions/data/repositories/transaction_repository.dart';
import 'package:moniary/features/transactions/domain/models/transaction_entry.dart';
import 'package:moniary/features/wallets/data/repositories/wallet_repository.dart';
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
      expect(
        classifyAssistantQuestion('xin chao'),
        AssistantQuestionKind.greeting,
      );
      expect(
        classifyAssistantQuestion('toi ten la gi'),
        AssistantQuestionKind.userIdentity,
      );
      expect(
        classifyAssistantQuestion('thoi tiet hom nay sao'),
        AssistantQuestionKind.unsupported,
      );
      expect(
        classifyAssistantQuestion('How much have I spent this month?'),
        AssistantQuestionKind.monthlyTotal,
      );
      expect(
        classifyAssistantQuestion(
          'Which category costs me the most this month?',
        ),
        AssistantQuestionKind.topCategory,
      );
      expect(
        classifyAssistantQuestion('How much do I spend per day on average?'),
        AssistantQuestionKind.dailyAverage,
      );
    });
  });

  group('assistant answer text safety', () {
    test('normalizes comma-grouped numbers for chat display', () {
      expect(
        AssistantLanguageConfig.displaySafeAnswer(
          'You spent 6,231,000 VND this month.',
        ),
        'You spent 6 231 000 VND this month.',
      );
    });

    test('detects truncated comma number responses', () {
      expect(
        AssistantLanguageConfig.looksTruncatedAnswer('You spent 6,'),
        isTrue,
      );
      expect(
        AssistantLanguageConfig.looksTruncatedAnswer('You spent 6,2'),
        isTrue,
      );
      expect(
        AssistantLanguageConfig.looksTruncatedAnswer('You spent 6 231 000'),
        isFalse,
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
          amount: 200000,
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
        _expense(
          id: '4',
          amount: 200000,
          note: 'Coffee',
          category: 'Food',
          date: now.subtract(const Duration(days: 3)),
        ),
      ]);
      final repository = AssistantRepositoryImpl(
        preferences: await SharedPreferences.getInstance(),
        transactionRepository: transactions,
        walletRepository: _FakeWalletRepository(),
        budgetRepository: _FakeBudgetRepository(),
        client: _FakeSupabaseClient(),
        useMockData: true,
      );

      final snapshot = await repository.buildSnapshot(
        AssistantSnapshotWindow.local(now),
      );

      expect(snapshot.monthlyExpense, 700000);
      expect(snapshot.topCategoryName, 'Food');
      expect(snapshot.topCategoryAmount, 600000);
      expect(snapshot.recurringLabel, 'Coffee');
      expect(snapshot.recurringCount, 3);
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
        walletRepository: _FakeWalletRepository(),
        budgetRepository: _FakeBudgetRepository(),
        client: _FakeSupabaseClient(),
        useMockData: true,
      );

      final snapshot = await repository.buildSnapshot(
        AssistantSnapshotWindow.local(DateTime.now()),
      );

      expect(snapshot.monthlyExpense, 0);
      expect(snapshot.topCategoryName, isNull);
    });

    test('excludes future transactions from current month totals', () async {
      final now = DateTime(2026, 7, 20, 10);
      TransactionRepository.mockTransactions.addAll([
        _expense(
          id: 'past',
          amount: 200000,
          note: 'Lunch',
          category: 'Food',
          date: now.subtract(const Duration(days: 1)),
        ),
        _expense(
          id: 'future',
          amount: 900000,
          note: 'Future bill',
          category: 'Bills',
          date: now.add(const Duration(days: 1)),
        ),
      ]);
      final repository = AssistantRepositoryImpl(
        preferences: await SharedPreferences.getInstance(),
        transactionRepository: transactions,
        walletRepository: _FakeWalletRepository(),
        budgetRepository: _FakeBudgetRepository(),
        client: _FakeSupabaseClient(),
        useMockData: true,
      );

      final snapshot = await repository.buildSnapshot(
        AssistantSnapshotWindow.local(now),
      );

      expect(snapshot.monthlyExpense, 200000);
      expect(snapshot.topCategoryName, 'Food');
    });

    test('uses Sunday as the configured first day of week', () async {
      final now = DateTime(2026, 7, 20, 12); // Monday.
      TransactionRepository.mockTransactions.addAll([
        _expense(
          id: 'sunday',
          amount: 120000,
          note: 'Sunday groceries',
          category: 'Food',
          date: DateTime(2026, 7, 19, 12),
        ),
        _expense(
          id: 'previous-saturday',
          amount: 90000,
          note: 'Old coffee',
          category: 'Food',
          date: DateTime(2026, 7, 18, 12),
        ),
      ]);
      final repository = AssistantRepositoryImpl(
        preferences: await SharedPreferences.getInstance(),
        transactionRepository: transactions,
        walletRepository: _FakeWalletRepository(),
        budgetRepository: _FakeBudgetRepository(),
        client: _FakeSupabaseClient(),
        useMockData: true,
      );

      final snapshot = await repository.buildSnapshot(
        AssistantSnapshotWindow.local(now, firstDayOfWeek: DateTime.sunday),
      );

      expect(snapshot.currentWeekExpense, 120000);
      expect(snapshot.previousWeekExpense, 90000);
    });

    test(
      'separates previous and current month by explicit boundaries',
      () async {
        final now = DateTime(2026, 8, 1, 1);
        TransactionRepository.mockTransactions.addAll([
          _expense(
            id: 'previous-month',
            amount: 450000,
            note: 'July bill',
            category: 'Bills',
            date: DateTime(2026, 7, 31, 23),
          ),
          _expense(
            id: 'current-month',
            amount: 125000,
            note: 'August breakfast',
            category: 'Food',
            date: DateTime(2026, 8, 1),
          ),
        ]);
        final repository = AssistantRepositoryImpl(
          preferences: await SharedPreferences.getInstance(),
          transactionRepository: transactions,
          walletRepository: _FakeWalletRepository(),
          budgetRepository: _FakeBudgetRepository(),
          client: _FakeSupabaseClient(),
          useMockData: true,
        );

        final snapshot = await repository.buildSnapshot(
          AssistantSnapshotWindow.local(now),
        );

        expect(snapshot.monthlyExpense, 125000);
        expect(snapshot.previousMonthExpense, 450000);
      },
    );
  });

  group('AssistantConversationController', () {
    test('blocks direct asks when assistant consent is disabled', () async {
      SharedPreferences.setMockInitialValues({});
      final fakeRepository = _ImmediateAssistantRepository(
        access: const AssistantAccess(introSeen: true),
      );
      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(
            await SharedPreferences.getInstance(),
          ),
          currentSessionProvider.overrideWithValue(null),
          assistantRepositoryProvider.overrideWithValue(fakeRepository),
        ],
      );
      addTearDown(container.dispose);

      final controller = container.read(assistantConversationProvider.notifier);
      await expectLater(
        controller.ask('How much have I spent this month?'),
        throwsA(isA<AppException>()),
      );

      final state = container.read(assistantConversationProvider).value!;
      expect(state.messages, isEmpty);
    });

    test('blocks financial asks when transaction scope is disabled', () async {
      SharedPreferences.setMockInitialValues({});
      final fakeRepository = _ImmediateAssistantRepository(
        access: const AssistantAccess(
          introSeen: true,
          enabled: true,
          transactions: false,
        ),
      );
      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(
            await SharedPreferences.getInstance(),
          ),
          currentSessionProvider.overrideWithValue(null),
          assistantRepositoryProvider.overrideWithValue(fakeRepository),
        ],
      );
      addTearDown(container.dispose);

      final controller = container.read(assistantConversationProvider.notifier);
      await expectLater(
        controller.ask(
          'How much have I spent this month?',
          kind: AssistantQuestionKind.monthlyTotal,
        ),
        throwsA(isA<AppException>()),
      );

      final state = container.read(assistantConversationProvider).value!;
      expect(state.messages, isEmpty);
    });

    test('ignores duplicate sends while a request is in flight', () async {
      SharedPreferences.setMockInitialValues({});
      final fakeRepository = _ControllableAssistantRepository();
      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(
            await SharedPreferences.getInstance(),
          ),
          currentSessionProvider.overrideWithValue(null),
          assistantRepositoryProvider.overrideWithValue(fakeRepository),
        ],
      );
      addTearDown(container.dispose);

      final controller = container.read(assistantConversationProvider.notifier);
      final first = controller.ask(
        'How much have I spent this month?',
        kind: AssistantQuestionKind.monthlyTotal,
      );
      await Future<void>.delayed(Duration.zero);
      await controller.ask(
        'Which category costs the most?',
        kind: AssistantQuestionKind.topCategory,
      );

      expect(
        container.read(assistantConversationProvider).value!.isSending,
        isTrue,
      );
      expect(
        container.read(assistantConversationProvider).value!.messages,
        hasLength(1),
      );

      fakeRepository.completeAnswer('Looks steady for now.');
      await first;

      final state = container.read(assistantConversationProvider).value!;
      expect(state.isSending, isFalse);
      expect(state.messages, hasLength(2));
      expect(state.messages.first.text, 'How much have I spent this month?');
    });

    test('clear discards a stale in-flight assistant response', () async {
      SharedPreferences.setMockInitialValues({});
      final fakeRepository = _ControllableAssistantRepository();
      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(
            await SharedPreferences.getInstance(),
          ),
          currentSessionProvider.overrideWithValue(null),
          assistantRepositoryProvider.overrideWithValue(fakeRepository),
        ],
      );
      addTearDown(container.dispose);

      final controller = container.read(assistantConversationProvider.notifier);
      final request = controller.ask(
        'How much have I spent this month?',
        kind: AssistantQuestionKind.monthlyTotal,
      );
      await Future<void>.delayed(Duration.zero);
      controller.clear();
      fakeRepository.completeAnswer('Looks steady for now.');
      await request;

      final state = container.read(assistantConversationProvider).value!;
      expect(state.isSending, isFalse);
      expect(state.messages, isEmpty);
    });

    test('drops AI text with numbers for financial answers', () async {
      SharedPreferences.setMockInitialValues({});
      final fakeRepository = _ImmediateAssistantRepository(
        answer: 'You spent 123,000 VND this month.',
      );
      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(
            await SharedPreferences.getInstance(),
          ),
          currentSessionProvider.overrideWithValue(null),
          assistantRepositoryProvider.overrideWithValue(fakeRepository),
        ],
      );
      addTearDown(container.dispose);

      final controller = container.read(assistantConversationProvider.notifier);
      await controller.ask(
        'How much have I spent this month?',
        kind: AssistantQuestionKind.monthlyTotal,
      );

      final state = container.read(assistantConversationProvider).value!;
      expect(state.messages, hasLength(2));
      final assistant = state.messages.last;
      expect(assistant.insight, isNotNull);
      expect(assistant.assistantText, isNull);
    });

    test('sends only the latest eight messages as AI history', () async {
      SharedPreferences.setMockInitialValues({});
      final fakeRepository = _ImmediateAssistantRepository(answer: 'Hello!');
      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(
            await SharedPreferences.getInstance(),
          ),
          currentSessionProvider.overrideWithValue(null),
          assistantRepositoryProvider.overrideWithValue(fakeRepository),
        ],
      );
      addTearDown(container.dispose);

      final controller = container.read(assistantConversationProvider.notifier);
      for (var i = 0; i < 10; i++) {
        await controller.ask('hello $i', kind: AssistantQuestionKind.greeting);
      }

      expect(fakeRepository.capturedHistories.last, hasLength(8));
      expect(fakeRepository.capturedHistories.last.first.text, 'hello 5');
    });
  });
}

class _FakeWalletRepository extends WalletRepository {
  _FakeWalletRepository() : super(_FakeSupabaseClient(), useMockData: true);
}

class _FakeBudgetRepository implements BudgetRepository {
  @override
  Future<MonthlyBudget> fetchMonthlyBudget(DateTime month) async {
    return MonthlyBudget(
      month: DateTime(month.year, month.month),
      categories: const [],
      unbudgetedCategories: const [],
    );
  }

  @override
  Future<void> setCategoryLimit({
    required DateTime month,
    required String categoryId,
    required double amount,
    required double warningRatio,
  }) async {}
}

class _ControllableAssistantRepository implements AssistantRepository {
  final _answer = Completer<String?>();

  void completeAnswer(String? value) {
    if (!_answer.isCompleted) _answer.complete(value);
  }

  @override
  Future<AssistantAccess> loadAccess() async {
    return const AssistantAccess(introSeen: true, enabled: true);
  }

  @override
  Future<void> saveAccess(AssistantAccess access) async {}

  @override
  Future<FinancialAssistantSnapshot> buildSnapshot(
    AssistantSnapshotWindow window,
  ) async {
    return const FinancialAssistantSnapshot(
      monthlyExpense: 700000,
      previousMonthExpense: 500000,
      currentWeekExpense: 200000,
      previousWeekExpense: 100000,
      dailyAverage: 100000,
      topCategoryName: 'Food',
      topCategoryAmount: 500000,
      topCategoryShare: 0.7,
      recurringLabel: null,
      recurringCount: 0,
      recurringAmount: 0,
      suggestedSaving: 70000,
    );
  }

  @override
  Future<String?> generateAnswer({
    required String question,
    required AssistantQuestionKind kind,
    required String locale,
    required String currencyCode,
    required List<AssistantMessage> history,
    FinancialAssistantSnapshot? snapshot,
    String? profileName,
  }) {
    return _answer.future;
  }
}

class _ImmediateAssistantRepository implements AssistantRepository {
  _ImmediateAssistantRepository({
    this.access = const AssistantAccess(introSeen: true, enabled: true),
    this.answer = 'Looks steady for now.',
  });

  final AssistantAccess access;
  final String? answer;
  final capturedHistories = <List<AssistantMessage>>[];

  @override
  Future<AssistantAccess> loadAccess() async => access;

  @override
  Future<void> saveAccess(AssistantAccess access) async {}

  @override
  Future<FinancialAssistantSnapshot> buildSnapshot(
    AssistantSnapshotWindow window,
  ) async {
    return const FinancialAssistantSnapshot(
      monthlyExpense: 700000,
      previousMonthExpense: 500000,
      currentWeekExpense: 200000,
      previousWeekExpense: 100000,
      dailyAverage: 100000,
      topCategoryName: 'Food',
      topCategoryAmount: 500000,
      topCategoryShare: 0.7,
      recurringLabel: null,
      recurringCount: 0,
      recurringAmount: 0,
      suggestedSaving: 70000,
    );
  }

  @override
  Future<String?> generateAnswer({
    required String question,
    required AssistantQuestionKind kind,
    required String locale,
    required String currencyCode,
    required List<AssistantMessage> history,
    FinancialAssistantSnapshot? snapshot,
    String? profileName,
  }) async {
    capturedHistories.add(List<AssistantMessage>.from(history));
    return answer;
  }
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
