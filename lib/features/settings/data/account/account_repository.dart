import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/supabase/app_exception.dart';
import '../../../../core/supabase/supabase_providers.dart';
import '../../../../shared/utils/app_logger.dart';
import '../../../categories/data/repositories/category_repository.dart';
import '../../../transactions/data/repositories/transaction_repository.dart';
import '../../../wallets/data/repositories/wallet_repository.dart';
import '../../domain/export/export_filters.dart';
import '../../domain/export/export_file_text.dart';
import '../../domain/export/export_history_entry.dart';
import '../../domain/account/active_session.dart';
import '../../domain/transparency/data_transparency_summary.dart';
import '../../domain/privacy_requests/privacy_request_history_entry.dart';
import '../export/pdf_report.dart';
import '../export/xlsx_workbook.dart';

final accountRepositoryProvider = Provider<AccountRepository>((ref) {
  final session = ref.watch(currentSessionProvider);
  return AccountRepository(
    ref.watch(supabaseClientProvider),
    currentUserId: session?.user.id,
    useMockData: ref.watch(useMockDataModeProvider),
  );
});

class AccountRepository {
  AccountRepository(
    this._client, {
    String? currentUserId,
    Directory? documentsDirectory,
    Directory? exportDirectory,
    bool useMockData = false,
  }) : _currentUserId = currentUserId,
       _useMockData = useMockData || !AppConstants.hasSupabaseConfig,
       _documentsDirectory = documentsDirectory,
       _exportDirectory = exportDirectory;

  final SupabaseClient _client;
  final String? _currentUserId;
  final bool _useMockData;
  final Directory? _documentsDirectory;
  final Directory? _exportDirectory;

  Future<File> exportTransactionsCsv({
    ExportFilters filters = const ExportFilters(),
  }) async {
    final userId = _requireExportUserId();
    final exportRows = await _buildExportRows(userId, filters: filters);

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

    try {
      final directory = await _getExportDirectory();
      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final file = File('${directory.path}/moniary_export_$timestamp.csv');
      final saved = await file.writeAsString(csv.toString(), encoding: utf8);
      await _recordExport(format: 'CSV', file: saved, filters: filters);
      return saved;
    } catch (e, st) {
      if (e is AppException) rethrow;
      AppLogger.error('Failed to write CSV export file', e, st);
      throw const AppException(
        'Failed to write CSV export file',
        code: 'FILE_IO_ERROR',
      );
    }
  }

  Future<File> exportTransactionsXlsx({
    ExportFilters filters = const ExportFilters(),
    required ExportFileText text,
  }) async {
    final userId = _requireExportUserId();
    final exportRows = await _buildExportRows(userId, filters: filters);
    final workbookRows = <List<Object?>>[
      List<Object?>.from(text.xlsxHeaders),
      ...exportRows,
    ];

    final bytes = XlsxWorkbook(
      sheetName: text.xlsxSheetName,
      rows: workbookRows,
    ).build();
    try {
      final directory = await _getExportDirectory();
      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final file = File('${directory.path}/moniary_export_$timestamp.xlsx');
      final saved = await file.writeAsBytes(bytes, flush: true);
      await _recordExport(format: 'XLSX', file: saved, filters: filters);
      return saved;
    } catch (e, st) {
      if (e is AppException) rethrow;
      AppLogger.error('Failed to write XLSX export file', e, st);
      throw const AppException(
        'Failed to write XLSX export file',
        code: 'FILE_IO_ERROR',
      );
    }
  }

