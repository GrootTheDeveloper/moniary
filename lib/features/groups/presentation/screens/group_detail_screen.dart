import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

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
            detail: detail,
            transactionsAsync: transactionsAsync,
            settlementsAsync: settlementsAsync,
            onRefresh: () async {
              ref.invalidate(groupDetailProvider(groupId));
              ref.invalidate(groupTransactionsProvider(groupId));
              ref.invalidate(groupSettlementOverviewProvider(groupId));
            },
            onActions: () => _showGroupActions(context, ref, detail),
            onSettle: () =>
                context.push(DebtSettlementScreen.routePath, extra: groupId),
            onAddTransaction: detail.activeMembers.isEmpty
                ? null
                : () => context.push(
                    AddGroupTransactionScreen.routePath,
                    extra: AddGroupTransactionArgs(groupId: groupId),
                  ),
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
                    context.push(InviteMemberScreen.routePath, extra: groupId);
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

class _GroupDetailContent extends StatelessWidget {
  const _GroupDetailContent({
    required this.detail,
    required this.transactionsAsync,
    required this.settlementsAsync,
    required this.onRefresh,
    required this.onActions,
    required this.onSettle,
    required this.onAddTransaction,
  });

  final SpendingGroupDetail detail;
  final AsyncValue<List<GroupTransaction>> transactionsAsync;
  final AsyncValue<GroupSettlementOverview> settlementsAsync;
  final Future<void> Function() onRefresh;
  final VoidCallback onActions;
  final VoidCallback onSettle;
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
                      transactionsAsync: transactionsAsync,
                      onSettle: onSettle,
                    ),
                    MoniarySectionLabel(
                      context.l10n.groupMemberBalanceTitle,
                      padding: const EdgeInsets.only(top: 25, bottom: 10),
                    ),
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
                    MoniarySectionLabel(
                      context.l10n.groupTransactionsTitle,
                      padding: const EdgeInsets.only(top: 28, bottom: 10),
                    ),
                    transactionsAsync.when(
                      loading: () =>
                          const Center(child: CircularProgressIndicator()),
                      error: (_, _) => _InlineNotice(
                        text: context.l10n.groupTransactionLoadError,
                        color: context.moniaryColors.danger,
                      ),
                      data: (transactions) => _TransactionHistory(
                        transactions: transactions,
                        memberCount: detail.activeMembers.length,
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
                child: FilledButton.icon(
                  onPressed: onAddTransaction,
                  icon: const Icon(Icons.add_rounded, size: 20),
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
              icon: Icons.chevron_left_rounded,
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
              icon: Icons.more_vert_rounded,
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
    final transactions = transactionsAsync.asData?.value;
    final total = transactions
        ?.where((item) => item.splitStatus == GroupSplitStatus.posted)
        .fold<int>(0, (sum, item) => sum + item.totalAmount);
    final transactionCount = transactions?.length ?? group.transactionCount;
    final totalText = formatVnd(total ?? group.totalSpent);

    return Column(
      children: [
        SupabaseImage(
          imagePath: group.avatarPath,
          width: 58,
          height: 58,
          borderRadius: BorderRadius.circular(17),
          fallbackBuilder: (_) => const _GroupImageFallback(),
        ),
        const SizedBox(height: 16),
        Text(
          group.name,
          textAlign: TextAlign.center,
          style: context.moniaryTypography.displayMedium.copyWith(
            fontSize: 26,
            height: 1.03,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          [
            context.l10n.groupMemberCount(detail.activeMembers.length),
            context.l10n.groupTransactionCount(transactionCount),
            totalText,
          ].join(' · ').toUpperCase(),
          textAlign: TextAlign.center,
          style: context.moniaryTypography.metadata.copyWith(
            color: colors.textDim,
            letterSpacing: 2.2,
          ),
        ),
        const SizedBox(height: 20),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(16, 15, 16, 17),
          decoration: BoxDecoration(
            color: balanceColor.withValues(alpha: 0.07),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: balanceColor.withValues(alpha: 0.34)),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      balanceLabel.toUpperCase(),
                      style: context.moniaryTypography.metadataStrong.copyWith(
                        color: balanceColor,
                        fontSize: 9,
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      formatVnd(balance.abs()),
                      style: context.moniaryTypography.displaySmall.copyWith(
                        color: balanceColor,
                        fontSize: 24,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ),
              ),
              if (!isSettled)
                TextButton(
                  onPressed: onSettle,
                  child: Text('${context.l10n.groupSettleAction} →'),
                ),
            ],
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
    final valueText = balance.balance == 0
        ? formatVnd(0)
        : '${balance.balance > 0 ? '-' : '+'}${formatVnd(balance.balance.abs())}';

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

class _TransactionHistory extends StatelessWidget {
  const _TransactionHistory({
    required this.transactions,
    required this.memberCount,
  });

  final List<GroupTransaction> transactions;
  final int memberCount;

  @override
  Widget build(BuildContext context) {
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
            memberCount: memberCount,
            showTopDivider: index == 0,
            onTap: () => context.push(
              GroupTransactionDetailScreen.routePath,
              extra: transactions[index].id,
            ),
          ),
      ],
    );
  }
}

class _TransactionRow extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final colors = context.moniaryColors;
    final payerName = transaction.creatorName?.trim().isNotEmpty == true
        ? transaction.creatorName!
        : context.l10n.groupUnknownMember;

    return Material(
      color: Colors.transparent,
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
                formatVnd(transaction.totalAmount),
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
