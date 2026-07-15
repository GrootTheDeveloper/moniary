enum OcrSuggestionSource { ocr, derived, classifier }

class OcrSuggestion<T> {
  const OcrSuggestion({
    required this.value,
    required this.confidence,
    required this.source,
  });

  final T value;
  final double confidence;
  final OcrSuggestionSource source;

  bool get needsReview => confidence < 0.75;
}

class OcrResult {
  const OcrResult({
    this.merchantSuggestion,
    this.totalSuggestion,
    this.dateSuggestion,
    this.noteSuggestion,
    this.categorySuggestion,
    this.paymentMethod,
    this.currency = 'VND',
    this.items = const [],
    this.confidence = 0,
    this.processingTime = Duration.zero,
    this.validationIssues = const [],
    this.fieldConfidence = const {},
  });

  final OcrSuggestion<String>? merchantSuggestion;
  final OcrSuggestion<int>? totalSuggestion;
  final OcrSuggestion<DateTime>? dateSuggestion;
  final OcrSuggestion<String>? noteSuggestion;
  final OcrSuggestion<String>? categorySuggestion;
  final String? paymentMethod;
  final String currency;
  final List<OcrLineItem> items;
  final double confidence;
  final Duration processingTime;
  final List<String> validationIssues;
  final Map<String, double> fieldConfidence;

  String? get merchantName => merchantSuggestion?.value;
  int? get totalAmount => totalSuggestion?.value;
  DateTime? get transactionDate => dateSuggestion?.value;
  String? get note => noteSuggestion?.value;
  String? get categoryKey => categorySuggestion?.value;
  bool get needsReview => validationIssues.isNotEmpty || confidence < 0.75;
}

class OcrLineItem {
  const OcrLineItem({
    required this.name,
    this.quantity,
    this.price,
    this.confidence = 0,
  });

  final String name;
  final double? quantity;
  final int? price;
  final double confidence;
}
