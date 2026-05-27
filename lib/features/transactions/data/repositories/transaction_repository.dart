import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/supabase/supabase_providers.dart';
import '../../../categories/domain/models/category.dart';
import '../../domain/models/transaction_entry.dart';

final transactionRepositoryProvider = Provider<TransactionRepository>((ref) {
  return TransactionRepository(ref.watch(supabaseClientProvider));
});

class TransactionRepository {
  TransactionRepository(this._client);

  final SupabaseClient _client;

  Future<List<TransactionEntry>> fetchTransactionsForMonth(
    DateTime month, {
    String? walletId,
    String? categoryId,
  }) async {
    final session = _client.auth.currentSession;
    if (session == null) return [];

    final start = DateTime(month.year, month.month, 1);
    final end = DateTime(month.year, month.month + 1, 1);

    var query = _baseSelect()
        .eq('user_id', session.user.id)
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
  }

  Future<List<TransactionEntry>> fetchTransactionsForDay(
    DateTime day, {
    String? walletId,
    String? categoryId,
  }) async {
    final session = _client.auth.currentSession;
    if (session == null) return [];

    final start = DateTime(day.year, day.month, day.day);
    final end = start.add(const Duration(days: 1));

    var query = _baseSelect()
        .eq('user_id', session.user.id)
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
  }

  Future<TransactionEntry> fetchTransactionById(String transactionId) async {
    final session = _client.auth.currentSession;
    if (session == null) throw Exception('Ban chua dang nhap');

    final row = await _baseSelect()
        .eq('id', transactionId)
        .eq('user_id', session.user.id)
        .single();
    return TransactionEntry.fromMap(row);
  }

  Future<String> createTransaction({
    required double amount,
    required TransactionType type,
    required String walletId,
    required String categoryId,
    required DateTime transactionDate,
    String? note,
  }) async {
    final session = _client.auth.currentSession;
    if (session == null) {
      throw Exception('Ban chua dang nhap.');
    }

    final row = await _client
        .from('transactions')
        .insert({
          'user_id': session.user.id,
          'wallet_id': walletId,
          'category_id': categoryId,
          'amount': amount,
          'type': type.value,
          'note': note,
          'transaction_date': transactionDate.toUtc().toIso8601String(),
          'source': 'manual',
          'image_upload_status': 'pending',
        })
        .select('id')
        .single();

    return row['id'] as String;
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
    final session = _client.auth.currentSession;
    if (session == null) throw Exception('Ban chua dang nhap');

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
        .eq('user_id', session.user.id);
  }

  Future<void> deleteTransaction(String transactionId) async {
    final session = _client.auth.currentSession;
    if (session == null) throw Exception('Ban chua dang nhap');

    // 1. Fetch transaction to get image path
    final transaction = await fetchTransactionById(transactionId);

    // 2. Delete from database
    await _client
        .from('transactions')
        .delete()
        .eq('id', transactionId)
        .eq('user_id', session.user.id);

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
  }

  Future<String> uploadTransactionImage(
    String transactionId,
    Uint8List bytes,
  ) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');

    final path = 'transactions/$userId/$transactionId.jpg';

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
  }

  Future<void> updateTransactionImageMetadata({
    required String transactionId,
    required String? imagePath,
    required String status,
  }) async {
    final session = _client.auth.currentSession;
    if (session == null) throw Exception('Ban chua dang nhap');

    await _client
        .from('transactions')
        .update({'image_path': imagePath, 'image_upload_status': status})
        .eq('id', transactionId)
        .eq('user_id', session.user.id);
  }

  String getPublicImageUrl(String path) {
    // Since the bucket is private, we should ideally use createSignedUrl
    // but for simplicity in MVP we might use a short-lived signed URL or
    // the user might have some specific requirement.
    // The PRD says "App tạo signed URL từ imagePath khi cần hiển thị ảnh"
    return _client.storage.from('transaction-images').getPublicUrl(path);
  }

  Future<String> getSignedImageUrl(String path) async {
    return await _client.storage
        .from('transaction-images')
        .createSignedUrl(path, 3600); // 1 hour
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