  Future<File> exportTransactionsPdf({
    ExportFilters filters = const ExportFilters(),
    required ExportFileText text,
  }) async {
    final userId = _requireExportUserId();

    final transactions = filters.hasTransactions
        ? await _fetchTransactionRows(userId, filters: filters)
        : <Map<String, dynamic>>[];
    final wallets = filters.hasWallets
        ? await _fetchWalletRows(userId)
        : <Map<String, dynamic>>[];
    final categories = filters.hasCategories
        ? await _fetchCategoryRows(userId)
        : <Map<String, dynamic>>[];
    final generatedAt = DateFormat(
      'yyyy-MM-dd HH:mm:ss',
    ).format(DateTime.now());
    final income = transactions
        .where((row) => row['type'] == 'income')
        .fold<double>(0, (sum, row) => sum + (row['amount'] as num).toDouble());
    final expense = transactions
        .where((row) => row['type'] == 'expense')
        .fold<double>(0, (sum, row) => sum + (row['amount'] as num).toDouble());

    final lines = <String>[
      '${text.pdfGeneratedAtLabel}: $generatedAt',
      '${text.pdfDataTypesLabel}: ${_localizedExportDataTypes(filters, text)}',
      '${text.pdfTransactionsLabel}: ${transactions.length}',
      '${text.pdfWalletsLabel}: ${wallets.length}',
      '${text.pdfCategoriesLabel}: ${categories.length}',
      '${text.pdfIncomeTotalLabel}: ${income.toStringAsFixed(0)}',
      '${text.pdfExpenseTotalLabel}: ${expense.toStringAsFixed(0)}',
      '${text.pdfRecentTransactionsLabel}:',
      ...transactions.take(20).map((row) {
        final wallet = row['wallet'] as Map<String, dynamic>? ?? const {};
        final category = row['category'] as Map<String, dynamic>? ?? const {};
        final type = row['type'] == 'income'
            ? text.pdfIncomeTypeLabel
            : text.pdfExpenseTypeLabel;
        final amount = (row['amount'] as num).toStringAsFixed(0);
        final date = _formatDate(row['transaction_date'] as String?);
        return '$date | $type | $amount | ${wallet['name'] ?? ''} | ${category['name'] ?? ''}';
      }),
    ];

    final bytes = PdfReport(title: text.pdfTitle, lines: lines).build();
    try {
      final directory = await _getExportDirectory();
      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final file = File('${directory.path}/moniary_export_$timestamp.pdf');
      final saved = await file.writeAsBytes(bytes, flush: true);
      await _recordExport(format: 'PDF', file: saved, filters: filters);
      return saved;
    } catch (e, st) {
      if (e is AppException) rethrow;
      AppLogger.error('Failed to write PDF export file', e, st);
      throw const AppException(
        'Failed to write PDF export file',
        code: 'FILE_IO_ERROR',
      );
    }
  }

  Future<List<ExportHistoryEntry>> fetchExportHistory() async {
    try {
      final file = await _exportHistoryFile();
      if (!await file.exists()) {
        return const [];
      }

      final raw = await file.readAsString();
      final decoded = jsonDecode(raw) as List<dynamic>;
      return decoded
          .cast<Map<String, dynamic>>()
          .map(ExportHistoryEntry.fromMap)
          .toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    } catch (e, st) {
      AppLogger.error('Failed to read export history', e, st);
      throw const AppException(
        'Failed to read export history',
        code: 'EXPORT_HISTORY_READ_ERROR',
      );
    }
  }

  @visibleForTesting
  Future<void> recordExportForTest({
    required String format,
    required File file,
    ExportFilters filters = const ExportFilters(),
  }) {
    return _recordExport(format: format, file: file, filters: filters);
  }

  Future<List<PrivacyRequestHistoryEntry>> fetchPrivacyRequestHistory() async {
    try {
      final file = await _privacyRequestHistoryFile();
      if (!await file.exists()) {
        return const [];
      }

      final raw = await file.readAsString();
      final decoded = jsonDecode(raw) as List<dynamic>;
      return decoded
          .cast<Map<String, dynamic>>()
          .map(PrivacyRequestHistoryEntry.fromMap)
          .toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    } catch (e, st) {
      AppLogger.error('Failed to read privacy request history', e, st);
      throw const AppException(
        'Failed to read privacy request history',
        code: 'PRIVACY_HISTORY_READ_ERROR',
      );
    }
  }

  Future<void> updatePrivacyRequestStatus({
    required String id,
    required String status,
  }) async {
    final history = await fetchPrivacyRequestHistory();
    final updated = history
        .map((entry) => entry.id == id ? entry.copyWith(status: status) : entry)
        .map((entry) => entry.toMap())
        .toList();
    try {
      final historyFile = await _privacyRequestHistoryFile();
      await historyFile.writeAsString(
        const JsonEncoder.withIndent('  ').convert(updated),
      );
    } catch (e, st) {
      AppLogger.error('Failed to write privacy request history file', e, st);
      throw const AppException(
        'Failed to write privacy request history file',
        code: 'FILE_IO_ERROR',
      );
    }
  }

