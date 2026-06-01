import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../app/app_theme.dart';
import '../../data/export/file_action_service.dart';
import '../../domain/export/export_history_entry.dart';

class ExportDetailScreen extends ConsumerWidget {
  const ExportDetailScreen({super.key, required this.entry});

  final ExportHistoryEntry entry;

  static const routePath = '/export-detail';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final createdAt = DateFormat('dd/MM/yyyy HH:mm').format(entry.createdAt);
    final file = File(entry.path);
    final exists = file.existsSync();

    return Scaffold(
      appBar: AppBar(title: const Text('Chi tiết bản xuất')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
          children: [
            _DetailHeader(entry: entry),
            const SizedBox(height: 24),
            _InfoSection(
              title: 'Thông tin file',
              items: [
                _InfoRow(label: 'Thời gian', value: createdAt),
                _InfoRow(label: 'Định dạng', value: entry.format.toUpperCase()),
                _InfoRow(
                  label: 'Trạng thái',
                  value: exists ? 'Sẵn sàng' : 'File đã bị xóa',
                  valueColor: exists ? AppTheme.success : AppTheme.danger,
                ),
              ],
            ),
            const SizedBox(height: 16),
            _InfoSection(
              title: 'Cấu hình dữ liệu',
              items: [
                _InfoRow(label: 'Thời gian dữ liệu', value: entry.dateRange),
                _InfoRow(label: 'Các nhóm dữ liệu', value: entry.dataTypes.join(', ')),
              ],
            ),
            const SizedBox(height: 16),
            _InfoSection(
              title: 'Đường dẫn lưu trữ',
              items: [
                _InfoRow(
                  label: 'Vị trí',
                  value: entry.path,
                  isLongText: true,
                ),
              ],
            ),
            const SizedBox(height: 32),
            if (exists) ...[
              FilledButton.icon(
                onPressed: () => ref.read(fileActionServiceProvider).open(file),
                icon: const Icon(Icons.open_in_new),
                label: const Text('Mở xem file ngay'),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () => ref.read(fileActionServiceProvider).share(file),
                icon: const Icon(Icons.share_outlined),
                label: const Text('Chia sẻ qua Email / Zalo'),
              ),
            ] else
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.danger.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.danger.withValues(alpha: 0.3)),
                ),
                child: const Text(
                  'Tệp tin này không còn tồn tại trên thiết bị. Bạn có thể thực hiện xuất lại dữ liệu với các bộ lọc tương tự.',
                  style: TextStyle(color: AppTheme.danger),
                  textAlign: TextAlign.center,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _DetailHeader extends StatelessWidget {
  const _DetailHeader({required this.entry});
  final ExportHistoryEntry entry;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: AppTheme.mint.withValues(alpha: 0.1),
            shape: BoxShape.circle,
            border: Border.all(color: AppTheme.mint.withValues(alpha: 0.2)),
          ),
          child: Center(
            child: Text(
              entry.format.toUpperCase(),
              style: const TextStyle(
                color: AppTheme.mint,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Xuất dữ liệu thành công',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          'Moniary Financial Report',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white54),
        ),
      ],
    );
  }
}

class _InfoSection extends StatelessWidget {
  const _InfoSection({required this.title, required this.items});
  final String title;
  final List<Widget> items;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            title,
            style: const TextStyle(
              color: AppTheme.mint,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppTheme.outline),
          ),
          child: Column(children: items),
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.label,
    required this.value,
    this.valueColor,
    this.isLongText = false,
  });

  final String label;
  final String value;
  final Color? valueColor;
  final bool isLongText;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: isLongText
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(color: Colors.white54, fontSize: 13)),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(color: valueColor ?? Colors.white70, fontSize: 12),
                ),
              ],
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(label, style: const TextStyle(color: Colors.white54, fontSize: 13)),
                const SizedBox(width: 16),
                Flexible(
                  child: Text(
                    value,
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      color: valueColor ?? Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
