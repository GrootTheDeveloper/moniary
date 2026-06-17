import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../transactions/data/repositories/transaction_repository.dart';
import '../../../transactions/domain/models/transaction_entry.dart';
import '../../domain/month/calendar_month_data.dart';

import 'calendar_filter_provider.dart';

final calendarMonthProvider =
    FutureProvider.family<CalendarMonthData, DateTime>((ref, month) async {
      final filters = ref.watch(calendarFilterProvider);
      final normalizedMonth = DateTime(month.year, month.month, 1);
      var transactions = await ref
          .watch(transactionRepositoryProvider)
          .fetchTransactionsForMonth(
            normalizedMonth,
            walletId: filters.walletId,
            categoryId: filters.categoryId,
          );

      if (filters.isStarredOnly) {
        transactions = transactions.where((tx) => tx.isImportant).toList();
      }

      return _CalendarMonthBuilder.build(
        month: normalizedMonth,
        transactions: transactions,
      );
    });

class _CalendarMonthBuilder {
  static CalendarMonthData build({
    required DateTime month,
    required List<TransactionEntry> transactions,
  }) {
    final firstDay = DateTime(month.year, month.month, 1);
    final calendarStart = firstDay.subtract(
      Duration(days: firstDay.weekday - 1),
    );
    final grouped = <String, List<TransactionEntry>>{};

    for (final transaction in transactions) {
      final key = _dateKey(transaction.transactionDate);
      grouped.putIfAbsent(key, () => []).add(transaction);
    }

    final weeks = <List<CalendarDayData>>[];

    for (var weekIndex = 0; weekIndex < 6; weekIndex++) {
      final week = <CalendarDayData>[];
      for (var dayIndex = 0; dayIndex < 7; dayIndex++) {
        final date = calendarStart.add(
          Duration(days: (weekIndex * 7) + dayIndex),
        );
        final key = _dateKey(date);
        week.add(
          CalendarDayData(
            date: date,
            isCurrentMonth: date.month == month.month,
            transactions: grouped[key] ?? const [],
          ),
        );
      }
      weeks.add(week);
    }

    return CalendarMonthData(
      month: month,
      weeks: weeks,
      transactions: transactions,
    );
  }

  static String _dateKey(DateTime date) {
    final normalized = DateTime(date.year, date.month, date.day);
    return normalized.toIso8601String();
  }
}
