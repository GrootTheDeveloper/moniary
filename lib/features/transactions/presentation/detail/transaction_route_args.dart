import '../../domain/models/transaction_entry.dart';

class TransactionDetailRouteArgs {
  const TransactionDetailRouteArgs({
    required this.transaction,
    required this.day,
  });

  final TransactionEntry transaction;
  final DateTime day;
}
