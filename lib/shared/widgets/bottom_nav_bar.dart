import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/app_theme.dart';
import '../../l10n/l10n_extension.dart';
import '../../features/calendar/presentation/month/calendar_screen.dart';
import '../../features/groups/presentation/groups_screen.dart';
import '../../features/settings/presentation/profile_screen.dart';

enum MoniaryTab { calendar, stats, groups, profile }

class MoniaryBottomNavBar extends ConsumerWidget {
  const MoniaryBottomNavBar({
    super.key,
    required this.currentTab,
    this.onTabSelected,
    this.onCameraPressed,
  });

  final MoniaryTab currentTab;
  final ValueChanged<MoniaryTab>? onTabSelected;
  final VoidCallback? onCameraPressed;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.moniaryColors;

    return SafeArea(
      top: false,
      child: SizedBox(
        height: 86,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.topCenter,
          children: [
            Positioned.fill(
              top: 14,
              child: ClipRect(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    decoration: BoxDecoration(
                      color: colors.navBar.withValues(alpha: 0.82),
                      border: Border(
                        top: BorderSide(
                          color: colors.textPrimary.withValues(alpha: 0.08),
                          width: 0.8,
                        ),
                      ),
                    ),
                    child: Row(
                      children: [
                        const SizedBox(width: 8),
                        _NavItem(
                          icon: Icons.calendar_today_outlined,
                          label: context.l10n.calendarTitle,
                          active: currentTab == MoniaryTab.calendar,
                          onTap: () {
                            HapticFeedback.selectionClick();
                            if (onTabSelected != null) {
                              onTabSelected!(MoniaryTab.calendar);
                            } else if (currentTab != MoniaryTab.calendar) {
                              context.go(CalendarScreen.routePath);
                            }
                          },
                        ),
                        _NavItem(
                          icon: Icons.bar_chart_rounded,
                          label: context.l10n.navStatsLabel,
                          active: currentTab == MoniaryTab.stats,
                          onTap: () {
                            HapticFeedback.selectionClick();
                            if (onTabSelected != null) {
                              onTabSelected!(MoniaryTab.stats);
                            } else if (currentTab != MoniaryTab.stats) {
                              context.go('/statistics');
                            }
                          },
                        ),
                        const SizedBox(width: 78),
                        _NavItem(
                          icon: Icons.group_rounded,
                          label: context.l10n.navGroupsLabel,
                          active: currentTab == MoniaryTab.groups,
                          onTap: () {
                            HapticFeedback.selectionClick();
                            if (onTabSelected != null) {
                              onTabSelected!(MoniaryTab.groups);
                            } else if (currentTab != MoniaryTab.groups) {
                              context.go(GroupsScreen.routePath);
                            }
                          },
                        ),
                        _NavItem(
                          icon: Icons.person_rounded,
                          label: context.l10n.navProfileLabel,
                          active: currentTab == MoniaryTab.profile,
                          onTap: () {
                            HapticFeedback.selectionClick();
                            if (onTabSelected != null) {
                              onTabSelected!(MoniaryTab.profile);
                            } else if (currentTab != MoniaryTab.profile) {
                              context.go(ProfileScreen.routePath);
                            }
                          },
                        ),
                        const SizedBox(width: 8),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            _CameraActionButton(onPressed: onCameraPressed),
          ],
        ),
      ),
    );
  }
}

class _CameraActionButton extends StatelessWidget {
  const _CameraActionButton({required this.onPressed});

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = context.moniaryColors;

    return Semantics(
      button: true,
      label: context.l10n.scanTakePhoto,
      child: SizedBox(
        width: 68,
        height: 68,
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            color: colors.background,
          ),
          child: Material(
            color: colors.button,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(18),
              onTap: () {
                HapticFeedback.mediumImpact();
                if (onPressed != null) {
                  onPressed!();
                }
              },
              child: Icon(
                Icons.camera_alt_rounded,
                color: Theme.of(
                  context,
                ).floatingActionButtonTheme.foregroundColor,
                size: 27,
              ),
            ),
          ),
        ),
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
    final color = active ? colors.button : colors.navInactive;
    return Expanded(
      child: Semantics(
        selected: active,
        button: true,
        label: label,
        child: InkWell(
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOutCubic,
            constraints: const BoxConstraints(minHeight: 52),
            padding: const EdgeInsets.symmetric(vertical: 7),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: color, size: 22),
                const SizedBox(height: 3),
                Text(
                  label.toUpperCase(),
                  maxLines: 1,
                  style: context.moniaryTypography.metadataStrong.copyWith(
                    color: color,
                    fontSize: 8.5,
                    letterSpacing: 0.55,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
