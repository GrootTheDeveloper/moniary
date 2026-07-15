import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/app_theme.dart';
import '../../../l10n/l10n_extension.dart';
import '../../../shared/widgets/moniary_design.dart';
import '../../profile/application/profile_setup_controller.dart';
import '../application/assistant_controller.dart';
import 'assistant_conversation_screen.dart';
import 'assistant_intro_screen.dart';
import 'assistant_permission_screen.dart';
import 'assistant_question_catalog.dart';
import 'assistant_question_library_screen.dart';

class AssistantHomeScreen extends ConsumerStatefulWidget {
  const AssistantHomeScreen({super.key});

  static const routePath = '/assistant';

  @override
  ConsumerState<AssistantHomeScreen> createState() =>
      _AssistantHomeScreenState();
}

class _AssistantHomeScreenState extends ConsumerState<AssistantHomeScreen> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accessAsync = ref.watch(assistantAccessProvider);
    return accessAsync.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (_, _) =>
          Scaffold(body: Center(child: Text(context.l10n.errorGeneric))),
      data: (access) {
        if (!access.introSeen || !access.enabled) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            context.go(
              access.introSeen
                  ? AssistantPermissionScreen.routePath
                  : AssistantIntroScreen.routePath,
            );
          });
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        return _buildHome(context);
      },
    );
  }

  Widget _buildHome(BuildContext context) {
    final prompts = assistantPrompts(context);
    final name =
        ref.watch(currentProfileProvider).value?.fullName?.trim() ??
        context.l10n.profileSurveyFallbackName;

    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.assistantTitle),
        leading: context.canPop()
            ? null
            : IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => context.go('/'),
              ),
        actions: [
          IconButton(
            tooltip: context.l10n.assistantOpenLibrary,
            onPressed: () =>
                context.push(AssistantQuestionLibraryScreen.routePath),
            icon: const Icon(Icons.library_books_outlined),
          ),
        ],
      ),
      bottomNavigationBar: _AssistantComposer(
        controller: _controller,
        onSend: _sendCustomQuestion,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(24, 6, 24, 28),
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: context.moniaryColors.primary,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.auto_awesome_outlined,
                  color: context.moniaryColors.surface,
                  size: 26,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.l10n.assistantGreeting(name),
                      style: context.moniaryTypography.displayMedium,
                    ),
                    const SizedBox(height: 5),
                    Text(
                      context.l10n.assistantHomePrompt,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ],
                ),
              ),
            ],
          ),
          MoniarySectionLabel(context.l10n.assistantSuggestionsTitle),
          SizedBox(
            height: 154,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: 3,
              separatorBuilder: (_, _) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final prompt = prompts[index];
                return SizedBox(
                  width: 226,
                  child: MoniaryEditorialCard(
                    onTap: () => _openPrompt(prompt),
                    radius: 20,
                    backgroundColor: index == 0
                        ? context.moniaryColors.primary.withValues(alpha: 0.09)
                        : context.moniaryColors.surface.withValues(alpha: 0.8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          [
                            Icons.receipt_long_outlined,
                            Icons.donut_large_outlined,
                            Icons.compare_arrows,
                          ][index],
                          color: context.moniaryColors.primary,
                        ),
                        const Spacer(),
                        Text(
                          prompt.text,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Icon(
                          Icons.arrow_forward,
                          size: 18,
                          color: context.moniaryColors.textDim,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          MoniarySectionLabel(
            context.l10n.assistantQuestionsTitle,
            trailing: TextButton(
              onPressed: () =>
                  context.push(AssistantQuestionLibraryScreen.routePath),
              child: Text(context.l10n.commonViewAll),
            ),
          ),
          for (var index = 0; index < 4; index++)
            MoniaryHairlineTile(
              showTopDivider: index == 0,
              onTap: () => _openPrompt(prompts[index]),
              title: Text(prompts[index].text),
              trailing: const Icon(Icons.arrow_forward, size: 18),
            ),
        ],
      ),
    );
  }

  void _openPrompt(AssistantPrompt prompt) {
    context.push(
      AssistantConversationScreen.routePath,
      extra: AssistantLaunch(question: prompt.text, kind: prompt.kind),
    );
  }

  void _sendCustomQuestion() {
    final value = _controller.text.trim();
    if (value.isEmpty) return;
    _controller.clear();
    context.push(
      AssistantConversationScreen.routePath,
      extra: AssistantLaunch(question: value),
    );
  }
}

class _AssistantComposer extends StatelessWidget {
  const _AssistantComposer({required this.controller, required this.onSend});

  final TextEditingController controller;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      minimum: const EdgeInsets.fromLTRB(18, 8, 18, 14),
      child: TextField(
        controller: controller,
        textInputAction: TextInputAction.send,
        onSubmitted: (_) => onSend(),
        decoration: InputDecoration(
          hintText: context.l10n.assistantInputHint,
          prefixIcon: const Icon(Icons.auto_awesome_outlined),
          suffixIcon: IconButton.filled(
            tooltip: context.l10n.assistantInputHint,
            onPressed: onSend,
            icon: const Icon(Icons.arrow_upward),
          ),
        ),
      ),
    );
  }
}
