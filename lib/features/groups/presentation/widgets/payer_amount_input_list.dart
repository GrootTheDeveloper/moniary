import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../l10n/l10n_extension.dart';
import '../../../../shared/utils/currency_formatting_ref.dart';
import '../../../../shared/utils/integer_money_input_formatter.dart';
import '../../domain/entities/group_enums.dart';
import '../../domain/entities/spending_group.dart';

class PayerAmountInputList extends ConsumerWidget {
  const PayerAmountInputList({
    required this.members,
    required this.paymentMode,
    required this.selectedPayerIds,
    required this.controllers,
    required this.onSingleSelected,
    required this.onMultipleToggled,
    super.key,
  });

  final List<SpendingGroupMember> members;
  final GroupPaymentMode paymentMode;
  final Set<String> selectedPayerIds;
  final Map<String, TextEditingController> controllers;
  final ValueChanged<String> onSingleSelected;
  final void Function(String userId, bool selected) onMultipleToggled;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (paymentMode == GroupPaymentMode.everyonePaid) {
      return const SizedBox.shrink();
    }
    if (paymentMode == GroupPaymentMode.singlePayer) {
      final selected = selectedPayerIds.length == 1
          ? selectedPayerIds.first
          : null;
      return RadioGroup<String>(
        groupValue: selected,
        onChanged: (value) {
          if (value != null) onSingleSelected(value);
        },
        child: Column(
          children: members
              .map(
                (member) => RadioListTile<String>(
                  value: member.userId,
                  title: Text(member.resolvedName),
                  contentPadding: EdgeInsets.zero,
                ),
              )
              .toList(),
        ),
      );
    }
    return Column(
      children: members.map((member) {
        final selected = selectedPayerIds.contains(member.userId);
        return Column(
          children: [
            CheckboxListTile(
              value: selected,
              title: Text(member.resolvedName),
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
              onChanged: (value) =>
                  onMultipleToggled(member.userId, value ?? false),
            ),
            if (selected)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: TextField(
                  key: ValueKey('payer-amount-${member.userId}'),
                  controller: controllers[member.userId],
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    IntegerMoneyInputFormatter(
                      locale: Localizations.localeOf(context).toString(),
                    ),
                  ],
                  decoration: InputDecoration(
                    labelText: context.l10n.groupTransactionTotal,
                    suffixText: ref.currencySymbol,
                  ),
                ),
              ),
          ],
        );
      }).toList(),
    );
  }
}
