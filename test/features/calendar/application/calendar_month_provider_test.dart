import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moniary/core/preferences/preferences_providers.dart';
import 'package:moniary/core/supabase/supabase_providers.dart';
import 'package:moniary/features/calendar/application/month/calendar_month_provider.dart';
import 'package:moniary/features/categories/domain/models/category.dart';
import 'package:moniary/features/transactions/data/repositories/transaction_repository.dart';
import 'package:moniary/features/transactions/domain/models/transaction_entry.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final _testSessionProvider = NotifierProvider<_TestSessionNotifier, Session?>(
  _TestSessionNotifier.new,
);

class _TestSessionNotifier extends Notifier<Session?> {
  @override
  Session? build() => _sessionFor('hoang');

  void switchTo(Session? session) => state = session;
}

class _TestFirstDayOfWeekNotifier extends FirstDayOfWeekNotifier {
  @override
  int build() => 1;
}

class _FakeSupabaseClient extends Fake implements SupabaseClient {}

class _SessionTransactionRepository extends TransactionRepository {
  _SessionTransactionRepository(this._transactions)
    : super(_FakeSupabaseClient());

  final List<TransactionEntry> _transactions;

  @override
  Future<List<TransactionEntry>> fetchTransactionsForMonth(
    DateTime month, {
    String? walletId,
    String? categoryId,
  }) async {
    return _transactions;
  }
}

Session _sessionFor(String userId) {
  return Session(
    accessToken: 'token-$userId',
    tokenType: 'bearer',
    user: User(
      id: userId,
      appMetadata: const {},
      userMetadata: const {},
      aud: 'authenticated',
      createdAt: '2026-07-16T00:00:00Z',
    ),
  );
}

TransactionEntry _transaction(String id) {
  return TransactionEntry(
    id: id,
    amount: 32300,
    type: TransactionType.expense,
    note: 'Account-scoped transaction',
    imagePath: null,
    transactionDate: DateTime(2026, 7, 15),
    walletId: 'wallet',
    walletName: 'Wallet',
    walletColor: null,
    walletCurrency: 'VND',
    categoryId: 'category',
    categoryName: 'Food',
    categoryColor: null,
  );
}

void main() {
  test('calendar month refetches when OAuth changes account', () async {
    final transactionsByUser = <String, List<TransactionEntry>>{
      'hoang': [_transaction('hoang-transaction')],
      'bruce': const [],
    };
    final container = ProviderContainer(
      overrides: [
        firstDayOfWeekProvider.overrideWith(_TestFirstDayOfWeekNotifier.new),
        currentSessionProvider.overrideWith(
          (ref) => ref.watch(_testSessionProvider),
        ),
        transactionRepositoryProvider.overrideWith((ref) {
          final userId = ref.watch(currentSessionProvider)?.user.id;
          return _SessionTransactionRepository(
            transactionsByUser[userId] ?? const [],
          );
        }),
      ],
    );
    addTearDown(container.dispose);

    final month = DateTime(2026, 7);
    expect(
      (await container.read(
        calendarMonthProvider(month).future,
      )).transactions.single.id,
      'hoang-transaction',
    );

    container
        .read(_testSessionProvider.notifier)
        .switchTo(_sessionFor('bruce'));
    await container.pump();

    expect(
      (await container.read(calendarMonthProvider(month).future)).transactions,
      isEmpty,
    );
  });
}
