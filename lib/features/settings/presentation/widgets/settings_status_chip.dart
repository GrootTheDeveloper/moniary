import 'package:flutter/material.dart';

import '../../../../app/app_theme.dart';

enum SettingsStatusTone { neutral, info, success, warning, danger }

class SettingsStatusChip extends StatelessWidget {
  const SettingsStatusChip({
    required this.label,
    this.tone = SettingsStatusTone.neutral,
    super.key,
  });

  final String label;
  final SettingsStatusTone tone;

  @override
  Widget build(BuildContext context) {
    final color = switch (tone) {
      SettingsStatusTone.neutral => AppTheme.textSubtle,
      SettingsStatusTone.info => AppTheme.mintSoft,
      SettingsStatusTone.success => AppTheme.success,
      SettingsStatusTone.warning => AppTheme.amber,
      SettingsStatusTone.danger => AppTheme.danger,
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
