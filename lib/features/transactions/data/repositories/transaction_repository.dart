import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/supabase/app_exception.dart';
import '../../../../core/supabase/supabase_providers.dart';
import '../../../../shared/utils/app_logger.dart';
import '../../../categories/domain/models/category.dart';
import '../../domain/models/transaction_entry.dart';
import '../../domain/models/transaction_search_filter.dart';

final transactionRepositoryProvider = Provider<TransactionRepository>((ref) {
  return TransactionRepository(ref.watch(supabaseClientProvider));
});

class TransactionRepository {
  TransactionRepository(this._client);

  final SupabaseClient _client;

  String get _userId {
    final uid = _client.auth.currentSession?.user.id;
    if (uid == null) {
      throw const AppException('User not logged in', code: 'AUTH_REQUIRED');
    }
    return uid;
  }

  Future<List<TransactionEntry>> fetchTransactionsForMonth(
    DateTime month, {
    String? walletId,
    String? categoryId,
  }) async {
    final start = DateTime(month.year, month.month, 1);
    final end = DateTime(month.year, month.month + 1, 1);
    return fetchTransactionsForRange(
      start: start,
      end: end,
      walletId: walletId,
      categoryId: categoryId,
    );
  }

  Future<List<TransactionEntry>> fetchTransactionsForRange({
    required DateTime start,
    required DateTime end,
    String? walletId,
    String? categoryId,
  }) async {
    try {
      final uid = _userId;

      var query = _baseSelect()
          .eq('user_id', uid)
          .gte('transaction_date', start.toUtc().toIso8601String())
          .lt('transaction_date', end.toUtc().toIso8601String());

      if (walletId != null) {
        query = query.eq('wallet_id', walletId);
      }
      if (categoryId != null) {
        query = query.eq('category_id', categoryId);
      }

      final rows = await query
          .order('is_important', ascending: false)
          .order('transaction_date', ascending: false);

      return _mapList(rows);
    } on PostgrestException catch (e, st) {
      AppLogger.error('Lá»—i cÆ¡ sá»Ÿ dá»¯ liá»‡u', e, st);
      throw AppException(e.message, code: e.code);
    } catch (e, st) {
      if (e is AppException) rethrow;
      AppLogger.error('Lá»—i káº¿t ná»‘i', e, st);
      throw const AppException('errorConnection');
    }
  }

  Future<List<TransactionEntry>> fetchStarredTransactions() async {
    try {
      final uid = _userId;

      // Use the existing _baseSelect() helper to get all required columns
      final rows = await _baseSelect()
          .eq('user_id', uid)
          .eq('is_important', true)
          .order('transaction_date', ascending: false);

      return _mapList(rows);
    } on PostgrestException catch (e, st) {
      AppLogger.error('Lỗi truy vấn danh sách yêu thích', e, st);
      throw AppException(e.message, code: e.code);
    } catch (e, st) {
      if (e is AppException) rethrow;
      AppLogger.error('Lỗi kết nối khi lấy danh sách yêu thích', e, st);
      throw const AppException('errorConnection');
    }
  }

