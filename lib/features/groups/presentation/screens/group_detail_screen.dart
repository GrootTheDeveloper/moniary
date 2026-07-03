import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../app/app_theme.dart';
import '../../../../l10n/l10n_extension.dart';
import '../../../../shared/utils/currency_formatter.dart';
import '../../../../shared/utils/error_helpers.dart';
import '../../../../shared/widgets/moniary_design.dart';
import '../../../../shared/widgets/supabase_image.dart';
import '../../application/group_controller.dart';
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
    final transactionsAsync = ref.watch(groupTransactionsProvider(groupId));
    final settlementsAsync = ref.watch(
      groupSettlementOverviewProvider(groupId),
    );

    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.groupDetailTitle)),
      body: detailAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _ErrorState(
          message: userFriendlyMessage(context, error),
          onRetry: () => ref.invalidate(groupDetailProvider(groupId)),
        ),
        data: (detail) => RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(groupDetailProvider(groupId));
            ref.invalidate(groupTransactionsProvider(groupId));
            ref.invalidate(groupSettlementOverviewProvider(groupId));
          },
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 4, 24, 40),
            children: [
              _GroupHero(
                detail: detail,
                transactionsAsync: transactionsAsync,
                onSettle: () => context.push(
                  DebtSettlementScreen.routePath,
                  extra: groupId,
                ),
              ),
              MoniarySectionLabel(context.l10n.groupBalanceTableTitle),
              settlementsAsync.when(
                loading: () => const LinearProgressIndicator(),
                error: (_, _) => _InlineNotice(
                  text: context.l10n.debtLoadError,
                  color: context.moniaryColors.danger,
                ),
                data: (overview) => _MemberBalances(
                  overview: overview,
                  members: detail.members,
                ),
              ),
              MoniarySectionLabel(context.l10n.groupTransactionsTitle),
              transactionsAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (_, _) => _InlineNotice(
                  text: context.l10n.groupTransactionLoadError,
                  color: context.moniaryColors.danger,
                ),
                data: (transactions) {
                  if (transactions.isEmpty) {
                    return _InlineNotice(
                      text: context.l10n.groupTransactionNoData,
                      color: context.moniaryColors.secondary,
                    );
                  }
                  return Column(
                    children: [
                      for (var index = 0; index < transactions.length; index++)
                        _TransactionRow(
                          transaction: transactions[index],
                          showTopDivider: index == 0,
                          onTap: () => context.push(
                            GroupTransactionDetailScreen.routePath,
                            extra: transactions[index].id,
                          ),
                        ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: detail.activeMembers.isEmpty
                    ? null
                    : () => context.push(
                        AddGroupTransactionScreen.routePath,
                        extra: AddGroupTransactionArgs(groupId: groupId),
                      ),
                icon: const Icon(Icons.add),
                label: Text(context.l10n.groupAddTransaction),
              ),
              MoniarySectionLabel(
                context.l10n.groupMembersHeader,
                trailing: detail.canInvite
                    ? TextButton.icon(
                        onPressed: () => context.push(
                          InviteMemberScreen.routePath,
                          extra: groupId,
                        ),
                        icon: const Icon(Icons.person_add_outlined, size: 18),
                        label: Text(context.l10n.groupInviteTitle),
                      )
                    : null,
              ),
              for (var index = 0; index < detail.members.length; index++)
                _MemberRow(
                  member: detail.members[index],
                  showTopDivider: index == 0,
                ),
              const SizedBox(height: 24),
              OutlinedButton.icon(
                onPressed: () => _leaveGroup(context, ref),
                icon: const Icon(Icons.logout_outlined),
                label: Text(context.l10n.groupLeave),
              ),
            ],
          ),
        ),
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
      if (context.mounted) context.go('/groups');
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(userFriendlyMessage(context, error))),
      );
    }
  }
}

class _GroupHero extends StatelessWidget {
  const _GroupHero({
    required this.detail,
    required this.transactionsAsync,
    required this.onSettle,
  });

  final SpendingGroupDetail detail;
  final AsyncValue<List<GroupTransaction>> transactionsAsync;
  final VoidCallback onSettle;

