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
    final colors = context.moniaryColors;
    final color = destructive ? colors.danger : colors.primary;

    final content = Row(
      children: [
        SizedBox(width: 34, child: Icon(icon, color: color, size: 20)),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: destructive ? colors.danger : colors.textPrimary,
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
        const SizedBox(width: 6),
        if (isLoading)
          SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2, color: color),
          )
        else
          Icon(Icons.chevron_right_outlined, color: colors.textDim, size: 20),
      ],
    );

    return InkWell(
      onTap: isLoading ? null : onTap,
      borderRadius: BorderRadius.circular(grouped ? 0 : 16),
      child: Container(
        margin: margin,
        constraints: const BoxConstraints(minHeight: 60),
        padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 14),
        decoration: grouped
            ? BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: colors.textPrimary.withValues(alpha: 0.12),
                  ),
                ),
              )
            : BoxDecoration(
                color: colors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: colors.outline),
              ),
        child: content,
      ),
    );
  }
}
