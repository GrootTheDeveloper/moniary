import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/app_theme.dart';
import '../../../../l10n/l10n_extension.dart';
import '../../../../shared/utils/currency_formatting_ref.dart';
import '../../domain/entities/spending_group.dart';

class ParticipantSelector extends StatelessWidget {
  const ParticipantSelector({
    required this.members,
    required this.selectedIds,
    required this.onChanged,
    super.key,
  });

  final List<SpendingGroupMember> members;
  final Set<String> selectedIds;
  final ValueChanged<Set<String>> onChanged;

  @override
  Widget build(BuildContext context) {
    final allSelected =
        members.isNotEmpty &&
        members.every((member) => selectedIds.contains(member.userId));
    final selectedLabel = allSelected
        ? context.l10n.groupParticipantsAllSelected
        : selectedIds.isEmpty
        ? context.l10n.groupParticipantsNoneSelected
        : context.l10n.groupParticipantsSelectedCount(
            selectedIds.length,
            members.length,
          );

    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      color: context.moniaryColors.surface.withValues(alpha: 0.7),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: context.moniaryColors.outline),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => _openPicker(context),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
          child: Row(
            children: [
              Icon(Icons.group_outlined, color: context.moniaryColors.primary),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.l10n.groupParticipantsTitle,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      selectedLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: context.moniaryColors.textDim,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.expand_more_rounded,
                color: context.moniaryColors.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openPicker(BuildContext context) async {
    final selected = {...selectedIds};
    final result = await showModalBottomSheet<Set<String>>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setSheetState) {
          final allSelected =
              members.isNotEmpty &&
              members.every((member) => selected.contains(member.userId));
          return DraggableScrollableSheet(
            expand: false,
            initialChildSize: 0.62,
            minChildSize: 0.38,
            maxChildSize: 0.9,
            builder: (context, scrollController) => Material(
              color: context.moniaryColors.backgroundSoft,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 10),
                  Container(
                    width: 42,
                    height: 4,
                    decoration: BoxDecoration(
                      color: context.moniaryColors.outline,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 12, 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            context.l10n.groupParticipantsSelectHint,
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                        ),
                        TextButton(
                          onPressed: () => setSheetState(() {
                            if (allSelected) {
                              selected.clear();
                            } else {
                              selected
                                ..clear()
                                ..addAll(
                                  members.map((member) => member.userId),
                                );
                            }
                          }),
                          child: Text(
                            allSelected
                                ? context.l10n.groupParticipantsDeselectAll
                                : context.l10n.groupParticipantsSelectAll,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ListView.separated(
                      controller: scrollController,
                      padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
                      itemCount: members.length,
                      separatorBuilder: (_, _) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final member = members[index];
                        return CheckboxListTile(
                          value: selected.contains(member.userId),
                          title: Text(member.resolvedName),
                          controlAffinity: ListTileControlAffinity.leading,
                          onChanged: (value) => setSheetState(() {
                            if (value == true) {
                              selected.add(member.userId);
                            } else {
                              selected.remove(member.userId);
                            }
                          }),
                        );
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                    child: SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: () => Navigator.pop(sheetContext, selected),
                        child: Text(context.l10n.groupParticipantsDone),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
    if (result != null) onChanged({...result});
  }
}

class ExactShareInputList extends ConsumerWidget {
  const ExactShareInputList({
    required this.members,
    required this.selectedIds,
    required this.controllers,
    super.key,
  });

  final List<SpendingGroupMember> members;
  final Set<String> selectedIds;
  final Map<String, TextEditingController> controllers;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedMembers = members
        .where((member) => selectedIds.contains(member.userId))
        .toList(growable: false);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.l10n.groupTransactionShares,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        for (final member in selectedMembers)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: TextField(
              key: ValueKey('share-amount-${member.userId}'),
              controller: controllers[member.userId],
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: member.resolvedName,
                suffixText: ref.currencySymbol,
              ),
            ),
          ),
      ],
    );
  }
}
