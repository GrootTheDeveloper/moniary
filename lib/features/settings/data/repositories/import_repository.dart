import 'dart:convert';
import 'dart:io';
import 'package:csv/csv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:moniary/core/constants/app_constants.dart';
import 'package:moniary/core/supabase/app_exception.dart';
import 'package:moniary/shared/utils/app_logger.dart';
import 'package:moniary/features/settings/domain/models/csv_transaction_row.dart';
import 'package:path_provider/path_provider.dart';
import 'package:moniary/features/settings/domain/import/import_history_entry.dart';

final importRepositoryProvider = Provider<ImportRepository>((ref) {
  return ImportRepository();
});

class ImportRepository {
  ImportRepository({Directory? documentsDirectory})
    : _documentsDirectory = documentsDirectory;

  final Directory? _documentsDirectory;

  /// Parses a CSV file and returns a list of [CsvTransactionRow].
  /// Expected columns: Date (YYYY-MM-DD), Amount, Type, Category, Note
  Future<List<CsvTransactionRow>> parseCsv(String filePath) async {
    if (!AppConstants.hasSupabaseConfig && filePath == 'mock_test.csv') {
      return [
        CsvTransactionRow(
          date: DateTime.now(),
          amount: 50000.0,
          typeStr: 'Chi',
          categoryName: 'Ăn uống',
          note: 'Mock transaction',
          isValid: true,
        ),
      ];
    }
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        throw const AppException(
          'File does not exist',
          code: 'IMPORT_FILE_NOT_FOUND',
        );
      }

      final input = file.openRead();
      final csvCodec = Csv(dynamicTyping: false);
      final fields = await input
          .transform(utf8.decoder)
          .transform(csvCodec.decoder)
          .toList();

      if (fields.isEmpty) {
        throw const AppException('File is empty', code: 'IMPORT_FILE_EMPTY');
      }

      // Skip header row
      final dataRows = fields.skip(1);
      final List<CsvTransactionRow> result = [];

      for (var row in dataRows) {
        // Handle empty rows
        if (row.isEmpty ||
            (row.length == 1 && row[0].toString().trim().isEmpty)) {
          continue;
        }

        if (row.length < 5) {
          result.add(
            const CsvTransactionRow(
              typeStr: '',
              categoryName: '',
              note: '',
              isValid: false,
              errorMessage: 'MISSING_COLUMNS',
            ),
          );
          continue;
        }

        final dateStr = row[0].toString().trim();
        final amountStr = row[1].toString().trim().replaceAll(',', '');
        final typeStr = row[2].toString().trim();
        final categoryStr = row[3].toString().trim();
        final noteStr = row[4].toString().trim();

        final parsedDate = DateTime.tryParse(dateStr);
        final parsedAmount = double.tryParse(amountStr);

        final isTypeValid = _isSupportedType(typeStr);
        final isValid =
            parsedDate != null &&
            parsedAmount != null &&
            parsedAmount > 0 &&
            isTypeValid;
        String? error;
        if (!isValid) {
          if (parsedDate == null) {
            error = 'INVALID_DATE';
          } else if (parsedAmount == null || parsedAmount <= 0) {
            error = 'INVALID_AMOUNT';
          } else if (!isTypeValid) {
            error = 'INVALID_TYPE';
          }
        }

        result.add(
          CsvTransactionRow(
            date: parsedDate,
            amount: parsedAmount,
            typeStr: typeStr,
            categoryName: categoryStr,
            note: noteStr,
            isValid: isValid,
            errorMessage: error,
          ),
        );
      }

      return result;
    } on AppException catch (e, st) {
      AppLogger.error('CSV Import Error', e, st);
      rethrow;
    } catch (e, st) {
      AppLogger.error('Failed to parse CSV', e, st);
      throw AppException('Failed to parse CSV: $e', code: 'IMPORT_PARSE_ERROR');
    }
  }

  static bool _isSupportedType(String value) {
    final normalized = value.trim().toLowerCase();
    return normalized == 'income' ||
        normalized == 'expense' ||
        normalized == 'thu' ||
        normalized == 'chi';
  }

  Future<File> _importHistoryFile() async {
    final directory =
        _documentsDirectory ?? await getApplicationDocumentsDirectory();
    return File('${directory.path}/moniary_import_history.json');
  }

  Future<List<ImportHistoryEntry>> fetchImportHistory() async {
    final file = await _importHistoryFile();
    if (!await file.exists()) {
      return const [];
    }

    try {
      final raw = await file.readAsString();
      final decoded = jsonDecode(raw) as List<dynamic>;
      return decoded
          .cast<Map<String, dynamic>>()
          .map(ImportHistoryEntry.fromMap)
          .toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    } catch (e, st) {
      AppLogger.error('Failed to read import history', e, st);
      throw const AppException(
        'Failed to read import history',
        code: 'IMPORT_HISTORY_READ_ERROR',
      );
    }
  }

  Future<void> recordImport({
    required String fileName,
    required int importedCount,
    required String walletName,
  }) async {
    final entry = ImportHistoryEntry(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      fileName: fileName,
      importedCount: importedCount,
      walletName: walletName,
      createdAt: DateTime.now(),
      status: ImportHistoryStatus.completed,
    );

    await _prependImportHistory(entry);
  }

  Future<ImportHistoryEntry> createPendingImport({
    required String fileName,
    required String walletName,
  }) async {
    final entry = ImportHistoryEntry(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      fileName: fileName,
      importedCount: 0,
      walletName: walletName,
      createdAt: DateTime.now(),
      status: ImportHistoryStatus.pending,
    );
    await _prependImportHistory(entry);
    return entry;
  }

  Future<void> completeImport({
    required String id,
    required int importedCount,
  }) {
    return _updateImportHistoryEntry(
      id,
      (entry) => entry.copyWith(
        importedCount: importedCount,
        status: ImportHistoryStatus.completed,
        errorMessage: () => null,
      ),
    );
  }

  Future<void> failImport({
    required String id,
    required int importedCount,
    required String errorMessage,
  }) {
    return _updateImportHistoryEntry(
      id,
      (entry) => entry.copyWith(
        importedCount: importedCount,
        status: ImportHistoryStatus.failed,
        errorMessage: () => errorMessage,
      ),
    );
  }

  Future<void> _prependImportHistory(ImportHistoryEntry entry) async {
    final history = await fetchImportHistory();
    await _writeImportHistory([entry, ...history].take(50).toList());
  }

  Future<void> _updateImportHistoryEntry(
    String id,
    ImportHistoryEntry Function(ImportHistoryEntry entry) update,
  ) async {
    final history = await fetchImportHistory();
    final updated = history.map((entry) {
      return entry.id == id ? update(entry) : entry;
    }).toList();
    await _writeImportHistory(updated);
  }

  Future<void> _writeImportHistory(List<ImportHistoryEntry> history) async {
    final fileHistory = await _importHistoryFile();
    final next = history.take(50).map((item) => item.toMap()).toList();
    await fileHistory.writeAsString(
      const JsonEncoder.withIndent('  ').convert(next),
    );
  }
}
