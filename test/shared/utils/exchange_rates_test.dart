import 'package:flutter_test/flutter_test.dart';
import 'package:moniary/shared/utils/exchange_rates.dart';

void main() {
  ExchangeRateEntry entry(String date, String code, double rateToUsd) {
    return ExchangeRateEntry(
      date: DateTime.parse(date),
      currencyCode: code,
      rateToUsd: rateToUsd,
    );
  }

  test('same currency returns the amount unchanged without needing a rate', () {
    final rates = ExchangeRates(const []);
    expect(
      rates.convert(
        amount: 100,
        from: 'VND',
        to: 'VND',
        date: DateTime(2026, 7, 19),
      ),
      100,
    );
  });

  test('converts using the USD pivot for two known currencies', () {
    final rates = ExchangeRates([
      entry('2026-07-19', 'VND', 1 / 25000),
      entry('2026-07-19', 'USD', 1),
    ]);
    // 250,000 VND == 10 USD at 25,000 VND/USD.
    final result = rates.convert(
      amount: 250000,
      from: 'VND',
      to: 'USD',
      date: DateTime(2026, 7, 19),
    );
    expect(result, closeTo(10, 1e-9));
  });

  test('converts between two non-USD currencies through the pivot', () {
    final rates = ExchangeRates([
      entry('2026-07-19', 'VND', 1 / 25000),
      entry('2026-07-19', 'EUR', 1 / 0.92),
    ]);
    final result = rates.convert(
      amount: 25000,
      from: 'VND',
      to: 'EUR',
      date: DateTime(2026, 7, 19),
    );
    expect(result, closeTo(0.92, 1e-9));
  });

  test('picks the nearest rate on or before the requested date', () {
    final rates = ExchangeRates([
      entry('2026-07-01', 'VND', 1 / 24000),
      entry('2026-07-15', 'VND', 1 / 25000),
      entry('2026-07-20', 'VND', 1 / 26000),
    ]);
    final result = rates.convert(
      amount: 25000,
      from: 'VND',
      to: 'USD',
      date: DateTime(2026, 7, 18),
    );
    expect(result, closeTo(1, 1e-9));
  });

  test(
    'falls back to the earliest known rate for dates before any history',
    () {
      final rates = ExchangeRates([entry('2026-07-15', 'VND', 1 / 25000)]);
      final result = rates.convert(
        amount: 25000,
        from: 'VND',
        to: 'USD',
        date: DateTime(2020, 1, 1),
      );
      expect(result, closeTo(1, 1e-9));
    },
  );

  test('returns null when a currency has no recorded rate at all', () {
    final rates = ExchangeRates([entry('2026-07-19', 'VND', 1 / 25000)]);
    final result = rates.convert(
      amount: 100,
      from: 'VND',
      to: 'JPY',
      date: DateTime(2026, 7, 19),
    );
    expect(result, isNull);
  });

  test('currency codes are matched case-insensitively', () {
    final rates = ExchangeRates([entry('2026-07-19', 'VND', 1 / 25000)]);
    final result = rates.convert(
      amount: 25000,
      from: 'vnd',
      to: 'USD',
      date: DateTime(2026, 7, 19),
    );
    expect(result, closeTo(1, 1e-9));
  });
}
