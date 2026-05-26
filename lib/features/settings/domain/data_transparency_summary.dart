class DataTransparencySummary {
  const DataTransparencySummary({
    required this.transactionCount,
    required this.walletCount,
    required this.categoryCount,
    required this.photoTransactionCount,
    required this.exportFileCount,
    required this.oldestTransactionDate,
    required this.newestTransactionDate,
    required this.latestExportDate,
  });

  final int transactionCount;
  final int walletCount;
  final int categoryCount;
  final int photoTransactionCount;
  final int exportFileCount;
  final DateTime? oldestTransactionDate;
  final DateTime? newestTransactionDate;
  final DateTime? latestExportDate;

  int get transactionWithoutPhotoCount =>
      transactionCount - photoTransactionCount;
}
