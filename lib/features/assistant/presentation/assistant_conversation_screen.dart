import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/app_theme.dart';
import '../../../l10n/l10n_extension.dart';
import '../../../shared/utils/currency_formatting_ref.dart';
import '../../../shared/widgets/moniary_design.dart';
import '../application/assistant_controller.dart';
import '../domain/assistant_models.dart';
import 'assistant_intro_screen.dart';
import 'assistant_permission_screen.dart';
import 'assistant_question_catalog.dart';

class AssistantConversationScreen extends ConsumerStatefulWidget {
  const AssistantConversationScreen({this.launch, super.key});

  static const routePath = '/assistant/conversation';

  final AssistantLaunch? launch;

  @override
  ConsumerState<AssistantConversationScreen> createState() =>
      _AssistantConversationScreenState();
}

class _AssistantConversationScreenState
    extends ConsumerState<AssistantConversationScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final _focusNode = FocusNode();
  bool _launched = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      if (_focusNode.hasFocus) {
        Future.delayed(const Duration(milliseconds: 200), () {
          if (mounted) _scrollToEnd();
        });
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _askLaunch());
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accessAsync = ref.watch(assistantAccessProvider);
    final conversation = ref.watch(assistantConversationProvider);
    ref.listen(assistantConversationProvider, (_, _) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToEnd());
    });

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
        return _buildConversation(context, conversation);
      },
    );
  }

  Widget _buildConversation(
    BuildContext context,
    AsyncValue<AssistantConversationState> conversation,
  ) {
    final chat = conversation.value;
    final isSending = chat?.isSending ?? conversation.isLoading;
    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.assistantTitle),
        actions: [
          IconButton(
            tooltip: context.l10n.assistantPermissionTitle,
            onPressed: () => context.push(AssistantPermissionScreen.routePath),
            icon: const Icon(Icons.tune_outlined),
          ),
          IconButton(
            tooltip: context.l10n.commonDelete,
            onPressed: chat?.messages.isEmpty == true
                ? null
                : () =>
                      ref.read(assistantConversationProvider.notifier).clear(),
            icon: const Icon(Icons.delete_sweep_outlined),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(18, 8, 18, 14),
        child: TextField(
          controller: _controller,
          focusNode: _focusNode,
          enabled: !isSending,
          textInputAction: TextInputAction.send,
          onSubmitted: (_) => _send(),
          decoration: InputDecoration(
            hintText: context.l10n.assistantInputHint,
            suffixIcon: IconButton.filled(
              tooltip: context.l10n.assistantInputHint,
              onPressed: isSending ? null : _send,
              icon: const Icon(Icons.arrow_upward),
            ),
          ),
        ),
      ),
      body: conversation.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) =>
            Center(child: Text(context.l10n.assistantAnalysisError)),
        data: (chat) {
          final messages = chat.messages;
          if (messages.isEmpty) {
            return _AssistantEmptyState(
              onPromptSelected: (prompt) =>
                  _ask(prompt.text, kind: prompt.kind),
            );
          }
          return ListView.separated(
            controller: _scrollController,
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
            itemCount: messages.length + (chat.isSending ? 1 : 0),
            separatorBuilder: (_, _) => const SizedBox(height: 14),
            itemBuilder: (context, index) {
              if (index == messages.length) {
                final isVi = Localizations.localeOf(context).languageCode == 'vi';
                return _AssistantResponseShell(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox.square(
                        dimension: 16,
                        child: CircularProgressIndicator(strokeWidth: 1.8),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        isVi ? 'Đang phân tích...' : 'Analyzing...',
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w500,
                          color: context.moniaryColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                );
              }
              final message = messages[index];
              if (message.isUser) {
                return Align(
                  alignment: Alignment.centerRight,
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 300),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: context.moniaryColors.textPrimary.withValues(
                        alpha: 0.08,
                      ),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(18),
                        topRight: Radius.circular(6),
                        bottomLeft: Radius.circular(18),
                        bottomRight: Radius.circular(18),
                      ),
                    ),
                    child: Text(message.text!),
                  ),
                );
              }
              if (message.isError) {
                return _AssistantResponseShell(
                  child: Text(context.l10n.assistantAnalysisError),
                );
              }
              final assistantText = message.assistantText?.trim();
              if (message.insight != null) {
                return _InsightCard(
                  insight: message.insight!,
                  commentaryText: assistantText,
                );
              }
              if (assistantText != null && assistantText.isNotEmpty) {
                return _AssistantResponseShell(
                  child: _AssistantMessageText(assistantText),
                );
              }
              return const SizedBox.shrink();
            },
          );
        },
      ),
    );
  }

  Future<void> _askLaunch() async {
    if (_launched || widget.launch == null) return;
    _launched = true;
    final launch = widget.launch!;
    await _ask(launch.question, kind: launch.kind);
  }

  void _send() {
    final question = _controller.text.trim();
    if (question.isEmpty) return;
    _controller.clear();
    _ask(question);
  }

  Future<void> _ask(String question, {AssistantQuestionKind? kind}) async {
    try {
      await ref
          .read(assistantConversationProvider.notifier)
          .ask(question, kind: kind);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.assistantAnalysisError)),
      );
    }
  }

  void _scrollToEnd() {
    if (!_scrollController.hasClients) return;
    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent,
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
    );
  }
}