  Future<List<TransactionEntry>> searchTransactions(
    TransactionSearchFilter filter,
  ) async {
    final normalizedQuery = filter.query.trim().toLowerCase();

    try {
      final uid = _userId;

      var query = _baseSelect().eq('user_id', uid);
      if (filter.type != null) {
        query = query.eq('type', filter.type!.value);
      }
      if (filter.categoryId != null) {
        query = query.eq('category_id', filter.categoryId!);
      }
      if (filter.importance != null) {
        query = query.eq(
          'is_important',
          filter.importance == TransactionImportanceFilter.important,
        );
      }
      if (filter.subscription != null) {
        // A subscription transaction is any auto-posted one (source =
        // 'recurring'). This is more reliable than recurring_transaction_id,
        // which is only set on transactions created after that column existed.
        query =
            filter.subscription == TransactionSubscriptionFilter.subscription
            ? query.eq('source', 'recurring')
            : query.not('source', 'eq', 'recurring');
      }
      if (filter.dateFrom != null) {
        query = query.gte(
          'transaction_date',
          _startOfDay(filter.dateFrom!).toUtc().toIso8601String(),
        );
      }
      if (filter.dateTo != null) {
        query = query.lt(
          'transaction_date',
          _startOfDay(
            filter.dateTo!,
          ).add(const Duration(days: 1)).toUtc().toIso8601String(),
        );
      }
      if (filter.minAmount != null) {
        query = query.gte('amount', filter.minAmount!);
      }
      if (filter.maxAmount != null) {
        query = query.lte('amount', filter.maxAmount!);
      }

      final rows = await query.order('transaction_date', ascending: false);
      var results = _mapList(rows);
      if (normalizedQuery.isNotEmpty) {
        results = results
            .where((tx) => _matchesSearchQuery(tx, normalizedQuery))
            .toList();
      }
      _sortStarredThenDate(results);
      return results;
    } on PostgrestException catch (e, st) {
      AppLogger.error('Search transactions failed', e, st);
      throw AppException(e.message, code: e.code);
    } catch (e, st) {
      if (e is AppException) rethrow;
      AppLogger.error('Search transactions failed', e, st);
      throw const AppException('errorConnection');
    }
  }

  Future<List<TransactionEntry>> fetchTransactionsForDay(
    DateTime day, {
    String? walletId,
    String? categoryId,
  }) async {
    try {
      final uid = _userId;

      final start = DateTime(day.year, day.month, day.day);
      final end = start.add(const Duration(days: 1));

      var query = _baseSelect()
          .eq('user_id', uid)
          .gte('transaction_date', start.toUtc().toIso8601String())
          .lt('transaction_date', end.toUtc().toIso8601String());

      if (walletId != null) {
        query = query.eq('wallet_id', walletId);
      }
      if (categoryId != null) {
        query = query.eq('category_id', categoryId);
      }

      final rows = await query
          .order('is_important', ascending: false)
          .order('transaction_date', ascending: false);

      return _mapList(rows);
    } on PostgrestException catch (e, st) {
      AppLogger.error('Lá»—i cÆ¡ sá»Ÿ dá»¯ liá»‡u', e, st);
      throw AppException(e.message, code: e.code);
    } catch (e, st) {
      if (e is AppException) rethrow;
      AppLogger.error('Lá»—i káº¿t ná»‘i', e, st);
      throw const AppException('errorConnection');
    }
  }

  Future<TransactionEntry> fetchTransactionById(String transactionId) async {
    try {
      final uid = _userId;

      final row = await _baseSelect()
          .eq('id', transactionId)
          .eq('user_id', uid)
          .single();
      return TransactionEntry.fromMap(row);
    } on PostgrestException catch (e, st) {
      AppLogger.error('Lá»—i cÆ¡ sá»Ÿ dá»¯ liá»‡u', e, st);
      throw AppException(e.message, code: e.code);
    } catch (e, st) {
      if (e is AppException) rethrow;
      AppLogger.error('Lá»—i káº¿t ná»‘i', e, st);
      throw const AppException('errorConnection');
    }
  }

  Future<String> createTransaction({
    required double amount,
    required TransactionType type,
    required String walletId,
    required String categoryId,
    required DateTime transactionDate,
    String? note,
    String? merchantName,
    String source = 'manual',
    bool isImportant = false,
    String? recurringTransactionId,
    String imageUploadStatus = 'none',
  }) async {
    try {
      final uid = _userId;

      final row = await _client
          .from('transactions')
          .insert({
            'user_id': uid,
            'wallet_id': walletId,
            'category_id': categoryId,
            'amount': amount,
            'type': type.value,
            'note': note,
            'merchant_name': merchantName,
            'transaction_date': transactionDate.toUtc().toIso8601String(),
            'source': source,
            'image_upload_status': imageUploadStatus,
            'is_important': isImportant,
            'recurring_transaction_id': recurringTransactionId,
          })
          .select('id')
          .single();

      return row['id'] as String;
    } on PostgrestException catch (e, st) {
      AppLogger.error('Lá»—i cÆ¡ sá»Ÿ dá»¯ liá»‡u', e, st);
      throw AppException(e.message, code: e.code);
    } catch (e, st) {
      if (e is AppException) rethrow;
      AppLogger.error('Lá»—i káº¿t ná»‘i', e, st);
      throw const AppException('errorConnection');
    }
  }

