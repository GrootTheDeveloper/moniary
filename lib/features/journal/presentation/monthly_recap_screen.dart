import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: _storyBackground,
        body: recapAsync.when(
          loading: () => const _StoryShell(child: _StoryLoading()),
          error: (error, _) => _StoryShell(
            child: _StoryError(message: userFriendlyMessage(context, error)),
          ),
          data: (recap) => _StoryShell(
            page: _page,
            recap: recap,
            onClose: () => context.pop(),
            onShare: () =>
                context.push(JournalExportScreen.routePath, extra: recap),
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

const _storyBackground = Color(0xFF1F1A14);
const _storyInk = Color(0xFFF3EEE5);
const _storyMuted = Color(0xFFB7AEA2);
const _storyLine = Color(0xFF8B8378);
const _storyAccent = Color(0xFFD9A56D);

class _StoryShell extends StatelessWidget {
  const _StoryShell({
    required this.child,
    this.page = 0,
    this.recap,
    this.onClose,
    this.onShare,
  });

  final Widget child;
  final int page;
  final MonthlyRecap? recap;
  final VoidCallback? onClose;
  final VoidCallback? onShare;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          if (recap != null)
            _StoryHeader(page: page, recap: recap!, onClose: onClose)
          else
            const SizedBox(height: 74),
          Expanded(child: child),
          if (recap != null)
            SafeArea(
              top: false,
              minimum: const EdgeInsets.fromLTRB(34, 8, 34, 22),
              child: _ShareButton(onPressed: onShare),
            )
          else
            const SizedBox(height: 44),
        ],
      ),
    );
  }
}

class _StoryHeader extends StatelessWidget {
  const _StoryHeader({
    required this.page,
    required this.recap,
    required this.onClose,
  });

  final int page;
  final MonthlyRecap recap;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    final month = _monthName(context, recap.month);
    return Padding(
      padding: const EdgeInsets.fromLTRB(34, 13, 22, 0),
      child: Column(
        children: [
          Row(
            children: [
              for (var index = 0; index < 4; index++) ...[
                Expanded(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    height: 4,
                    decoration: BoxDecoration(
                      color: index <= page
                          ? _storyInk
                          : _storyInk.withValues(alpha: 0.42),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                if (index < 3) const SizedBox(width: 6),
              ],
            ],
          ),
          const SizedBox(height: 13),
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: const BoxDecoration(
                  color: Color(0xFFD6CABD),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  context.l10n.journalRecapMonth(month),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: _storyInk,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    height: 1,
                  ),
                ),
              ),
              IconButton(
                onPressed: onClose,
                tooltip: context.l10n.commonClose,
                icon: const Icon(Icons.close_rounded),
                color: _storyMuted,
                iconSize: 18,
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ShareButton extends StatelessWidget {
  const _ShareButton({required this.onPressed});

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: const Icon(Icons.link_rounded, size: 17),
        label: Text(context.l10n.journalShareRecap),
        style: OutlinedButton.styleFrom(
          foregroundColor: _storyInk,
          side: BorderSide(color: _storyLine.withValues(alpha: 0.85)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(999),
          ),
          textStyle: Theme.of(
            context,
          ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w800),
        ),
      ),
    );
  }
}

class _StoryLoading extends StatelessWidget {
  const _StoryLoading();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: CircularProgressIndicator(
        color: _storyInk,
        backgroundColor: _storyInk.withValues(alpha: 0.18),
      ),
    );
  }
}

class _StoryError extends StatelessWidget {
  const _StoryError({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 34),
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: Theme.of(
            context,
          ).textTheme.bodyLarge?.copyWith(color: _storyInk, height: 1.35),
        ),
      ),
    );
  }
}

class _StoryPadding extends StatelessWidget {
  const _StoryPadding({required this.child, this.center = true});

  final Widget child;
  final bool center;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(34, 0, 34, 0),
      child: center
          ? Center(child: child)
          : Align(alignment: Alignment.topCenter, child: child),
    );
  }
}

class _OverviewSlide extends StatelessWidget {
  const _OverviewSlide({required this.recap});

  final MonthlyRecap recap;

