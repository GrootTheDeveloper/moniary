import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:moniary/core/constants/app_constants.dart';
import 'package:moniary/core/supabase/app_exception.dart';
import 'package:moniary/features/settings/data/account/account_repository.dart';
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
}
