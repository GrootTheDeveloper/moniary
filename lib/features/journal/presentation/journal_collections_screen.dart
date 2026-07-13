import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../app/app_theme.dart';
import '../../../l10n/l10n_extension.dart';
import '../../../shared/utils/currency_formatting_ref.dart';
import '../../../shared/utils/error_helpers.dart';
import '../../../shared/widgets/supabase_image.dart';
import '../../transactions/presentation/utils/transaction_image_source.dart';
import '../application/journal_controller.dart';
import '../domain/journal_models.dart';
import 'journal_collection_detail_screen.dart';

class JournalCollectionsScreen extends ConsumerWidget {
  const JournalCollectionsScreen({super.key});

  static const routePath = '/journal/collections';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final collectionsAsync = ref.watch(journalCollectionsProvider);
    final colors = context.moniaryColors;
    return Scaffold(
      backgroundColor: colors.backgroundSoft,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 393),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(28, 18, 28, 18),
                  child: _CollectionsHeader(
                    onBack: () => Navigator.of(context).maybePop(),
                    onCreate: () => _createCollection(context, ref),
                  ),
                ),
                Expanded(
                  child: collectionsAsync.when(
                    loading: () => const _CollectionsLoading(),
                    error: (error, _) => _CollectionsError(
                      message: userFriendlyMessage(context, error),
                      onRetry: () => ref.invalidate(journalCollectionsProvider),
                    ),
                    data: (collections) => RefreshIndicator(
                      color: colors.primary,
                      backgroundColor: colors.backgroundSoft,
                      onRefresh: () async =>
                          ref.invalidate(journalCollectionsProvider),
                      child: ListView.separated(
                        padding: const EdgeInsets.fromLTRB(28, 4, 28, 40),
                        itemCount: collections.length + 1,
                        separatorBuilder: (_, _) => const SizedBox(height: 14),
                        itemBuilder: (context, index) {
                          if (index == collections.length) {
                            return _CreateCollectionTile(
                              compact: collections.isEmpty,
                              onCreate: () => _createCollection(context, ref),
                            );
                          }
                          final collection = collections[index];
                          return _CollectionCard(
                            collection: collection,
                            onTap: () => context.push(
                              JournalCollectionDetailScreen.routePath,
                              extra: collection.id,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _createCollection(BuildContext context, WidgetRef ref) async {
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.l10n.journalCreateCollection),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(
            labelText: context.l10n.journalCollectionName,
            hintText: context.l10n.journalCollectionNameHint,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(context.l10n.commonCancel),
          ),
          FilledButton(
            onPressed: () {
              final value = controller.text.trim();
              if (value.isNotEmpty) Navigator.pop(context, value);
            },
            child: Text(context.l10n.commonCreate),
          ),
        ],
      ),
    );
    controller.dispose();
    if (name == null || !context.mounted) return;
    try {
      final id = await ref
          .read(journalActionControllerProvider.notifier)
          .createCollection(name: name);
      if (context.mounted) {
        await context.push(JournalCollectionDetailScreen.routePath, extra: id);
      }
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(userFriendlyMessage(context, error))),
      );
    }
  }
}

class _CollectionsHeader extends StatelessWidget {
  const _CollectionsHeader({required this.onBack, required this.onCreate});

