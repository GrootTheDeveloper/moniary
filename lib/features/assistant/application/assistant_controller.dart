import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/utils/app_logger.dart';
import '../data/assistant_repository_impl.dart';
import '../domain/assistant_models.dart';

final assistantAccessProvider = FutureProvider<AssistantAccess>((ref) {
  return ref.watch(assistantRepositoryProvider).loadAccess();
});

final assistantAccessControllerProvider =
    AsyncNotifierProvider<AssistantAccessController, void>(
      AssistantAccessController.new,
    );

final assistantConversationProvider =
    AsyncNotifierProvider<
      AssistantConversationController,
      List<AssistantMessage>
    >(AssistantConversationController.new);

class AssistantAccessController extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<void> save(AssistantAccess access) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(assistantRepositoryProvider).saveAccess(access);
      ref.invalidate(assistantAccessProvider);
    });
    if (state.hasError) {
      Error.throwWithStackTrace(state.error!, state.stackTrace!);
    }
  }
}

class AssistantConversationController
    extends AsyncNotifier<List<AssistantMessage>> {
  @override
  Future<List<AssistantMessage>> build() async => const [];

  Future<void> ask(String question, {AssistantQuestionKind? kind}) async {
    final normalized = question.trim();
    if (normalized.isEmpty) return;
    final messages = state.value ?? const <AssistantMessage>[];
    final withQuestion = [...messages, AssistantMessage.user(normalized)];
    state = AsyncData(withQuestion);

    try {
      final snapshot = await ref
          .read(assistantRepositoryProvider)
          .buildSnapshot(DateTime.now());
      final resolvedKind = kind ?? classifyAssistantQuestion(normalized);
      state = AsyncData([
        ...withQuestion,
        AssistantMessage.assistant(
          AssistantInsight(kind: resolvedKind, snapshot: snapshot),
        ),
      ]);
    } catch (error, stackTrace) {
      AppLogger.error('Financial assistant analysis failed', error, stackTrace);
      state = AsyncData([...withQuestion, const AssistantMessage.error()]);
      rethrow;
    }
  }

  void clear() {
    state = const AsyncData([]);
  }
}

AssistantQuestionKind classifyAssistantQuestion(String question) {
  final value = question.toLowerCase();
  if (_containsAny(value, ['tuần', 'week', 'so với'])) {
    return AssistantQuestionKind.weeklyComparison;
  }
  if (_containsAny(value, ['trung bình', 'mỗi ngày', 'daily', 'average'])) {
    return AssistantQuestionKind.dailyAverage;
  }
  if (_containsAny(value, ['lặp lại', 'nhiều lần', 'recurring', 'repeat'])) {
    return AssistantQuestionKind.recurringExpenses;
  }
  if (_containsAny(value, ['cắt giảm', 'tiết kiệm', 'giảm', 'save'])) {
    return AssistantQuestionKind.savingSuggestion;
  }
  if (_containsAny(value, ['hạng mục', 'danh mục', 'nhiều nhất', 'top'])) {
    return AssistantQuestionKind.topCategory;
  }
  return AssistantQuestionKind.monthlyTotal;
}

bool _containsAny(String value, List<String> needles) {
  return needles.any(value.contains);
}
