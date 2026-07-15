import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/app_theme.dart';
import '../../../../core/supabase/app_exception.dart';
import '../../../../l10n/l10n_extension.dart';
import '../../../../shared/utils/error_helpers.dart';
import '../../application/group_controller.dart';
import 'debt_settlement_screen.dart';
import 'group_detail_screen.dart';
import 'group_activity_center_screen.dart';
import 'group_audit_log_screen.dart';
import 'group_budget_screen.dart';
import 'group_notification_preferences_screen.dart';
import 'group_photo_album_screen.dart';
import 'group_participation_screen.dart';
import 'group_public_profile_screen.dart';
import 'group_recurring_transactions_screen.dart';
import 'group_summary_screen.dart';
import 'group_settings_screen.dart';

class GroupToolsScreen extends ConsumerWidget {
  const GroupToolsScreen({required this.groupId, super.key});

  static const routePath = '/group-tools';
  final String groupId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync = ref.watch(groupDetailProvider(groupId));
    final colors = context.moniaryColors;
    return Scaffold(
      backgroundColor: colors.backgroundSoft,
      appBar: AppBar(title: Text(context.l10n.groupToolsTitle)),
      body: detailAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text(context.l10n.errorGeneric)),
        data: (detail) => ListView(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 32),
          children: [
            Text(
              context.l10n.groupToolsSubtitle,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 22),
            _ToolsSection(
              title: context.l10n.groupToolsFinanceSection,
              children: [
                _ToolTile(
                  icon: Icons.account_balance_wallet_outlined,
                  title: context.l10n.groupBudgetTitle,
                  subtitle: context.l10n.groupToolsBudgetSubtitle,
                  onTap: () =>
                      context.push(GroupBudgetScreen.routePath, extra: groupId),
                ),
                _ToolTile(
                  icon: Icons.autorenew_outlined,
                  title: context.l10n.groupRecurringTitle,
                  subtitle: context.l10n.groupToolsRecurringSubtitle,
                  onTap: () => context.push(
                    GroupRecurringTransactionsScreen.routePath,
                    extra: groupId,
                  ),
                ),
                _ToolTile(
                  icon: Icons.insights_outlined,
                  title: context.l10n.groupSummaryTitle,
                  subtitle: context.l10n.groupToolsSummarySubtitle,
                  onTap: () => context.push(
                    GroupSummaryScreen.routePath,
                    extra: groupId,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            _ToolsSection(
              title: context.l10n.groupToolsCommunitySection,
              children: [
                _ToolTile(
                  icon: Icons.bolt_outlined,
                  title: context.l10n.groupActivityCenterTitle,
                  subtitle: context.l10n.groupToolsActivitySubtitle,
                  onTap: () => context.push(
                    GroupActivityCenterScreen.routePath,
                    extra: groupId,
                  ),
                ),
                _ToolTile(
                  icon: Icons.photo_library_outlined,
                  title: context.l10n.groupPhotoAlbumTitle,
                  subtitle: context.l10n.groupToolsAlbumSubtitle,
                  onTap: () => context.push(
                    GroupPhotoAlbumScreen.routePath,
                    extra: groupId,
                  ),
                ),
                _ToolTile(
                  icon: Icons.how_to_vote_outlined,
                  title: context.l10n.groupParticipationTitle,
                  subtitle: context.l10n.groupParticipationSubtitle,
                  onTap: () => context.push(
                    GroupParticipationScreen.routePath,
                    extra: groupId,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            _ToolsSection(
              title: context.l10n.groupToolsSettingsSection,
              children: [
                _ToolTile(
                  icon: Icons.notifications_none_outlined,
                  title: context.l10n.groupNotificationPreferencesTitle,
                  subtitle: context.l10n.groupToolsNotificationsSubtitle,
                  onTap: () => context.push(
                    GroupNotificationPreferencesScreen.routePath,
                    extra: groupId,
                  ),
                ),
                if (detail.canInvite)
                  _ToolTile(
                    icon: Icons.public_outlined,
                    title: context.l10n.groupPublicProfileSettingsTitle,
                    subtitle: context.l10n.groupToolsPublicProfileSubtitle,
                    onTap: () => context.push(
                      GroupPublicProfileScreen.routePath,
                      extra: groupId,
                    ),
                  ),
                if (detail.canInvite)
                  _ToolTile(
                    icon: Icons.history_outlined,
                    title: context.l10n.groupAuditLogTitle,
                    subtitle: context.l10n.groupAuditLogSubtitle,
                    onTap: () => context.push(
                      GroupAuditLogScreen.routePath,
                      extra: groupId,
                    ),
                  ),
                if (detail.canInvite)
                  _ToolTile(
                    icon: Icons.tune_outlined,
                    title: context.l10n.groupSettingsTitle,
                    subtitle: context.l10n.groupSettingsSubtitle,
                    onTap: () => context.push(
                      GroupSettingsScreen.routePath,
                      extra: groupId,
                    ),
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
                    context.push(
                      DebtSettlementScreen.routePath,
                      extra: groupId,
                    );
                  } else {
                    context.push(GroupDetailScreen.routePath, extra: groupId);
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
    trailing: const Icon(Icons.chevron_right),
    onTap: onTap,
  );
}
