import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../app/app_theme.dart';
import '../../../../l10n/l10n_extension.dart';
import '../../domain/export/export_history_entry.dart';
import 'export_file_actions.dart';
import 'export_l10n_helpers.dart';

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
      appBar: AppBar(title: Text(context.l10n.exportDetailTitle)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
          children: [
            _DetailHeader(entry: entry),
            const SizedBox(height: 24),
            _InfoSection(
              title: context.l10n.exportDetailFileInfo,
              items: [
                _InfoRow(
                  label: context.l10n.exportDetailTime,
                  value: createdAt,
                ),
                _InfoRow(
                  label: context.l10n.exportDetailFormat,
                  value: entry.format.toUpperCase(),
                ),
                _InfoRow(
                  label: context.l10n.exportDetailStatus,
                  value: exists
                      ? context.l10n.exportDetailReady
                      : context.l10n.exportDetailMissing,
                  valueColor: exists ? AppTheme.success : AppTheme.danger,
                ),
              ],
            ),
            const SizedBox(height: 16),
            _InfoSection(
              title: context.l10n.exportDetailDataConfig,
              items: [
                _InfoRow(
                  label: context.l10n.exportDetailDataRange,
                  value: localizedExportDateRange(context, entry),
                ),
                _InfoRow(
                  label: context.l10n.exportDetailDataGroups,
                  value: localizedExportDataTypeList(context, entry.dataTypes),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _InfoSection(
              title: context.l10n.exportDetailStoragePath,
              items: [
                _InfoRow(
                  label: context.l10n.exportDetailLocation,
                  value: entry.path,
                  isLongText: true,
                ),
              ],
            ),
            const SizedBox(height: 32),
            if (exists) ...[
              FilledButton.icon(
                onPressed: () => openExportFile(context, ref, file),
                icon: const Icon(Icons.open_in_new),
                label: Text(context.l10n.exportDetailOpenFile),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () => shareExportFile(context, ref, file),
                icon: const Icon(Icons.share_outlined),
                label: Text(context.l10n.exportDetailShareFile),
              ),
            ] else
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.danger.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppTheme.danger.withValues(alpha: 0.3),
                  ),
                ),
                child: Text(
                  context.l10n.exportDetailMissingMessage,
                  style: const TextStyle(color: AppTheme.danger),
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
        Text(
          context.l10n.exportDetailSuccessTitle,
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          context.l10n.exportDetailReportSubtitle,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: Colors.white54),
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
                Text(
                  label,
                  style: const TextStyle(color: Colors.white54, fontSize: 13),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    color: valueColor ?? Colors.white70,
                    fontSize: 12,
                  ),
                ),
              ],
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  label,
                  style: const TextStyle(color: Colors.white54, fontSize: 13),
                ),
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
