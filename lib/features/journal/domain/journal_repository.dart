import 'journal_models.dart';

abstract interface class JournalRepository {
  Future<MonthlyRecap> fetchMonthlyRecap(DateTime month);

  Future<RecordingStreak> fetchRecordingStreak(DateTime today);

  Future<List<JournalCollectionSummary>> fetchCollections();

  Future<JournalCollectionSummary> fetchCollection(String collectionId);

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
