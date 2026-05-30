import 'dart:convert';
import 'dart:io';
import 'package:csv/csv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CsvTransactionRow {
  final DateTime? date;
  final double? amount;
  final String typeStr;
  final String categoryName;
  final String note;
  final bool isValid;
  final String? errorMessage;

  CsvTransactionRow({
    this.date,
    this.amount,
    required this.typeStr,
    required this.categoryName,
    required this.note,
    required this.isValid,
    this.errorMessage,
  });
}

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
        throw Exception('File does not exist');
      }

      final input = file.openRead();
      final csvCodec = Csv(dynamicTyping: false);
      final fields = await input
          .transform(utf8.decoder)
          .transform(csvCodec.decoder)
          .toList();

      if (fields.isEmpty) throw Exception('File is empty');

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
            CsvTransactionRow(
              typeStr: '',
              categoryName: '',
              note: '',
              isValid: false,
              errorMessage: 'Missing columns (expected 5)',
            ),
          );
          continue;
        }

        final dateStr = row[0].toString().trim();
        final amountStr = row[1].toString().trim().replaceAll(
          ',',
          '',
        ); // Handle comma thousands separator
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

        final isValid =
            parsedDate != null && parsedAmount != null && parsedAmount > 0;
        String? error;
        if (!isValid) {
          if (parsedDate == null)
            error = 'Invalid date format (use YYYY-MM-DD)';
          else if (parsedAmount == null)
            error = 'Invalid amount';
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
    } catch (e) {
      throw Exception('Failed to parse CSV: $e');
    }
  }
}
