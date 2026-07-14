import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../calendar/application/month/calendar_month_provider.dart';
import '../../../categories/domain/models/category.dart';
import '../../../wallets/application/wallets_controller.dart';
import '../../../../core/widgets/widget_update_service.dart';
import '../../data/repositories/transaction_repository.dart';
import '../queries/transaction_queries.dart';

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
    String? merchantName,
    String source = 'manual',
    Uint8List? imageBytes,
    bool isImportant = false,
  }) async {
    state = const AsyncLoading();

    final repo = ref.read(transactionRepositoryProvider);

    try {
      // 1. Create transaction record (pending status)
      final transactionId = await repo.createTransaction(
        amount: amount,
        type: type,
        walletId: walletId,
        categoryId: categoryId,
        transactionDate: transactionDate,
        note: note,
        merchantName: merchantName,
        source: source,
        isImportant: isImportant,
      );

      // 2. If no image, we are done (but status is pending, maybe we should update to uploaded if no image?
      // The constraint says image_path null and status pending/failed is ok.
      // Actually image_path is null and status pending is fine for "no image" or "uploading".)
      if (imageBytes == null) {
        // Update to 'uploaded' even if no image? Or just leave it?
        // PRD says: image_path is null and status pending/failed is allowed.
        _triggerUpdates();
        state = const AsyncData(null);
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
      _triggerUpdates();
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
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
    bool isImportant = false,
  }) async {
    state = const AsyncLoading();
    final repo = ref.read(transactionRepositoryProvider);

    try {
      await repo.updateTransaction(
        transactionId: transactionId,
        amount: amount,
        type: type,
        walletId: walletId,
        categoryId: categoryId,
        transactionDate: transactionDate,
        note: note,
        isImportant: isImportant,
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
      _triggerUpdates();
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }

  Future<void> toggleImportance(
    String transactionId,
    bool value,
    DateTime transactionDate,
  ) async {
    state = const AsyncLoading();
    try {
      await ref
          .read(transactionRepositoryProvider)
          .toggleTransactionImportance(transactionId, value);
      final dayStart = DateTime(
        transactionDate.year,
        transactionDate.month,
        transactionDate.day,
      );
      final monthStart = DateTime(
        transactionDate.year,
        transactionDate.month,
        1,
      );
      ref.invalidate(transactionByIdProvider(transactionId));
      ref.invalidate(transactionsForDayProvider(dayStart));
      ref.invalidate(calendarMonthProvider(monthStart));
      _triggerUpdates();
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }

  Future<void> deleteTransaction(String transactionId) async {
    state = const AsyncLoading();
    try {
      await ref
          .read(transactionRepositoryProvider)
          .deleteTransaction(transactionId);
      _triggerUpdates();
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }

  void _triggerUpdates() {
    ref.invalidate(walletsControllerProvider);
    ref.read(widgetUpdateServiceProvider).updateWidget().ignore();
  }
}
