import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../l10n/l10n_extension.dart';
import '../../../../app/app_theme.dart';
import '../../../../core/constants/app_color.dart';
import '../../../../core/supabase/supabase_providers.dart';
import '../../../auth/presentation/login_screen.dart';
import '../../../categories/domain/models/category.dart';
import '../../../categories/application/categories_controller.dart';
import '../../../transactions/domain/models/transaction_mutation_result.dart';
import '../../../transactions/presentation/detail/day_detail_screen.dart';
import '../../../wallets/domain/models/wallet.dart';
import '../../../wallets/application/wallets_controller.dart';
import '../../application/month/calendar_filter_provider.dart';
import '../../application/month/calendar_month_provider.dart';
import '../../application/month/calendar_visible_month_provider.dart';
import '../../domain/month/calendar_month_data.dart';
import 'manage_data_sheet.dart';

class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});

  static const routePath = '/calendar';

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  @override
  Widget build(BuildContext context) {
    final session = ref.watch(currentSessionProvider);
    final userId = session?.user.id ?? '';
    final visibleMonth = ref.watch(calendarVisibleMonthProvider);
    final monthAsync = ref.watch(calendarMonthProvider(visibleMonth));

    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0B1521), AppTheme.background, Color(0xFF08111B)],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Column(
              children: [
                _CalendarHeader(
                  month: visibleMonth,
                  onPreviousMonth: () => _changeMonth(-1),
                  onNextMonth: () => _changeMonth(1),
                  onOpenManager: () => _openManager(context),
                  onLogout: () async {
                    await ref.read(supabaseClientProvider).auth.signOut();
                    if (!context.mounted) {
                      return;
                    }
                    context.go(LoginScreen.routePath);
                  },
                  onMonthSelect: (date) {
                    ref
                        .read(calendarVisibleMonthProvider.notifier)
                        .setMonth(date);
                  },
                ),
                const SizedBox(height: 14),
                _FilterRow(userId: userId),
                const SizedBox(height: 16),
                Expanded(
                  child: monthAsync.when(
                    data: (monthData) => SingleChildScrollView(
                      child: Column(
                        children: [
                          _MonthCalendarCard(
                            monthData: monthData,
                            onDayTap: _openDayDetail,
                          ),
                          const SizedBox(height: 16),
                          _MonthlySummaryCard(monthData: monthData),
                          const SizedBox(height: 100),
                        ],
                      ),
                    ),
                    error: (error, stackTrace) =>
                        _CalendarErrorState(error: error),
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _changeMonth(int offset) {
    ref.read(calendarVisibleMonthProvider.notifier).changeMonth(offset);
  }

  Future<void> _openManager(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => const ManageDataSheet(),
    );
  }

  Future<void> _openDayDetail(DateTime date) async {
    final result = await context.push<TransactionMutationResult>(
      DayDetailScreen.routePath,
      extra: date,
    );
    if (result == null || !mounted) {
      return;
    }
    _applyMutationResult(result);
  }

  void _applyMutationResult(TransactionMutationResult result) {
    final months = <DateTime>{
      if (result.previousDate != null)
        DateTime(result.previousDate!.year, result.previousDate!.month, 1),
      if (result.currentDate != null)
        DateTime(result.currentDate!.year, result.currentDate!.month, 1),
    };

    if (result.currentDate != null) {
      ref
          .read(calendarVisibleMonthProvider.notifier)
          .setMonth(result.currentDate!);
    }

    for (final month in months) {
      ref.invalidate(calendarMonthProvider(month));
    }
  }
}

class _CalendarHeader extends StatelessWidget {
  const _CalendarHeader({
    required this.month,
    required this.onPreviousMonth,
    required this.onNextMonth,
    required this.onOpenManager,
    required this.onLogout,
    required this.onMonthSelect,
  });

  final DateTime month;
  final VoidCallback onPreviousMonth;
  final VoidCallback onNextMonth;
  final VoidCallback onOpenManager;
  final VoidCallback onLogout;
  final ValueChanged<DateTime> onMonthSelect;

  @override
  Widget build(BuildContext context) {
    final localeName = Localizations.localeOf(context).toString();
    final label = DateFormat.MMMM(localeName).format(month);
    final title = '${_capitalize(label)} ${month.year}';

    return Row(
      children: [
        _RoundIconButton(icon: Icons.menu_rounded, onTap: onOpenManager),
        const SizedBox(width: 12),
        Expanded(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                onPressed: onPreviousMonth,
                icon: const Icon(Icons.chevron_left_rounded),
              ),
              Flexible(
                child: InkWell(
                  onTap: () => _showMonthPicker(context),
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    child: Text(
                      title,
                      textAlign: TextAlign.center,
                      style: Theme.of(
                        context,
                      ).textTheme.titleLarge?.copyWith(fontSize: 24),
                    ),
                  ),
                ),
              ),
              IconButton(
                onPressed: onNextMonth,
                icon: const Icon(Icons.chevron_right_rounded),
              ),
            ],
          ),
        ),
        _RoundIconButton(
          icon: Icons.calendar_month_outlined,
          onTap: () {
            onMonthSelect(DateTime.now());
          },
        ),
        const SizedBox(width: 8),
        _RoundIconButton(icon: Icons.logout_rounded, onTap: onLogout),
      ],
    );
  }

  void _showMonthPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return _MonthPickerContent(
          initialDate: month,
          onSelected: (date) {
            onMonthSelect(date);
            Navigator.pop(context);
          },
        );
      },
    );
  }
}

