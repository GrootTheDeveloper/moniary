import 'assistant_models.dart';

abstract interface class AssistantRepository {
  Future<AssistantAccess> loadAccess();

  Future<void> saveAccess(AssistantAccess access);

  Future<FinancialAssistantSnapshot> buildSnapshot(
    AssistantSnapshotWindow window,
  );

  Future<String?> generateAnswer({
    required String question,
    required AssistantQuestionKind kind,
    required String locale,
    required String currencyCode,
    required List<AssistantMessage> history,
    FinancialAssistantSnapshot? snapshot,
    String? profileName,
  });
}
