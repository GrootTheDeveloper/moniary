import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../app/app_theme.dart';
import '../../../../l10n/l10n_extension.dart';
import '../../../../shared/utils/app_logger.dart';
import '../../../../shared/utils/error_helpers.dart';
import '../../application/account/account_actions_controller.dart';
import '../../domain/export/export_filters.dart';
import '../../domain/export/export_history_entry.dart';
import '../widgets/recent_history_error_card.dart';
import 'export_detail_screen.dart';
import 'export_file_actions.dart';
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
      appBar: AppBar(title: Text(context.l10n.exportDataTitle)),
      body: SafeArea(
        child: Stack(
          children: [
            ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
              children: [
                _SectionTitle(title: context.l10n.exportFormat),
                const SizedBox(height: 12),
                ...ExportFormat.values.map(
                  (format) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _FormatOption(
                      format: format,
                      selected: _format == format,
                      onTap: () => setState(() => _format = format),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                _SectionTitle(title: context.l10n.exportDateRange),
                const SizedBox(height: 12),
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
                const SizedBox(height: 16),
                _SectionTitle(title: context.l10n.exportDataTypes),
                const SizedBox(height: 12),
                _DataTypesPickerCard(
                  selectedTypes: _filters.dataTypes,
                  onTap: _showDataTypesPicker,
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: state.isLoading ? null : _export,
                  icon: const Icon(Icons.file_upload_outlined),
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

  Future<void> _showDataTypesPicker() async {
    final selected = await showModalBottomSheet<Set<ExportDataType>>(
      context: context,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) =>
          _DataTypesPickerSheet(selectedTypes: _filters.dataTypes),
    );

    if (selected != null && mounted) {
      setState(() => _filters = _filters.copyWith(dataTypes: selected));
    }
  }

  Future<void> _pickDateRange() async {
    final picked = await showDialog<DateTimeRange>(
      context: context,
      builder: (context) => _DateRangePickerDialog(filters: _filters),
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

  Future<void> _export() async {
    final exportText = buildExportFileText(context);
    final file = switch (_format) {
      ExportFormat.csv =>
        await ref
            .read(accountActionsControllerProvider.notifier)
            .exportCsv(filters: _filters),
      ExportFormat.xlsx =>
        await ref
            .read(accountActionsControllerProvider.notifier)
            .exportXlsx(filters: _filters, text: exportText),
      ExportFormat.pdf =>
        await ref
            .read(accountActionsControllerProvider.notifier)
            .exportPdf(filters: _filters, text: exportText),
    };
    if (!mounted || file == null) {
      return;
    }

    await openExportFile(context, ref, file);
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(context.l10n.exportDone),
        action: SnackBarAction(
          label: context.l10n.commonShare,
          onPressed: () => shareExportFile(context, ref, file),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleLarge?.copyWith(
        color: Colors.white,
        fontWeight: FontWeight.w800,
      ),
    );
  }
}

class _FormatOption extends StatelessWidget {
  const _FormatOption({
    required this.format,
    required this.selected,
    required this.onTap,
  });

  final ExportFormat format;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
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
              color: selected ? AppTheme.mint : AppTheme.mint,
            ),
            const SizedBox(width: 12),
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
                ],
              ),
            ),
          ],
        ),
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
        ? '${dateLabel(filters.startDate)} - ${dateLabel(filters.endDate)}'
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

  static String dateLabel(DateTime? date) {
    if (date == null) {
      return '...';
    }
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}

class _DateRangePickerDialog extends StatefulWidget {
  const _DateRangePickerDialog({required this.filters});

  final ExportFilters filters;

  @override
  State<_DateRangePickerDialog> createState() => _DateRangePickerDialogState();
}

class _DateRangePickerDialogState extends State<_DateRangePickerDialog> {
  late DateTime? _startDate;
  late DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    _startDate = widget.filters.startDate;
    _endDate = widget.filters.endDate;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppTheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: Text(context.l10n.exportDateRange),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 320),
        child: Row(
          children: [
            Expanded(
              child: _DatePill(
                date: _startDate,
                onTap: () => _pickDate(isStart: true),
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 10),
              child: Icon(Icons.arrow_forward, color: AppTheme.textDim),
            ),
            Expanded(
              child: _DatePill(
                date: _endDate,
                onTap: () => _pickDate(isStart: false),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(context.l10n.commonCancel),
        ),
        FilledButton(
          onPressed: _canSave
              ? () => Navigator.pop(
                  context,
                  DateTimeRange(start: _startDate!, end: _endDate!),
                )
              : null,
          child: Text(context.l10n.commonSave),
        ),
      ],
    );
  }

  bool get _canSave {
    final start = _startDate;
    final end = _endDate;
    return start != null && end != null && !end.isBefore(start);
  }

  Future<void> _pickDate({required bool isStart}) async {
    final now = DateTime.now();
    final current = isStart ? _startDate : _endDate;
    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 1, 12, 31),
      initialDate: current ?? now,
    );

    if (picked == null || !mounted) {
      return;
    }

    setState(() {
      if (isStart) {
        _startDate = picked;
        if (_endDate != null && _endDate!.isBefore(picked)) {
          _endDate = picked;
        }
      } else {
        _endDate = picked;
        if (_startDate != null && picked.isBefore(_startDate!)) {
          _startDate = picked;
        }
      }
    });
  }
}