class _AssistantEmptyState extends StatelessWidget {
  const _AssistantEmptyState({required this.onPromptSelected});

  final ValueChanged<AssistantPrompt> onPromptSelected;

  @override
  Widget build(BuildContext context) {
    final prompts = assistantPrompts(context);
    final icons = [
      Icons.receipt_long_outlined,
      Icons.donut_large_outlined,
      Icons.compare_arrows,
      Icons.calendar_today_outlined,
    ];

    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 34, 24, 28),
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: Container(
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
        ),
        const SizedBox(height: 18),
        Text(
          context.l10n.assistantHomePrompt,
          style: context.moniaryTypography.displayMedium,
        ),
        MoniarySectionLabel(context.l10n.assistantSuggestionsTitle),
        for (var index = 0; index < math.min(4, prompts.length); index++)
          MoniaryHairlineTile(
            showTopDivider: index == 0,
            leading: Icon(icons[index], color: context.moniaryColors.primary),
            title: Text(prompts[index].text),
            trailing: const Icon(Icons.arrow_forward, size: 18),
            onTap: () => onPromptSelected(prompts[index]),
          ),
      ],
    );
  }
}

class _InsightCard extends ConsumerWidget {
  const _InsightCard({required this.insight, this.commentaryText});

  final AssistantInsight insight;
  final String? commentaryText;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final snapshot = insight.snapshot;
    final content = _answer(context, ref, snapshot);
    final primaryAmount = switch (insight.kind) {
      AssistantQuestionKind.monthlyTotal => snapshot.monthlyExpense,
      AssistantQuestionKind.weeklyComparison => snapshot.currentWeekExpense,
      AssistantQuestionKind.dailyAverage => snapshot.dailyAverage,
      AssistantQuestionKind.topCategory => snapshot.topCategoryAmount,
      AssistantQuestionKind.recurringExpenses => snapshot.recurringAmount,
      AssistantQuestionKind.savingSuggestion => snapshot.suggestedSaving,
      AssistantQuestionKind.greeting ||
      AssistantQuestionKind.userIdentity ||
      AssistantQuestionKind.assistantIdentity ||
      AssistantQuestionKind.unsupported => 0,
    };