  Future<void> updateTransaction({
    required String transactionId,
    required double amount,
    required TransactionType type,
    required String walletId,
    required String categoryId,
    required DateTime transactionDate,
    String? note,
    bool isImportant = false,
  }) async {
    try {
      final uid = _userId;

      await _client
          .from('transactions')
          .update({
            'wallet_id': walletId,
            'category_id': categoryId,
            'amount': amount,
            'type': type.value,
            'note': note,
            'transaction_date': transactionDate.toUtc().toIso8601String(),
            'is_important': isImportant,
          })
          .eq('id', transactionId)
          .eq('user_id', uid);
    } on PostgrestException catch (e, st) {
      AppLogger.error('Lá»—i cÆ¡ sá»Ÿ dá»¯ liá»‡u', e, st);
      throw AppException(e.message, code: e.code);
    } catch (e, st) {
      if (e is AppException) rethrow;
      AppLogger.error('Lá»—i káº¿t ná»‘i', e, st);
      throw const AppException('errorConnection');
    }
  }

  /// Imports a validated batch in one database transaction.
  ///
  /// [batchKey] is stable for retries of the same confirmation attempt. The
  /// server returns the original count if a committed response was lost.
  Future<int> importTransactionsAtomically({
    required String batchKey,
    required String walletId,
    required List<Map<String, Object?>> rows,
  }) async {
    try {
      final response = await _client.rpc(
        'import_personal_transactions',
        params: {
          'p_wallet_id': walletId,
          'p_batch_key': batchKey,
          'p_rows': rows,
        },
      );
      if (response is int) return response;
      if (response is num) return response.toInt();
      throw const AppException(
        'Invalid import response',
        code: 'IMPORT_INVALID_RESPONSE',
      );
    } on PostgrestException catch (e, st) {
      AppLogger.error('Atomic transaction import failed', e, st);
      throw AppException(e.message, code: e.code);
    } catch (e, st) {
      if (e is AppException) rethrow;
      AppLogger.error('Atomic transaction import failed', e, st);
      throw const AppException('errorConnection');
    }
  }

  Future<void> toggleTransactionImportance(
    String transactionId,
    bool isImportant,
  ) async {
    try {
      final uid = _userId;

      await _client
          .from('transactions')
          .update({'is_important': isImportant})
          .eq('id', transactionId)
          .eq('user_id', uid);
    } on PostgrestException catch (e, st) {
      AppLogger.error('Lá»—i cÆ¡ sá»Ÿ dá»¯ liá»‡u', e, st);
      throw AppException(e.message, code: e.code);
    } catch (e, st) {
      if (e is AppException) rethrow;
      AppLogger.error('Lá»—i káº¿t ná»‘i', e, st);
      throw const AppException('errorConnection');
    }
  }

  Future<void> deleteTransaction(String transactionId) async {
    try {
      final uid = _userId;

      // Remove storage first. If storage cleanup fails, keep the financial
      // record so the user can retry without leaving an unreachable object.
      final transaction = await fetchTransactionById(transactionId);
      final deterministicPath = transactionImagePath(transactionId);
      final paths = <String>{deterministicPath};
      if (transaction.imagePath case final imagePath?) {
        paths.add(imagePath);
      }
      await _client.storage
          .from(AppConstants.storageBucket)
          .remove(paths.toList(growable: false));

      // Delete the financial record only after its private attachment is gone.
      await _client
          .from('transactions')
          .delete()
          .eq('id', transactionId)
          .eq('user_id', uid);
    } on PostgrestException catch (e, st) {
      AppLogger.error('Lá»—i cÆ¡ sá»Ÿ dá»¯ liá»‡u', e, st);
      throw AppException(e.message, code: e.code);
    } catch (e, st) {
      if (e is AppException) rethrow;
      AppLogger.error('Lá»—i káº¿t ná»‘i', e, st);
      throw const AppException('errorConnection');
    }
  }

