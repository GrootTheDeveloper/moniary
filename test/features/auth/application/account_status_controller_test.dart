import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:moniary/features/auth/application/account_status_controller.dart';
import 'package:moniary/features/settings/data/account/account_repository.dart';
import 'package:moniary/features/settings/domain/account/account_deletion_status.dart';

class MockAccountRepository extends Mock implements AccountRepository {}

void main() {
  late MockAccountRepository accountRepository;
  late ProviderContainer container;

  setUp(() {
    accountRepository = MockAccountRepository();
    container = ProviderContainer(
      overrides: [
        accountRepositoryProvider.overrideWithValue(accountRepository),
      ],
    );
  });

  tearDown(() {
    container.dispose();
  });

  test('build reads pending deletion status from repository', () async {
    when(() => accountRepository.fetchAccountDeletionStatus()).thenAnswer(
      (_) async => AccountDeletionStatus(deletedAt: DateTime.utc(2026, 6, 1)),
    );

    final isPendingDeletion = await container.read(
      accountStatusControllerProvider.future,
    );

    expect(isPendingDeletion.isPending, isTrue);
    verify(() => accountRepository.fetchAccountDeletionStatus()).called(1);
  });

  test('scheduled deletion is exactly 30 days after server timestamp', () {
    final deletedAt = DateTime.utc(2026, 6, 1, 12);
    final status = AccountDeletionStatus(deletedAt: deletedAt);

    expect(status.scheduledDeletionAt, DateTime.utc(2026, 7, 1, 12));
  });

  test(
    'restoreAccount delegates to repository and clears pending state',
    () async {
      when(() => accountRepository.fetchAccountDeletionStatus()).thenAnswer(
        (_) async => AccountDeletionStatus(deletedAt: DateTime.utc(2026, 6, 1)),
      );
      when(() => accountRepository.restoreAccount()).thenAnswer((_) async {});

      await container.read(accountStatusControllerProvider.future);
      await container
          .read(accountStatusControllerProvider.notifier)
          .restoreAccount();

      final state = container.read(accountStatusControllerProvider);
      expect(state.value?.isPending, isFalse);
      verify(() => accountRepository.restoreAccount()).called(1);
    },
  );
}
