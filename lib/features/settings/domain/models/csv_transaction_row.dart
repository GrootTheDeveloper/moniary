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

  CsvTransactionRow copyWith({
    DateTime? date,
    double? amount,
    String? typeStr,
    String? categoryName,
    String? note,
    bool? isValid,
    String? Function()? errorMessage,
  }) {
    return CsvTransactionRow(
      date: date ?? this.date,
      amount: amount ?? this.amount,
      typeStr: typeStr ?? this.typeStr,
      categoryName: categoryName ?? this.categoryName,
      note: note ?? this.note,
      isValid: isValid ?? this.isValid,
      errorMessage: errorMessage != null ? errorMessage() : this.errorMessage,
    );
  }
}
