import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../app/app_theme.dart';
import '../../../../core/constants/app_color.dart';
import '../../../../l10n/l10n_extension.dart';
import '../../../../shared/utils/app_logger.dart';
import '../../../../shared/utils/currency_formatting_ref.dart';
import '../../../../shared/utils/error_helpers.dart';
import '../../../../shared/widgets/supabase_image.dart';
import '../../../calendar/application/month/calendar_month_provider.dart';
import '../../../statistics/presentation/statistics_view.dart';
import '../../application/queries/transaction_queries.dart';
import '../../domain/models/transaction_entry.dart';
import '../../domain/models/transaction_mutation_result.dart';
import '../form/transaction_form_sheet.dart';
import 'transaction_detail_screen.dart';
import 'transaction_route_args.dart';

class DayDetailScreen extends ConsumerWidget {
  const DayDetailScreen({required this.date, super.key});

  static const routePath = '/day-detail';

  final DateTime date;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactionsAsync = ref.watch(transactionsForDayProvider(date));

    return Scaffold(
      backgroundColor: context.moniaryColors.background,
      body: transactionsAsync.when(
        data: (transactions) =>
            _DayDetailBody(date: date, transactions: transactions),
        loading: () => Center(
          child: CircularProgressIndicator(
            color: context.moniaryColors.primary,
          ),
        ),
        error: (error, stackTrace) {
          AppLogger.error('Failed to load day transactions', error, stackTrace);
          return SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 393),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    context.l10n.transactionLoadDayError(
                      userFriendlyMessage(context, error),
                    ),
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: context.moniaryColors.textSecondary,
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

enum _DayDetailViewMode { grid, list }

class _DayDetailBody extends ConsumerStatefulWidget {
  const _DayDetailBody({required this.date, required this.transactions});

  final DateTime date;
  final List<TransactionEntry> transactions;

  @override
  ConsumerState<_DayDetailBody> createState() => _DayDetailBodyState();
}

class _DayDetailBodyState extends ConsumerState<_DayDetailBody> {
  _DayDetailViewMode _viewMode = _DayDetailViewMode.grid;

  @override
  Widget build(BuildContext context) {
    final date = widget.date;
    final transactions = widget.transactions;
    final income = transactions
        .where((transaction) => transaction.isIncome)
        .fold<double>(0, (sum, item) => sum + item.amount);
    final expense = transactions
        .where((transaction) => transaction.isExpense)
        .fold<double>(0, (sum, item) => sum + item.amount);
    final net = income - expense;
    final colors = context.moniaryColors;
    final typography = context.moniaryTypography;
    final isToday = DateUtils.isSameDay(date, DateTime.now());

    return SafeArea(
      bottom: false,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 393),
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(22, 10, 22, 0),
                      child: Row(
                        children: [
                          _DayTopButton(
                            icon: Icons.arrow_back_ios_new_rounded,
                            tooltip: MaterialLocalizations.of(
                              context,
                            ).backButtonTooltip,
                            onPressed: () {
                              if (context.canPop()) {
                                context.pop();
                              } else {
                                context.go('/calendar');
                              }
                            },
                          ),
                          const Spacer(),
                          _DayTopButton(
                            icon: Icons.star_border_rounded,
                            tooltip: context.l10n.starredTransactionsTitle,
                            onPressed: () =>
                                context.push('/starred-transactions'),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 15),
                    Text(
                      isToday
                          ? context.l10n.calendarToday.toUpperCase()
                          : _titleCase(
                              DateFormat(
                                'EEEE',
                                Localizations.localeOf(context).toString(),
                              ).format(date),
                            ).toUpperCase(),
                      style: typography.metadataStrong.copyWith(
                        color: colors.primary,
                        fontSize: 9,
                        letterSpacing: 2.2,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      _dayTitle(context, date),
                      textAlign: TextAlign.center,
                      style: typography.displayMedium.copyWith(
                        fontSize: 29,
                        height: 1,
                      ),
                    ),
                    const SizedBox(height: 13),
                    Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: context.l10n
                                .transactionCount(transactions.length)
                                .toUpperCase(),
                          ),
                          const TextSpan(text: '   '),
                          TextSpan(
                            text:
                                '${net >= 0 ? '+' : '-'}${ref.formatAmount(net.abs())}',
                            style: TextStyle(
                              color: net >= 0 ? colors.success : colors.danger,
                              letterSpacing: 0.45,
                            ),
                          ),
                        ],
                      ),
                      style: typography.metadataStrong.copyWith(
                        color: colors.textDim,
                        fontSize: 9.5,
                        letterSpacing: 2.1,
                      ),
                    ),
                    const SizedBox(height: 30),
                    if (transactions.isNotEmpty) ...[
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: _DayViewSwitcher(
                          selected: _viewMode,
                          onChanged: (value) =>
                              setState(() => _viewMode = value),
                        ),
                      ),
                      const SizedBox(height: 18),
                    ],
                  ],
                ),
              ),
              if (transactions.isEmpty)
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(30, 10, 30, 18),
                  sliver: SliverToBoxAdapter(
                    child: Text(
                      context.l10n.transactionDayEmpty,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: colors.textSecondary,
                      ),
                    ),
                  ),
                )
              else if (_viewMode == _DayDetailViewMode.grid)
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 0),
                  sliver: SliverGrid.builder(
                    itemCount: transactions.length,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 7,
                          mainAxisSpacing: 6,
                          crossAxisSpacing: 6,
                          childAspectRatio: 1,
                        ),
                    itemBuilder: (context, index) {
                      final transaction = transactions[index];
                      return TransactionGridTile(
                            transaction: transaction,
                            onTap: () =>
                                _openTransactionDetail(context, transaction),
                          )
                          .animate(delay: (22 * index).ms)
                          .fade()
                          .scale(
                            begin: const Offset(0.96, 0.96),
                            end: const Offset(1, 1),
                            curve: Curves.easeOutQuad,
                            duration: 240.ms,
                          );
                    },
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 0),
                  sliver: SliverList.separated(
                    itemCount: transactions.length,
                    separatorBuilder: (context, index) => Padding(
                      padding: const EdgeInsets.only(left: 58),
                      child: Divider(
                        height: 1,
                        color: colors.outline.withValues(alpha: 0.74),
                      ),
                    ),
                    itemBuilder: (context, index) {
                      final transaction = transactions[index];
                      return _DayTransactionRow(
                            transaction: transaction,
                            onTap: () =>
                                _openTransactionDetail(context, transaction),
                          )
                          .animate(delay: (26 * index).ms)
                          .fade()
                          .slideY(
                            begin: 0.08,
                            end: 0,
                            curve: Curves.easeOutQuad,
                            duration: 260.ms,
                          );
                    },
                  ),
                ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(24, 22, 24, 108),
                sliver: SliverToBoxAdapter(
                  child: _AddForDayButton(
                    onPressed: () async {
                      final result = await showTransactionFormSheet(
                        context,
                        ref,
                        initialDateTime: date,
                      );
                      if (result == null || !context.mounted) return;
                      _applyMutation(ref, result);
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openTransactionDetail(
    BuildContext context,
    TransactionEntry transaction,
  ) async {
    final result = await context.push<TransactionMutationResult>(
      TransactionDetailScreen.routePath,
      extra: TransactionDetailRouteArgs(
        transaction: transaction,
        day: widget.date,
      ),
    );
    if (result == null || !context.mounted) return;
    _applyMutation(ref, result);
  }
}

class _DayTopButton extends StatelessWidget {
  const _DayTopButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = context.moniaryColors;
    return Tooltip(
      message: tooltip,
      child: Material(
        color: colors.surface.withValues(alpha: 0.56),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(13),
          side: BorderSide(color: colors.outline),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onPressed,
          child: SizedBox(
            width: 41,
            height: 41,
            child: Icon(icon, size: 18, color: colors.icon),
          ),
        ),
      ),
    );
  }
}

