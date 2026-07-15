import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../../../core/constants/app_constants.dart';
import '../../../core/preferences/preferences_providers.dart';
import '../../../core/supabase/app_exception.dart';
import '../../../core/supabase/supabase_providers.dart';
import '../../../shared/utils/app_logger.dart';
import '../../profile/application/profile_setup_controller.dart';
import '../data/assistant_repository_impl.dart';
import '../domain/assistant_language_config.dart';
import '../domain/assistant_models.dart';

final assistantAccessProvider =
    AsyncNotifierProvider<AssistantAccessNotifier, AssistantAccess>(
      AssistantAccessNotifier.new,
    );

final assistantAccessControllerProvider =
    AsyncNotifierProvider<AssistantAccessController, void>(
      AssistantAccessController.new,
    );

final assistantConversationProvider =
    AsyncNotifierProvider<
      AssistantConversationController,
      AssistantConversationState
    >(AssistantConversationController.new);

class AssistantAccessController extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<void> save(AssistantAccess access) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(assistantAccessProvider.notifier).save(access);
    });
    if (state.hasError) {
      Error.throwWithStackTrace(state.error!, state.stackTrace!);
    }
  }
}

class AssistantAccessNotifier extends AsyncNotifier<AssistantAccess> {
  @override
  Future<AssistantAccess> build() {
    ref.watch(currentSessionProvider);
    return ref.watch(assistantRepositoryProvider).loadAccess();
  }

  Future<void> save(AssistantAccess access) async {
    state = AsyncData(access);
    try {
      await ref.read(assistantRepositoryProvider).saveAccess(access);
      state = AsyncData(access);
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      Error.throwWithStackTrace(error, stackTrace);
    }
  }
}

class AssistantConversationController
    extends AsyncNotifier<AssistantConversationState> {
  @override
  Future<AssistantConversationState> build() async {
    ref.watch(currentSessionProvider);
    return const AssistantConversationState();
  }

  Future<void> ask(String question, {AssistantQuestionKind? kind}) async {
    final normalized = question.trim();
    if (normalized.isEmpty) return;
    final current = state.value ?? const AssistantConversationState();
    if (current.isSending) return;
    final access = await ref.read(assistantAccessProvider.future);
    if (!access.enabled) {
      throw const AppException(
        'Assistant access is disabled',
        code: 'ASSISTANT_ACCESS_DISABLED',
      );
    }
    final resolvedKind = kind ?? classifyAssistantQuestion(normalized);
    if (_isFinancialQuestion(resolvedKind) && !access.transactions) {
      throw const AppException(
        'Transaction access is disabled',
        code: 'ASSISTANT_TRANSACTION_ACCESS_DISABLED',
      );
    }

    final messages = current.messages;
    final withQuestion = [...messages, AssistantMessage.user(normalized)];
    final generation = current.generation + 1;
    state = AsyncData(
      current.copyWith(
        messages: withQuestion,
        isSending: true,
        generation: generation,
      ),
    );

    try {
      final locale = ref.read(preferredLocaleProvider);
      final currencyCode = ref.read(preferredCurrencyProvider);
      final profile = ref.read(currentProfileProvider).asData?.value;
      final snapshot = _isFinancialQuestion(resolvedKind)
          ? await ref
                .read(assistantRepositoryProvider)
                .buildSnapshot(
                  _snapshotWindowForProfile(
                    timezone: profile?.timezone,
                    firstDayOfWeek: ref.read(firstDayOfWeekProvider),
                  ),
                )
          : null;
      final answer = await ref
          .read(assistantRepositoryProvider)
          .generateAnswer(
            question: normalized,
            kind: resolvedKind,
            snapshot: snapshot,
            locale: locale,
            currencyCode: currencyCode,
            history: messages.takeLast(8).toList(),
            profileName: profile?.fullName,
          );
      final safeAnswer = _safeAssistantAnswer(answer, kind: resolvedKind);
      final latest = state.value;
      if (latest == null || latest.generation != generation) return;
      if (snapshot == null) {
        state = AsyncData(
          latest.copyWith(
            messages: [
              ...withQuestion,
              AssistantMessage.assistantText(
                safeAnswer ??
                    AssistantLanguageConfig.offlineFallback(locale: locale),
              ),
            ],
            isSending: false,
          ),
        );
        return;
      }
      state = AsyncData(
        latest.copyWith(
          messages: [
            ...withQuestion,
            AssistantMessage.assistant(
              AssistantInsight(kind: resolvedKind, snapshot: snapshot),
              assistantText: safeAnswer,
            ),
          ],
          isSending: false,
        ),
      );
    } catch (error, stackTrace) {
      AppLogger.error('Financial assistant analysis failed', error, stackTrace);
      final latest = state.value;
      if (latest == null || latest.generation != generation) rethrow;
      state = AsyncData(
        latest.copyWith(
          messages: [...withQuestion, const AssistantMessage.error()],
          isSending: false,
        ),
      );
      rethrow;
    }
  }

  void clear() {
    final current = state.value ?? const AssistantConversationState();
    state = AsyncData(
      current.copyWith(
        messages: const [],
        isSending: false,
        generation: current.generation + 1,
      ),
    );
  }
}

