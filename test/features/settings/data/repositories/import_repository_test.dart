import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:moniary/features/settings/data/repositories/import_repository.dart';

void main() {
  late ImportRepository repository;
  late File tempFile;

  setUp(() {
    repository = ImportRepository();
    final tempDir = Directory.systemTemp.createTempSync('moniary_test');
    tempFile = File('${tempDir.path}/test.csv');
  });

  tearDown(() {
    if (tempFile.existsSync()) {
      tempFile.deleteSync();
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
''');

    final rows = await repository.parseCsv(tempFile.path);
    expect(rows.length, 3);
    
    expect(rows[0].isValid, false);
    expect(rows[0].errorMessage, contains('Invalid date'));
    
    expect(rows[1].isValid, false);
    expect(rows[1].errorMessage, contains('Invalid amount'));
    
    expect(rows[2].isValid, false);
    expect(rows[2].errorMessage, contains('Missing columns'));
  });
  
  test('parseCsv skips empty rows', () async {
    await tempFile.writeAsString('''Date,Amount,Type,Category,Note
2026-05-30,50000,Expense,Food,Lunch

2026-05-31,20000,Income,Salary,Test
''');

    final rows = await repository.parseCsv(tempFile.path);
    expect(rows.length, 2);
  });
}
