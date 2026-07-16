import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

/// Formats integer money values with locale-aware grouping separators.
///
/// Group finance stores money as integers, so this formatter intentionally
/// drops decimal and non-numeric characters while the user types.
class IntegerMoneyInputFormatter extends TextInputFormatter {
  IntegerMoneyInputFormatter({required String locale, this.maxDigits = 15})
    : _numberFormat = NumberFormat.decimalPattern(locale);

  final NumberFormat _numberFormat;
  final int maxDigits;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) return const TextEditingValue();
    if (digits.length > maxDigits) return oldValue;

    final value = int.tryParse(digits);
    if (value == null) return oldValue;
    final formatted = _numberFormat.format(value);
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

int parseIntegerMoney(String input) {
  return int.tryParse(input.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
}
