import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/app_theme.dart';
import '../../../../l10n/l10n_extension.dart';
import '../../../../shared/utils/app_logger.dart';
import '../../../../shared/utils/currency_formatting_ref.dart';
import '../../../../shared/widgets/supabase_image.dart';
import '../../application/group_controller.dart';
import '../../domain/entities/spending_group.dart';
import 'create_group_screen.dart';
import 'group_activity_center_screen.dart';
import 'group_detail_screen.dart';
import 'group_invitations_screen.dart';
import 'invite_member_screen.dart';

class GroupListScreen extends ConsumerWidget {
  const GroupListScreen({super.key});

  static const routePath = '/groups';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groupsAsync = ref.watch(groupsControllerProvider);
    final pendingInviteCount = ref.watch(pendingGroupInviteCountProvider);
    final unreadNotificationCount = ref.watch(
      unreadGroupNotificationCountProvider,
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
        body: groupsAsync.when(
          loading: () => const _GroupListLoading(),
          error: (error, stackTrace) {
            AppLogger.error('Failed to load groups', error, stackTrace);
            return _GroupListError(
              onRetry: () =>
                  ref.read(groupsControllerProvider.notifier).refresh(),
            );
          },
          data: (groups) => _GroupListContent(
            groups: groups,
            pendingInviteCount: pendingInviteCount,
            unreadNotificationCount: unreadNotificationCount,
            onCreate: () => _openCreateGroup(context, ref),
            onRefresh: () =>
                ref.read(groupsControllerProvider.notifier).refresh(),
          ),
        ),
      ),
    );
  }

  Future<void> _openCreateGroup(BuildContext context, WidgetRef ref) async {
    final result = await context.push<Object?>(CreateGroupScreen.routePath);
    ref.invalidate(groupsControllerProvider);
    final groupId = switch (result) {
      final CreateGroupResult value => value.groupId,
      final String value => value,
      _ => null,
    };
    if (groupId == null || !context.mounted) return;
    final inviteMembers = result is CreateGroupResult && result.inviteMembers;
    if (inviteMembers) {
      await context.push(InviteMemberScreen.routePath, extra: groupId);
      if (!context.mounted) return;
    }
    await context.push(GroupDetailScreen.routePath, extra: groupId);
  }
}

class _GroupListContent extends StatelessWidget {
  const _GroupListContent({
    required this.groups,
    required this.pendingInviteCount,
    required this.unreadNotificationCount,
    required this.onCreate,
    required this.onRefresh,
  });

  final List<SpendingGroup> groups;
  final int pendingInviteCount;
  final int unreadNotificationCount;
  final VoidCallback onCreate;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 393),
          child: RefreshIndicator(
            color: context.moniaryColors.primary,
            backgroundColor: context.moniaryColors.backgroundSoft,
            onRefresh: onRefresh,
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(14, 18, 14, 0),
                    child: _GroupsHeader(
                      pendingInviteCount: pendingInviteCount,
                      unreadNotificationCount: unreadNotificationCount,
                      onCreate: onCreate,
                    ),
                  ),
                ),
                if (groups.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(14, 28, 14, 120),
                      child: _GroupEmptyState(onCreate: onCreate),
                    ),
                  )
                else ...[
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(14, 20, 14, 18),
                      child: _GroupBalanceOverview(groups: groups),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
                      child: Text(
                        context.l10n
                            .groupListSection(groups.length)
                            .toUpperCase(),
                        style: context.moniaryTypography.metadataStrong
                            .copyWith(
                              color: context.moniaryColors.textDim,
                              fontSize: 9,
                              letterSpacing: 2.8,
                            ),
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(14, 0, 14, 132),
                    sliver: SliverList.separated(
                      itemCount: groups.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (context, index) => _ReferenceGroupCard(
                        group: groups[index],
                        index: index,
                        onTap: () => context.push(
                          GroupDetailScreen.routePath,
                          extra: groups[index].id,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _GroupsHeader extends StatelessWidget {
  const _GroupsHeader({
    required this.pendingInviteCount,
    required this.unreadNotificationCount,
    required this.onCreate,
  });

  final int pendingInviteCount;
  final int unreadNotificationCount;
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    final colors = context.moniaryColors;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'MONIARY',
                style: context.moniaryTypography.metadataStrong.copyWith(
                  color: colors.primary,
                  fontSize: 9,
                  letterSpacing: 3.2,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                context.l10n.groupListTitle,
                style: context.moniaryTypography.displaySmall.copyWith(
                  color: colors.textPrimary,
                  fontSize: 24,
                  height: 1,
                  letterSpacing: 0,
                ),
              ),
            ],
          ),
        ),
        if (pendingInviteCount > 0) ...[
          _HeaderIconButton(
            label: context.l10n.groupInvitationsTitle,
            icon: Icons.mark_email_unread_outlined,
            badge: pendingInviteCount,
            onTap: () => context.push(GroupInvitationsScreen.routePath),
            foreground: colors.textPrimary,
            background: colors.surface.withValues(alpha: 0.58),
            border: colors.outline.withValues(alpha: 0.8),
          ),
          const SizedBox(width: 9),
        ],
        _HeaderIconButton(
          label: context.l10n.groupActivityTabNotifications,
          icon: unreadNotificationCount > 0
              ? Icons.notifications_active_outlined
              : Icons.notifications_none_outlined,
          badge: unreadNotificationCount,
          onTap: () => context.push(GroupActivityCenterScreen.routePath),
          foreground: colors.textPrimary,
          background: colors.surface.withValues(alpha: 0.58),
          border: colors.outline.withValues(alpha: 0.8),
        ),
        const SizedBox(width: 9),
        _HeaderIconButton(
          label: context.l10n.groupCreateNew,
          icon: Icons.add_rounded,
          onTap: onCreate,
          foreground: colors.backgroundSoft,
          background: colors.textPrimary,
          border: colors.textPrimary,
        ),
      ],
    );
  }
}

