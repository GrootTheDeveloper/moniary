import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../app/app_theme.dart';
import '../../../../l10n/l10n_extension.dart';
import '../../../../shared/utils/currency_formatter.dart';
import '../../../../shared/utils/error_helpers.dart';
import '../../../../shared/widgets/supabase_image.dart';
import '../../application/group_controller.dart';
import '../../domain/entities/group_community.dart';
import '../../domain/entities/group_enums.dart';
import '../../domain/entities/group_settlement.dart';
import '../../domain/entities/group_transaction.dart';
import '../../domain/entities/spending_group.dart';
import 'add_group_transaction_screen.dart';
import 'debt_settlement_screen.dart';
import 'group_transaction_detail_screen.dart';
import 'invite_member_screen.dart';

class GroupDetailScreen extends ConsumerWidget {
  const GroupDetailScreen({required this.groupId, super.key});

  static const routePath = '/group-detail';

  final String groupId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync = ref.watch(groupDetailProvider(groupId));
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.groupDetailTitle)),
      body: detailAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _ErrorState(
          message: userFriendlyMessage(context, error),
          onRetry: () => ref.invalidate(groupDetailProvider(groupId)),
        ),
        data: (detail) {
          final currentUserId = ref.watch(currentGroupUserIdProvider);
          final transactionsAsync = ref.watch(
            groupTransactionsProvider(groupId),
          );
          final settlementsAsync = ref.watch(
            groupSettlementOverviewProvider(groupId),
          );
          final canLeaveGroup = _canLeaveGroup(
            settlementsAsync.asData?.value,
            currentUserId,
          );
          final statsAsync = ref.watch(groupStatsProvider(groupId));
          final activitiesAsync = ref.watch(groupActivitiesProvider(groupId));
          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(groupDetailProvider(groupId));
              ref.invalidate(groupTransactionsProvider(groupId));
              ref.invalidate(groupSettlementOverviewProvider(groupId));
              ref.invalidate(groupStatsProvider(groupId));
              ref.invalidate(groupActivitiesProvider(groupId));
            },
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
              children: [
                _GroupHeader(
                  name: detail.group.name,
                  type: detail.group.type,
                  description: detail.group.description,
                  avatarPath: detail.group.avatarPath,
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    if (detail.canInvite)
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => context.push(
                            InviteMemberScreen.routePath,
                            extra: groupId,
                          ),
                          icon: const Icon(Icons.person_add_outlined),
                          label: Text(context.l10n.groupInviteTitle),
                        ),
                      ),
                    if (detail.canInvite) const SizedBox(width: 10),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: detail.activeMembers.isEmpty
                            ? null
                            : () => context.push(
                                AddGroupTransactionScreen.routePath,
                                extra: AddGroupTransactionArgs(
                                  groupId: groupId,
                                ),
                              ),
                        icon: const Icon(Icons.add_outlined),
                        label: Text(context.l10n.groupAddTransaction),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 28),
                Text(
                  context.l10n.groupOverviewTitle,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                statsAsync.when(
                  loading: () => const LinearProgressIndicator(),
                  error: (_, _) => Text(context.l10n.groupStatsLoadError),
                  data: (stats) => _OverviewCards(stats: stats),
                ),
                const SizedBox(height: 26),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        context.l10n.groupDebtAreaTitle,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                    TextButton(
                      onPressed: () => context.push(
                        DebtSettlementScreen.routePath,
                        extra: groupId,
                      ),
                      child: Text(context.l10n.commonViewAll),
                    ),
                  ],
                ),
                settlementsAsync.when(
                  loading: () => const LinearProgressIndicator(),
                  error: (_, _) => Text(context.l10n.debtLoadError),
                  data: (overview) {
                    final unresolved = overview.suggestions
                        .where(
                          (item) =>
                              item.status != GroupSettlementStatus.completed,
                        )
                        .take(3)
                        .toList();
                    if (unresolved.isEmpty) {
                      return _Notice(
                        text: context.l10n.groupSettlementEmpty,
                        color: AppTheme.success,
                      );
                    }
                    return Column(
                      children: unresolved
                          .map(
                            (item) => ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: const Icon(
                                Icons.swap_horiz_outlined,
                                color: AppTheme.amber,
                              ),
                              title: Text(
                                context.l10n.groupSettlementFromTo(
                                  item.fromDisplayName ??
                                      context.l10n.groupUnknownMember,
                                  item.toDisplayName ??
                                      context.l10n.groupUnknownMember,
                                ),
                              ),
                              trailing: Text(formatVnd(item.amount)),
                            ),
                          )
                          .toList(),
                    );
                  },
                ),
                const SizedBox(height: 26),
                Text(
                  context.l10n.groupTransactionsTitle,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                transactionsAsync.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (_, _) => Text(context.l10n.groupTransactionLoadError),
                  data: (transactions) {
                    if (transactions.isEmpty) {
                      return _Notice(
                        text: context.l10n.groupTransactionNoData,
                        color: AppTheme.mintSoft,
                      );
                    }
                    return Column(
                      children: transactions
                          .map(
                            (transaction) => _TransactionCard(
                              transaction: transaction,
                              onTap: () => context.push(
                                GroupTransactionDetailScreen.routePath,
                                extra: transaction.id,
                              ),
                            ),
                          )
                          .toList(),
                    );
                  },
                ),
                const SizedBox(height: 26),
                Text(
                  context.l10n.groupMembersHeader,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 10),
                ...detail.members.map(
                  (member) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(
                      backgroundColor: AppTheme.surfaceRaised,
                      child: const Icon(Icons.person_outline),
                    ),
                    title: Text(member.resolvedName),
                    subtitle: Text(
                      member.status == GroupMemberStatus.active
                          ? context.l10n.groupMemberActive
                          : context.l10n.groupMemberInvited,
                    ),
                    trailing: _MemberTrailing(
                      member: member,
                      canTransferOwnership:
                          detail.currentUserRole == GroupRole.owner &&
                          member.isActive &&
                          member.userId != currentUserId,
                      onTransferOwnership: () =>
                          _transferOwnership(context, ref, member),
                    ),
                  ),
                ),
                const SizedBox(height: 26),
                Text(
                  context.l10n.groupActivitiesTitle,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 10),
                activitiesAsync.when(
                  loading: () => const LinearProgressIndicator(),
                  error: (_, _) => Text(context.l10n.groupActivitiesLoadError),
                  data: (activities) => _ActivityList(activities: activities),
                ),
                const SizedBox(height: 18),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    OutlinedButton.icon(
                      onPressed: canLeaveGroup
                          ? () => _leaveGroup(context, ref)
                          : null,
                      icon: const Icon(Icons.logout_outlined),
                      label: Text(context.l10n.groupLeave),
                    ),
                    if (!canLeaveGroup)
                      const Padding(
                        padding: EdgeInsets.only(top: 8),
                        child: Text(
                          'Bạn còn khoản nợ chưa xử lý. Vui lòng thanh toán trước khi rời nhóm.',
                          style: TextStyle(color: AppTheme.amber),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _leaveGroup(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.l10n.groupLeaveConfirmTitle),
        content: Text(context.l10n.groupLeaveConfirmMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(context.l10n.commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(context.l10n.groupLeave),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    try {
      await ref
          .read(groupActionControllerProvider.notifier)
          .leaveGroup(groupId);
      if (!context.mounted) return;
      context.go('/groups');
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(userFriendlyMessage(context, error))),
      );
    }
  }

  bool _canLeaveGroup(GroupSettlementOverview? overview, String currentUserId) {
    if (overview == null) return true;
    final userBalance = overview.balances
        .where((balance) => balance.userId == currentUserId)
        .fold<int>(0, (sum, balance) => sum + balance.balance);
    final hasUnresolvedSettlements = overview.suggestions.any(
      (settlement) =>
          (settlement.fromUserId == currentUserId ||
              settlement.toUserId == currentUserId) &&
          (settlement.status == GroupSettlementStatus.pending ||
              settlement.status == GroupSettlementStatus.payerMarkedPaid),
    );
    return userBalance == 0 && !hasUnresolvedSettlements;
  }

  Future<void> _transferOwnership(
    BuildContext context,
    WidgetRef ref,
    SpendingGroupMember member,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.l10n.groupTransferOwnership),
        content: Text(
          context.l10n.groupTransferOwnershipConfirm(member.resolvedName),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(context.l10n.commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(context.l10n.groupTransferOwnership),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    try {
      await ref
          .read(groupActionControllerProvider.notifier)
          .transferOwnership(groupId: groupId, newOwnerUserId: member.userId);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.groupTransferOwnershipDone)),
      );
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(userFriendlyMessage(context, error))),
      );
    }
  }
}

