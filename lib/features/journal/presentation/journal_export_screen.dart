import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../app/app_theme.dart';
import '../../../l10n/l10n_extension.dart';
import '../../../shared/utils/currency_formatting_ref.dart';
import '../../../shared/utils/app_logger.dart';
import '../../../shared/widgets/supabase_image.dart';
import '../../transactions/domain/models/transaction_entry.dart';
import '../../transactions/presentation/utils/transaction_image_source.dart';
import '../domain/journal_models.dart';

const _fileActionsChannel = MethodChannel('moniary/file_actions');

class JournalExportScreen extends StatefulWidget {
  const JournalExportScreen({required this.recap, super.key});

  static const routePath = '/journal/export';

  final MonthlyRecap recap;

  @override
  State<JournalExportScreen> createState() => _JournalExportScreenState();
}

class _JournalExportScreenState extends State<JournalExportScreen> {
  final _boundaryKey = GlobalKey();
  bool _busy = false;
  _JournalExportRangeMode _mode = _JournalExportRangeMode.wholeMonth;
  DateTimeRange? _customRange;

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: _exportBackground,
        body: SafeArea(
          child: Column(
            children: [
              _ExportTopBar(
                busy: _busy,
                onClose: () => Navigator.of(context).maybePop(),
                onPost: _share,
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(36, 58, 36, 22),
                  child: Column(
                    children: [
                      Center(
                        child: SizedBox(
                          width: 325,
                          child: RepaintBoundary(
                            key: _boundaryKey,
                            child: _JournalPoster(
                              recap: widget.recap,
                              range: _activeRange,
                              mode: _mode,
                            ),
                          ),
                        ),
                      ),
                      const Spacer(),
                      _ExportRangePills(
                        mode: _mode,
                        onWholeMonth: () =>
                            _setMode(_JournalExportRangeMode.wholeMonth),
                        onToday: () => _setMode(_JournalExportRangeMode.today),
                        onCustomRange: _pickCustomRange,
                      ),
                      const SizedBox(height: 14),
                      _SaveButton(busy: _busy, onPressed: _save),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<File?> _renderToFile({required bool permanent}) async {
    setState(() => _busy = true);
    try {
      await WidgetsBinding.instance.endOfFrame;
      final boundary =
          _boundaryKey.currentContext?.findRenderObject()
              as RenderRepaintBoundary?;
      if (boundary == null) return null;
      final image = await boundary.toImage(pixelRatio: 3);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      if (bytes == null) return null;
      final directory = permanent
          ? await getApplicationDocumentsDirectory()
          : await getTemporaryDirectory();
      final file = File(
        '${directory.path}/moniary-journal-${widget.recap.month.year}-${widget.recap.month.month}.png',
      );
      await file.writeAsBytes(bytes.buffer.asUint8List());
      return file;
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _share() async {
    final file = await _renderToFile(permanent: false);
    if (file == null || !mounted) return;
    await Share.shareXFiles([
      XFile(file.path),
    ], text: context.l10n.journalShareRecap);
  }

  Future<void> _save() async {
    final file = await _renderToFile(permanent: true);
    if (file == null || !mounted) return;
    try {
      await _fileActionsChannel.invokeMethod<bool>('saveImageToGallery', {
        'fileName': file.uri.pathSegments.last,
        'bytes': await file.readAsBytes(),
      });
    } catch (error, stackTrace) {
      AppLogger.error(
        'Failed to save Money Story image locally',
        error,
        stackTrace,
      );
    }
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(context.l10n.journalExportSaved)));
  }

  DateTimeRange get _activeRange {
    final monthStart = DateTime(
      widget.recap.month.year,
      widget.recap.month.month,
    );
    final monthEnd = DateTime(
      widget.recap.month.year,
      widget.recap.month.month + 1,
    ).subtract(const Duration(days: 1));
    return switch (_mode) {
      _JournalExportRangeMode.wholeMonth => DateTimeRange(
        start: monthStart,
        end: monthEnd,
      ),
      _JournalExportRangeMode.today => DateTimeRange(
        start: _dayOnly(DateTime.now()),
        end: _dayOnly(DateTime.now()),
      ),
      _JournalExportRangeMode.custom =>
        _customRange ?? DateTimeRange(start: monthStart, end: monthEnd),
    };
  }

  void _setMode(_JournalExportRangeMode mode) {
    if (_mode == mode) return;
    setState(() => _mode = mode);
  }

  Future<void> _pickCustomRange() async {
    final monthStart = DateTime(
      widget.recap.month.year,
      widget.recap.month.month,
    );
    final monthEnd = DateTime(
      widget.recap.month.year,
      widget.recap.month.month + 1,
    ).subtract(const Duration(days: 1));
    final picked = await showDateRangePicker(
      context: context,
      firstDate: monthStart,
      lastDate: monthEnd,
      initialDateRange:
          _customRange ?? DateTimeRange(start: monthStart, end: monthEnd),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: _exportAccent,
              onPrimary: _posterInk,
              surface: _posterSurface,
              onSurface: _posterInk,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked == null || !mounted) return;
    setState(() {
      _customRange = DateTimeRange(
        start: _dayOnly(picked.start),
        end: _dayOnly(picked.end),
      );
      _mode = _JournalExportRangeMode.custom;
    });
  }
}

enum _JournalExportRangeMode { wholeMonth, today, custom }

const _exportBackground = Color(0xFF1F1A14);
const _posterSurface = Color(0xFFF4EEE4);
const _posterInk = Color(0xFF2A2119);
const _posterMuted = Color(0xFF8D8176);
const _posterLine = Color(0xFFE3DACD);
const _exportAccent = Color(0xFFE4AD72);

class _ExportTopBar extends StatelessWidget {
  const _ExportTopBar({
    required this.busy,
    required this.onClose,
    required this.onPost,
  });

  final bool busy;
  final VoidCallback onClose;
  final VoidCallback onPost;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: IconButton(
              onPressed: busy ? null : onClose,
              tooltip: MaterialLocalizations.of(context).backButtonTooltip,
              icon: const Icon(Icons.arrow_back_ios_new_rounded),
              color: _posterSurface,
              iconSize: 22,
            ),
          ),
          Text(
            context.l10n.journalExportTitle,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: _posterSurface,
              fontWeight: FontWeight.w900,
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: Padding(
              padding: const EdgeInsets.only(right: 14),
              child: TextButton(
                onPressed: busy ? null : onPost,
                style: TextButton.styleFrom(
                  foregroundColor: _exportAccent,
                  textStyle: Theme.of(
                    context,
                  ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w900),
                ),
                child: Text(context.l10n.journalExportPost),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _JournalPoster extends StatelessWidget {
  const _JournalPoster({
    required this.recap,
    required this.range,
    required this.mode,
  });

  final MonthlyRecap recap;
  final DateTimeRange range;
  final _JournalExportRangeMode mode;

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).toString();
    final transactions = _transactionsInRange(recap.transactions, range);
    final expenses = transactions.where((transaction) => transaction.isExpense);
    final expenseCount = expenses.length;
    final totalExpense = expenses.fold<double>(
      0,
      (sum, transaction) => sum + transaction.amount,
    );

    return AspectRatio(
      aspectRatio: 0.62,
      child: Container(
        padding: const EdgeInsets.fromLTRB(22, 22, 22, 19),
        decoration: BoxDecoration(
          color: _posterSurface,
          borderRadius: BorderRadius.circular(22),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              context.l10n.journalExportBrand.toUpperCase(),
              textAlign: TextAlign.center,
              style: context.moniaryTypography.metadataStrong.copyWith(
                color: const Color(0xFFC56A4B),
                fontSize: 8,
                letterSpacing: 4,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              _rangeTitle(locale),
              textAlign: TextAlign.center,
              style: context.moniaryTypography.displaySmall.copyWith(
                color: _posterInk,
                fontSize: 25,
                height: 1.04,
              ),
            ),
            const SizedBox(height: 20),
            Expanded(child: _PosterMosaic(transactions: transactions)),
            const SizedBox(height: 17),
            const Divider(color: _posterLine, height: 1),
            const SizedBox(height: 12),
            _PosterMetrics(
              transactionCount: expenseCount,
              totalExpense: totalExpense,
            ),
          ],
        ),
      ),
    );
  }

  String _rangeTitle(String locale) {
    if (mode == _JournalExportRangeMode.wholeMonth) {
      return DateFormat.yMMMM(locale).format(recap.month);
    }
    if (_isSameDay(range.start, range.end)) {
      return DateFormat.yMMMMd(locale).format(range.start);
    }
    final sameMonth =
        range.start.year == range.end.year &&
        range.start.month == range.end.month;
    if (sameMonth) {
      return '${DateFormat.d(locale).format(range.start)}-${DateFormat.yMMMMd(locale).format(range.end)}';
    }
    return '${DateFormat.yMMMd(locale).format(range.start)} - ${DateFormat.yMMMd(locale).format(range.end)}';
  }
}

class _PosterMosaic extends StatelessWidget {
  const _PosterMosaic({required this.transactions});

  final List<TransactionEntry> transactions;

  @override
  Widget build(BuildContext context) {
    final visibleCount = 15;
    final expenses = transactions.where((item) => item.isExpense).toList()
      ..sort((a, b) => b.transactionDate.compareTo(a.transactionDate));
    final overflow = (expenses.length - visibleCount).clamp(0, 999);
    final visible = expenses.take(16).toList(growable: false);

    if (visible.isEmpty) {
      return Center(
        child: Text(
          context.l10n.journalExportNoTransactions,
          textAlign: TextAlign.center,
          style: context.moniaryTypography.metadataStrong.copyWith(
            color: _posterMuted,
            fontSize: 9,
            letterSpacing: 1.4,
          ),
        ),
      );
    }

    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      itemCount: visible.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        crossAxisSpacing: 4,
        mainAxisSpacing: 4,
      ),
      itemBuilder: (context, index) {
        final isOverflowCell = index == 15 && overflow > 0;
        final transaction = visible[index];
        return ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: Stack(
            fit: StackFit.expand,
            children: [
              SupabaseImage(
                imagePath: transactionImagePathForDisplay(transaction),
                fit: BoxFit.cover,
                fallbackBuilder: (context) =>
                    _PosterImageFallback(transaction: transaction),
              ),
              if (isOverflowCell)
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.36),
                  ),
                ),
              if (isOverflowCell)
                Center(
                  child: Text(
                    '+$overflow',
                    style: context.moniaryTypography.metadataStrong.copyWith(
                      color: _posterSurface,
                      fontSize: 9,
                      letterSpacing: 0,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _PosterMetrics extends ConsumerWidget {
  const _PosterMetrics({
    required this.transactionCount,
    required this.totalExpense,
  });

  final int transactionCount;
  final double totalExpense;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: _PosterMetric(
            value: transactionCount.toString(),
            label: context.l10n.transactionCount(transactionCount),
          ),
        ),
        Expanded(
          child: _PosterMetric(
            value: ref.formatAmount(totalExpense),
            label: context.l10n.statsTotalExpense,
            alignEnd: true,
            accentValue: true,
          ),
        ),
      ],
    );
  }
}

class _PosterMetric extends StatelessWidget {
  const _PosterMetric({
    required this.value,
    required this.label,
    this.alignEnd = false,
    this.accentValue = false,
  });

  final String value;
  final String label;
  final bool alignEnd;
  final bool accentValue;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: alignEnd
          ? CrossAxisAlignment.end
          : CrossAxisAlignment.start,
      children: [
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: context.moniaryTypography.displaySmall.copyWith(
            color: accentValue ? const Color(0xFFD96D4D) : _posterInk,
            fontSize: 15,
            height: 1,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label.toUpperCase(),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: context.moniaryTypography.metadata.copyWith(
            color: _posterMuted,
            fontSize: 7,
            letterSpacing: 2.3,
          ),
        ),
      ],
    );
  }
}

class _ExportRangePills extends StatelessWidget {
  const _ExportRangePills({
    required this.mode,
    required this.onWholeMonth,
    required this.onToday,
    required this.onCustomRange,
  });

  final _JournalExportRangeMode mode;
  final VoidCallback onWholeMonth;
  final VoidCallback onToday;
  final VoidCallback onCustomRange;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _ExportPill(
          label: context.l10n.journalExportWholeMonth,
          selected: mode == _JournalExportRangeMode.wholeMonth,
          onTap: onWholeMonth,
        ),
        const SizedBox(width: 8),
        _ExportPill(
          label: context.l10n.journalExportToday,
          selected: mode == _JournalExportRangeMode.today,
          onTap: onToday,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _ExportPill(
            label: context.l10n.journalExportCustomRange,
            selected: mode == _JournalExportRangeMode.custom,
            onTap: onCustomRange,
          ),
        ),
      ],
    );
  }
}

class _ExportPill extends StatelessWidget {
  const _ExportPill({
    required this.label,
    required this.onTap,
    this.selected = false,
  });

