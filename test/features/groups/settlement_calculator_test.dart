import 'package:flutter_test/flutter_test.dart';
import 'package:moniary/features/groups/domain/services/settlement_calculator.dart';

void main() {
  const calculator = SettlementCalculator();

  test('không tạo settlement khi tất cả balance bằng 0', () {
    expect(calculator.calculate(const {'a': 0, 'b': 0}), isEmpty);
  });

  test('một debtor trả một creditor', () {
    final result = calculator.calculate(const {'a': 100, 'b': -100});

    expect(result, hasLength(1));
    expect(result.first.fromUserId, 'a');
    expect(result.first.toUserId, 'b');
    expect(result.first.amount, 100);
  });

  test('một debtor trả nhiều creditor', () {
    final result = calculator.calculate(const {'a': 300, 'b': -100, 'c': -200});

    expect(result, hasLength(2));
    expect(result.map((item) => item.amount), containsAll([200, 100]));
  });

  test('nhiều debtor trả một creditor', () {
    final result = calculator.calculate(const {'a': 100, 'b': 200, 'c': -300});

    expect(result, hasLength(2));
    expect(result.map((item) => item.toUserId), everyElement('c'));
  });

  test('nhiều debtor và nhiều creditor', () {
    final result = calculator.calculate(const {
      'a': 200,
      'b': 100,
      'c': -150,
      'd': -150,
    });

    expect(result, hasLength(3));
    expect(result.fold<int>(0, (sum, item) => sum + item.amount), 300);
  });

  test('debtor lớn nhất trả creditor âm nhiều nhất trước', () {
    final result = calculator.calculate(const {
      'a': 100,
      'b': 300,
      'c': -250,
      'd': -150,
    });

    expect(result.first.fromUserId, 'b');
    expect(result.first.toUserId, 'c');
    expect(result.first.amount, 250);
  });

  test('tất cả balance về 0 sau settlement suggestion', () {
    final balances = <String, int>{'a': 350, 'b': 150, 'c': -200, 'd': -300};
    final result = calculator.calculate(balances);

    for (final item in result) {
      balances[item.fromUserId] = balances[item.fromUserId]! - item.amount;
      balances[item.toUserId] = balances[item.toUserId]! + item.amount;
    }

    expect(balances.values, everyElement(0));
  });

  test('từ chối khi tổng debt không bằng tổng credit', () {
    expect(
      () => calculator.calculate(const {'a': 100, 'b': -90}),
      throwsArgumentError,
    );
  });
}
