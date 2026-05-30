class CsvTransactionRow {
  final DateTime? date;
  final double? amount;
  final String typeStr;
  final String categoryName;
  final String note;
  final bool isValid;
  final String? errorMessage;

  const CsvTransactionRow({
    this.date,
    this.amount,
    required this.typeStr,
    required this.categoryName,
    required this.note,
    required this.isValid,
    this.errorMessage,
  });
}
