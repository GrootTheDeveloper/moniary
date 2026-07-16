import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/supabase/app_exception.dart';
import '../../../../core/supabase/supabase_providers.dart';
import '../../../../shared/utils/app_logger.dart';
import '../../../categories/domain/models/category.dart';
import '../../domain/models/recurring_transaction.dart';

final recurringTransactionRepositoryProvider =
    Provider<RecurringTransactionRepository>((ref) {
      return RecurringTransactionRepository(ref.watch(supabaseClientProvider));
    });

class RecurringTransactionRepository {
  RecurringTransactionRepository(this._client);

  final SupabaseClient _client;

  String get _userId {
    final uid = _client.auth.currentSession?.user.id;
    if (uid == null) {
      throw const AppException('User not logged in', code: 'AUTH_REQUIRED');
    }
    return uid;
  }

  Future<List<RecurringTransaction>> fetchRecurringTransactions() async {
    try {
      final rows = await _baseSelect()
          .eq('user_id', _userId)
          .order('next_run_date', ascending: true);
      return _mapList(rows);
    } on PostgrestException catch (e, st) {
      AppLogger.error('Fetch recurring transactions failed', e, st);
      throw AppException(e.message, code: e.code);
    } catch (e, st) {
      if (e is AppException) rethrow;
      AppLogger.error('Fetch recurring transactions failed', e, st);
      throw const AppException('errorConnection');
    }
  }

  Future<String> createRecurringTransaction({
    required double amount,
    required TransactionType type,
    required String walletId,
    required String categoryId,
    required RecurringFrequency frequency,
    required int interval,
    required DateTime startDate,
    required DateTime nextRunDate,
    DateTime? endDate,
    String? note,
    bool autoPost = false,
  }) async {
    try {
      final row = await _client
          .from('recurring_transactions')
          .insert({
            'user_id': _userId,
            'wallet_id': walletId,
            'category_id': categoryId,
            'amount': amount,
            'type': type.value,
            'note': note,
            'frequency': frequency.value,
            'interval': interval,
            'start_date': _dateOnly(startDate),
            'next_run_date': _dateOnly(nextRunDate),
            'end_date': endDate == null ? null : _dateOnly(endDate),
            'auto_post': autoPost,
          })
          .select('id')
          .single();
      return row['id'] as String;
    } on PostgrestException catch (e, st) {
      AppLogger.error('Create recurring transaction failed', e, st);
      throw AppException(e.message, code: e.code);
    } catch (e, st) {
      if (e is AppException) rethrow;
      AppLogger.error('Create recurring transaction failed', e, st);
      throw const AppException('errorConnection');
    }
  }

  Future<void> updateRecurringTransaction({
    required String id,
    required double amount,
    required TransactionType type,
    required String walletId,
    required String categoryId,
    required RecurringFrequency frequency,
    required int interval,
    required DateTime startDate,
    required DateTime nextRunDate,
    required bool isActive,
    DateTime? endDate,
    String? note,
    bool autoPost = false,
    RecurringApplyMode applyMode = RecurringApplyMode.futureOnly,
  }) async {
    try {
      await _client.rpc(
        'update_personal_recurring_transaction',
        params: {
          'p_id': id,
          'p_amount': amount,
          'p_type': type.value,
          'p_wallet_id': walletId,
          'p_category_id': categoryId,
          'p_frequency': frequency.value,
          'p_interval': interval,
          'p_start_date': _dateOnly(startDate),
          'p_next_run_date': _dateOnly(nextRunDate),
          'p_is_active': isActive,
          'p_end_date': endDate == null ? null : _dateOnly(endDate),
          'p_note': note,
          'p_auto_post': autoPost,
          'p_apply_mode': applyMode.name.toSnakeCase(),
        },
      );
    } on PostgrestException catch (e, st) {
      AppLogger.error('Update recurring transaction failed', e, st);
      throw AppException(e.message, code: e.code);
    } catch (e, st) {
      if (e is AppException) rethrow;
      AppLogger.error('Update recurring transaction failed', e, st);
      throw const AppException('errorConnection');
    }
  }

  Future<int> postDueTransactions({required DateTime through}) async {
    try {
      final response = await _client.rpc(
        'post_due_personal_recurring_transactions',
        params: {'p_limit': 500, 'p_through': _dateOnly(through)},
      );
      return (response as num?)?.toInt() ?? 0;
    } on PostgrestException catch (e, st) {
      AppLogger.error('Post due recurring transactions failed', e, st);
      throw AppException(e.message, code: e.code);
    } catch (e, st) {
      if (e is AppException) rethrow;
      AppLogger.error('Post due recurring transactions failed', e, st);
      throw const AppException('errorConnection');
    }
  }

  Future<void> deleteRecurringTransaction(
    String id, {
    bool deleteGeneratedTransactions = false,
  }) async {
    try {
      await _client.rpc(
        'delete_personal_recurring_transaction',
        params: {'p_id': id, 'p_delete_generated': deleteGeneratedTransactions},
      );
    } on PostgrestException catch (e, st) {
      AppLogger.error('Delete recurring transaction failed', e, st);
      throw AppException(e.message, code: e.code);
    } catch (e, st) {
      if (e is AppException) rethrow;
      AppLogger.error('Delete recurring transaction failed', e, st);
      throw const AppException('errorConnection');
    }
  }

  // Postgres `date` columns want a bare YYYY-MM-DD (no timezone shift).
  String _dateOnly(DateTime date) {
    final local = date.toLocal();
    final month = local.month.toString().padLeft(2, '0');
    final day = local.day.toString().padLeft(2, '0');
    return '${local.year}-$month-$day';
  }

  PostgrestFilterBuilder<PostgrestList> _baseSelect() {
    return _client.from('recurring_transactions').select('''
          id,
          amount,
          type,
          note,
          frequency,
          interval,
          start_date,
          next_run_date,
          end_date,
          auto_post,
          is_active,
          last_run_date,
          wallet:wallets!inner(id,name,color),
          category:categories!inner(id,name,color)
        ''');
  }

  List<RecurringTransaction> _mapList(dynamic rows) {
    return (rows as List<dynamic>)
        .cast<Map<String, dynamic>>()
        .map(RecurringTransaction.fromMap)
        .toList();
  }
}

extension on String {
  String toSnakeCase() {
    return replaceAllMapped(
      RegExp('[A-Z]'),
      (match) => '_${match.group(0)!.toLowerCase()}',
    );
  }
}
