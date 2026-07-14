import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../app/app_theme.dart';
import '../../../core/constants/app_color.dart';
import '../../../l10n/l10n_extension.dart';
import '../../../shared/utils/currency_formatting_ref.dart';
import '../../../shared/utils/error_helpers.dart';
import '../../../shared/widgets/moniary_design.dart';
import '../../../shared/widgets/supabase_image.dart';
import '../../transactions/domain/models/transaction_entry.dart';
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
  static const _slideCount = 6;

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
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: _paper,
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
                  _CoverSlide(recap: recap),
                  _CashFlowSlide(recap: recap),
                  _TopCategoriesSlide(recap: recap),
                  _HighestDaySlide(recap: recap),
                  _InsightsSlide(recap: recap),
                  _ShareSlide(recap: recap),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _move(int delta) {
    final next = (_page + delta).clamp(0, _slideCount - 1);
    if (next == _page) return;
    _controller.animateToPage(
      next,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
    );
  }
}

const _storySlideCount = 6;
const _paper = Color(0xFFF4EEE4);
const _paperSoft = Color(0xFFFFFBF3);
const _ink = Color(0xFF23322B);
const _inkSoft = Color(0xFF4D4A3F);
const _muted = Color(0xFF8A7D6C);
const _line = Color(0xFFD9CCBA);
const _terracotta = AppTheme.terracotta;
const _terracottaBright = AppTheme.terracottaBright;
const _sage = AppTheme.sage;
const _forest = AppTheme.forest;
const _charcoal = Color(0xFF20231D);

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
      child: Stack(
        children: [
          const Positioned.fill(child: _PaperBackdrop()),
          Column(
            children: [
              if (recap != null)
                _StoryHeader(page: page, recap: recap!, onClose: onClose)
              else
                const SizedBox(height: 76),
              Expanded(child: child),
              if (recap != null)
                SafeArea(
                  top: false,
                  minimum: const EdgeInsets.fromLTRB(28, 8, 28, 22),
                  child: _ShareButton(onPressed: onShare),
                )
              else
                const SizedBox(height: 44),
            ],
          ),
        ],
      ),
    );
  }
}

class _PaperBackdrop extends StatelessWidget {
  const _PaperBackdrop();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_paperSoft, _paper, Color(0xFFEDE1D0)],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            left: -54,
            top: 210,
            child: Container(
              width: 92,
              height: 180,
              decoration: BoxDecoration(
                color: _terracotta.withValues(alpha: 0.72),
                borderRadius: const BorderRadius.horizontal(
                  right: Radius.circular(90),
                ),
              ),
            ),
          ),
          Positioned(
            right: -36,
            top: 248,
            child: Icon(
              Icons.spa_outlined,
              size: 118,
              color: _sage.withValues(alpha: 0.28),
            ),
          ),
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
      padding: const EdgeInsets.fromLTRB(28, 13, 18, 0),
      child: Column(
        children: [
          Row(
            children: [
              for (var index = 0; index < _storySlideCount; index++) ...[
                Expanded(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    height: 5,
                    decoration: BoxDecoration(
                      color: index <= page
                          ? _terracotta
                          : _line.withValues(alpha: 0.82),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                if (index < _storySlideCount - 1) const SizedBox(width: 6),
              ],
              const SizedBox(width: 14),
              IconButton(
                onPressed: onClose,
                tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
                icon: const Icon(Icons.close_rounded),
                color: _ink,
                iconSize: 25,
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
          const SizedBox(height: 6),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              context.l10n.journalRecapMonth(month),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: context.moniaryTypography.metadataStrong.copyWith(
                color: _muted,
                fontSize: 11,
                letterSpacing: 2.4,
              ),
            ),
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
      height: 56,
      child: FilledButton.icon(
        onPressed: onPressed,
        icon: const Icon(Icons.ios_share_rounded, size: 21),
        label: Text(context.l10n.journalShareRecap),
        style: FilledButton.styleFrom(
          backgroundColor: _terracottaBright,
          foregroundColor: _paperSoft,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(999),
          ),
          textStyle: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
        ),
      ),
    );
  }
}

class _StoryLoading extends StatelessWidget {
  const _StoryLoading();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(
        color: _terracotta,
        backgroundColor: _line,
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
          ).textTheme.bodyLarge?.copyWith(color: _ink, height: 1.35),
        ),
      ),
    );
  }
}

