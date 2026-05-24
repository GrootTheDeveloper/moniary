import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/calendar_filters.dart';

final calendarFilterProvider = StateProvider<CalendarFilters>((ref) {
  return const CalendarFilters();
});
