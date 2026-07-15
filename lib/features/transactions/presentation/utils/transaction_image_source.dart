import '../../domain/models/transaction_entry.dart';

String transactionImagePathForDisplay(TransactionEntry transaction) {
  final imagePath = transaction.imagePath?.trim();
  if (imagePath != null && imagePath.isNotEmpty) {
    return imagePath;
  }

  return '';
}
