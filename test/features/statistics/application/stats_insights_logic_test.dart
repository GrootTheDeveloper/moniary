import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moniary/features/categories/domain/models/category.dart';
import 'package:moniary/features/statistics/application/stats_insights_logic.dart';
import 'package:moniary/features/transactions/domain/models/transaction_entry.dart';
import 'package:moniary/l10n/gen_l10n/app_localizations.dart';
import 'package:moniary/shared/utils/exchange_rates.dart';

TransactionEntry _entry({
  required double amount,
  required TransactionType type,
  required String walletCurrency,
  String categoryId = 'cat-1',
}) {
  return TransactionEntry(
    id: 'tx-${type.name}-$amount-$walletCurrency-$categoryId',
    amount: amount,
    type: type,
    note: null,
    imagePath: null,
    transactionDate: DateTime(2026, 7, 19),
    walletId: 'wallet-1',
    walletName: 'Wallet',
    walletColor: null,
    walletCurrency: walletCurrency,
    categoryId: categoryId,
    categoryName: categoryId,
    categoryColor: null,
  );
}

Future<List<StatsInsight>> _generate(
  WidgetTester tester,
  List<TransactionEntry> current,
  List<TransactionEntry> previous,
  String currency,
  ExchangeRates? rates,
) async {
  late List<StatsInsight> result;
  await tester.pumpWidget(
    MaterialApp(
      locale: const Locale('vi'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Builder(
        builder: (context) {
          result = StatsInsightsLogic.generateInsights(
            context,
            current,
            previous,
            currency,
            rates,
          );
          return const SizedBox.shrink();
        },
      ),
    ),
  );
  await tester.pumpAndSettle();
  return result;
}

void main() {
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

  testWidgets(
    'converts every wallet currency to the target currency before computing the savings rate',
    (tester) async {
      final insights = await _generate(
        tester,
        [
          _entry(
            amount: 100,
            type: TransactionType.income,
            walletCurrency: 'USD',
          ),
          // 50,000 VND == 2 USD, so real spending is small relative to income.
          _entry(
            amount: 50000,
            type: TransactionType.expense,
            walletCurrency: 'VND',
          ),
        ],
        const [],
        'USD',
        rates,
      );

      final savings = insights.where(
        (insight) => insight.type == InsightType.success,
      );
      expect(savings, isNotEmpty);
      expect(savings.first.message, contains('98'));
    },
  );

  testWidgets(
    'falls back to unconverted raw sums when rates are unavailable (null)',
    (tester) async {
      final insights = await _generate(
        tester,
        [
          _entry(
            amount: 100,
            type: TransactionType.income,
            walletCurrency: 'USD',
          ),
          // Without conversion this raw 50000 dwarfs the 100 raw income,
          // turning what is actually a healthy savings month negative.
          _entry(
            amount: 50000,
            type: TransactionType.expense,
            walletCurrency: 'VND',
          ),
        ],
        const [],
        'USD',
        null,
      );

      expect(
        insights.any((insight) => insight.type == InsightType.success),
        isFalse,
      );
    },
  );
}
