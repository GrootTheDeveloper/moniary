import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../app/app_theme.dart';
import '../../../core/constants/app_color.dart';
import '../../../l10n/l10n_extension.dart';
import '../../../shared/utils/currency_formatter.dart';
import '../../../shared/utils/error_helpers.dart';
import '../../../shared/widgets/moniary_design.dart';
import '../../../shared/widgets/supabase_image.dart';
import '../application/journal_controller.dart';
import '../domain/journal_models.dart';
import 'journal_export_screen.dart';

class MonthlyRecapScreen extends ConsumerStatefulWidget {
  const MonthlyRecapScreen({required this.month, super.key});

  static const routePath = '/journal/recap';

  final DateTime month;

  @override
  ConsumerState<MonthlyRecapScreen> createState() => _MonthlyRecapScreenState();
}

class _MonthlyRecapScreenState extends ConsumerState<MonthlyRecapScreen> {
  final _controller = PageController();
  int _page = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final recapAsync = ref.watch(monthlyRecapProvider(widget.month));
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.journalRecapTitle)),
      body: recapAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) =>
            Center(child: Text(userFriendlyMessage(context, error))),
        data: (recap) => Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 10),
              child: Row(
                children: [
                  for (var index = 0; index < 4; index++) ...[
                    Expanded(
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 220),
                        height: 4,
                        decoration: BoxDecoration(
                          color: index <= _page
                              ? context.moniaryColors.primary
                              : context.moniaryColors.outline,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                    if (index < 3) const SizedBox(width: 6),
                  ],
                ],
              ),
            ),
            Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTapUp: (details) {
                  final width = MediaQuery.sizeOf(context).width;
                  _move(details.localPosition.dx < width / 2 ? -1 : 1);
                },
                child: PageView(
                  controller: _controller,
                  onPageChanged: (value) => setState(() => _page = value),
                  children: [
                    _OverviewSlide(recap: recap),
                    _HighlightsSlide(recap: recap),
                    _ComparisonSlide(recap: recap),
                    _TopCategoriesSlide(recap: recap),
                  ],
                ),
              ),
            ),
            if (_page == 3)
              SafeArea(
                minimum: const EdgeInsets.fromLTRB(24, 8, 24, 18),
                child: FilledButton.icon(
                  onPressed: () =>
                      context.push(JournalExportScreen.routePath, extra: recap),
                  icon: const Icon(Icons.ios_share_outlined),
                  label: Text(context.l10n.journalShareRecap),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _move(int delta) {
    final next = (_page + delta).clamp(0, 3);
    if (next == _page) return;
    _controller.animateToPage(
      next,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
    );
  }
}

class _StoryPadding extends StatelessWidget {
  const _StoryPadding({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 18, 28, 24),
      child: child,
    );
  }
}

class _OverviewSlide extends StatelessWidget {
  const _OverviewSlide({required this.recap});

  final MonthlyRecap recap;

