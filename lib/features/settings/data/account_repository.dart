import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/supabase/supabase_providers.dart';
import 'pdf_report.dart';
import 'xlsx_workbook.dart';

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

    final rows = await _fetchTransactionRows(session.user.id);

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

  Future<File> exportTransactionsXlsx() async {
    final session = _client.auth.currentSession;
    if (session == null) {
      throw Exception('Ban chua dang nhap.');
    }

    final rows = await _fetchTransactionRows(session.user.id);
    final workbookRows = <List<Object?>>[
      [
        'ID',
        'Loại',
        'Số tiền',
        'Ví',
        'Danh mục',
        'Ghi chú',
        'Ngày giao dịch',
        'Đường dẫn ảnh',
        'Ngày tạo',
      ],
      ...rows.map((row) {
        final wallet = row['wallet'] as Map<String, dynamic>? ?? const {};
        final category = row['category'] as Map<String, dynamic>? ?? const {};
        return [
          row['id'],
          row['type'] == 'income' ? 'Thu' : 'Chi',
          row['amount'],
          wallet['name'],
          category['name'],
          row['note'],
          _formatDate(row['transaction_date'] as String?),
          row['image_path'],
          _formatDate(row['created_at'] as String?),
        ];
      }),
    ];

    final bytes = XlsxWorkbook(sheetName: 'Transactions', rows: workbookRows).build();
    final directory = await getApplicationDocumentsDirectory();
    final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final file = File('${directory.path}/moniary_export_$timestamp.xlsx');
    return file.writeAsBytes(bytes, flush: true);
  }

  Future<File> exportTransactionsPdf() async {
    final session = _client.auth.currentSession;
    if (session == null) {
      throw Exception('Ban chua dang nhap.');
    }

    final rows = await _fetchTransactionRows(session.user.id);
    final generatedAt = DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());
    final income = rows
        .where((row) => row['type'] == 'income')
        .fold<double>(0, (sum, row) => sum + (row['amount'] as num).toDouble());
    final expense = rows
        .where((row) => row['type'] == 'expense')
        .fold<double>(0, (sum, row) => sum + (row['amount'] as num).toDouble());

    final lines = <String>[
      'Generated: $generatedAt',
      'Transactions: ${rows.length}',
      'Income total: ${income.toStringAsFixed(0)}',
      'Expense total: ${expense.toStringAsFixed(0)}',
      'Recent transactions:',
      ...rows.take(24).map((row) {
        final wallet = row['wallet'] as Map<String, dynamic>? ?? const {};
        final category = row['category'] as Map<String, dynamic>? ?? const {};
        final type = row['type'] == 'income' ? 'Income' : 'Expense';
        final amount = (row['amount'] as num).toStringAsFixed(0);
        final date = _formatDate(row['transaction_date'] as String?);
        return '$date | $type | $amount | ${wallet['name'] ?? ''} | ${category['name'] ?? ''}';
      }),
    ];

    final bytes = PdfReport(lines: lines).build();
    final directory = await getApplicationDocumentsDirectory();
    final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final file = File('${directory.path}/moniary_export_$timestamp.pdf');
    return file.writeAsBytes(bytes, flush: true);
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

  Future<List<Map<String, dynamic>>> _fetchTransactionRows(String userId) async {
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
        .eq('user_id', userId)
        .order('transaction_date', ascending: false);

    return (rows as List<dynamic>).cast<Map<String, dynamic>>();
  }
}