  final String label;
  final VoidCallback onTap;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? _posterSurface : Colors.transparent,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          height: 34,
          padding: const EdgeInsets.symmetric(horizontal: 15),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: selected
                  ? _posterSurface
                  : _posterSurface.withValues(alpha: 0.28),
            ),
          ),
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: selected
                  ? _posterInk
                  : _posterSurface.withValues(alpha: 0.72),
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }
}

class _SaveButton extends StatelessWidget {
  const _SaveButton({required this.busy, required this.onPressed});

  final bool busy;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: FilledButton.icon(
        onPressed: busy ? null : onPressed,
        icon: busy
            ? const SizedBox.square(
                dimension: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.file_download_outlined, size: 18),
        label: Text(context.l10n.journalExportSave),
        style: FilledButton.styleFrom(
          backgroundColor: _exportAccent,
          foregroundColor: _posterInk,
          disabledBackgroundColor: _exportAccent.withValues(alpha: 0.54),
          disabledForegroundColor: _posterInk.withValues(alpha: 0.54),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(999),
          ),
          textStyle: Theme.of(
            context,
          ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900),
        ),
      ),
    );
  }
}

class _PosterImageFallback extends StatelessWidget {
  const _PosterImageFallback({required this.transaction});

  final TransactionEntry transaction;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _categoryColor(transaction.categoryColor).withValues(alpha: 0.3),
      alignment: Alignment.center,
      child: Icon(
        transaction.isIncome
            ? Icons.savings_outlined
            : Icons.receipt_long_outlined,
        size: 17,
        color: _posterMuted,
      ),
    );
  }
}

List<TransactionEntry> _transactionsInRange(
  List<TransactionEntry> transactions,
  DateTimeRange range,
) {
  final start = _dayOnly(range.start);
  final endExclusive = _dayOnly(range.end).add(const Duration(days: 1));
  return transactions
      .where(
        (transaction) =>
            !transaction.transactionDate.isBefore(start) &&
            transaction.transactionDate.isBefore(endExclusive),
      )
      .toList(growable: false);
}

DateTime _dayOnly(DateTime value) {
  return DateTime(value.year, value.month, value.day);
}

bool _isSameDay(DateTime left, DateTime right) {
  return left.year == right.year &&
      left.month == right.month &&
      left.day == right.day;
}

Color _categoryColor(String? hex) {
  final value = hex?.replaceFirst('#', '');
  if (value == null || value.length != 6) return _posterLine;
  final parsed = int.tryParse('FF$value', radix: 16);
  return parsed == null ? _posterLine : Color(parsed);
}
