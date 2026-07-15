import 'dart:convert';
import 'dart:io';
import 'package:csv/csv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:moniary/core/supabase/app_exception.dart';
import 'package:moniary/features/settings/domain/data_transfer/spreadsheet_data_format.dart';
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

  /// Parses Moniary exports and legacy five-column CSV transaction files.
  ///
  /// Headers may be localized or reordered. Headerless legacy files use:
  /// Date, Amount, Type, Category, Note.
  Future<List<CsvTransactionRow>> parseCsv(String filePath) async {
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

      final nonEmptyRows = fields.where(_hasContent).toList(growable: false);
      if (nonEmptyRows.isEmpty) {
        throw const AppException('File is empty', code: 'IMPORT_FILE_EMPTY');
      }

      final layout = _CsvColumnLayout.fromFirstRow(nonEmptyRows.first);
      final dataRows = nonEmptyRows.skip(layout.firstDataRowIndex);
      final List<CsvTransactionRow> result = [];

      for (var row in dataRows) {
        if (layout.dataTypeIndex case final dataTypeIndex?) {
          if (dataTypeIndex >= row.length) {
            result.add(_missingColumnsRow);
            continue;
          }
          if (!SpreadsheetDataFormat.isTransactionDataType(
            row[dataTypeIndex],
          )) {
            // A full account export also contains wallet/category rows. The
            // transaction importer intentionally ignores those record types.
            continue;
          }
        }

        if (layout.requiredIndexes.any((index) => index >= row.length)) {
          result.add(_missingColumnsRow);
          continue;
        }

        final dateStr = _cell(row, layout.dateIndex);
        final amountStr = _cell(row, layout.amountIndex);
        final typeStr = _cell(row, layout.typeIndex);
        final categoryStr = _cell(row, layout.categoryIndex);
        final noteStr = layout.noteIndex == null
            ? ''
            : _cell(row, layout.noteIndex!);

        final parsedDate = _parseSpreadsheetDate(dateStr);
        final parsedAmount = _parseSpreadsheetAmount(amountStr);

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

      if (result.isEmpty) {
        throw const AppException(
          'No transactions found in file',
          code: 'IMPORT_NO_TRANSACTIONS',
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

  static const _missingColumnsRow = CsvTransactionRow(
    typeStr: '',
    categoryName: '',
    note: '',
    isValid: false,
    errorMessage: 'MISSING_COLUMNS',
  );

  static bool _hasContent(List<dynamic> row) {
    return row.any((cell) => cell.toString().trim().isNotEmpty);
  }

  static String _cell(List<dynamic> row, int index) {
    if (index < 0 || index >= row.length) return '';
    return row[index].toString().trim();
  }

  static DateTime? _parseSpreadsheetDate(String value) {
    final input = value.trim();
    if (input.isEmpty) return null;

    final isoDate = DateTime.tryParse(input);
    if (isoDate != null) return isoDate;

    final separated = RegExp(
      r'^(\d{1,4})[/-](\d{1,2})[/-](\d{1,4})(?:[ T](.+))?$',
      caseSensitive: false,
    ).firstMatch(input);
    if (separated != null) {
      final first = int.parse(separated.group(1)!);
      final second = int.parse(separated.group(2)!);
      final third = int.parse(separated.group(3)!);
      final clock = _parseClock(separated.group(4));
      if (clock == null) return null;
      if (separated.group(1)!.length == 4) {
        return _checkedDate(first, second, third, clock: clock);
      }
      if (separated.group(3)!.length == 4) {
        if (second > 12 && first <= 12) {
          // Unambiguous US date emitted by an en-US spreadsheet.
          return _checkedDate(third, first, second, clock: clock);
        }
        // Moniary documents day-first dates for ambiguous spreadsheet dates.
        return _checkedDate(third, second, first, clock: clock);
      }
    }

    final serial = double.tryParse(input.replaceAll(',', '.'));
    if (serial != null && serial >= 1 && serial < 2958466) {
      return DateTime(1899, 12, 30).add(
        Duration(
          days: serial.floor(),
          milliseconds: ((serial - serial.floor()) * 86400000).round(),
        ),
      );
    }
    return null;
  }

  static ({int hour, int minute, int second})? _parseClock(String? value) {
    if (value == null || value.trim().isEmpty) {
      return (hour: 0, minute: 0, second: 0);
    }
    final match = RegExp(
      r'^(\d{1,2}):(\d{2})(?::(\d{2}))?(?:\.\d+)?\s*(AM|PM)?$',
      caseSensitive: false,
    ).firstMatch(value.trim());
    if (match == null) return null;

    var hour = int.parse(match.group(1)!);
    final minute = int.parse(match.group(2)!);
    final second = int.tryParse(match.group(3) ?? '') ?? 0;
    final meridiem = match.group(4)?.toUpperCase();
    if (meridiem != null) {
      if (hour < 1 || hour > 12) return null;
      if (meridiem == 'AM' && hour == 12) hour = 0;
      if (meridiem == 'PM' && hour != 12) hour += 12;
    }
    if (hour > 23 || minute > 59 || second > 59) return null;
    return (hour: hour, minute: minute, second: second);
  }

  static DateTime? _checkedDate(
    int year,
    int month,
    int day, {
    required ({int hour, int minute, int second}) clock,
  }) {
    if (year < 1 || month < 1 || month > 12 || day < 1 || day > 31) {
      return null;
    }
    final date = DateTime(
      year,
      month,
      day,
      clock.hour,
      clock.minute,
      clock.second,
    );
    if (date.year != year || date.month != month || date.day != day) {
      return null;
    }
    return date;
  }

  static double? _parseSpreadsheetAmount(String value) {
    var input = value.trim().replaceAll(RegExp(r'[\s\u00A0]'), '');
    if (input.isEmpty) return null;

    final isParenthesized = input.startsWith('(') && input.endsWith(')');
    input = input.replaceAll(RegExp(r'[^0-9,.+\-]'), '');
    if (input.isEmpty) return null;

    final comma = input.lastIndexOf(',');
    final dot = input.lastIndexOf('.');
    if (comma >= 0 && dot >= 0) {
      final decimalIndex = comma > dot ? comma : dot;
      final whole = input
          .substring(0, decimalIndex)
          .replaceAll(',', '')
          .replaceAll('.', '');
      final fraction = input
          .substring(decimalIndex + 1)
          .replaceAll(',', '')
          .replaceAll('.', '');
      input = fraction.isEmpty ? whole : '$whole.$fraction';
    } else if (comma >= 0) {
      input = _normalizeSingleSeparator(input, ',');
    } else if (dot >= 0) {
      input = _normalizeSingleSeparator(input, '.');
    }

    final parsed = double.tryParse(input);
    if (parsed == null) return null;
    return isParenthesized ? -parsed.abs() : parsed;
  }

  static String _normalizeSingleSeparator(String value, String separator) {
    final parts = value.split(separator);
    if (_looksLikeGroupedNumber(parts)) return parts.join();
    if (parts.length == 2) {
      return '${parts.first}.${parts.last}';
    }
    return '${parts.take(parts.length - 1).join()}.'
        '${parts.last}';
  }

  static bool _looksLikeGroupedNumber(List<String> parts) {
    if (parts.length < 2 || parts.first.isEmpty) return false;
    return parts.skip(1).every((part) => part.length == 3);
  }

  Future<File> _importHistoryFile() async {
    final directory =
        _documentsDirectory ?? await getApplicationDocumentsDirectory();
    return File('${directory.path}/moniary_import_history.json');
  }

  Future<List<ImportHistoryEntry>> fetchImportHistory() async {
    try {
      final file = await _importHistoryFile();
      if (!await file.exists()) {
        return const [];
      }

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
    try {
      final fileHistory = await _importHistoryFile();
      final next = history.take(50).map((item) => item.toMap()).toList();
      await fileHistory.writeAsString(
        const JsonEncoder.withIndent('  ').convert(next),
      );
    } catch (e, st) {
      AppLogger.error('Failed to write import history file', e, st);
      throw const AppException(
        'Failed to write import history file',
        code: 'FILE_IO_ERROR',
      );
    }
  }

  Future<void> clearLocalHistory() async {
    final file = await _importHistoryFile();
    try {
      if (await file.exists()) await file.delete();
    } catch (error, stackTrace) {
      AppLogger.error('Failed to clear import history', error, stackTrace);
      throw const AppException(
        'Failed to clear import history',
        code: 'IMPORT_HISTORY_CLEAR_ERROR',
      );
    }
  }
}

class _CsvColumnLayout {
  const _CsvColumnLayout({
    required this.firstDataRowIndex,
    required this.dateIndex,
    required this.amountIndex,
    required this.typeIndex,
    required this.categoryIndex,
    required this.noteIndex,
    required this.dataTypeIndex,
  });

  factory _CsvColumnLayout.fromFirstRow(List<dynamic> firstRow) {
    final indexes = SpreadsheetDataFormat.indexHeaders(firstRow);
    final looksLikeHeader =
        SpreadsheetDataFormat.looksLikeHeader(indexes) ||
        (indexes.containsKey(SpreadsheetDataFormat.transactionDate) &&
            indexes.length >= 2);

    if (!looksLikeHeader) {
      return const _CsvColumnLayout(
        firstDataRowIndex: 0,
        dateIndex: 0,
        amountIndex: 1,
        typeIndex: 2,
        categoryIndex: 3,
        noteIndex: 4,
        dataTypeIndex: null,
      );
    }

    if (!SpreadsheetDataFormat.hasRequiredTransactionColumns(indexes)) {
      throw const AppException(
        'CSV header is missing required columns',
        code: 'IMPORT_INVALID_HEADER',
      );
    }

    return _CsvColumnLayout(
      firstDataRowIndex: 1,
      dateIndex: indexes[SpreadsheetDataFormat.transactionDate]!,
      amountIndex: indexes[SpreadsheetDataFormat.amount]!,
      typeIndex: indexes[SpreadsheetDataFormat.type]!,
      categoryIndex: indexes[SpreadsheetDataFormat.category]!,
      noteIndex: indexes[SpreadsheetDataFormat.note],
      dataTypeIndex: indexes[SpreadsheetDataFormat.dataType],
    );
  }

  final int firstDataRowIndex;
  final int dateIndex;
  final int amountIndex;
  final int typeIndex;
  final int categoryIndex;
  final int? noteIndex;
  final int? dataTypeIndex;

  Iterable<int> get requiredIndexes sync* {
    if (dataTypeIndex case final index?) yield index;
    yield dateIndex;
    yield amountIndex;
    yield typeIndex;
    yield categoryIndex;
  }
}
