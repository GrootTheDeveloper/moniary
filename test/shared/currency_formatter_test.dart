import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:moniary/shared/utils/currency_formatter.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting();
  });

  setUp(() => setActiveCurrencyCode('VND'));

  group('formatMoney', () {
    test('formats VND with no decimals and the dong symbol', () {
      final result = formatMoney(1234567, currencyCode: 'VND');
      expect(result, contains('₫'));
      expect(result, contains('1.234.567'));
      expect(result, isNot(contains(',00')));
    });

    test('formats USD with two decimals and the dollar symbol', () {
      final result = formatMoney(1234.5, currencyCode: 'USD');
      expect(result, contains(r'$'));
      expect(result, contains('1,234.50'));
    });

    test('formats JPY with no decimals', () {
      final result = formatMoney(1234.9, currencyCode: 'JPY');
      expect(result, contains('¥'));
      expect(result, isNot(contains('.')));
    });

    test('includeSymbol: false omits the currency symbol', () {
      final result = formatMoney(
        1000,
        currencyCode: 'USD',
        includeSymbol: false,
      );
      expect(result, isNot(contains(r'$')));
      expect(result, contains('1,000'));
    });

    test('unknown currency falls back to its code as the symbol', () {
      final result = formatMoney(1000, currencyCode: 'XYZ');
      expect(result, contains('XYZ'));
    });
  });

  group('active currency', () {
    test('formatVnd follows the active currency', () {
      setActiveCurrencyCode('USD');
      expect(activeCurrencyCode(), 'USD');
      expect(activeCurrencySymbol(), r'$');
      expect(formatVnd(1234.5), contains(r'$'));
      expect(formatVnd(1234.5), contains('1,234.50'));
    });

    test('setActiveCurrencyCode normalizes and ignores blanks', () {
      setActiveCurrencyCode('usd');
      expect(activeCurrencyCode(), 'USD');
      setActiveCurrencyCode('   ');
      expect(activeCurrencyCode(), 'USD');
    });
  });
}
