import 'package:flutter_test/flutter_test.dart';
import 'package:moniary/shared/utils/currency_formatter.dart';

void main() {
  group('formatCurrency (VND)', () {
    test('0 returns string containing 0', () {
      final result = formatCurrency(0, currencyCode: 'VND', locale: 'vi');
      expect(result, contains('0'));
    });

    test('125000 returns string containing formatted digits', () {
      final result = formatCurrency(125000, currencyCode: 'VND', locale: 'vi');
      expect(result, contains('125'));
      expect(result, contains('000'));
      expect(result.toLowerCase(), anyOf(contains('₫'), contains('đ')));
    });

    test('-50000 returns string containing negative indicator and digits', () {
      final result = formatCurrency(-50000, currencyCode: 'VND', locale: 'vi');
      expect(result, contains('-'));
      expect(result, contains('50'));
      expect(result, contains('000'));
    });

    test('empty currency code falls back to VND formatting', () {
      final result = formatCurrency(1000, currencyCode: '', locale: 'vi');
      expect(result.toLowerCase(), anyOf(contains('₫'), contains('đ')));
    });
  });

  group('formatCurrency (other currencies)', () {
    test('USD formats with 2 decimal digits', () {
      final result = formatCurrency(125.5, currencyCode: 'USD', locale: 'en');
      expect(result, contains('125.50'));
    });
  });

  group('currencySymbolFor', () {
    test('VND returns đ symbol', () {
      expect(currencySymbolFor(currencyCode: 'VND', locale: 'vi'), '₫');
    });

    test('empty code returns đ symbol', () {
      expect(currencySymbolFor(currencyCode: '', locale: 'vi'), '₫');
    });

    test('USD returns \$ symbol', () {
      expect(currencySymbolFor(currencyCode: 'USD', locale: 'en'), '\$');
    });
  });
}
