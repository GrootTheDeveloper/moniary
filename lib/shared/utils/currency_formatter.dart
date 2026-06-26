import 'package:intl/intl.dart';

String formatVnd(num amount) {
  return NumberFormat.currency(
    locale: 'vi_VN',
    symbol: '₫',
    decimalDigits: 0,
  ).format(amount);
}
