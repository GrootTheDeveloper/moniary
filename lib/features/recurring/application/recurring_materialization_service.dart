import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/repositories/recurring_transaction_repository.dart';

final recurringMaterializationServiceProvider =
    Provider<RecurringMaterializationService>((ref) {
      return RecurringMaterializationService(
        ref.read(recurringTransactionRepositoryProvider),
      );
    });

/// Client-side "catch-up on launch" engine. Any active rule with
/// `autoPost == true` whose `nextRunDate` is on or before today is
/// materialized atomically by PostgreSQL — one transaction per missed
/// occurrence — then its schedule is advanced past today. A unique posting
/// ledger makes retries and concurrent devices idempotent.
class RecurringMaterializationService {
  RecurringMaterializationService(this._recurringRepo);

  final RecurringTransactionRepository _recurringRepo;

  Future<int>? _inFlight;

  /// Runs the pass, deduplicating concurrent callers (launch hook + screen).
  /// Returns the number of transactions posted.
  Future<int> run() {
    return _inFlight ??= _run().whenComplete(() => _inFlight = null);
  }

  Future<int> _run() async {
    final today = _dateOnly(DateTime.now());
    return _recurringRepo.postDueTransactions(through: today);
  }

  DateTime _dateOnly(DateTime date) {
    final local = date.toLocal();
    return DateTime(local.year, local.month, local.day);
  }
}
