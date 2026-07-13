import 'package:intl/intl.dart';

// Dynamic currency policy:
// - Empty/null-like code → VND (₫, 0 decimals, locale-aware separators).
// - VND → same as above.
// - Any other non-empty code → NumberFormat.simpleCurrency via Intl.
//   Intl resolves symbol and decimal digits from locale data for the code.
//   Unknown codes (e.g. XYZ) produce the code itself as symbol: "12.345,67 XYZ".
//   Currency-symbol variation by locale (e.g. $ vs CA$) is intentional Intl
//   behavior — do not override or whitelist symbols.

String currencySymbolFor({
  required String currencyCode,
  required String locale,
}) {
  final normalized = currencyCode.trim().toUpperCase();
  if (normalized.isEmpty || normalized == 'VND') return '₫';
  final symbol = NumberFormat.simpleCurrency(
    locale: locale,
    name: normalized,
  ).currencySymbol;
  // Intl returns the code itself for unknown currencies — acceptable as suffix.
  return symbol.isEmpty ? normalized : symbol;
}

String formatCurrency(
  num amount, {
  required String currencyCode,
  required String locale,
}) {
  final normalized = currencyCode.trim().toUpperCase();
  if (normalized.isEmpty || normalized == 'VND') {
    return formatVnd(amount, locale: locale);
  }
  return NumberFormat.simpleCurrency(
    locale: locale,
    name: normalized,
  ).format(amount);
}

String formatVnd(num amount, {String locale = 'vi_VN'}) {
  return NumberFormat.currency(
    locale: locale,
    symbol: '₫',
    decimalDigits: 0,
  ).format(amount);
}