  /// How many transactions were auto-posted from the given recurring rule.
  Future<int> countGeneratedTransactions(String recurringTransactionId) async {
    try {
      final rows = await _client
          .from('transactions')
          .select('id')
          .eq('user_id', _userId)
          .eq('recurring_transaction_id', recurringTransactionId);
      return (rows as List).length;
    } on PostgrestException catch (e, st) {
      AppLogger.error('Count generated transactions failed', e, st);
      throw AppException(e.message, code: e.code);
    } catch (e, st) {
      if (e is AppException) rethrow;
      AppLogger.error('Count generated transactions failed', e, st);
      throw const AppException('errorConnection');
    }
  }

  /// Updates the shared fields of every transaction generated by a rule, to
  /// match an edited rule. Deliberately leaves transaction_date, is_important
  /// and image untouched (a user may have adjusted those).
  Future<void> updateGeneratedTransactions({
    required String recurringTransactionId,
    required double amount,
    required TransactionType type,
    required String walletId,
    required String categoryId,
    String? note,
  }) async {
    try {
      await _client
          .from('transactions')
          .update({
            'wallet_id': walletId,
            'category_id': categoryId,
            'amount': amount,
            'type': type.value,
            'note': note,
          })
          .eq('user_id', _userId)
          .eq('recurring_transaction_id', recurringTransactionId);
    } on PostgrestException catch (e, st) {
      AppLogger.error('Update generated transactions failed', e, st);
      throw AppException(e.message, code: e.code);
    } catch (e, st) {
      if (e is AppException) rethrow;
      AppLogger.error('Update generated transactions failed', e, st);
      throw const AppException('errorConnection');
    }
  }

  /// Deletes every transaction generated by a rule.
  Future<void> deleteGeneratedTransactions(
    String recurringTransactionId,
  ) async {
    try {
      await _client
          .from('transactions')
          .delete()
          .eq('user_id', _userId)
          .eq('recurring_transaction_id', recurringTransactionId);
    } on PostgrestException catch (e, st) {
      AppLogger.error('Delete generated transactions failed', e, st);
      throw AppException(e.message, code: e.code);
    } catch (e, st) {
      if (e is AppException) rethrow;
      AppLogger.error('Delete generated transactions failed', e, st);
      throw const AppException('errorConnection');
    }
  }

  Future<String> uploadTransactionImage(
    String transactionId,
    Uint8List bytes,
  ) async {
    try {
      final path = transactionImagePath(transactionId);

      await _client.storage
          .from(AppConstants.storageBucket)
          .uploadBinary(
            path,
            bytes,
            fileOptions: const FileOptions(
              contentType: 'image/jpeg',
              upsert: true,
            ),
          );

      return path;
    } on PostgrestException catch (e, st) {
      AppLogger.error('Lá»—i cÆ¡ sá»Ÿ dá»¯ liá»‡u', e, st);
      throw AppException(e.message, code: e.code);
    } catch (e, st) {
      if (e is AppException) rethrow;
      AppLogger.error('Lá»—i káº¿t ná»‘i', e, st);
      throw const AppException('errorConnection');
    }
  }

  String transactionImagePath(String transactionId) {
    return 'transactions/$_userId/$transactionId.jpg';
  }

  Future<void> removeTransactionImage(String transactionId) async {
    try {
      await _client.storage.from(AppConstants.storageBucket).remove([
        transactionImagePath(transactionId),
      ]);
    } on StorageException catch (e, st) {
      AppLogger.error('Failed to remove transaction image', e, st);
      throw AppException(e.message, code: e.statusCode);
    } catch (e, st) {
      if (e is AppException) rethrow;
      AppLogger.error('Failed to remove transaction image', e, st);
      throw const AppException(
        'Failed to remove transaction image',
        code: 'TRANSACTION_IMAGE_DELETE_FAILED',
      );
    }
  }

