import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/utils/app_logger.dart';
import '../../transactions/data/repositories/transaction_repository.dart';
import '../data/repositories/recurring_transaction_repository.dart';
import '../domain/models/recurring_transaction.dart';

final recurringMaterializationServiceProvider =
    Provider<RecurringMaterializationService>((ref) {
      return RecurringMaterializationService(
        ref.read(recurringTransactionRepositoryProvider),
        ref.read(transactionRepositoryProvider),
      );
    });

/// Client-side "catch-up on launch" engine. Any active rule with
/// `autoPost == true` whose `nextRunDate` is on or before today is
/// materialized into the `transactions` table — one transaction per missed
/// occurrence — then its schedule is advanced past today. `lastRunDate`
/// guards against double-posting across runs.
class RecurringMaterializationService {
  RecurringMaterializationService(this._recurringRepo, this._transactionRepo);

  final RecurringTransactionRepository _recurringRepo;
  final TransactionRepository _transactionRepo;

  // Safety cap: never post more than this many catch-up occurrences for one
  // rule in a single pass (guards against a far-past start date).
  static const _maxOccurrencesPerRule = 500;

  Future<int>? _inFlight;

  /// Runs the pass, deduplicating concurrent callers (launch hook + screen).
  /// Returns the number of transactions posted.
  Future<int> run() {
    return _inFlight ??= _run().whenComplete(() => _inFlight = null);
  }

  Future<int> _run() async {
    final today = _dateOnly(DateTime.now());
    List<RecurringTransaction> rules;
    try {
      rules = await _recurringRepo.fetchRecurringTransactions();
    } catch (error, stackTrace) {
      AppLogger.error('Recurring auto-post: fetch failed', error, stackTrace);
      return 0;
    }

    var posted = 0;
    for (final rule in rules) {
      if (!rule.isActive || !rule.autoPost) continue;
      try {
        posted += await _processRule(rule, today);
      } catch (error, stackTrace) {
        // One bad rule must not abort the whole pass.
        AppLogger.error(
          'Recurring auto-post: rule ${rule.id} failed',
          error,
          stackTrace,
        );
      }
    }
    return posted;
  }

  Future<int> _processRule(RecurringTransaction rule, DateTime today) async {
    final end = rule.endDate == null ? null : _dateOnly(rule.endDate!);
    var next = _dateOnly(rule.nextRunDate);
    DateTime? lastRun = rule.lastRunDate;
    var posted = 0;

    while (!next.isAfter(today) &&
        (end == null || !next.isAfter(end)) &&
        posted < _maxOccurrencesPerRule) {
      await _transactionRepo.createTransaction(
        amount: rule.amount,
        type: rule.type,
        walletId: rule.walletId,
        categoryId: rule.categoryId,
        transactionDate: next,
        note: rule.note,
        source: 'recurring',
      );
      posted++;
      lastRun = next;
      next = _advance(next, rule.frequency, rule.interval);
    }

    // The rule is finished once its next occurrence falls past the end date.
    final stillActive = end == null || !next.isAfter(end);

    if (posted > 0 || !stillActive) {
      await _recurringRepo.advanceSchedule(
        id: rule.id,
        nextRunDate: next,
        lastRunDate: lastRun,
        isActive: stillActive,
      );
    }
    return posted;
  }

  DateTime _advance(DateTime date, RecurringFrequency frequency, int interval) {
    final step = interval < 1 ? 1 : interval;
    return switch (frequency) {
      RecurringFrequency.daily => _dateOnly(date.add(Duration(days: step))),
      RecurringFrequency.weekly =>
        _dateOnly(date.add(Duration(days: 7 * step))),
      RecurringFrequency.monthly => _addMonths(date, step),
      RecurringFrequency.yearly => _addMonths(date, 12 * step),
    };
  }

  // Adds whole months, clamping the day to the target month's length so that
  // e.g. Jan 31 + 1 month = Feb 28/29 rather than rolling into March.
  DateTime _addMonths(DateTime date, int months) {
    final zeroBased = date.month - 1 + months;
    final year = date.year + (zeroBased ~/ 12);
    final month = (zeroBased % 12) + 1;
    final lastDayOfMonth = DateTime(year, month + 1, 0).day;
    final day = date.day <= lastDayOfMonth ? date.day : lastDayOfMonth;
    return DateTime(year, month, day);
  }

  DateTime _dateOnly(DateTime date) {
    final local = date.toLocal();
    return DateTime(local.year, local.month, local.day);
  }
}
