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
  if (normalized.isEmpty) return '₫';
  
  final info = _catalog[normalized];
  if (info != null) return info.symbol;

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
  if (normalized.isEmpty) {
    return NumberFormat.currency(
      locale: locale,
      symbol: '₫',
      decimalDigits: 0,
    ).format(amount);
  }

  final info = _catalog[normalized];
  if (info != null) {
    return NumberFormat.currency(
      locale: locale,
      symbol: info.symbol,
      decimalDigits: info.decimalDigits,
    ).format(amount);
  }

  return NumberFormat.simpleCurrency(
    locale: locale,
    name: normalized,
  ).format(amount);
}

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
