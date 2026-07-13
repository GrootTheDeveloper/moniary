import '../../domain/models/transaction_entry.dart';

String transactionImagePathForDisplay(TransactionEntry transaction) {
  final imagePath = transaction.imagePath?.trim();
  if (imagePath != null && imagePath.isNotEmpty) {
    return imagePath;
  }

  return 'asset://${transactionFallbackAssetPath(transaction)}';
}

String transactionFallbackAssetPath(TransactionEntry transaction) {
  final imageName = switch (transaction.categoryId) {
    'mock-cat-food' =>
      transaction.note?.toLowerCase().contains('cafe') == true
          ? 'cafe'
          : 'market',
    'mock-cat-transport' => 'transport',
    'mock-cat-shopping' => 'shopping',
    'mock-cat-salary' => 'salary',
    _ when transaction.isIncome => 'salary',
    _ => 'market',
  };

  return 'assets/demo_transactions/$imageName.png';
}
