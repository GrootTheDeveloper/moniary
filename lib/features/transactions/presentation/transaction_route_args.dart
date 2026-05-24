class TransactionDetailRouteArgs {
  const TransactionDetailRouteArgs({
    required this.transactionId,
    required this.day,
  });

  final String transactionId;
  final DateTime day;
}