class _DatePill extends StatelessWidget {
  const _DatePill({required this.date, required this.onTap});

  final DateTime? date;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          color: AppTheme.surfaceRaised,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.outline),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.calendar_today_outlined,
              color: AppTheme.mint,
              size: 18,
            ),
            const SizedBox(height: 8),
            Text(
              date == null
                  ? context.l10n.commonSelect
                  : _DateRangeCard.dateLabel(date),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DataTypesPickerCard extends StatelessWidget {
  const _DataTypesPickerCard({
    required this.selectedTypes,
    required this.onTap,
  });

  final Set<ExportDataType> selectedTypes;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final selectedLabels = ExportDataType.values
        .where((type) => selectedTypes.contains(type))
        .map((type) => type.getLabel(context))
        .join(', ');

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: Container(
        constraints: const BoxConstraints(minHeight: 72),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: AppTheme.outline),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppTheme.mint.withValues(alpha: 0.14),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.dataset_outlined, color: AppTheme.mint),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    context.l10n.exportDataTypes,
                    style: const TextStyle(
                      color: AppTheme.textDim,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    selectedLabels,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            const Icon(Icons.keyboard_arrow_down, color: AppTheme.textSubtle),
          ],
        ),
      ),
    );
  }
}

class _DataTypesPickerSheet extends StatefulWidget {
  const _DataTypesPickerSheet({required this.selectedTypes});

  final Set<ExportDataType> selectedTypes;

  @override
  State<_DataTypesPickerSheet> createState() => _DataTypesPickerSheetState();
}

class _DataTypesPickerSheetState extends State<_DataTypesPickerSheet> {
  late Set<ExportDataType> _selectedTypes;

  @override
  void initState() {
    super.initState();
    _selectedTypes = {...widget.selectedTypes};
  }

  @override
  Widget build(BuildContext context) {
    final maxHeight = MediaQuery.sizeOf(context).height * 0.62;

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxHeight),
        child: Container(
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: AppTheme.outline),
            boxShadow: const [
              BoxShadow(
                color: Color(0x66000000),
                blurRadius: 28,
                offset: Offset(0, 12),
              ),
            ],
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 42,
                    height: 5,
                    decoration: BoxDecoration(
                      color: AppTheme.outline,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const SizedBox(width: 48),
                      Expanded(
                        child: Text(
                          context.l10n.exportDataTypes,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Flexible(
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: ExportDataType.values.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final type = ExportDataType.values[index];
                        final selected = _selectedTypes.contains(type);
                        return _DataTypeOptionTile(
                          type: type,
                          selected: selected,
                          onTap: () => _toggle(type),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () => Navigator.pop(context, _selectedTypes),
                      child: Text(context.l10n.commonSave),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _toggle(ExportDataType type) {
    setState(() {
      final next = {..._selectedTypes};
      if (next.contains(type)) {
        if (next.length > 1) next.remove(type);
      } else {
        next.add(type);
      }
      _selectedTypes = next;
    });
  }
}

class _DataTypeOptionTile extends StatelessWidget {
  const _DataTypeOptionTile({
    required this.type,
    required this.selected,
    required this.onTap,
  });

  final ExportDataType type;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: selected ? AppTheme.mint.withValues(alpha: 0.16) : null,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected ? AppTheme.mint : Colors.transparent,
          ),
        ),
        child: Row(
          children: [
            Icon(
              selected ? Icons.check_circle : Icons.circle_outlined,
              color: selected ? AppTheme.mint : AppTheme.textDim,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                type.getLabel(context),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
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
      error: (e, st) {
        AppLogger.error('Failed to load recent export history', e, st);
        return RecentHistoryErrorCard(
          message: context.l10n.exportRecentHistoryError,
          onRetry: () => ref.invalidate(exportHistoryProvider),
        );
      },
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
        title: Text(
          localizedExportDateRange(context, entry),
          style: const TextStyle(fontSize: 14),
        ),
        subtitle: Text(date, style: const TextStyle(fontSize: 12)),
        trailing: const Icon(Icons.chevron_right, size: 20),
      ),
    );
  }
}
