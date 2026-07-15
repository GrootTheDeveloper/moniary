import 'package:flutter/material.dart';

import '../../../../l10n/l10n_extension.dart';
import '../../domain/entities/group_enums.dart';

/// A compact, fixed-width filter control for the three transaction states.
///
/// Labels are intentionally short so the control stays usable on narrow
/// phones. The selected state is still explained by the surrounding screen.
class GroupTransactionFilterBar extends StatelessWidget {
  const GroupTransactionFilterBar({
    required this.value,
    required this.onChanged,
    super.key,
  });

  final GroupSplitStatus? value;
  final ValueChanged<GroupSplitStatus?> onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: Row(
        children: [
          Expanded(
            child: _FilterChip(
              label: context.l10n.groupTransactionFilterAll,
              selected: value == null,
              onTap: () => onChanged(null),
            ),
          ),
          Expanded(
            child: _FilterChip(
              label: context.l10n.groupTransactionPostedStatus,
              selected: value == GroupSplitStatus.posted,
              onTap: () => onChanged(GroupSplitStatus.posted),
            ),
          ),
          Expanded(
            child: _FilterChip(
              label: context.l10n.groupTransactionPendingShort,
              selected: value != null && value != GroupSplitStatus.posted,
              onTap: () => onChanged(GroupSplitStatus.pendingMemberAmountInput),
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ChoiceChip(
        label: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
        selected: selected,
        onSelected: (_) => onTap(),
        labelPadding: const EdgeInsets.symmetric(horizontal: 8),
        padding: EdgeInsets.zero,
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        visualDensity: const VisualDensity(horizontal: -2, vertical: -2),
      ),
    );
  }
}
