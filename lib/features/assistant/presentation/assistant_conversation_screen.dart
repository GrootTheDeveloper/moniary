import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/app_theme.dart';
import '../../../l10n/l10n_extension.dart';
import '../../../shared/utils/currency_formatter.dart';
import '../../../shared/widgets/moniary_design.dart';
import '../application/assistant_controller.dart';
import '../domain/assistant_models.dart';
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
  bool _launched = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _askLaunch());
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final conversation = ref.watch(assistantConversationProvider);
    ref.listen(assistantConversationProvider, (_, _) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToEnd());
    });

    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.assistantTitle),
        actions: [
          IconButton(
            tooltip: context.l10n.commonDelete,
            onPressed: () =>
                ref.read(assistantConversationProvider.notifier).clear(),
            icon: const Icon(Icons.delete_sweep_outlined),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(18, 8, 18, 14),
        child: TextField(
          controller: _controller,
          textInputAction: TextInputAction.send,
          onSubmitted: (_) => _send(),
          decoration: InputDecoration(
            hintText: context.l10n.assistantInputHint,
            suffixIcon: IconButton.filled(
              tooltip: context.l10n.assistantInputHint,
              onPressed: conversation.isLoading ? null : _send,
              icon: const Icon(Icons.arrow_upward),
            ),
          ),
        ),
      ),
      body: conversation.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) =>
            Center(child: Text(context.l10n.assistantAnalysisError)),
        data: (messages) {
          if (messages.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Text(
                  context.l10n.assistantHomePrompt,
                  textAlign: TextAlign.center,
                  style: context.moniaryTypography.displayMedium,
                ),
              ),
            );
          }
          return ListView.separated(
            controller: _scrollController,
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
            itemCount: messages.length,
            separatorBuilder: (_, _) => const SizedBox(height: 14),
            itemBuilder: (context, index) {
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
              return _InsightCard(insight: message.insight!);
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

class _InsightCard extends StatelessWidget {
  const _InsightCard({required this.insight});

  final AssistantInsight insight;

  @override
  Widget build(BuildContext context) {
    final snapshot = insight.snapshot;
    final content = _answer(context, snapshot);
    final primaryAmount = switch (insight.kind) {
      AssistantQuestionKind.monthlyTotal => snapshot.monthlyExpense,
      AssistantQuestionKind.weeklyComparison => snapshot.currentWeekExpense,
      AssistantQuestionKind.dailyAverage => snapshot.dailyAverage,
      AssistantQuestionKind.topCategory => snapshot.topCategoryAmount,
      AssistantQuestionKind.recurringExpenses => snapshot.recurringAmount,
      AssistantQuestionKind.savingSuggestion => snapshot.suggestedSaving,
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
              formatVnd(primaryAmount),
              style: context.moniaryTypography.displayMedium.copyWith(
                color: context.moniaryColors.textPrimary,
              ),
            ),
            const SizedBox(height: 10),
          ],
          Text(
            content,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: context.moniaryColors.textPrimary,
              height: 1.55,
            ),
          ),
          if (insight.kind == AssistantQuestionKind.topCategory &&
              snapshot.topCategoryName != null) ...[
            const SizedBox(height: 16),
            MoniaryProgressBar(
              value: snapshot.topCategoryShare,
              color: context.moniaryColors.primary,
            ),
          ],
        ],
      ),
    );
  }

  String _answer(BuildContext context, FinancialAssistantSnapshot snapshot) {
    if (snapshot.monthlyExpense <= 0) {
      return context.l10n.assistantNoData;
    }
    switch (insight.kind) {
      case AssistantQuestionKind.monthlyTotal:
        final previous = snapshot.previousMonthExpense;
        if (previous <= 0) {
          return context.l10n.assistantMonthlyAnswer(
            formatVnd(snapshot.monthlyExpense),
          );
        }
        final delta =
            ((snapshot.monthlyExpense - previous).abs() / previous) * 100;
        final direction = snapshot.monthlyExpense >= previous
            ? context.l10n.assistantDirectionMore
            : context.l10n.assistantDirectionLess;
        return '${context.l10n.assistantMonthlyAnswer(formatVnd(snapshot.monthlyExpense))} '
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
          formatVnd(snapshot.currentWeekExpense),
          direction,
          delta.toStringAsFixed(0),
        );
      case AssistantQuestionKind.dailyAverage:
        return context.l10n.assistantDailyAnswer(
          formatVnd(snapshot.dailyAverage),
        );
      case AssistantQuestionKind.topCategory:
        final category = snapshot.topCategoryName;
        if (category == null) return context.l10n.assistantNoData;
        return context.l10n.assistantTopCategoryAnswer(
          category,
          formatVnd(snapshot.topCategoryAmount),
          (snapshot.topCategoryShare * 100).round().toString(),
        );
      case AssistantQuestionKind.recurringExpenses:
        final label = snapshot.recurringLabel;
        if (label == null || snapshot.recurringCount < 2) {
          return context.l10n.assistantNoData;
        }
        return context.l10n.assistantRecurringAnswer(
          label,
          snapshot.recurringCount,
          formatVnd(snapshot.recurringAmount),
        );
      case AssistantQuestionKind.savingSuggestion:
        final category = snapshot.topCategoryName;
        if (category == null || snapshot.suggestedSaving <= 0) {
          return context.l10n.assistantNoData;
        }
        return context.l10n.assistantSavingAnswer(
          category,
          formatVnd(math.max(0, snapshot.suggestedSaving)),
        );
    }
  }
}

class _AssistantResponseShell extends StatelessWidget {
  const _AssistantResponseShell({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 330),
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
