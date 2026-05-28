import 'package:flutter_test/flutter_test.dart';
import 'package:moniary/features/groups/data/group_expense_validation_service.dart';
import 'package:moniary/features/groups/domain/expense_group.dart';
import 'package:moniary/features/groups/domain/expense_split.dart';
import 'package:moniary/features/groups/domain/group_member.dart';

void main() {
  const service = GroupExpenseValidationService();

  group('GroupExpenseValidationService Extended Tests', () {
    final validGroup = ExpenseGroup(
      id: 'group',
      name: 'Nhóm hợp lệ',
      ownerId: 'a',
      createdAt: DateTime(2026),
      members: const [
        GroupMember(id: 'a', displayName: 'A'),
        GroupMember(id: 'b', displayName: 'B'),
      ],
    );

    test('validate returns error if group has less than 2 members', () {
      final smallGroup = ExpenseGroup(
        id: 'group',
        name: 'Nhóm nhỏ',
        ownerId: 'a',
        createdAt: DateTime(2026),
        members: const [
          GroupMember(id: 'a', displayName: 'A'),
        ],
      );

      final error = service.validate(
        group: smallGroup,
        amount: 100,
        payerMemberId: 'a',
        participantIds: ['a'],
        splits: const [ExpenseSplit(memberId: 'a', amount: 100)],
      );

      expect(error, contains('ít nhất 2 thành viên'));
    });

    test('validate returns error if amount is 0 or negative', () {
      final errorZero = service.validate(
        group: validGroup,
        amount: 0,
        payerMemberId: 'a',
        participantIds: ['a', 'b'],
        splits: const [
          ExpenseSplit(memberId: 'a', amount: 0),
          ExpenseSplit(memberId: 'b', amount: 0),
        ],
      );

      final errorNegative = service.validate(
        group: validGroup,
        amount: -50,
        payerMemberId: 'a',
        participantIds: ['a', 'b'],
        splits: const [
          ExpenseSplit(memberId: 'a', amount: -25),
          ExpenseSplit(memberId: 'b', amount: -25),
        ],
      );

      expect(errorZero, contains('lớn hơn 0'));
      expect(errorNegative, contains('lớn hơn 0'));
    });

    test('validate returns error if payerMemberId is null or not in group', () {
      final errorNull = service.validate(
        group: validGroup,
        amount: 100,
        payerMemberId: null,
        participantIds: ['a', 'b'],
        splits: const [
          ExpenseSplit(memberId: 'a', amount: 50),
          ExpenseSplit(memberId: 'b', amount: 50),
        ],
      );

      final errorNotInGroup = service.validate(
        group: validGroup,
        amount: 100,
        payerMemberId: 'c', // not in group
        participantIds: ['a', 'b'],
        splits: const [
          ExpenseSplit(memberId: 'a', amount: 50),
          ExpenseSplit(memberId: 'b', amount: 50),
        ],
      );

      expect(errorNull, contains('người đã thanh toán'));
      expect(errorNotInGroup, contains('người đã thanh toán'));
    });

    test('validate returns error if participantIds list is empty', () {
      final error = service.validate(
        group: validGroup,
        amount: 100,
        payerMemberId: 'a',
        participantIds: [],
        splits: [],
      );

      expect(error, contains('Chọn ít nhất một người tham gia'));
    });

    test('validate returns error if participants have duplicate IDs', () {
      final error = service.validate(
        group: validGroup,
        amount: 100,
        payerMemberId: 'a',
        participantIds: ['a', 'b', 'a'], // duplicates
        splits: const [
          ExpenseSplit(memberId: 'a', amount: 100),
          ExpenseSplit(memberId: 'b', amount: 0),
        ],
      );

      expect(error, contains('cần đúng một phần chia'));
    });

    test('createEqualSplits with amount <= 0 or empty participants returns empty list', () {
      final splitsZeroAmount = service.createEqualSplits(amount: 0, participantIds: ['a', 'b']);
      final splitsEmptyParticipants = service.createEqualSplits(amount: 100, participantIds: []);

      expect(splitsZeroAmount, isEmpty);
      expect(splitsEmptyParticipants, isEmpty);
    });

    test('SplitMethod label extension values', () {
      expect(SplitMethod.equal.label, 'Chia đều');
      expect(SplitMethod.manual.label, 'Tự nhập số tiền');
    });
  });
}