  Future<void> updateTransactionImageMetadata({
    required String transactionId,
    required String? imagePath,
    required String status,
  }) async {
    try {
      final uid = _userId;

      await _client
          .from('transactions')
          .update({'image_path': imagePath, 'image_upload_status': status})
          .eq('id', transactionId)
          .eq('user_id', uid);
    } on PostgrestException catch (e, st) {
      AppLogger.error('Lá»—i cÆ¡ sá»Ÿ dá»¯ liá»‡u', e, st);
      throw AppException(e.message, code: e.code);
    } catch (e, st) {
      if (e is AppException) rethrow;
      AppLogger.error('Lá»—i káº¿t ná»‘i', e, st);
      throw const AppException('errorConnection');
    }
  }

  Future<String> getSignedImageUrl(String path) async {
    try {
      // getSignedImageUrl does not need user session strictly for generating url,
      // but to be consistent with wrapping Má»ŒI public method and duplicate check,
      // let's wrap it. Since _userId isn't required by the client call, we just try/catch.
      return await _client.storage
          .from(AppConstants.storageBucket)
          .createSignedUrl(path, AppConstants.signedUrlTtlSeconds);
    } on PostgrestException catch (e, st) {
      AppLogger.error('Lá»—i cÆ¡ sá»Ÿ dá»¯ liá»‡u', e, st);
      throw AppException(e.message, code: e.code);
    } catch (e, st) {
      if (e is AppException) rethrow;
      AppLogger.error('Lá»—i káº¿t ná»‘i', e, st);
      throw const AppException('errorConnection');
    }
  }

  Future<bool> hasAnyTransactions() async {
    try {
      final uid = _userId;
      final rows = await _client
          .from('transactions')
          .select('id')
          .eq('user_id', uid)
          .limit(1);
      return (rows as List).isNotEmpty;
    } on PostgrestException catch (e, st) {
      AppLogger.error('Check transactions existence failed', e, st);
      throw AppException(e.message, code: e.code);
    } catch (e, st) {
      if (e is AppException) rethrow;
      AppLogger.error('Check transactions existence failed', e, st);
      throw const AppException('errorConnection');
    }
  }

  PostgrestFilterBuilder<PostgrestList> _baseSelect() {
    return _client.from('transactions').select('''
          id,
          amount,
          type,
          note,
          image_path,
          transaction_date,
          is_important,
          recurring_transaction_id,
          wallet:wallets!inner(id,name,color),
          category:categories!inner(id,name,color)
        ''');
  }

  List<TransactionEntry> _mapList(dynamic rows) {
    return (rows as List<dynamic>)
        .cast<Map<String, dynamic>>()
        .map(TransactionEntry.fromMap)
        .toList();
  }

  void _sortStarredThenDate(List<TransactionEntry> list) {
    list.sort((a, b) {
      if (a.isImportant != b.isImportant) {
        return b.isImportant ? 1 : -1;
      }
      return b.transactionDate.compareTo(a.transactionDate);
    });
  }

  DateTime _startOfDay(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  bool _matchesSearchQuery(
    TransactionEntry transaction,
    String normalizedQuery,
  ) {
    final noteMatch =
        transaction.note?.toLowerCase().contains(normalizedQuery) ?? false;
    final categoryMatch = transaction.categoryName.toLowerCase().contains(
      normalizedQuery,
    );
    final walletMatch = transaction.walletName.toLowerCase().contains(
      normalizedQuery,
    );
    // Digits in the query are matched against the whole-number amount, so
    // typing "45000" finds a 45,000 transaction.
    final amountMatch = transaction.amount
        .toStringAsFixed(0)
        .contains(normalizedQuery);
    return noteMatch || categoryMatch || walletMatch || amountMatch;
  }
}
