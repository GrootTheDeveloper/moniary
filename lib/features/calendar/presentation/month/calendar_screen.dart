import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../l10n/l10n_extension.dart';
import '../../../../app/app_theme.dart';
import '../../../../core/supabase/supabase_providers.dart';
import '../../../transactions/domain/models/transaction_entry.dart';
import '../../../transactions/domain/models/transaction_mutation_result.dart';
import '../../../transactions/presentation/detail/day_detail_screen.dart';
import '../../../transactions/presentation/detail/transaction_detail_screen.dart';
import '../../../transactions/presentation/detail/transaction_route_args.dart';
import '../../../wallets/domain/models/wallet.dart';
import '../../../wallets/application/wallets_controller.dart';
import '../../application/month/calendar_filter_provider.dart';
import '../../application/month/calendar_month_provider.dart';
import '../../application/month/calendar_visible_month_provider.dart';
import '../../domain/month/calendar_month_data.dart';
import 'manage_data_sheet.dart';
import 'transaction_search_delegate.dart';
import '../../../../shared/widgets/supabase_image.dart';
import '../../../../shared/widgets/obscurable_amount_text.dart';
import '../../../../shared/widgets/placeholder_card.dart';
import '../../../../shared/utils/error_helpers.dart';
import '../../../settings/application/privacy_controller.dart';

class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});

  static const routePath = '/calendar';

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  bool _isTodayGridMode = false;

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(currentSessionProvider);
    final userId = session?.user.id ?? '';
    final visibleMonth = ref.watch(calendarVisibleMonthProvider);
    final monthAsync = ref.watch(calendarMonthProvider(visibleMonth));
    final walletsAsync = ref.watch(walletsControllerProvider);

    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF0A1128),
              AppTheme.background,
              AppTheme.background,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                        child: _SeamlessHeader(
                          userName:
                              session?.user.userMetadata?['name'] ?? 'groot',
                          onProfileTap: () => _openManager(context),
                          onTransactionTap: _openTransactionDetail,
                          walletsAsync: walletsAsync,
                          monthAsync: monthAsync,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: _UnifiedFilterRow(
                          userId: userId,
                          isTodaySelected: _isTodayGridMode,
                          onTodayTap: () {
                            setState(() {
                              _isTodayGridMode = true;
                            });
                          },
                          onResetTap: () {
                            setState(() {
                              _isTodayGridMode = false;
                            });
                          },
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (!_isTodayGridMode) ...[
                        _CalendarHeader(
                          month: visibleMonth,
                          onPreviousMonth: () => _changeMonth(-1),
                          onNextMonth: () => _changeMonth(1),
                          onMonthSelect: (date) {
                            ref
                                .read(calendarVisibleMonthProvider.notifier)
                                .setMonth(date);
                          },
                        ),
                        const SizedBox(height: 8),
                      ],
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: monthAsync.when(
                          data: (monthData) {
                            if (monthData.isEmpty) {
                              return Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 24,
                                ),
                                child: PlaceholderCard(
                                  title: context.l10n.calendarTitle,
                                  body: context.l10n.calendarEmptyMessage,
                                ),
                              );
                            }
                            if (_isTodayGridMode) {
                              return _TodayGrid(
                                monthData: monthData,
                                onTransactionTap: _openDayDetail,
                              );
                            }
                            return _MonthCalendarCard(
                              monthData: monthData,
                              onDayTap: _openDayDetail,
                            );
                          },
                          loading: () => const SizedBox(height: 200),
                          error: (error, stackTrace) {
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      userFriendlyMessage(context, error),
                                    ),
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              }
                            });
                            return Center(
                              child: PlaceholderCard(
                                title: context.l10n.errorGeneric,
                                body: userFriendlyMessage(context, error),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 120),
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

  void _changeMonth(int offset) {
    ref.read(calendarVisibleMonthProvider.notifier).changeMonth(offset);
  }

  Future<void> _openManager(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
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

  Future<void> _openTransactionDetail(TransactionEntry transaction) async {
    final result = await context.push<TransactionMutationResult>(
      TransactionDetailScreen.routePath,
      extra: TransactionDetailRouteArgs(
        transaction: transaction,
        day: transaction.transactionDate,
      ),
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

class _SeamlessHeader extends ConsumerWidget {
  const _SeamlessHeader({
    required this.userName,
    required this.onProfileTap,
    required this.onTransactionTap,
    required this.walletsAsync,
    required this.monthAsync,
  });

  final String userName;
  final VoidCallback onProfileTap;
  final Future<void> Function(TransactionEntry transaction) onTransactionTap;
  final AsyncValue<List<Wallet>> walletsAsync;
  final AsyncValue<CalendarMonthData> monthAsync;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isHidden = ref.watch(privacyControllerProvider).isBalancesHidden;
    return Column(
      children: [
        // Row 1: Greeting & Avatar
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.l10n.appName,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: Colors.white54),
                ),
                Text(
                  userName.isEmpty ? 'User' : userName,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            Row(
              children: [
                GestureDetector(
                  onTap: () {
                    ref
                        .read(privacyControllerProvider.notifier)
                        .toggleHideBalances(!isHidden);
                  },
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isHidden
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      color: Colors.white70,
                      size: 20,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () async {
                    final transaction = await showSearch<TransactionEntry?>(
                      context: context,
                      delegate: TransactionSearchDelegate(
                        ref: ref,
                        searchFieldLabelText: context.l10n.calendarSearchHint,
                      ),
                    );
                    if (transaction == null || !context.mounted) {
                      return;
                    }
                    await onTransactionTap(transaction);
                  },
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.search,
                      color: Colors.white70,
                      size: 20,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: onProfileTap,
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.account_balance_wallet_outlined,
                      color: Colors.white70,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),
        // Row 2: Total Balance (Huge & Centered)
        walletsAsync.when(
          data: (wallets) {
            final totalBalance = wallets.fold(
              0.0,
              (sum, w) => sum + w.initialBalance,
            );
            return Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  context.l10n.calendarBalance,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.white54,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                ObscurableAmountText(
                  amountText: _formatMoney(
                    context,
                    totalBalance,
                    isNegative: totalBalance < 0,
                  ),
                  style: Theme.of(context).textTheme.displaySmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 36,
                    letterSpacing: -1,
                  ),
                ),
              ],
            );
          },
          loading: () => const SizedBox(height: 60),
          error: (_, _) => const SizedBox(height: 60),
        ),
        const SizedBox(height: 12),
        // Row 3: Income & Expense (Pills)
        monthAsync.when(
          data: (monthData) {
            return Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _IncomeExpensePill(
                  label: context.l10n.calendarIncome,
                  amount: monthData.totalIncome,
                  color: AppTheme.mint,
                  icon: Icons.arrow_downward_outlined,
                ),
                const SizedBox(width: 12),
                _IncomeExpensePill(
                  label: context.l10n.calendarExpense,
                  amount: monthData.totalExpense,
                  color: Colors.redAccent,
                  icon: Icons.arrow_upward_outlined,
                ),
              ],
            );
          },
          loading: () => const SizedBox(height: 30),
          error: (_, _) => const SizedBox(height: 30),
        ),
      ],
    );
  }
}

