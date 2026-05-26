import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../app/app_theme.dart';
import '../domain/privacy_request_history_entry.dart';

class PrivacyRequestDetailScreen extends StatelessWidget {
  const PrivacyRequestDetailScreen({required this.entry, super.key});

  static const routePath = '/privacy-request-detail';

  final PrivacyRequestHistoryEntry entry;

  @override
  Widget build(BuildContext context) {
    final createdAt = DateFormat('dd/MM/yyyy HH:mm').format(entry.createdAt);

    return Scaffold(
      appBar: AppBar(title: const Text('Chi tiết yêu cầu')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppTheme.surfaceRaised,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppTheme.outline),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.description_outlined,
                    color: AppTheme.mint,
                    size: 34,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    entry.requestType,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tạo lúc $createdAt',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _DetailTile(
              icon: Icons.flag_outlined,
              title: 'Trạng thái',
              value: entry.status,
            ),
            _DetailTile(
              icon: Icons.notes_outlined,
              title: 'Nội dung yêu cầu',
              value: entry.message.trim().isEmpty
                  ? 'Không có nội dung bổ sung.'
                  : entry.message.trim(),
            ),
            _DetailTile(
              icon: Icons.folder_outlined,
              title: 'File đã tạo',
              value: entry.path,
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailTile extends StatelessWidget {
  const _DetailTile({
    required this.icon,
    required this.title,
    required this.value,
  });

  final IconData icon;
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppTheme.outline),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppTheme.mint),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 6),
                Text(value, style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
