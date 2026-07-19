import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:moniary/core/supabase/app_exception.dart';
import 'package:moniary/features/bank_linking/application/bank_link_controller.dart';
import 'package:moniary/features/bank_linking/data/repositories/bank_link_repository_impl.dart';
import 'package:moniary/features/bank_linking/domain/models/bank_connection.dart';
import 'package:moniary/features/bank_linking/domain/models/pending_synced_transaction.dart';
import 'package:moniary/features/bank_linking/domain/repositories/bank_link_repository.dart';
import 'package:moniary/features/categories/domain/models/category.dart';

class _MockBankLinkRepository extends Mock implements BankLinkRepository {}

void main() {
  late _MockBankLinkRepository repository;
  late ProviderContainer container;

  setUp(() {
    repository = _MockBankLinkRepository();
    container = ProviderContainer(
      overrides: [bankLinkRepositoryProvider.overrideWithValue(repository)],
    );
  });

  tearDown(() => container.dispose());

  final connection = BankConnection(
    id: 'connection-1',
    institutionId: 'institution-1',
    institutionName: 'Vietcombank',
    status: BankConnectionStatus.connected,
    provider: 'mock',
    createdAt: DateTime(2026, 7, 18),
  );

  test('build loads connections from the repository', () async {
    when(
      () => repository.fetchConnections(),
    ).thenAnswer((_) async => [connection]);

    final result = await container.read(bankLinkControllerProvider.future);

    expect(result, [connection]);
  });

  test('linkInstitution links then refreshes the connection list', () async {
    when(() => repository.fetchConnections()).thenAnswer((_) async => []);
    when(
      () => repository.linkInstitution(
        institutionId: 'institution-1',
        consentToken: 'granted',
      ),
    ).thenAnswer((_) async => connection);

    await container.read(bankLinkControllerProvider.future);
    when(
      () => repository.fetchConnections(),
    ).thenAnswer((_) async => [connection]);

    final result = await container
        .read(bankLinkControllerProvider.notifier)
        .linkInstitution(
          institutionId: 'institution-1',
          consentToken: 'granted',
        );

    expect(result, connection);
    expect(container.read(bankLinkControllerProvider).requireValue, [
      connection,
    ]);
  });

  test('unlinkConnection removes the connection and refreshes', () async {
    when(
      () => repository.fetchConnections(),
    ).thenAnswer((_) async => [connection]);
    await container.read(bankLinkControllerProvider.future);

    when(
      () => repository.unlinkConnection('connection-1'),
    ).thenAnswer((_) async {});
    when(() => repository.fetchConnections()).thenAnswer((_) async => []);

    await container
        .read(bankLinkControllerProvider.notifier)
        .unlinkConnection('connection-1');

    expect(container.read(bankLinkControllerProvider).requireValue, isEmpty);
  });

  test('syncConnection returns the number of pending rows found', () async {
    when(
      () => repository.fetchConnections(),
    ).thenAnswer((_) async => [connection]);
    await container.read(bankLinkControllerProvider.future);

    final pending = [
      PendingSyncedTransaction(
        id: 'pending-1',
        bankConnectionId: 'connection-1',
        externalTransactionId: 'ext-1',
        amount: 50000,
        type: TransactionType.expense,
        transactionDate: DateTime(2026, 7, 18),
        status: PendingSyncedTransactionStatus.pending,
        createdAt: DateTime(2026, 7, 18),
      ),
    ];
    when(
      () => repository.syncConnection('connection-1'),
    ).thenAnswer((_) async => pending);

    final count = await container
        .read(bankLinkControllerProvider.notifier)
        .syncConnection('connection-1');

    expect(count, 1);
    verify(() => repository.syncConnection('connection-1')).called(1);
  });

  test(
    'syncConnection failure leaves the existing connection list intact',
    () async {
      when(
        () => repository.fetchConnections(),
      ).thenAnswer((_) async => [connection]);
      await container.read(bankLinkControllerProvider.future);

      when(() => repository.syncConnection('connection-1')).thenThrow(
        const AppException(
          'errorBankSyncNotConfigured',
          code: 'BANK_SYNC_NOT_CONFIGURED',
        ),
      );

      await expectLater(
        () => container
            .read(bankLinkControllerProvider.notifier)
            .syncConnection('connection-1'),
        throwsA(isA<AppException>()),
      );

      expect(container.read(bankLinkControllerProvider).requireValue, [
        connection,
      ]);
    },
  );
}
