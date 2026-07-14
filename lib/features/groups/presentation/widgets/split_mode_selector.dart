import 'package:flutter/material.dart';

import '../../../../l10n/l10n_extension.dart';
import '../../domain/entities/group_enums.dart';

class SplitModeSelector extends StatelessWidget {
  const SplitModeSelector({
    required this.value,
    required this.onChanged,
    super.key,
  });

  final GroupSplitMode value;
  final ValueChanged<GroupSplitMode> onChanged;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SegmentedButton<GroupSplitMode>(
        segments: [
          ButtonSegment(
            value: GroupSplitMode.equal,
            label: Text(context.l10n.groupSplitEqual),
            icon: const Icon(Icons.balance_outlined),
          ),
          ButtonSegment(
            value: GroupSplitMode.exact,
            label: Text(context.l10n.groupSplitExact),
            icon: const Icon(Icons.edit_note_outlined),
          ),
          ButtonSegment(
            value: GroupSplitMode.unequal,
            label: Text(context.l10n.groupSplitUnequal),
            icon: const Icon(Icons.tune_outlined),
          ),
        ],
        selected: {value},
        showSelectedIcon: false,
        onSelectionChanged: (selection) => onChanged(selection.first),
      ),
    );
  }
}
