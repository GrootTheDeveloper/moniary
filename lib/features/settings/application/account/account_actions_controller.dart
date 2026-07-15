import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/account/account_repository.dart';
import '../../domain/export/export_file_text.dart';
import '../../domain/transparency/data_transparency_summary.dart';
import '../../domain/export/export_filters.dart';
import '../../domain/export/export_history_entry.dart';
import '../../domain/privacy_requests/privacy_request_history_entry.dart';
import '../../domain/account/deletion_feedback.dart';

final exportHistoryProvider = FutureProvider<List<ExportHistoryEntry>>((ref) {
  return ref.watch(accountRepositoryProvider).fetchExportHistory();
});

final privacyRequestHistoryProvider =
    FutureProvider<List<PrivacyRequestHistoryEntry>>((ref) {
      return ref.watch(accountRepositoryProvider).fetchPrivacyRequestHistory();
    });

final dataTransparencySummaryProvider = FutureProvider<DataTransparencySummary>(
  (ref) {
    return ref.watch(accountRepositoryProvider).fetchDataTransparencySummary();
  },
);

final accountActionsControllerProvider =
    AsyncNotifierProvider<AccountActionsController, void>(
      AccountActionsController.new,
    );

class AccountActionsController extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<File?> exportCsv({
    ExportFilters filters = const ExportFilters(),
  }) async {
    state = const AsyncLoading();
    File? exportedFile;
    state = await AsyncValue.guard(() async {
      exportedFile = await ref
          .read(accountRepositoryProvider)
          .exportTransactionsCsv(filters: filters);
    });
    ref.invalidate(exportHistoryProvider);
    return exportedFile;
  }

  Future<File?> exportXlsx({
    ExportFilters filters = const ExportFilters(),
    required ExportFileText text,
  }) async {
    state = const AsyncLoading();
    File? exportedFile;
    state = await AsyncValue.guard(() async {
      exportedFile = await ref
          .read(accountRepositoryProvider)
          .exportTransactionsXlsx(filters: filters, text: text);
    });
    ref.invalidate(exportHistoryProvider);
    return exportedFile;
  }

  Future<File?> exportPdf({
    ExportFilters filters = const ExportFilters(),
    required ExportFileText text,
  }) async {
    state = const AsyncLoading();
    File? exportedFile;
    state = await AsyncValue.guard(() async {
      exportedFile = await ref
          .read(accountRepositoryProvider)
          .exportTransactionsPdf(filters: filters, text: text);
    });
    ref.invalidate(exportHistoryProvider);
    return exportedFile;
  }

  Future<DateTime?> requestSoftDelete({
    required AccountDeletionReason reason,
    String? details,
    required DeletionFeedbackContext feedbackContext,
  }) async {
    state = const AsyncLoading();
    DateTime? deletedAt;
    state = await AsyncValue.guard(() async {
      deletedAt = await ref
          .read(accountRepositoryProvider)
          .requestSoftDelete(
            reason: reason,
            details: details,
            feedbackContext: feedbackContext,
          );
    });
    return deletedAt;
  }

  Future<void> restoreAccount() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(accountRepositoryProvider).restoreAccount(),
    );
  }

  Future<void> createDeletionRequest({required String reason}) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref
          .read(accountRepositoryProvider)
          .createDeletionRequest(reason: reason);
    });
    ref.invalidate(privacyRequestHistoryProvider);
  }

  Future<void> createPrivacyRequest({
    required String requestType,
    required String message,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref
          .read(accountRepositoryProvider)
          .createPrivacyRequest(requestType: requestType, message: message);
    });
    ref.invalidate(privacyRequestHistoryProvider);
  }

  Future<void> updatePrivacyRequestStatus({
    required String id,
    required String status,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref
          .read(accountRepositoryProvider)
          .updatePrivacyRequestStatus(id: id, status: status),
    );
    ref.invalidate(privacyRequestHistoryProvider);
  }
}