class _HeaderIconButton extends StatelessWidget {
  const _HeaderIconButton({
    required this.label,
    required this.icon,
    required this.onTap,
    required this.foreground,
    required this.background,
    required this.border,
    this.badge,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final Color foreground;
  final Color background;
  final Color border;
  final int? badge;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: Tooltip(
        message: label,
        child: Material(
          color: background,
          borderRadius: BorderRadius.circular(9),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(9),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(9),
                border: Border.all(color: border),
              ),
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: [
                  Icon(icon, size: 21, color: foreground),
                  if ((badge ?? 0) > 0)
                    Positioned(
                      top: -5,
                      right: -5,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: context.moniaryColors.primary,
                          borderRadius: BorderRadius.circular(99),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 5,
                            vertical: 2,
                          ),
                          child: Text(
                            badge! > 99 ? '99+' : '$badge',
                            style: context.moniaryTypography.metadataStrong
                                .copyWith(
                                  color: AppTheme.surfaceRaised,
                                  fontSize: 9,
                                  letterSpacing: 0,
                                ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _GroupBalanceOverview extends ConsumerWidget {
  const _GroupBalanceOverview({required this.groups});

  final List<SpendingGroup> groups;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final toReceive = groups
        .where((group) => group.currentUserBalance < 0)
        .fold<int>(0, (sum, group) => sum + group.currentUserBalance.abs());
    final toPay = groups
        .where((group) => group.currentUserBalance > 0)
        .fold<int>(0, (sum, group) => sum + group.currentUserBalance);

    return Row(
      children: [
        Expanded(
          child: _BalanceSummaryTile(
            label: context.l10n.groupBalanceReceiveShort,
            summaryLabel: context.l10n.groupBalanceReceiveSummary,
            value: '+${ref.formatAmount(toReceive)}',
            color: context.moniaryColors.success,
          ),
        ),
        const SizedBox(width: 9),
        Expanded(
          child: _BalanceSummaryTile(
            label: context.l10n.groupBalancePayShort,
            summaryLabel: context.l10n.groupBalancePaySummary,
            value: '-${ref.formatAmount(toPay)}',
            color: context.moniaryColors.danger,
          ),
        ),
      ],
    );
  }
}

class _BalanceSummaryTile extends StatelessWidget {
  const _BalanceSummaryTile({
    required this.label,
    required this.summaryLabel,
    required this.value,
    required this.color,
  });

  final String label;
  final String summaryLabel;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 78,
      padding: const EdgeInsets.fromLTRB(16, 13, 12, 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.34)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            summaryLabel.toUpperCase(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: context.moniaryTypography.metadataStrong.copyWith(
              color: color,
              fontSize: 9,
              letterSpacing: 2.2,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: context.moniaryTypography.displaySmall.copyWith(
              color: color,
              fontSize: 16,
              height: 1,
              letterSpacing: 0,
            ),
          ),
        ],
      ),
    );
  }
}

class _ReferenceGroupCard extends ConsumerWidget {
  const _ReferenceGroupCard({
    required this.group,
    required this.index,
    required this.onTap,
  });

  final SpendingGroup group;
  final int index;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.moniaryColors;
    final balance = group.currentUserBalance;
    final settled = balance == 0;
    final amountColor = settled
        ? colors.textSecondary
        : balance < 0
        ? colors.success
        : colors.danger;
    final amountText = settled
        ? ref.formatAmount(0)
        : balance < 0
        ? '+${ref.formatAmount(balance.abs())}'
        : '-${ref.formatAmount(balance)}';
    final stateLabel = settled
        ? context.l10n.groupBalanceSettledShort
        : balance < 0
        ? context.l10n.groupBalanceReceiveShort
        : context.l10n.groupBalancePayShort;
    final showSettlementAction = group.hasUnresolvedSettlements && balance < 0;

    return Material(
      color: Colors.transparent,
      child: Ink(
        decoration: BoxDecoration(
          color: colors.surface.withValues(alpha: 0.72),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: colors.outline.withValues(alpha: 0.75)),
          boxShadow: [
            BoxShadow(
              color: colors.textPrimary.withValues(alpha: 0.035),
              blurRadius: 14,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 13),
            child: Column(
              children: [
                Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: SizedBox.square(
                        dimension: 39,
                        child: SupabaseImage(
                          imagePath: group.avatarPath,
                          fit: BoxFit.cover,
                          fallbackBuilder: (context) =>
                              const _GroupImageFallback(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            group.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(
                                  color: colors.textPrimary,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                  height: 1.05,
                                  letterSpacing: 0,
                                ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '${context.l10n.groupMemberCount(group.memberCount)} · '
                            '${context.l10n.groupTransactionCount(group.transactionCount)}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: context.moniaryTypography.metadata.copyWith(
                              color: colors.textDim,
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          amountText,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: context.moniaryTypography.metadataStrong
                              .copyWith(
                                color: amountColor,
                                fontSize: 11,
                                letterSpacing: 0,
                              ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          stateLabel.toUpperCase(),
                          style: context.moniaryTypography.metadata.copyWith(
                            color: colors.textDim,
                            fontSize: 8,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                if (showSettlementAction) ...[
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      _MemberDotStack(
                        count: group.memberCount,
                        avatarPaths: group.memberAvatarPaths,
                      ),
                      const Spacer(),
                      Text(
                        '${context.l10n.groupSettleAction} →',
                        style: context.moniaryTypography.metadataStrong
                            .copyWith(
                              color: colors.primary,
                              fontSize: 9,
                              letterSpacing: 0,
                            ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MemberDotStack extends StatelessWidget {
  const _MemberDotStack({required this.count, required this.avatarPaths});

  final int count;
  final List<String?> avatarPaths;

  @override
  Widget build(BuildContext context) {
    final visible = count.clamp(1, 5);
    return SizedBox(
      width: 15 + (visible - 1) * 13,
      height: 19,
      child: Stack(
        children: [
          for (var index = 0; index < visible; index++)
            Positioned(
              left: index * 12,
              child: Container(
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: context.moniaryColors.surface.withValues(alpha: 0.9),
                    width: 1.1,
                  ),
                ),
                child: ClipOval(
                  child: SupabaseImage(
                    imagePath: index < avatarPaths.length
                        ? avatarPaths[index]
                        : null,
                    fit: BoxFit.cover,
                    fallbackBuilder: (context) => const _MemberAvatarFallback(),
                  ),
                ),
              ),
            ),
        ],
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
      child: Icon(Icons.groups_2_outlined, size: 20, color: colors.textDim),
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
      child: Icon(Icons.person_outline, size: 12, color: colors.textDim),
    );
  }
}

class _GroupEmptyState extends StatelessWidget {
  const _GroupEmptyState({required this.onCreate});

  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    final colors = context.moniaryColors;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.groups_2_rounded, size: 72, color: AppTheme.sand),
        const SizedBox(height: 18),
        Text(
          context.l10n.groupEmpty,
          textAlign: TextAlign.center,
          style: context.moniaryTypography.displaySmall.copyWith(
            color: colors.textPrimary,
            fontSize: 28,
            height: 1.08,
            letterSpacing: 0,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          context.l10n.groupEmptySubtitle,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: colors.textSecondary,
            height: 1.35,
          ),
        ),
        const SizedBox(height: 28),
        SizedBox(
          width: double.infinity,
          height: 58,
          child: FilledButton.icon(
            onPressed: onCreate,
            icon: const Icon(Icons.add_rounded),
            label: Text(context.l10n.groupCreateNew),
          ),
        ),
      ],
    );
  }
}

class _GroupListLoading extends StatelessWidget {
  const _GroupListLoading();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Center(
        child: SizedBox(
          width: 22,
          height: 22,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: context.moniaryColors.primary,
          ),
        ),
      ),
    );
  }
}

class _GroupListError extends StatelessWidget {
  const _GroupListError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final colors = context.moniaryColors;
    return SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(30),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                context.l10n.groupLoadError,
                textAlign: TextAlign.center,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: colors.textSecondary),
              ),
              const SizedBox(height: 14),
              OutlinedButton(
                onPressed: onRetry,
                child: Text(context.l10n.commonRetry),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
