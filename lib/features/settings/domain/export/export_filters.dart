enum ExportDataType {
  transactions('Giao dịch'),
  wallets('Ví'),
  categories('Danh mục');

  const ExportDataType(this.label);

  final String label;
}

class ExportFilters {
  const ExportFilters({
    this.startDate,
    this.endDate,
    this.dataTypes = const {ExportDataType.transactions},
  });

  final DateTime? startDate;
  final DateTime? endDate;
  final Set<ExportDataType> dataTypes;

  bool get hasDateRange => startDate != null || endDate != null;
  bool get hasTransactions => dataTypes.contains(ExportDataType.transactions);
  bool get hasWallets => dataTypes.contains(ExportDataType.wallets);
  bool get hasCategories => dataTypes.contains(ExportDataType.categories);

  ExportFilters copyWith({
    DateTime? startDate,
    DateTime? endDate,
    Set<ExportDataType>? dataTypes,
    bool clearDateRange = false,
  }) {
    if (clearDateRange) {
      return ExportFilters(dataTypes: dataTypes ?? this.dataTypes);
    }
    return ExportFilters(
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      dataTypes: dataTypes ?? this.dataTypes,
    );
  }
}