class _MonthPickerContent extends StatefulWidget {
  const _MonthPickerContent({
    required this.initialDate,
    required this.onSelected,
  });
  final DateTime initialDate;
  final ValueChanged<DateTime> onSelected;

  @override
  State<_MonthPickerContent> createState() => _MonthPickerContentState();
}

class _MonthPickerContentState extends State<_MonthPickerContent> {
  late int _selectedYear;

  @override
  void initState() {
    super.initState();
    _selectedYear = widget.initialDate.year;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 380,
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: () => setState(() => _selectedYear--),
              ),
              Text(
                '$_selectedYear',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: () => setState(() => _selectedYear++),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Expanded(
            child: GridView.builder(
              itemCount: 12,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 1.5,
              ),
              itemBuilder: (context, index) {
                final month = index + 1;
                final isSelected =
                    widget.initialDate.year == _selectedYear &&
                    widget.initialDate.month == month;
                return InkWell(
                  onTap: () =>
                      widget.onSelected(DateTime(_selectedYear, month)),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    decoration: BoxDecoration(
                      color: isSelected ? AppTheme.mint : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isSelected ? AppTheme.mint : Colors.white10,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      DateFormat.MMM(
                        Localizations.localeOf(context).toString(),
                      ).format(DateTime(_selectedYear, month)),
                      style: TextStyle(
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.normal,
                        color: isSelected ? Colors.black : Colors.white,
                      ),
                    ),
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

class _FilterRow extends ConsumerWidget {
  const _FilterRow({required this.userId});

  final String userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filters = ref.watch(calendarFilterProvider);
    final walletsAsync = ref.watch(walletsControllerProvider);
    final categoriesAsync = ref.watch(categoriesControllerProvider);

    final selectedWallet = walletsAsync.value?.cast<Wallet?>().firstWhere(
      (w) => w?.id == filters.walletId,
      orElse: () => null,
    );

    final selectedCategory = categoriesAsync.value
        ?.cast<Category?>()
        .firstWhere((c) => c?.id == filters.categoryId, orElse: () => null);

    return Row(
      children: [
        Expanded(
          child: _PillButton(
            label: selectedWallet?.name ?? context.l10n.calendarAllWallets,
            selected: filters.walletId != null,
            onTap: () =>
                _showWalletPicker(context, ref, walletsAsync.value ?? []),
            onClear: filters.walletId != null
                ? () => ref.read(calendarFilterProvider.notifier).clearWallet()
                : null,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _PillButton(
            label: selectedCategory?.name ?? context.l10n.calendarAllCategories,
            selected: filters.categoryId != null,
            onTap: () =>
                _showCategoryPicker(context, ref, categoriesAsync.value ?? []),
            onClear: filters.categoryId != null
                ? () =>
                      ref.read(calendarFilterProvider.notifier).clearCategory()
                : null,
          ),
        ),
        const SizedBox(width: 10),
        _RoundIconButton(
          icon: Icons.tune_rounded,
          onTap: () {
            ref.read(calendarFilterProvider.notifier).reset();
          },
        ),
      ],
    );
  }

  void _showWalletPicker(
    BuildContext context,
    WidgetRef ref,
    List<Wallet> wallets,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surface,
      builder: (context) => ListView(
        shrinkWrap: true,
        padding: const EdgeInsets.symmetric(vertical: 20),
        children: [
          ListTile(
            title: Text(
              context.l10n.calendarSelectWalletFilter,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          ...wallets.map(
            (w) => ListTile(
              title: Text(w.name),
              onTap: () {
                ref.read(calendarFilterProvider.notifier).setWallet(w.id);
                Navigator.pop(context);
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showCategoryPicker(
    BuildContext context,
    WidgetRef ref,
    List<Category> categories,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surface,
      builder: (context) => ListView(
        shrinkWrap: true,
        padding: const EdgeInsets.symmetric(vertical: 20),
        children: [
          ListTile(
            title: Text(
              context.l10n.calendarSelectCategoryFilter,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          ...categories.map(
            (c) => ListTile(
              title: Text(c.name),
              onTap: () {
                ref.read(calendarFilterProvider.notifier).setCategory(c.id);
                Navigator.pop(context);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _MonthCalendarCard extends ConsumerWidget {
  const _MonthCalendarCard({required this.monthData, required this.onDayTap});

  final CalendarMonthData monthData;
  final Future<void> Function(DateTime date) onDayTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final weekdayLabels = [
      context.l10n.calendarMon,
      context.l10n.calendarTue,
      context.l10n.calendarWed,
      context.l10n.calendarThu,
      context.l10n.calendarFri,
      context.l10n.calendarSat,
      context.l10n.calendarSun,
    ];

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 16, 14, 12),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppTheme.outline),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.16),
            blurRadius: 26,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: weekdayLabels
                .map(
                  (day) => Expanded(
                    child: Center(
                      child: Text(
                        day,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 10),
          ...monthData.weeks.map(
            (week) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: week
                    .map(
                      (day) => Expanded(
                        child: _CalendarDayCell(
                          day: day,
                          onTap: () => onDayTap(day.date),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CalendarDayCell extends StatelessWidget {
  const _CalendarDayCell({required this.day, required this.onTap});

  final CalendarDayData day;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final accent = AppColor.fromHex(
      day.transactions.isNotEmpty
          ? day.transactions.last.categoryColor ??
                day.transactions.last.walletColor
          : null,
      fallback: AppTheme.amber,
    );

    final double dayExpense = day.transactions
        .where((t) => t.isExpense)
        .fold(0, (sum, t) => sum + t.amount);

    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: day.isCurrentMonth ? onTap : null,
      child: SizedBox(
        height: 72,
        child: Stack(
          alignment: Alignment.topCenter,
          children: [
            if (day.transactions.any((t) => t.isImportant))
              const Positioned(
                top: 2,
                right: 2,
                child: Icon(Icons.star, color: Colors.amber, size: 12),
              ),
            if (day.transactions.isNotEmpty)
              Positioned(
                bottom: 18,
                child: Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: accent,
                  ),
                ),
              ),
            if (dayExpense > 0)
              Positioned(
                bottom: 0,
                child: Text(
                  _formatCompactMoney(dayExpense),
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withValues(alpha: 0.7),
                  ),
                ),
              ),
            Positioned(
              top: 0,
              child: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: day.isToday ? AppTheme.mint : Colors.transparent,
                ),
                child: Center(
                  child: Text(
                    '${day.date.day}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontSize: 12,
                      color: day.isToday
                          ? Colors.white
                          : day.isCurrentMonth
                          ? Colors.white
                          : const Color(0xFF54687B),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _formatCompactMoney(double amount) {
  if (amount >= 1000000) {
    return '${(amount / 1000000).toStringAsFixed(1)}M';
  }
  if (amount >= 1000) {
    return '${(amount / 1000).toStringAsFixed(0)}k';
  }
  return amount.toStringAsFixed(0);
}

class _MonthlySummaryCard extends StatelessWidget {
  const _MonthlySummaryCard({required this.monthData});

  final CalendarMonthData monthData;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: AppTheme.outline),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _MetricBlock(
                  label: context.l10n.calendarMonthlyExpense,
                  value: _formatMoney(monthData.totalExpense, isNegative: true),
                  color: AppTheme.danger,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _MetricBlock(
                  label: context.l10n.calendarMonthlyIncome,
                  value: _formatMoney(monthData.totalIncome, isNegative: false),
                  color: AppTheme.mint,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: Text(
                  monthData.isEmpty
                      ? context.l10n.calendarEmptyMessage
                      : context.l10n.calendarStatsMessage(
                          monthData.transactionCount,
                          monthData.activeDays,
                        ),
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
              const SizedBox(width: 10),
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.mint.withValues(alpha: 0.18),
                ),
                child: Icon(
                  monthData.isEmpty
                      ? Icons.inbox_outlined
                      : Icons.insights_rounded,
                  color: AppTheme.mint,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CalendarErrorState extends StatelessWidget {
  const _CalendarErrorState({required this.error});

  final Object error;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          context.l10n.calendarLoadError(error.toString()),
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      ),
    );
  }
}

class _MetricBlock extends StatelessWidget {
  const _MetricBlock({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceRaised,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.white70,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          SizedBox(
            width: double.infinity,
            height: 32,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                value,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: color,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PillButton extends StatelessWidget {
  const _PillButton({
    required this.label,
    required this.selected,
    required this.onTap,
    this.onClear,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: selected
              ? AppTheme.mint.withValues(alpha: 0.2)
              : AppTheme.surfaceRaised,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected ? AppTheme.mint : AppTheme.outline,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Flexible(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: selected ? AppTheme.mint : Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 4),
            if (selected && onClear != null)
              GestureDetector(
                onTap: () {
                  onClear!();
                },
                child: const Icon(
                  Icons.close_rounded,
                  size: 16,
                  color: AppTheme.mint,
                ),
              )
            else
              Icon(
                Icons.keyboard_arrow_down_rounded,
                size: 18,
                color: selected
                    ? AppTheme.mint
                    : Colors.white.withValues(alpha: 0.9),
              ),
          ],
        ),
      ),
    );
  }
}

class _RoundIconButton extends StatelessWidget {
  const _RoundIconButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Ink(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: AppTheme.surfaceRaised,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.outline),
        ),
        child: Icon(icon, size: 20),
      ),
    );
  }
}

String _formatMoney(double amount, {required bool isNegative}) {
  final formatter = NumberFormat.currency(
    locale: 'vi_VN',
    symbol: '',
    decimalDigits: 0,
  );
  final sign = isNegative ? '-' : '+';
  final formatted = formatter.format(amount).trim();
  return '$sign$formattedđ';
}

String _capitalize(String value) {
  if (value.isEmpty) {
    return value;
  }
  return '${value[0].toUpperCase()}${value.substring(1)}';
}
