import 'package:flutter_test/flutter_test.dart';
import 'package:moniary/features/calendar/domain/month/calendar_month_data.dart';
import 'package:moniary/features/categories/domain/models/category.dart';
import 'package:moniary/features/transactions/domain/models/transaction_entry.dart';
import 'package:moniary/shared/utils/exchange_rates.dart';

TransactionEntry _transaction({
  required double amount,
  required TransactionType type,
  required String walletCurrency,
}) {
  return TransactionEntry(
    id: 'tx-${amount}_$walletCurrency',
    amount: amount,
    type: type,
    note: null,
    imagePath: null,
    transactionDate: DateTime(2026, 7, 19),
    walletId: 'wallet-1',
    walletName: 'Wallet',
    walletColor: null,
    walletCurrency: walletCurrency,
    categoryId: 'cat-1',
    categoryName: 'Category',
    categoryColor: null,
  );
}

void main() {
  group('TransactionEntry.amountIn', () {
    test(
      'returns the raw amount when the wallet already uses that currency',
      () {
        final entry = _transaction(
          amount: 50000,
          type: TransactionType.expense,
          walletCurrency: 'VND',
        );
        expect(entry.amountIn('VND', ExchangeRates(const [])), 50000);
      },
    );

    test('converts using the supplied rates', () {
      final entry = _transaction(
        amount: 250000,
        type: TransactionType.expense,
        walletCurrency: 'VND',
      );
      final rates = ExchangeRates([
        ExchangeRateEntry(
          date: DateTime(2026, 7, 19),
          currencyCode: 'VND',
          rateToUsd: 1 / 25000,
        ),
      ]);
      expect(entry.amountIn('USD', rates), closeTo(10, 1e-9));
    });

    test('falls back to the raw amount when the rate is missing', () {
      final entry = _transaction(
        amount: 100,
        type: TransactionType.expense,
        walletCurrency: 'JPY',
      );
      expect(entry.amountIn('USD', ExchangeRates(const [])), 100);
    });
  });

  group('CalendarMonthData totals', () {
    late CalendarMonthData month;

    setUp(() {
      month = CalendarMonthData(
        month: DateTime(2026, 7),
        weeks: const [],
        transactions: [
          _transaction(
            amount: 100000,
            type: TransactionType.income,
            walletCurrency: 'VND',
          ),
          _transaction(
            amount: 20,
            type: TransactionType.income,
            walletCurrency: 'USD',
          ),
          _transaction(
            amount: 50000,
            type: TransactionType.expense,
            walletCurrency: 'VND',
          ),
        ],
      );
    });

    test('sums raw amounts when rates are unavailable (null)', () {
      expect(month.totalIncome('VND', null), 100020);
      expect(month.totalExpense('VND', null), 50000);
    });

    test('converts every wallet currency into the target currency', () {
      final rates = ExchangeRates([
        ExchangeRateEntry(
          date: DateTime(2026, 7, 19),
          currencyCode: 'VND',
          rateToUsd: 1 / 25000,
        ),
        ExchangeRateEntry(
          date: DateTime(2026, 7, 19),
          currencyCode: 'USD',
          rateToUsd: 1,
        ),
      ]);
      // 100,000 VND == 4 USD, plus the 20 USD income already in USD.
      expect(month.totalIncome('USD', rates), closeTo(24, 1e-9));
    });
  });
}
