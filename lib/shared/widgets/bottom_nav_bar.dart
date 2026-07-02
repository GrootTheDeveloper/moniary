import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/app_theme.dart';
import '../../l10n/l10n_extension.dart';
import '../../features/calendar/presentation/month/calendar_screen.dart';
import '../../features/groups/presentation/groups_screen.dart';
import '../../features/settings/presentation/profile_screen.dart';

enum MoniaryTab { calendar, stats, groups, profile }

class MoniaryBottomNavBar extends StatelessWidget {
  const MoniaryBottomNavBar({
    super.key,
    required this.currentTab,
    this.onTabSelected,
  });

  final MoniaryTab currentTab;
  final ValueChanged<MoniaryTab>? onTabSelected;

  @override
  Widget build(BuildContext context) {
    final colors = context.moniaryColors;

    return Container(
      height: 84,
      decoration: BoxDecoration(
        color: colors.navBar,
        border: Border(top: BorderSide(color: colors.outline)),
      ),
      child: Row(
        children: [
          const SizedBox(width: 10),
          _NavItem(
            icon: Icons.calendar_month_outlined,
            label: context.l10n.calendarTitle,
            active: currentTab == MoniaryTab.calendar,
            onTap: () {
              if (onTabSelected != null) {
                onTabSelected!(MoniaryTab.calendar);
              } else if (currentTab != MoniaryTab.calendar) {
                context.go(CalendarScreen.routePath);
              }
            },
          ),
          _NavItem(
            icon: Icons.pie_chart_outline,
            label: context.l10n.calendarStatsTab,
            active: currentTab == MoniaryTab.stats,
            onTap: () {
              if (onTabSelected != null) {
                onTabSelected!(MoniaryTab.stats);
              }
            },
          ),
          _NavItem(
            icon: Icons.groups_2_outlined,
            label: context.l10n.groupTitle,
            active: currentTab == MoniaryTab.groups,
            onTap: () {
              if (onTabSelected != null) {
                onTabSelected!(MoniaryTab.groups);
              } else if (currentTab != MoniaryTab.groups) {
                context.go(GroupsScreen.routePath);
              }
            },
          ),
          _NavItem(
            icon: Icons.person_outlined,
            label: context.l10n.profileTitle,
            active: currentTab == MoniaryTab.profile,
            onTap: () {
              if (onTabSelected != null) {
                onTabSelected!(MoniaryTab.profile);
              } else if (currentTab != MoniaryTab.profile) {
                context.go(ProfileScreen.routePath);
              }
            },
          ),
          const SizedBox(width: 10),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    this.active = false,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.moniaryColors;
    final color = active ? colors.primary : colors.navInactive;
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 4),
            Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: color,
                fontSize: 11,
                fontWeight: active ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
