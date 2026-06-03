import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:moniary/core/constants/app_constants.dart';
import 'package:moniary/core/supabase/app_exception.dart';
import 'package:moniary/core/supabase/supabase_providers.dart';
import 'package:moniary/shared/utils/app_logger.dart';
import 'package:moniary/features/settings/data/repositories/import_repository.dart';
import 'package:moniary/features/transactions/data/repositories/transaction_repository.dart';
import 'package:moniary/features/categories/data/repositories/category_repository.dart';
import 'package:moniary/features/wallets/domain/models/wallet.dart';
import 'package:moniary/features/categories/domain/models/category.dart';
import 'dart:io';
import 'package:moniary/features/settings/domain/models/csv_transaction_row.dart';
import 'package:moniary/features/settings/domain/import/import_history_entry.dart';

final importHistoryProvider = FutureProvider<List<ImportHistoryEntry>>((ref) {
  return ref.watch(importRepositoryProvider).fetchImportHistory();
});

class ImportState {
  final bool isParsing;
  final bool isImporting;
  final List<CsvTransactionRow> parsedRows;
  final String? selectedFilePath;
  final String? error;

  ImportState({
    this.isParsing = false,
    this.isImporting = false,
    this.parsedRows = const [],
    this.selectedFilePath,
    this.error,
  });

  ImportState copyWith({
    bool? isParsing,
    bool? isImporting,
    List<CsvTransactionRow>? parsedRows,
    String? Function()? selectedFilePath,
    String? Function()? error,
  }) {
    return ImportState(
      isParsing: isParsing ?? this.isParsing,
      isImporting: isImporting ?? this.isImporting,
      parsedRows: parsedRows ?? this.parsedRows,
      selectedFilePath: selectedFilePath != null
          ? selectedFilePath()
          : this.selectedFilePath,
      error: error != null ? error() : this.error,
    );
  }
}

final importControllerProvider =
    NotifierProvider<ImportController, ImportState>(ImportController.new);

class ImportController extends Notifier<ImportState> {
  @override
  ImportState build() {
    return ImportState();
  }

  Future<void> pickAndParseFile(String filePath) async {
    state = state.copyWith(
      isParsing: true,
      selectedFilePath: () => filePath,
      error: () => null,
    );
    try {
      final repo = ref.read(importRepositoryProvider);
      final rows = await repo.parseCsv(filePath);
      final categories = await ref
          .read(categoryRepositoryProvider)
          .fetchCategories();
      final validatedRows = _validateCategories(rows, categories);
      state = state.copyWith(
        parsedRows: validatedRows,
        isParsing: false,
        selectedFilePath: () => filePath,
      );
    } on AppException catch (e, st) {
      AppLogger.error('Failed to parse file', e, st);
      state = state.copyWith(
        isParsing: false,
        parsedRows: [],
        error: () => e.code ?? 'IMPORT_PARSE_ERROR',
      );
    } catch (e, st) {
      AppLogger.error('Failed to parse file', e, st);
      state = state.copyWith(
        isParsing: false,
        parsedRows: [],
        error: () => 'IMPORT_PARSE_ERROR',
      );
    }
  }

  Future<int?> confirmImport(Wallet targetWallet) async {
    state = state.copyWith(isImporting: true, error: () => null);
    final importRepo = ref.read(importRepositoryProvider);
    ImportHistoryEntry? historyEntry;
    var importCount = 0;
    bool isTransactionSuccess = false;

    try {
      final session = ref.read(currentSessionProvider);
      final profileId = session?.user.id;
      if (AppConstants.hasSupabaseConfig && profileId == null) {
        throw const AppException('User not logged in', code: 'AUTH_REQUIRED');
      }

      final validRows = state.parsedRows.where((r) => r.isValid).toList();
      if (validRows.isEmpty) {
        state = state.copyWith(isImporting: false);
        return 0;
      }

      final fileName = _selectedFileName();
      historyEntry = await _createPendingImportHistory(
        importRepo: importRepo,
        fileName: fileName,
        walletName: targetWallet.name,
      );

      final categoryRepo = ref.read(categoryRepositoryProvider);
      final transactionRepo = ref.read(transactionRepositoryProvider);

      final categories = await categoryRepo.fetchCategories();

      for (var row in validRows) {
        final type = _transactionTypeFor(row.typeStr);
        if (type == null) {
          AppLogger.warning('Skipping row because type is invalid');
          continue;
        }

        final matchedCat = _findCategory(row.categoryName, type, categories);
        if (matchedCat == null) {
          AppLogger.warning(
            'Skipping row because category was not found: ${row.categoryName}',
          );
          continue;
        }

        await transactionRepo.createTransaction(
          amount: row.amount ?? 0.0,
          type: type,
          walletId: targetWallet.id,
          categoryId: matchedCat.id,
          transactionDate: row.date ?? DateTime.now(),
          note: row.note,
        );
        importCount++;
      }

      isTransactionSuccess = true;

      await _completeImportHistory(
        importRepo: importRepo,
        historyEntry: historyEntry,
        importedCount: importCount,
      );

      state = state.copyWith(isImporting: false, parsedRows: []);
      return importCount;
    } on AppException catch (e, st) {
      if (!isTransactionSuccess) {
        try {
          await _failImportHistory(
            importRepo: importRepo,
            historyEntry: historyEntry,
            importedCount: importCount,
            errorMessage: e.code ?? e.message,
          );
        } catch (historyErr) {
          AppLogger.error(
            'Failed to mark import history as failed during exception handling',
            historyErr,
          );
          state = state.copyWith(
            isImporting: false,
            error: () => 'IMPORT_FAILED_HISTORY_FAILED',
          );
          return null;
        }
      }
      AppLogger.error('Import failed', e, st);
      state = state.copyWith(
        isImporting: false,
        parsedRows: isTransactionSuccess ? [] : state.parsedRows,
        error: () => isTransactionSuccess
            ? (e.code ?? 'IMPORT_HISTORY_COMPLETE_ERROR')
            : (e.code ?? 'IMPORT_FAILED'),
      );
      return isTransactionSuccess ? importCount : null;
    } catch (e, st) {
      if (!isTransactionSuccess) {
        try {
          await _failImportHistory(
            importRepo: importRepo,
            historyEntry: historyEntry,
            importedCount: importCount,
            errorMessage: 'IMPORT_FAILED',
          );
        } catch (historyErr) {
          AppLogger.error(
            'Failed to mark import history as failed during exception handling',
            historyErr,
          );
          state = state.copyWith(
            isImporting: false,
            error: () => 'IMPORT_FAILED_HISTORY_FAILED',
          );
          return null;
        }
      }
      AppLogger.error('Import failed', e, st);
      state = state.copyWith(
        isImporting: false,
        parsedRows: isTransactionSuccess ? [] : state.parsedRows,
        error: () => isTransactionSuccess
            ? 'IMPORT_HISTORY_COMPLETE_ERROR'
            : 'IMPORT_FAILED',
      );
      return isTransactionSuccess ? importCount : null;
    }
  }

