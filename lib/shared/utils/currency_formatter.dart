import 'package:intl/intl.dart';

String currencySymbolFor({
  required String currencyCode,
  required String locale,
}) {
  final normalized = currencyCode.trim().toUpperCase();
  if (normalized.isEmpty || normalized == 'VND') return '₫';
  return NumberFormat.simpleCurrency(locale: locale, name: normalized).currencySymbol;
}

String formatCurrency(
  num amount, {
  required String currencyCode,
  required String locale,
}) {
  final normalized = currencyCode.trim().toUpperCase();
  if (normalized.isEmpty || normalized == 'VND') {
    return NumberFormat.currency(
      locale: locale,
      symbol: '₫',
      decimalDigits: 0,
    ).format(amount);
  }
  return NumberFormat.simpleCurrency(locale: locale, name: normalized).format(amount);
}
