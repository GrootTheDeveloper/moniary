import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/repositories/bank_link_repository_impl.dart';
import '../domain/models/bank_connection.dart';
import '../domain/models/bank_institution.dart';
import 'bank_sync_review_controller.dart';

final bankInstitutionsProvider = FutureProvider<List<BankInstitution>>((ref) {
  return ref.watch(bankLinkRepositoryProvider).fetchInstitutions();
});

final bankLinkControllerProvider =
    AsyncNotifierProvider<BankLinkController, List<BankConnection>>(
      BankLinkController.new,
    );

class BankLinkController extends AsyncNotifier<List<BankConnection>> {
  @override
  Future<List<BankConnection>> build() {
    return ref.watch(bankLinkRepositoryProvider).fetchConnections();
  }

  Future<BankConnection> linkInstitution({
    required String institutionId,
    required String consentToken,
  }) async {
    state = const AsyncLoading();
    try {
      final repo = ref.read(bankLinkRepositoryProvider);
      final connection = await repo.linkInstitution(
        institutionId: institutionId,
        consentToken: consentToken,
      );
      state = AsyncData(await repo.fetchConnections());
      return connection;
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      rethrow;
    }
  }

  Future<void> unlinkConnection(String connectionId) async {
    state = const AsyncLoading();
    try {
      final repo = ref.read(bankLinkRepositoryProvider);
      await repo.unlinkConnection(connectionId);
      state = AsyncData(await repo.fetchConnections());
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      rethrow;
    }
  }

  // Unlike linkInstitution/unlinkConnection, a sync failure does not mean the
  // existing connection list is stale or invalid — most notably, syncing
  // fails on every attempt until a real aggregator is wired up. Leave `state`
  // untouched on failure so the list stays visible and only the triggering
  // screen's snackbar reports the error.
  Future<int> syncConnection(String connectionId) async {
    final repo = ref.read(bankLinkRepositoryProvider);
    final pending = await repo.syncConnection(connectionId);
    state = AsyncData(await repo.fetchConnections());
    ref.invalidate(bankSyncReviewControllerProvider);
    return pending.length;
  }
}
