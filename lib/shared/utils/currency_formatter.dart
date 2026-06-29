import 'package:intl/intl.dart';

String formatVnd(num amount, {String locale = 'vi_VN'}) {
  return NumberFormat.currency(
    locale: locale,
    symbol: '₫',
    decimalDigits: 0,
  ).format(amount);
}