String? _safeAssistantAnswer(
  String? answer, {
  required AssistantQuestionKind kind,
}) {
  if (answer == null) return null;
  final safeAnswer = AssistantLanguageConfig.displaySafeAnswer(answer);
  if (safeAnswer.isEmpty ||
      AssistantLanguageConfig.looksTruncatedAnswer(safeAnswer)) {
    return null;
  }
  if (_isFinancialQuestion(kind) && RegExp(r'\d').hasMatch(safeAnswer)) {
    return null;
  }
  return safeAnswer;
}

AssistantQuestionKind classifyAssistantQuestion(String question) {
  final value = _normalizeQuery(question);

  if (_containsAny(value, AssistantLanguageConfig.weeklyKeywords)) {
    return AssistantQuestionKind.weeklyComparison;
  }
  if (_containsAny(value, AssistantLanguageConfig.dailyAverageKeywords)) {
    return AssistantQuestionKind.dailyAverage;
  }
  if (_containsAny(value, AssistantLanguageConfig.recurringKeywords)) {
    return AssistantQuestionKind.recurringExpenses;
  }
  if (_containsAny(value, AssistantLanguageConfig.savingKeywords)) {
    return AssistantQuestionKind.savingSuggestion;
  }
  if (_containsAny(value, AssistantLanguageConfig.topCategoryKeywords)) {
    return AssistantQuestionKind.topCategory;
  }
  if (_containsAny(value, AssistantLanguageConfig.monthlyKeywords)) {
    return AssistantQuestionKind.monthlyTotal;
  }

  if (_isGreeting(value)) {
    return AssistantQuestionKind.greeting;
  }
  if (_containsAny(value, AssistantLanguageConfig.userIdentityKeywords)) {
    return AssistantQuestionKind.userIdentity;
  }
  if (_containsAny(value, AssistantLanguageConfig.assistantIdentityKeywords)) {
    return AssistantQuestionKind.assistantIdentity;
  }
  return AssistantQuestionKind.unsupported;
}

bool _containsAny(String value, List<String> needles) {
  return needles.any(value.contains);
}

bool _isFinancialQuestion(AssistantQuestionKind kind) {
  return switch (kind) {
    AssistantQuestionKind.monthlyTotal ||
    AssistantQuestionKind.weeklyComparison ||
    AssistantQuestionKind.dailyAverage ||
    AssistantQuestionKind.topCategory ||
    AssistantQuestionKind.recurringExpenses ||
    AssistantQuestionKind.savingSuggestion => true,
    AssistantQuestionKind.greeting ||
    AssistantQuestionKind.userIdentity ||
    AssistantQuestionKind.assistantIdentity ||
    AssistantQuestionKind.unsupported => false,
  };
}

String _normalizeQuery(String value) {
  return value
      .toLowerCase()
      .replaceAll(RegExp(r'[àáạảãâầấậẩẫăằắặẳẵ]'), 'a')
      .replaceAll(RegExp(r'[èéẹẻẽêềếệểễ]'), 'e')
      .replaceAll(RegExp(r'[ìíịỉĩ]'), 'i')
      .replaceAll(RegExp(r'[òóọỏõôồốộổỗơờớợởỡ]'), 'o')
      .replaceAll(RegExp(r'[ùúụủũưừứựửữ]'), 'u')
      .replaceAll(RegExp(r'[ỳýỵỷỹ]'), 'y')
      .replaceAll('đ', 'd')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
}

bool _isGreeting(String value) {
  return AssistantLanguageConfig.exactGreetings.contains(value) ||
      value.startsWith('xin chao ') ||
      value.startsWith('chao ');
}

extension _AssistantMessageWindow on List<AssistantMessage> {
  Iterable<AssistantMessage> takeLast(int count) {
    if (length <= count) return this;
    return skip(length - count);
  }
}

AssistantSnapshotWindow _snapshotWindowForProfile({
  required String? timezone,
  required int firstDayOfWeek,
}) {
  try {
    tz_data.initializeTimeZones();
    final location = tz.getLocation(
      timezone?.trim().isNotEmpty == true
          ? timezone!.trim()
          : AppConstants.defaultTimezone,
    );
    final now = tz.TZDateTime.now(location);
    final today = tz.TZDateTime(location, now.year, now.month, now.day);
    final firstDay = firstDayOfWeek == DateTime.sunday
        ? DateTime.sunday
        : DateTime.monday;
    final delta = (today.weekday - firstDay + 7) % 7;
    final currentWeekStart = today.subtract(Duration(days: delta));
    return AssistantSnapshotWindow(
      now: now.toLocal(),
      previousMonthStart: tz.TZDateTime(
        location,
        now.year,
        now.month - 1,
      ).toLocal(),
      currentMonthStart: tz.TZDateTime(location, now.year, now.month).toLocal(),
      nextMonthStart: tz.TZDateTime(
        location,
        now.year,
        now.month + 1,
      ).toLocal(),
      previousWeekStart: currentWeekStart
          .subtract(const Duration(days: 7))
          .toLocal(),
      currentWeekStart: currentWeekStart.toLocal(),
      budgetMonth: DateTime(now.year, now.month),
      daysElapsed: today.day,
    );
  } catch (error, stackTrace) {
    AppLogger.error('Assistant timezone window failed', error, stackTrace);
    return AssistantSnapshotWindow.local(
      DateTime.now(),
      firstDayOfWeek: firstDayOfWeek,
    );
  }
}
