import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/app_theme.dart';
import '../application/account_actions_controller.dart';

enum ExportFormat {
  csv('CSV', 'Bảng dữ liệu nhẹ, mở được bằng Excel hoặc Google Sheets.'),
  xlsx('Excel', 'Workbook .xlsx cho Excel, Sheets hoặc WPS Office.'),
  pdf('PDF', 'Báo cáo dễ đọc để lưu hoặc gửi cho người khác.');

  const ExportFormat(this.label, this.description);

  final String label;
  final String description;
}

class ExportDataScreen extends ConsumerStatefulWidget {
  const ExportDataScreen({super.key});

  static const routePath = '/export-data';

  @override
  ConsumerState<ExportDataScreen> createState() => _ExportDataScreenState();
}

class _ExportDataScreenState extends ConsumerState<ExportDataScreen> {
  ExportFormat _format = ExportFormat.csv;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(accountActionsControllerProvider);

    ref.listen(accountActionsControllerProvider, (previous, next) {
      next.whenOrNull(
        error: (error, stackTrace) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(error.toString())),
          );
        },
      );
    });

    return Scaffold(
      appBar: AppBar(title: const Text('Xuất dữ liệu')),
      body: SafeArea(
        child: Stack(
          children: [
            ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
              children: [
                Text('Định dạng file', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 12),
                ...ExportFormat.values.map(
                  (format) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _FormatOption(
                      format: format,
                      selected: _format == format,
                      enabled: format == ExportFormat.csv || format == ExportFormat.xlsx,
                      onTap: () => setState(() => _format = format),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                FilledButton.icon(
                  onPressed: state.isLoading ? null : _export,
                  icon: const Icon(Icons.file_download_outlined),
                  label: const Text('Xuất dữ liệu'),
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

  Future<void> _export() async {
    if (_format == ExportFormat.pdf) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${_format.label} sẽ được bật ở bản cập nhật tiếp theo.')),
      );
      return;
    }

    final file = switch (_format) {
      ExportFormat.csv => await ref.read(accountActionsControllerProvider.notifier).exportCsv(),
      ExportFormat.xlsx => await ref.read(accountActionsControllerProvider.notifier).exportXlsx(),
      ExportFormat.pdf => null,
    };
    if (!mounted || file == null) {
      return;
    }

    await showDialog<void>(
      context: context,
      builder: (context) => _ExportCompleteDialog(file: file),
    );
  }
}

class _FormatOption extends StatelessWidget {
  const _FormatOption({
    required this.format,
    required this.selected,
    required this.enabled,
    required this.onTap,
  });

  final ExportFormat format;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final accent = enabled ? AppTheme.mint : const Color(0xFF74889A);
    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(22),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: selected ? AppTheme.mint : AppTheme.outline),
        ),
        child: Row(
          children: [
            Icon(
              selected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
              color: selected ? AppTheme.mint : accent,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(format.label, style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 4),
                  Text(format.description, style: Theme.of(context).textTheme.bodyMedium),
                  if (!enabled) ...[
                    const SizedBox(height: 6),
                    Text('Sắp có', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: accent)),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ExportCompleteDialog extends StatelessWidget {
  const _ExportCompleteDialog({required this.file});

  final File file;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Đã xuất dữ liệu'),
      content: Text(
        'File đã được lưu tại:\n${file.path}',
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