  final VoidCallback onBack;
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    final colors = context.moniaryColors;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          button: true,
          label: MaterialLocalizations.of(context).backButtonTooltip,
          child: Material(
            color: colors.surface.withValues(alpha: 0.58),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
              side: BorderSide(color: colors.outline.withValues(alpha: 0.78)),
            ),
            child: InkWell(
              onTap: onBack,
              borderRadius: BorderRadius.circular(10),
              child: SizedBox(
                width: 36,
                height: 36,
                child: Icon(
                  Icons.chevron_left_rounded,
                  size: 25,
                  color: colors.textPrimary.withValues(alpha: 0.64),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'MONIARY',
                style: context.moniaryTypography.metadataStrong.copyWith(
                  color: colors.primary,
                  letterSpacing: 3.2,
                  fontSize: 9,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                context.l10n.journalCollectionsTitle,
                style: context.moniaryTypography.displaySmall.copyWith(
                  fontSize: 24,
                  height: 1,
                  letterSpacing: 0,
                  color: colors.textPrimary,
                ),
              ),
            ],
          ),
        ),
        Semantics(
          button: true,
          label: context.l10n.journalCreateCollection,
          child: Material(
            color: colors.textPrimary,
            borderRadius: BorderRadius.circular(10),
            child: InkWell(
              onTap: onCreate,
              borderRadius: BorderRadius.circular(10),
              child: SizedBox(
                width: 36,
                height: 36,
                child: Icon(Icons.add, size: 20, color: colors.backgroundSoft),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _CollectionCard extends ConsumerWidget {
  const _CollectionCard({required this.collection, required this.onTap});

  final JournalCollectionSummary collection;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dateRange = _dateRange(context);
    final colors = context.moniaryColors;
    final radius = BorderRadius.circular(16);
    return Material(
      color: Colors.transparent,
      child: Ink(
        decoration: BoxDecoration(
          color: colors.surface.withValues(alpha: 0.72),
          borderRadius: radius,
          border: Border.all(color: colors.outline.withValues(alpha: 0.78)),
          boxShadow: [
            BoxShadow(
              color: colors.textPrimary.withValues(alpha: 0.035),
              blurRadius: 14,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: radius,
          child: ClipRRect(
            borderRadius: radius,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _CollectionMosaic(collection: collection),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 13, 16, 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        collection.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              color: colors.textPrimary,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              height: 1.12,
                              letterSpacing: 0,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        [
                          context.l10n.journalCollectionMeta(
                            collection.transactionCount,
                            ref.formatAmount(collection.totalExpense),
                          ),
                          ?dateRange,
                        ].join(' · '),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: context.moniaryTypography.metadata.copyWith(
                          color: colors.textDim,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.45,
                          height: 1,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String? _dateRange(BuildContext context) {
    final start = collection.startDate;
    final end = collection.endDate;
    if (start == null && end == null) return null;
    final locale = Localizations.localeOf(context).toString();
    if (start != null && end != null) {
      if (_sameDate(start, end)) {
        if (locale.startsWith('vi')) return '${start.day} TH${start.month}';
        return DateFormat.MMMd(locale).format(start).toUpperCase();
      }
      if (start.year == end.year && start.month == end.month) {
        if (locale.startsWith('vi')) {
          return '${start.day}–${end.day} TH${end.month}';
        }
        return '${DateFormat.MMM(locale).format(end).toUpperCase()} '
            '${start.day}–${end.day}';
      }
      return '${DateFormat.MMMd(locale).format(start)}–'
          '${DateFormat.MMMd(locale).format(end)}';
    }
    final value = start ?? end!;
    if (locale.startsWith('vi')) return '${value.day} TH${value.month}';
    return DateFormat.MMMd(locale).format(value).toUpperCase();
  }

  bool _sameDate(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}

class _CollectionMosaic extends StatelessWidget {
  const _CollectionMosaic({required this.collection});

  final JournalCollectionSummary collection;

  @override
  Widget build(BuildContext context) {
    final colors = context.moniaryColors;
    final palette = _paletteFor(collection);
    final transactions = collection.transactions.take(4).toList();
    final overflow = collection.transactions.length - 4;

    return SizedBox(
      height: 78,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: List.generate(4, (index) {
          final transaction = index < transactions.length
              ? transactions[index]
              : null;
          final color = palette[index];
          return Expanded(
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (transaction == null)
                  ColoredBox(color: color)
                else
                  SupabaseImage(
                    imagePath: transactionImagePathForDisplay(transaction),
                    fit: BoxFit.cover,
                    fallbackBuilder: (context) => ColoredBox(color: color),
                  ),
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.22),
                    border: Border(
                      right: index == 3
                          ? BorderSide.none
                          : BorderSide(
                              color: colors.backgroundSoft.withValues(
                                alpha: 0.82,
                              ),
                              width: 1.2,
                            ),
                    ),
                  ),
                ),
                if (index == 3 && overflow > 0)
                  Center(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: colors.textPrimary.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 4,
                        ),
                        child: Text(
                          '+$overflow',
                          style: context.moniaryTypography.metadataStrong
                              .copyWith(
                                color: AppTheme.surfaceRaised,
                                fontSize: 11,
                                letterSpacing: 0,
                                shadows: [
                                  Shadow(
                                    color: colors.textPrimary.withValues(
                                      alpha: 0.3,
                                    ),
                                    blurRadius: 4,
                                  ),
                                ],
                              ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          );
        }),
      ),
    );
  }

  List<Color> _paletteFor(JournalCollectionSummary collection) {
    final lowerName = collection.name.toLowerCase();
    if (collection.id.contains('birthday') || lowerName.contains('sinh nhật')) {
      return const [
        Color(0xFFB58F93),
        Color(0xFF9F91A8),
        Color(0xFF78918B),
        Color(0xFFB7A89B),
      ];
    }

    return const [
      Color(0xFF8796A8),
      Color(0xFF91A092),
      Color(0xFFAD918C),
      Color(0xFFC2A98C),
    ];
  }
}

class _CreateCollectionTile extends StatelessWidget {
  const _CreateCollectionTile({required this.onCreate, this.compact = false});

  final VoidCallback onCreate;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final colors = context.moniaryColors;
    return Semantics(
      button: true,
      label: context.l10n.journalCreateCollection,
      child: CustomPaint(
        painter: _DashedRoundRectPainter(
          color: colors.outline.withValues(alpha: 0.92),
          radius: 15,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onCreate,
            borderRadius: BorderRadius.circular(15),
            child: SizedBox(
              height: compact ? 124 : 90,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add, size: 24, color: colors.textDim),
                  const SizedBox(height: 10),
                  Text(
                    context.l10n.journalCreateCollection,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: colors.textDim,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0,
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
}

class _CollectionsLoading extends StatelessWidget {
  const _CollectionsLoading();

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(28, 4, 28, 40),
      itemBuilder: (context, index) => const _CollectionSkeleton(),
      separatorBuilder: (_, _) => const SizedBox(height: 14),
      itemCount: 2,
    );
  }
}

class _CollectionSkeleton extends StatelessWidget {
  const _CollectionSkeleton();

  @override
  Widget build(BuildContext context) {
    final colors = context.moniaryColors;
    return Container(
      height: 142,
      decoration: BoxDecoration(
        color: colors.surface.withValues(alpha: 0.56),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.outline.withValues(alpha: 0.6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 78,
            decoration: BoxDecoration(
              color: colors.textPrimary.withValues(alpha: 0.08),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(15),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: Column(
              children: [
                _SkeletonLine(width: 140, height: 13),
                const SizedBox(height: 10),
                _SkeletonLine(width: 210, height: 8),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CollectionsError extends StatelessWidget {
  const _CollectionsError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final colors = context.moniaryColors;
    return ListView(
      padding: const EdgeInsets.fromLTRB(28, 4, 28, 40),
      children: [
        CustomPaint(
          painter: _DashedRoundRectPainter(
            color: colors.outline.withValues(alpha: 0.9),
            radius: 15,
          ),
          child: Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
              children: [
                Icon(Icons.refresh_rounded, color: colors.primary, size: 26),
                const SizedBox(height: 12),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: colors.textSecondary),
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: onRetry,
                  child: Text(context.l10n.commonRetry),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _SkeletonLine extends StatelessWidget {
  const _SkeletonLine({required this.width, required this.height});

  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: context.moniaryColors.textPrimary.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(height),
        ),
      ),
    );
  }
}

class _DashedRoundRectPainter extends CustomPainter {
  const _DashedRoundRectPainter({required this.color, required this.radius});

  final Color color;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;
    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(Offset.zero & size, Radius.circular(radius)),
      );
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final next = distance + 7;
        canvas.drawPath(metric.extractPath(distance, next), paint);
        distance = next + 5;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedRoundRectPainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.radius != radius;
  }
}
