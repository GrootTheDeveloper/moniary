import '../../../../l10n/l10n_extension.dart';
import 'package:go_router/go_router.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../app/app_theme.dart';
import '../../../../shared/utils/error_helpers.dart';
import '../../application/account/account_actions_controller.dart';
import '../../data/export/file_action_service.dart';
import '../../domain/export/export_filters.dart';
import '../../domain/export/export_history_entry.dart';
import 'export_detail_screen.dart';
import 'export_history_screen.dart';
import 'export_l10n_helpers.dart';

enum ExportFormat { csv, xlsx, pdf }

extension ExportFormatL10n on ExportFormat {
  String getLabel(BuildContext context) {
    return switch (this) {
      ExportFormat.csv => context.l10n.exportFormatCsvLabel,
      ExportFormat.xlsx => context.l10n.exportFormatXlsxLabel,
      ExportFormat.pdf => context.l10n.exportFormatPdfLabel,
    };
  }

  String getDescription(BuildContext context) {
    return switch (this) {
      ExportFormat.csv => context.l10n.exportFormatCsvDesc,
      ExportFormat.xlsx => context.l10n.exportFormatXlsxDesc,
      ExportFormat.pdf => context.l10n.exportFormatPdfDesc,
    };
  }
}

class ExportDataScreen extends ConsumerStatefulWidget {
  const ExportDataScreen({super.key});

  static const routePath = '/export-data';

  @override
  ConsumerState<ExportDataScreen> createState() => _ExportDataScreenState();
}

class _ExportDataScreenState extends ConsumerState<ExportDataScreen> {
  ExportFormat _format = ExportFormat.csv;
  ExportFilters _filters = const ExportFilters();

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(accountActionsControllerProvider);

    ref.listen(accountActionsControllerProvider, (previous, next) {
      next.whenOrNull(
        error: (error, stackTrace) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(userFriendlyMessage(context, error))),
          );
        },
      );
    });

    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.exportTitle)),
      body: SafeArea(
        child: Stack(
          children: [
            ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
              children: [
                Text(
                  context.l10n.exportFormat,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
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
                _DateRangeCard(
                  filters: _filters,
                  onPick: _pickDateRange,
                  onClear: _filters.hasDateRange
                      ? () => setState(
                          () => _filters = _filters.copyWith(
                            clearDateRange: true,
                          ),
                        )
                      : null,
                ),
                const SizedBox(height: 12),
                _DataTypesCard(
                  selectedTypes: _filters.dataTypes,
                  onChanged: (types) {
                    setState(
                      () => _filters = _filters.copyWith(dataTypes: types),
                    );
                  },
                ),
                const SizedBox(height: 8),
                FilledButton.icon(
                  onPressed: state.isLoading ? null : _export,
                  icon: const Icon(Icons.file_download_outlined),
                  label: Text(context.l10n.exportButton),
                ),
                const SizedBox(height: 24),
                _RecentExportsSection(),
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
      ExportFormat.csv =>
        await ref
            .read(accountActionsControllerProvider.notifier)
            .exportCsv(filters: _filters),
      ExportFormat.xlsx =>
        await ref
            .read(accountActionsControllerProvider.notifier)
            .exportXlsx(filters: _filters),
      ExportFormat.pdf =>
        await ref
            .read(accountActionsControllerProvider.notifier)
            .exportPdf(filters: _filters),
    };
    if (!mounted || file == null) {
      return;
    }

    await ref.read(fileActionServiceProvider).open(file);
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(context.l10n.exportDone),
        action: SnackBarAction(
          label: context.l10n.commonShare,
          onPressed: () => ref.read(fileActionServiceProvider).share(file),
        ),
      ),
    );
  }

  Future<void> _pickDateRange() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 1, 12, 31),
      initialDateRange: _filters.startDate != null && _filters.endDate != null
          ? DateTimeRange(start: _filters.startDate!, end: _filters.endDate!)
          : null,
    );

    if (picked == null || !mounted) {
      return;
    }

    setState(() {
      _filters = _filters.copyWith(
        startDate: picked.start,
        endDate: picked.end,
      );
    });
  }
}

class _DataTypesCard extends StatelessWidget {
  const _DataTypesCard({required this.selectedTypes, required this.onChanged});

  final Set<ExportDataType> selectedTypes;
  final ValueChanged<Set<ExportDataType>> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppTheme.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.l10n.exportDataTypes,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          ...ExportDataType.values.map(
            (type) => CheckboxListTile(
              value: selectedTypes.contains(type),
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              activeColor: AppTheme.mint,
              title: Text(type.getLabel(context)),
              onChanged: (selected) {
                final next = {...selectedTypes};
                if (selected == true) {
                  next.add(type);
                } else if (next.length > 1) {
                  next.remove(type);
                }
                onChanged(next);
              },
            ),
          ),
        ],
      ),
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
          border: Border.all(
            color: selected ? AppTheme.mint : AppTheme.outline,
          ),
        ),
        child: Row(
          children: [
            Icon(
              selected
                  ? Icons.radio_button_checked
                  : Icons.radio_button_unchecked,
              color: selected ? AppTheme.mint : accent,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    format.getLabel(context),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    format.getDescription(context),
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  if (!enabled) ...[
                    const SizedBox(height: 6),
                    Text(
                      context.l10n.commonComingSoon,
                      style: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.copyWith(color: accent),
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
}

class _RecentExportsSection extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(exportHistoryProvider);

    return historyAsync.when(
      data: (items) {
        if (items.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  context.l10n.exportRecentTitle,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton(
                  onPressed: () => context.push(ExportHistoryScreen.routePath),
                  child: Text(context.l10n.commonViewAll),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ...items.take(3).map((item) => _RecentExportTile(entry: item)),
          ],
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (e, st) => const SizedBox.shrink(),
    );
  }
}

class _RecentExportTile extends StatelessWidget {
  const _RecentExportTile({required this.entry});
  final ExportHistoryEntry entry;

  @override
  Widget build(BuildContext context) {
    final date = DateFormat('dd/MM HH:mm').format(entry.createdAt);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.outline),
      ),
      child: ListTile(
        onTap: () => context.push(ExportDetailScreen.routePath, extra: entry),
        leading: CircleAvatar(
          backgroundColor: AppTheme.mint.withValues(alpha: 0.1),
          child: Text(
            entry.format.toUpperCase(),
            style: const TextStyle(color: AppTheme.mint, fontSize: 10),
          ),
        ),
        title: Text(entry.dateRange, style: const TextStyle(fontSize: 14)),
        subtitle: Text(date, style: const TextStyle(fontSize: 12)),
        trailing: const Icon(Icons.chevron_right, size: 20),
      ),
    );
  }
}

class _DateRangeCard extends StatelessWidget {
  const _DateRangeCard({
    required this.filters,
    required this.onPick,
    required this.onClear,
  });

  final ExportFilters filters;
  final VoidCallback onPick;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    final label = filters.hasDateRange
        ? '${_dateLabel(filters.startDate)} - ${_dateLabel(filters.endDate)}'
        : context.l10n.exportAllTime;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppTheme.outline),
      ),
      child: Row(
        children: [
          const Icon(Icons.date_range_outlined, color: AppTheme.mint),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.l10n.exportDateRange,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 4),
                Text(label, style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
          ),
          if (onClear != null)
            IconButton(
              onPressed: onClear,
              icon: const Icon(Icons.close_outlined),
            ),
          TextButton(onPressed: onPick, child: Text(context.l10n.commonSelect)),
        ],
      ),
    );
  }

  static String _dateLabel(DateTime? date) {
    if (date == null) {
      return '...';
    }
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}
