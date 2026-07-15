import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moniary/shared/utils/integer_money_input_formatter.dart';

void main() {
  TextEditingValue format(String locale, String value) {
    return IntegerMoneyInputFormatter(
      locale: locale,
    ).formatEditUpdate(const TextEditingValue(), TextEditingValue(text: value));
  }

  test('formats integer money with the active locale separator', () {
    expect(format('vi_VN', '1000000').text, '1.000.000');
    expect(format('en_US', '1000000').text, '1,000,000');
  });

  test('parses formatted values without losing integer precision', () {
    expect(parseIntegerMoney('1.234.567'), 1234567);
    expect(parseIntegerMoney('1,234,567'), 1234567);
    expect(parseIntegerMoney(' 250 000 đ'), 250000);
  });

  test('rejects an edit that exceeds the configured digit limit', () {
    final formatter = IntegerMoneyInputFormatter(locale: 'vi_VN', maxDigits: 3);
    const oldValue = TextEditingValue(
      text: '999',
      selection: TextSelection.collapsed(offset: 3),
    );

    expect(
      formatter.formatEditUpdate(
        oldValue,
        const TextEditingValue(text: '9999'),
      ),
      oldValue,
    );
  });
}
