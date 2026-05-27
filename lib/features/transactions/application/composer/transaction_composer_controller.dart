import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../categories/domain/models/category.dart';
import '../../data/repositories/transaction_repository.dart';

final transactionComposerProvider =
    AsyncNotifierProvider<TransactionComposerController, void>(
      TransactionComposerController.new,
    );

class TransactionComposerController extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<void> createTransaction({
    required double amount,
    required TransactionType type,
    required String walletId,
    required String categoryId,
    required DateTime transactionDate,
    String? note,
    Uint8List? imageBytes,
  }) async {
    state = const AsyncLoading();

    final repo = ref.read(transactionRepositoryProvider);

    state = await AsyncValue.guard(() async {
      // 1. Create transaction record (pending status)
      final transactionId = await repo.createTransaction(
        amount: amount,
        type: type,
        walletId: walletId,
        categoryId: categoryId,
        transactionDate: transactionDate,
        note: note,
      );

      // 2. If no image, we are done (but status is pending, maybe we should update to uploaded if no image?
      // The constraint says image_path null and status pending/failed is ok.
      // Actually image_path is null and status pending is fine for "no image" or "uploading".)
      if (imageBytes == null) {
        // Update to 'uploaded' even if no image? Or just leave it?
        // PRD says: image_path is null and status pending/failed is allowed.
        return;
      }

      // 3. Upload image
      try {
        final imagePath = await repo.uploadTransactionImage(
          transactionId,
          imageBytes,
        );

        // 4. Update metadata
        await repo.updateTransactionImageMetadata(
          transactionId: transactionId,
          imagePath: imagePath,
          status: 'uploaded',
        );
      } catch (e) {
        // 5. If failed, update status to failed
        await repo.updateTransactionImageMetadata(
          transactionId: transactionId,
          imagePath: null,
          status: 'failed',
        );
        rethrow;
      }
    });
  }

  Future<void> updateTransaction({
    required String transactionId,
    required double amount,
    required TransactionType type,
    required String walletId,
    required String categoryId,
    required DateTime transactionDate,
    String? note,
    Uint8List? imageBytes,
  }) async {
    state = const AsyncLoading();
    final repo = ref.read(transactionRepositoryProvider);

    state = await AsyncValue.guard(() async {
      await repo.updateTransaction(
        transactionId: transactionId,
        amount: amount,
        type: type,
        walletId: walletId,
        categoryId: categoryId,
        transactionDate: transactionDate,
        note: note,
      );

      if (imageBytes != null) {
        try {
          final imagePath = await repo.uploadTransactionImage(
            transactionId,
            imageBytes,
          );
          await repo.updateTransactionImageMetadata(
            transactionId: transactionId,
            imagePath: imagePath,
            status: 'uploaded',
          );
        } catch (e) {
          await repo.updateTransactionImageMetadata(
            transactionId: transactionId,
            imagePath: null,
            status: 'failed',
          );
          rethrow;
        }
      }
    });
  }

  Future<void> deleteTransaction(String transactionId) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref
          .read(transactionRepositoryProvider)
          .deleteTransaction(transactionId),
    );
  }
}
