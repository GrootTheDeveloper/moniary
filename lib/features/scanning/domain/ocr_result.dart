class OcrResult {
  const OcrResult({
    this.merchantName,
    this.totalAmount,
    this.transactionDate,
    this.note,
    this.items = const [],
    this.confidence = 0,
  });

  final String? merchantName;
  final double? totalAmount;
  final DateTime? transactionDate;
  final String? note;
  final List<OcrLineItem> items;
  final double confidence;
}

class OcrLineItem {
  const OcrLineItem({required this.name, this.quantity, this.price});

  final String name;
  final double? quantity;
  final double? price;
}
