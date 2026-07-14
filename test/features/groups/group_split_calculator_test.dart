import 'package:flutter_test/flutter_test.dart';
import 'package:moniary/features/groups/domain/entities/group_enums.dart';
import 'package:moniary/features/groups/domain/services/group_split_calculator.dart';

void main() {
  const calculator = GroupSplitCalculator();
  const members = ['a', 'b', 'c'];

  group('GroupSplitCalculator equal split', () {
    test('chia đều chỉ cho thành viên được chọn', () {
      final result = calculator.calculate(
        totalAmount: 200,
        activeMemberIds: members,
        participantIds: const ['a', 'b'],
        splitMode: GroupSplitMode.equal,
        paymentMode: GroupPaymentMode.singlePayer,
        payerAmounts: const {'c': 200},
      );

      expect(result.shares, {'a': 100, 'b': 100});
      expect(result.balances, {'a': 100, 'b': 100, 'c': -200});
    });
    test('chia đều không dư', () {
      final shares = calculator.calculateEqualShares(
        totalAmount: 300,
        activeMemberIds: members,
      );

      expect(shares, {'a': 100, 'b': 100, 'c': 100});
    });

    test('chia đều có dư theo thứ tự ổn định', () {
      final shares = calculator.calculateEqualShares(
        totalAmount: 100,
        activeMemberIds: const ['c', 'a', 'b'],
      );

      expect(shares, {'a': 34, 'b': 33, 'c': 33});
      expect(shares.values.reduce((left, right) => left + right), 100);
    });

    test('chia đều và mọi người đều trả', () {
      final result = calculator.calculate(
        totalAmount: 300,
        activeMemberIds: members,
        splitMode: GroupSplitMode.equal,
        paymentMode: GroupPaymentMode.everyonePaid,
      );

      expect(result.paidAmounts, result.shares);
      expect(result.balances.values, everyElement(0));
    });

    test('chia đều và một người trả', () {
      final result = calculator.calculate(
        totalAmount: 300,
        activeMemberIds: members,
        splitMode: GroupSplitMode.equal,
        paymentMode: GroupPaymentMode.singlePayer,
        payerAmounts: const {'a': 300},
      );

      expect(result.balances, {'a': -200, 'b': 100, 'c': 100});
    });

    test('chia đều và nhiều người trả', () {
      final result = calculator.calculate(
        totalAmount: 300,
        activeMemberIds: members,
        splitMode: GroupSplitMode.equal,
        paymentMode: GroupPaymentMode.multiplePayers,
        payerAmounts: const {'a': 200, 'b': 100},
      );

      expect(result.balances, {'a': -100, 'b': 0, 'c': 100});
    });

    test('nhiều người trả nhưng tổng tiền không khớp', () {
      expect(
        () => calculator.calculate(
          totalAmount: 300,
          activeMemberIds: members,
          splitMode: GroupSplitMode.equal,
          paymentMode: GroupPaymentMode.multiplePayers,
          payerAmounts: const {'a': 100, 'b': 100},
        ),
        throwsA(
          isA<GroupSplitException>().having(
            (error) => error.error,
            'error',
            GroupSplitError.paidTotalMismatch,
          ),
        ),
      );
    });
  });

  group('GroupSplitCalculator unequal split', () {
    test('chia không đều và mọi người đều trả', () {
      final result = calculator.calculate(
        totalAmount: 300,
        activeMemberIds: members,
        splitMode: GroupSplitMode.unequal,
        paymentMode: GroupPaymentMode.everyonePaid,
        unequalShares: const {'a': 50, 'b': 100, 'c': 150},
        submittedMemberIds: members.toSet(),
      );

      expect(result.paidAmounts, result.shares);
      expect(result.balances.values, everyElement(0));
    });

    test('chia không đều và một người trả', () {
      final result = calculator.calculate(
        totalAmount: 300,
        activeMemberIds: members,
        splitMode: GroupSplitMode.unequal,
        paymentMode: GroupPaymentMode.singlePayer,
        unequalShares: const {'a': 50, 'b': 100, 'c': 150},
        submittedMemberIds: members.toSet(),
        payerAmounts: const {'a': 300},
      );

      expect(result.balances, {'a': -250, 'b': 100, 'c': 150});
    });

    test('chia không đều và nhiều người trả', () {
      final result = calculator.calculate(
        totalAmount: 300,
        activeMemberIds: members,
        splitMode: GroupSplitMode.unequal,
        paymentMode: GroupPaymentMode.multiplePayers,
        unequalShares: const {'a': 50, 'b': 100, 'c': 150},
        submittedMemberIds: members.toSet(),
        payerAmounts: const {'a': 200, 'c': 100},
      );

      expect(result.balances, {'a': -150, 'b': 100, 'c': 50});
    });

    test('tổng share không khớp', () {
      expect(
        () => calculator.calculate(
          totalAmount: 300,
          activeMemberIds: members,
          splitMode: GroupSplitMode.unequal,
          paymentMode: GroupPaymentMode.everyonePaid,
          unequalShares: const {'a': 50, 'b': 100, 'c': 100},
          submittedMemberIds: members.toSet(),
        ),
        throwsA(
          isA<GroupSplitException>().having(
            (error) => error.error,
            'error',
            GroupSplitError.shareTotalMismatch,
          ),
        ),
      );
    });

    test('còn thành viên chưa nhập', () {
      expect(
        () => calculator.calculate(
          totalAmount: 300,
          activeMemberIds: members,
          splitMode: GroupSplitMode.unequal,
          paymentMode: GroupPaymentMode.everyonePaid,
          unequalShares: const {'a': 100, 'b': 200},
          submittedMemberIds: const {'a', 'b'},
        ),
        throwsA(
          isA<GroupSplitException>().having(
            (error) => error.error,
            'error',
            GroupSplitError.pendingMemberInput,
          ),
        ),
      );
    });

    test('cho phép used amount bằng 0', () {
      final result = calculator.calculate(
        totalAmount: 300,
        activeMemberIds: members,
        splitMode: GroupSplitMode.unequal,
        paymentMode: GroupPaymentMode.everyonePaid,
        unequalShares: const {'a': 0, 'b': 100, 'c': 200},
        submittedMemberIds: members.toSet(),
      );

      expect(result.shares['a'], 0);
    });

    test('không có active member thì thất bại', () {
      expect(
        () => calculator.calculateEqualShares(
          totalAmount: 100,
          activeMemberIds: const [],
        ),
        throwsA(
          isA<GroupSplitException>().having(
            (error) => error.error,
            'error',
            GroupSplitError.noActiveMembers,
          ),
        ),
      );
    });
  });

  group('GroupSplitCalculator exact split', () {
    test('chấp nhận số tiền cụ thể có tổng khớp', () {
      final result = calculator.calculate(
        totalAmount: 300,
        activeMemberIds: members,
        participantIds: const ['a', 'b'],
        splitMode: GroupSplitMode.exact,
        paymentMode: GroupPaymentMode.singlePayer,
        unequalShares: const {'a': 120, 'b': 180},
        payerAmounts: const {'c': 300},
      );

      expect(result.shares, {'a': 120, 'b': 180});
      expect(result.balances, {'a': 120, 'b': 180, 'c': -300});
    });

    test('từ chối số tiền cụ thể có tổng sai', () {
      expect(
        () => calculator.validateDraft(
          totalAmount: 300,
          activeMemberIds: members,
          participantIds: const ['a', 'b'],
          splitMode: GroupSplitMode.exact,
          paymentMode: GroupPaymentMode.everyonePaid,
          shareAmounts: const {'a': 100, 'b': 100},
        ),
        throwsA(
          isA<GroupSplitException>().having(
            (error) => error.error,
            'error',
            GroupSplitError.shareTotalMismatch,
          ),
        ),
      );
    });

    test('từ chối participant không còn active', () {
      expect(
        () => calculator.validateDraft(
          totalAmount: 300,
          activeMemberIds: members,
          participantIds: const ['a', 'removed'],
          splitMode: GroupSplitMode.equal,
          paymentMode: GroupPaymentMode.everyonePaid,
        ),
        throwsA(
          isA<GroupSplitException>().having(
            (error) => error.error,
            'error',
            GroupSplitError.participantNotActive,
          ),
        ),
      );
    });
  });
}