  Future<DataTransparencySummary> fetchDataTransparencySummary() async {
    if (_useMockData) {
      final txs = TransactionRepository.mockTransactions;
      final wallets = WalletRepository.mockWallets;
      final categories = CategoryRepository.mockCategories;

      final transactionDates = txs.map((t) => t.transactionDate).toList()
        ..sort();

      return DataTransparencySummary(
        transactionCount: txs.length,
        walletCount: wallets.length,
        categoryCount: categories.length,
        photoTransactionCount: txs
            .where((row) => row.imagePath?.isNotEmpty == true)
            .length,
        exportFileCount: 0,
        oldestTransactionDate: transactionDates.isEmpty
            ? null
            : transactionDates.first,
        newestTransactionDate: transactionDates.isEmpty
            ? null
            : transactionDates.last,
        latestExportDate: null,
      );
    }
    final session = _client.auth.currentSession;
    if (session == null) {
      throw const AppException('User not logged in', code: 'AUTH_REQUIRED');
    }

    final userId = session.user.id;
    final transactions = await _client
        .from('transactions')
        .select('id,image_path,transaction_date')
        .eq('user_id', userId);
    final wallets = await _client
        .from('wallets')
        .select('id')
        .eq('user_id', userId);
    final categories = await _client
        .from('categories')
        .select('id')
        .eq('user_id', userId);
    final history = await fetchExportHistory();

    final transactionRows = (transactions as List<dynamic>)
        .cast<Map<String, dynamic>>();
    final transactionDates =
        transactionRows
            .map(
              (row) =>
                  DateTime.tryParse(row['transaction_date'] as String? ?? ''),
            )
            .whereType<DateTime>()
            .map((date) => date.toLocal())
            .toList()
          ..sort();

    return DataTransparencySummary(
      transactionCount: transactionRows.length,
      walletCount: (wallets as List<dynamic>).length,
      categoryCount: (categories as List<dynamic>).length,
      photoTransactionCount: transactionRows
          .where((row) => (row['image_path'] as String?)?.isNotEmpty == true)
          .length,
      exportFileCount: history.length,
      oldestTransactionDate: transactionDates.isEmpty
          ? null
          : transactionDates.first,
      newestTransactionDate: transactionDates.isEmpty
          ? null
          : transactionDates.last,
      latestExportDate: history.isEmpty ? null : history.first.createdAt,
    );
  }

  Future<void> deleteAccount() async {
    if (_useMockData) {
      await _client.auth.signOut();
      return;
    }
    final session = _client.auth.currentSession;
    if (session == null) {
      throw const AppException('User not logged in', code: 'AUTH_REQUIRED');
    }

    await _client.functions.invoke('delete-account');
    await _client.auth.signOut();
  }

  Future<void> requestSoftDelete() async {
    if (_useMockData) {
      await _client.auth.signOut();
      return;
    }
    final session = _client.auth.currentSession;
    if (session == null) {
      throw const AppException('User not logged in', code: 'AUTH_REQUIRED');
    }

    await _client.functions.invoke('soft-delete-account');
    await _client.auth.signOut();
  }

  Future<void> restoreAccount() async {
    if (_useMockData) return;

    final session = _client.auth.currentSession;
    if (session == null) {
      throw const AppException('User not logged in', code: 'AUTH_REQUIRED');
    }

    await _client
        .from('profiles')
        .update({'deleted_at': null})
        .eq('id', session.user.id);
  }

  Future<bool> isAccountPendingDeletion() async {
    if (_useMockData) return false;

    final session = _client.auth.currentSession;
    if (session == null) return false;

    try {
      final row = await _client
          .from('profiles')
          .select('deleted_at')
          .eq('id', session.user.id)
          .maybeSingle();

      return row != null && row['deleted_at'] != null;
    } on PostgrestException catch (e, st) {
      AppLogger.error('Failed to load account status', e, st);
      throw AppException(e.message, code: e.code);
    } catch (e, st) {
      if (e is AppException) rethrow;
      AppLogger.error('Failed to load account status', e, st);
      throw const AppException(
        'Failed to load account status',
        code: 'ACCOUNT_STATUS_LOAD_FAILED',
      );
    }
  }

