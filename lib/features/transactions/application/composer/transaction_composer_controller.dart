import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../calendar/application/month/calendar_month_provider.dart';
import '../../../categories/domain/models/category.dart';
import '../../../wallets/application/wallets_controller.dart';
import '../../../../core/widgets/widget_update_service.dart';
import '../../../../shared/utils/app_logger.dart';
import '../../data/repositories/transaction_repository.dart';
import '../../domain/models/transaction_mutation_result.dart';
import '../queries/transaction_queries.dart';

final transactionComposerProvider =
    AsyncNotifierProvider<TransactionComposerController, void>(
      TransactionComposerController.new,
    );

class TransactionComposerController extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<TransactionSaveResult> createTransaction({
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
        imageUploadStatus: imageBytes == null ? 'none' : 'pending',
      );

      final imageUploadFailed =
          imageBytes != null &&
          !await _attachNewImage(
            repo: repo,
            transactionId: transactionId,
            imageBytes: imageBytes,
          );
      _triggerUpdates();
      state = const AsyncData(null);
      return TransactionSaveResult(
        transactionId: transactionId,
        imageUploadFailed: imageUploadFailed,
      );
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }

  Future<TransactionSaveResult> updateTransaction({
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
      final previousImagePath = imageBytes == null
          ? null
          : (await repo.fetchTransactionById(transactionId)).imagePath;
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

      final imageUploadFailed =
          imageBytes != null &&
          !await _replaceImage(
            repo: repo,
            transactionId: transactionId,
            imageBytes: imageBytes,
            previousImagePath: previousImagePath,
          );
      _triggerUpdates();
      state = const AsyncData(null);
      return TransactionSaveResult(
        transactionId: transactionId,
        imageUploadFailed: imageUploadFailed,
      );
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }

  Future<bool> _attachNewImage({
    required TransactionRepository repo,
    required String transactionId,
    required Uint8List imageBytes,
  }) async {
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
      return true;
    } catch (error, stackTrace) {
      AppLogger.error(
        'Transaction saved but image attachment failed',
        error,
        stackTrace,
      );
      await _cleanupFailedNewImage(repo, transactionId);
      return false;
    }
  }

  Future<bool> _replaceImage({
    required TransactionRepository repo,
    required String transactionId,
    required Uint8List imageBytes,
    required String? previousImagePath,
  }) async {
    String? uploadedImagePath;
    try {
      final imagePath = await repo.uploadTransactionImage(
        transactionId,
        imageBytes,
      );
      uploadedImagePath = imagePath;
      try {
        await repo.updateTransactionImageMetadata(
          transactionId: transactionId,
          imagePath: imagePath,
          status: 'uploaded',
        );
      } catch (error, stackTrace) {
        // Existing images use the same deterministic path. The new bytes are
        // already referenced by the old metadata, so do not delete them.
        if (previousImagePath == imagePath) {
          AppLogger.warning(
            'Image bytes replaced; metadata refresh will retry on next edit',
          );
          return true;
        }
        Error.throwWithStackTrace(error, stackTrace);
      }
      return true;
    } catch (error, stackTrace) {
      AppLogger.error(
        'Transaction updated but replacement image failed',
        error,
        stackTrace,
      );
      if (previousImagePath == null) {
        await _cleanupFailedNewImage(repo, transactionId);
      } else if (uploadedImagePath != null &&
          previousImagePath != uploadedImagePath) {
        // A legacy attachment may use a different path. If uploading the new
        // deterministic object succeeded but its metadata update failed, keep
        // the referenced legacy image and remove the otherwise orphaned object.
        try {
          await repo.removeTransactionImage(transactionId);
        } catch (cleanupError, cleanupStackTrace) {
          AppLogger.error(
            'Failed to clean up unreferenced replacement image',
            cleanupError,
            cleanupStackTrace,
          );
        }
      }
      return false;
    }
  }

  Future<void> _cleanupFailedNewImage(
    TransactionRepository repo,
    String transactionId,
  ) async {
    try {
      await repo.removeTransactionImage(transactionId);
    } catch (error, stackTrace) {
      AppLogger.error(
        'Failed to clean up unattached transaction image',
        error,
        stackTrace,
      );
    }
    try {
      await repo.updateTransactionImageMetadata(
        transactionId: transactionId,
        imagePath: null,
        status: 'failed',
      );
    } catch (error, stackTrace) {
      AppLogger.error(
        'Failed to mark transaction image attachment as failed',
        error,
        stackTrace,
      );
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
    // Refresh every list that shows transactions so a create/update/delete is
    // reflected immediately, not only on the screen that triggered it.
    ref.invalidate(calendarMonthProvider);
    ref.invalidate(transactionsForDayProvider);
    ref.invalidate(transactionSearchProvider);
    ref.read(widgetUpdateServiceProvider).updateWidget().ignore();
  }
}
