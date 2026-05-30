import 'package:flutter_riverpod/flutter_riverpod.dart';
// Removed collection
import 'package:moniary/core/supabase/supabase_providers.dart';
import 'package:moniary/core/supabase/app_exception.dart';
import 'package:moniary/shared/utils/app_logger.dart';
import 'package:moniary/features/settings/data/repositories/import_repository.dart';
import 'package:moniary/features/transactions/data/repositories/transaction_repository.dart';
import 'package:moniary/features/categories/data/repositories/category_repository.dart';
import 'package:moniary/features/wallets/domain/models/wallet.dart';
import 'package:moniary/features/categories/domain/models/category.dart';
import 'package:moniary/features/settings/domain/models/csv_transaction_row.dart';

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
      selectedFilePath: selectedFilePath != null ? selectedFilePath() : this.selectedFilePath,
      error: error != null ? error() : this.error,
    );
  }
}

final importControllerProvider = NotifierProvider<ImportController, ImportState>(
  ImportController.new,
);

class ImportController extends Notifier<ImportState> {
  @override
  ImportState build() {
    return ImportState();
  }

  Future<void> pickAndParseFile(String filePath) async {
    state = state.copyWith(isParsing: true, selectedFilePath: () => filePath, error: () => null);
    try {
      final repo = ref.read(importRepositoryProvider);
      final rows = await repo.parseCsv(filePath);
      state = state.copyWith(parsedRows: rows, isParsing: false, selectedFilePath: () => filePath);
    } on AppException catch (e, st) {
      AppLogger.error('Failed to parse file', e, st);
      state = state.copyWith(isParsing: false, parsedRows: [], error: () => e.code ?? 'IMPORT_PARSE_ERROR');
    } catch (e, st) {
      AppLogger.error('Failed to parse file', e, st);
      state = state.copyWith(isParsing: false, parsedRows: [], error: () => 'IMPORT_PARSE_ERROR');
    }
  }

  Future<int> confirmImport(Wallet targetWallet) async {
    state = state.copyWith(isImporting: true, error: () => null);
    try {
      final session = ref.read(currentSessionProvider);
      final profileId = session?.user.id;
      if (profileId == null) {
         throw const AppException('User not logged in', code: 'AUTH_REQUIRED');
      }

      final validRows = state.parsedRows.where((r) => r.isValid).toList();
      if (validRows.isEmpty) {
        state = state.copyWith(isImporting: false);
        return 0;
      }

      final categoryRepo = ref.read(categoryRepositoryProvider);
      final transactionRepo = ref.read(transactionRepositoryProvider);

      // Fetch categories to map names to IDs
      final categories = await categoryRepo.fetchCategories();

      int importCount = 0;

      for (var row in validRows) {
        final isIncome = row.typeStr.toLowerCase().contains('income') || row.typeStr.toLowerCase() == 'thu';
        final type = isIncome ? TransactionType.income : TransactionType.expense;

        // Find matching category (case-insensitive)
        Category? matchedCat;
        for (var c in categories) {
          if (c.name.toLowerCase() == row.categoryName.toLowerCase() && c.type == type) {
            matchedCat = c;
            break;
          }
        }
        
        // Fallback to first available category of the same type
        if (matchedCat == null) {
          for (var c in categories) {
            if (c.type == type) {
              matchedCat = c;
              break;
            }
          }
        }

        if (matchedCat == null) {
           // If no categories exist, we cannot import this row safely.
           AppLogger.warning('Skipping row because no category found for type: $type');
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

      state = state.copyWith(isImporting: false, parsedRows: []);
      return importCount;
    } on AppException catch (e, st) {
      AppLogger.error('Import failed', e, st);
      state = state.copyWith(isImporting: false, error: () => e.code ?? 'IMPORT_FAILED');
      return 0;
    } catch (e, st) {
      AppLogger.error('Import failed', e, st);
      state = state.copyWith(isImporting: false, error: () => 'IMPORT_FAILED');
      return 0;
    }
  }
}
