import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/app_theme.dart';
import '../../../../core/supabase/app_exception.dart';
import '../../../../l10n/l10n_extension.dart';
import '../../../../shared/utils/error_helpers.dart';
import '../../../../shared/widgets/moniary_design.dart';
import '../../application/group_controller.dart';
import 'group_route_paths.dart';

class GroupToolsScreen extends ConsumerWidget {
  const GroupToolsScreen({required this.groupId, super.key});

  static const routePath = GroupRoutePaths.managementPattern;
  static const legacyRoutePath = '/group-tools';
  final String groupId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync = ref.watch(groupDetailProvider(groupId));
    final colors = context.moniaryColors;
    return Scaffold(
      backgroundColor: colors.backgroundSoft,
      appBar: AppBar(title: Text(context.l10n.groupManageTitle)),
      body: detailAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  userFriendlyMessage(context, error),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () => ref.invalidate(groupDetailProvider(groupId)),
                  icon: const Icon(Icons.refresh_outlined),
                  label: Text(context.l10n.commonRetry),
                ),
              ],
            ),
          ),
        ),
        data: (detail) => ListView(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 32),
          children: [
            MoniaryEditorialCard(
              padding: const EdgeInsets.fromLTRB(16, 16, 12, 14),
              child: Row(
                children: [
                  Icon(Icons.tune_outlined, color: colors.primary, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          detail.group.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          context.l10n.groupManageSubtitle,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),
            _ToolsSection(
              title: context.l10n.groupManagePeopleSection,
              children: [
                _ToolTile(
                  icon: Icons.groups_outlined,
                  title: context.l10n.groupMembersHeader,
                  subtitle: context.l10n.groupManageMembersSubtitle,
                  onTap: () => context.push(GroupRoutePaths.members(groupId)),
                ),
                if (detail.canInvite)
                  _ToolTile(
                    icon: Icons.person_add_outlined,
                    title: context.l10n.groupInviteTitle,
                    subtitle: context.l10n.groupManageInviteSubtitle,
                    onTap: () => context.push(GroupRoutePaths.invite(groupId)),
                  ),
              ],
            ),
            const SizedBox(height: 18),
            _ToolsSection(
              title: context.l10n.groupToolsFinanceSection,
              children: [
                _ToolTile(
                  icon: Icons.account_balance_wallet_outlined,
                  title: context.l10n.groupBudgetTitle,
                  subtitle: context.l10n.groupToolsBudgetSubtitle,
                  onTap: () => context.push(GroupRoutePaths.budget(groupId)),
                ),
                _ToolTile(
                  icon: Icons.autorenew_outlined,
                  title: context.l10n.groupRecurringTitle,
                  subtitle: context.l10n.groupToolsRecurringSubtitle,
                  onTap: () => context.push(GroupRoutePaths.recurring(groupId)),
                ),
              ],
            ),
            const SizedBox(height: 18),
            _ToolsSection(
              title: context.l10n.groupManageAccessSection,
              children: [
                _ToolTile(
                  icon: Icons.notifications_none_outlined,
                  title: context.l10n.groupNotificationPreferencesTitle,
                  subtitle: context.l10n.groupToolsNotificationsSubtitle,
                  onTap: () => context.push(
                    GroupRoutePaths.notificationPreferences(groupId),
                  ),
                ),
                if (detail.canInvite)
                  _ToolTile(
                    icon: Icons.public_outlined,
                    title: context.l10n.groupPublicProfileSettingsTitle,
                    subtitle: context.l10n.groupToolsPublicProfileSubtitle,
                    onTap: () =>
                        context.push(GroupRoutePaths.publicProfile(groupId)),
                  ),
                if (detail.canInvite)
                  _ToolTile(
                    icon: Icons.history_outlined,
                    title: context.l10n.groupAuditLogTitle,
                    subtitle: context.l10n.groupAuditLogSubtitle,
                    onTap: () =>
                        context.push(GroupRoutePaths.auditLog(groupId)),
                  ),
                if (detail.canInvite)
                  _ToolTile(
                    icon: Icons.tune_outlined,
                    title: context.l10n.groupSettingsTitle,
                    subtitle: context.l10n.groupSettingsSubtitle,
                    onTap: () =>
                        context.push(GroupRoutePaths.settings(groupId)),
                  ),
                _ToolTile(
                  icon: Icons.logout_outlined,
                  title: context.l10n.groupLeave,
                  subtitle: context.l10n.groupToolsLeaveSubtitle,
                  iconColor: colors.danger,
                  onTap: () => _leaveGroup(context, ref),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _leaveGroup(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(context.l10n.groupLeaveConfirmTitle),
        content: Text(context.l10n.groupLeaveConfirmMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(context.l10n.commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
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
}

class _ToolsSection extends StatelessWidget {
  const _ToolsSection({required this.title, required this.children});
  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        title.toUpperCase(),
        style: context.moniaryTypography.metadataStrong.copyWith(
          color: context.moniaryColors.textDim,
          fontSize: 10,
          letterSpacing: 1.8,
        ),
      ),
      const SizedBox(height: 8),
      Card(child: Column(children: children)),
    ],
  );
}

class _ToolTile extends StatelessWidget {
  const _ToolTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.iconColor,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) => ListTile(
    leading: Icon(icon, color: iconColor ?? context.moniaryColors.primary),
    title: Text(title),
    subtitle: Text(subtitle),
    trailing: const Icon(Icons.chevron_right_outlined),
    onTap: onTap,
  );
}
