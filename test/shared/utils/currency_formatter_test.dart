import 'package:flutter_test/flutter_test.dart';
import 'package:moniary/shared/utils/currency_formatter.dart';

void main() {
  group('Currency Formatter Tests', () {
    test('formatCurrency VND 0 returns string containing 0', () {
      final result = formatCurrency(0, currencyCode: 'VND', locale: 'vi_VN');
      expect(result, contains('0'));
    });

    test('formatCurrency VND 125000 returns string containing formatted digits', () {
      final result = formatCurrency(125000, currencyCode: 'VND', locale: 'vi_VN');
      expect(result, contains('125'));
      expect(result, contains('000'));
      expect(result.toLowerCase(), anyOf(contains('₫'), contains('đ')));
    });

    test(
      'formatCurrency VND -50000 returns string containing negative indicator and digits',
      () {
        final result = formatCurrency(-50000, currencyCode: 'VND', locale: 'vi_VN');
        expect(result, contains('-'));
        expect(result, contains('50'));
        expect(result, contains('000'));
      },
    );
  });
}
