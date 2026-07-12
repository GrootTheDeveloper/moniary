import 'package:flutter/material.dart';

import '../../../../app/app_theme.dart';

class SettingsGroupCard extends StatelessWidget {
  const SettingsGroupCard({
    required this.title,
    required this.children,
    this.subtitle,
    super.key,
  });

  final String title;
  final String? subtitle;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final colors = context.moniaryColors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title.toUpperCase(),
                style: context.moniaryTypography.metadataStrong.copyWith(
                  color: colors.textDim,
                ),
              ),
              if (subtitle?.isNotEmpty == true) ...[
                const SizedBox(height: 5),
                Text(subtitle!, style: Theme.of(context).textTheme.bodyMedium),
              ],
            ],
          ),
        ),
        Container(
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(
                color: colors.textPrimary.withValues(alpha: 0.12),
              ),
            ),
          ),
          child: Column(children: [for (final child in children) child]),
        ),
      ],
    );
  }
}
