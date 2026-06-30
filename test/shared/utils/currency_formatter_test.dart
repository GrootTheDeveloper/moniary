import 'package:flutter_test/flutter_test.dart';
import 'package:moniary/shared/utils/currency_formatter.dart';

void main() {
  group('formatCurrency', () {
    // VND
    test('VND 0 contains 0', () {
      expect(
        formatCurrency(0, currencyCode: 'VND', locale: 'vi_VN'),
        contains('0'),
      );
    });

    test('VND 125000 contains digits and VND symbol', () {
      final result = formatCurrency(
        125000,
        currencyCode: 'VND',
        locale: 'vi_VN',
      );
      expect(result, contains('125'));
      expect(result, contains('000'));
      expect(result.toLowerCase(), anyOf(contains('₫'), contains('đ')));
    });

    test('VND -50000 contains negative indicator', () {
      final result = formatCurrency(
        -50000,
        currencyCode: 'VND',
        locale: 'vi_VN',
      );
      expect(result, contains('-'));
      expect(result, contains('50'));
      expect(result, contains('000'));
    });

    test('empty code falls back to VND', () {
      final result = formatCurrency(100000, currencyCode: '', locale: 'vi_VN');
      expect(result.toLowerCase(), anyOf(contains('₫'), contains('đ')));
    });

    test('whitespace-only code falls back to VND', () {
      final result = formatCurrency(
        100000,
        currencyCode: '  ',
        locale: 'vi_VN',
      );
      expect(result.toLowerCase(), anyOf(contains('₫'), contains('đ')));
    });

    // Non-VND — Intl dynamic behavior
    test('USD en_US contains digits and does not use VND symbol', () {
      final result = formatCurrency(
        1234.56,
        currencyCode: 'USD',
        locale: 'en_US',
      );
      expect(result, contains('1'));
      expect(result, contains('234'));
      expect(result, isNot(contains('₫')));
    });

    test('USD vi_VN contains digits and does not use VND symbol', () {
      // Intl resolves symbol per locale — $ or US$ are both valid Intl output.
      final result = formatCurrency(
        1234.56,
        currencyCode: 'USD',
        locale: 'vi_VN',
      );
      expect(result, contains('1'));
      expect(result, contains('234'));
      expect(result, isNot(contains('₫')));
    });

    test('JPY uses zero decimals and non-VND symbol', () {
      final result = formatCurrency(1000, currencyCode: 'JPY', locale: 'en_US');
      expect(result, contains('1'));
      expect(result, contains('000'));
      expect(result, isNot(contains('₫')));
      // JPY has no decimal — no period expected
      expect(result, isNot(contains('.')));
    });

    // Unknown code — graceful dynamic fallback via Intl
    test('unknown code XYZ uses code as suffix, no VND symbol, no throw', () {
      final result = formatCurrency(
        12345.67,
        currencyCode: 'XYZ',
        locale: 'vi_VN',
      );
      expect(result, isNotEmpty);
      expect(result, isNot(contains('₫')));
      expect(result, contains('XYZ'));
    });
  });

  group('currencySymbolFor', () {
    test('VND returns ₫', () {
      expect(
        currencySymbolFor(currencyCode: 'VND', locale: 'vi_VN'),
        equals('₫'),
      );
    });

    test('empty code returns ₫', () {
      expect(currencySymbolFor(currencyCode: '', locale: 'vi_VN'), equals('₫'));
    });

    test('USD returns non-empty symbol', () {
      // Intl returns $ or locale variant — not pinned to avoid locale sensitivity.
      final sym = currencySymbolFor(currencyCode: 'USD', locale: 'en_US');
      expect(sym, isNotEmpty);
      expect(sym, isNot(equals('₫')));
    });

    test('unknown code XYZ returns non-empty, non-VND symbol', () {
      final sym = currencySymbolFor(currencyCode: 'XYZ', locale: 'en_US');
      expect(sym, isNotEmpty);
      expect(sym, isNot(equals('₫')));
    });

    test('lowercase code is normalized to uppercase', () {
      final vnd = currencySymbolFor(currencyCode: 'vnd', locale: 'vi_VN');
      expect(vnd, equals('₫'));
    });
  });
}
