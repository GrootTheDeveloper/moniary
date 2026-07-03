import 'package:flutter/widgets.dart';

import '../../../l10n/l10n_extension.dart';
import '../domain/assistant_models.dart';

enum AssistantQuestionGroup { understand, alerts, actions }

class AssistantPrompt {
  const AssistantPrompt({
    required this.kind,
    required this.group,
    required this.text,
  });

  final AssistantQuestionKind kind;
  final AssistantQuestionGroup group;
  final String text;
}

List<AssistantPrompt> assistantPrompts(BuildContext context) {
  return [
    AssistantPrompt(
      kind: AssistantQuestionKind.monthlyTotal,
      group: AssistantQuestionGroup.understand,
      text: context.l10n.assistantQuestionMonthly,
    ),
    AssistantPrompt(
      kind: AssistantQuestionKind.topCategory,
      group: AssistantQuestionGroup.understand,
      text: context.l10n.assistantQuestionTopCategory,
    ),
    AssistantPrompt(
      kind: AssistantQuestionKind.weeklyComparison,
      group: AssistantQuestionGroup.understand,
      text: context.l10n.assistantQuestionWeekly,
    ),
    AssistantPrompt(
      kind: AssistantQuestionKind.dailyAverage,
      group: AssistantQuestionGroup.understand,
      text: context.l10n.assistantQuestionDaily,
    ),
    AssistantPrompt(
      kind: AssistantQuestionKind.recurringExpenses,
      group: AssistantQuestionGroup.alerts,
      text: context.l10n.assistantQuestionRecurring,
    ),
    AssistantPrompt(
      kind: AssistantQuestionKind.savingSuggestion,
      group: AssistantQuestionGroup.actions,
      text: context.l10n.assistantQuestionSaving,
    ),
  ];
}

class AssistantLaunch {
  const AssistantLaunch({required this.question, this.kind});

  final String question;
  final AssistantQuestionKind? kind;
}