  String _selectedFileName() {
    return state.selectedFilePath?.split(Platform.pathSeparator).last ??
        'unknown.csv';
  }

  Future<ImportHistoryEntry> _createPendingImportHistory({
    required ImportRepository importRepo,
    required String fileName,
    required String walletName,
  }) async {
    try {
      final entry = await importRepo.createPendingImport(
        fileName: fileName,
        walletName: walletName,
      );
      ref.invalidate(importHistoryProvider);
      return entry;
    } catch (e, st) {
      AppLogger.error('Failed to create pending import history', e, st);
      if (e is AppException) rethrow;
      throw const AppException(
        'Failed to create pending import history',
        code: 'IMPORT_HISTORY_CREATE_ERROR',
      );
    }
  }

  Future<void> _completeImportHistory({
    required ImportRepository importRepo,
    required ImportHistoryEntry? historyEntry,
    required int importedCount,
  }) async {
    if (historyEntry == null) return;
    try {
      await importRepo.completeImport(
        id: historyEntry.id,
        importedCount: importedCount,
      );
      ref.invalidate(importHistoryProvider);
    } catch (e, st) {
      AppLogger.error('Failed to complete import history', e, st);
      if (e is AppException) rethrow;
      throw const AppException(
        'Failed to complete import history',
        code: 'IMPORT_HISTORY_COMPLETE_ERROR',
      );
    }
  }

  Future<void> _failImportHistory({
    required ImportRepository importRepo,
    required ImportHistoryEntry? historyEntry,
    required int importedCount,
    required String errorMessage,
  }) async {
    if (historyEntry == null) return;
    try {
      await importRepo.failImport(
        id: historyEntry.id,
        importedCount: importedCount,
        errorMessage: errorMessage,
      );
      ref.invalidate(importHistoryProvider);
    } catch (e, st) {
      AppLogger.error('Failed to mark import history as failed', e, st);
      if (e is AppException) rethrow;
      throw const AppException(
        'Failed to mark import history as failed',
        code: 'IMPORT_HISTORY_FAIL_ERROR',
      );
    }
  }

  List<CsvTransactionRow> _validateCategories(
    List<CsvTransactionRow> rows,
    List<Category> categories,
  ) {
    return rows.map((row) {
      if (!row.isValid) return row;

      final type = _transactionTypeFor(row.typeStr);
      if (type == null) {
        return row.copyWith(isValid: false, errorMessage: () => 'INVALID_TYPE');
      }

      final category = _findCategory(row.categoryName, type, categories);
      if (category == null) {
        return row.copyWith(
          isValid: false,
          errorMessage: () => 'CATEGORY_NOT_FOUND',
        );
      }

      return row;
    }).toList();
  }

  static TransactionType? _transactionTypeFor(String value) {
    switch (value.trim().toLowerCase()) {
      case 'income':
      case 'thu':
        return TransactionType.income;
      case 'expense':
      case 'chi':
        return TransactionType.expense;
    }
    return null;
  }

  static Category? _findCategory(
    String categoryName,
    TransactionType type,
    List<Category> categories,
  ) {
    final normalizedName = categoryName.trim().toLowerCase();
    for (final category in categories) {
      if (category.name.trim().toLowerCase() == normalizedName &&
          category.type == type) {
        return category;
      }
    }
    return null;
  }
}
