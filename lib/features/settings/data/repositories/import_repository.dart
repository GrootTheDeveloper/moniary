import 'dart:convert';
import 'dart:io';
import 'package:csv/csv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// Removed app_constants
import 'package:moniary/core/supabase/app_exception.dart';
import 'package:moniary/shared/utils/app_logger.dart';
import 'package:moniary/features/settings/domain/models/csv_transaction_row.dart';

final importRepositoryProvider = Provider<ImportRepository>((ref) {
  return ImportRepository();
});

class ImportRepository {
  /// Parses a CSV file and returns a list of [CsvTransactionRow].
  /// Expected columns: Date (YYYY-MM-DD), Amount, Type, Category, Note
  Future<List<CsvTransactionRow>> parseCsv(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        throw const AppException('File does not exist', code: 'IMPORT_FILE_NOT_FOUND');
      }

      final input = file.openRead();
      final csvCodec = Csv(dynamicTyping: false);
      final fields = await input
          .transform(utf8.decoder)
          .transform(csvCodec.decoder)
          .toList();

      if (fields.isEmpty) throw const AppException('File is empty', code: 'IMPORT_FILE_EMPTY');

      // Skip header row
      final dataRows = fields.skip(1);
      final List<CsvTransactionRow> result = [];

      for (var row in dataRows) {
        // Handle empty rows
        if (row.isEmpty || (row.length == 1 && row[0].toString().trim().isEmpty)) {
          continue;
        }

        if (row.length < 5) {
          result.add(const CsvTransactionRow(
            typeStr: '',
            categoryName: '',
            note: '',
            isValid: false,
            errorMessage: 'MISSING_COLUMNS',
          ));
          continue;
        }

        final dateStr = row[0].toString().trim();
        final amountStr = row[1].toString().trim().replaceAll(',', ''); // Handle comma thousands separator
        final typeStr = row[2].toString().trim();
        final categoryStr = row[3].toString().trim();
        final noteStr = row[4].toString().trim();

        DateTime? parsedDate;
        try {
          parsedDate = DateTime.parse(dateStr);
        } catch (_) {}

        double? parsedAmount;
        try {
          parsedAmount = double.parse(amountStr);
        } catch (_) {}

        final isValid = parsedDate != null && parsedAmount != null && parsedAmount > 0;
        String? error;
        if (!isValid) {
          if (parsedDate == null) {
            error = 'INVALID_DATE';
          } else if (parsedAmount == null) {
            error = 'INVALID_AMOUNT';
          }
        }

        result.add(CsvTransactionRow(
          date: parsedDate,
          amount: parsedAmount,
          typeStr: typeStr,
          categoryName: categoryStr,
          note: noteStr,
          isValid: isValid,
          errorMessage: error,
        ));
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
}
