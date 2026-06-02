import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:moniary/features/auth/application/account_status_controller.dart';
import 'package:moniary/features/settings/data/account/account_repository.dart';

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
    when(
      () => accountRepository.isAccountPendingDeletion(),
    ).thenAnswer((_) async => true);

    final isPendingDeletion = await container.read(
      accountStatusControllerProvider.future,
    );

    expect(isPendingDeletion, isTrue);
    verify(() => accountRepository.isAccountPendingDeletion()).called(1);
  });

  test(
    'restoreAccount delegates to repository and clears pending state',
    () async {
      when(
        () => accountRepository.isAccountPendingDeletion(),
      ).thenAnswer((_) async => true);
      when(() => accountRepository.restoreAccount()).thenAnswer((_) async {});

      await container.read(accountStatusControllerProvider.future);
      await container
          .read(accountStatusControllerProvider.notifier)
          .restoreAccount();

      final state = container.read(accountStatusControllerProvider);
      expect(state.value, isFalse);
      verify(() => accountRepository.restoreAccount()).called(1);
    },
  );
}
