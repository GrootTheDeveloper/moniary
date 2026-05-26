class ExportFilters {
  const ExportFilters({this.startDate, this.endDate});

  final DateTime? startDate;
  final DateTime? endDate;

  bool get hasDateRange => startDate != null || endDate != null;

  ExportFilters copyWith({
    DateTime? startDate,
    DateTime? endDate,
    bool clearDateRange = false,
  }) {
    if (clearDateRange) {
      return const ExportFilters();
    }
    return ExportFilters(
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
    );
  }
}
