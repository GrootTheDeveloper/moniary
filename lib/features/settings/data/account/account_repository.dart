import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/supabase/app_exception.dart';
import '../../../../core/supabase/supabase_providers.dart';
import '../../../../shared/utils/app_logger.dart';
import '../../domain/export/export_filters.dart';
import '../../domain/export/export_file_text.dart';
import '../../domain/export/export_history_entry.dart';
import '../../domain/data_transfer/spreadsheet_data_format.dart';
import '../../domain/account/active_session.dart';
import '../../domain/account/account_deletion_status.dart';
import '../../domain/account/deletion_feedback.dart';
import '../../domain/transparency/data_transparency_summary.dart';
import '../../domain/privacy_requests/privacy_request_history_entry.dart';
import '../export/pdf_report.dart';
import '../export/xlsx_workbook.dart';

final accountRepositoryProvider = Provider<AccountRepository>((ref) {
  final session = ref.watch(currentSessionProvider);
  return AccountRepository(
    ref.watch(supabaseClientProvider),
    currentUserId: session?.user.id,
  );
});

const _fileActionsChannel = MethodChannel('moniary/file_actions');

class AccountRepository {
  AccountRepository(
    this._client, {
    String? currentUserId,
    Directory? documentsDirectory,
    Directory? exportDirectory,
  }) : _currentUserId = currentUserId,
       _documentsDirectory = documentsDirectory,
       _exportDirectory = exportDirectory;

  final SupabaseClient _client;
  final String? _currentUserId;
  final Directory? _documentsDirectory;
  final Directory? _exportDirectory;

  Future<File> exportTransactionsCsv({
    ExportFilters filters = const ExportFilters(),
    required ExportFileText text,
  }) async {
    final userId = _requireExportUserId();
    final exportRows = await _buildExportRows(userId, filters: filters);
    final headers = _spreadsheetHeaders(text);
    final csvLines = <String>[
      headers.map(_csvCell).join(','),
      ...exportRows.map((row) => row.map(_csvCell).join(',')),
    ];
    final csv = '\uFEFF${csvLines.join('\r\n')}\r\n';

    try {
      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final saved = await _writeExportFile(
        fileName: 'moniary_export_$timestamp.csv',
        mimeType: 'text/csv;charset=utf-8',
        bytes: Uint8List.fromList(utf8.encode(csv)),
      );
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
      List<Object?>.from(_spreadsheetHeaders(text)),
      ...exportRows,
    ];

    final bytes = XlsxWorkbook(
      sheetName: text.xlsxSheetName,
      rows: workbookRows,
    ).build();
    try {
      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final saved = await _writeExportFile(
        fileName: 'moniary_export_$timestamp.xlsx',
        mimeType:
            'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
        bytes: bytes,
      );
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
      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final saved = await _writeExportFile(
        fileName: 'moniary_export_$timestamp.pdf',
        mimeType: 'application/pdf',
        bytes: bytes,
      );
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
      final session = _client.auth.currentSession;
      if (session == null) {
        throw const AppException('User not logged in', code: 'AUTH_REQUIRED');
      }
      final rows = await _client
          .from('privacy_requests')
          .select(
            'id,request_type,message,status,admin_note,submitted_at,resolved_at',
          )
          .eq('user_id', session.user.id)
          .order('submitted_at', ascending: false)
          .limit(50);
      return (rows as List<dynamic>)
          .cast<Map<String, dynamic>>()
          .map(PrivacyRequestHistoryEntry.fromMap)
          .toList(growable: false);
    } on PostgrestException catch (e, st) {
      AppLogger.error('Failed to read privacy request history', e, st);
      throw AppException(e.message, code: e.code);
    } catch (e, st) {
      if (e is AppException) rethrow;
      AppLogger.error('Failed to read privacy request history', e, st);
      throw const AppException(
        'errorConnection',
        code: 'PRIVACY_HISTORY_READ_ERROR',
      );
    }
  }

