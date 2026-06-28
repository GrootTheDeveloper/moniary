import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../app/app_theme.dart';
import '../../../../l10n/l10n_extension.dart';
import '../../domain/import/import_history_entry.dart';

class ImportDetailScreen extends StatelessWidget {
  const ImportDetailScreen({super.key, required this.entry});

  static const routePath = 'detail';
  final ImportHistoryEntry entry;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(title: Text(context.l10n.importDetailTitle)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  const Icon(
                    Icons.description_outlined,
                    size: 48,
                    color: AppTheme.mint,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    entry.fileName,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  _DetailTile(
                    icon: Icons.calendar_today_outlined,
                    title: context.l10n.importDetailDate,
                    value: DateFormat(
                      'dd/MM/yyyy HH:mm',
                    ).format(entry.createdAt),
                  ),
                  const Divider(height: 1, color: Colors.white24),
                  _DetailTile(
                    icon: Icons.list_alt,
                    title: context.l10n.importDetailImportedCount,
                    value: entry.importedCount.toString(),
                  ),
                  const Divider(height: 1, color: Colors.white24),
                  _DetailTile(
                    icon: Icons.account_balance_wallet_outlined,
                    title: context.l10n.importDetailWallet,
                    value: entry.walletName.trim().isEmpty ? context.l10n.walletUnknown : entry.walletName,
                  ),
                  const Divider(height: 1, color: Colors.white24),
                  _DetailTile(
                    icon: Icons.info_outline,
                    title: context.l10n.importDetailStatus,
                    value: _statusLabel(context, entry.status),
                  ),
                  if (entry.errorMessage != null &&
                      entry.errorMessage!.isNotEmpty) ...[
                    const Divider(height: 1, color: Colors.white24),
                    _DetailTile(
                      icon: Icons.error_outline,
                      title: context.l10n.importDetailError,
                      value: entry.errorMessage!,
                    ),
                  ],
                ],
              ),
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
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Icon(icon, color: Colors.white54, size: 20),
          const SizedBox(width: 12),
          Text(title, style: const TextStyle(color: Colors.white70)),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
