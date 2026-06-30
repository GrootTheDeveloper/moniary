import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../app/app_theme.dart';
import '../../../../l10n/l10n_extension.dart';
import '../../application/import_controller.dart';
import '../../domain/import/import_history_entry.dart';
import '../widgets/recent_history_error_card.dart';
import 'import_detail_screen.dart';

class ImportHistoryScreen extends ConsumerWidget {
  const ImportHistoryScreen({super.key});

  static const routePath = '/import-history';
  static const detailRoutePath = '$routePath/${ImportDetailScreen.routePath}';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(importHistoryProvider);

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(title: Text(context.l10n.importHistoryTitle)),
      body: historyAsync.when(
        data: (history) {
          if (history.isEmpty) {
            return Center(
              child: Text(
                context.l10n.importNoHistory,
                style: const TextStyle(color: Colors.white70),
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: history.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final entry = history[index];
              return _HistoryCard(entry: entry);
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: RecentHistoryErrorCard(
              message: context.l10n.importRecentHistoryError,
              onRetry: () => ref.invalidate(importHistoryProvider),
            ),
          ),
        ),
      ),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  const _HistoryCard({required this.entry});

  final ImportHistoryEntry entry;

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat('dd/MM/yyyy HH:mm', Localizations.localeOf(context).toString()).format(entry.createdAt);

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () {
        context.push(ImportHistoryScreen.detailRoutePath, extra: entry);
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white24),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.download_done, color: AppTheme.mint, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    entry.fileName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  dateStr,
                  style: const TextStyle(color: Colors.white54, fontSize: 12),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              '${context.l10n.importDetailImportedCount}: ${entry.importedCount}',
              style: const TextStyle(color: Colors.white70, fontSize: 13),
            ),
            const SizedBox(height: 4),
            Text(
              '${context.l10n.importDetailWallet}: ${entry.walletName.trim().isEmpty ? context.l10n.walletUnknown : entry.walletName}',
              style: const TextStyle(color: Colors.white70, fontSize: 13),
            ),
            const SizedBox(height: 4),
            Text(
              '${context.l10n.importDetailStatus}: ${_statusLabel(context, entry.status)}',
              style: TextStyle(color: _statusColor(entry.status), fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }

  static String _statusLabel(BuildContext context, ImportHistoryStatus status) {
    return switch (status) {
      ImportHistoryStatus.pending => context.l10n.importStatusPending,
      ImportHistoryStatus.completed => context.l10n.importStatusCompleted,
      ImportHistoryStatus.failed => context.l10n.importStatusFailed,
    };
  }

  static Color _statusColor(ImportHistoryStatus status) {
    return switch (status) {
      ImportHistoryStatus.pending => AppTheme.mint,
      ImportHistoryStatus.completed => Colors.white70,
      ImportHistoryStatus.failed => AppTheme.danger,
    };
  }
}
