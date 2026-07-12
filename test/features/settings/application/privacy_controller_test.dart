import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:local_auth/local_auth.dart';
import 'package:moniary/features/settings/application/privacy_controller.dart';
import 'package:moniary/features/settings/data/repositories/privacy_repository.dart';
import 'package:moniary/core/supabase/app_exception.dart';

class MockPrivacyRepository extends Mock implements PrivacyRepository {}

class MockLocalAuthentication extends Mock implements LocalAuthentication {}

void main() {
  late MockPrivacyRepository mockRepo;
  late MockLocalAuthentication mockAuth;

  setUp(() {
    mockRepo = MockPrivacyRepository();
    mockAuth = MockLocalAuthentication();

    // Default mock behaviors
    when(() => mockRepo.getIsAppLocked()).thenReturn(false);
    when(() => mockRepo.getIsBalancesHidden()).thenReturn(false);
    when(() => mockRepo.setIsAppLocked(any())).thenAnswer((_) async {});
    when(() => mockRepo.setIsBalancesHidden(any())).thenAnswer((_) async {});

    when(() => mockAuth.canCheckBiometrics).thenAnswer((_) async => true);
    when(() => mockAuth.isDeviceSupported()).thenAnswer((_) async => true);
  });

  ProviderContainer makeContainer() {
    return ProviderContainer(
      overrides: [
        privacyRepositoryProvider.overrideWithValue(mockRepo),
        localAuthProvider.overrideWithValue(mockAuth),
      ],
    );
  }

  test('build initializes state from repository', () {
    when(() => mockRepo.getIsAppLocked()).thenReturn(true);
    when(() => mockRepo.getIsBalancesHidden()).thenReturn(true);

    final container = makeContainer();
    final state = container.read(privacyControllerProvider);

    expect(state.isAppLocked, isTrue);
    expect(state.isBalancesHidden, isTrue);
    expect(state.isAuthenticated, isFalse);
  });

  test('toggleHideBalances updates state and calls repository', () async {
    final container = makeContainer();
    final notifier = container.read(privacyControllerProvider.notifier);

    await notifier.toggleHideBalances(true);

    final state = container.read(privacyControllerProvider);
    expect(state.isBalancesHidden, isTrue);
    verify(() => mockRepo.setIsBalancesHidden(true)).called(1);
  });

  test(
    'toggleAppLock(true) with successful auth updates state and repository',
    () async {
      when(
        () => mockAuth.authenticate(
          localizedReason: any(named: 'localizedReason'),
        ),
      ).thenAnswer((_) async => true);

      final container = makeContainer();
      final notifier = container.read(privacyControllerProvider.notifier);

      await notifier.toggleAppLock(true, reason: 'Unlock');

      final state = container.read(privacyControllerProvider);
      expect(state.isAppLocked, isTrue);
      expect(state.isAuthenticated, isTrue);
      verify(() => mockAuth.authenticate(localizedReason: 'Unlock')).called(1);
      verify(() => mockRepo.setIsAppLocked(true)).called(1);
    },
  );

  test('toggleAppLock(true) with failed auth does not update state', () async {
    when(
      () =>
          mockAuth.authenticate(localizedReason: any(named: 'localizedReason')),
    ).thenAnswer((_) async => false);

    final container = makeContainer();
    final notifier = container.read(privacyControllerProvider.notifier);

    await notifier.toggleAppLock(true, reason: 'Unlock');

    final state = container.read(privacyControllerProvider);
    expect(state.isAppLocked, isFalse);
    verifyNever(() => mockRepo.setIsAppLocked(true));
  });

  test('toggleAppLock(false) also requires successful auth', () async {
    when(() => mockRepo.getIsAppLocked()).thenReturn(true);
    when(
      () =>
          mockAuth.authenticate(localizedReason: any(named: 'localizedReason')),
    ).thenAnswer((_) async => true);

    final container = makeContainer();
    final changed = await container
        .read(privacyControllerProvider.notifier)
        .toggleAppLock(false, reason: 'Disable lock');

    expect(changed, isTrue);
    expect(container.read(privacyControllerProvider).isAppLocked, isFalse);
    verify(
      () => mockAuth.authenticate(localizedReason: 'Disable lock'),
    ).called(1);
    verify(() => mockRepo.setIsAppLocked(false)).called(1);
  });

  test('unsupported local auth does not enable App Lock', () async {
    when(() => mockAuth.canCheckBiometrics).thenAnswer((_) async => false);
    when(() => mockAuth.isDeviceSupported()).thenAnswer((_) async => false);

    final container = makeContainer();
    final operation = container
        .read(privacyControllerProvider.notifier)
        .toggleAppLock(true, reason: 'Enable lock');

    await expectLater(
      operation,
      throwsA(
        isA<AppException>().having(
          (error) => error.code,
          'code',
          'LOCAL_AUTH_UNAVAILABLE',
        ),
      ),
    );
    expect(container.read(privacyControllerProvider).isAppLocked, isFalse);
    verifyNever(() => mockRepo.setIsAppLocked(true));
  });

  test('lockApp changes isAuthenticated to false if isAppLocked is true', () {
    when(() => mockRepo.getIsAppLocked()).thenReturn(true);
    final container = makeContainer();
    final notifier = container.read(privacyControllerProvider.notifier);

    // Initial build sets isAuthenticated = false, let's manually set it to true
    notifier.state = notifier.state.copyWith(isAuthenticated: true);
    expect(container.read(privacyControllerProvider).isAuthenticated, isTrue);

    notifier.lockApp();

    expect(container.read(privacyControllerProvider).isAuthenticated, isFalse);
  });
}