  @override
  Widget build(BuildContext context) {
    final colors = context.moniaryColors;
    final group = detail.group;
    final balance = group.currentUserBalance;
    final balanceColor = balance == 0
        ? colors.success
        : balance > 0
        ? colors.danger
        : colors.success;
    final transactionCount = transactionsAsync.asData?.value.length;
    final total = transactionsAsync.asData?.value.fold<int>(
      0,
      (sum, item) => item.splitStatus == GroupSplitStatus.posted
          ? sum + item.totalAmount
          : sum,
    );

    return MoniaryEditorialCard(
      padding: const EdgeInsets.all(20),
      radius: 22,
      backgroundColor: colors.surface.withValues(alpha: 0.9),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SupabaseImage(
                imagePath: group.avatarPath,
                width: 58,
                height: 58,
                borderRadius: BorderRadius.circular(18),
                fallbackIcon: Icons.groups_2_outlined,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      group.name,
                      style: context.moniaryTypography.displayMedium,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      [
                        context.l10n.groupMemberCount(
                          detail.activeMembers.length,
                        ),
                        if (transactionCount != null)
                          context.l10n.transactionCount(transactionCount),
                        if (total != null) formatVnd(total),
                      ].join(' · ').toUpperCase(),
                      style: context.moniaryTypography.metadata,
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (group.description?.trim().isNotEmpty == true) ...[
            const SizedBox(height: 16),
            Text(group.description!),
          ],
          const SizedBox(height: 22),
          Container(
            padding: const EdgeInsets.only(top: 16),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: colors.textPrimary.withValues(alpha: 0.12),
                ),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        balance > 0
                            ? context.l10n.groupYouNeedPay
                            : balance < 0
                            ? context.l10n.groupOthersNeedPayYou
                            : context.l10n.groupBalanceSettled,
                        style: context.moniaryTypography.metadataStrong
                            .copyWith(color: balanceColor),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        formatVnd(balance.abs()),
                        style: context.moniaryTypography.displayMedium.copyWith(
                          color: balanceColor,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    ],
                  ),
                ),
                TextButton.icon(
                  onPressed: onSettle,
                  iconAlignment: IconAlignment.end,
                  icon: const Icon(Icons.arrow_forward, size: 18),
                  label: Text(context.l10n.groupSettlementTitle),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MemberBalances extends StatelessWidget {
  const _MemberBalances({required this.overview, required this.members});

  final GroupSettlementOverview overview;
  final List<SpendingGroupMember> members;

  @override
  Widget build(BuildContext context) {
    if (overview.balances.isEmpty) {
      return _InlineNotice(
        text: context.l10n.debtNoData,
        color: context.moniaryColors.secondary,
      );
    }

    return Column(
      children: [
        for (var index = 0; index < overview.balances.length; index++)
          _BalanceRow(
            balance: overview.balances[index],
            avatarPath: _avatarFor(overview.balances[index].userId),
            showTopDivider: index == 0,
          ),
      ],
    );
  }

  String? _avatarFor(String userId) {
    for (final member in members) {
      if (member.userId == userId) return member.avatarPath;
    }
    return null;
  }
}

class _BalanceRow extends StatelessWidget {
  const _BalanceRow({
    required this.balance,
    required this.avatarPath,
    required this.showTopDivider,
  });

  final GroupBalance balance;
  final String? avatarPath;
  final bool showTopDivider;

  @override
  Widget build(BuildContext context) {
    final colors = context.moniaryColors;
    final valueColor = balance.balance == 0
        ? colors.textDim
        : balance.balance > 0
        ? colors.danger
        : colors.success;

    return MoniaryHairlineTile(
      showTopDivider: showTopDivider,
      leading: SupabaseImage(
        imagePath: avatarPath,
        width: 34,
        height: 34,
        borderRadius: BorderRadius.circular(17),
        fallbackIcon: Icons.person_outline,
      ),
      title: Text(balance.displayName ?? context.l10n.groupUnknownMember),
      subtitle: Text(
        context.l10n.groupSharePaidBalance(
          formatVnd(balance.totalShareAmount),
          formatVnd(balance.totalPaidAmount),
          formatVnd(balance.balance),
        ),
      ),
      trailing: Text(
        balance.balance == 0
            ? context.l10n.groupBalanceSettled
            : '${balance.balance > 0 ? '−' : '+'}${formatVnd(balance.balance.abs())}',
        style: context.moniaryTypography.metadataStrong.copyWith(
          color: valueColor,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      ),
    );
  }
}

class _TransactionRow extends StatelessWidget {
  const _TransactionRow({
    required this.transaction,
    required this.onTap,
    required this.showTopDivider,
  });

  final GroupTransaction transaction;
  final VoidCallback onTap;
  final bool showTopDivider;

  @override
  Widget build(BuildContext context) {
    final status = switch (transaction.splitStatus) {
      GroupSplitStatus.posted => context.l10n.groupTransactionPostedStatus,
      GroupSplitStatus.amountMismatch =>
        context.l10n.groupTransactionMismatchStatus,
      _ => context.l10n.groupTransactionPendingStatus,
    };

    return MoniaryHairlineTile(
      showTopDivider: showTopDivider,
      contentPadding: const EdgeInsets.symmetric(vertical: 12),
      onTap: onTap,
      leading: SupabaseImage(
        imagePath: transaction.imagePath,
        width: 42,
        height: 42,
        borderRadius: BorderRadius.circular(12),
        fallbackIcon: Icons.receipt_long_outlined,
      ),
      title: Text(
        transaction.caption?.trim().isNotEmpty == true
            ? transaction.caption!
            : transaction.categoryName ?? context.l10n.groupNoCategory,
      ),
      subtitle: Text(
        '$status · ${DateFormat('dd/MM/yyyy').format(transaction.transactionDate)}',
      ),
      trailing: Text(
        formatVnd(transaction.totalAmount),
        style: context.moniaryTypography.metadataStrong.copyWith(
          color: context.moniaryColors.textPrimary,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      ),
    );
  }
}

class _MemberRow extends StatelessWidget {
  const _MemberRow({required this.member, required this.showTopDivider});

  final SpendingGroupMember member;
  final bool showTopDivider;

  @override
  Widget build(BuildContext context) {
    return MoniaryHairlineTile(
      showTopDivider: showTopDivider,
      leading: SupabaseImage(
        imagePath: member.avatarPath,
        width: 34,
        height: 34,
        borderRadius: BorderRadius.circular(17),
        fallbackIcon: Icons.person_outline,
      ),
      title: Text(member.resolvedName),
      subtitle: Text(
        member.status == GroupMemberStatus.active
            ? context.l10n.groupMemberActive
            : context.l10n.groupMemberInvited,
      ),
      trailing: Text(
        member.role.value.toUpperCase(),
        style: context.moniaryTypography.metadata,
      ),
    );
  }
}

class _InlineNotice extends StatelessWidget {
  const _InlineNotice({required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return MoniaryEditorialCard(
      backgroundColor: color.withValues(alpha: 0.08),
      borderColor: color.withValues(alpha: 0.25),
      child: Text(text),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: onRetry,
              child: Text(context.l10n.commonRetry),
            ),
          ],
        ),
      ),
    );
  }
}
