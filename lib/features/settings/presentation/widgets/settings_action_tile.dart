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
    this.status,
    this.grouped = false,
    this.isLoading = false,
    super.key,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final bool destructive;
  final EdgeInsetsGeometry margin;
  final Widget? status;
  final bool grouped;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final color = destructive ? AppTheme.danger : AppTheme.mint;

    final content = Row(
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
              if (subtitle.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
              ],
            ],
          ),
        ),
        if (status != null) ...[const SizedBox(width: 8), status!],
        const SizedBox(width: 8),
        if (isLoading)
          SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2, color: color),
          )
        else
          Icon(Icons.chevron_right_outlined, color: color),
      ],
    );

    return InkWell(
      onTap: isLoading ? null : onTap,
      borderRadius: BorderRadius.circular(grouped ? 0 : 22),
      child: Container(
        margin: margin,
        padding: const EdgeInsets.all(16),
        decoration: grouped
            ? null
            : BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: AppTheme.outline),
              ),
        child: content,
      ),
    );
  }
}
