import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/app_theme.dart';
import '../../../../l10n/l10n_extension.dart';
import '../../../../shared/utils/currency_formatting_ref.dart';
import '../../../../shared/utils/error_helpers.dart';
import '../../application/group_controller.dart';
import '../../domain/entities/group_community.dart';

class GroupParticipationScreen extends ConsumerWidget {
  const GroupParticipationScreen({required this.groupId, super.key});

  static const routePath = '/group-participation';
  final String groupId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final polls = ref.watch(groupPollsProvider(groupId));
    final challenges = ref.watch(groupSavingsChallengesProvider(groupId));
    final detail = ref.watch(groupDetailProvider(groupId)).asData?.value;
    final isAdmin = detail?.canInvite ?? false;
    return Scaffold(
      backgroundColor: context.moniaryColors.backgroundSoft,
      appBar: AppBar(title: Text(context.l10n.groupParticipationTitle)),
      floatingActionButton: isAdmin
          ? FloatingActionButton.extended(
              onPressed: () => _createChallenge(context, ref),
              icon: const Icon(Icons.savings_outlined),
              label: Text(context.l10n.groupChallengeCreate),
            )
          : null,
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 100),
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  context.l10n.groupPollsTitle,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              IconButton(
                tooltip: context.l10n.groupPollCreate,
                onPressed: () => _createPoll(context, ref),
                icon: const Icon(Icons.add_circle_outline),
              ),
            ],
          ),
          polls.when(
            loading: () => const LinearProgressIndicator(),
            error: (error, _) => Text(userFriendlyMessage(context, error)),
            data: (items) => items.isEmpty
                ? _Empty(text: context.l10n.groupPollsEmpty)
                : Column(
                    children: items
                        .map(
                          (poll) => _PollCard(
                            poll: poll,
                            onVote: (optionId) async {
                              try {
                                await ref
                                    .read(
                                      groupActionControllerProvider.notifier,
                                    )
                                    .votePoll(
                                      groupId: groupId,
                                      pollId: poll.id,
                                      optionId: optionId,
                                    );
                              } catch (error) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        userFriendlyMessage(context, error),
                                      ),
                                    ),
                                  );
                                }
                              }
                            },
                          ),
                        )
                        .toList(growable: false),
                  ),
          ),
          const SizedBox(height: 28),
          Text(
            context.l10n.groupChallengesTitle,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          challenges.when(
            loading: () => const LinearProgressIndicator(),
            error: (error, _) => Text(userFriendlyMessage(context, error)),
            data: (items) => items.isEmpty
                ? _Empty(text: context.l10n.groupChallengesEmpty)
                : Column(
                    children: items
                        .map(
                          (challenge) => _ChallengeCard(
                            challenge: challenge,
                            onContribute: () =>
                                _contribute(context, ref, challenge),
                          ),
                        )
                        .toList(growable: false),
                  ),
          ),
        ],
      ),
    );
  }

  Future<void> _createPoll(BuildContext context, WidgetRef ref) async {
    final result = await showDialog<(String, List<String>)>(
      context: context,
      builder: (_) => const _PollDialog(),
    );
    if (result == null || !context.mounted) return;
    try {
      await ref
          .read(groupActionControllerProvider.notifier)
          .createPoll(groupId: groupId, title: result.$1, options: result.$2);
      ref.invalidate(groupPollsProvider(groupId));
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(userFriendlyMessage(context, error))),
        );
      }
    }
  }

  Future<void> _createChallenge(BuildContext context, WidgetRef ref) async {
    final result = await showDialog<(String, int)>(
      context: context,
      builder: (_) => const _ChallengeDialog(),
    );
    if (result == null || !context.mounted) return;
    final now = DateTime.now();
    try {
      await ref
          .read(groupActionControllerProvider.notifier)
          .createSavingsChallenge(
            groupId: groupId,
            title: result.$1,
            targetAmount: result.$2,
            startDate: now,
            endDate: now.add(const Duration(days: 30)),
          );
      ref.invalidate(groupSavingsChallengesProvider(groupId));
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(userFriendlyMessage(context, error))),
        );
      }
    }
  }

  Future<void> _contribute(
    BuildContext context,
    WidgetRef ref,
    GroupSavingsChallenge challenge,
  ) async {
    final controller = TextEditingController();
    final amount = await showDialog<int>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(context.l10n.groupChallengeContribute),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: context.l10n.groupBudgetMonthlyLimit,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(context.l10n.commonCancel),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.pop(dialogContext, int.tryParse(controller.text)),
            child: Text(context.l10n.commonSave),
          ),
        ],
      ),
    );
    controller.dispose();
    if (amount == null || amount <= 0 || !context.mounted) return;
    try {
      await ref
          .read(groupActionControllerProvider.notifier)
          .addSavingsContribution(
            groupId: groupId,
            challengeId: challenge.id,
            amount: amount,
          );
      ref.invalidate(groupSavingsChallengesProvider(groupId));
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(userFriendlyMessage(context, error))),
        );
      }
    }
  }
}

