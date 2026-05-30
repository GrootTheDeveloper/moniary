import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/account/active_session.dart';
import '../../data/account/account_repository.dart';

final activeSessionsControllerProvider =
    AsyncNotifierProvider<ActiveSessionsController, List<ActiveSession>>(
      ActiveSessionsController.new,
    );

class ActiveSessionsController extends AsyncNotifier<List<ActiveSession>> {
  @override
  Future<List<ActiveSession>> build() async {
    return _fetchSessions();
  }

  Future<List<ActiveSession>> _fetchSessions() async {
    return ref.read(accountRepositoryProvider).getActiveSessions();
  }

  Future<void> revokeSession(String sessionId) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(accountRepositoryProvider).revokeSession(sessionId);
      return _fetchSessions();
    });

    if (state.hasError) {
      // Revert if error occurs, but we still have error in state, so we might want to let the UI handle the error.
      // Usually, AsyncValue.guard sets the error.
    }
  }
}
