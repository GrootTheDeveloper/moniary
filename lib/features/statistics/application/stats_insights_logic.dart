import 'package:flutter/material.dart';
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

    // 1. Savings Rate Insight
    final currentIncome = currentMonth
        .where((t) => t.isIncome)
        .fold<double>(0, (sum, t) => sum + t.amount);
    final currentExpense = currentMonth
        .where((t) => t.isExpense)
        .fold<double>(0, (sum, t) => sum + t.amount);

    if (currentIncome > 0) {
      final savingsRate = ((currentIncome - currentExpense) / currentIncome) * 100;
      if (savingsRate > 0) {
        insights.add(StatsInsight(
          message: 'Bạn đã tiết kiệm được ${savingsRate.toStringAsFixed(0)}% thu nhập trong tháng này.',
          type: InsightType.success,
          icon: Icons.savings_outlined,
        ));
      }
    }

    // 2. Weekend vs Weekday Spending
    final weekendExpense = currentMonth
        .where((t) => t.isExpense && (t.transactionDate.weekday == DateTime.saturday || t.transactionDate.weekday == DateTime.sunday))
        .fold<double>(0, (sum, t) => sum + t.amount);

    if (currentExpense > 0) {
      final weekendPercent = (weekendExpense / currentExpense) * 100;
      if (weekendPercent > 50) {
        insights.add(StatsInsight(
          message: 'Bạn chi tiêu ${weekendPercent.toStringAsFixed(0)}% ngân sách vào cuối tuần. Hãy cẩn thận!',
          type: InsightType.warning,
          icon: Icons.event_busy_outlined,
        ));
      }
    }

    // 3. Category Surge (e.g. Food)
    final foodCategoryId = _findCategoryIdByName(currentMonth, 'Ăn uống');
    if (foodCategoryId != null) {
      final currentFood = currentMonth
          .where((t) => t.categoryId == foodCategoryId)
          .fold<double>(0, (sum, t) => sum + t.amount);
      final prevFood = previousMonth
          .where((t) => t.categoryId == foodCategoryId)
          .fold<double>(0, (sum, t) => sum + t.amount);

      if (prevFood > 0) {
        final surge = ((currentFood - prevFood) / prevFood) * 100;
        if (surge > 20) {
          insights.add(StatsInsight(
            message: 'Chi tiêu Ăn uống tăng ${surge.toStringAsFixed(0)}% so với tháng trước.',
            type: InsightType.warning,
            icon: Icons.restaurant_menu_outlined,
          ));
        }
      }
    }

    // Default insight if empty
    if (insights.isEmpty && currentMonth.isNotEmpty) {
      insights.add(StatsInsight(
        message: 'Bạn đang quản lý chi tiêu rất tốt! Hãy tiếp tục duy trì nhé.',
        type: InsightType.info,
        icon: Icons.thumb_up_off_alt_outlined,
      ));
    }

    return insights;
  }

  static String? _findCategoryIdByName(List<TransactionEntry> txs, String name) {
    try {
      return txs.firstWhere((t) => t.categoryName == name).categoryId;
    } catch (_) {
      return null;
    }
  }
}
