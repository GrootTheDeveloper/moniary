import 'package:flutter/material.dart';

import '../../app/app_theme.dart';
import '../../l10n/l10n_extension.dart';

enum ConfirmActionStyle { primary, danger, neutral }

class ConfirmAction<T> {
  const ConfirmAction(
    this.label,
    this.value, {
    this.style = ConfirmActionStyle.primary,
  });

  final String label;
  final T value;
  final ConfirmActionStyle style;
}

/// A confirmation dialog with a centered icon badge, title and message, then
/// full-width stacked action buttons and a trailing Cancel. Pops with the
/// chosen action's value, or null on cancel.
class ConfirmActionDialog<T> extends StatelessWidget {
  const ConfirmActionDialog({
    required this.icon,
    required this.title,
    required this.message,
    required this.actions,
    this.iconColor,
    super.key,
  });

  final IconData icon;
  final Color? iconColor;
  final String title;
  final String message;
  final List<ConfirmAction<T>> actions;

  @override
  Widget build(BuildContext context) {
    final colors = context.moniaryColors;
    final accent = iconColor ?? colors.primary;
    return AlertDialog(
      backgroundColor: colors.surface,
      icon: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          color: accent.withValues(alpha: 0.12),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: accent),
      ),
      title: Text(title, textAlign: TextAlign.center),
      content: Text(
        message,
        textAlign: TextAlign.center,
        style: TextStyle(color: colors.textDim, height: 1.4),
      ),
      actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      actions: [
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final action in actions) ...[
              SizedBox(width: double.infinity, child: _button(context, action)),
              const SizedBox(height: 8),
            ],
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(context.l10n.commonCancel),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _button(BuildContext context, ConfirmAction<T> action) {
    final colors = context.moniaryColors;
    void onPressed() => Navigator.pop(context, action.value);
    return switch (action.style) {
      ConfirmActionStyle.primary => FilledButton(
        onPressed: onPressed,
        child: Text(action.label),
      ),
      ConfirmActionStyle.danger => FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(backgroundColor: colors.danger),
        child: Text(action.label),
      ),
      ConfirmActionStyle.neutral => OutlinedButton(
        onPressed: onPressed,
        child: Text(action.label),
      ),
    };
  }
}