    return _AssistantResponseShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.l10n.assistantTitle.toUpperCase(),
            style: context.moniaryTypography.metadataStrong.copyWith(
              color: context.moniaryColors.primary,
            ),
          ),
          const SizedBox(height: 12),
          if (primaryAmount > 0) ...[
            Text(
              ref.formatAmount(primaryAmount),
              style: context.moniaryTypography.displayMedium.copyWith(
                color: context.moniaryColors.textPrimary,
              ),
            ),
            const SizedBox(height: 10),
          ],
          Text(
            content,
            style: _assistantMessageTextStyle(context),
            softWrap: true,
            maxLines: null,
            overflow: TextOverflow.visible,
            textWidthBasis: TextWidthBasis.parent,
            strutStyle: _assistantMessageStrut(context),
          ),
          if (insight.kind == AssistantQuestionKind.topCategory &&
              snapshot.topCategoryName != null) ...[
            const SizedBox(height: 16),
            MoniaryProgressBar(
              value: snapshot.topCategoryShare,
              color: context.moniaryColors.primary,
            ),
          ],
          if (commentaryText?.trim().isNotEmpty == true) ...[
            const SizedBox(height: 14),
            Divider(color: context.moniaryColors.outline),
            const SizedBox(height: 10),
            Text(
              commentaryText!.trim(),
              style: _assistantMessageTextStyle(context),
              softWrap: true,
              maxLines: null,
              overflow: TextOverflow.visible,
              textWidthBasis: TextWidthBasis.parent,
              strutStyle: _assistantMessageStrut(context),
            ),
          ],
        ],
      ),
    );
  }

  String _answer(
    BuildContext context,
    WidgetRef ref,
    FinancialAssistantSnapshot snapshot,
  ) {
    if (snapshot.monthlyExpense <= 0) {
      return context.l10n.assistantNoData;
    }
    switch (insight.kind) {
      case AssistantQuestionKind.monthlyTotal:
        final previous = snapshot.previousMonthExpense;
        if (previous <= 0) {
          return context.l10n.assistantMonthlyAnswer(
            ref.formatAmount(snapshot.monthlyExpense),
          );
        }
        final delta =
            ((snapshot.monthlyExpense - previous).abs() / previous) * 100;
        final direction = snapshot.monthlyExpense >= previous
            ? context.l10n.assistantDirectionMore
            : context.l10n.assistantDirectionLess;
        return '${context.l10n.assistantMonthlyAnswer(ref.formatAmount(snapshot.monthlyExpense))} '
            '${context.l10n.assistantMonthlyCompare(direction, delta.toStringAsFixed(0))}';
      case AssistantQuestionKind.weeklyComparison:
        final previous = snapshot.previousWeekExpense;
        final delta = previous <= 0
            ? 0.0
            : ((snapshot.currentWeekExpense - previous).abs() / previous) * 100;
        final direction = snapshot.currentWeekExpense >= previous
            ? context.l10n.assistantDirectionMore.toLowerCase()
            : context.l10n.assistantDirectionLess.toLowerCase();
        return context.l10n.assistantWeeklyAnswer(
          ref.formatAmount(snapshot.currentWeekExpense),
          direction,
          delta.toStringAsFixed(0),
        );
      case AssistantQuestionKind.dailyAverage:
        return context.l10n.assistantDailyAnswer(
          ref.formatAmount(snapshot.dailyAverage),
        );
      case AssistantQuestionKind.topCategory:
        final category = snapshot.topCategoryName;
        if (category == null) return context.l10n.assistantNoData;
        return context.l10n.assistantTopCategoryAnswer(
          category,
          ref.formatAmount(snapshot.topCategoryAmount),
          (snapshot.topCategoryShare * 100).round().toString(),
        );
      case AssistantQuestionKind.recurringExpenses:
        final label = snapshot.recurringLabel;
        if (label == null || snapshot.recurringAmount <= 0) {
          return context.l10n.assistantNoData;
        }
        return context.l10n.assistantRecurringAnswer(
          label,
          math.max(1, snapshot.recurringCount),
          ref.formatAmount(snapshot.recurringAmount),
        );
      case AssistantQuestionKind.savingSuggestion:
        final category = snapshot.topCategoryName;
        if (category == null || snapshot.suggestedSaving <= 0) {
          return context.l10n.assistantNoData;
        }
        return context.l10n.assistantSavingAnswer(
          category,
          ref.formatAmount(math.max(0, snapshot.suggestedSaving)),
        );
      case AssistantQuestionKind.greeting:
      case AssistantQuestionKind.userIdentity:
      case AssistantQuestionKind.assistantIdentity:
      case AssistantQuestionKind.unsupported:
        return context.l10n.assistantNoData;
    }
  }
}

class _AssistantResponseShell extends StatelessWidget {
  const _AssistantResponseShell({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final maxBubbleWidth = math.min(
      MediaQuery.sizeOf(context).width - 56,
      320.0,
    );
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(maxWidth: maxBubbleWidth),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: context.moniaryColors.surface.withValues(alpha: 0.88),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(6),
            topRight: Radius.circular(22),
            bottomLeft: Radius.circular(22),
            bottomRight: Radius.circular(22),
          ),
          border: Border.all(color: context.moniaryColors.outline),
          boxShadow: [
            BoxShadow(
              color: context.moniaryColors.textPrimary.withValues(alpha: 0.04),
              blurRadius: 14,
              offset: const Offset(0, 7),
            ),
          ],
        ),
        child: child,
      ),
    );
  }
}

class _AssistantMessageText extends StatelessWidget {
  const _AssistantMessageText(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: _assistantMessageTextStyle(context),
      softWrap: true,
      maxLines: null,
      overflow: TextOverflow.visible,
      textWidthBasis: TextWidthBasis.parent,
      strutStyle: _assistantMessageStrut(context),
    );
  }
}

TextStyle _assistantMessageTextStyle(BuildContext context) {
  return Theme.of(context).textTheme.bodyLarge?.copyWith(
        color: context.moniaryColors.textPrimary,
        height: 1.55,
      ) ??
      TextStyle(
        color: context.moniaryColors.textPrimary,
        fontSize: 15,
        height: 1.55,
      );
}

StrutStyle _assistantMessageStrut(BuildContext context) {
  return StrutStyle.fromTextStyle(
    _assistantMessageTextStyle(context),
    forceStrutHeight: true,
  );
}
