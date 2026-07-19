import '../../../../core/supabase/app_exception.dart';
import '../../../categories/domain/models/category.dart';
import '../../domain/models/bank_connection.dart';
import '../../domain/models/bank_institution.dart';
import '../../domain/models/pending_synced_transaction.dart';
import '../../domain/repositories/bank_link_repository.dart';

class BankLinkMockRepository implements BankLinkRepository {
  BankLinkMockRepository();

  static const _institutions = [
    BankInstitution(id: 'vietcombank', name: 'Vietcombank'),
    BankInstitution(id: 'techcombank', name: 'Techcombank'),
    BankInstitution(id: 'mbbank', name: 'MB Bank'),
    BankInstitution(id: 'acb', name: 'ACB'),
    BankInstitution(id: 'bidv', name: 'BIDV'),
  ];

  final List<BankConnection> _connections = [];
  final List<PendingSyncedTransaction> _pending = [];
  var _sequence = 0;

  @override
  Future<List<BankInstitution>> fetchInstitutions() async => _institutions;

  @override
  Future<List<BankConnection>> fetchConnections() async =>
      List.unmodifiable(_connections);

  @override
  Future<BankConnection> linkInstitution({
    required String institutionId,
    required String consentToken,
  }) async {
    if (consentToken.trim().isEmpty) {
      throw const AppException(
        'errorBankLinkConsentRequired',
        code: 'BANK_LINK_CONSENT_REQUIRED',
      );
    }
    final institution = _institutions.where((item) => item.id == institutionId);
    if (institution.isEmpty) {
      throw const AppException(
        'errorBankLinkInstitutionNotFound',
        code: 'BANK_LINK_INSTITUTION_NOT_FOUND',
      );
    }
    _sequence += 1;
    final connection = BankConnection(
      id: 'mock-connection-$_sequence',
      institutionId: institution.first.id,
      institutionName: institution.first.name,
      maskedAccountNumber: '**** ${1000 + _sequence}',
      status: BankConnectionStatus.connected,
      provider: 'mock',
      createdAt: DateTime.now(),
    );
    _connections.add(connection);
    return connection;
  }

  @override
  Future<void> unlinkConnection(String connectionId) async {
    _connections.removeWhere((item) => item.id == connectionId);
    _pending.removeWhere((item) => item.bankConnectionId == connectionId);
  }

  @override
  Future<List<PendingSyncedTransaction>> syncConnection(
    String connectionId,
  ) async {
    final index = _connections.indexWhere((item) => item.id == connectionId);
    if (index == -1) {
      throw const AppException(
        'errorBankLinkConnectionNotFound',
        code: 'BANK_LINK_CONNECTION_NOT_FOUND',
      );
    }
    final generated = List.generate(2, (offset) {
      _sequence += 1;
      return PendingSyncedTransaction(
        id: 'mock-pending-$_sequence',
        bankConnectionId: connectionId,
        externalTransactionId: 'mock-ext-$_sequence',
        amount: 50000.0 + (offset * 35000),
        type: TransactionType.expense,
        transactionDate: DateTime.now().subtract(Duration(days: offset)),
        merchantName: offset.isEven ? 'Circle K' : 'Highlands Coffee',
        rawDescription: 'Mock synced transaction',
        status: PendingSyncedTransactionStatus.pending,
        createdAt: DateTime.now(),
      );
    });
    _pending.addAll(generated);
    _connections[index] = _connections[index].copyWith(
      status: BankConnectionStatus.connected,
      lastSyncedAt: DateTime.now(),
    );
    return generated;
  }

  @override
  Future<List<PendingSyncedTransaction>>
  fetchPendingSyncedTransactions() async {
    return _pending
        .where((item) => item.status == PendingSyncedTransactionStatus.pending)
        .toList(growable: false);
  }

  @override
  Future<void> markSyncedTransactionConfirmed({
    required String pendingId,
    required String transactionId,
  }) async {
    _updateStatus(pendingId, PendingSyncedTransactionStatus.confirmed);
  }

  @override
  Future<void> dismissSyncedTransaction(String pendingId) async {
    _updateStatus(pendingId, PendingSyncedTransactionStatus.dismissed);
  }

  void _updateStatus(String pendingId, PendingSyncedTransactionStatus status) {
    final index = _pending.indexWhere((item) => item.id == pendingId);
    if (index == -1) return;
    _pending[index] = _pending[index].copyWith(status: status);
  }
}