  @override
  Widget build(BuildContext context) {
    final month = DateFormat.yMMMM(
      Localizations.localeOf(context).toString(),
    ).format(recap.month);
    final topCategory = recap.topCategories.firstOrNull?.name ?? '—';
    return _StoryPadding(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            month.toUpperCase(),
            style: context.moniaryTypography.metadataStrong.copyWith(
              color: context.moniaryColors.primary,
            ),
          ),
          const SizedBox(height: 18),
          Text(
            context.l10n.journalRecordedCount(recap.expenseCount),
            style: context.moniaryTypography.displayLarge,
          ),
          const SizedBox(height: 22),
          Text(
            formatVnd(recap.totalExpense),
            style: context.moniaryTypography.displayLarge.copyWith(
              color: context.moniaryColors.primary,
              fontSize: 52,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            context.l10n.journalRecapSummary(
              formatVnd(recap.totalExpense),
              topCategory,
            ),
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          if (recap.highestSpendDate != null) ...[
            const SizedBox(height: 34),
            MoniaryEditorialCard(
              backgroundColor: context.moniaryColors.warning.withValues(
                alpha: 0.08,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.l10n.journalHighestDay.toUpperCase(),
                    style: context.moniaryTypography.metadataStrong,
                  ),
                  const SizedBox(height: 7),
                  Text(
                    context.l10n.journalHighestDayValue(
                      DateFormat.MMMMd(
                        Localizations.localeOf(context).toString(),
                      ).format(recap.highestSpendDate!),
                      formatVnd(recap.highestDayAmount),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _HighlightsSlide extends StatelessWidget {
  const _HighlightsSlide({required this.recap});

  final MonthlyRecap recap;

  @override
  Widget build(BuildContext context) {
    final withImages = recap.transactions
        .where(
          (transaction) => transaction.imagePath?.trim().isNotEmpty == true,
        )
        .take(4)
        .toList();
    return _StoryPadding(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.l10n.journalHighestDay,
            style: context.moniaryTypography.displayMedium,
          ),
          const SizedBox(height: 18),
          Expanded(
            child: withImages.isEmpty
                ? MoniaryEditorialCard(
                    child: Center(
                      child: Icon(
                        Icons.photo_library_outlined,
                        size: 54,
                        color: context.moniaryColors.textDim,
                      ),
                    ),
                  )
                : GridView.builder(
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                        ),
                    itemCount: withImages.length,
                    itemBuilder: (context, index) {
                      final transaction = withImages[index];
                      return Transform.rotate(
                        angle: index.isEven ? -0.025 : 0.025,
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            SupabaseImage(
                              imagePath: transaction.imagePath,
                              borderRadius: BorderRadius.circular(18),
                              fallbackIcon: Icons.receipt_long_outlined,
                            ),
                            Positioned(
                              left: 10,
                              right: 10,
                              bottom: 9,
                              child: Text(
                                formatVnd(transaction.amount),
                                style: context.moniaryTypography.metadataStrong
                                    .copyWith(
                                      color: Colors.white,
                                      shadows: const [
                                        Shadow(
                                          color: Colors.black87,
                                          blurRadius: 8,
                                        ),
                                      ],
                                    ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _ComparisonSlide extends StatelessWidget {
  const _ComparisonSlide({required this.recap});

  final MonthlyRecap recap;

  @override
  Widget build(BuildContext context) {
    final maxAmount = [
      recap.previousMonthExpense,
      recap.totalExpense,
      1,
    ].reduce((a, b) => a > b ? a : b);
    final change = recap.monthChange;
    return _StoryPadding(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            context.l10n.journalComparedPrevious.toUpperCase(),
            style: context.moniaryTypography.metadataStrong,
          ),
          const SizedBox(height: 30),
          SizedBox(
            height: 260,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _MonthBar(
                  label: DateFormat.MMM().format(
                    DateTime(recap.month.year, recap.month.month - 1),
                  ),
                  amount: recap.previousMonthExpense,
                  fraction: recap.previousMonthExpense / maxAmount,
                  color: context.moniaryColors.secondary,
                ),
                const SizedBox(width: 24),
                _MonthBar(
                  label: DateFormat.MMM().format(recap.month),
                  amount: recap.totalExpense,
                  fraction: recap.totalExpense / maxAmount,
                  color: context.moniaryColors.primary,
                ),
              ],
            ),
          ),
          const SizedBox(height: 30),
          Text(
            change >= 0
                ? context.l10n.journalSpentMore
                : context.l10n.journalSpentLess,
            style: context.moniaryTypography.displayMedium,
          ),
          Text(
            '${(change.abs() * 100).round()}%',
            style: context.moniaryTypography.displayLarge.copyWith(
              color: change >= 0
                  ? context.moniaryColors.danger
                  : context.moniaryColors.success,
            ),
          ),
        ],
      ),
    );
  }
}

class _MonthBar extends StatelessWidget {
  const _MonthBar({
    required this.label,
    required this.amount,
    required this.fraction,
    required this.color,
  });

  final String label;
  final double amount;
  final double fraction;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text(
            formatVnd(amount),
            style: context.moniaryTypography.metadataStrong,
          ),
          const SizedBox(height: 8),
          Container(
            height: 190 * fraction.clamp(0.05, 1),
            decoration: BoxDecoration(
              color: color,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(18),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(label.toUpperCase(), style: context.moniaryTypography.metadata),
        ],
      ),
    );
  }
}

class _TopCategoriesSlide extends StatelessWidget {
  const _TopCategoriesSlide({required this.recap});

  final MonthlyRecap recap;

  @override
  Widget build(BuildContext context) {
    return _StoryPadding(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            context.l10n.journalTopCategories,
            style: context.moniaryTypography.displayLarge,
          ),
          const SizedBox(height: 28),
          if (recap.topCategories.isEmpty)
            Text(context.l10n.assistantNoData)
          else
            for (var index = 0; index < recap.topCategories.length; index++)
              _CategoryRank(
                rank: index + 1,
                category: recap.topCategories[index],
              ),
        ],
      ),
    );
  }
}

class _CategoryRank extends StatelessWidget {
  const _CategoryRank({required this.rank, required this.category});

  final int rank;
  final JournalCategoryTotal category;

  @override
  Widget build(BuildContext context) {
    final color = AppColor.fromHex(category.color, fallback: AppTheme.sand);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 18),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: context.moniaryColors.textPrimary.withValues(alpha: 0.12),
          ),
        ),
      ),
      child: Row(
        children: [
          Text(
            '$rank',
            style: context.moniaryTypography.displayMedium.copyWith(
              color: color,
            ),
          ),
          const SizedBox(width: 16),
          MoniaryDotBadge(color: color, size: 12),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              category.name,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          Text(
            formatVnd(category.amount),
            style: context.moniaryTypography.metadataStrong,
          ),
        ],
      ),
    );
  }
}
