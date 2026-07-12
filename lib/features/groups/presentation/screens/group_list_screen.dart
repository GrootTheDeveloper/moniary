import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/app_theme.dart';
import '../../../../l10n/l10n_extension.dart';
import '../../../../shared/utils/app_logger.dart';
import '../../../../shared/utils/currency_formatter.dart';
import '../../domain/entities/spending_group.dart';
import '../../application/group_controller.dart';
import '../widgets/group_card.dart';
import 'create_group_screen.dart';
import 'group_detail_screen.dart';
import 'group_invitations_screen.dart';

class GroupListScreen extends ConsumerWidget {
  const GroupListScreen({super.key});

  static const routePath = '/groups';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groupsAsync = ref.watch(groupsControllerProvider);
    final pendingInviteCount = ref.watch(pendingGroupInviteCountProvider);
    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.groupTitle),
        actions: [
          _InviteInboxButton(count: pendingInviteCount),
          IconButton(
            onPressed: () => _openCreateGroup(context, ref),
            tooltip: context.l10n.groupCreateNew,
            icon: const Icon(Icons.group_add_outlined),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: groupsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) {
          AppLogger.error('Failed to load groups', error, stackTrace);
          return _ErrorState(
            onRetry: () =>
                ref.read(groupsControllerProvider.notifier).refresh(),
          );
        },
        data: (groups) {
          if (groups.isEmpty) {
            return _EmptyState(onCreate: () => _openCreateGroup(context, ref));
          }
          return RefreshIndicator(
            onRefresh: () =>
                ref.read(groupsControllerProvider.notifier).refresh(),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 120),
              children: [
                _GroupOverviewCard(groups: groups),
                const SizedBox(height: 20),
                Text(
                  '${context.l10n.groupTitle.toUpperCase()} · ${groups.length}',
                  style: context.moniaryTypography.metadataStrong,
                ),
                const SizedBox(height: 12),
                for (final group in groups) ...[
                  GroupCard(
                    group: group,
                    onTap: () => context.push(
                      GroupDetailScreen.routePath,
                      extra: group.id,
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _openCreateGroup(BuildContext context, WidgetRef ref) async {
    final groupId = await context.push<String>(CreateGroupScreen.routePath);
    ref.invalidate(groupsControllerProvider);
    if (groupId == null || !context.mounted) return;
    await context.push(GroupDetailScreen.routePath, extra: groupId);
  }
}

class _InviteInboxButton extends StatelessWidget {
  const _InviteInboxButton({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: () => context.push(GroupInvitationsScreen.routePath),
      tooltip: context.l10n.groupInvitationsTitle,
      icon: Stack(
        clipBehavior: Clip.none,
        children: [
          const Icon(Icons.mark_email_unread_outlined),
          if (count > 0)
            Positioned(
              top: -7,
              right: -10,
              child: Container(
                constraints: const BoxConstraints(minWidth: 17, minHeight: 17),
                padding: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  color: context.moniaryColors.danger,
                  borderRadius: BorderRadius.circular(999),
                ),
                alignment: Alignment.center,
                child: Text(
                  count > 99 ? '99+' : '$count',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: context.moniaryColors.surface,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _GroupOverviewCard extends StatelessWidget {
  const _GroupOverviewCard({required this.groups});

  final List<SpendingGroup> groups;

  @override
  Widget build(BuildContext context) {
    final colors = context.moniaryColors;
    final typography = context.moniaryTypography;
    final toPay = groups
        .where((group) => group.currentUserBalance > 0)
        .fold<int>(0, (sum, group) => sum + group.currentUserBalance);
    final toReceive = groups
        .where((group) => group.currentUserBalance < 0)
        .fold<int>(0, (sum, group) => sum + group.currentUserBalance.abs());

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: colors.outline),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.l10n.appName.toUpperCase(),
              style: typography.metadataStrong,
            ),
            const SizedBox(height: 8),
            Text(context.l10n.groupTitle, style: typography.displayMedium),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: _OverviewMetric(
                    label: context.l10n.groupOthersNeedPayYou,
                    value: '+${formatVnd(toReceive)}',
                    color: colors.success,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _OverviewMetric(
                    label: context.l10n.groupYouNeedPay,
                    value: '-${formatVnd(toPay)}',
                    color: colors.danger,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _OverviewMetric extends StatelessWidget {
  const _OverviewMetric({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: context.moniaryTypography.metadata.copyWith(
            color: context.moniaryColors.textDim,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: context.moniaryTypography.displaySmall.copyWith(color: color),
        ),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onCreate});

  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.groups_2_outlined,
              size: 72,
              color: AppTheme.mintSoft,
            ),
            const SizedBox(height: 16),
            Text(
              context.l10n.groupEmpty,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(context.l10n.groupEmptySubtitle, textAlign: TextAlign.center),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onCreate,
              icon: const Icon(Icons.add_outlined),
              label: Text(context.l10n.groupCreateNew),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(context.l10n.groupLoadError),
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
