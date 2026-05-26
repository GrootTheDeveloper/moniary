import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/supabase/supabase_providers.dart';
import '../domain/export_filters.dart';
import 'pdf_report.dart';
import 'xlsx_workbook.dart';

final accountRepositoryProvider = Provider<AccountRepository>((ref) {
  return AccountRepository(ref.watch(supabaseClientProvider));
});

class AccountRepository {
  AccountRepository(this._client);

  final SupabaseClient _client;

  Future<File> exportTransactionsCsv({ExportFilters filters = const ExportFilters()}) async {
    final session = _client.auth.currentSession;
    if (session == null) {
      throw Exception('Ban chua dang nhap.');
    }

    final exportRows = await _buildExportRows(session.user.id, filters: filters);

    final csv = StringBuffer()
      ..writeln(
        [
          'data_type',
          'id',
          'name',
          'type',
          'amount',
          'wallet',
          'category',
          'note',
          'transaction_date',
          'image_path',
          'created_at',
          'initial_balance',
          'is_default',
          'is_active',
        ].map(_csvCell).join(','),
      );

    for (final row in exportRows) {
      csv.writeln(row.map(_csvCell).join(','));
    }

    final directory = await getApplicationDocumentsDirectory();
    final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final file = File('${directory.path}/moniary_export_$timestamp.csv');
    return file.writeAsString(csv.toString(), encoding: utf8);
  }

  Future<File> exportTransactionsXlsx({ExportFilters filters = const ExportFilters()}) async {
    final session = _client.auth.currentSession;
    if (session == null) {
      throw Exception('Ban chua dang nhap.');
    }

    final exportRows = await _buildExportRows(session.user.id, filters: filters);
    final workbookRows = <List<Object?>>[
      [
        'Data type',
        'ID',
        'Name',
        'Type',
        'Amount',
        'Wallet',
        'Category',
        'Note',
        'Transaction date',
        'Image path',
        'Created at',
        'Initial balance',
        'Is default',
        'Is active',
      ],
      ...exportRows,
    ];

    final bytes = XlsxWorkbook(sheetName: 'Transactions', rows: workbookRows).build();
    final directory = await getApplicationDocumentsDirectory();
    final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final file = File('${directory.path}/moniary_export_$timestamp.xlsx');
    return file.writeAsBytes(bytes, flush: true);
  }

  Future<File> exportTransactionsPdf({ExportFilters filters = const ExportFilters()}) async {
    final session = _client.auth.currentSession;
    if (session == null) {
      throw Exception('Ban chua dang nhap.');
    }

    final transactions = filters.hasTransactions
        ? await _fetchTransactionRows(session.user.id, filters: filters)
        : <Map<String, dynamic>>[];
    final wallets = filters.hasWallets ? await _fetchWalletRows(session.user.id) : <Map<String, dynamic>>[];
    final categories = filters.hasCategories
        ? await _fetchCategoryRows(session.user.id)
        : <Map<String, dynamic>>[];
    final generatedAt = DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());
    final income = transactions
        .where((row) => row['type'] == 'income')
        .fold<double>(0, (sum, row) => sum + (row['amount'] as num).toDouble());
    final expense = transactions
        .where((row) => row['type'] == 'expense')
        .fold<double>(0, (sum, row) => sum + (row['amount'] as num).toDouble());