  Future<DataTransparencySummary> fetchDataTransparencySummary() async {
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

  Future<DateTime> requestSoftDelete({
    required AccountDeletionReason reason,
    String? details,
    required DeletionFeedbackContext feedbackContext,
  }) async {
    final session = _client.auth.currentSession;
    if (session == null) {
      throw const AppException('User not logged in', code: 'AUTH_REQUIRED');
    }

    final normalizedDetails = details?.trim();
    if (normalizedDetails != null && normalizedDetails.length > 500) {
      throw const AppException(
        'Deletion feedback is too long',
        code: 'DELETION_DETAILS_TOO_LONG',
      );
    }

    final response = await _client.functions.invoke(
      'soft-delete-account',
      body: {
        'reasonCode': reason.id,
        if (normalizedDetails?.isNotEmpty == true) 'details': normalizedDetails,
        ...feedbackContext.toMap(),
      },
    );
    final data = response.data;
    if (data is! Map<String, dynamic>) {
      throw const AppException(
        'Invalid account deletion response',
        code: 'ACCOUNT_DELETE_INVALID_RESPONSE',
      );
    }
    final deletedAt = DateTime.tryParse(data['deleted_at'] as String? ?? '');
    if (deletedAt == null) {
      throw const AppException(
        'Missing account deletion timestamp',
        code: 'ACCOUNT_DELETE_INVALID_RESPONSE',
      );
    }
    // The Edge Function has already revoked every refresh token. Clear this
    // device locally so a successful deletion request is not reported as a
    // failure when the server-side session no longer exists.
    await _client.auth.signOut(scope: SignOutScope.local);
    return deletedAt.toLocal();
  }

  Future<void> restoreAccount() async {
    final session = _client.auth.currentSession;
    if (session == null) {
      throw const AppException('User not logged in', code: 'AUTH_REQUIRED');
    }

    try {
      await _client.rpc('restore_deleted_account');
    } on PostgrestException catch (e, st) {
      AppLogger.error('Failed to restore account', e, st);
      if (e.message.contains('ACCOUNT_RESTORE_EXPIRED')) {
        throw const AppException(
          'Account restoration window has expired',
          code: 'ACCOUNT_RESTORE_EXPIRED',
        );
      }
      throw AppException(e.message, code: e.code);
    } catch (e, st) {
      if (e is AppException) rethrow;
      AppLogger.error('Failed to restore account', e, st);
      throw const AppException(
        'Failed to restore account',
        code: 'ACCOUNT_RESTORE_FAILED',
      );
    }
  }

  Future<AccountDeletionStatus> fetchAccountDeletionStatus() async {
    final session = _client.auth.currentSession;
    if (session == null) return AccountDeletionStatus.active;

    try {
      final row = await _client
          .from('profiles')
          .select('deleted_at')
          .eq('id', session.user.id)
          .maybeSingle();

      final deletedAt = DateTime.tryParse(row?['deleted_at'] as String? ?? '');
      return AccountDeletionStatus(deletedAt: deletedAt?.toLocal());
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
    final session = _client.auth.currentSession;
    if (session == null) {
      throw const AppException('User not logged in', code: 'AUTH_REQUIRED');
    }
    await _client.rpc('revoke_session', params: {'session_id': sessionId});
  }

  Future<List<ActiveSession>> getActiveSessions() async {
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
    await createPrivacyRequest(requestType: 'data_deletion', message: reason);
  }

  Future<void> createPrivacyRequest({
    required String requestType,
    required String message,
  }) async {
    final session = _client.auth.currentSession;
    if (session == null) {
      throw const AppException('User not logged in', code: 'AUTH_REQUIRED');
    }

    const allowedTypes = {
      'data_access',
      'data_export_help',
      'data_correction',
      'data_deletion',
      'privacy_complaint',
    };
    final normalizedMessage = message.trim();
    if (!allowedTypes.contains(requestType)) {
      throw const AppException(
        'Invalid privacy request type',
        code: 'PRIVACY_REQUEST_TYPE_INVALID',
      );
    }
    if (normalizedMessage.isEmpty || normalizedMessage.length > 4000) {
      throw const AppException(
        'Privacy request message must contain 1 to 4000 characters',
        code: 'PRIVACY_REQUEST_MESSAGE_INVALID',
      );
    }
    try {
      await _client.rpc(
        'submit_privacy_request',
        params: {'p_request_type': requestType, 'p_message': normalizedMessage},
      );
    } on PostgrestException catch (e, st) {
      AppLogger.error('Failed to submit privacy request', e, st);
      if (e.message.contains('PRIVACY_REQUEST_RATE_LIMITED')) {
        throw const AppException(
          'Privacy request rate limit exceeded',
          code: 'PRIVACY_REQUEST_RATE_LIMITED',
        );
      }
      throw AppException(e.message, code: e.code);
    } catch (e, st) {
      if (e is AppException) rethrow;
      AppLogger.error('Failed to submit privacy request', e, st);
      throw const AppException(
        'Failed to submit privacy request',
        code: 'PRIVACY_REQUEST_SUBMIT_FAILED',
      );
    }
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

  static List<String> _spreadsheetHeaders(ExportFileText text) {
    if (text.spreadsheetHeaders.length ==
        SpreadsheetDataFormat.fullColumnKeys.length) {
      return text.spreadsheetHeaders;
    }
    return SpreadsheetDataFormat.fullColumnKeys;
  }

  String _requireExportUserId() {
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
      final transactions = await _fetchTransactionRows(
        userId,
        filters: filters,
      );
      for (final row in transactions) {
        final wallet = row['wallet'] as Map<String, dynamic>? ?? const {};
        final category = row['category'] as Map<String, dynamic>? ?? const {};
        rows.add(
          SpreadsheetDataFormat.orderedValues({
            SpreadsheetDataFormat.dataType: 'transaction',
            SpreadsheetDataFormat.id: row['id'],
            SpreadsheetDataFormat.type: row['type'],
            SpreadsheetDataFormat.amount: row['amount'],
            SpreadsheetDataFormat.wallet: wallet['name'],
            SpreadsheetDataFormat.category: category['name'],
            SpreadsheetDataFormat.note: row['note'],
            SpreadsheetDataFormat.transactionDate: _formatDate(
              row['transaction_date'] as String?,
            ),
            SpreadsheetDataFormat.imagePath: row['image_path'],
            SpreadsheetDataFormat.createdAt: _formatDate(
              row['created_at'] as String?,
            ),
          }),
        );
      }
    }

    if (filters.hasWallets) {
      final wallets = await _fetchWalletRows(userId);
      for (final row in wallets) {
        rows.add(
          SpreadsheetDataFormat.orderedValues({
            SpreadsheetDataFormat.dataType: 'wallet',
            SpreadsheetDataFormat.id: row['id'],
            SpreadsheetDataFormat.name: row['name'],
            SpreadsheetDataFormat.type: row['type'],
            SpreadsheetDataFormat.createdAt: _formatDate(
              row['created_at'] as String?,
            ),
            SpreadsheetDataFormat.initialBalance: row['initial_balance'],
            SpreadsheetDataFormat.isDefault: row['is_default'],
            SpreadsheetDataFormat.isActive: row['is_active'],
          }),
        );
      }
    }

    if (filters.hasCategories) {
      final categories = await _fetchCategoryRows(userId);
      for (final row in categories) {
        rows.add(
          SpreadsheetDataFormat.orderedValues({
            SpreadsheetDataFormat.dataType: 'category',
            SpreadsheetDataFormat.id: row['id'],
            SpreadsheetDataFormat.name: row['name'],
            SpreadsheetDataFormat.type: row['type'],
            SpreadsheetDataFormat.createdAt: _formatDate(
              row['created_at'] as String?,
            ),
            SpreadsheetDataFormat.isDefault: row['is_default'],
            SpreadsheetDataFormat.isActive: row['is_active'],
          }),
        );
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

  Future<void> clearLocalUserFiles() async {
    try {
      final directory = await _getExportDirectory();
      if (!await directory.exists()) return;
      await for (final entity in directory.list()) {
        if (entity is! File) continue;
        final name = entity.uri.pathSegments.last;
        final isMoniaryUserFile =
            name == 'moniary_export_history.json' ||
            name == 'moniary_privacy_request_history.json' ||
            name.startsWith('moniary_export_');
        if (isMoniaryUserFile) await entity.delete();
      }
    } catch (error, stackTrace) {
      AppLogger.error('Failed to clear local account files', error, stackTrace);
      throw const AppException(
        'Failed to clear local account files',
        code: 'ACCOUNT_LOCAL_DATA_CLEAR_ERROR',
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

  Future<File> _writeExportFile({
    required String fileName,
    required String mimeType,
    required Uint8List bytes,
  }) async {
    if (_exportDirectory == null && Platform.isAndroid) {
      try {
        final publicPath = await _fileActionsChannel.invokeMethod<String>(
          'saveToDownloads',
          {'fileName': fileName, 'mimeType': mimeType, 'bytes': bytes},
        );
        if (publicPath != null && publicPath.isNotEmpty) {
          return File(publicPath);
        }
      } catch (e, st) {
        AppLogger.error('Failed to save export to public Downloads', e, st);
      }
    }

    final directory = await _getExportDirectory();
    final file = File('${directory.path}/$fileName');
    return file.writeAsBytes(bytes, flush: true);
  }
}
