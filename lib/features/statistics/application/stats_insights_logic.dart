import 'package:flutter/material.dart';
import '../../../l10n/l10n_extension.dart';
import '../../transactions/domain/models/transaction_entry.dart';

enum InsightType { info, warning, success }

class StatsInsight {
  const StatsInsight({
    required this.message,
    required this.type,
    required this.icon,
  });

  final String message;
  final InsightType type;
  final IconData icon;
}

class StatsInsightsLogic {
  static List<StatsInsight> generateInsights(
    BuildContext context,
    List<TransactionEntry> currentMonth,
    List<TransactionEntry> previousMonth,
  ) {
    final insights = <StatsInsight>[];

    final currentIncome = currentMonth
        .where((t) => t.isIncome)
        .fold<double>(0, (sum, t) => sum + t.amount);
    final currentExpense = currentMonth
        .where((t) => t.isExpense)
        .fold<double>(0, (sum, t) => sum + t.amount);

    if (currentIncome > 0) {
      final savingsRate =
          ((currentIncome - currentExpense) / currentIncome) * 100;
      if (savingsRate > 0) {
        insights.add(
          StatsInsight(
            message: context.l10n.statsInsightSavings(
              savingsRate.toStringAsFixed(0),
            ),
            type: InsightType.success,
            icon: Icons.savings_outlined,
          ),
        );
      }
    }

    final weekendExpense = currentMonth
        .where(
          (t) =>
              t.isExpense &&
              (t.transactionDate.weekday == DateTime.saturday ||
                  t.transactionDate.weekday == DateTime.sunday),
        )
        .fold<double>(0, (sum, t) => sum + t.amount);

    if (currentExpense > 0) {
      final weekendPercent = (weekendExpense / currentExpense) * 100;
      if (weekendPercent > 50) {
        insights.add(
          StatsInsight(
            message: context.l10n.statsInsightWeekend(
              weekendPercent.toStringAsFixed(0),
            ),
            type: InsightType.warning,
            icon: Icons.event_busy_outlined,
          ),
        );
      }
    }

    final categorySurge = _findLargestCategorySurge(
      currentMonth,
      previousMonth,
    );
    if (categorySurge != null && categorySurge.percent > 20) {
      insights.add(
        StatsInsight(
          message: context.l10n.statsInsightCategorySurge(
            categorySurge.name,
            categorySurge.percent.toStringAsFixed(0),
          ),
          type: InsightType.warning,
          icon: Icons.trending_up_outlined,
        ),
      );
    }

    if (insights.isEmpty && currentMonth.isNotEmpty) {
      insights.add(
        StatsInsight(
          message: context.l10n.statsInsightPositive,
          type: InsightType.info,
          icon: Icons.thumb_up_off_alt_outlined,
        ),
      );
    }

    return insights;
  }

  static _CategorySurge? _findLargestCategorySurge(
    List<TransactionEntry> current,
    List<TransactionEntry> prev,
  ) {
    final currentSums = _sumByCategory(current.where((t) => t.isExpense));
    final prevSums = _sumByCategory(prev.where((t) => t.isExpense));

    _CategorySurge? largest;

    currentSums.forEach((categoryId, currentAmount) {
      final prevAmount = prevSums[categoryId] ?? 0;
      if (prevAmount > 0) {
        final percent = ((currentAmount - prevAmount) / prevAmount) * 100;
        if (largest == null || percent > largest!.percent) {
          final name = current
              .firstWhere((t) => t.categoryId == categoryId)
              .categoryName;
          largest = _CategorySurge(name: name, percent: percent);
        }
      }
    });

    return largest;
  }

  static Map<String, double> _sumByCategory(Iterable<TransactionEntry> txs) {
    final sums = <String, double>{};
    for (final tx in txs) {
      sums[tx.categoryId] = (sums[tx.categoryId] ?? 0) + tx.amount;
    }
    return sums;
  }
}

class _CategorySurge {
  _CategorySurge({required this.name, required this.percent});
  final String name;
  final double percent;
}