class _MemberTrailing extends StatelessWidget {
  const _MemberTrailing({
    required this.member,
    required this.canTransferOwnership,
    required this.onTransferOwnership,
  });

  final SpendingGroupMember member;
  final bool canTransferOwnership;
  final VoidCallback onTransferOwnership;

  @override
  Widget build(BuildContext context) {
    if (!canTransferOwnership) {
      return Text(member.role.value);
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(member.role.value),
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_horiz),
          onSelected: (value) {
            if (value == 'transfer_owner') {
              onTransferOwnership();
            }
          },
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'transfer_owner',
              child: Row(
                children: [
                  const Icon(Icons.workspace_premium_outlined),
                  const SizedBox(width: 10),
                  Text(context.l10n.groupTransferOwnership),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _GroupHeader extends StatelessWidget {
  const _GroupHeader({
    required this.name,
    required this.type,
    required this.description,
    required this.avatarPath,
  });

  final String name;
  final String? type;
  final String? description;
  final String? avatarPath;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SupabaseImage(
          imagePath: avatarPath,
          width: 88,
          height: 88,
          borderRadius: BorderRadius.circular(28),
          fallbackIcon: Icons.groups_2_outlined,
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name, style: Theme.of(context).textTheme.headlineMedium),
              if (type?.isNotEmpty == true) ...[
                const SizedBox(height: 5),
                Text(type!, style: const TextStyle(color: AppTheme.mintSoft)),
              ],
              if (description?.isNotEmpty == true) ...[
                const SizedBox(height: 7),
                Text(description!),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _OverviewCards extends StatelessWidget {
  const _OverviewCards({required this.stats});

  final GroupStatsOverview stats;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        SizedBox(
          width: (MediaQuery.sizeOf(context).width - 50) / 2,
          child: _MetricCard(
            icon: Icons.payments_outlined,
            label: context.l10n.groupTransactionTotal,
            value: formatVnd(stats.totalSpent),
          ),
        ),
        SizedBox(
          width: (MediaQuery.sizeOf(context).width - 50) / 2,
          child: _MetricCard(
            icon: Icons.people_outline,
            label: context.l10n.groupMembersHeader,
            value: stats.memberCount.toString(),
          ),
        ),
        SizedBox(
          width: (MediaQuery.sizeOf(context).width - 50) / 2,
          child: _MetricCard(
            icon: Icons.receipt_long_outlined,
            label: context.l10n.groupStatsTransactionCount,
            value: stats.transactionCount.toString(),
          ),
        ),
        SizedBox(
          width: (MediaQuery.sizeOf(context).width - 50) / 2,
          child: _MetricCard(
            icon: Icons.pending_actions_outlined,
            label: context.l10n.groupStatsPendingCount,
            value:
                '${stats.pendingTransactionCount + stats.pendingSettlementCount}',
          ),
        ),
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceRaised,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppTheme.mintSoft),
          const SizedBox(height: 12),
          Text(label, style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 4),
          Text(value, style: Theme.of(context).textTheme.titleMedium),
        ],
      ),
    );
  }
}

class _TransactionCard extends StatelessWidget {
  const _TransactionCard({required this.transaction, required this.onTap});