class _StorySlide extends StatelessWidget {
  const _StorySlide({required this.child, this.alignment = Alignment.center});

  final Widget child;
  final Alignment alignment;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(28, 18, 28, 20),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minHeight: MediaQuery.sizeOf(context).height - 190,
        ),
        child: Align(alignment: alignment, child: child),
      ),
    );
  }
}

class _CoverSlide extends ConsumerWidget {
  const _CoverSlide({required this.recap});

  final MonthlyRecap recap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final topCategory = recap.topCategories.firstOrNull;
    final month = _monthName(context, recap.month);
    return _StorySlide(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.auto_awesome_rounded, color: _terracotta, size: 34),
          const SizedBox(height: 14),
          Text(
            context.l10n.journalRecapTitle,
            textAlign: TextAlign.center,
            style: context.moniaryTypography.displayLarge.copyWith(
              color: _ink,
              fontSize: 56,
              height: 0.96,
              letterSpacing: 0,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            context.l10n.journalMoneyStoryMonth(month),
            textAlign: TextAlign.center,
            style: context.moniaryTypography.displaySmall.copyWith(
              color: _terracotta,
              fontSize: 29,
              height: 1,
            ),
          ),
          const SizedBox(height: 28),
          Text(
            context.l10n.journalRecordedCount(recap.expenseCount),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: _inkSoft,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            ref.formatAmount(recap.totalExpense),
            textAlign: TextAlign.center,
            style: context.moniaryTypography.displayLarge.copyWith(
              color: _ink,
              fontSize: 50,
              height: 1,
              letterSpacing: 0,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            context.l10n.journalMoneyStoryExpenseLabel,
            style: context.moniaryTypography.metadataStrong.copyWith(
              color: _muted,
              letterSpacing: 1.3,
            ),
          ),
          const SizedBox(height: 28),
          if (topCategory != null)
            _InsightPill(
              icon: Icons.restaurant_menu_rounded,
              label: context.l10n.journalMoneyStoryCategoryShare(
                topCategory.name,
                _percent(recap.topCategoryShare),
              ),
              color: _terracotta,
            )
          else
            _EmptyStoryCard(
              title: context.l10n.journalMoneyStoryNoTransactionsTitle,
              body: context.l10n.journalMoneyStoryNoTransactionsBody,
            ),
          const SizedBox(height: 18),
          if (recap.previousMonthExpense > 0)
            _MonthChangeLine(change: recap.monthChange),
        ],
      ),
    );
  }
}

class _MonthChangeLine extends StatelessWidget {
  const _MonthChangeLine({required this.change});

  final double change;

