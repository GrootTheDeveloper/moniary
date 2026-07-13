import 'package:flutter_test/flutter_test.dart';
import 'package:moniary/features/categories/domain/models/category.dart';
import 'package:moniary/features/transactions/domain/models/transaction_entry.dart';
import 'package:moniary/features/transactions/presentation/utils/transaction_image_source.dart';

void main() {
  group('transactionImagePathForDisplay', () {
    test('keeps a real transaction image path when available', () {
      final transaction = _transaction(imagePath: '/tmp/receipt.jpg');

      expect(transactionImagePathForDisplay(transaction), '/tmp/receipt.jpg');
    });

    test('uses a transaction-like demo image when no image is available', () {
      final transaction = _transaction(categoryId: 'mock-cat-shopping');

      expect(
        transactionImagePathForDisplay(transaction),
        'asset://assets/demo_transactions/shopping.png',
      );
    });

    test('uses salary image for income fallback thumbnails', () {
      final transaction = _transaction(
        type: TransactionType.income,
        categoryId: 'custom-income',
      );

      expect(
        transactionFallbackAssetPath(transaction),
        'assets/demo_transactions/salary.png',
      );
    });
  });
}

TransactionEntry _transaction({
  String? imagePath,
  String categoryId = 'mock-cat-food',
  TransactionType type = TransactionType.expense,
}) {
  return TransactionEntry(
    id: 'tx-1',
    amount: 42000,
    type: type,
    note: 'Coffee',
    imagePath: imagePath,
    transactionDate: DateTime(2026, 7, 13),
    walletId: 'wallet-1',
    walletName: 'Cash',
    walletColor: null,
    categoryId: categoryId,
    categoryName: 'Food',
    categoryColor: null,
  );
}
