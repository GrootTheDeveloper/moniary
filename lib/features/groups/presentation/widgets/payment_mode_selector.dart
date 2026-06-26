import 'package:flutter/material.dart';

import '../../../../l10n/l10n_extension.dart';
import '../../domain/entities/group_enums.dart';

class PaymentModeSelector extends StatelessWidget {
  const PaymentModeSelector({
    required this.value,
    required this.onChanged,
    super.key,
  });

  final GroupPaymentMode value;
  final ValueChanged<GroupPaymentMode> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        RadioGroup<GroupPaymentMode>(
          groupValue: value,
          onChanged: (mode) {
            if (mode != null) onChanged(mode);
          },
          child: Column(
            children: [
              RadioListTile<GroupPaymentMode>(
                value: GroupPaymentMode.everyonePaid,
                title: Text(context.l10n.groupPaymentEveryone),
                contentPadding: EdgeInsets.zero,
              ),
              RadioListTile<GroupPaymentMode>(
                value: GroupPaymentMode.singlePayer,
                title: Text(context.l10n.groupPaymentSingle),
                contentPadding: EdgeInsets.zero,
              ),
              RadioListTile<GroupPaymentMode>(
                value: GroupPaymentMode.multiplePayers,
                title: Text(context.l10n.groupPaymentMultiple),
                contentPadding: EdgeInsets.zero,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