    final lines = <String>[
      'Generated: $generatedAt',
      'Data types: ${filters.dataTypes.map((type) => type.label).join(', ')}',
      'Transactions: ${transactions.length}',
      'Wallets: ${wallets.length}',
      'Categories: ${categories.length}',
      'Income total: ${income.toStringAsFixed(0)}',
      'Expense total: ${expense.toStringAsFixed(0)}',
      'Recent transactions:',
      ...transactions.take(20).map((row) {
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

  Future<File> createDeletionRequest({required String reason}) async {
    final session = _client.auth.currentSession;
    if (session == null) {
      throw Exception('Ban chua dang nhap.');
    }

    final timestamp = DateTime.now();
    final payload = {
      'type': 'account_deletion_request',
      'status': 'pending_manual_review',
      'created_at': timestamp.toIso8601String(),
      'user_id': session.user.id,
      'email': session.user.email,
      'reason': reason.trim(),
      'requested_scope': [
        'profile',
        'wallets',
        'categories',
        'transactions',
        'transaction_images',
      ],
    };

    final directory = await getApplicationDocumentsDirectory();
    final fileTimestamp = DateFormat('yyyyMMdd_HHmmss').format(timestamp);
    final file = File('${directory.path}/moniary_deletion_request_$fileTimestamp.json');
    return file.writeAsString(const JsonEncoder.withIndent('  ').convert(payload));
  }

  Future<File> createPrivacyRequest({
    required String requestType,
    required String message,
  }) async {
    final session = _client.auth.currentSession;
    if (session == null) {
      throw Exception('Ban chua dang nhap.');
    }

    final timestamp = DateTime.now();
    final payload = {
      'type': 'privacy_request',
      'status': 'pending_manual_review',
      'created_at': timestamp.toIso8601String(),
      'user_id': session.user.id,
      'email': session.user.email,
      'request_type': requestType,
      'message': message.trim(),
    };

    final directory = await getApplicationDocumentsDirectory();
    final fileTimestamp = DateFormat('yyyyMMdd_HHmmss').format(timestamp);
    final file = File('${directory.path}/moniary_privacy_request_$fileTimestamp.json');
    return file.writeAsString(const JsonEncoder.withIndent('  ').convert(payload));
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

  Future<List<Map<String, dynamic>>> _fetchTransactionRows(
    String userId, {
    ExportFilters filters = const ExportFilters(),
  }) async {
    var query = _client
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
        .eq('user_id', userId);

    if (filters.startDate != null) {
      final start = DateTime(
        filters.startDate!.year,
        filters.startDate!.month,
        filters.startDate!.day,
      );
      query = query.gte('transaction_date', start.toUtc().toIso8601String());
    }

    if (filters.endDate != null) {
      final endExclusive = DateTime(
        filters.endDate!.year,
        filters.endDate!.month,
        filters.endDate!.day,
      ).add(const Duration(days: 1));
      query = query.lt('transaction_date', endExclusive.toUtc().toIso8601String());
    }

    final rows = await query.order('transaction_date', ascending: false);

    return (rows as List<dynamic>).cast<Map<String, dynamic>>();
  }

  Future<List<Map<String, dynamic>>> _fetchWalletRows(String userId) async {
    final rows = await _client
        .from('wallets')
        .select('id,name,type,initial_balance,is_default,is_active,created_at')
        .eq('user_id', userId)
        .order('created_at', ascending: false);

    return (rows as List<dynamic>).cast<Map<String, dynamic>>();
  }

  Future<List<Map<String, dynamic>>> _fetchCategoryRows(String userId) async {
    final rows = await _client
        .from('categories')
        .select('id,name,type,is_default,is_active,created_at')
        .eq('user_id', userId)
        .order('created_at', ascending: false);

    return (rows as List<dynamic>).cast<Map<String, dynamic>>();
  }

  Future<List<List<Object?>>> _buildExportRows(
    String userId, {
    required ExportFilters filters,
  }) async {
    final rows = <List<Object?>>[];

    if (filters.hasTransactions) {
      final transactions = await _fetchTransactionRows(userId, filters: filters);
      for (final row in transactions) {
        final wallet = row['wallet'] as Map<String, dynamic>? ?? const {};
        final category = row['category'] as Map<String, dynamic>? ?? const {};
        rows.add([
          'transaction',
          row['id'],
          '',
          row['type'] == 'income' ? 'Thu' : 'Chi',
          row['amount'],
          wallet['name'],
          category['name'],
          row['note'],
          _formatDate(row['transaction_date'] as String?),
          row['image_path'],
          _formatDate(row['created_at'] as String?),
          '',
          '',
          '',
        ]);
      }
    }

    if (filters.hasWallets) {
      final wallets = await _fetchWalletRows(userId);
      for (final row in wallets) {
        rows.add([
          'wallet',
          row['id'],
          row['name'],
          row['type'],
          '',
          '',
          '',
          '',
          '',
          '',
          _formatDate(row['created_at'] as String?),
          row['initial_balance'],
          row['is_default'],
          row['is_active'],
        ]);
      }
    }

    if (filters.hasCategories) {
      final categories = await _fetchCategoryRows(userId);
      for (final row in categories) {
        rows.add([
          'category',
          row['id'],
          row['name'],
          row['type'],
          '',
          '',
          '',
          '',
          '',
          '',
          _formatDate(row['created_at'] as String?),
          '',
          row['is_default'],
          row['is_active'],
        ]);
      }
    }

    return rows;
  }
}
