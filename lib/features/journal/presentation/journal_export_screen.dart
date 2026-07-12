import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../app/app_theme.dart';
import '../../../l10n/l10n_extension.dart';
import '../../../shared/utils/currency_formatter.dart';
import '../../../shared/widgets/supabase_image.dart';
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
    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.journalExportTitle),
        actions: [
          TextButton(
            onPressed: _busy ? null : _share,
            child: Text(context.l10n.journalExportPost),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(24, 6, 24, 36),
        children: [
          RepaintBoundary(
            key: _boundaryKey,
            child: _JournalPoster(recap: widget.recap),
          ),
          const SizedBox(height: 18),
          FilledButton.icon(
            onPressed: _busy ? null : _save,
            icon: _busy
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.download_outlined),
            label: Text(context.l10n.journalExportSave),
          ),
        ],
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

class _JournalPoster extends StatelessWidget {
  const _JournalPoster({required this.recap});

  final MonthlyRecap recap;

  @override
  Widget build(BuildContext context) {
    final images = recap.transactions
        .where(
          (transaction) => transaction.imagePath?.trim().isNotEmpty == true,
        )
        .take(4)
        .toList();
    final month = DateFormat.yMMMM(
      Localizations.localeOf(context).toString(),
    ).format(recap.month);
    final colors = context.moniaryColors;

    return AspectRatio(
      aspectRatio: 4 / 5,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: colors.outline),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    context.l10n.journalExportBrand.toUpperCase(),
                    style: context.moniaryTypography.metadataStrong,
                  ),
                ),
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: colors.primary.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.auto_stories_outlined,
                    color: colors.primary,
                    size: 18,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(month, style: context.moniaryTypography.displayMedium),
            const SizedBox(height: 16),
            Expanded(
              child: _ReceiptMosaic(
                images: images
                    .map((transaction) => transaction.imagePath)
                    .toList(),
                count: recap.expenseCount,
              ),
            ),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colors.background,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: colors.textPrimary.withValues(alpha: 0.10),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: _PosterMetric(
                      value: recap.expenseCount.toString(),
                      label: context.l10n.transactionCount(recap.expenseCount),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    flex: 2,
                    child: _PosterMetric(
                      value: formatVnd(recap.totalExpense),
                      label: context.l10n.statsTotalExpense,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _PosterPill(label: context.l10n.journalExportWholeMonth),
                _PosterPill(label: context.l10n.journalExportToday),
                _PosterPill(label: context.l10n.journalExportCustomRange),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ReceiptMosaic extends StatelessWidget {
  const _ReceiptMosaic({required this.images, required this.count});

  final List<String?> images;
  final int count;

  @override
  Widget build(BuildContext context) {
    final colors = context.moniaryColors;
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height = constraints.maxHeight;
        final largeWidth = width * 0.62;
        final smallWidth = width * 0.34;

        return Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              left: 0,
              top: 0,
              width: largeWidth,
              height: height * 0.84,
              child: _ReceiptImage(
                imagePath: images.isNotEmpty ? images[0] : null,
                color: AppTheme.sand,
              ),
            ),
            Positioned(
              right: 0,
              top: height * 0.08,
              width: smallWidth,
              height: height * 0.42,
              child: _ReceiptImage(
                imagePath: images.length > 1 ? images[1] : null,
                color: AppTheme.sage,
              ),
            ),
            Positioned(
              right: width * 0.09,
              bottom: 0,
              width: smallWidth,
              height: height * 0.42,
              child: _ReceiptImage(
                imagePath: images.length > 2 ? images[2] : null,
                color: AppTheme.dustyRose,
              ),
            ),
            Positioned(
              left: width * 0.43,
              bottom: height * 0.08,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: colors.surface,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: colors.outline),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.18),
                      blurRadius: 18,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Text(
                  '+$count',
                  style: context.moniaryTypography.metadataStrong,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _ReceiptImage extends StatelessWidget {
  const _ReceiptImage({required this.imagePath, required this.color});

  final String? imagePath;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.24),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: context.moniaryColors.textPrimary.withValues(alpha: 0.10),
        ),
      ),
      child: SupabaseImage(
        imagePath: imagePath,
        borderRadius: BorderRadius.circular(18),
        fallbackIcon: Icons.receipt_long_outlined,
      ),
    );
  }
}

class _PosterMetric extends StatelessWidget {
  const _PosterMetric({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(value, style: context.moniaryTypography.displaySmall),
        const SizedBox(height: 4),
        Text(label.toUpperCase(), style: context.moniaryTypography.metadata),
      ],
    );
  }
}

class _PosterPill extends StatelessWidget {
  const _PosterPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = context.moniaryColors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: colors.outline),
      ),
      child: Text(label, style: context.moniaryTypography.metadataStrong),
    );
  }
}
