import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../app/app_theme.dart';
import '../../application/account/account_actions_controller.dart';
import '../../data/export/file_action_service.dart';
import '../../domain/export/export_history_entry.dart';

class ExportHistoryScreen extends ConsumerWidget {
  const ExportHistoryScreen({super.key});

  static const routePath = '/export-history';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(exportHistoryProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Lịch sử xuất dữ liệu')),
      body: SafeArea(
        child: historyAsync.when(
          data: (items) {
            if (items.isEmpty) {
              return Center(
                child: Text(
                  'Chưa có file export nào.',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              );
            }
            return ListView.builder(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
              itemCount: items.length,
              itemBuilder: (context, index) =>
                  _HistoryTile(entry: items[index]),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stackTrace) => Center(child: Text(error.toString())),
        ),
      ),
    );
  }
}

class _HistoryTile extends ConsumerWidget {
  const _HistoryTile({required this.entry});

  final ExportHistoryEntry entry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final createdAt = DateFormat('dd/MM/yyyy HH:mm').format(entry.createdAt);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppTheme.outline),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: AppTheme.mint.withValues(alpha: 0.16),
            child: Text(
              entry.format,
              style: const TextStyle(color: AppTheme.mint, fontSize: 11),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(createdAt, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 4),
                Text(
                  entry.dataTypes.join(', '),
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 2),
                Text(
                  entry.dateRange,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () async {
              final opened = await ref
                  .read(fileActionServiceProvider)
                  .open(File(entry.path));
              if (!context.mounted) {
                return;
              }
              if (!opened) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Không mở được file này. File có thể đã bị xóa.',
                    ),
                  ),
                );
              }
            },
            icon: const Icon(Icons.open_in_new_rounded, color: AppTheme.mint),
          ),
        ],
      ),
    );
  }
}
