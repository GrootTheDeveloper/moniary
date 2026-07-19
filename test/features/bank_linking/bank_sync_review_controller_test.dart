import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:moniary/core/widgets/widget_update_service.dart';
import 'package:moniary/features/bank_linking/application/bank_sync_review_controller.dart';
import 'package:moniary/features/bank_linking/data/repositories/bank_link_repository_impl.dart';
import 'package:moniary/features/bank_linking/domain/models/pending_synced_transaction.dart';
import 'package:moniary/features/bank_linking/domain/repositories/bank_link_repository.dart';
import 'package:moniary/features/categories/domain/models/category.dart';
import 'package:moniary/features/transactions/data/repositories/transaction_repository.dart';
import 'package:moniary/features/transactions/domain/models/transaction_entry.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class _MockBankLinkRepository extends Mock implements BankLinkRepository {}

class _FakeSupabaseClient extends Fake implements SupabaseClient {}

class _MockWidgetUpdateService extends Mock implements WidgetUpdateService {}

class _FakeTransactionRepository extends TransactionRepository {
  _FakeTransactionRepository() : super(_FakeSupabaseClient());

  String createdTransactionId = 'transaction-1';
  String? lastSource;

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
    lastSource = source;
    return createdTransactionId;
  }

  @override
  Future<TransactionEntry> fetchTransactionById(String transactionId) async {
    throw UnimplementedError();
  }
}

void main() {
  late _MockBankLinkRepository repository;
  late _FakeTransactionRepository transactionRepository;
  late ProviderContainer container;

  final pending = PendingSyncedTransaction(
    id: 'pending-1',
    bankConnectionId: 'connection-1',
    externalTransactionId: 'ext-1',
    amount: 75000,
    type: TransactionType.expense,
    transactionDate: DateTime(2026, 7, 18),
    merchantName: 'Circle K',
    status: PendingSyncedTransactionStatus.pending,
    createdAt: DateTime(2026, 7, 18),
  );

  setUp(() {
    repository = _MockBankLinkRepository();
    transactionRepository = _FakeTransactionRepository();
    final widgetService = _MockWidgetUpdateService();
    when(() => widgetService.updateWidget()).thenAnswer((_) async {});
    container = ProviderContainer(
      overrides: [
        bankLinkRepositoryProvider.overrideWithValue(repository),
        transactionRepositoryProvider.overrideWithValue(transactionRepository),
        widgetUpdateServiceProvider.overrideWithValue(widgetService),
      ],
    );
  });

  tearDown(() => container.dispose());

  test('build loads pending synced transactions', () async {
    when(
      () => repository.fetchPendingSyncedTransactions(),
    ).thenAnswer((_) async => [pending]);

    final result = await container.read(
      bankSyncReviewControllerProvider.future,
    );

    expect(result, [pending]);
  });

  test('dismiss marks the row dismissed and refreshes the list', () async {
    when(
      () => repository.fetchPendingSyncedTransactions(),
    ).thenAnswer((_) async => [pending]);
    await container.read(bankSyncReviewControllerProvider.future);

    when(
      () => repository.dismissSyncedTransaction('pending-1'),
    ).thenAnswer((_) async {});
    when(
      () => repository.fetchPendingSyncedTransactions(),
    ).thenAnswer((_) async => []);

    await container
        .read(bankSyncReviewControllerProvider.notifier)
        .dismiss('pending-1');

    expect(
      container.read(bankSyncReviewControllerProvider).requireValue,
      isEmpty,
    );
    verify(() => repository.dismissSyncedTransaction('pending-1')).called(1);
  });

  test(
    'confirm creates a real transaction tagged bank_sync and links it back',
    () async {
      var confirmed = false;
      when(
        () => repository.fetchPendingSyncedTransactions(),
      ).thenAnswer((_) async => confirmed ? [] : [pending]);
      await container.read(bankSyncReviewControllerProvider.future);

      when(
        () => repository.markSyncedTransactionConfirmed(
          pendingId: 'pending-1',
          transactionId: 'transaction-1',
        ),
      ).thenAnswer((_) async => confirmed = true);

      await container
          .read(bankSyncReviewControllerProvider.notifier)
          .confirm(
            pendingId: 'pending-1',
            walletId: 'wallet-1',
            categoryId: 'category-1',
          );

      expect(transactionRepository.lastSource, 'bank_sync');
      verify(
        () => repository.markSyncedTransactionConfirmed(
          pendingId: 'pending-1',
          transactionId: 'transaction-1',
        ),
      ).called(1);
      expect(
        container.read(bankSyncReviewControllerProvider).requireValue,
        isEmpty,
      );
    },
  );
}
