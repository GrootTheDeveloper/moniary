import '../../../../l10n/l10n_extension.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../app/app_theme.dart';
import '../../../../shared/utils/error_helpers.dart';
import '../../application/account/account_actions_controller.dart';
import '../../domain/export/export_history_entry.dart';
import 'export_detail_screen.dart';

class ExportHistoryScreen extends ConsumerWidget {
  const ExportHistoryScreen({super.key});

  static const routePath = '/export-history';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(exportHistoryProvider);

    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.exportHistoryTitle)),
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
          error: (error, stackTrace) =>
              Center(child: Text(userFriendlyMessage(context, error))),
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
      child: InkWell(
        onTap: () => context.push(ExportDetailScreen.routePath, extra: entry),
        borderRadius: BorderRadius.circular(22),
        child: Ink(
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
              const Icon(Icons.chevron_right, color: Colors.white54),
            ],
          ),
        ),
      ),
    );
  }
}
