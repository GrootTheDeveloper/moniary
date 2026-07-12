import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/supabase/app_exception.dart';
import '../../../shared/utils/app_logger.dart';

class BudgetLimitRecord {
  const BudgetLimitRecord({required this.limitAmount, this.warningRatio = 0.9});

  final double limitAmount;
  final double warningRatio;
}

abstract interface class BudgetLimitDataSource {
  Future<Map<String, BudgetLimitRecord>> fetchLimits(DateTime month);

  Future<void> setLimit({
    required DateTime month,
    required String categoryId,
    required double amount,
    required double warningRatio,
  });
}

class SupabaseBudgetLimitDataSource implements BudgetLimitDataSource {
  SupabaseBudgetLimitDataSource(this._client);

  final SupabaseClient _client;

  String get _userId {
    final id = _client.auth.currentSession?.user.id;
    if (id == null) {
      throw const AppException('errorGeneric', code: 'AUTH_REQUIRED');
    }
    return id;
  }

  @override
  Future<Map<String, BudgetLimitRecord>> fetchLimits(DateTime month) async {
    try {
      final monthStart = _monthStart(month);
      final rows = await _client
          .from('category_budget_limits')
          .select('category_id, limit_amount, warning_ratio')
          .eq('user_id', _userId)
          .eq('month_start', monthStart);
      return {
        for (final row in (rows as List<dynamic>).cast<Map<String, dynamic>>())
          row['category_id'] as String: BudgetLimitRecord(
            limitAmount: (row['limit_amount'] as num).toDouble(),
            warningRatio: ((row['warning_ratio'] as num?)?.toDouble() ?? 0.9)
                .clamp(0.5, 1),
          ),
      };
    } on PostgrestException catch (error, stackTrace) {
      AppLogger.error(
        'Failed to load category budget limits',
        error,
        stackTrace,
      );
      throw AppException(error.message, code: error.code);
    } catch (error, stackTrace) {
      if (error is AppException) rethrow;
      AppLogger.error(
        'Failed to load category budget limits',
        error,
        stackTrace,
      );
      throw const AppException(
        'errorConnection',
        code: 'BUDGET_LIMIT_LOAD_FAILED',
      );
    }
  }

  @override
  Future<void> setLimit({
    required DateTime month,
    required String categoryId,
    required double amount,
    required double warningRatio,
  }) async {
    try {
      final monthStart = _monthStart(month);
      if (amount <= 0) {
        await _client
            .from('category_budget_limits')
            .delete()
            .eq('user_id', _userId)
            .eq('category_id', categoryId)
            .eq('month_start', monthStart);
        return;
      }
      await _client.from('category_budget_limits').upsert({
        'user_id': _userId,
        'category_id': categoryId,
        'month_start': monthStart,
        'limit_amount': amount,
        'warning_ratio': warningRatio.clamp(0.5, 1),
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      }, onConflict: 'user_id,category_id,month_start');
    } on PostgrestException catch (error, stackTrace) {
      AppLogger.error(
        'Failed to save category budget limit',
        error,
        stackTrace,
      );
      throw AppException(error.message, code: error.code);
    } catch (error, stackTrace) {
      if (error is AppException) rethrow;
      AppLogger.error(
        'Failed to save category budget limit',
        error,
        stackTrace,
      );
      throw const AppException(
        'errorConnection',
        code: 'BUDGET_LIMIT_SAVE_FAILED',
      );
    }
  }

  String _monthStart(DateTime month) {
    final value = DateTime.utc(month.year, month.month);
    return value.toIso8601String().substring(0, 10);
  }
}

class MockBudgetLimitDataSource implements BudgetLimitDataSource {
  static final Map<String, Map<String, BudgetLimitRecord>> _limits = {};

  @override
  Future<Map<String, BudgetLimitRecord>> fetchLimits(DateTime month) async {
    _seedMonthIfEmpty(month);
    return Map<String, BudgetLimitRecord>.from(
      _limits[_key(month)] ?? const {},
    );
  }

  @override
  Future<void> setLimit({
    required DateTime month,
    required String categoryId,
    required double amount,
    required double warningRatio,
  }) async {
    final values = _limits.putIfAbsent(_key(month), () => {});
    if (amount <= 0) {
      values.remove(categoryId);
    } else {
      values[categoryId] = BudgetLimitRecord(
        limitAmount: amount,
        warningRatio: warningRatio.clamp(0.5, 1),
      );
    }
  }

  static void clear() => _limits.clear();

  String _key(DateTime month) =>
      '${month.year}-${month.month.toString().padLeft(2, '0')}';

  void _seedMonthIfEmpty(DateTime month) {
    final key = _key(month);
    if (_limits.containsKey(key)) return;
    _limits[key] = const {
      'mock-cat-food': BudgetLimitRecord(limitAmount: 210000),
      'mock-cat-shopping': BudgetLimitRecord(limitAmount: 230000),
      'mock-cat-transport': BudgetLimitRecord(limitAmount: 130000),
    };
  }
}
