import 'package:flutter_riverpod/flutter_riverpod.dart';

class CalendarVisibleMonthNotifier extends Notifier<DateTime> {
  @override
  DateTime build() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, 1);
  }

  void setMonth(DateTime month) {
    state = DateTime(month.year, month.month, 1);
  }

  void changeMonth(int offset) {
    state = DateTime(state.year, state.month + offset, 1);
  }
}

final calendarVisibleMonthProvider =
    NotifierProvider<CalendarVisibleMonthNotifier, DateTime>(
      CalendarVisibleMonthNotifier.new,
    );