  @override
  Widget build(BuildContext context) {
    final topCategory = recap.topCategories.firstOrNull?.name ?? '—';
    return _StoryPadding(
      child: Transform.translate(
        offset: const Offset(0, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _storyMonthLabel(context, recap.month).toUpperCase(),
              textAlign: TextAlign.center,
              style: context.moniaryTypography.metadataStrong.copyWith(
                color: _storyAccent,
                fontSize: 10,
                letterSpacing: 4,
              ),
            ),
            const SizedBox(height: 18),
            _RecordedCountTitle(count: recap.expenseCount),
            const SizedBox(height: 18),
            Text(
              context.l10n.journalRecapSummary(
                formatVnd(recap.totalExpense),
                topCategory,
              ),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: _storyMuted,
                fontSize: 16,
                height: 1.35,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RecordedCountTitle extends StatelessWidget {
  const _RecordedCountTitle({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final text = context.l10n.journalRecordedCount(count);
    final countText = count.toString();
    final parts = text.split(countText);
    final baseStyle = context.moniaryTypography.displayLarge.copyWith(
      color: _storyInk,
      fontSize: 38,
      height: 1.08,
      letterSpacing: 0,
    );

    if (parts.length < 2) {
      return Text(text, textAlign: TextAlign.center, style: baseStyle);
    }

    return Text.rich(
      TextSpan(
        children: [
          TextSpan(text: '${parts.first.trimRight()}\n'),
          TextSpan(
            text: countText,
            style: baseStyle.copyWith(color: _storyAccent),
          ),
          TextSpan(text: parts.skip(1).join(countText)),
        ],
      ),
      textAlign: TextAlign.center,
      style: baseStyle,
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
      center: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 72),
          Text(
            context.l10n.journalHighestDay,
            style: context.moniaryTypography.displayMedium.copyWith(
              color: _storyInk,
              fontSize: 34,
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: withImages.isEmpty
                ? DecoratedBox(
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: _storyLine.withValues(alpha: 0.42),
                      ),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Center(
                      child: Icon(
                        Icons.photo_library_outlined,
                        size: 54,
                        color: _storyMuted,
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
                              borderRadius: BorderRadius.circular(16),
                              fallbackIcon: Icons.receipt_long_outlined,
                            ),
                            Positioned.fill(
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(16),
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      Colors.transparent,
                                      Colors.black.withValues(alpha: 0.58),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            Positioned(
                              left: 10,
                              right: 10,
                              bottom: 9,
                              child: Text(
                                formatVnd(transaction.amount),
                                style: context.moniaryTypography.metadataStrong
                                    .copyWith(
                                      color: _storyInk,
                                      fontSize: 11,
                                      letterSpacing: 0,
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
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            context.l10n.journalComparedPrevious.toUpperCase(),
            textAlign: TextAlign.center,
            style: context.moniaryTypography.metadataStrong.copyWith(
              color: _storyAccent,
              letterSpacing: 3,
            ),
          ),
          const SizedBox(height: 26),
          SizedBox(
            height: 230,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _MonthBar(
                  label: DateFormat.MMM().format(
                    DateTime(recap.month.year, recap.month.month - 1),
                  ),
                  amount: recap.previousMonthExpense,
                  fraction: recap.previousMonthExpense / maxAmount,
                  color: const Color(0xFF8B8378),
                ),
                const SizedBox(width: 24),
                _MonthBar(
                  label: DateFormat.MMM().format(recap.month),
                  amount: recap.totalExpense,
                  fraction: recap.totalExpense / maxAmount,
                  color: _storyAccent,
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          Text(
            change >= 0
                ? context.l10n.journalSpentMore
                : context.l10n.journalSpentLess,
            textAlign: TextAlign.center,
            style: context.moniaryTypography.displayMedium.copyWith(
              color: _storyInk,
              fontSize: 30,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${(change.abs() * 100).round()}%',
            textAlign: TextAlign.center,
            style: context.moniaryTypography.displayLarge.copyWith(
              color: change >= 0
                  ? const Color(0xFFE09A80)
                  : const Color(0xFF8FB79A),
              fontSize: 56,
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
            textAlign: TextAlign.center,
            style: context.moniaryTypography.metadataStrong.copyWith(
              color: _storyMuted,
              letterSpacing: 0,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            height: 180 * fraction.clamp(0.05, 1),
            decoration: BoxDecoration(
              color: color,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
            ),
          ),
          const SizedBox(height: 9),
          Text(
            label.toUpperCase(),
            style: context.moniaryTypography.metadata.copyWith(
              color: _storyMuted,
              letterSpacing: 2,
            ),
          ),
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
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.l10n.journalTopCategories,
            style: context.moniaryTypography.displayLarge.copyWith(
              color: _storyInk,
              fontSize: 42,
              height: 1.05,
            ),
          ),
          const SizedBox(height: 22),
          if (recap.topCategories.isEmpty)
            Text(
              context.l10n.assistantNoData,
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(color: _storyMuted),
            )
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
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: _storyLine.withValues(alpha: 0.38)),
        ),
      ),
      child: Row(
        children: [
          Text(
            '$rank',
            style: context.moniaryTypography.displayMedium.copyWith(
              color: color,
              fontSize: 30,
            ),
          ),
          const SizedBox(width: 16),
          MoniaryDotBadge(color: color, size: 12),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              category.name,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: _storyInk,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Text(
            formatVnd(category.amount),
            style: context.moniaryTypography.metadataStrong.copyWith(
              color: _storyMuted,
              letterSpacing: 0,
            ),
          ),
        ],
      ),
    );
  }
}

String _monthName(BuildContext context, DateTime month) {
  return DateFormat.MMMM(
    Localizations.localeOf(context).toString(),
  ).format(month);
}

String _storyMonthLabel(BuildContext context, DateTime month) {
  return '${_monthName(context, month)}, ${month.year}';
}
