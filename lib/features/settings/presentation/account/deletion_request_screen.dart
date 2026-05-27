import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/app_theme.dart';
import '../../application/account/account_actions_controller.dart';

class DeletionRequestScreen extends ConsumerStatefulWidget {
  const DeletionRequestScreen({super.key});

  static const routePath = '/deletion-request';

  @override
  ConsumerState<DeletionRequestScreen> createState() =>
      _DeletionRequestScreenState();
}

class _DeletionRequestScreenState extends ConsumerState<DeletionRequestScreen> {
  final _reasonController = TextEditingController();

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(accountActionsControllerProvider);

    ref.listen(accountActionsControllerProvider, (previous, next) {
      next.whenOrNull(
        error: (error, stackTrace) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(error.toString())));
        },
      );
    });

    return Scaffold(
      appBar: AppBar(title: const Text('Yêu cầu xóa dữ liệu')),
      body: SafeArea(
        child: Stack(
          children: [
            ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
              children: [
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceRaised,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: AppTheme.outline),
                  ),
                  child: Text(
                    'Dùng lựa chọn này khi không thể xóa tài khoản trực tiếp trong app. Moniary sẽ tạo một file yêu cầu để bạn gửi cho kênh hỗ trợ quyền riêng tư.',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _reasonController,
                  minLines: 4,
                  maxLines: 6,
                  decoration: const InputDecoration(
                    labelText: 'Lý do hoặc ghi chú cho yêu cầu',
                    hintText:
                        'Ví dụ: Tôi không còn sử dụng app và muốn xóa toàn bộ dữ liệu.',
                  ),
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: state.isLoading ? null : _createRequest,
                  icon: const Icon(Icons.description_outlined),
                  label: const Text('Tạo yêu cầu xóa dữ liệu'),
                ),
              ],
            ),
            if (state.isLoading)
              const Positioned.fill(
                child: ColoredBox(
                  color: Color(0x66000000),
                  child: Center(child: CircularProgressIndicator()),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _createRequest() async {
    final file = await ref
        .read(accountActionsControllerProvider.notifier)
        .createDeletionRequest(reason: _reasonController.text);
    if (!mounted || file == null) {
      return;
    }

    await showDialog<void>(
      context: context,
      builder: (context) => _DeletionRequestDialog(file: file),
    );
  }
}

class _DeletionRequestDialog extends StatelessWidget {
  const _DeletionRequestDialog({required this.file});

  final File file;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Đã tạo yêu cầu'),
      content: Text(
        'File yêu cầu đã được lưu tại:\n${file.path}',
        style: Theme.of(context).textTheme.bodyMedium,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Đóng'),
        ),
      ],
    );
  }
}
