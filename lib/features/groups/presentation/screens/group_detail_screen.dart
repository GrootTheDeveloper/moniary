import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/app_theme.dart';
import '../../../../core/supabase/app_exception.dart';
import '../../../../l10n/l10n_extension.dart';
import '../../../../shared/utils/currency_formatting_ref.dart';
import '../../../../shared/utils/error_helpers.dart';
import '../../../../shared/widgets/moniary_design.dart';
import '../../../../shared/widgets/supabase_image.dart';
import '../../application/group_controller.dart';
import '../../domain/entities/group_enums.dart';
import '../../domain/entities/group_settlement.dart';
import '../../domain/entities/group_transaction.dart';
import '../../domain/entities/spending_group.dart';
import 'group_route_paths.dart';
import '../widgets/group_transaction_filter_bar.dart';

enum _MemberAction { transferOwnership, remove }

class GroupDetailScreen extends ConsumerWidget {
  const GroupDetailScreen({required this.groupId, super.key});

  static const routePath = '/group-detail';

  final String groupId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync = ref.watch(groupDetailProvider(groupId));
    final settlementsAsync = ref.watch(
      groupSettlementOverviewProvider(groupId),
    );
    final colors = context.moniaryColors;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: colors.backgroundSoft,
        systemNavigationBarDividerColor: Colors.transparent,
      ),
      child: Scaffold(
        backgroundColor: colors.backgroundSoft,
        body: detailAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => _ErrorState(
            message: userFriendlyMessage(context, error),
            onRetry: () => ref.invalidate(groupDetailProvider(groupId)),
          ),
          data: (detail) => _GroupDetailContent(
            groupId: groupId,
            detail: detail,
            settlementsAsync: settlementsAsync,
            onRefresh: () async {
              ref.invalidate(groupDetailProvider(groupId));
              ref.invalidate(groupTransactionsPageProvider);
              ref.invalidate(groupSettlementOverviewProvider(groupId));
            },
            onActions: () => _showGroupActions(context, ref, detail),
            onSettle: () => context.push(GroupRoutePaths.settlements(groupId)),
            onSummary: () => context.push(GroupRoutePaths.summary(groupId)),
            onCommunity: () => context.go(GroupRoutePaths.community(groupId)),
            onAddTransaction: detail.activeMembers.isEmpty
                ? null
                : () => context.push(GroupRoutePaths.transactionForm(groupId)),
          ),
        ),
      ),
    );
  }

  Future<void> _showGroupActions(
    BuildContext context,
    WidgetRef ref,
    SpendingGroupDetail detail,
  ) async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  detail.group.name,
                  style: context.moniaryTypography.displaySmall,
                ),
                const SizedBox(height: 16),
                if (detail.canInvite)
                  ListTile(
                    leading: const Icon(Icons.person_add_outlined),
                    title: Text(context.l10n.groupInviteTitle),
                    onTap: () {
                      Navigator.pop(sheetContext);
                      context.push(GroupRoutePaths.invite(groupId));
                    },
                  ),
                if (detail.canInvite)
                  ListTile(
                    leading: const Icon(Icons.manage_accounts_outlined),
                    title: Text(context.l10n.groupMembersHeader),
                    onTap: () {
                      Navigator.pop(sheetContext);
                      _manageMembers(context, ref, detail);
                    },
                  ),
                ListTile(
                  leading: const Icon(Icons.forum_outlined),
                  title: Text(context.l10n.groupActivityCenterTitle),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    context.go(GroupRoutePaths.community(groupId));
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.tune_outlined),
                  title: Text(context.l10n.groupManageTitle),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    context.go(GroupRoutePaths.management(groupId));
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.logout_outlined),
                  title: Text(context.l10n.groupLeave),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _leaveGroup(context, ref);
                  },
                ),
              ],
            ),
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
      final code = error is AppException ? error.code : null;
      final shouldOpenSettlements =
          code == 'GROUP_LEAVE_UNRESOLVED' ||
          code == 'GROUP_LEAVE_DISPUTED_SETTLEMENT';
      final shouldOpenGroup =
          code == 'GROUP_LEAVE_INCOMPLETE_TRANSACTION' ||
          code == 'GROUP_OWNER_TRANSFER_REQUIRED';
      await showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text(context.l10n.groupLeaveBlockedTitle),
          content: Text(userFriendlyMessage(context, error)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(context.l10n.commonCancel),
            ),
            if (shouldOpenSettlements || shouldOpenGroup)
              FilledButton(
                onPressed: () {
                  Navigator.pop(dialogContext);
                  if (shouldOpenSettlements) {
                    context.push(GroupRoutePaths.settlements(groupId));
                  } else {
                    context.go(GroupRoutePaths.home(groupId));
                  }
                },
                child: Text(
                  shouldOpenSettlements
                      ? context.l10n.groupLeaveViewSettlements
                      : context.l10n.groupLeaveViewGroup,
                ),
              ),
          ],
        ),
      );
    }
  }

  Future<void> _manageMembers(
    BuildContext context,
    WidgetRef ref,
    SpendingGroupDetail detail,
  ) async {
    final currentUserId = ref.read(currentGroupUserIdProvider);
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheetContext) => SafeArea(
        child: SizedBox(
          height: MediaQuery.sizeOf(sheetContext).height * 0.7,
          child: Column(
            children: [
              ListTile(
                title: Text(
                  context.l10n.groupMembersHeader,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              Expanded(
                child: ListView(
                  children: [
                    for (final member in detail.activeMembers)
                      ListTile(
                        leading: const Icon(Icons.person_outline),
                        title: Text(member.resolvedName),
                        subtitle: Text(member.role.value.toUpperCase()),
                        trailing:
                            !_canManageMember(detail, member, currentUserId)
                            ? null
                            : PopupMenuButton<_MemberAction>(
                                onSelected: (action) {
                                  Navigator.pop(sheetContext);
                                  if (action ==
                                      _MemberAction.transferOwnership) {
                                    _transferOwnership(context, ref, member);
                                  } else {
                                    _removeMember(context, ref, member);
                                  }
                                },
                                itemBuilder: (context) => [
                                  if (detail.currentUserRole == GroupRole.owner)
                                    PopupMenuItem(
                                      value: _MemberAction.transferOwnership,
                                      child: Text(
                                        context
                                            .l10n
                                            .groupTransferOwnershipAction,
                                      ),
                                    ),
                                  if (detail.currentUserRole ==
                                          GroupRole.owner ||
                                      (detail.currentUserRole ==
                                              GroupRole.admin &&
                                          member.role == GroupRole.member))
                                    PopupMenuItem(
                                      value: _MemberAction.remove,
                                      child: Text(
                                        context.l10n.groupRemoveMemberAction,
                                      ),
                                    ),
                                ],
                              ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _transferOwnership(
    BuildContext context,
    WidgetRef ref,
    SpendingGroupMember member,
  ) async {
    final confirmed = await _confirmMemberAction(
      context,
      title: context.l10n.groupTransferOwnershipAction,
      member: member,
    );
    if (!confirmed || !context.mounted) return;
    try {
      await ref
          .read(groupActionControllerProvider.notifier)
          .transferOwnership(groupId: groupId, newOwnerUserId: member.userId);
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(userFriendlyMessage(context, error))),
      );
    }
  }

  bool _canManageMember(
    SpendingGroupDetail detail,
    SpendingGroupMember member,
    String currentUserId,
  ) {
    if (member.userId == currentUserId || member.role == GroupRole.owner) {
      return false;
    }
    return detail.currentUserRole == GroupRole.owner ||
        (detail.currentUserRole == GroupRole.admin &&
            member.role == GroupRole.member);
  }

  Future<void> _removeMember(
    BuildContext context,
    WidgetRef ref,
    SpendingGroupMember member,
  ) async {
    final confirmed = await _confirmMemberAction(
      context,
      title: context.l10n.groupRemoveMemberConfirm,
      member: member,
    );
    if (!confirmed || !context.mounted) return;
    try {
      await ref
          .read(groupActionControllerProvider.notifier)
          .removeMember(groupId: groupId, userId: member.userId);
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(userFriendlyMessage(context, error))),
      );
    }
  }

  Future<bool> _confirmMemberAction(
    BuildContext context, {
    required String title,
    required SpendingGroupMember member,
  }) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(title),
            content: Text(member.resolvedName),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(context.l10n.commonCancel),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text(context.l10n.commonConfirm),
              ),
            ],
          ),
        ) ??
        false;
  }
}

class _GroupDetailContent extends StatelessWidget {
  const _GroupDetailContent({
    required this.groupId,
    required this.detail,
    required this.settlementsAsync,
    required this.onRefresh,
    required this.onActions,
    required this.onSettle,
    required this.onSummary,
    required this.onCommunity,
    required this.onAddTransaction,
  });

  final String groupId;
  final SpendingGroupDetail detail;
  final AsyncValue<GroupSettlementOverview> settlementsAsync;
  final Future<void> Function() onRefresh;
  final VoidCallback onActions;
  final VoidCallback onSettle;
  final VoidCallback onSummary;
  final VoidCallback onCommunity;
  final VoidCallback? onAddTransaction;

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;
    return Stack(
      children: [
        SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 393),
              child: RefreshIndicator(
                color: context.moniaryColors.primary,
                backgroundColor: context.moniaryColors.backgroundSoft,
                onRefresh: onRefresh,
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(30, 12, 30, 126),
                  children: [
                    _DetailTopBar(onActions: onActions),
                    const SizedBox(height: 16),
                    _GroupHero(
                      detail: detail,
                      onSettle: onSettle,
                      onSummary: onSummary,
                    ),
                    const SizedBox(height: 16),
                    _GroupCollapsibleSection(
                      title: context.l10n.groupTransactionsTitle,
                      subtitle: context.l10n.groupTransactionCount(
                        detail.group.transactionCount,
                      ),
                      icon: Icons.receipt_long_outlined,
                      initiallyExpanded: true,
                      child: _TransactionHistory(
                        groupId: groupId,
                        memberCount: detail.activeMembers.length,
                        isPreview: true,
                        onViewAll: () =>
                            context.push(GroupRoutePaths.transactions(groupId)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _GroupCollapsibleSection(
                      title: context.l10n.groupMemberBalanceTitle,
                      subtitle: context.l10n.groupMemberCount(
                        detail.activeMembers.length,
                      ),
                      icon: Icons.people_outline,
                      child: settlementsAsync.when(
                        loading: () => const Padding(
                          padding: EdgeInsets.all(18),
                          child: LinearProgressIndicator(),
                        ),
                        error: (_, _) => _InlineNotice(
                          text: context.l10n.debtLoadError,
                          color: context.moniaryColors.danger,
                        ),
                        data: (overview) => _MemberBalances(
                          overview: overview,
                          members: detail.members,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        Positioned(
          left: 30,
          right: 30,
          bottom: bottomInset + 18,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 333),
              child: SizedBox(
                height: 50,
                child: FloatingActionButton.extended(
                  heroTag: 'group-add-transaction',
                  onPressed: onAddTransaction,
                  icon: const Icon(Icons.add_outlined, size: 20),
                  label: Text(context.l10n.groupAddTransaction),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _GroupCollapsibleSection extends StatelessWidget {
  const _GroupCollapsibleSection({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.child,
    this.initiallyExpanded = false,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Widget child;
  final bool initiallyExpanded;

  @override
  Widget build(BuildContext context) {
    final colors = context.moniaryColors;
    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      color: colors.surface.withValues(alpha: 0.72),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colors.outline.withValues(alpha: 0.8)),
      ),
      child: Theme(
        data: Theme.of(
          context,
        ).copyWith(dividerColor: colors.surface.withValues(alpha: 0)),
        child: ExpansionTile(
          initiallyExpanded: initiallyExpanded,
          tilePadding: const EdgeInsets.symmetric(horizontal: 14),
          childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
          leading: Icon(icon, color: colors.primary),
          title: Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          subtitle: Text(subtitle),
          children: [child],
        ),
      ),
    );
  }
}

class _DetailTopBar extends StatelessWidget {
  const _DetailTopBar({required this.onActions});

  final VoidCallback onActions;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: _TopIconButton(
              icon: Icons.arrow_back_outlined,
              label: MaterialLocalizations.of(context).backButtonTooltip,
              onTap: () => context.pop(),
            ),
          ),
          Text(
            context.l10n.groupDetailKindLabel.toUpperCase(),
            style: context.moniaryTypography.metadataStrong.copyWith(
              color: context.moniaryColors.textDim,
              fontSize: 9,
              letterSpacing: 3.2,
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: _TopIconButton(
              icon: Icons.more_vert_outlined,
              label: context.l10n.groupMoreActions,
              onTap: onActions,
            ),
          ),
        ],
      ),
    );
  }
}

class _TopIconButton extends StatelessWidget {
  const _TopIconButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.moniaryColors;
    return Semantics(
      button: true,
      label: label,
      child: Material(
        color: colors.surface.withValues(alpha: 0.54),
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: colors.outline.withValues(alpha: 0.8)),
            ),
            child: Icon(icon, size: 22, color: colors.textPrimary),
          ),
        ),
      ),
    );
  }
}

class _GroupHero extends ConsumerWidget {
  const _GroupHero({
    required this.detail,
    required this.onSettle,
    required this.onSummary,
  });

  final SpendingGroupDetail detail;
  final VoidCallback onSettle;
  final VoidCallback onSummary;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.moniaryColors;
    final group = detail.group;
    final balance = group.currentUserBalance;
    final isSettled = balance == 0;
    final balanceColor = isSettled
        ? colors.success
        : balance > 0
        ? colors.danger
        : colors.success;
    final balanceLabel = isSettled
        ? context.l10n.groupBalanceSettled
        : balance > 0
        ? context.l10n.groupDetailYouPay
        : context.l10n.groupDetailReceiveBack;
    final transactionCount = group.transactionCount;
    final totalText = ref.formatAmount(group.totalSpent);

    return MoniaryEditorialCard(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SupabaseImage(
                imagePath: group.avatarPath,
                width: 60,
                height: 60,
                borderRadius: BorderRadius.circular(18),
                fallbackBuilder: (_) => const _GroupImageFallback(),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      group.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.moniaryTypography.displaySmall.copyWith(
                        fontSize: 25,
                        height: 1.05,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Text(
                      context.l10n.groupMemberCount(
                        detail.activeMembers.length,
                      ),
                      style: context.moniaryTypography.metadata.copyWith(
                        color: colors.textDim,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 7),
                    SizedBox(
                      height: 24,
                      child: Stack(
                        children: [
                          for (
                            var index = 0;
                            index < detail.activeMembers.take(5).length;
                            index++
                          )
                            Positioned(
                              left: index * 18,
                              child: SupabaseImage(
                                imagePath: detail.activeMembers
                                    .elementAt(index)
                                    .avatarPath,
                                width: 24,
                                height: 24,
                                borderRadius: BorderRadius.circular(14),
                                fallbackBuilder: (_) =>
                                    const _MemberAvatarFallback(),
                              ),
                            ),
                          if (detail.activeMembers.length > 5)
                            Positioned(
                              left: 5 * 18,
                              child: Container(
                                width: 24,
                                height: 24,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: colors.backgroundSoft,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: colors.surface),
                                ),
                                child: Text(
                                  '+${detail.activeMembers.length - 5}',
                                  style: Theme.of(
                                    context,
                                  ).textTheme.labelSmall?.copyWith(fontSize: 8),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (group.description?.trim().isNotEmpty == true) ...[
            const SizedBox(height: 10),
            Text(
              group.description!,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: colors.textSecondary),
            ),
          ],
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _HeroMetric(
                  label: context.l10n.groupSummaryTotalSpent,
                  value: totalText,
                  color: colors.textPrimary,
                ),
              ),
              Container(
                width: 1,
                height: 40,
                color: colors.outline.withValues(alpha: 0.7),
              ),
              Expanded(
                child: _HeroMetric(
                  label: balanceLabel,
                  value: ref.formatAmount(balance.abs()),
                  color: balanceColor,
                  alignEnd: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          Container(
            height: 7,
            decoration: BoxDecoration(
              color: colors.outline.withValues(alpha: 0.32),
              borderRadius: BorderRadius.circular(8),
            ),
            alignment: Alignment.centerLeft,
            child: FractionallySizedBox(
              widthFactor: (transactionCount / (transactionCount + 4)).clamp(
                0.08,
                1.0,
              ),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: colors.primary,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Text(
                  context.l10n.groupTransactionCount(transactionCount),
                  style: context.moniaryTypography.metadata.copyWith(
                    color: colors.textDim,
                    fontSize: 9,
                  ),
                ),
              ),
              Text(
                isSettled
                    ? context.l10n.groupBalanceSettled
                    : context.l10n.groupSettlementTitle,
                style: context.moniaryTypography.metadata.copyWith(
                  color: isSettled ? colors.success : colors.textDim,
                  fontSize: 9,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onSummary,
                  icon: const Icon(Icons.insights_outlined, size: 16),
                  label: Text(context.l10n.groupSummaryTitle),
                ),
              ),
              if (!isSettled) ...[
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton.tonalIcon(
                    onPressed: onSettle,
                    icon: const Icon(Icons.swap_horiz_outlined, size: 16),
                    label: Text(context.l10n.groupSettleAction),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroMetric extends StatelessWidget {
  const _HeroMetric({
    required this.label,
    required this.value,
    required this.color,
    this.alignEnd = false,
  });

  final String label;
  final String value;
  final Color color;
  final bool alignEnd;

  @override
  Widget build(BuildContext context) {
    final alignment = alignEnd
        ? CrossAxisAlignment.end
        : CrossAxisAlignment.start;
    return Column(
      crossAxisAlignment: alignment,
      children: [
        Text(
          label,
          textAlign: alignEnd ? TextAlign.end : TextAlign.start,
          style: context.moniaryTypography.metadata.copyWith(
            color: context.moniaryColors.textDim,
            fontSize: 9,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          textAlign: alignEnd ? TextAlign.end : TextAlign.start,
          style: context.moniaryTypography.displaySmall.copyWith(
            color: color,
            fontSize: 18,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ],
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

class _BalanceRow extends ConsumerWidget {
  const _BalanceRow({
    required this.balance,
    required this.avatarPath,
    required this.showTopDivider,
  });

  final GroupBalance balance;
  final String? avatarPath;
  final bool showTopDivider;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.moniaryColors;
    final valueColor = balance.balance == 0
        ? colors.textDim
        : balance.balance > 0
        ? colors.danger
        : colors.success;
    final valueText = balance.balance == 0
        ? ref.formatAmount(0)
        : '${balance.balance > 0 ? '-' : '+'}${ref.formatAmount(balance.balance.abs())}';

    return Container(
      constraints: const BoxConstraints(minHeight: 62),
      padding: const EdgeInsets.symmetric(vertical: 11),
      decoration: BoxDecoration(
        border: Border(
          top: showTopDivider
              ? BorderSide(
                  color: colors.textPrimary.withValues(alpha: 0.11),
                  width: 0.8,
                )
              : BorderSide.none,
          bottom: BorderSide(
            color: colors.textPrimary.withValues(alpha: 0.11),
            width: 0.8,
          ),
        ),
      ),
      child: Row(
        children: [
          SupabaseImage(
            imagePath: avatarPath,
            width: 37,
            height: 37,
            borderRadius: BorderRadius.circular(20),
            fallbackBuilder: (_) => const _MemberAvatarFallback(),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              balance.displayName ?? context.l10n.groupUnknownMember,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: colors.textPrimary,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            valueText,
            style: context.moniaryTypography.metadataStrong.copyWith(
              color: valueColor,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

class _TransactionHistory extends ConsumerStatefulWidget {
  const _TransactionHistory({
    required this.groupId,
    required this.memberCount,
    this.isPreview = false,
    this.onViewAll,
  });

  final String groupId;
  final int memberCount;
  final bool isPreview;
  final VoidCallback? onViewAll;

  @override
  ConsumerState<_TransactionHistory> createState() =>
      _TransactionHistoryState();
}

class _TransactionHistoryState extends ConsumerState<_TransactionHistory> {
  String _query = '';
  GroupSplitStatus? _status;
  int _offset = 0;

  @override
  Widget build(BuildContext context) {
    final status = switch (_status) {
      GroupSplitStatus.posted => 'posted',
      null => null,
      _ => 'pending',
    };
    final pageAsync = ref.watch(
      groupTransactionsPageProvider((
        groupId: widget.groupId,
        offset: _offset,
        limit: widget.isPreview ? 5 : 20,
        query: _query,
        status: status,
      )),
    );
    final page = pageAsync.asData?.value;

    return Column(
      children: [
        TextField(
          onChanged: (value) => setState(() {
            _query = value;
            _offset = 0;
          }),
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.search_outlined),
            hintText: context.l10n.groupTransactionSearchHint,
            isDense: true,
          ),
        ),
        const SizedBox(height: 10),
        GroupTransactionFilterBar(
          value: _status,
          onChanged: (value) => setState(() {
            _status = value;
            _offset = 0;
          }),
        ),
        const SizedBox(height: 8),
        if (pageAsync.isLoading && pageAsync.asData == null)
          const Padding(
            padding: EdgeInsets.all(18),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (pageAsync.hasError)
          _InlineNotice(
            text: context.l10n.groupTransactionLoadError,
            color: context.moniaryColors.danger,
          )
        else if (page == null || page.items.isEmpty)
          _InlineNotice(
            text: _query.trim().isEmpty && _status == null
                ? context.l10n.groupTransactionNoData
                : context.l10n.groupTransactionFilterNoResults,
            color: context.moniaryColors.secondary,
          )
        else ...[
          for (var index = 0; index < page.items.length; index++)
            _TransactionRow(
              transaction: page.items[index],
              memberCount: widget.memberCount,
              showTopDivider: index == 0,
              onTap: () => context.push(
                GroupRoutePaths.transactionDetail(
                  groupId: widget.groupId,
                  transactionId: page.items[index].id,
                ),
              ),
            ),
          if (page.hasMore && !widget.isPreview)
            Align(
              alignment: Alignment.center,
              child: OutlinedButton.icon(
                onPressed: () =>
                    setState(() => _offset += widget.isPreview ? 5 : 20),
                icon: const Icon(Icons.expand_more_outlined),
                label: Text(context.l10n.groupTransactionLoadMore),
              ),
            ),
          if (widget.isPreview && widget.onViewAll != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: OutlinedButton.icon(
                onPressed: widget.onViewAll,
                icon: const Icon(Icons.open_in_new_outlined, size: 16),
                label: Text(context.l10n.groupTransactionViewAll),
              ),
            ),
        ],
      ],
    );
  }
}

class _TransactionRow extends ConsumerWidget {
  const _TransactionRow({
    required this.transaction,
    required this.memberCount,
    required this.onTap,
    required this.showTopDivider,
  });

  final GroupTransaction transaction;
  final int memberCount;
  final VoidCallback onTap;
  final bool showTopDivider;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.moniaryColors;
    final payerName = transaction.creatorName?.trim().isNotEmpty == true
        ? transaction.creatorName!
        : context.l10n.groupUnknownMember;

    return Material(
      color: colors.surface.withValues(alpha: 0),
      child: InkWell(
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 62),
          padding: const EdgeInsets.symmetric(vertical: 11),
          decoration: BoxDecoration(
            border: Border(
              top: showTopDivider
                  ? BorderSide(
                      color: colors.textPrimary.withValues(alpha: 0.11),
                      width: 0.8,
                    )
                  : BorderSide.none,
              bottom: BorderSide(
                color: colors.textPrimary.withValues(alpha: 0.11),
                width: 0.8,
              ),
            ),
          ),
          child: Row(
            children: [
              SupabaseImage(
                imagePath: transaction.imagePath,
                width: 42,
                height: 42,
                borderRadius: BorderRadius.circular(10),
                fallbackBuilder: (_) => const _ReceiptImageFallback(),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      transaction.caption?.trim().isNotEmpty == true
                          ? transaction.caption!
                          : transaction.categoryName ??
                                context.l10n.groupNoCategory,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: colors.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        height: 1.05,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      context.l10n.groupTransactionHistorySubtitle(
                        payerName,
                        memberCount,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.moniaryTypography.metadata.copyWith(
                        color: colors.textDim,
                        fontSize: 8.5,
                        letterSpacing: 1.1,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Text(
                ref.formatAmount(transaction.totalAmount),
                style: context.moniaryTypography.metadataStrong.copyWith(
                  color: colors.textPrimary,
                  fontSize: 11,
                  letterSpacing: 0,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GroupImageFallback extends StatelessWidget {
  const _GroupImageFallback();

  @override
  Widget build(BuildContext context) {
    final colors = context.moniaryColors;
    return ColoredBox(
      color: colors.backgroundSoft,
      child: Icon(Icons.groups_2_outlined, size: 24, color: colors.textDim),
    );
  }
}

class _MemberAvatarFallback extends StatelessWidget {
  const _MemberAvatarFallback();

  @override
  Widget build(BuildContext context) {
    final colors = context.moniaryColors;
    return ColoredBox(
      color: colors.surface,
      child: Icon(Icons.person_outline, size: 16, color: colors.textDim),
    );
  }
}

class _ReceiptImageFallback extends StatelessWidget {
  const _ReceiptImageFallback();

  @override
  Widget build(BuildContext context) {
    final colors = context.moniaryColors;
    return ColoredBox(
      color: colors.surface,
      child: Icon(Icons.receipt_long_outlined, size: 20, color: colors.textDim),
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
