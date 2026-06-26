import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/month/calendar_filters.dart';

class CalendarFilterNotifier extends Notifier<CalendarFilters> {
  @override
  CalendarFilters build() {
    return const CalendarFilters();
  }

  void updateFilters(CalendarFilters filters) {
    state = filters;
  }

  void setWallet(String? walletId) {
    state = state.copyWith(walletId: walletId);
  }

  void setCategory(String? categoryId) {
    state = state.copyWith(categoryId: categoryId);
  }

  void clearWallet() {
    state = state.copyWith(clearWallet: true);
  }

  void clearCategory() {
    state = state.copyWith(clearCategory: true);
  }

  void toggleStarredOnly() {
    state = state.copyWith(isStarredOnly: !state.isStarredOnly);
  }

  void reset() {
    state = const CalendarFilters();
  }
}

final calendarFilterProvider =
    NotifierProvider<CalendarFilterNotifier, CalendarFilters>(
      CalendarFilterNotifier.new,
    );
