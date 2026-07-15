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

  test('parseCsv keeps the first row of a headerless legacy CSV', () async {
    await tempFile.writeAsString('2026-07-15,50000,Expense,Food,Lunch\n');

    final rows = await repository.parseCsv(tempFile.path);

    expect(rows, hasLength(1));
    expect(rows.single.isValid, isTrue);
    expect(rows.single.date, DateTime(2026, 7, 15));
    expect(rows.single.amount, 50000);
  });

  test('parseCsv supports reordered Excel-style semicolon columns', () async {
    await tempFile.writeAsString('''\uFEFFsep=;
Note;Category;Type;Amount;Date
Lunch;Food;Expense;1.234,50;15/07/2026
''');

    final rows = await repository.parseCsv(tempFile.path);

    expect(rows, hasLength(1));
    expect(rows.single.isValid, isTrue);
    expect(rows.single.date, DateTime(2026, 7, 15));
    expect(rows.single.amount, 1234.5);
    expect(rows.single.note, 'Lunch');
  });

  test(
    'parseCsv supports spreadsheet date-times and unambiguous US dates',
    () async {
      await tempFile.writeAsString('''Date,Amount,Type,Category,Note
15/07/2026 13:45:30,1000,Expense,Food,Day first
07/15/2026 1:30 PM,2000,Expense,Food,US locale
''');

      final rows = await repository.parseCsv(tempFile.path);

      expect(rows, hasLength(2));
      expect(rows[0].date, DateTime(2026, 7, 15, 13, 45, 30));
      expect(rows[1].date, DateTime(2026, 7, 15, 13, 30));
    },
  );

  test('parseCsv imports transactions from a full Moniary export', () async {
    await tempFile.writeAsString(
      '''data_type,id,name,type,amount,wallet,category,note,transaction_date,image_path,created_at,initial_balance,is_default,is_active
wallet,wallet-1,Cash,cash,,,,,,,2026-07-15 10:00:00,0,true,true
transaction,tx-1,,expense,50000,Cash,Food,Lunch,2026-07-15 12:30:00,,2026-07-15 12:31:00,,,
category,category-1,Food,expense,,,,,,,2026-07-15 10:00:00,,true,true
''',
    );

    final rows = await repository.parseCsv(tempFile.path);

    expect(rows, hasLength(1));
    expect(rows.single.isValid, isTrue);
    expect(rows.single.amount, 50000);
    expect(rows.single.categoryName, 'Food');
    expect(rows.single.note, 'Lunch');
  });

  test('parseCsv recognizes localized Moniary export headers', () async {
    await tempFile.writeAsString(
      '''Loại dữ liệu,ID,Tên,Loại giao dịch,Số tiền,Ví,Danh mục,Ghi chú,Ngày giao dịch,Đường dẫn ảnh,Tạo lúc,Số dư ban đầu,Mặc định,Đang dùng
transaction,tx-1,,expense,"1.234,50",Tiền mặt,Ăn uống,Bữa trưa,15/07/2026,,15/07/2026,,,
''',
    );

    final rows = await repository.parseCsv(tempFile.path);

    expect(rows, hasLength(1));
    expect(rows.single.isValid, isTrue);
    expect(rows.single.amount, 1234.5);
    expect(rows.single.categoryName, 'Ăn uống');
  });

  test('parseCsv reports a header missing required columns', () async {
    await tempFile.writeAsString('''Date,Amount,Type
2026-07-15,50000,Expense
''');

    await expectLater(
      repository.parseCsv(tempFile.path),
      throwsA(
        isA<AppException>().having(
          (error) => error.code,
          'code',
          'IMPORT_INVALID_HEADER',
        ),
      ),
    );
  });

  test('parseCsv reports a full export without transactions', () async {
    await tempFile.writeAsString(
      '''data_type,id,name,type,amount,wallet,category,note,transaction_date,image_path,created_at,initial_balance,is_default,is_active
wallet,wallet-1,Cash,cash,,,,,,,2026-07-15 10:00:00,0,true,true
''',
    );

    await expectLater(
      repository.parseCsv(tempFile.path),
      throwsA(
        isA<AppException>().having(
          (error) => error.code,
          'code',
          'IMPORT_NO_TRANSACTIONS',
        ),
      ),
    );
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
