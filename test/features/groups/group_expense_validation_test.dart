import 'package:flutter_test/flutter_test.dart';
import 'package:moniary/features/groups/data/group_expense_validation_service.dart';
import 'package:moniary/features/groups/domain/expense_group.dart';
import 'package:moniary/features/groups/domain/expense_split.dart';
import 'package:moniary/features/groups/domain/group_member.dart';

void main() {
  const service = GroupExpenseValidationService();
  final group = ExpenseGroup(
    id: 'group',
    name: 'Du lịch',
    ownerId: 'owner',
    createdAt: DateTime(2026),
    members: const [
      GroupMember(id: 'a', displayName: 'A'),
      GroupMember(id: 'b', displayName: 'B'),
      GroupMember(id: 'c', displayName: 'C'),
    ],
  );

  test('chia đều giữ nguyên tổng tiền khi không chia hết', () {
    final splits = service.createEqualSplits(
      amount: 100000,
      participantIds: ['a', 'b', 'c'],
    );

    expect(splits.map((split) => split.amount), [33334, 33333, 33333]);
    expect(splits.fold<int>(0, (sum, split) => sum + split.amount), 100000);
  });

  test('cho phép chia tay khi tổng khớp chi phí', () {
    final error = service.validate(
      group: group,
      amount: 300000,
      payerMemberId: 'a',
      participantIds: ['a', 'b', 'c'],
      splits: const [
        ExpenseSplit(memberId: 'a', amount: 50000),
        ExpenseSplit(memberId: 'b', amount: 100000),
        ExpenseSplit(memberId: 'c', amount: 150000),
      ],
    );

    expect(error, isNull);
  });

  test('từ chối chia tay có tổng sai hoặc giá trị âm', () {
    final wrongTotal = service.validate(
      group: group,
      amount: 300000,
      payerMemberId: 'a',
      participantIds: ['a', 'b'],
      splits: const [
        ExpenseSplit(memberId: 'a', amount: 100000),
        ExpenseSplit(memberId: 'b', amount: 100000),
      ],
    );
    final negative = service.validate(
      group: group,
      amount: 300000,
      payerMemberId: 'a',
      participantIds: ['a', 'b'],
      splits: const [
        ExpenseSplit(memberId: 'a', amount: -1),
        ExpenseSplit(memberId: 'b', amount: 300001),
      ],
    );

    expect(wrongTotal, GroupExpenseValidationError.splitMismatch);
    expect(negative, GroupExpenseValidationError.negativeSplit);
  });
}
