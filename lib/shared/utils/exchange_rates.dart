class ExchangeRateEntry {
  const ExchangeRateEntry({
    required this.date,
    required this.currencyCode,
    required this.rateToUsd,
  });

  /// Calendar date the rate applies to (no time component).
  final DateTime date;
  final String currencyCode;

  /// USD value of 1 unit of [currencyCode].
  final double rateToUsd;

  factory ExchangeRateEntry.fromMap(Map<String, dynamic> map) {
    return ExchangeRateEntry(
      date: DateTime.parse(map['rate_date'] as String),
      currencyCode: map['currency_code'] as String,
      rateToUsd: (map['rate_to_usd'] as num).toDouble(),
    );
  }
}

/// Historical exchange rates pivoted through USD, with nearest-date lookup
/// per currency. Conversion always goes through the rate for the *earlier*
/// of the two dates being compared — in practice callers pass the date the
/// money movement actually happened (e.g. a transaction's date), so a
/// wallet's balance always converts using the rate from when it changed
/// rather than today's rate drifting old totals.
class ExchangeRates {
  ExchangeRates(List<ExchangeRateEntry> entries)
    : _byCurrency = _groupByCurrency(entries);

  final Map<String, List<ExchangeRateEntry>> _byCurrency;

  static Map<String, List<ExchangeRateEntry>> _groupByCurrency(
    List<ExchangeRateEntry> entries,
  ) {
    final map = <String, List<ExchangeRateEntry>>{};
    for (final entry in entries) {
      map.putIfAbsent(entry.currencyCode, () => []).add(entry);
    }
    for (final entriesForCurrency in map.values) {
      entriesForCurrency.sort((a, b) => a.date.compareTo(b.date));
    }
    return map;
  }

  /// USD value of 1 unit of [currencyCode] on or before [date]; falls back to
  /// the earliest known rate if [date] predates our rate history, and to
  /// null only when no rate has ever been recorded for that currency.
  double? _rateToUsd(String currencyCode, DateTime date) {
    if (currencyCode == 'USD') return 1;
    final entries = _byCurrency[currencyCode];
    if (entries == null || entries.isEmpty) return null;

    ExchangeRateEntry? candidate;
    for (final entry in entries) {
      if (!entry.date.isAfter(date)) {
        candidate = entry;
      } else {
        break;
      }
    }
    return (candidate ?? entries.first).rateToUsd;
  }

  /// Converts [amount] from [from] to [to] using the rate for [date]. Returns
  /// null when a required rate isn't available yet (e.g. the daily fetch
  /// hasn't run for a currency) — callers should fall back to the
  /// unconverted amount rather than show a wrong or blank number.
  double? convert({
    required double amount,
    required String from,
    required String to,
    required DateTime date,
  }) {
    final fromCode = from.toUpperCase();
    final toCode = to.toUpperCase();
    if (fromCode == toCode) return amount;

    final fromRate = _rateToUsd(fromCode, date);
    final toRate = _rateToUsd(toCode, date);
    if (fromRate == null || toRate == null) return null;

    return amount * fromRate / toRate;
  }
}
