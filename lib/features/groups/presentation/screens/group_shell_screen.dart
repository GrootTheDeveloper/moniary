import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/app_theme.dart';
import '../../../../l10n/l10n_extension.dart';
import '../../../notifications/application/notification_controller.dart';
import 'group_route_paths.dart';

class GroupShellScreen extends ConsumerWidget {
  const GroupShellScreen({
    required this.groupId,
    required this.navigationShell,
    super.key,
  });

  static const routePath = '/group-shell';
  static const homeRoutePath = GroupRoutePaths.homePattern;

  final String groupId;
  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.moniaryColors;
    final unreadCount = ref.watch(
      groupUnreadNotificationCountProvider(groupId),
    );
    final currentIndex = navigationShell.currentIndex;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: colors.navBar,
        systemNavigationBarDividerColor: Colors.transparent,
      ),
      child: Scaffold(
        backgroundColor: colors.backgroundSoft,
        body: navigationShell,
        bottomNavigationBar: _GroupBottomNavigationBar(
          currentIndex: currentIndex,
          unreadCount: unreadCount,
          onSelected: (index) => navigationShell.goBranch(
            index,
            initialLocation: index == currentIndex,
          ),
        ),
      ),
    );
  }
}

class _GroupBottomNavigationBar extends StatelessWidget {
  const _GroupBottomNavigationBar({
    required this.currentIndex,
    required this.unreadCount,
    required this.onSelected,
  });

  final int currentIndex;
  final int unreadCount;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final colors = context.moniaryColors;
    final items = [
      (Icons.receipt_long_outlined, context.l10n.groupShellHome),
      (Icons.forum_outlined, context.l10n.groupShellCommunity),
      (Icons.notifications_none_outlined, context.l10n.groupShellNotifications),
      (Icons.manage_accounts_outlined, context.l10n.groupManageTitle),
    ];

    return SafeArea(
      top: false,
      child: Container(
        height: 80,
        decoration: BoxDecoration(
          color: colors.navBar.withValues(alpha: 0.98),
          border: Border(
            top: BorderSide(
              color: colors.textPrimary.withValues(alpha: 0.1),
              width: 0.8,
            ),
          ),
        ),
        child: Row(
          children: [
            for (var index = 0; index < items.length; index++)
              Expanded(
                child: _GroupNavItem(
                  icon: items[index].$1,
                  label: items[index].$2,
                  badgeCount: index == 2 ? unreadCount : 0,
                  selected: currentIndex == index,
                  onTap: () => onSelected(index),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _GroupNavItem extends StatelessWidget {
  const _GroupNavItem({
    required this.icon,
    required this.label,
    this.badgeCount = 0,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final int badgeCount;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.moniaryColors;
    final color = selected ? colors.button : colors.navInactive;
    return Semantics(
      selected: selected,
      button: true,
      label: label,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 5),
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 7),
          decoration: BoxDecoration(
            color: selected
                ? colors.button.withValues(alpha: 0.09)
                : colors.navBar.withValues(alpha: 0),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Icon(icon, color: color, size: 22),
                  if (badgeCount > 0)
                    Positioned(
                      top: -7,
                      right: -10,
                      child: Container(
                        constraints: const BoxConstraints(minWidth: 18),
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        decoration: BoxDecoration(
                          color: colors.danger,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: colors.navBar),
                        ),
                        child: Text(
                          badgeCount > 99 ? '99+' : '$badgeCount',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: colors.surfaceRaised,
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 4),
              Flexible(
                child: Text(
                  label.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.moniaryTypography.metadataStrong.copyWith(
                    color: color,
                    fontSize: 10,
                    letterSpacing: 0.15,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
