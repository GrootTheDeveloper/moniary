import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/supabase/app_exception.dart';
import '../../../../core/supabase/supabase_providers.dart';
import '../../../categories/domain/models/category.dart';
import '../../domain/models/transaction_entry.dart';

final transactionRepositoryProvider = Provider<TransactionRepository>((ref) {
  return TransactionRepository(ref.watch(supabaseClientProvider));
});

class TransactionRepository {
  TransactionRepository(this._client);

  final SupabaseClient _client;

  String get _userId {
    final uid = _client.auth.currentSession?.user.id;
    if (uid == null) throw const AppException('Bạn chưa đăng nhập.');
    return uid;
  }

  Future<List<TransactionEntry>> fetchTransactionsForMonth(
    DateTime month, {
    String? walletId,
    String? categoryId,
  }) async {
    try {
      final uid = _userId;

      final start = DateTime(month.year, month.month, 1);
      final end = DateTime(month.year, month.month + 1, 1);

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

      final rows = await query.order('transaction_date');

      return _mapList(rows);
    } on PostgrestException catch (e) {
      throw AppException(e.message, code: e.code);
    } catch (e) {
      if (e is AppException) rethrow;
      throw const AppException('Lỗi kết nối. Vui lòng thử lại.');
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

      final rows = await query.order('transaction_date', ascending: false);

      return _mapList(rows);
    } on PostgrestException catch (e) {
      throw AppException(e.message, code: e.code);
    } catch (e) {
      if (e is AppException) rethrow;
      throw const AppException('Lỗi kết nối. Vui lòng thử lại.');
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
    } on PostgrestException catch (e) {
      throw AppException(e.message, code: e.code);
    } catch (e) {
      if (e is AppException) rethrow;
      throw const AppException('Lỗi kết nối. Vui lòng thử lại.');
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
            'image_upload_status': 'pending',
          })
          .select('id')
          .single();

      return row['id'] as String;
    } on PostgrestException catch (e) {
      throw AppException(e.message, code: e.code);
    } catch (e) {
      if (e is AppException) rethrow;
      throw const AppException('Lỗi kết nối. Vui lòng thử lại.');
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
          })
          .eq('id', transactionId)
          .eq('user_id', uid);
    } on PostgrestException catch (e) {
      throw AppException(e.message, code: e.code);
    } catch (e) {
      if (e is AppException) rethrow;
      throw const AppException('Lỗi kết nối. Vui lòng thử lại.');
    }
  }

  Future<void> deleteTransaction(String transactionId) async {
    try {
      final uid = _userId;

      // 1. Fetch transaction to get image path
      final transaction = await fetchTransactionById(transactionId);

      // 2. Delete from database
      await _client
          .from('transactions')
          .delete()
          .eq('id', transactionId)
          .eq('user_id', uid);

      // 3. Cleanup storage if needed
      if (transaction.imagePath != null) {
        try {
          await _client.storage.from('transaction-images').remove([
            transaction.imagePath!,
          ]);
        } catch (e) {
          // Log error but don't fail transaction deletion
        }
      }
    } on PostgrestException catch (e) {
      throw AppException(e.message, code: e.code);
    } catch (e) {
      if (e is AppException) rethrow;
      throw const AppException('Lỗi kết nối. Vui lòng thử lại.');
    }
  }

  Future<String> uploadTransactionImage(
    String transactionId,
    Uint8List bytes,
  ) async {
    try {
      final uid = _userId;

      final path = 'transactions/$uid/$transactionId.jpg';

      await _client.storage
          .from('transaction-images')
          .uploadBinary(
            path,
            bytes,
            fileOptions: const FileOptions(
              contentType: 'image/jpeg',
              upsert: true,
            ),
          );

      return path;
    } on PostgrestException catch (e) {
      throw AppException(e.message, code: e.code);
    } catch (e) {
      if (e is AppException) rethrow;
      throw const AppException('Lỗi kết nối. Vui lòng thử lại.');
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
    } on PostgrestException catch (e) {
      throw AppException(e.message, code: e.code);
    } catch (e) {
      if (e is AppException) rethrow;
      throw const AppException('Lỗi kết nối. Vui lòng thử lại.');
    }
  }

  Future<String> getSignedImageUrl(String path) async {
    try {
      // getSignedImageUrl does not need user session strictly for generating url, 
      // but to be consistent with wrapping MỌI public method and duplicate check, 
      // let's wrap it. Since _userId isn't required by the client call, we just try/catch.
      return await _client.storage
          .from('transaction-images')
          .createSignedUrl(path, 3600); // 1 hour
    } on PostgrestException catch (e) {
      throw AppException(e.message, code: e.code);
    } catch (e) {
      if (e is AppException) rethrow;
      throw const AppException('Lỗi kết nối. Vui lòng thử lại.');
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
}
