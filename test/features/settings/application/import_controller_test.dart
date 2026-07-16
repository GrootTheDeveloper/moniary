import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:moniary/features/settings/application/import_controller.dart';
import 'package:moniary/features/settings/data/repositories/import_repository.dart';
import 'package:moniary/features/settings/domain/import/import_history_entry.dart';
import 'package:moniary/features/settings/domain/models/csv_transaction_row.dart';
import 'package:moniary/features/transactions/data/repositories/transaction_repository.dart';
import 'package:moniary/features/categories/data/repositories/category_repository.dart';
import 'package:moniary/features/wallets/domain/models/wallet.dart';
import 'package:moniary/features/categories/domain/models/category.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:moniary/core/supabase/supabase_providers.dart';
import 'package:moniary/core/supabase/app_exception.dart';

class MockImportRepository extends Mock implements ImportRepository {}

class MockTransactionRepository extends Mock implements TransactionRepository {}

class MockCategoryRepository extends Mock implements CategoryRepository {}

void main() {
  late MockImportRepository mockImportRepo;
  late MockTransactionRepository mockTransactionRepo;
  late MockCategoryRepository mockCategoryRepo;
  late ProviderContainer container;

  setUpAll(() {
    registerFallbackValue(TransactionType.expense);
  });

  setUp(() {
    mockImportRepo = MockImportRepository();
    mockTransactionRepo = MockTransactionRepository();
    mockCategoryRepo = MockCategoryRepository();

    container = ProviderContainer(
      overrides: [
        importRepositoryProvider.overrideWithValue(mockImportRepo),
        transactionRepositoryProvider.overrideWithValue(mockTransactionRepo),
        categoryRepositoryProvider.overrideWithValue(mockCategoryRepo),
        currentSessionProvider.overrideWithValue(
          Session(
            accessToken: '123',
            tokenType: 'bearer',
            user: const User(
              id: 'u1',
              appMetadata: {},
              userMetadata: {},
              aud: 'authenticated',
              createdAt: '2026-05-30T00:00:00Z',
            ),
          ),
        ),
      ],
    );
  });

  tearDown(() {
    container.dispose();
  });

  ImportHistoryEntry historyEntry() {
    return ImportHistoryEntry(
      id: 'import-history-1',
      fileName: 'test.csv',
      importedCount: 0,
      walletName: 'Wallet',
      createdAt: DateTime(2026, 6, 2),
      status: ImportHistoryStatus.pending,
    );
  }

  test('pickAndParseFile updates state with parsed rows', () async {
    when(() => mockImportRepo.parseCsv(any())).thenAnswer(
      (_) async => [
        CsvTransactionRow(
          typeStr: 'Expense',
          categoryName: 'Food',
          note: '',
          isValid: true,
          amount: 100,
          date: DateTime.now(),
        ),
      ],
    );
    when(() => mockCategoryRepo.fetchCategories()).thenAnswer(
      (_) async => [
        Category(
          id: 'c1',
          name: 'Food',
          type: TransactionType.expense,
          icon: '',
          color: '',
          isDefault: false,
          isActive: true,
          createdAt: DateTime.now(),
        ),
      ],
    );

    final controller = container.read(importControllerProvider.notifier);
    await controller.pickAndParseFile('test.csv');

    final state = container.read(importControllerProvider);
    expect(state.parsedRows.length, 1);
    expect(state.isParsing, false);
    expect(state.error, isNull);
  });

  test('confirmImport creates transactions for valid rows', () async {
    when(() => mockImportRepo.parseCsv(any())).thenAnswer(
      (_) async => [
        CsvTransactionRow(
          typeStr: 'Expense',
          categoryName: 'Food',
          note: 'Lunch',
          isValid: true,
          amount: 100,
          date: DateTime.now(),
        ),
        CsvTransactionRow(
          typeStr: 'Income',
          categoryName: 'Salary',
          note: 'May',
          isValid: true,
          amount: 1000,
          date: DateTime.now(),
        ),
        CsvTransactionRow(
          typeStr: 'Expense',
          categoryName: 'Unknown',
          note: '',
          isValid: true,
          amount: 10,
          date: DateTime.now(),
        ),
        CsvTransactionRow(
          typeStr: 'Transfer',
          categoryName: 'Food',
          note: '',
          isValid: true,
          amount: 10,
          date: DateTime.now(),
        ),
      ],
    );

    when(() => mockCategoryRepo.fetchCategories()).thenAnswer(
      (_) async => [
        Category(
          id: 'c1',
          name: 'Food',
          type: TransactionType.expense,
          icon: '',
          color: '',
          isDefault: false,
          isActive: true,
          createdAt: DateTime.now(),
        ),
        Category(
          id: 'c2',
          name: 'Salary',
          type: TransactionType.income,
          icon: '',
          color: '',
          isDefault: false,
          isActive: true,
          createdAt: DateTime.now(),
        ),
      ],
    );

    when(
      () => mockTransactionRepo.importTransactionsAtomically(
        batchKey: any(named: 'batchKey'),
        walletId: any(named: 'walletId'),
        rows: any(named: 'rows'),
      ),
    ).thenAnswer((invocation) async {
      final rows =
          invocation.namedArguments[#rows] as List<Map<String, Object?>>;
      return rows.length;
    });
    when(
      () => mockImportRepo.createPendingImport(
        fileName: any(named: 'fileName'),
        walletName: any(named: 'walletName'),
      ),
    ).thenAnswer((_) async => historyEntry());
    when(
      () => mockImportRepo.completeImport(
        id: any(named: 'id'),
        importedCount: any(named: 'importedCount'),
      ),
    ).thenAnswer((_) async {});

    final controller = container.read(importControllerProvider.notifier);
    await controller.pickAndParseFile('test.csv');

    final parsedState = container.read(importControllerProvider);
    expect(parsedState.parsedRows[2].isValid, isFalse);
    expect(parsedState.parsedRows[2].errorMessage, 'CATEGORY_NOT_FOUND');
    expect(parsedState.parsedRows[3].isValid, isFalse);
    expect(parsedState.parsedRows[3].errorMessage, 'INVALID_TYPE');

    final wallet = Wallet(
      id: 'w1',
      name: 'Wallet',
      type: WalletType.bank,
      icon: null,
      color: null,
      initialBalance: 0,
      isDefault: true,
      isActive: true,
      createdAt: DateTime.now(),
    );

    final count = await controller.confirmImport(wallet);
    expect(count, 2); // 2 valid rows
    verify(
      () => mockTransactionRepo.importTransactionsAtomically(
        batchKey: any(named: 'batchKey'),
        walletId: any(named: 'walletId'),
        rows: any(named: 'rows'),
      ),
    ).called(1);

    final state = container.read(importControllerProvider);
    expect(state.parsedRows, isEmpty); // Clears rows on success
    verify(
      () => mockImportRepo.createPendingImport(
        fileName: 'test.csv',
        walletName: 'Wallet',
      ),
    ).called(1);
    verify(
      () => mockImportRepo.completeImport(
        id: 'import-history-1',
        importedCount: 2,
      ),
    ).called(1);
  });

  test(
    'confirmImport keeps imported count when completing history fails',
    () async {
      when(() => mockImportRepo.parseCsv(any())).thenAnswer(
        (_) async => [
          CsvTransactionRow(
            typeStr: 'Expense',
            categoryName: 'Food',
            note: 'Lunch',
            isValid: true,
            amount: 100,
            date: DateTime.now(),
          ),
        ],
      );
      when(() => mockCategoryRepo.fetchCategories()).thenAnswer(
        (_) async => [
          Category(
            id: 'c1',
            name: 'Food',
            type: TransactionType.expense,
            icon: '',
            color: '',
            isDefault: false,
            isActive: true,
            createdAt: DateTime.now(),
          ),
        ],
      );
      when(
        () => mockTransactionRepo.importTransactionsAtomically(
          batchKey: any(named: 'batchKey'),
          walletId: any(named: 'walletId'),
          rows: any(named: 'rows'),
        ),
      ).thenAnswer((_) async => 1);
      when(
        () => mockImportRepo.createPendingImport(
          fileName: any(named: 'fileName'),
          walletName: any(named: 'walletName'),
        ),
      ).thenAnswer((_) async => historyEntry());
      when(
        () => mockImportRepo.completeImport(
          id: any(named: 'id'),
          importedCount: any(named: 'importedCount'),
        ),
      ).thenThrow(Exception('history write failed'));

      final controller = container.read(importControllerProvider.notifier);
      await controller.pickAndParseFile('test.csv');

      final count = await controller.confirmImport(
        Wallet(
          id: 'w1',
          name: 'Wallet',
          type: WalletType.bank,
          icon: null,
          color: null,
          initialBalance: 0,
          isDefault: true,
          isActive: true,
          createdAt: DateTime.now(),
        ),
      );

      expect(count, 1);
      final state = container.read(importControllerProvider);
      expect(state.error, 'IMPORT_HISTORY_COMPLETE_ERROR');
      expect(state.parsedRows, isEmpty);
    },
  );

  test(
    'confirmImport stops before creating transactions when pending history fails',
    () async {
      when(() => mockImportRepo.parseCsv(any())).thenAnswer(
        (_) async => [
          CsvTransactionRow(
            typeStr: 'Expense',
            categoryName: 'Food',
            note: 'Lunch',
            isValid: true,
            amount: 100,
            date: DateTime.now(),
          ),
        ],
      );
      when(() => mockCategoryRepo.fetchCategories()).thenAnswer(
        (_) async => [
          Category(
            id: 'c1',
            name: 'Food',
            type: TransactionType.expense,
            icon: '',
            color: '',
            isDefault: false,
            isActive: true,
            createdAt: DateTime.now(),
          ),
        ],
      );
      when(
        () => mockImportRepo.createPendingImport(
          fileName: any(named: 'fileName'),
          walletName: any(named: 'walletName'),
        ),
      ).thenThrow(Exception('history write failed'));

      final controller = container.read(importControllerProvider.notifier);
      await controller.pickAndParseFile('test.csv');

      final count = await controller.confirmImport(
        Wallet(
          id: 'w1',
          name: 'Wallet',
          type: WalletType.bank,
          icon: null,
          color: null,
          initialBalance: 0,
          isDefault: true,
          isActive: true,
          createdAt: DateTime.now(),
        ),
      );

      expect(count, isNull);
      final state = container.read(importControllerProvider);
      expect(state.error, 'IMPORT_HISTORY_CREATE_ERROR');
      expect(state.parsedRows, isNotEmpty);
      verifyNever(
        () => mockTransactionRepo.importTransactionsAtomically(
          batchKey: any(named: 'batchKey'),
          walletId: any(named: 'walletId'),
          rows: any(named: 'rows'),
        ),
      );
      verifyNever(
        () => mockImportRepo.completeImport(
          id: any(named: 'id'),
          importedCount: any(named: 'importedCount'),
        ),
      );
    },
  );

  test('confirmImport reuses the batch key after a lost response', () async {
    final date = DateTime(2026, 6, 2);
    when(() => mockImportRepo.parseCsv(any())).thenAnswer(
      (_) async => [
        CsvTransactionRow(
          typeStr: 'Expense',
          categoryName: 'Food',
          note: 'Lunch',
          isValid: true,
          amount: 100,
          date: date,
        ),
      ],
    );
    when(() => mockCategoryRepo.fetchCategories()).thenAnswer(
      (_) async => [
        Category(
          id: 'c1',
          name: 'Food',
          type: TransactionType.expense,
          icon: '',
          color: '',
          isDefault: false,
          isActive: true,
          createdAt: date,
        ),
      ],
    );
    when(
      () => mockImportRepo.createPendingImport(
        fileName: any(named: 'fileName'),
        walletName: any(named: 'walletName'),
      ),
    ).thenAnswer((_) async => historyEntry());
    when(
      () => mockImportRepo.failImport(
        id: any(named: 'id'),
        importedCount: any(named: 'importedCount'),
        errorMessage: any(named: 'errorMessage'),
      ),
    ).thenAnswer((_) async {});
    var attempts = 0;
    final batchKeys = <String>[];
    when(
      () => mockTransactionRepo.importTransactionsAtomically(
        batchKey: any(named: 'batchKey'),
        walletId: any(named: 'walletId'),
        rows: any(named: 'rows'),
      ),
    ).thenAnswer((invocation) async {
      batchKeys.add(invocation.namedArguments[#batchKey] as String);
      attempts++;
      if (attempts == 1) {
        throw const AppException('Response was lost', code: 'errorConnection');
      }
      return 1;
    });
    when(
      () => mockImportRepo.completeImport(
        id: any(named: 'id'),
        importedCount: any(named: 'importedCount'),
      ),
    ).thenAnswer((_) async {});

    final controller = container.read(importControllerProvider.notifier);
    await controller.pickAndParseFile('test.csv');
    final wallet = Wallet(
      id: 'w1',
      name: 'Wallet',
      type: WalletType.bank,
      icon: null,
      color: null,
      initialBalance: 0,
      isDefault: true,
      isActive: true,
      createdAt: date,
    );

    expect(await controller.confirmImport(wallet), isNull);
    expect(await controller.confirmImport(wallet), 1);
    expect(batchKeys, hasLength(2));
    expect(batchKeys.first, batchKeys.last);
  });
}
