import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/app_theme.dart';
import '../../../../l10n/l10n_extension.dart';

class DeleteAccountDialog extends StatefulWidget {
  const DeleteAccountDialog({super.key});

  @override
  State<DeleteAccountDialog> createState() => _DeleteAccountDialogState();
}

class _DeleteAccountDialogState extends State<DeleteAccountDialog> {
  bool _understood = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(context.l10n.deleteAccountTitleQuestion),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.l10n.deleteAccountUndone,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: AppTheme.danger,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            _DeleteConsequence(text: context.l10n.deleteAccountConsequence1),
            _DeleteConsequence(text: context.l10n.deleteAccountConsequence2),
            _DeleteConsequence(text: context.l10n.deleteAccountConsequence3),
            const SizedBox(height: 10),
            CheckboxListTile(
              value: _understood,
              contentPadding: EdgeInsets.zero,
              activeColor: AppTheme.danger,
              controlAffinity: ListTileControlAffinity.leading,
              title: Text(
                context.l10n.deleteAccountUnderstand,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              onChanged: (value) =>
                  setState(() => _understood = value ?? false),
            ),
          ],
        ),
      ),
      actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      actions: [
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            FilledButton(
              onPressed: _understood ? () => context.pop(true) : null,
              style: FilledButton.styleFrom(backgroundColor: AppTheme.danger),
              child: Text(context.l10n.commonConfirm),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => context.pop(false),
              child: Text(context.l10n.commonCancel),
            ),
          ],
        ),
      ],
    );
  }
}

class _DeleteConsequence extends StatelessWidget {
  const _DeleteConsequence({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 5),
            child: Icon(
              Icons.remove_circle_outline,
              color: AppTheme.danger,
              size: 16,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text, style: Theme.of(context).textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }
}
