import 'package:flutter/material.dart';

import '../../../../app/app_theme.dart';

class SettingsActionTile extends StatelessWidget {
  const SettingsActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.destructive = false,
    this.margin = EdgeInsets.zero,
    super.key,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final bool destructive;
  final EdgeInsetsGeometry margin;

  @override
  Widget build(BuildContext context) {
    final color = destructive ? AppTheme.danger : AppTheme.mint;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: Container(
        margin: margin,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: AppTheme.outline),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.14),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: destructive ? AppTheme.danger : Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Icon(Icons.chevron_right_outlined, color: color),
          ],
        ),
      ),
    );
  }
}
