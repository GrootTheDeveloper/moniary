import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/supabase/app_exception.dart';
import '../../../../core/supabase/supabase_providers.dart';
import '../../../../shared/utils/app_logger.dart';
import '../../domain/models/bank_connection.dart';
import '../../domain/models/bank_institution.dart';
import '../../domain/models/pending_synced_transaction.dart';
import '../../domain/repositories/bank_link_repository.dart';
import 'bank_link_mock_repository.dart';

final bankLinkRepositoryProvider = Provider<BankLinkRepository>((ref) {
  ref.watch(currentSessionProvider);
  final client = ref.watch(supabaseClientProvider);
  if (ref.watch(useMockDataModeProvider)) {
    return BankLinkMockRepository();
  }
  return BankLinkRepositoryImpl(client);
});

/// Real Supabase-backed implementation. Connecting a bank persists a
/// connection record so the UI and data model are fully exercised today, but
/// [syncConnection] intentionally has no wired aggregator yet: no vendor has
/// been chosen, and this feature must never fabricate transactions in a
/// user's real ledger. Swap the body of [syncConnection] for a real
/// aggregator call once a provider is selected; every other method already
/// works end to end.
class BankLinkRepositoryImpl implements BankLinkRepository {
  BankLinkRepositoryImpl(this._client);

  final SupabaseClient _client;

  String get _userId {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw const AppException('User not logged in', code: 'AUTH_REQUIRED');
    }
    return userId;
  }

  @override
  Future<List<BankInstitution>> fetchInstitutions() {
    return _guard('fetch bank institutions', () async {
      final rows = await _client
          .from('bank_institutions')
          .select()
          .eq('is_supported', true)
          .order('name');
      return (rows as List<dynamic>)
          .cast<Map<String, dynamic>>()
          .map(BankInstitution.fromMap)
          .toList(growable: false);
    });
  }

  @override
  Future<List<BankConnection>> fetchConnections() {
    return _guard('fetch bank connections', () async {
      final rows = await _client
          .from('bank_connections')
          .select()
          .eq('user_id', _userId)
          .order('created_at');
      return (rows as List<dynamic>)
          .cast<Map<String, dynamic>>()
          .map(BankConnection.fromMap)
          .toList(growable: false);
    });
  }

  @override
  Future<BankConnection> linkInstitution({
    required String institutionId,
    required String consentToken,
  }) {
    return _guard('link bank institution', () async {
      if (consentToken.trim().isEmpty) {
        throw const AppException(
          'errorBankLinkConsentRequired',
          code: 'BANK_LINK_CONSENT_REQUIRED',
        );
      }
      final institutionRow = await _client
          .from('bank_institutions')
          .select()
          .eq('id', institutionId)
          .maybeSingle();
      if (institutionRow == null) {
        throw const AppException(
          'errorBankLinkInstitutionNotFound',
          code: 'BANK_LINK_INSTITUTION_NOT_FOUND',
        );
      }
      final row = await _client
          .from('bank_connections')
          .insert({
            'user_id': _userId,
            'institution_id': institutionId,
            'institution_name': institutionRow['name'],
            'institution_logo_url': institutionRow['logo_url'],
            'status': BankConnectionStatus.connected.value,
            'provider': 'unconfigured',
          })
          .select()
          .single();
      return BankConnection.fromMap(row);
    });
  }

  @override
  Future<void> unlinkConnection(String connectionId) {
    return _guard('unlink bank connection', () async {
      await _client
          .from('bank_connections')
          .delete()
          .eq('id', connectionId)
          .eq('user_id', _userId);
    });
  }

  @override
  Future<List<PendingSyncedTransaction>> syncConnection(
    String connectionId,
  ) async {
    throw const AppException(
      'errorBankSyncNotConfigured',
      code: 'BANK_SYNC_NOT_CONFIGURED',
    );
  }

  @override
  Future<List<PendingSyncedTransaction>> fetchPendingSyncedTransactions() {
    return _guard('fetch pending synced transactions', () async {
      final rows = await _client
          .from('bank_sync_transactions')
          .select()
          .eq('user_id', _userId)
          .eq('status', PendingSyncedTransactionStatus.pending.value)
          .order('transaction_date', ascending: false);
      return (rows as List<dynamic>)
          .cast<Map<String, dynamic>>()
          .map(PendingSyncedTransaction.fromMap)
          .toList(growable: false);
    });
  }

  @override
  Future<void> markSyncedTransactionConfirmed({
    required String pendingId,
    required String transactionId,
  }) {
    return _guard('confirm synced transaction', () async {
      await _client
          .from('bank_sync_transactions')
          .update({
            'status': PendingSyncedTransactionStatus.confirmed.value,
            'confirmed_transaction_id': transactionId,
          })
          .eq('id', pendingId)
          .eq('user_id', _userId);
    });
  }

  @override
  Future<void> dismissSyncedTransaction(String pendingId) {
    return _guard('dismiss synced transaction', () async {
      await _client
          .from('bank_sync_transactions')
          .update({'status': PendingSyncedTransactionStatus.dismissed.value})
          .eq('id', pendingId)
          .eq('user_id', _userId);
    });
  }

  Future<T> _guard<T>(String operation, Future<T> Function() action) async {
    try {
      return await action();
    } on PostgrestException catch (e, st) {
      AppLogger.error(operation, e, st);
      throw AppException(e.message, code: e.code);
    } catch (e, st) {
      if (e is AppException) rethrow;
      AppLogger.error(operation, e, st);
      throw const AppException('errorConnection');
    }
  }
}
