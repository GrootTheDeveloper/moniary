import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/supabase/app_exception.dart';
import '../../../shared/utils/app_logger.dart';

class JournalCollectionRecord {
  const JournalCollectionRecord({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.transactionIds,
    this.startDate,
    this.endDate,
  });

  final String id;
  final String name;
  final DateTime createdAt;
  final DateTime? startDate;
  final DateTime? endDate;
  final List<String> transactionIds;
}

abstract interface class JournalCollectionDataSource {
  Future<List<JournalCollectionRecord>> fetchCollections();

  Future<JournalCollectionRecord> fetchCollection(String collectionId);

  Future<String> createCollection({
    required String name,
    DateTime? startDate,
    DateTime? endDate,
  });

  Future<void> addTransaction({
    required String collectionId,
    required String transactionId,
  });
}

class SupabaseJournalCollectionDataSource
    implements JournalCollectionDataSource {
  SupabaseJournalCollectionDataSource(this._client);

  final SupabaseClient _client;

  String get _userId {
    final id = _client.auth.currentSession?.user.id;
    if (id == null) {
      throw const AppException('errorGeneric', code: 'AUTH_REQUIRED');
    }
    return id;
  }

  @override
  Future<List<JournalCollectionRecord>> fetchCollections() async {
    try {
      final rows = await _client
          .from('journal_collections')
          .select()
          .eq('user_id', _userId)
          .order('created_at', ascending: false);
      return Future.wait(
        (rows as List<dynamic>).cast<Map<String, dynamic>>().map(_mapRecord),
      );
    } on PostgrestException catch (error, stackTrace) {
      AppLogger.error('Failed to load journal collections', error, stackTrace);
      throw AppException(error.message, code: error.code);
    } catch (error, stackTrace) {
      if (error is AppException) rethrow;
      AppLogger.error('Failed to load journal collections', error, stackTrace);
      throw const AppException(
        'errorConnection',
        code: 'JOURNAL_COLLECTION_LOAD_FAILED',
      );
    }
  }

  @override
  Future<JournalCollectionRecord> fetchCollection(String collectionId) async {
    try {
      final row = await _client
          .from('journal_collections')
          .select()
          .eq('id', collectionId)
          .eq('user_id', _userId)
          .single();
      return _mapRecord(row);
    } on PostgrestException catch (error, stackTrace) {
      AppLogger.error('Failed to load journal collection', error, stackTrace);
      throw AppException(error.message, code: error.code);
    } catch (error, stackTrace) {
      if (error is AppException) rethrow;
      AppLogger.error('Failed to load journal collection', error, stackTrace);
      throw const AppException(
        'errorConnection',
        code: 'JOURNAL_COLLECTION_LOAD_FAILED',
      );
    }
  }

  @override
  Future<String> createCollection({
    required String name,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final row = await _client
          .from('journal_collections')
          .insert({
            'user_id': _userId,
            'name': name,
            'start_date': _dateValue(startDate),
            'end_date': _dateValue(endDate),
          })
          .select('id')
          .single();
      return row['id'] as String;
    } on PostgrestException catch (error, stackTrace) {
      AppLogger.error('Failed to create journal collection', error, stackTrace);
      throw AppException(error.message, code: error.code);
    } catch (error, stackTrace) {
      if (error is AppException) rethrow;
      AppLogger.error('Failed to create journal collection', error, stackTrace);
      throw const AppException(
        'errorConnection',
        code: 'JOURNAL_COLLECTION_CREATE_FAILED',
      );
    }
  }

  @override
  Future<void> addTransaction({
    required String collectionId,
    required String transactionId,
  }) async {
    try {
      await _client.from('journal_collection_transactions').upsert({
        'collection_id': collectionId,
        'transaction_id': transactionId,
        'user_id': _userId,
      }, onConflict: 'collection_id,transaction_id');
    } on PostgrestException catch (error, stackTrace) {
      AppLogger.error(
        'Failed to add transaction to journal collection',
        error,
        stackTrace,
      );
      throw AppException(error.message, code: error.code);
    } catch (error, stackTrace) {
      if (error is AppException) rethrow;
      AppLogger.error(
        'Failed to add transaction to journal collection',
        error,
        stackTrace,
      );
      throw const AppException(
        'errorConnection',
        code: 'JOURNAL_COLLECTION_ADD_FAILED',
      );
    }
  }

  Future<JournalCollectionRecord> _mapRecord(Map<String, dynamic> row) async {
    final id = row['id'] as String;
    final links = await _client
        .from('journal_collection_transactions')
        .select('transaction_id')
        .eq('collection_id', id)
        .eq('user_id', _userId);
    return JournalCollectionRecord(
      id: id,
      name: row['name'] as String,
      createdAt: DateTime.parse(row['created_at'] as String),
      startDate: _parseDate(row['start_date']),
      endDate: _parseDate(row['end_date']),
      transactionIds: (links as List<dynamic>)
          .cast<Map<String, dynamic>>()
          .map((link) => link['transaction_id'] as String)
          .toList(),
    );
  }

  DateTime? _parseDate(dynamic value) {
    return value is String ? DateTime.tryParse(value) : null;
  }

  String? _dateValue(DateTime? value) {
    if (value == null) return null;
    return DateTime.utc(
      value.year,
      value.month,
      value.day,
    ).toIso8601String().substring(0, 10);
  }
}
