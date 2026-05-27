import 'package:flutter_test/flutter_test.dart';
import 'package:moniary/features/groups/data/debt_calculator_service.dart';
import 'package:moniary/features/groups/domain/expense_split.dart';
import 'package:moniary/features/groups/domain/group_expense.dart';

void main() {
  const service = DebtCalculatorService();

  test('tính số dư đúng cho khoản chia đều', () {
    final expenses = [
      GroupExpense(
        id: 'expense',
        groupId: 'group',
        payerMemberId: 'a',
        amount: 300000,
        note: 'Bữa tối',
        date: DateTime(2026),
        splits: [
          ExpenseSplit(memberId: 'a', amount: 100000),
          ExpenseSplit(memberId: 'b', amount: 100000),
          ExpenseSplit(memberId: 'c', amount: 100000),
        ],
      ),
    ];

    final balances = service.calculateBalances(expenses);
    final settlement = service.simplifyDebts(balances);

    expect(balances, {'a': 200000, 'b': -100000, 'c': -100000});
    expect(settlement, hasLength(2));
    expect(settlement.map((item) => item.toMemberId), everyElement('a'));
    expect(settlement.map((item) => item.amount), everyElement(100000));
  });

  test('tính số dư đúng cho phần chia nhập tay qua nhiều hóa đơn', () {
    final expenses = [
      GroupExpense(
        id: 'one',
        groupId: 'group',
        payerMemberId: 'a',
        amount: 200000,
        note: '',
        date: DateTime(2026),
        splits: [
          ExpenseSplit(memberId: 'a', amount: 50000),
          ExpenseSplit(memberId: 'b', amount: 150000),
        ],
      ),
      GroupExpense(
        id: 'two',
        groupId: 'group',
        payerMemberId: 'b',
        amount: 50000,
        note: '',
        date: DateTime(2026),
        splits: [ExpenseSplit(memberId: 'a', amount: 50000)],
      ),
    ];

    final balances = service.calculateBalances(expenses);

    expect(balances['a'], 100000);
    expect(balances['b'], -100000);
  });
}
