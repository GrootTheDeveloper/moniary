import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../app/app_theme.dart';
import '../../../l10n/l10n_extension.dart';
import '../../../shared/utils/currency_formatter.dart';
import '../domain/journal_models.dart';

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
                            child: _JournalPoster(recap: widget.recap),
                          ),
                        ),
                      ),
                      const Spacer(),
                      _ExportRangePills(),
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
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(context.l10n.journalExportSaved)));
  }
}

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
              tooltip: context.l10n.commonClose,
              icon: const Icon(Icons.close_rounded),
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
  const _JournalPoster({required this.recap});

  final MonthlyRecap recap;

  @override
  Widget build(BuildContext context) {
    final month = DateFormat.yMMMM(
      Localizations.localeOf(context).toString(),
    ).format(recap.month);

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
              month,
              textAlign: TextAlign.center,
              style: context.moniaryTypography.displaySmall.copyWith(
                color: _posterInk,
                fontSize: 25,
                height: 1.04,
              ),
            ),
            const SizedBox(height: 20),
            Expanded(child: _PosterMosaic(recap: recap)),
            const SizedBox(height: 17),
            const Divider(color: _posterLine, height: 1),
            const SizedBox(height: 12),
            _PosterMetrics(recap: recap),
          ],
        ),
      ),
    );
  }
}

class _PosterMosaic extends StatelessWidget {
  const _PosterMosaic({required this.recap});

  final MonthlyRecap recap;

  @override
  Widget build(BuildContext context) {
    final palette = _posterPalette();
    final visibleCount = 15;
    final overflow = (recap.expenseCount - visibleCount).clamp(0, 999);

    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      itemCount: 16,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        crossAxisSpacing: 4,
        mainAxisSpacing: 4,
      ),
      itemBuilder: (context, index) {
        final isOverflowCell = index == 15 && overflow > 0;
        return DecoratedBox(
          decoration: BoxDecoration(
            color: isOverflowCell
                ? const Color(0xFFECE5D9)
                : palette[index % palette.length],
            borderRadius: BorderRadius.circular(6),
          ),
          child: Center(
            child: isOverflowCell
                ? Text(
                    '+$overflow',
                    style: context.moniaryTypography.metadataStrong.copyWith(
                      color: _posterMuted,
                      fontSize: 9,
                      letterSpacing: 0,
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        );
      },
    );
  }
}

class _PosterMetrics extends StatelessWidget {
  const _PosterMetrics({required this.recap});

  final MonthlyRecap recap;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: _PosterMetric(
            value: recap.expenseCount.toString(),
            label: context.l10n.transactionCount(recap.expenseCount),
          ),
        ),
        Expanded(
          child: _PosterMetric(
            value: formatVnd(recap.totalExpense),
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
  const _ExportRangePills();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _ExportPill(
          label: context.l10n.journalExportWholeMonth,
          selected: true,
        ),
        const SizedBox(width: 8),
        _ExportPill(label: context.l10n.journalExportToday),
        const SizedBox(width: 8),
        Expanded(
          child: _ExportPill(label: context.l10n.journalExportCustomRange),
        ),
      ],
    );
  }
}

class _ExportPill extends StatelessWidget {
  const _ExportPill({required this.label, this.selected = false});

  final String label;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 34,
      padding: const EdgeInsets.symmetric(horizontal: 15),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: selected ? _posterSurface : Colors.transparent,
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
          color: selected ? _posterInk : _posterSurface.withValues(alpha: 0.72),
          fontWeight: FontWeight.w800,
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

List<Color> _posterPalette() {
  return [
    const Color(0xFFB8AA9D),
    const Color(0xFF92A197),
    const Color(0xFFB18F8C),
    const Color(0xFF8998AB),
    const Color(0xFFC2A98C),
    const Color(0xFF9F91A8),
    const Color(0xFF78908B),
    const Color(0xFFB78E90),
    const Color(0xFF8A9AAE),
  ];
}
