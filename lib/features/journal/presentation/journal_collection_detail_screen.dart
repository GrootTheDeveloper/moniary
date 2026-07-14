import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../app/app_theme.dart';
import '../../../l10n/l10n_extension.dart';
import '../../../shared/utils/currency_formatting_ref.dart';
import '../../../shared/utils/error_helpers.dart';
import '../../../shared/widgets/moniary_design.dart';
import '../../../shared/widgets/supabase_image.dart';
import '../../statistics/presentation/statistics_view.dart';
import '../../transactions/domain/models/transaction_entry.dart';
import '../../transactions/presentation/utils/transaction_image_source.dart';
import '../application/journal_controller.dart';
import '../domain/journal_models.dart';

class JournalCollectionDetailScreen extends ConsumerWidget {
  const JournalCollectionDetailScreen({required this.collectionId, super.key});

  static const routePath = '/journal/collection';

  final String collectionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final collectionAsync = ref.watch(journalCollectionProvider(collectionId));
    return Scaffold(
      backgroundColor: context.moniaryColors.backgroundSoft,
      body: collectionAsync.when(
        loading: () => const _CollectionDetailLoading(),
        error: (error, _) => _CollectionDetailError(
          message: userFriendlyMessage(context, error),
          onRetry: () =>
              ref.invalidate(journalCollectionProvider(collectionId)),
        ),
        data: (collection) => _CollectionDetailContent(
          collection: collection,
          onBack: () => Navigator.of(context).maybePop(),
          onAdd: () => _chooseTransaction(context, ref, collection),
        ),
      ),
    );
  }

  Future<void> _chooseTransaction(
    BuildContext context,
    WidgetRef ref,
    JournalCollectionSummary collection,
  ) async {
    final now = DateTime.now();
    final month = DateTime(now.year, now.month);
    final transactions = await ref.read(statisticsMonthProvider(month).future);
    final existingIds = collection.transactions
        .map((transaction) => transaction.id)
        .toSet();
    final choices = transactions
        .where((transaction) => !existingIds.contains(transaction.id))
        .toList();
    if (!context.mounted) return;
    final selected = await showModalBottomSheet<TransactionEntry>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.72,
        maxChildSize: 0.92,
        builder: (context, controller) => Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Text(
                context.l10n.journalChooseTransaction,
                style: context.moniaryTypography.displayMedium,
              ),
            ),
            Expanded(
              child: ListView.builder(
                controller: controller,
                padding: const EdgeInsets.symmetric(horizontal: 24),
                itemCount: choices.length,
                itemBuilder: (context, index) {
                  final transaction = choices[index];
                  return MoniaryHairlineTile(
                    showTopDivider: index == 0,
                    onTap: () => Navigator.pop(context, transaction),
                    title: Text(
                      transaction.note?.trim().isNotEmpty == true
                          ? transaction.note!.trim()
                          : transaction.categoryName,
                    ),
                    subtitle: Text(
                      DateFormat.yMMMd(
                        Localizations.localeOf(context).toString(),
                      ).format(transaction.transactionDate),
                    ),
                    trailing: Text(ref.formatAmount(transaction.amount)),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
    if (selected == null || !context.mounted) return;
    try {
      await ref
          .read(journalActionControllerProvider.notifier)
          .addTransaction(
            collectionId: collectionId,
            transactionId: selected.id,
          );
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(userFriendlyMessage(context, error))),
      );
    }
  }
}

class _CollectionDetailContent extends StatelessWidget {
  const _CollectionDetailContent({
    required this.collection,
    required this.onBack,
    required this.onAdd,
  });

  final JournalCollectionSummary collection;
  final VoidCallback onBack;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final displayTransactions =
        ([...collection.transactions]..sort((a, b) {
              if (a.isExpense != b.isExpense) return a.isExpense ? -1 : 1;
              return b.transactionDate.compareTo(a.transactionDate);
            }))
            .take(6)
            .toList();

    return SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 393),
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(28, 18, 28, 0),
                  child: _CollectionTopBar(
                    collection: collection,
                    onBack: onBack,
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(28, 10, 28, 20),
                  child: _CollectionHero(collection: collection),
                ),
              ),
              if (displayTransactions.isEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(28, 0, 28, 12),
                    child: _CollectionEmptyState(onAdd: onAdd),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  sliver: SliverGrid.builder(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          crossAxisSpacing: 6,
                          mainAxisSpacing: 6,
                          childAspectRatio: 1,
                        ),
                    itemCount: displayTransactions.length,
                    itemBuilder: (context, index) => _TransactionImageBlock(
                      transaction: displayTransactions[index],
                      paletteIndex: index,
                    ),
                  ),
                ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(28, 18, 28, 44),
                  child: _AddTransactionTile(onAdd: onAdd),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CollectionTopBar extends StatelessWidget {
  const _CollectionTopBar({required this.collection, required this.onBack});

  final JournalCollectionSummary collection;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final colors = context.moniaryColors;
    return SizedBox(
      height: 42,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Material(
              color: colors.surface.withValues(alpha: 0.58),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
                side: BorderSide(color: colors.outline.withValues(alpha: 0.8)),
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
          Text(
            collection.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: context.moniaryTypography.displaySmall.copyWith(
              fontSize: 16,
              height: 1,
              letterSpacing: 0,
              color: colors.textPrimary,
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: Icon(
              Icons.link_rounded,
              size: 18,
              color: colors.textSecondary.withValues(alpha: 0.68),
            ),
          ),
        ],
      ),
    );
  }
}

