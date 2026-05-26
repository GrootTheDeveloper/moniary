const privacyRequestResponseBusinessDays = 7;

DateTime privacyRequestDueDate(DateTime createdAt) {
  var current = DateTime(createdAt.year, createdAt.month, createdAt.day);
  var addedDays = 0;

  while (addedDays < privacyRequestResponseBusinessDays) {
    current = current.add(const Duration(days: 1));
    final isWeekend =
        current.weekday == DateTime.saturday ||
        current.weekday == DateTime.sunday;
    if (!isWeekend) {
      addedDays++;
    }
  }

  return current;
}
