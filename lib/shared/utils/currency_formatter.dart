import 'package:intl/intl.dart';

String formatCurrency(
  num amount, {
  required String currencyCode,
  required String locale,
}) {
  final normalized = currencyCode.trim().toUpperCase();
  if (normalized.isEmpty || normalized == 'VND') {
    return formatVnd(amount, locale: locale);
  }
  return NumberFormat.simpleCurrency(locale: locale, name: normalized).format(amount);
}

String formatVnd(num amount, {String locale = 'vi_VN'}) {
  return NumberFormat.currency(
    locale: locale,
    symbol: '₫',
    decimalDigits: 0,
  ).format(amount);
}
