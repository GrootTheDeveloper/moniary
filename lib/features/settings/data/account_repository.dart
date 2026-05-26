import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/supabase/supabase_providers.dart';

final accountRepositoryProvider = Provider<AccountRepository>((ref) {
  return AccountRepository(ref.watch(supabaseClientProvider));
});

class AccountRepository {
  AccountRepository(this._client);

  final SupabaseClient _client;

  Future<File> exportTransactionsCsv() async {
    final session = _client.auth.currentSession;
    if (session == null) {
      throw Exception('Ban chua dang nhap.');
    }

    final rows = await _client
        .from('transactions')
        .select('''
          id,
          amount,
          type,
          note,
          image_path,
          transaction_date,
          created_at,
          wallet:wallets!inner(name),
          category:categories!inner(name)
        ''')
        .eq('user_id', session.user.id)
        .order('transaction_date', ascending: false);

    final csv = StringBuffer()
      ..writeln(
        [
          'id',
          'loai',
          'so_tien',
          'vi',
          'danh_muc',
          'ghi_chu',
          'ngay_giao_dich',
          'duong_dan_anh',
          'ngay_tao',
        ].map(_csvCell).join(','),
      );

    for (final row in (rows as List<dynamic>).cast<Map<String, dynamic>>()) {
      final wallet = row['wallet'] as Map<String, dynamic>? ?? const {};
      final category = row['category'] as Map<String, dynamic>? ?? const {};
      csv.writeln(
        [
          row['id'],
          row['type'] == 'income' ? 'Thu' : 'Chi',
          row['amount'],
          wallet['name'],
          category['name'],
          row['note'],
          _formatDate(row['transaction_date'] as String?),
          row['image_path'],
          _formatDate(row['created_at'] as String?),
        ].map(_csvCell).join(','),
      );
    }

    final directory = await getApplicationDocumentsDirectory();
    final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final file = File('${directory.path}/moniary_export_$timestamp.csv');
    return file.writeAsString(csv.toString(), encoding: utf8);
  }

  Future<void> deleteAccount() async {
    final session = _client.auth.currentSession;
    if (session == null) {
      throw Exception('Ban chua dang nhap.');
    }

    await _client.functions.invoke('delete-account');
    await _client.auth.signOut();
  }

  static String _formatDate(String? value) {
    if (value == null || value.isEmpty) {
      return '';
    }
    final date = DateTime.tryParse(value);
    if (date == null) {
      return value;
    }
    return DateFormat('yyyy-MM-dd HH:mm:ss').format(date.toLocal());
  }

  static String _csvCell(Object? value) {
    final text = (value ?? '').toString().replaceAll('"', '""');
    return '"$text"';
  }
}
