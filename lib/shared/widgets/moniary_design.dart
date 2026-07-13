import 'package:flutter/material.dart';

import '../../app/app_theme.dart';

const moniaryPagePadding = EdgeInsets.symmetric(horizontal: 24);

class MoniarySectionLabel extends StatelessWidget {
  const MoniarySectionLabel(
    this.label, {
    super.key,
    this.trailing,
    this.padding = const EdgeInsets.only(top: 24, bottom: 10),
  });

  final String label;
  final Widget? trailing;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Text(
              label.toUpperCase(),
              style: context.moniaryTypography.metadataStrong.copyWith(
                color: context.moniaryColors.textDim,
              ),
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}

class MoniaryEditorialCard extends StatelessWidget {
  const MoniaryEditorialCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.backgroundColor,
    this.borderColor,
    this.radius = 16,
    this.onTap,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? backgroundColor;
  final Color? borderColor;
  final double radius;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.moniaryColors;
    final decoration = BoxDecoration(
      color: backgroundColor ?? colors.surface.withValues(alpha: 0.82),
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(
        color: borderColor ?? colors.outline.withValues(alpha: 0.72),
      ),
      boxShadow: [
        BoxShadow(
          color: colors.textPrimary.withValues(alpha: 0.035),
          blurRadius: 14,
          offset: const Offset(0, 7),
        ),
      ],
    );

    if (onTap == null) {
      return Container(decoration: decoration, padding: padding, child: child);
    }

    return Material(
      color: Colors.transparent,
      child: Ink(
        decoration: decoration,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(radius),
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}

class MoniaryHairlineTile extends StatelessWidget {
  const MoniaryHairlineTile({
    super.key,
    required this.title,
    this.subtitle,
    this.leading,
    this.trailing,
    this.onTap,
    this.showTopDivider = false,
    this.showBottomDivider = true,
    this.contentPadding = const EdgeInsets.symmetric(vertical: 14),
  });

  final Widget title;
  final Widget? subtitle;
  final Widget? leading;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool showTopDivider;
  final bool showBottomDivider;
  final EdgeInsetsGeometry contentPadding;

  @override
  Widget build(BuildContext context) {
    final colors = context.moniaryColors;
    final divider = BorderSide(
      color: colors.textPrimary.withValues(alpha: 0.11),
      width: 0.8,
    );

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 56),
          padding: contentPadding,
          decoration: BoxDecoration(
            border: Border(
              top: showTopDivider ? divider : BorderSide.none,
              bottom: showBottomDivider ? divider : BorderSide.none,
            ),
          ),
          child: Row(
            children: [
              if (leading != null) ...[
                SizedBox(
                  width: 36,
                  child: IconTheme.merge(
                    data: IconThemeData(color: colors.textPrimary, size: 20),
                    child: leading!,
                  ),
                ),
                const SizedBox(width: 10),
              ],
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    DefaultTextStyle.merge(
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: colors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                      child: title,
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 3),
                      DefaultTextStyle.merge(
                        style: Theme.of(
                          context,
                        ).textTheme.bodySmall?.copyWith(color: colors.textDim),
                        child: subtitle!,
                      ),
                    ],
                  ],
                ),
              ),
              if (trailing != null) ...[
                const SizedBox(width: 12),
                trailing!,
              ] else if (onTap != null) ...[
                const SizedBox(width: 12),
                Icon(Icons.chevron_right, size: 20, color: colors.textDim),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class MoniaryPill extends StatelessWidget {
  const MoniaryPill({
    super.key,
    required this.label,
    this.selected = false,
    this.onTap,
    this.leading,
  });

  final String label;
  final bool selected;
  final VoidCallback? onTap;
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    final colors = context.moniaryColors;
    final foreground = selected ? colors.background : colors.textSecondary;
    final background = selected
        ? colors.textPrimary
        : colors.surface.withValues(alpha: 0.64);

    return Material(
      color: background,
      shape: StadiumBorder(
        side: BorderSide(
          color: selected
              ? colors.textPrimary
              : colors.outline.withValues(alpha: 0.82),
        ),
      ),
      child: InkWell(
        onTap: onTap,
        customBorder: const StadiumBorder(),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 44),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (leading != null) ...[
                  IconTheme.merge(
                    data: IconThemeData(color: foreground, size: 18),
                    child: leading!,
                  ),
                  const SizedBox(width: 7),
                ],
                Text(
                  label,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: foreground,
                    fontWeight: FontWeight.w600,
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

class MoniaryProgressBar extends StatelessWidget {
  const MoniaryProgressBar({
    super.key,
    required this.value,
    this.height = 6,
    this.color,
    this.backgroundColor,
  });

  final double value;
  final double height;
  final Color? color;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    final colors = context.moniaryColors;
    final clampedValue = value.clamp(0.0, 1.0);

    return Semantics(
      value: '${(clampedValue * 100).round()}%',
      child: ClipRRect(
        borderRadius: BorderRadius.circular(height),
        child: SizedBox(
          height: height,
          child: LayoutBuilder(
            builder: (context, constraints) {
              return Stack(
                fit: StackFit.expand,
                children: [
                  ColoredBox(
                    color:
                        backgroundColor ??
                        colors.textPrimary.withValues(alpha: 0.08),
                  ),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 240),
                      curve: Curves.easeOutCubic,
                      width: constraints.maxWidth * clampedValue,
                      color: color ?? colors.primary,
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class MoniaryDotBadge extends StatelessWidget {
  const MoniaryDotBadge({super.key, required this.color, this.size = 10});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      child: SizedBox.square(dimension: size),
    );
  }
}