class _IncomeExpensePill extends StatelessWidget {
  const _IncomeExpensePill({
    required this.label,
    required this.amount,
    required this.color,
    required this.icon,
  });

  final String label;
  final double amount;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 6),
          ObscurableAmountText(
            prefixText: '$label: ',
            amountText: _formatMoney(
              context,
              amount,
              isNegative: false,
            ).replaceAll('+', ''),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _CalendarHeader extends StatelessWidget {
  const _CalendarHeader({
    required this.month,
    required this.onPreviousMonth,
    required this.onNextMonth,
    required this.onMonthSelect,
  });

  final DateTime month;
  final VoidCallback onPreviousMonth;
  final VoidCallback onNextMonth;
  final ValueChanged<DateTime> onMonthSelect;

  @override
  Widget build(BuildContext context) {
    final localeName = Localizations.localeOf(context).toString();
    final label = DateFormat.MMMM(localeName).format(month);
    final title = '${label.toLowerCase()} ${month.year}';

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_outlined,
            color: AppTheme.mint,
            size: 16,
          ),
          onPressed: onPreviousMonth,
        ),
        const SizedBox(width: 24),
        InkWell(
          onTap: () => _showMonthPicker(context),
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(
                  Icons.keyboard_arrow_down_outlined,
                  color: Colors.white70,
                  size: 24,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 24),
        IconButton(
          icon: const Icon(
            Icons.arrow_forward_ios_outlined,
            color: AppTheme.mint,
            size: 16,
          ),
          onPressed: onNextMonth,
        ),
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

class _UnifiedFilterRow extends ConsumerWidget {
  const _UnifiedFilterRow({
    required this.userId,
    required this.isTodaySelected,
    required this.onTodayTap,
    required this.onResetTap,
  });

  final String userId;
  final bool isTodaySelected;
  final VoidCallback onTodayTap;
  final VoidCallback onResetTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filters = ref.watch(calendarFilterProvider);
    final walletsAsync = ref.watch(walletsControllerProvider);
    final selectedWallet = walletsAsync.value?.cast<Wallet?>().firstWhere(
      (w) => w?.id == filters.walletId,
      orElse: () => null,
    );
    final isAll = filters.walletId == null && filters.categoryId == null;

    return SizedBox(
      height: 38,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _PillButton(
                    label: context.l10n.calendarAllWallets,
                    selected: isAll,
                    onTap: () =>
                        ref.read(calendarFilterProvider.notifier).reset(),
                    activeColor: AppTheme.mint.withValues(alpha: 0.2),
                    activeTextColor: AppTheme.mint,
                    inactiveColor: Colors.transparent,
                    inactiveBorderColor: Colors.white10,
                  ),
                  const SizedBox(width: 8),
                  _PillButton(
                    label: selectedWallet != null
                        ? selectedWallet.name
                        : context.l10n.transactionWallet,
                    selected: filters.walletId != null,
                    onTap: () => _showWalletPicker(
                      context,
                      ref,
                      walletsAsync.value ?? [],
                    ),
                    activeColor: AppTheme.mint.withValues(alpha: 0.2),
                    activeTextColor: AppTheme.mint,
                    inactiveColor: Colors.transparent,
                    inactiveBorderColor: Colors.white10,
                  ),
                  const SizedBox(width: 8),
                  _PillButton(
                    label: context.l10n.calendarToday,
                    selected: isTodaySelected,
                    onTap: onTodayTap,
                    activeColor: AppTheme.mint.withValues(alpha: 0.2),
                    activeTextColor: AppTheme.mint,
                    inactiveColor: Colors.transparent,
                    inactiveBorderColor: Colors.white10,
                  ),
                  const SizedBox(width: 8),
                  _PillButton(
                    label: context.l10n.calendarStarred,
                    selected: filters.isStarredOnly,
                    onTap: () => ref
                        .read(calendarFilterProvider.notifier)
                        .toggleStarredOnly(),
                    activeColor: Colors.amber.withValues(alpha: 0.2),
                    activeTextColor: Colors.amber,
                    inactiveColor: Colors.transparent,
                    inactiveBorderColor: Colors.white10,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          _RoundIconButton(
            icon: Icons.refresh_outlined,
            onTap: () {
              onResetTap();
              // Reset filters (Wallet/Category)
              ref.read(calendarFilterProvider.notifier).reset();

              // Reset calendar view to current month
              final now = DateTime.now();
              ref
                  .read(calendarVisibleMonthProvider.notifier)
                  .setMonth(DateTime(now.year, now.month, 1));
            },
          ),
        ],
      ),
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
      padding: const EdgeInsets.fromLTRB(10, 12, 10, 8),
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
                          fontWeight: FontWeight.w500,
                          color:
                              Colors.white54, // Dimmer text for weekday headers
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 8),
          ...monthData.weeks.map(
            (week) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
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
    final images = day.transactions
        .where((t) => t.imagePath != null && t.imagePath!.isNotEmpty)
        .toList()
        .reversed
        .toList();

    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: day.isCurrentMonth ? onTap : null,
      child: SizedBox(
        height: 60,
        child: Stack(
          alignment: Alignment.topCenter,
          clipBehavior: Clip.none,
          children: [
            // Always show placeholder circle for current month
            if (day.isCurrentMonth)
              Positioned(
                top: 4,
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(
                      alpha: 0.05,
                    ), // Subtle placeholder
                    shape: BoxShape.circle,
                  ),
                ),
              ),

            // If there's an image, place it at the very top (over the placeholder).
            if (images.isNotEmpty)
              Positioned(
                top: 4,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    // Background image (if more than 1)
                    if (images.length > 1)
                      Positioned(
                        top: 3,
                        left: -4,
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Colors.orange,
                              width: 1.5,
                            ),
                          ),
                          child: SupabaseImage(
                            imagePath: images[1].imagePath,
                            width: 28,
                            height: 28,
                            borderRadius: BorderRadius.circular(6.5),
                          ),
                        ),
                      ),

                    // Main foreground image
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.orange, width: 1.5),
                      ),
                      child: SupabaseImage(
                        imagePath: images[0].imagePath,
                        width: 28,
                        height: 28,
                        borderRadius: BorderRadius.circular(6.5),
                      ),
                    ),

                    // Badge (+1, +2)
                    if (images.length > 1)
                      Positioned(
                        top: -6,
                        right: -6,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.orange,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: AppTheme.surface,
                              width: 1.5,
                            ),
                          ),
                          child: Text(
                            '+${images.length - 1}',
                            style: const TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),

            // Day Number (Always consistently placed below the placeholder)
            Positioned(
              top: 36,
              child: SizedBox(
                width: 22,
                height: 22,
                child: Center(
                  child: Text(
                    '${day.date.day}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontSize: 13,
                      color: day.isCurrentMonth
                          ? (day.isToday
                                ? AppTheme.mint
                                : Colors
                                      .white) // Highlight number mint if today
                          : Colors.white24, // Dimmer for non-current month
                      fontWeight: day.isToday
                          ? FontWeight.w900
                          : FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),

            // Dot Indicator at the bottom for TODAY
            if (day.isToday)
              Positioned(
                bottom: 4,
                child: Container(
                  width: 4,
                  height: 4,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppTheme.mint, // Dot indicates today
                  ),
                ),
              ),

            // Star Indicator for Important Transactions
            if (day.hasImportant)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.amber.withValues(alpha: 0.15),
                        blurRadius: 12,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                ),
              ),

            if (day.hasImportant)
              Positioned(
                top: 2,
                right: 2,
                child: const Icon(Icons.star, color: AppTheme.amber, size: 10),
              ),
          ],
        ),
      ),
    );
  }
}

