import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:moniary/core/constants/app_constants.dart';
import 'package:moniary/core/supabase/app_exception.dart';
import 'package:moniary/features/settings/data/account/account_repository.dart';
import 'package:moniary/features/settings/domain/export/export_filters.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class FakeSupabaseClient extends Fake implements SupabaseClient {}

void main() {
  late Directory tempDir;
  late AccountRepository repository;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('moniary_account_test');
    repository = AccountRepository(
      FakeSupabaseClient(),
      documentsDirectory: tempDir,
      exportDirectory: tempDir,
    );
  });

  tearDown(() {
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  test(
    'fetchExportHistory returns empty list when history file is missing',
    () async {
      final history = await repository.fetchExportHistory();

      expect(history, isEmpty);
    },
  );

  test('fetchExportHistory throws when stored history JSON is invalid', () {
    final historyFile = File('${tempDir.path}/moniary_export_history.json');
    historyFile.writeAsStringSync('not valid json');

    expect(
      repository.fetchExportHistory(),
      throwsA(
        isA<AppException>().having(
          (error) => error.code,
          'code',
          'EXPORT_HISTORY_READ_ERROR',
        ),
      ),
    );
  });

  test('recordExportForTest does not overwrite invalid history file', () async {
    final historyFile = File('${tempDir.path}/moniary_export_history.json');
    const corruptHistory = 'not valid json';
    historyFile.writeAsStringSync(corruptHistory);
    final exportedFile = File('${tempDir.path}/moniary_export_test.csv');
    exportedFile.writeAsStringSync('data_type,id');

    await expectLater(
      repository.recordExportForTest(format: 'CSV', file: exportedFile),
      throwsA(isA<AppException>()),
    );

    expect(historyFile.readAsStringSync(), corruptHistory);
  });

  test(
    'exportTransactionsCsv works in mock mode without Supabase auth',
    () async {
      if (AppConstants.hasSupabaseConfig) {
        markTestSkipped(
          'Mock mode export test requires missing Supabase config.',
        );
      }

      final file = await repository.exportTransactionsCsv();

      expect(file.path, endsWith('.csv'));
      expect(await file.exists(), isTrue);
      expect(await file.readAsString(), contains('data_type'));

      final history = await repository.fetchExportHistory();
      expect(history, hasLength(1));
      expect(history.single.format, 'CSV');
      expect(history.single.path, file.path);
    },
  );

  test(
    'exportTransactionsXlsx works in mock mode without Supabase auth',
    () async {
      if (AppConstants.hasSupabaseConfig) {
        markTestSkipped(
          'Mock mode export test requires missing Supabase config.',
        );
      }

      final file = await repository.exportTransactionsXlsx();

      expect(file.path, endsWith('.xlsx'));
      expect(await file.exists(), isTrue);
      expect(await file.length(), greaterThan(0));

      final history = await repository.fetchExportHistory();
      expect(history, hasLength(1));
      expect(history.single.format, 'XLSX');
      expect(history.single.path, file.path);
    },
  );

  test(
    'exportTransactionsPdf works in mock mode without Supabase auth',
    () async {
      if (AppConstants.hasSupabaseConfig) {
        markTestSkipped(
          'Mock mode export test requires missing Supabase config.',
        );
      }

      final file = await repository.exportTransactionsPdf();

      expect(file.path, endsWith('.pdf'));
      expect(await file.exists(), isTrue);
      expect(await file.length(), greaterThan(0));

      final history = await repository.fetchExportHistory();
      expect(history, hasLength(1));
      expect(history.single.format, 'PDF');
      expect(history.single.path, file.path);
    },
  );

  test(
    'export history stores date range as technical dates instead of display text',
    () async {
      if (AppConstants.hasSupabaseConfig) {
        markTestSkipped(
          'Mock mode export test requires missing Supabase config.',
        );
      }

      final start = DateTime(2026, 5, 1);
      final end = DateTime(2026, 5, 31);
      await repository.exportTransactionsCsv(
        filters: ExportFilters(startDate: start, endDate: end),
      );

      final historyFile = File('${tempDir.path}/moniary_export_history.json');
      final raw = jsonDecode(await historyFile.readAsString()) as List<dynamic>;
      final first = raw.single as Map<String, dynamic>;

      expect(first, isNot(contains('date_range')));
      expect(first['start_date'], start.toIso8601String());
      expect(first['end_date'], end.toIso8601String());

      final history = await repository.fetchExportHistory();
      expect(history.single.startDate, start);
      expect(history.single.endDate, end);
      expect(history.single.legacyDateRange, isNull);
    },
  );

  test('fetchExportHistory preserves legacy display date range', () async {
    final historyFile = File('${tempDir.path}/moniary_export_history.json');
    await historyFile.writeAsString(
      jsonEncode([
        {
          'format': 'CSV',
          'path': 'legacy.csv',
          'created_at': DateTime(2026, 5, 1).toIso8601String(),
          'data_types': ['transactions'],
          'date_range': 'Tất cả thời gian',
        },
      ]),
    );

    final history = await repository.fetchExportHistory();

    expect(history.single.startDate, isNull);
    expect(history.single.endDate, isNull);
    expect(history.single.legacyDateRange, 'Tất cả thời gian');
    expect(history.single.toMap()['date_range'], 'Tất cả thời gian');
  });
}