  @override
  Widget build(BuildContext context) {
    final isDown = change < 0;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        CircleAvatar(
          radius: 17,
          backgroundColor: (isDown ? _forest : _terracotta).withValues(
            alpha: 0.88,
          ),
          child: Icon(
            isDown ? Icons.south_rounded : Icons.north_rounded,
            color: _paperSoft,
            size: 19,
          ),
        ),
        const SizedBox(width: 10),
        Text(
          '${isDown ? context.l10n.journalSpentLess : context.l10n.journalSpentMore} ${_percent(change.abs())}%',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            color: isDown ? _forest : _terracotta,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _CashFlowSlide extends ConsumerWidget {
  const _CashFlowSlide({required this.recap});

  final MonthlyRecap recap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return _StorySlide(
      alignment: Alignment.topCenter,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _SlideTitle(
            icon: Icons.account_balance_wallet_outlined,
            title: context.l10n.journalMoneyStoryCashFlow,
          ),
          const SizedBox(height: 24),
          _MetricCard(
            label: context.l10n.journalMoneyStoryIncome,
            value: ref.formatAmount(recap.totalIncome),
            color: _forest,
            icon: Icons.call_received_rounded,
          ),
          const SizedBox(height: 12),
          _MetricCard(
            label: context.l10n.journalMoneyStoryExpense,
            value: ref.formatAmount(recap.totalExpense),
            color: _terracotta,
            icon: Icons.call_made_rounded,
          ),
          const SizedBox(height: 12),
          _MetricCard(
            label: context.l10n.journalMoneyStoryNet,
            value: ref.formatAmount(recap.netAmount),
            color: recap.netAmount >= 0 ? _forest : _terracotta,
            icon: Icons.savings_outlined,
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _MiniStat(
                  label: context.l10n.journalMoneyStoryAverageDay,
                  value: ref.formatAmount(recap.averageDailyExpense),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _MiniStat(
                  label: context.l10n.journalMoneyStoryActiveDays(
                    recap.activeRecordingDays,
                  ),
                  value: '${recap.activeRecordingDays}',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TopCategoriesSlide extends ConsumerWidget {
  const _TopCategoriesSlide({required this.recap});

  final MonthlyRecap recap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final maxAmount = recap.topCategories.isEmpty
        ? 1.0
        : recap.topCategories.first.amount;
    return _StorySlide(
      alignment: Alignment.topCenter,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _SlideTitle(
            icon: Icons.bar_chart_rounded,
            title: context.l10n.journalTopCategories,
          ),
          const SizedBox(height: 24),
          if (recap.topCategories.isEmpty)
            _EmptyStoryCard(
              title: context.l10n.journalMoneyStoryNoTransactionsTitle,
              body: context.l10n.journalMoneyStoryNoTransactionsBody,
            )
          else
            _PaperPanel(
              child: Column(
                children: [
                  for (
                    var index = 0;
                    index < recap.topCategories.length;
                    index++
                  )
                    _CategoryBar(
                      category: recap.topCategories[index],
                      maxAmount: maxAmount,
                      totalExpense: recap.totalExpense,
                      isLast: index == recap.topCategories.length - 1,
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _HighestDaySlide extends ConsumerWidget {
  const _HighestDaySlide({required this.recap});

  final MonthlyRecap recap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = Localizations.localeOf(context).toString();
    final highestDate = recap.highestSpendDate;
    final dayTransactions =
        highestDate == null
              ? <TransactionEntry>[]
              : recap.transactions
                    .where(
                      (transaction) =>
                          transaction.isExpense &&
                          _isSameDay(transaction.transactionDate, highestDate),
                    )
                    .toList()
          ..sort((a, b) => b.amount.compareTo(a.amount));
    final imageTransactions = dayTransactions
        .where(
          (transaction) => transaction.imagePath?.trim().isNotEmpty == true,
        )
        .take(3)
        .toList();

    return _StorySlide(
      alignment: Alignment.topCenter,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _SlideTitle(
            icon: Icons.calendar_month_outlined,
            title: context.l10n.journalHighestDay,
          ),
          const SizedBox(height: 24),
          if (highestDate == null)
            _EmptyStoryCard(
              title: context.l10n.journalMoneyStoryHighestDayEmpty,
              body: context.l10n.journalMoneyStoryNoTransactionsBody,
            )
          else ...[
            Text(
              DateFormat.yMMMMd(locale).format(highestDate),
              style: context.moniaryTypography.displayMedium.copyWith(
                color: _ink,
                fontSize: 36,
                height: 1.05,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              context.l10n.journalHighestDayValue(
                DateFormat.MMMd(locale).format(highestDate),
                ref.formatAmount(recap.highestDayAmount),
              ),
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: _muted,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 18),
            if (imageTransactions.isNotEmpty)
              _ReceiptStrip(transactions: imageTransactions)
            else
              _PaperPanel(
                child: Icon(
                  Icons.receipt_long_outlined,
                  size: 84,
                  color: _sage.withValues(alpha: 0.75),
                ),
              ),
            const SizedBox(height: 16),
            Text(
              context.l10n.journalMoneyStoryHighestDayTransactions(
                dayTransactions.length,
              ),
              style: context.moniaryTypography.metadataStrong.copyWith(
                color: _terracotta,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 8),
            for (final transaction in dayTransactions.take(3))
              _TransactionLine(transaction: transaction),
          ],
        ],
      ),
    );
  }
}

class _InsightsSlide extends StatelessWidget {
  const _InsightsSlide({required this.recap});

  final MonthlyRecap recap;

  @override
  Widget build(BuildContext context) {
    return _StorySlide(
      alignment: Alignment.topCenter,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _SlideTitle(
            icon: Icons.tips_and_updates_outlined,
            title: context.l10n.journalMoneyStoryInsightsTitle,
          ),
          const SizedBox(height: 24),
          for (var index = 0; index < recap.insights.length; index++) ...[
            _InsightCard(insight: recap.insights[index]),
            if (index < recap.insights.length - 1) const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }
}

class _ShareSlide extends ConsumerWidget {
  const _ShareSlide({required this.recap});

  final MonthlyRecap recap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final month = _storyMonthLabel(context, recap.month);
    final topCategory = recap.topCategories.firstOrNull;
    return _StorySlide(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            context.l10n.journalMoneyStoryShareTitle,
            textAlign: TextAlign.center,
            style: context.moniaryTypography.displayLarge.copyWith(
              color: _ink,
              fontSize: 44,
              height: 1.02,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            context.l10n.journalMoneyStoryShareBody,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: _muted,
              height: 1.35,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 26),
          _PosterPreview(
            month: month,
            amount: ref.formatAmount(recap.totalExpense),
            count: recap.expenseCount,
            topCategory: topCategory?.name,
          ),
        ],
      ),
    );
  }
}

class _SlideTitle extends StatelessWidget {
  const _SlideTitle({required this.icon, required this.title});

  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: 22,
          backgroundColor: _terracotta.withValues(alpha: 0.14),
          child: Icon(icon, color: _terracotta, size: 24),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Text(
            title,
            style: context.moniaryTypography.displayMedium.copyWith(
              color: _ink,
              fontSize: 39,
              height: 1.02,
            ),
          ),
        ),
      ],
    );
  }
}

class _PaperPanel extends StatelessWidget {
  const _PaperPanel({
    required this.child,
    this.padding = const EdgeInsets.all(18),
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: _paperSoft.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _line.withValues(alpha: 0.82)),
        boxShadow: [
          BoxShadow(
            color: _ink.withValues(alpha: 0.055),
            blurRadius: 18,
            offset: const Offset(0, 9),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  final String label;
  final String value;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return _PaperPanel(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: color.withValues(alpha: 0.14),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: _inkSoft,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: context.moniaryTypography.displaySmall.copyWith(
                color: color,
                fontSize: 27,
                height: 1,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return _PaperPanel(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: context.moniaryTypography.displaySmall.copyWith(
              color: _ink,
              fontSize: 27,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: _muted,
              height: 1.2,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryBar extends ConsumerWidget {
  const _CategoryBar({
    required this.category,
    required this.maxAmount,
    required this.totalExpense,
    required this.isLast,
  });

  final JournalCategoryTotal category;
  final double maxAmount;
  final double totalExpense;
  final bool isLast;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final color = AppColor.fromHex(category.color, fallback: _terracotta);
    final share = totalExpense <= 0 ? 0.0 : category.amount / totalExpense;
    return Container(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 16, top: isLast ? 0 : 0),
      margin: EdgeInsets.only(bottom: isLast ? 0 : 16),
      decoration: BoxDecoration(
        border: Border(
          bottom: isLast
              ? BorderSide.none
              : BorderSide(color: _line.withValues(alpha: 0.75)),
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: color.withValues(alpha: 0.95),
            child: Icon(_categoryIcon(category.name), color: _paperSoft),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        category.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              color: _ink,
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                    ),
                    Text(
                      ref.formatAmount(category.amount),
                      style: context.moniaryTypography.metadataStrong.copyWith(
                        color: _inkSoft,
                        letterSpacing: 0,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: (category.amount / maxAmount)
                        .clamp(0.05, 1)
                        .toDouble(),
                    minHeight: 9,
                    backgroundColor: _line.withValues(alpha: 0.8),
                    valueColor: AlwaysStoppedAnimation(color),
                  ),
                ),
                const SizedBox(height: 6),
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    context.l10n.journalMoneyStoryCategoryPercent(
                      _percent(share),
                    ),
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: color,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ReceiptStrip extends StatelessWidget {
  const _ReceiptStrip({required this.transactions});

  final List<TransactionEntry> transactions;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 174,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          for (var index = 0; index < transactions.length; index++)
            Positioned(
              left: index * 70,
              top: index.isEven ? 6 : 24,
              width: 132,
              height: 140,
              child: Transform.rotate(
                angle: index.isEven ? -0.045 : 0.045,
                child: SupabaseImage(
                  imagePath: transactions[index].imagePath,
                  borderRadius: BorderRadius.circular(22),
                  fallbackIcon: Icons.receipt_long_outlined,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _TransactionLine extends ConsumerWidget {
  const _TransactionLine({required this.transaction});

  final TransactionEntry transaction;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final color = AppColor.fromHex(transaction.categoryColor, fallback: _sage);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 11),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: _line.withValues(alpha: 0.7))),
      ),
      child: Row(
        children: [
          MoniaryDotBadge(color: color, size: 11),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              transaction.categoryName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: _ink,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Text(
            ref.formatAmount(transaction.amount),
            style: context.moniaryTypography.metadataStrong.copyWith(
              color: _muted,
              letterSpacing: 0,
            ),
          ),
        ],
      ),
    );
  }
}

class _InsightCard extends StatelessWidget {
  const _InsightCard({required this.insight});

  final MonthlyRecapInsight insight;

  @override
  Widget build(BuildContext context) {
    final color = _insightColor(insight.type);
    return _PaperPanel(
      padding: const EdgeInsets.fromLTRB(18, 17, 18, 17),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 23,
            backgroundColor: color.withValues(alpha: 0.15),
            child: Icon(_insightIcon(insight.type), color: color, size: 23),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              _insightText(context, insight),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: _ink,
                height: 1.28,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InsightPill extends StatelessWidget {
  const _InsightPill({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return _PaperPanel(
      padding: const EdgeInsets.fromLTRB(17, 14, 17, 14),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: color,
            child: Icon(icon, color: _paperSoft, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: _ink,
                fontWeight: FontWeight.w800,
                height: 1.2,
              ),
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: _muted),
        ],
      ),
    );
  }
}

class _EmptyStoryCard extends StatelessWidget {
  const _EmptyStoryCard({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return _PaperPanel(
      child: Column(
        children: [
          Icon(Icons.auto_stories_outlined, color: _sage, size: 46),
          const SizedBox(height: 12),
          Text(
            title,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: _ink,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            body,
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: _muted, height: 1.35),
          ),
        ],
      ),
    );
  }
}

class _PosterPreview extends StatelessWidget {
  const _PosterPreview({
    required this.month,
    required this.amount,
    required this.count,
    required this.topCategory,
  });

  final String month;
  final String amount;
  final int count;
  final String? topCategory;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 260,
      padding: const EdgeInsets.fromLTRB(22, 22, 22, 18),
      decoration: BoxDecoration(
        color: _charcoal,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: _charcoal.withValues(alpha: 0.22),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            context.l10n.journalRecapTitle,
            style: context.moniaryTypography.displayMedium.copyWith(
              color: _paperSoft,
              fontSize: 36,
              height: 1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            month,
            style: context.moniaryTypography.metadataStrong.copyWith(
              color: _terracottaBright,
              letterSpacing: 2.4,
            ),
          ),
          const SizedBox(height: 22),
          Text(
            amount,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: context.moniaryTypography.displaySmall.copyWith(
              color: _paperSoft,
              fontSize: 31,
            ),
          ),
          const SizedBox(height: 12),
          Divider(color: _paperSoft.withValues(alpha: 0.16)),
          const SizedBox(height: 12),
          Text(
            context.l10n.journalRecordedCount(count),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: _paperSoft.withValues(alpha: 0.74),
              fontWeight: FontWeight.w700,
            ),
          ),
          if (topCategory != null) ...[
            const SizedBox(height: 8),
            Text(
              topCategory!,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: _terracottaBright,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
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
  return DateFormat.yMMMM(
    Localizations.localeOf(context).toString(),
  ).format(month);
}

int _percent(double value) => (value.abs() * 100).round();

bool _isSameDay(DateTime a, DateTime b) {
  return a.year == b.year && a.month == b.month && a.day == b.day;
}

IconData _categoryIcon(String name) {
  final normalized = name.toLowerCase();
  if (normalized.contains('ăn') ||
      normalized.contains('food') ||
      normalized.contains('meal')) {
    return Icons.restaurant_menu_rounded;
  }
  if (normalized.contains('nhà') ||
      normalized.contains('rent') ||
      normalized.contains('home')) {
    return Icons.home_outlined;
  }
  if (normalized.contains('di chuyển') ||
      normalized.contains('move') ||
      normalized.contains('travel')) {
    return Icons.two_wheeler_rounded;
  }
  if (normalized.contains('shopping') || normalized.contains('mua')) {
    return Icons.shopping_bag_outlined;
  }
  return Icons.category_outlined;
}

IconData _insightIcon(MonthlyRecapInsightType type) {
  return switch (type) {
    MonthlyRecapInsightType.spendingDown => Icons.trending_down_rounded,
    MonthlyRecapInsightType.spendingUp => Icons.trending_up_rounded,
    MonthlyRecapInsightType.topCategoryShare => Icons.pie_chart_outline,
    MonthlyRecapInsightType.weekendHeavy => Icons.weekend_outlined,
    MonthlyRecapInsightType.recordingRhythm => Icons.edit_calendar_outlined,
    MonthlyRecapInsightType.quietMonth => Icons.auto_stories_outlined,
  };
}

Color _insightColor(MonthlyRecapInsightType type) {
  return switch (type) {
    MonthlyRecapInsightType.spendingDown => _forest,
    MonthlyRecapInsightType.spendingUp => _terracotta,
    MonthlyRecapInsightType.topCategoryShare => _terracottaBright,
    MonthlyRecapInsightType.weekendHeavy => _sage,
    MonthlyRecapInsightType.recordingRhythm => _forest,
    MonthlyRecapInsightType.quietMonth => _muted,
  };
}

String _insightText(BuildContext context, MonthlyRecapInsight insight) {
  return switch (insight.type) {
    MonthlyRecapInsightType.spendingDown =>
      context.l10n.journalMoneyStoryInsightSpendingDown(
        _percent(insight.value),
      ),
    MonthlyRecapInsightType.spendingUp =>
      context.l10n.journalMoneyStoryInsightSpendingUp(_percent(insight.value)),
    MonthlyRecapInsightType.topCategoryShare =>
      context.l10n.journalMoneyStoryInsightTopCategory(
        insight.categoryName ?? '',
        _percent(insight.value),
      ),
    MonthlyRecapInsightType.weekendHeavy =>
      context.l10n.journalMoneyStoryInsightWeekend(_percent(insight.value)),
    MonthlyRecapInsightType.recordingRhythm =>
      context.l10n.journalMoneyStoryInsightRecording(insight.value.round()),
    MonthlyRecapInsightType.quietMonth =>
      context.l10n.journalMoneyStoryInsightQuiet,
  };
}
