import 'package:flutter/material.dart';

import '../../../../app/app_theme.dart';

class DeleteAccountDialog extends StatefulWidget {
  const DeleteAccountDialog({super.key});

  @override
  State<DeleteAccountDialog> createState() => _DeleteAccountDialogState();
}

class _DeleteAccountDialogState extends State<DeleteAccountDialog> {
  static const confirmationText = 'XOA TAI KHOAN';

  final _controller = TextEditingController();
  bool _understood = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final canDelete =
        _understood &&
        _controller.text.trim().toUpperCase() == confirmationText;

    return AlertDialog(
      title: const Text('Xóa tài khoản?'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Thao tác này không thể hoàn tác trong app.',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: AppTheme.danger,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            const _DeleteConsequence(
              text: 'Xóa hồ sơ và phiên đăng nhập hiện tại.',
            ),
            const _DeleteConsequence(
              text: 'Xóa ví, danh mục và toàn bộ giao dịch.',
            ),
            const _DeleteConsequence(
              text: 'Xóa ảnh giao dịch trong Storage theo user ID.',
            ),
            const SizedBox(height: 10),
            CheckboxListTile(
              value: _understood,
              contentPadding: EdgeInsets.zero,
              activeColor: AppTheme.danger,
              controlAffinity: ListTileControlAffinity.leading,
              title: Text(
                'Tôi hiểu dữ liệu sẽ bị xóa khỏi tài khoản này.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              onChanged: (value) =>
                  setState(() => _understood = value ?? false),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _controller,
              decoration: const InputDecoration(
                labelText: 'Nhập XOA TAI KHOAN để xác nhận',
              ),
              textCapitalization: TextCapitalization.characters,
              onChanged: (_) => setState(() {}),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Hủy'),
        ),
        FilledButton(
          onPressed: canDelete ? () => Navigator.of(context).pop(true) : null,
          style: FilledButton.styleFrom(backgroundColor: AppTheme.danger),
          child: const Text('Xóa tài khoản'),
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