class _PollCard extends StatelessWidget {
  const _PollCard({required this.poll, required this.onVote});
  final GroupPoll poll;
  final Future<void> Function(String optionId) onVote;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(poll.title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          for (final option in poll.options)
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(option.label),
              trailing: Text('${option.voteCount}'),
              onTap: poll.isClosed ? null : () => onVote(option.id),
            ),
        ],
      ),
    ),
  );
}

class _ChallengeCard extends ConsumerWidget {
  const _ChallengeCard({required this.challenge, required this.onContribute});
  final GroupSavingsChallenge challenge;
  final VoidCallback onContribute;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progress = (challenge.totalContributed / challenge.targetAmount)
        .clamp(0.0, 1.0)
        .toDouble();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              challenge.title,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 10),
            LinearProgressIndicator(value: progress),
            const SizedBox(height: 8),
            Text(
              '${ref.formatAmount(challenge.totalContributed)} / '
              '${ref.formatAmount(challenge.targetAmount)}',
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: challenge.isActive ? onContribute : null,
                icon: const Icon(Icons.add),
                label: Text(context.l10n.groupChallengeContribute),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty({required this.text});
  final String text;
  @override
  Widget build(BuildContext context) => Card(
    child: Padding(padding: const EdgeInsets.all(16), child: Text(text)),
  );
}

class _PollDialog extends StatefulWidget {
  const _PollDialog();
  @override
  State<_PollDialog> createState() => _PollDialogState();
}

class _PollDialogState extends State<_PollDialog> {
  final title = TextEditingController();
  final options = TextEditingController();
  @override
  void dispose() {
    title.dispose();
    options.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(context.l10n.groupPollCreate),
    content: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        TextField(
          controller: title,
          decoration: InputDecoration(
            labelText: context.l10n.groupPollQuestion,
          ),
        ),
        TextField(
          controller: options,
          minLines: 2,
          maxLines: 5,
          decoration: InputDecoration(
            labelText: context.l10n.groupPollOptionsHint,
          ),
        ),
      ],
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: Text(context.l10n.commonCancel),
      ),
      FilledButton(
        onPressed: () {
          final values = options.text
              .split('\n')
              .map((item) => item.trim())
              .where((item) => item.isNotEmpty)
              .toList();
          if (title.text.trim().isNotEmpty && values.length >= 2) {
            Navigator.pop(context, (title.text.trim(), values));
          }
        },
        child: Text(context.l10n.commonSave),
      ),
    ],
  );
}

class _ChallengeDialog extends StatefulWidget {
  const _ChallengeDialog();
  @override
  State<_ChallengeDialog> createState() => _ChallengeDialogState();
}

class _ChallengeDialogState extends State<_ChallengeDialog> {
  final title = TextEditingController();
  final amount = TextEditingController();
  @override
  void dispose() {
    title.dispose();
    amount.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(context.l10n.groupChallengeCreate),
    content: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        TextField(
          controller: title,
          decoration: InputDecoration(
            labelText: context.l10n.groupChallengeName,
          ),
        ),
        TextField(
          controller: amount,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: context.l10n.groupChallengeTarget,
          ),
        ),
      ],
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: Text(context.l10n.commonCancel),
      ),
      FilledButton(
        onPressed: () {
          final value = int.tryParse(amount.text);
          if (title.text.trim().isNotEmpty && value != null && value > 0) {
            Navigator.pop(context, (title.text.trim(), value));
          }
        },
        child: Text(context.l10n.commonSave),
      ),
    ],
  );
}
