import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../l10n/l10n_extension.dart';
import '../../../shared/widgets/moniary_design.dart';
import 'assistant_conversation_screen.dart';
import 'assistant_question_catalog.dart';

class AssistantQuestionLibraryScreen extends StatefulWidget {
  const AssistantQuestionLibraryScreen({super.key});

  static const routePath = '/assistant/questions';

  @override
  State<AssistantQuestionLibraryScreen> createState() =>
      _AssistantQuestionLibraryScreenState();
}

class _AssistantQuestionLibraryScreenState
    extends State<AssistantQuestionLibraryScreen> {
  AssistantQuestionGroup? _filter;

  @override
  Widget build(BuildContext context) {
    final prompts = assistantPrompts(context);
    final visible = _filter == null
        ? prompts
        : prompts.where((prompt) => prompt.group == _filter).toList();

    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.assistantQuestionLibraryTitle)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(24, 4, 24, 36),
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                MoniaryPill(
                  label: context.l10n.assistantFilterAll,
                  selected: _filter == null,
                  onTap: () => setState(() => _filter = null),
                ),
                const SizedBox(width: 8),
                MoniaryPill(
                  label: context.l10n.assistantFilterUnderstand,
                  selected: _filter == AssistantQuestionGroup.understand,
                  onTap: () => setState(
                    () => _filter = AssistantQuestionGroup.understand,
                  ),
                ),
                const SizedBox(width: 8),
                MoniaryPill(
                  label: context.l10n.assistantFilterAlerts,
                  selected: _filter == AssistantQuestionGroup.alerts,
                  onTap: () =>
                      setState(() => _filter = AssistantQuestionGroup.alerts),
                ),
                const SizedBox(width: 8),
                MoniaryPill(
                  label: context.l10n.assistantFilterActions,
                  selected: _filter == AssistantQuestionGroup.actions,
                  onTap: () =>
                      setState(() => _filter = AssistantQuestionGroup.actions),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          for (final group in AssistantQuestionGroup.values)
            if (visible.any((prompt) => prompt.group == group)) ...[
              MoniarySectionLabel(_groupLabel(context, group)),
              for (final prompt in visible.where(
                (prompt) => prompt.group == group,
              ))
                MoniaryHairlineTile(
                  showTopDivider:
                      prompt ==
                      visible.firstWhere((item) => item.group == group),
                  onTap: () => context.push(
                    AssistantConversationScreen.routePath,
                    extra: AssistantLaunch(
                      question: prompt.text,
                      kind: prompt.kind,
                    ),
                  ),
                  title: Text(prompt.text),
                  trailing: const Icon(Icons.arrow_forward, size: 18),
                ),
            ],
        ],
      ),
    );
  }

  String _groupLabel(BuildContext context, AssistantQuestionGroup group) {
    return switch (group) {
      AssistantQuestionGroup.understand =>
        context.l10n.assistantFilterUnderstand,
      AssistantQuestionGroup.alerts => context.l10n.assistantFilterAlerts,
      AssistantQuestionGroup.actions => context.l10n.assistantFilterActions,
    };
  }
}
