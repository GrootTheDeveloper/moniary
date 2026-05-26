import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/app_theme.dart';
import '../application/account_actions_controller.dart';
import '../data/file_action_service.dart';

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
                      enabled: true,
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
    final file = switch (_format) {
      ExportFormat.csv => await ref.read(accountActionsControllerProvider.notifier).exportCsv(),
      ExportFormat.xlsx => await ref.read(accountActionsControllerProvider.notifier).exportXlsx(),
      ExportFormat.pdf => await ref.read(accountActionsControllerProvider.notifier).exportPdf(),
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
        TextButton.icon(
          onPressed: () async {
            final shared = await ProviderScope.containerOf(context)
                .read(fileActionServiceProvider)
                .share(file);
            if (!context.mounted) {
              return;
            }
            if (!shared) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Chưa tìm thấy app phù hợp để chia sẻ file.')),
              );
            }
          },
          icon: const Icon(Icons.ios_share_rounded),
          label: const Text('Chia sẻ'),
        ),
        TextButton.icon(
          onPressed: () async {
            final opened = await ProviderScope.containerOf(context)
                .read(fileActionServiceProvider)
                .open(file);
            if (!context.mounted) {
              return;
            }
            if (!opened) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Chưa tìm thấy app phù hợp để mở file.')),
              );
            }
          },
          icon: const Icon(Icons.open_in_new_rounded),
          label: const Text('Mở'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Đóng'),
        ),
      ],
    );
  }
}
