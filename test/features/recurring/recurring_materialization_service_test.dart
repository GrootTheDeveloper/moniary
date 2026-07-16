import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:moniary/core/supabase/app_exception.dart';
import 'package:moniary/features/recurring/application/recurring_materialization_service.dart';
import 'package:moniary/features/recurring/data/repositories/recurring_transaction_repository.dart';

class MockRecurringTransactionRepository extends Mock
    implements RecurringTransactionRepository {}

void main() {
  late MockRecurringTransactionRepository repository;
  late RecurringMaterializationService service;

  setUp(() {
    repository = MockRecurringTransactionRepository();
    service = RecurringMaterializationService(repository);
  });

  test('deduplicates concurrent launch and screen requests', () async {
    final completer = Completer<int>();
    when(
      () => repository.postDueTransactions(through: any(named: 'through')),
    ).thenAnswer((_) => completer.future);

    final first = service.run();
    final second = service.run();
    completer.complete(3);

    expect(await first, 3);
    expect(await second, 3);
    verify(
      () => repository.postDueTransactions(through: any(named: 'through')),
    ).called(1);
  });

  test('propagates server failures so interactive callers can report them', () {
    when(
      () => repository.postDueTransactions(through: any(named: 'through')),
    ).thenThrow(
      const AppException('Recurring failed', code: 'RECURRING_POST_FAILED'),
    );

    expect(service.run(), throwsA(isA<AppException>()));
  });
}