class _DayViewSwitcher extends StatelessWidget {
  const _DayViewSwitcher({required this.selected, required this.onChanged});

  final _DayDetailViewMode selected;
  final ValueChanged<_DayDetailViewMode> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = context.moniaryColors;
    return Container(
      height: 48,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: colors.surface.withValues(alpha: 0.68),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.outline.withValues(alpha: 0.82)),
      ),
      child: Row(
        children: [
          Expanded(
            child: _DayViewSegment(
              icon: Icons.grid_view_rounded,
              label: context.l10n.transactionDayGridView,
              selected: selected == _DayDetailViewMode.grid,
              onTap: () => onChanged(_DayDetailViewMode.grid),
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: _DayViewSegment(
              icon: Icons.view_agenda_outlined,
              label: context.l10n.transactionDayListView,
              selected: selected == _DayDetailViewMode.list,
              onTap: () => onChanged(_DayDetailViewMode.list),
            ),
          ),
        ],
      ),
    );
  }
}

class _DayViewSegment extends StatelessWidget {
  const _DayViewSegment({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.moniaryColors;
    final foreground = selected ? colors.background : colors.textSecondary;
    return Material(
      color: selected ? colors.textPrimary : Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18, color: foreground),
              const SizedBox(width: 7),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: foreground,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AddForDayButton extends StatelessWidget {
  const _AddForDayButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = context.moniaryColors;
    return CustomPaint(
      painter: _DashedBorderPainter(color: colors.outline, radius: 13),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(13),
          onTap: onPressed,
          child: SizedBox(
            height: 54,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_rounded, size: 20, color: colors.primary),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      context.l10n.transactionAddForDay,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: colors.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
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

class _DashedBorderPainter extends CustomPainter {
  const _DashedBorderPainter({required this.color, required this.radius});

  final Color color;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.1
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(Offset.zero & size, Radius.circular(radius)),
      );
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final end = (distance + 6).clamp(0.0, metric.length);
        canvas.drawPath(metric.extractPath(distance, end), paint);
        distance += 11;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedBorderPainter oldDelegate) {
    return color != oldDelegate.color || radius != oldDelegate.radius;
  }
}

class _CategoryTile extends StatelessWidget {
  const _CategoryTile({
    required this.color,
    required this.isImportant,
    required this.imagePath,
  });

  final Color color;
  final bool isImportant;
  final String? imagePath;

  @override
  Widget build(BuildContext context) {
    final colors = context.moniaryColors;
    return SizedBox(
      width: 42,
      height: 42,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              color: Color.lerp(color, colors.backgroundSoft, 0.08),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
              boxShadow: [
                BoxShadow(
                  color: colors.textPrimary.withValues(alpha: 0.07),
                  blurRadius: 10,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: imagePath == null
                  ? const SizedBox.expand()
                  : SupabaseImage(
                      imagePath: imagePath,
                      width: 42,
                      height: 42,
                      fit: BoxFit.cover,
                      fallbackIcon: Icons.receipt_long_outlined,
                    ),
            ),
          ),
          if (isImportant)
            Positioned(
              top: -5,
              right: -5,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: colors.primary,
                  shape: BoxShape.circle,
                  border: Border.all(color: colors.background, width: 1.4),
                ),
                child: SizedBox(
                  width: 17,
                  height: 17,
                  child: Icon(
                    Icons.star_rounded,
                    size: 11,
                    color: colors.surfaceRaised,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _DayTransactionRow extends ConsumerWidget {
  const _DayTransactionRow({required this.transaction, required this.onTap});

  final TransactionEntry transaction;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.moniaryColors;
    final accent = AppColor.fromHex(
      transaction.categoryColor ?? transaction.walletColor,
      fallback: transaction.isIncome ? colors.success : colors.warning,
    );
    final title = transaction.note?.trim().isNotEmpty == true
        ? transaction.note!.trim()
        : transaction.categoryName;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 13),
          child: Row(
            children: [
              _CategoryTile(
                color: accent,
                isImportant: transaction.isImportant,
                imagePath: transaction.imagePath,
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: colors.textPrimary,
                        fontSize: 14.5,
                        fontWeight: FontWeight.w800,
                        height: 1.15,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Text(
                      '${DateFormat('HH:mm').format(transaction.transactionDate)} · '
                      '${transaction.categoryName.toUpperCase()} · '
                      '${transaction.walletName.toUpperCase()}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.moniaryTypography.metadata.copyWith(
                        color: colors.textDim,
                        fontSize: 8.6,
                        letterSpacing: 0.55,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Text(
                '${transaction.isIncome ? '+' : '-'}${ref.formatAmount(transaction.amount)}',
                textAlign: TextAlign.right,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: transaction.isIncome
                      ? colors.success
                      : colors.textPrimary,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class TransactionGridTile extends ConsumerWidget {
  const TransactionGridTile({
    super.key,
    required this.transaction,
    required this.onTap,
  });

  final TransactionEntry transaction;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accent = AppColor.fromHex(
      transaction.categoryColor ?? transaction.walletColor,
      fallback: transaction.isIncome ? AppTheme.success : AppTheme.amber,
    );
    final categoryLabel = transaction.categoryName.trim().isEmpty
        ? context.l10n.categoryOther
        : transaction.categoryName;
    final walletLabel = transaction.walletName.trim().isEmpty
        ? context.l10n.walletUnknown
        : transaction.walletName;
    final amountLabel =
        '${transaction.isIncome ? '+' : '-'}${ref.formatAmount(transaction.amount)}';

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 70;
        final radius = compact ? 9.0 : 16.0;
        return InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(radius),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(radius),
            child: Stack(
              fit: StackFit.expand,
              children: [
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [accent, accent.withValues(alpha: 0.42)],
                    ),
                    boxShadow: transaction.isImportant && !compact
                        ? [
                            BoxShadow(
                              color: AppTheme.amber.withValues(alpha: 0.2),
                              blurRadius: 8,
                              spreadRadius: 1,
                            ),
                          ]
                        : null,
                  ),
                  child: Hero(
                    tag: 'tx_image_${transaction.id}',
                    child: SupabaseImage(
                      imagePath: transaction.imagePath,
                      width: double.infinity,
                      height: double.infinity,
                      fit: BoxFit.cover,
                      fallbackIcon: Icons.receipt_long_outlined,
                    ),
                  ),
                ),
                Positioned.fill(
                  child: ColoredBox(
                    color: Colors.black.withValues(alpha: compact ? 0.36 : 0.2),
                  ),
                ),
                if (!compact)
                  Positioned(
                    top: 6,
                    left: 6,
                    right: 6,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        GridTag(label: categoryLabel),
                        const SizedBox(height: 4),
                        GridTag(label: walletLabel),
                      ],
                    ),
                  ),
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: compact ? 2 : 8,
                      vertical: compact ? 3 : 8,
                    ),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [
                          Colors.black87,
                          Colors.black54,
                          Colors.transparent,
                        ],
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: compact
                                ? Alignment.center
                                : Alignment.centerLeft,
                            child: Text(
                              amountLabel,
                              maxLines: 1,
                              style: Theme.of(context).textTheme.titleSmall
                                  ?.copyWith(
                                    color: Colors.white,
                                    fontSize: compact ? 10 : 13.5,
                                    fontWeight: FontWeight.w900,
                                  ),
                            ),
                          ),
                        ),
                        if (transaction.isImportant) ...[
                          SizedBox(width: compact ? 1 : 4),
                          Icon(
                                Icons.star,
                                color: AppTheme.amber,
                                size: compact ? 10 : 16,
                              )
                              .animate(
                                onPlay: (controller) =>
                                    controller.repeat(reverse: true),
                              )
                              .scale(
                                begin: const Offset(1, 1),
                                end: const Offset(1.2, 1.2),
                                duration: 1000.ms,
                                curve: Curves.easeInOut,
                              )
                              .custom(
                                builder: (context, value, child) => Container(
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppTheme.amber.withValues(
                                          alpha: 0.3 * value,
                                        ),
                                        blurRadius: (compact ? 4 : 8) * value,
                                        spreadRadius: (compact ? 1 : 2) * value,
                                      ),
                                    ],
                                  ),
                                  child: child,
                                ),
                              ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class GridTag extends StatelessWidget {
  const GridTag({super.key, required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 9,
          fontWeight: FontWeight.w500,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

String _dayTitle(BuildContext context, DateTime date) {
  final locale = Localizations.localeOf(context).toString();
  return _titleCase(DateFormat('EEEE, d MMMM', locale).format(date));
}

String _titleCase(String value) {
  return value
      .split(' ')
      .map((word) {
        if (word.isEmpty) return word;
        return '${word[0].toUpperCase()}${word.substring(1)}';
      })
      .join(' ');
}

void _applyMutation(WidgetRef ref, TransactionMutationResult result) {
  final days = <DateTime>{
    if (result.previousDate != null)
      DateTime(
        result.previousDate!.year,
        result.previousDate!.month,
        result.previousDate!.day,
      ),
    if (result.currentDate != null)
      DateTime(
        result.currentDate!.year,
        result.currentDate!.month,
        result.currentDate!.day,
      ),
  };

  for (final day in days) {
    ref.invalidate(transactionsForDayProvider(day));
  }

  final months = <DateTime>{
    if (result.previousDate != null)
      DateTime(result.previousDate!.year, result.previousDate!.month, 1),
    if (result.currentDate != null)
      DateTime(result.currentDate!.year, result.currentDate!.month, 1),
  };

  for (final month in months) {
    ref.invalidate(calendarMonthProvider(month));
    ref.invalidate(statisticsMonthProvider(month));
  }
}