class _PillButton extends StatelessWidget {
  const _PillButton({
    required this.label,
    required this.selected,
    required this.onTap,
    this.activeColor = AppTheme.mint,
    this.activeTextColor = Colors.black,
    this.inactiveColor = Colors.transparent,
    this.inactiveBorderColor = Colors.white10,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Color activeColor;
  final Color activeTextColor;
  final Color inactiveColor;
  final Color inactiveBorderColor;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? activeColor : inactiveColor,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: selected ? activeColor : inactiveBorderColor,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: selected ? activeTextColor : Colors.white70,
                fontSize: 14,
                fontWeight: selected ? FontWeight.bold : FontWeight.w500,
              ),
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

class _CalendarSkeletonCard extends StatefulWidget {
  const _CalendarSkeletonCard();

  @override
  State<_CalendarSkeletonCard> createState() => _CalendarSkeletonCardState();
}

class _CalendarSkeletonCardState extends State<_CalendarSkeletonCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween<double>(begin: 0.4, end: 0.9).animate(_controller),
      child: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(14, 16, 14, 12),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: AppTheme.outline),
              ),
              child: Column(
                children: [
                  Row(
                    children: List.generate(
                      7,
                      (index) => Expanded(
                        child: Center(
                          child: Container(
                            width: 24,
                            height: 14,
                            decoration: BoxDecoration(
                              color: Colors.white24,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  ...List.generate(
                    6,
                    (week) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: List.generate(
                          7,
                          (day) => Expanded(
                            child: Container(
                              height: 72,
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.05),
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _formatMoney(
  BuildContext context,
  double amount, {
  required bool isNegative,
}) {
  final formatter = NumberFormat.currency(
    locale: Localizations.localeOf(context).toString(),
    symbol: '',
    decimalDigits: 0,
  );
  final sign = isNegative ? '-' : '+';
  final formatted = formatter.format(amount).trim();
  return '$sign$formatted${context.l10n.transactionAmountSuffix}';
}

class _TodayGrid extends StatelessWidget {
  const _TodayGrid({required this.monthData, required this.onTransactionTap});
  final CalendarMonthData monthData;
  final ValueChanged<DateTime> onTransactionTap;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    // Find today's data from monthData
    final todayData = monthData.weeks
        .expand((week) => week)
        .firstWhere(
          (d) =>
              d.date.year == now.year &&
              d.date.month == now.month &&
              d.date.day == now.day,
          orElse: () => CalendarDayData(
            date: now,
            isCurrentMonth: true,
            transactions: [],
          ),
        );

    final transactions = todayData.transactions;

    if (transactions.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: PlaceholderCard(
          title: context.l10n.calendarToday,
          body: context.l10n.calendarEmptyMessage,
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.only(top: 8),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: transactions.length,
      itemBuilder: (context, index) {
        final transaction = transactions[index];
        return TransactionGridTile(
              transaction: transaction,
              onTap: () => onTransactionTap(now),
            )
            .animate(delay: (30 * index).ms)
            .fade()
            .slideY(
              begin: 0.1,
              end: 0,
              curve: Curves.easeOutQuad,
              duration: 300.ms,
            );
      },
    );
  }
}
