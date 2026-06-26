import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:moniary/core/supabase/app_exception.dart';
import 'package:moniary/features/settings/data/repositories/import_repository.dart';

void main() {
  late ImportRepository repository;
  late Directory tempDir;
  late File tempFile;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('moniary_test');
    repository = ImportRepository(documentsDirectory: tempDir);
    tempFile = File('${tempDir.path}/test.csv');
  });

  tearDown(() {
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  test('parseCsv returns correct data for valid CSV', () async {
    await tempFile.writeAsString('''Date,Amount,Type,Category,Note
2026-05-30,50000,Expense,Food,Lunch
2026-05-31,20000,Income,Salary,Test
''');

    final rows = await repository.parseCsv(tempFile.path);
    expect(rows.length, 2);

    expect(rows[0].isValid, true);
    expect(rows[0].amount, 50000);
    expect(rows[0].categoryName, 'Food');
    expect(rows[0].note, 'Lunch');

    expect(rows[1].isValid, true);
    expect(rows[1].amount, 20000);
    expect(rows[1].typeStr, 'Income');
  });

  test('parseCsv handles invalid rows', () async {
    await tempFile.writeAsString('''Date,Amount,Type,Category,Note
invalid_date,50000,Expense,Food,Lunch
2026-05-31,invalid,Income,Salary,Test
2026-05-30,50000,Expense
2026-05-30,50000,Transfer,Food,Unsupported type
''');

    final rows = await repository.parseCsv(tempFile.path);
    expect(rows.length, 4);

    expect(rows[0].isValid, false);
    expect(rows[0].errorMessage, 'INVALID_DATE');

    expect(rows[1].isValid, false);
    expect(rows[1].errorMessage, 'INVALID_AMOUNT');

    expect(rows[2].isValid, false);
    expect(rows[2].errorMessage, 'MISSING_COLUMNS');

    expect(rows[3].isValid, false);
    expect(rows[3].errorMessage, 'INVALID_TYPE');
  });

  test('parseCsv skips empty rows', () async {
    await tempFile.writeAsString('''Date,Amount,Type,Category,Note
2026-05-30,50000,Expense,Food,Lunch

2026-05-31,20000,Income,Salary,Test
''');

    final rows = await repository.parseCsv(tempFile.path);
    expect(rows.length, 2);
  });

  test(
    'fetchImportHistory returns empty list when history file is missing',
    () async {
      final history = await repository.fetchImportHistory();

      expect(history, isEmpty);
    },
  );

  test(
    'fetchImportHistory throws when stored history JSON is invalid',
    () async {
      final historyFile = File('${tempDir.path}/moniary_import_history.json');
      await historyFile.writeAsString('not valid json');

      expect(
        repository.fetchImportHistory(),
        throwsA(
          isA<AppException>().having(
            (error) => error.code,
            'code',
            'IMPORT_HISTORY_READ_ERROR',
          ),
        ),
      );
    },
  );

  test('createPendingImport does not overwrite invalid history file', () async {
    final historyFile = File('${tempDir.path}/moniary_import_history.json');
    const corruptHistory = 'not valid json';
    await historyFile.writeAsString(corruptHistory);

    await expectLater(
      repository.createPendingImport(fileName: 'test.csv', walletName: 'Cash'),
      throwsA(isA<AppException>()),
    );

    expect(await historyFile.readAsString(), corruptHistory);
  });
}
