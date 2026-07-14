import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/app_theme.dart';
import '../../../../l10n/l10n_extension.dart';
import '../../application/group_controller.dart';
import 'group_activity_center_screen.dart';
import 'group_budget_screen.dart';
import 'group_notification_preferences_screen.dart';
import 'group_photo_album_screen.dart';
import 'group_public_profile_screen.dart';
import 'group_recurring_transactions_screen.dart';

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
              ],
            ),
          ],
        ),
      ),
    );
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
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => ListTile(
    leading: Icon(icon, color: context.moniaryColors.primary),
    title: Text(title),
    subtitle: Text(subtitle),
    trailing: const Icon(Icons.chevron_right),
    onTap: onTap,
  );
}
