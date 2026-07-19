import '../models/bank_connection.dart';
import '../models/bank_institution.dart';
import '../models/pending_synced_transaction.dart';

abstract interface class BankLinkRepository {
  Future<List<BankInstitution>> fetchInstitutions();

  Future<List<BankConnection>> fetchConnections();

  Future<BankConnection> linkInstitution({
    required String institutionId,
    required String consentToken,
  });

  Future<void> unlinkConnection(String connectionId);

  Future<List<PendingSyncedTransaction>> syncConnection(String connectionId);

  Future<List<PendingSyncedTransaction>> fetchPendingSyncedTransactions();

  Future<void> markSyncedTransactionConfirmed({
    required String pendingId,
    required String transactionId,
  });

  Future<void> dismissSyncedTransaction(String pendingId);
}
