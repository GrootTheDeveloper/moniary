import 'package:flutter/material.dart';

import '../../../../l10n/l10n_extension.dart';

Future<bool> showGroupConfirmationDialog(
  BuildContext context, {
  required String message,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      content: Text(message),
      actions: [
        TextButton(
          key: const ValueKey('cancel-group-transaction'),
          onPressed: () => Navigator.pop(context, false),
          child: Text(context.l10n.commonCancel),
        ),
        FilledButton(
          key: const ValueKey('confirm-group-transaction'),
          onPressed: () => Navigator.pop(context, true),
          child: Text(context.l10n.groupPost),
        ),
      ],
    ),
  );
  return result ?? false;
}