  Future<void> revokeSession(String sessionId) async {
    if (_useMockData) return;
    final session = _client.auth.currentSession;
    if (session == null) {
      throw const AppException('User not logged in', code: 'AUTH_REQUIRED');
    }
    await _client.rpc('revoke_session', params: {'session_id': sessionId});
  }

  Future<List<ActiveSession>> getActiveSessions() async {
    if (_useMockData) {
      return [
        ActiveSession(
          id: 'mock-session-id',
          createdAt: DateTime.now().subtract(const Duration(days: 1)),
          updatedAt: DateTime.now(),
          userAgent:
              'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/119.0.0.0 Safari/537.36',
          ip: '127.0.0.1',
        ),
      ];
    }

    final session = _client.auth.currentSession;
    if (session == null) {
      throw const AppException('User not logged in', code: 'AUTH_REQUIRED');
    }

    final response = await _client.rpc('get_active_sessions');
    final List<dynamic> data = response as List<dynamic>;

    return data.cast<Map<String, dynamic>>().map(ActiveSession.fromMap).toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  }

  Future<void> createDeletionRequest({required String reason}) async {
    if (_useMockData) {
      // Mock bypass
    } else {
      final session = _client.auth.currentSession;
      if (session == null) {
        throw const AppException('User not logged in', code: 'AUTH_REQUIRED');
      }
    }

    final timestamp = DateTime.now();

    // We just record it in local history as a privacy request for manual processing.
    // For now, we just record it in local history as 'requested'.
    await _recordPrivacyRequest(
      requestType: 'data_deletion',
      message: reason,
      status: 'sent_manually',
      timestamp: timestamp,
    );
  }

  Future<void> createPrivacyRequest({
    required String requestType,
    required String message,
  }) async {
    if (_useMockData) {
      // Mock bypass
    } else {
      final session = _client.auth.currentSession;
      if (session == null) {
        throw const AppException('User not logged in', code: 'AUTH_REQUIRED');
      }
    }

    final timestamp = DateTime.now();

    await _recordPrivacyRequest(
      requestType: requestType,
      message: message,
      status: 'sent_manually',
      timestamp: timestamp,
    );
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

  String _requireExportUserId() {
    if (_useMockData) {
      return _currentUserId ?? 'mock-user-id';
    }

    final userId = _currentUserId ?? _client.auth.currentSession?.user.id;
    if (userId == null) {
      throw const AppException('User not logged in', code: 'AUTH_REQUIRED');
    }
    return userId;
  }

  Future<List<Map<String, dynamic>>> _fetchTransactionRows(
    String userId, {
    ExportFilters filters = const ExportFilters(),
  }) async {
    if (_useMockData) {
      final txs = TransactionRepository.mockTransactions;
      return txs
          .where((t) {
            if (filters.startDate != null &&
                t.transactionDate.isBefore(filters.startDate!)) {
              return false;
            }
            if (filters.endDate != null &&
                t.transactionDate.isAfter(filters.endDate!)) {
              return false;
            }
            return true;
          })
          .map(
            (t) => {
              'id': t.id,
              'amount': t.amount,
              'type': t.type.name,
              'note': t.note,
              'image_path': t.imagePath,
              'transaction_date': t.transactionDate.toIso8601String(),
              'created_at': t.transactionDate.toIso8601String(),
              'wallet': {'name': t.walletName},
              'category': {'name': t.categoryName},
            },
          )
          .toList();
    }
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
      query = query.lt(
        'transaction_date',
        endExclusive.toUtc().toIso8601String(),
      );
    }

    final rows = await query.order('transaction_date', ascending: false);

    return (rows as List<dynamic>).cast<Map<String, dynamic>>();
  }

