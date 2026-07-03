import 'assistant_models.dart';

abstract interface class AssistantRepository {
  Future<AssistantAccess> loadAccess();

  Future<void> saveAccess(AssistantAccess access);

  Future<FinancialAssistantSnapshot> buildSnapshot(DateTime now);
}
