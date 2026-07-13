import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/journal_repository_impl.dart';
import '../domain/journal_models.dart';

final monthlyRecapProvider = FutureProvider.family<MonthlyRecap, DateTime>((
  ref,
  month,
) {
  return ref.watch(journalRepositoryProvider).fetchMonthlyRecap(month);
});

final recordingStreakProvider = FutureProvider<RecordingStreak>((ref) {
  return ref
      .watch(journalRepositoryProvider)
      .fetchRecordingStreak(DateTime.now());
});

final journalCollectionsProvider =
    FutureProvider<List<JournalCollectionSummary>>((ref) {
      return ref.watch(journalRepositoryProvider).fetchCollections();
    });

final journalCollectionProvider =
    FutureProvider.family<JournalCollectionSummary, String>((
      ref,
      collectionId,
    ) {
      return ref.watch(journalRepositoryProvider).fetchCollection(collectionId);
    });

final journalActionControllerProvider =
    AsyncNotifierProvider<JournalActionController, void>(
      JournalActionController.new,
    );

class JournalActionController extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<String> createCollection({
    required String name,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    state = const AsyncLoading();
    try {
      final id = await ref
          .read(journalRepositoryProvider)
          .createCollection(name: name, startDate: startDate, endDate: endDate);
      ref.invalidate(journalCollectionsProvider);
      state = const AsyncData(null);
      return id;
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      rethrow;
    }
  }

  Future<void> addTransaction({
    required String collectionId,
    required String transactionId,
  }) async {
    state = const AsyncLoading();
    try {
      await ref
          .read(journalRepositoryProvider)
          .addTransaction(
            collectionId: collectionId,
            transactionId: transactionId,
          );
      ref.invalidate(journalCollectionsProvider);
      ref.invalidate(journalCollectionProvider(collectionId));
      state = const AsyncData(null);
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      rethrow;
    }
  }
}
