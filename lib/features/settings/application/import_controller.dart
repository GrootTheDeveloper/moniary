import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:moniary/features/settings/data/repositories/import_repository.dart';
import 'package:moniary/features/transactions/data/repositories/transaction_repository.dart';
import 'package:moniary/features/categories/data/repositories/category_repository.dart';
import 'package:moniary/features/wallets/domain/models/wallet.dart';
import 'package:moniary/features/categories/domain/models/category.dart';

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
    String? selectedFilePath,
    String? error,
  }) {
    return ImportState(
      isParsing: isParsing ?? this.isParsing,
      isImporting: isImporting ?? this.isImporting,
      parsedRows: parsedRows ?? this.parsedRows,
      selectedFilePath: selectedFilePath, // replace if not null, or allow clearing? Use named argument carefully.
      error: error,
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
    state = state.copyWith(isParsing: true, selectedFilePath: filePath, error: null);
    try {
      final repo = ref.read(importRepositoryProvider);
      final rows = await repo.parseCsv(filePath);
      state = state.copyWith(parsedRows: rows, isParsing: false, selectedFilePath: filePath);
    } catch (e) {
      state = state.copyWith(isParsing: false, parsedRows: [], error: 'Failed to parse file: $e');
    }
  }

  Future<int> confirmImport(Wallet targetWallet, String profileId) async {
    state = state.copyWith(isImporting: true, error: null);
    try {
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
        try {
          matchedCat = categories.firstWhere(
            (c) => c.name.toLowerCase() == row.categoryName.toLowerCase() && c.type == type,
          );
        } catch (_) {
          // Fallback to first available category of the same type
          try {
             matchedCat = categories.firstWhere((c) => c.type == type);
          } catch (_) {
             // If no categories exist, we cannot import this row safely.
             continue;
          }
        }

        await transactionRepo.createTransaction(
          amount: row.amount ?? 0.0,
          type: type,
          walletId: targetWallet.id,
          categoryId: matchedCat!.id,
          transactionDate: row.date ?? DateTime.now(),
          note: row.note,
        );
        importCount++;
      }

      state = state.copyWith(isImporting: false, parsedRows: []);
      return importCount;
    } catch (e) {
      state = state.copyWith(isImporting: false, error: 'Import failed: $e');
      return 0;
    }
  }
}
