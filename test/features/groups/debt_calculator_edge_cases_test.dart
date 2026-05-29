import 'package:flutter_test/flutter_test.dart';
import 'package:moniary/features/groups/data/debt_calculator_service.dart';
import 'package:moniary/features/groups/domain/expense_split.dart';
import 'package:moniary/features/groups/domain/group_expense.dart';

void main() {
  const service = DebtCalculatorService();

  group('DebtCalculatorService Edge Cases', () {
    test('calculateBalances with empty list returns empty map', () {
      final balances = service.calculateBalances([]);
      expect(balances, isEmpty);
    });

    test(
      'calculateBalances with single member (payer = participant) returns balance 0',
      () {
        final expenses = [
          GroupExpense(
            id: 'one',
            groupId: 'group',
            payerMemberId: 'a',
            amount: 50000,
            note: 'Chỉ 1 người',
            date: DateTime(2026),
            splits: const [ExpenseSplit(memberId: 'a', amount: 50000)],
          ),
        ];

        final balances = service.calculateBalances(expenses);
        expect(balances['a'], 0.0);
      },
    );

    test('simplifyDebts with balances near 0.01 threshold are ignored', () {
      final balances = {
        'a': 0.009, // near positive threshold
        'b': -0.009, // near negative threshold
      };

      final settlements = service.simplifyDebts(balances);
      expect(settlements, isEmpty);
    });

    test('simplifyDebts handles circular debts correctly', () {
      // A owes B, B owes C, C owes A -> should balance out depending on values
      // A: +100000 (net)
      // B: -100000 (net)
      // C: 0 (net)
      final balances = {'a': 100000.0, 'b': -100000.0, 'c': 0.0};

      final settlements = service.simplifyDebts(balances);
      expect(settlements, hasLength(1));
      expect(settlements.first.fromMemberId, 'b');
      expect(settlements.first.toMemberId, 'a');
      expect(settlements.first.amount, 100000.0);
    });
  });
}