class _CollectionHero extends ConsumerWidget {
  const _CollectionHero({required this.collection});

  final JournalCollectionSummary collection;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.moniaryColors;
    return Column(
      children: [
        Text(
          [
            ?_dateRange(context),
            context.l10n
                .journalCollectionMeta(collection.transactionCount, '')
                .split('·')
                .first
                .trim(),
          ].join(' · ').toUpperCase(),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: context.moniaryTypography.metadata.copyWith(
            color: colors.textDim,
            fontSize: 10,
            fontWeight: FontWeight.w600,
            letterSpacing: 2.6,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          ref.formatAmount(collection.totalExpense),
          textAlign: TextAlign.center,
          style: context.moniaryTypography.displayMedium.copyWith(
            color: colors.textPrimary,
            fontSize: 31,
            height: 1,
            letterSpacing: 0,
          ),
        ),
      ],
    );
  }

  String? _dateRange(BuildContext context) {
    final start = collection.startDate;
    final end = collection.endDate;
    if (start == null && end == null) return null;
    final locale = Localizations.localeOf(context).toString();
    if (start != null && end != null) {
      if (_sameDate(start, end)) {
        if (locale.startsWith('vi')) return '${start.day} tháng ${start.month}';
        return DateFormat.MMMd(locale).format(start);
      }
      if (start.year == end.year && start.month == end.month) {
        if (locale.startsWith('vi')) {
          return '${start.day} - ${end.day} tháng ${end.month}';
        }
        return '${DateFormat.MMM(locale).format(end)} ${start.day}-${end.day}';
      }
      return '${DateFormat.MMMd(locale).format(start)} - '
          '${DateFormat.MMMd(locale).format(end)}';
    }
    final value = start ?? end!;
    if (locale.startsWith('vi')) return '${value.day} tháng ${value.month}';
    return DateFormat.MMMd(locale).format(value);
  }

  bool _sameDate(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}

class _TransactionImageBlock extends StatelessWidget {
  const _TransactionImageBlock({
    required this.transaction,
    required this.paletteIndex,
  });

  final TransactionEntry transaction;
  final int paletteIndex;

  @override
  Widget build(BuildContext context) {
    final colors = context.moniaryColors;
    final background = _blockColor(transaction, paletteIndex);
    final radius = BorderRadius.circular(9);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: background,
        borderRadius: radius,
        boxShadow: [
          BoxShadow(
            color: colors.textPrimary.withValues(alpha: 0.09),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Positioned.fill(
              child: SupabaseImage(
                imagePath: transactionImagePathForDisplay(transaction),
                fit: BoxFit.cover,
                fallbackBuilder: (context) => ColoredBox(color: background),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _blockColor(TransactionEntry transaction, int index) {
    const palette = [
      Color(0xFF8796A8),
      Color(0xFF91A092),
      Color(0xFFAD918C),
      Color(0xFFC2A98C),
      Color(0xFF9F91A8),
      Color(0xFF78918B),
    ];
    return palette[index % palette.length];
  }
}

class _AddTransactionTile extends StatelessWidget {
  const _AddTransactionTile({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final colors = context.moniaryColors;
    return Semantics(
      button: true,
      label: context.l10n.journalAddTransaction,
      child: CustomPaint(
        painter: _DashedRoundRectPainter(
          color: colors.outline.withValues(alpha: 0.92),
          radius: 15,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onAdd,
            borderRadius: BorderRadius.circular(15),
            child: SizedBox(
              height: 46,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add, size: 18, color: colors.textDim),
                  const SizedBox(width: 8),
                  Text(
                    context.l10n.journalAddTransaction,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: colors.textDim,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
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

class _CollectionEmptyState extends StatelessWidget {
  const _CollectionEmptyState({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 18),
        Text(
          context.l10n.journalCollectionNoTransactions,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: context.moniaryColors.textSecondary,
          ),
        ),
        const SizedBox(height: 18),
        _AddTransactionTile(onAdd: onAdd),
      ],
    );
  }
}

class _CollectionDetailLoading extends StatelessWidget {
  const _CollectionDetailLoading();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Center(
        child: SizedBox(
          width: 22,
          height: 22,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: context.moniaryColors.primary,
          ),
        ),
      ),
    );
  }
}

class _CollectionDetailError extends StatelessWidget {
  const _CollectionDetailError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final colors = context.moniaryColors;
    return SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
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
