import 'package:flutter_test/flutter_test.dart';
import 'package:moniary/shared/utils/currency_formatter.dart';

void main() {
  group('Currency Formatter Tests', () {
    test('formatVnd(0) returns string containing 0', () {
      final result = formatVnd(0);
      expect(result, contains('0'));
    });

    test('formatVnd(125000) returns string containing formatted digits', () {
      final result = formatVnd(125000);
      expect(result, contains('125'));
      expect(result, contains('000'));
      expect(result.toLowerCase(), anyOf(contains('₫'), contains('đ')));
    });

    test(
      'formatVnd(-50000) returns string containing negative indicator and digits',
      () {
        final result = formatVnd(-50000);
        expect(result, contains('-'));
        expect(result, contains('50'));
        expect(result, contains('000'));
      },
    );
  });
}
