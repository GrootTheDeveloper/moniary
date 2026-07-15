import 'package:flutter/material.dart';

import '../../../../app/app_theme.dart';
import '../../../../l10n/l10n_extension.dart';
import '../../domain/entities/group_enums.dart';

class SplitModeSelector extends StatelessWidget {
  const SplitModeSelector({
    required this.value,
    required this.onChanged,
    this.onHelp,
    super.key,
  });

  final GroupSplitMode value;
  final ValueChanged<GroupSplitMode> onChanged;
  final VoidCallback? onHelp;

  @override
  Widget build(BuildContext context) {
    final description = switch (value) {
      GroupSplitMode.equal => context.l10n.groupSplitEqualDescription,
      GroupSplitMode.exact => context.l10n.groupSplitExactDescription,
      GroupSplitMode.unequal => context.l10n.groupSplitUnequalDescription,
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Row(
                children: [
                  _SplitModeOption(
                    label: context.l10n.groupSplitEqual,
                    icon: Icons.balance_outlined,
                    selected: value == GroupSplitMode.equal,
                    onTap: () => onChanged(GroupSplitMode.equal),
                    position: _SplitModeOptionPosition.first,
                  ),
                  _SplitModeOption(
                    label: context.l10n.groupSplitExact,
                    icon: Icons.edit_note_outlined,
                    selected: value == GroupSplitMode.exact,
                    onTap: () => onChanged(GroupSplitMode.exact),
                    position: _SplitModeOptionPosition.middle,
                  ),
                  _SplitModeOption(
                    label: context.l10n.groupSplitUnequal,
                    icon: Icons.tune_outlined,
                    selected: value == GroupSplitMode.unequal,
                    onTap: () => onChanged(GroupSplitMode.unequal),
                    position: _SplitModeOptionPosition.last,
                  ),
                ],
              ),
            ),
            if (onHelp != null)
              IconButton(
                tooltip: context.l10n.groupSplitHelp,
                onPressed: onHelp,
                icon: Icon(
                  Icons.help_outline_rounded,
                  color: context.moniaryColors.primary,
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: context.moniaryColors.primary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            description,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: context.moniaryColors.textSecondary,
            ),
          ),
        ),
      ],
    );
  }
}

enum _SplitModeOptionPosition { first, middle, last }

class _SplitModeOption extends StatelessWidget {
  const _SplitModeOption({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
    required this.position,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  final _SplitModeOptionPosition position;

  @override
  Widget build(BuildContext context) {
    final colors = context.moniaryColors;
    final radius = switch (position) {
      _SplitModeOptionPosition.first => const BorderRadius.horizontal(
        left: Radius.circular(12),
      ),
      _SplitModeOptionPosition.middle => BorderRadius.zero,
      _SplitModeOptionPosition.last => const BorderRadius.horizontal(
        right: Radius.circular(12),
      ),
    };
    return Expanded(
      child: Semantics(
        button: true,
        selected: selected,
        label: label,
        child: Material(
          color: selected
              ? colors.primary.withValues(alpha: 0.12)
              : Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: radius,
            child: Container(
              height: 58,
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 5),
              decoration: BoxDecoration(
                border: Border.all(
                  color: selected ? colors.primary : colors.outline,
                  width: selected ? 1.4 : 1,
                ),
                borderRadius: radius,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    icon,
                    size: 18,
                    color: selected ? colors.primary : colors.textSecondary,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    label,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: selected ? colors.primary : colors.textSecondary,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                      height: 1.05,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
