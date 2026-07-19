import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:moniary/core/supabase/app_exception.dart';
import 'package:moniary/core/widgets/widget_update_service.dart';
import 'package:moniary/features/categories/domain/models/category.dart';
import 'package:moniary/features/transactions/application/composer/transaction_composer_controller.dart';
import 'package:moniary/features/transactions/data/repositories/transaction_repository.dart';
import 'package:moniary/features/transactions/domain/models/transaction_entry.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class _FakeSupabaseClient extends Fake implements SupabaseClient {}

class _MockWidgetUpdateService extends Mock implements WidgetUpdateService {}

class _FakeTransactionRepository extends TransactionRepository {
  _FakeTransactionRepository() : super(_FakeSupabaseClient());

  Object? uploadError;
  Object? metadataError;
  String uploadedPath = 'transactions/user-1/transaction-1.jpg';
  String? previousImagePath;
  String? createdImageStatus;
  int removeCalls = 0;
  final List<({String? path, String status})> metadataUpdates = [];

  @override
  Future<String> createTransaction({
    required double amount,
    required TransactionType type,
    required String walletId,
    required String categoryId,
    required DateTime transactionDate,
    String? note,
    String? merchantName,
    String source = 'manual',
    bool isImportant = false,
    String? recurringTransactionId,
    String imageUploadStatus = 'none',
  }) async {
    createdImageStatus = imageUploadStatus;
    return 'transaction-1';
  }

  @override
  Future<void> updateTransaction({
    required String transactionId,
    required double amount,
    required TransactionType type,
    required String walletId,
    required String categoryId,
    required DateTime transactionDate,
    String? note,
    bool isImportant = false,
  }) async {}

  @override
  Future<TransactionEntry> fetchTransactionById(String transactionId) async {
    return TransactionEntry(
      id: transactionId,
      amount: 100,
      type: TransactionType.expense,
      note: null,
      imagePath: previousImagePath,
      transactionDate: DateTime(2026, 7, 16),
      walletId: 'wallet-1',
      walletName: 'Cash',
      walletColor: null,
      walletCurrency: 'VND',
      categoryId: 'category-1',
      categoryName: 'Food',
      categoryColor: null,
    );
  }

  @override
  Future<String> uploadTransactionImage(
    String transactionId,
    Uint8List bytes,
  ) async {
    if (uploadError case final error?) throw error;
    return uploadedPath;
  }

  @override
  Future<void> updateTransactionImageMetadata({
    required String transactionId,
    required String? imagePath,
    required String status,
  }) async {
    metadataUpdates.add((path: imagePath, status: status));
    if (metadataError case final error?) throw error;
  }

  @override
  Future<void> removeTransactionImage(String transactionId) async {
    removeCalls += 1;
  }
}

void main() {
  late _FakeTransactionRepository repository;
  late _MockWidgetUpdateService widgetService;
  late ProviderContainer container;

  setUp(() {
    repository = _FakeTransactionRepository();
    widgetService = _MockWidgetUpdateService();
    when(() => widgetService.updateWidget()).thenAnswer((_) async {});
    container = ProviderContainer(
      overrides: [
        transactionRepositoryProvider.overrideWithValue(repository),
        widgetUpdateServiceProvider.overrideWithValue(widgetService),
      ],
    );
  });

  tearDown(() => container.dispose());

  Future<void> waitUntilReady() async {
    await container.read(transactionComposerProvider.future);
  }

  test('creates a transaction with explicit no-image status', () async {
    await waitUntilReady();

    final result = await container
        .read(transactionComposerProvider.notifier)
        .createTransaction(
          amount: 100,
          type: TransactionType.expense,
          walletId: 'wallet-1',
          categoryId: 'category-1',
          transactionDate: DateTime(2026, 7, 16),
        );

    expect(repository.createdImageStatus, 'none');
    expect(result.imageUploadFailed, isFalse);
    expect(repository.metadataUpdates, isEmpty);
  });

  test(
    'keeps a committed transaction when its new image upload fails',
    () async {
      repository.uploadError = const AppException(
        'Upload failed',
        code: 'IMAGE_UPLOAD_FAILED',
      );
      await waitUntilReady();

      final result = await container
          .read(transactionComposerProvider.notifier)
          .createTransaction(
            amount: 100,
            type: TransactionType.expense,
            walletId: 'wallet-1',
            categoryId: 'category-1',
            transactionDate: DateTime(2026, 7, 16),
            imageBytes: Uint8List.fromList([1, 2, 3]),
          );

      expect(repository.createdImageStatus, 'pending');
      expect(result.imageUploadFailed, isTrue);
      expect(repository.removeCalls, 1);
      expect(repository.metadataUpdates.single.status, 'failed');
    },
  );

  test(
    'removes an unreferenced replacement when legacy metadata update fails',
    () async {
      repository.previousImagePath = 'legacy/user-1/old.jpg';
      repository.metadataError = const AppException(
        'Metadata failed',
        code: 'METADATA_UPDATE_FAILED',
      );
      await waitUntilReady();

      final result = await container
          .read(transactionComposerProvider.notifier)
          .updateTransaction(
            transactionId: 'transaction-1',
            amount: 100,
            type: TransactionType.expense,
            walletId: 'wallet-1',
            categoryId: 'category-1',
            transactionDate: DateTime(2026, 7, 16),
            imageBytes: Uint8List.fromList([1, 2, 3]),
          );

      expect(result.imageUploadFailed, isTrue);
      expect(repository.removeCalls, 1);
    },
  );

  test(
    'does not delete an existing deterministic image when upload fails',
    () async {
      repository.previousImagePath = repository.uploadedPath;
      repository.uploadError = const AppException(
        'Upload failed',
        code: 'IMAGE_UPLOAD_FAILED',
      );
      await waitUntilReady();

      final result = await container
          .read(transactionComposerProvider.notifier)
          .updateTransaction(
            transactionId: 'transaction-1',
            amount: 100,
            type: TransactionType.expense,
            walletId: 'wallet-1',
            categoryId: 'category-1',
            transactionDate: DateTime(2026, 7, 16),
            imageBytes: Uint8List.fromList([1, 2, 3]),
          );

      expect(result.imageUploadFailed, isTrue);
      expect(repository.removeCalls, 0);
    },
  );
}