  Future<List<Map<String, dynamic>>> _fetchWalletRows(String userId) async {
    if (_useMockData) {
      return WalletRepository.mockWallets
          .map(
            (w) => {
              'id': w.id,
              'name': w.name,
              'type': w.type.name,
              'initial_balance': w.initialBalance,
              'is_default': w.isDefault,
              'is_active': w.isActive,
              'created_at': w.createdAt.toIso8601String(),
            },
          )
          .toList();
    }
    final rows = await _client
        .from('wallets')
        .select('id,name,type,initial_balance,is_default,is_active,created_at')
        .eq('user_id', userId)
        .order('created_at', ascending: false);

    return (rows as List<dynamic>).cast<Map<String, dynamic>>();
  }

  Future<List<Map<String, dynamic>>> _fetchCategoryRows(String userId) async {
    if (_useMockData) {
      return CategoryRepository.mockCategories
          .map(
            (c) => {
              'id': c.id,
              'name': c.name,
              'type': c.type.name,
              'is_default': c.isDefault,
              'is_active': c.isActive,
              'created_at': c.createdAt.toIso8601String(),
            },
          )
          .toList();
    }
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
      final transactions = await _fetchTransactionRows(
        userId,
        filters: filters,
      );
      for (final row in transactions) {
        final wallet = row['wallet'] as Map<String, dynamic>? ?? const {};
        final category = row['category'] as Map<String, dynamic>? ?? const {};
        rows.add([
          'transaction',
          row['id'],
          '',
          row['type'],
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

  String _localizedExportDataTypes(ExportFilters filters, ExportFileText text) {
    return filters.dataTypes
        .map((type) => text.dataTypeLabels[type] ?? type.key)
        .join(', ');
  }

  Future<void> _recordExport({
    required String format,
    required File file,
    required ExportFilters filters,
  }) async {
    final history = await fetchExportHistory();
    final entry = ExportHistoryEntry(
      format: format,
      path: file.path,
      createdAt: DateTime.now(),
      dataTypes: filters.dataTypes.map((type) => type.key).toList(),
      startDate: filters.startDate,
      endDate: filters.endDate,
    );

    try {
      final fileHistory = await _exportHistoryFile();
      final next = [
        entry,
        ...history,
      ].take(50).map((item) => item.toMap()).toList();
      await fileHistory.writeAsString(
        const JsonEncoder.withIndent('  ').convert(next),
      );
    } catch (e, st) {
      AppLogger.error('Failed to write export history file', e, st);
      throw const AppException(
        'Failed to write export history file',
        code: 'FILE_IO_ERROR',
      );
    }
  }

  Future<File> _exportHistoryFile() async {
    final directory =
        _documentsDirectory ?? await getApplicationDocumentsDirectory();
    return File('${directory.path}/moniary_export_history.json');
  }

  Future<File> _privacyRequestHistoryFile() async {
    final directory =
        _documentsDirectory ?? await getApplicationDocumentsDirectory();
    return File('${directory.path}/moniary_privacy_request_history.json');
  }

  Future<void> _recordPrivacyRequest({
    required String requestType,
    required String message,
    required String status,
    File? file,
    required DateTime timestamp,
  }) async {
    final history = await fetchPrivacyRequestHistory();
    final entry = PrivacyRequestHistoryEntry(
      id: DateFormat('yyyyMMddHHmmss').format(timestamp),
      requestType: requestType,
      message: message.trim(),
      status: status,
      createdAt: timestamp,
      path: file?.path,
    );

    try {
      final historyFile = await _privacyRequestHistoryFile();
      final next = [
        entry,
        ...history,
      ].take(50).map((item) => item.toMap()).toList();
      await historyFile.writeAsString(
        const JsonEncoder.withIndent('  ').convert(next),
      );
    } catch (e, st) {
      AppLogger.error('Failed to write privacy request history file', e, st);
      throw const AppException(
        'Failed to write privacy request history file',
        code: 'FILE_IO_ERROR',
      );
    }
  }

  Future<Directory> _getExportDirectory() async {
    if (_exportDirectory != null) return _exportDirectory;
    if (Platform.isAndroid) {
      final directory = await getDownloadsDirectory();
      if (directory != null) return directory;
    }
    return getApplicationDocumentsDirectory();
  }
}