  final GroupTransaction transaction;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final status = switch (transaction.splitStatus) {
      GroupSplitStatus.posted => context.l10n.groupTransactionPostedStatus,
      GroupSplitStatus.amountMismatch =>
        context.l10n.groupTransactionMismatchStatus,
      _ => context.l10n.groupTransactionPendingStatus,
    };
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.all(14),
        leading: SupabaseImage(
          imagePath: transaction.imagePath,
          width: 54,
          height: 54,
          borderRadius: BorderRadius.circular(16),
          fallbackIcon: Icons.receipt_long_outlined,
        ),
        title: Text(
          transaction.caption?.isNotEmpty == true
              ? transaction.caption!
              : transaction.categoryName ?? context.l10n.groupNoCategory,
        ),
        subtitle: Text(
          '$status • ${DateFormat('dd/MM/yyyy HH:mm').format(transaction.transactionDate)}',
        ),
        trailing: Text(
          formatVnd(transaction.totalAmount),
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}

class _Notice extends StatelessWidget {
  const _Notice({required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Text(text, style: TextStyle(color: color)),
    );
  }
}

class _ActivityList extends StatelessWidget {
  const _ActivityList({required this.activities});

  final List<GroupActivity> activities;

  @override
  Widget build(BuildContext context) {
    if (activities.isEmpty) {
      return _Notice(
        text: context.l10n.groupActivitiesEmpty,
        color: AppTheme.mintSoft,
      );
    }
    return Column(
      children: activities
          .take(5)
          .map(
            (activity) => ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(
                Icons.history_outlined,
                color: AppTheme.mintSoft,
              ),
              title: Text(_activityText(context, activity)),
              subtitle: Text(
                DateFormat('dd/MM/yyyy HH:mm').format(activity.createdAt),
              ),
            ),
          )
          .toList(),
    );
  }

  String _activityText(BuildContext context, GroupActivity activity) {
    final actor = activity.actorName ?? context.l10n.groupUnknownMember;
    switch (activity.type) {
      case 'member_joined':
        return context.l10n.groupActivityMemberJoined(actor);
      case 'member_left':
        return context.l10n.groupActivityMemberLeft(actor);
      case 'leave_blocked_unresolved':
        return context.l10n.groupLeaveWarningActivity;
      case 'transaction_created':
        return context.l10n.groupActivityTransactionCreated(actor);
      case 'transaction_posted':
        return context.l10n.groupActivityTransactionPosted(actor);
      case 'owner_transferred':
        return context.l10n.groupActivityOwnerTransferred(actor);
      default:
        return context.l10n.groupActivityGeneric(actor);
    }
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(message),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: onRetry,
            child: Text(context.l10n.commonRetry),
          ),
        ],
      ),
    );
  }
}
