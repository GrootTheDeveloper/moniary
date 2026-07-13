import 'package:intl/intl.dart';

/// Display metadata for a supported currency.
///
/// [numberLocale] drives digit grouping (e.g. `1.234` vs `1,234`) and the
/// symbol placement convention used by [NumberFormat.currency].
class CurrencyInfo {
  const CurrencyInfo({
    required this.code,
    required this.symbol,
    required this.decimalDigits,
    required this.numberLocale,
  });

  final String code;
  final String symbol;
  final int decimalDigits;
  final String numberLocale;
}

const _fallbackLocale = 'en_US';

const Map<String, CurrencyInfo> _catalog = {
  'VND': CurrencyInfo(
    code: 'VND',
    symbol: '₫',
    decimalDigits: 0,
    numberLocale: 'vi_VN',
  ),
  // App-specific gold unit ("chỉ") offered in the profile survey.
  'VGO': CurrencyInfo(
    code: 'VGO',
    symbol: 'chỉ',
    decimalDigits: 2,
    numberLocale: 'vi_VN',
  ),
  'USD': CurrencyInfo(
    code: 'USD',
    symbol: r'$',
    decimalDigits: 2,
    numberLocale: 'en_US',
  ),
  'EUR': CurrencyInfo(
    code: 'EUR',
    symbol: '€',
    decimalDigits: 2,
    numberLocale: 'de_DE',
  ),
  'GBP': CurrencyInfo(
    code: 'GBP',
    symbol: '£',
    decimalDigits: 2,
    numberLocale: 'en_GB',
  ),
  'JPY': CurrencyInfo(
    code: 'JPY',
    symbol: '¥',
    decimalDigits: 0,
    numberLocale: 'ja_JP',
  ),
  'CNY': CurrencyInfo(
    code: 'CNY',
    symbol: '¥',
    decimalDigits: 2,
    numberLocale: 'zh_CN',
  ),
  'KRW': CurrencyInfo(
    code: 'KRW',
    symbol: '₩',
    decimalDigits: 0,
    numberLocale: 'ko_KR',
  ),
  'THB': CurrencyInfo(
    code: 'THB',
    symbol: '฿',
    decimalDigits: 2,
    numberLocale: 'th_TH',
  ),
  'SGD': CurrencyInfo(
    code: 'SGD',
    symbol: r'S$',
    decimalDigits: 2,
    numberLocale: 'en_SG',
  ),
  'AUD': CurrencyInfo(
    code: 'AUD',
    symbol: r'A$',
    decimalDigits: 2,
    numberLocale: 'en_AU',
  ),
  'INR': CurrencyInfo(
    code: 'INR',
    symbol: '₹',
    decimalDigits: 2,
    numberLocale: 'en_IN',
  ),
  'IDR': CurrencyInfo(
    code: 'IDR',
    symbol: 'Rp',
    decimalDigits: 0,
    numberLocale: 'id_ID',
  ),
  'MYR': CurrencyInfo(
    code: 'MYR',
    symbol: 'RM',
    decimalDigits: 2,
    numberLocale: 'ms_MY',
  ),
  'PHP': CurrencyInfo(
    code: 'PHP',
    symbol: '₱',
    decimalDigits: 2,
    numberLocale: 'en_PH',
  ),
};

/// The currencies offered in pickers, in display order (VND first).
List<CurrencyInfo> get supportedCurrencies => _catalog.values.toList();

/// Metadata for [code]; falls back to a 2-decimal currency that renders the
/// raw code as its symbol when the code is unknown.
CurrencyInfo currencyInfoFor(String code) {
  return _catalog[code.toUpperCase()] ??
      CurrencyInfo(
        code: code.toUpperCase(),
        symbol: code.toUpperCase(),
        decimalDigits: 2,
        numberLocale: _fallbackLocale,
      );
}

/// The user's active display currency. Synced from `preferredCurrencyProvider`
/// (and at startup from persisted preferences) so the context-free
/// [formatMoney] / [formatVnd] helpers reflect the chosen currency everywhere.
String _activeCurrencyCode = 'VND';

void setActiveCurrencyCode(String code) {
  final normalized = code.trim().toUpperCase();
  if (normalized.isNotEmpty) _activeCurrencyCode = normalized;
}

String activeCurrencyCode() => _activeCurrencyCode;

String activeCurrencySymbol() => currencyInfoFor(_activeCurrencyCode).symbol;

/// Formats [amount] in [currencyCode] (defaults to the active currency).
/// Set [includeSymbol] to false for a bare grouped number.
String formatMoney(
  num amount, {
  String? currencyCode,
  bool includeSymbol = true,
}) {
  final info = currencyInfoFor(currencyCode ?? _activeCurrencyCode);
  try {
    return NumberFormat.currency(
      locale: info.numberLocale,
      symbol: includeSymbol ? info.symbol : '',
      decimalDigits: info.decimalDigits,
    ).format(amount).trim();
  } catch (_) {
    // Fall back to a safe locale if number-formatting data is unavailable.
    final number = NumberFormat.currency(
      locale: _fallbackLocale,
      symbol: '',
      decimalDigits: info.decimalDigits,
    ).format(amount).trim();
    return includeSymbol ? '${info.symbol}$number' : number;
  }
}

/// Formats [amount] in the user's active display currency.
///
/// Historically VND-only; retained as the app-wide money formatter so every
/// call site honours the chosen currency without threading context.
String formatVnd(num amount) => formatMoney(amount);
