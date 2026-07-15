import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/supabase/app_exception.dart';
import '../../../../core/supabase/supabase_providers.dart';
import '../../../../shared/utils/app_logger.dart';
import '../../../categories/data/repositories/category_repository.dart';
import '../../../categories/domain/models/category.dart';
import '../../../wallets/data/repositories/wallet_repository.dart';
import '../../../wallets/domain/models/wallet.dart';
import '../../domain/models/recurring_transaction.dart';

final recurringTransactionRepositoryProvider =
    Provider<RecurringTransactionRepository>((ref) {
      return RecurringTransactionRepository(
        ref.watch(supabaseClientProvider),
        useMockData: ref.watch(useMockDataModeProvider),
      );
    });

class RecurringTransactionRepository {
  RecurringTransactionRepository(this._client, {bool useMockData = false})
    : _useMockData = useMockData || !AppConstants.hasSupabaseConfig;

  final SupabaseClient _client;
  final bool _useMockData;

  static final List<RecurringTransaction> _mockRecurring = [];

  String get _userId {
    if (_useMockData) return 'mock-user-id';
    final uid = _client.auth.currentSession?.user.id;
    if (uid == null) {
      throw const AppException('User not logged in', code: 'AUTH_REQUIRED');
    }
    return uid;
  }

  Future<List<RecurringTransaction>> fetchRecurringTransactions() async {
    if (_useMockData) {
      final results = List<RecurringTransaction>.from(_mockRecurring);
      results.sort((a, b) => a.nextRunDate.compareTo(b.nextRunDate));
      return results;
    }
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
    if (_useMockData) {
      final id = 'mock-recur-${DateTime.now().millisecondsSinceEpoch}';
      final wallet = _mockWallet(walletId);
      final category = _mockCategory(categoryId, type);
      _mockRecurring.add(
        RecurringTransaction(
          id: id,
          amount: amount,
          type: type,
          note: note,
          walletId: walletId,
          walletName: wallet.name,
          walletColor: wallet.color,
          categoryId: categoryId,
          categoryName: category.name,
          categoryColor: category.color,
          frequency: frequency,
          interval: interval,
          startDate: startDate,
          nextRunDate: nextRunDate,
          endDate: endDate,
          autoPost: autoPost,
          isActive: true,
          lastRunDate: null,
        ),
      );
      return id;
    }
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
  }) async {
    if (_useMockData) {
      final index = _mockRecurring.indexWhere((item) => item.id == id);
      if (index == -1) return;
      final wallet = _mockWallet(walletId);
      final category = _mockCategory(categoryId, type);
      _mockRecurring[index] = RecurringTransaction(
        id: id,
        amount: amount,
        type: type,
        note: note,
        walletId: walletId,
        walletName: wallet.name,
        walletColor: wallet.color,
        categoryId: categoryId,
        categoryName: category.name,
        categoryColor: category.color,
        frequency: frequency,
        interval: interval,
        startDate: startDate,
        nextRunDate: nextRunDate,
        endDate: endDate,
        autoPost: autoPost,
        isActive: isActive,
        lastRunDate: _mockRecurring[index].lastRunDate,
      );
      return;
    }
    try {
      await _client
          .from('recurring_transactions')
          .update({
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
            'is_active': isActive,
          })
          .eq('id', id)
          .eq('user_id', _userId);
    } on PostgrestException catch (e, st) {
      AppLogger.error('Update recurring transaction failed', e, st);
      throw AppException(e.message, code: e.code);
    } catch (e, st) {
      if (e is AppException) rethrow;
      AppLogger.error('Update recurring transaction failed', e, st);
      throw const AppException('errorConnection');
    }
  }

  /// Moves a rule's schedule forward after the auto-post engine has
  /// materialized its due occurrences. Only touches the scheduling columns.
  Future<void> advanceSchedule({
    required String id,
    required DateTime nextRunDate,
    required DateTime? lastRunDate,
    required bool isActive,
  }) async {
    if (_useMockData) {
      final index = _mockRecurring.indexWhere((item) => item.id == id);
      if (index == -1) return;
      final current = _mockRecurring[index];
      _mockRecurring[index] = RecurringTransaction(
        id: current.id,
        amount: current.amount,
        type: current.type,
        note: current.note,
        walletId: current.walletId,
        walletName: current.walletName,
        walletColor: current.walletColor,
        categoryId: current.categoryId,
        categoryName: current.categoryName,
        categoryColor: current.categoryColor,
        frequency: current.frequency,
        interval: current.interval,
        startDate: current.startDate,
        nextRunDate: nextRunDate,
        endDate: current.endDate,
        autoPost: current.autoPost,
        isActive: isActive,
        lastRunDate: lastRunDate,
      );
      return;
    }
    try {
      await _client
          .from('recurring_transactions')
          .update({
            'next_run_date': _dateOnly(nextRunDate),
            'last_run_date': lastRunDate == null
                ? null
                : _dateOnly(lastRunDate),
            'is_active': isActive,
          })
          .eq('id', id)
          .eq('user_id', _userId);
    } on PostgrestException catch (e, st) {
      AppLogger.error('Advance recurring schedule failed', e, st);
      throw AppException(e.message, code: e.code);
    } catch (e, st) {
      if (e is AppException) rethrow;
      AppLogger.error('Advance recurring schedule failed', e, st);
      throw const AppException('errorConnection');
    }
  }

  Future<void> deleteRecurringTransaction(String id) async {
    if (_useMockData) {
      _mockRecurring.removeWhere((item) => item.id == id);
      return;
    }
    try {
      await _client
          .from('recurring_transactions')
          .delete()
          .eq('id', id)
          .eq('user_id', _userId);
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

  Wallet _mockWallet(String walletId) {
    return WalletRepository.mockWallets.firstWhere(
      (wallet) => wallet.id == walletId,
      orElse: () => Wallet(
        id: walletId,
        name: '',
        type: WalletType.cash,
        initialBalance: 0,
        isDefault: false,
        isActive: true,
        createdAt: DateTime.now(),
        icon: null,
        color: null,
      ),
    );
  }

  Category _mockCategory(String categoryId, TransactionType type) {
    return CategoryRepository.mockCategories.firstWhere(
      (category) => category.id == categoryId,
      orElse: () => Category(
        id: categoryId,
        name: '',
        type: type,
        icon: null,
        color: null,
        isDefault: false,
        isActive: true,
        createdAt: DateTime.now(),
      ),
    );
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
