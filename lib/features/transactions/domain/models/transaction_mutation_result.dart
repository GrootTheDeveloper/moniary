class TransactionMutationResult {
  const TransactionMutationResult({this.previousDate, this.currentDate});

  final DateTime? previousDate;
  final DateTime? currentDate;
}

/// Result of persisting the financial transaction and its optional image.
///
/// The financial record is the primary operation. An image failure must not
/// make callers retry the whole transaction and accidentally create a
/// duplicate financial entry.
class TransactionSaveResult {
  const TransactionSaveResult({
    required this.transactionId,
    this.imageUploadFailed = false,
  });

  final String transactionId;
  final bool imageUploadFailed;
}
