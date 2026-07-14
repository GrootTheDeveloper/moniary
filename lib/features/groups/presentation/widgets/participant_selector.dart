import 'package:flutter/material.dart';

import '../../../../l10n/l10n_extension.dart';
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
  final void Function(String userId, bool selected) onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.l10n.groupParticipantsTitle,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        for (final member in members)
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            value: selectedIds.contains(member.userId),
            title: Text(member.resolvedName),
            onChanged: (value) => onChanged(member.userId, value ?? false),
          ),
      ],
    );
  }
}

class ExactShareInputList extends StatelessWidget {
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
  Widget build(BuildContext context) {
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
                suffixText: context.l10n.transactionAmountSuffix,
              ),
            ),
          ),
      ],
    );
  }
}
