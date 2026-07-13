import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../l10n/l10n_extension.dart';
import '../../../../app/app_theme.dart';
import '../../../../core/constants/app_color.dart';
import '../../../profile/application/profile_setup_controller.dart';
import '../../../journal/application/journal_controller.dart';
import '../../../journal/presentation/monthly_recap_screen.dart';
import '../../../journal/presentation/recording_streak_screen.dart';
import '../../../transactions/domain/models/transaction_entry.dart';
import '../../../transactions/domain/models/transaction_mutation_result.dart';
import '../../../transactions/presentation/detail/day_detail_screen.dart';
import '../../../transactions/presentation/detail/transaction_detail_screen.dart';
import '../../../transactions/presentation/detail/transaction_route_args.dart';
import '../../../transactions/presentation/utils/transaction_image_source.dart';
import '../../../friends/presentation/screens/friends_screen.dart';
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
import '../../../../core/preferences/preferences_providers.dart';
import '../../../../shared/utils/currency_formatter.dart';
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
    final profileName = ref
        .watch(currentProfileProvider)
        .value
        ?.fullName
        ?.trim();
    final displayName = profileName?.isNotEmpty == true
        ? profileName!
        : context.l10n.profileUserDefault;
    final visibleMonth = ref.watch(calendarVisibleMonthProvider);
    final monthAsync = ref.watch(calendarMonthProvider(visibleMonth));
    final walletsAsync = ref.watch(walletsControllerProvider);
    final colors = context.moniaryColors;

    return Scaffold(
      backgroundColor: colors.backgroundSoft,
      body: ColoredBox(
        color: colors.backgroundSoft,
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 393),
                      child: Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(22, 9, 22, 17),
                            child: _SeamlessHeader(
                              userName: displayName,
                              onProfileTap: () => _openManager(context),
                              onFriendsTap: () => _openFriendsScreen(context),
                              onRecapTap: () => context.push(
                                MonthlyRecapScreen.routePath,
                                extra: visibleMonth,
                              ),
                              onTransactionTap: _openTransactionDetail,
                              walletsAsync: walletsAsync,
                              monthAsync: monthAsync,
                            ),
                          ),
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
                          const SizedBox(height: 13),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 22),
                            child: _UnifiedFilterRow(
                              isTodaySelected: _isTodayGridMode,
                              onTodayTap: () {
                                setState(() {
                                  _isTodayGridMode = !_isTodayGridMode;
                                });
                              },
                              onResetTap: () {
                                setState(() {
                                  _isTodayGridMode = false;
                                });
                              },
                            ),
                          ),
                          const SizedBox(height: 13),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 28),
                            child: monthAsync.when(
                              data: (monthData) {
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
                                WidgetsBinding.instance.addPostFrameCallback((
                                  _,
                                ) {
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
    final colors = context.moniaryColors;
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      barrierColor: colors.background,
      builder: (context) => const ManageDataSheet(),
    );
  }

  Future<void> _openFriendsScreen(BuildContext context) {
    return context.push(FriendsScreen.routePath);
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
    required this.onFriendsTap,
    required this.onRecapTap,
    required this.onTransactionTap,
    required this.walletsAsync,
    required this.monthAsync,
  });

  final String userName;
  final VoidCallback onProfileTap;
  final VoidCallback onFriendsTap;
  final VoidCallback onRecapTap;
  final Future<void> Function(TransactionEntry transaction) onTransactionTap;
  final AsyncValue<List<Wallet>> walletsAsync;
  final AsyncValue<CalendarMonthData> monthAsync;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isHidden = ref.watch(privacyControllerProvider).isBalancesHidden;
    final streak = ref.watch(recordingStreakProvider).value;
    final colors = context.moniaryColors;
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 2, 0, 0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.l10n.appName.toUpperCase(),
                      style: context.moniaryTypography.metadataStrong.copyWith(
                        color: AppTheme.terracotta,
                        fontSize: 8.5,
                        letterSpacing: 2.1,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: Text(
                            userName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: context.moniaryTypography.displaySmall
                                .copyWith(color: colors.textPrimary),
                          ),
                        ),
                        if (streak != null) ...[
                          const SizedBox(width: 8),
                          _StreakBadge(
                            count: streak.currentDays,
                            onTap: () =>
                                context.push(RecordingStreakScreen.routePath),
                          ),
                        ],
                        const SizedBox(width: 6),
                        _MiniHeaderAction(
                          icon: Icons.auto_stories_outlined,
                          tooltip: context.l10n.journalRecapTitle,
                          onTap: onRecapTap,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _HeaderCircleButton(
                    tooltip: context.l10n.friendsTitle,
                    label: context.l10n.friendsTitle,
                    icon: Icons.people_outline,
                    onTap: onFriendsTap,
                  ),
                  const SizedBox(width: 7),
                  _HeaderCircleButton(
                    tooltip: context.l10n.calendarSearchHint,
                    label: context.l10n.calendarSearchLabel,
                    icon: Icons.search,
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
                  ),
                  const SizedBox(width: 7),
                  _HeaderCircleButton(
                    tooltip: context.l10n.walletTitle,
                    label: context.l10n.calendarWalletsCategoriesAction,
                    icon: Icons.account_balance_wallet_outlined,
                    onTap: onProfileTap,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 28),
          walletsAsync.when(
            data: (wallets) {
              final totalBalance = wallets.fold(
                0.0,
                (sum, w) => sum + w.initialBalance,
              );
              return Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        context.l10n.calendarBalance.toUpperCase(),
                        style: context.moniaryTypography.metadata.copyWith(
                          color: colors.textDim,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(width: 5),
                      _BalanceVisibilityButton(
                        isHidden: isHidden,
                        onTap: () {
                          ref
                              .read(privacyControllerProvider.notifier)
                              .toggleHideBalances(!isHidden);
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ObscurableAmountText(
                    amountText: _formatMoney(
                      context,
                      totalBalance,
                      isNegative: totalBalance < 0,
                      currencyCode: ref.watch(preferredCurrencyProvider),
                    ),
                    style: context.moniaryTypography.displayLarge.copyWith(
                      fontSize: 42,
                      color: colors.textPrimary,
                    ),
                  ),
                ],
              );
            },
            loading: () => const SizedBox(height: 64),
            error: (_, _) => const SizedBox(height: 64),
          ),
          const SizedBox(height: 18),
          monthAsync.when(
            data: (monthData) {
              return Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _IncomeExpensePill(
                    label: context.l10n.calendarIncome,
                    amount: monthData.totalIncome,
                    color: colors.success,
                    icon: Icons.south_west_outlined,
                  ),
                  const SizedBox(width: 10),
                  _IncomeExpensePill(
                    label: context.l10n.calendarExpense,
                    amount: monthData.totalExpense,
                    color: colors.danger,
                    icon: Icons.north_east_outlined,
                  ),
                ],
              );
            },
            loading: () => const SizedBox(height: 30),
            error: (_, _) => const SizedBox(height: 30),
          ),
        ],
      ),
    );
  }
}

class _BalanceVisibilityButton extends StatelessWidget {
  const _BalanceVisibilityButton({required this.isHidden, required this.onTap});

  final bool isHidden;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.moniaryColors;
    return Tooltip(
      message: isHidden
          ? context.l10n.privacyHideBalancesTitle
          : context.l10n.calendarBalance,
      child: Material(
        color: AppTheme.terracotta.withValues(alpha: 0.1),
        shape: CircleBorder(
          side: BorderSide(color: AppTheme.terracotta.withValues(alpha: 0.22)),
        ),
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: SizedBox(
            width: 25,
            height: 25,
            child: Icon(
              isHidden
                  ? Icons.visibility_off_outlined
                  : Icons.visibility_outlined,
              color: colors.primary,
              size: 14,
            ),
          ),
        ),
      ),
    );
  }
}

class _StreakBadge extends StatelessWidget {
  const _StreakBadge({required this.count, required this.onTap});

  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.moniaryColors;
    return Tooltip(
      message: context.l10n.journalStreakTitle,
      child: Material(
        color: AppTheme.terracotta.withValues(alpha: 0.09),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: AppTheme.terracotta.withValues(alpha: 0.18)),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 5),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.local_fire_department_outlined,
                  size: 14,
                  color: AppTheme.terracotta,
                ),
                const SizedBox(width: 3),
                Text(
                  '$count',
                  style: context.moniaryTypography.metadataStrong.copyWith(
                    color: colors.primary,
                    fontSize: 9,
                    letterSpacing: 0,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MiniHeaderAction extends StatelessWidget {
  const _MiniHeaderAction({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.moniaryColors;
    return Tooltip(
      message: tooltip,
      child: Material(
        color: AppTheme.terracotta.withValues(alpha: 0.08),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: AppTheme.terracotta.withValues(alpha: 0.18)),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: SizedBox(
            width: 30,
            height: 28,
            child: Icon(
              icon,
              color: colors.primary.withValues(alpha: 0.9),
              size: 15,
            ),
          ),
        ),
      ),
    );
  }
}

class _HeaderCircleButton extends StatelessWidget {
  const _HeaderCircleButton({
    required this.tooltip,
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String tooltip;
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.moniaryColors;
    final fill = _controlFill(colors);
    final border = _controlBorder(colors);
    return Tooltip(
      message: tooltip,
      child: SizedBox(
        width: 46,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Material(
              color: fill,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: border, width: 1.15),
              ),
              child: InkWell(
                onTap: onTap,
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  width: 38,
                  height: 38,
                  child: Icon(
                    icon,
                    color: colors.textPrimary.withValues(alpha: 0.66),
                    size: 18,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              label.toUpperCase(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: context.moniaryTypography.metadata.copyWith(
                color: colors.textDim,
                fontSize: 7.5,
                letterSpacing: 1.1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _IconPill extends StatelessWidget {
  const _IconPill({
    required this.icon,
    required this.onTap,
    required this.tooltip,
  });

  final IconData icon;
  final VoidCallback onTap;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    final colors = context.moniaryColors;
    final fill = _controlFill(colors);
    final border = _controlBorder(colors);
    return Tooltip(
      message: tooltip,
      child: Material(
        color: fill,
        shape: CircleBorder(side: BorderSide(color: border, width: 1.15)),
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: SizedBox(
            width: 32,
            height: 32,
            child: Icon(
              icon,
              color: colors.textPrimary.withValues(alpha: 0.58),
              size: 16,
            ),
          ),
        ),
      ),
    );
  }
}

class _IncomeExpensePill extends ConsumerWidget {
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
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: color.withValues(alpha: 0.18)),
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
              currencyCode: ref.watch(preferredCurrencyProvider),
            ).replaceAll('+', ''),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
              fontFamily: 'JetBrains Mono',
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
    final title = _monthTitle(context, month);
    final colors = context.moniaryColors;

    return SizedBox(
      height: 39,
      child: Center(
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _IconPill(
                icon: Icons.arrow_back_ios_new_outlined,
                tooltip: MaterialLocalizations.of(context).previousPageTooltip,
                onTap: onPreviousMonth,
              ),
              const SizedBox(width: 12),
              InkWell(
                onTap: () => _showMonthPicker(context),
                borderRadius: BorderRadius.circular(10),
                child: Ink(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 7,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        style: context.moniaryTypography.displaySmall.copyWith(
                          fontSize: 22,
                          color: colors.textPrimary,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.keyboard_arrow_down_outlined,
                        color: colors.textDim,
                        size: 24,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              _IconPill(
                icon: Icons.arrow_forward_ios_outlined,
                tooltip: MaterialLocalizations.of(context).nextPageTooltip,
                onTap: onNextMonth,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _monthTitle(BuildContext context, DateTime month) {
    final locale = Localizations.localeOf(context);
    if (locale.languageCode == 'vi') {
      return 'Tháng ${month.month}, ${month.year}';
    }
    return DateFormat.yMMMM(locale.toString()).format(month);
  }

  void _showMonthPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: context.moniaryColors.backgroundSoft,
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
    final colors = context.moniaryColors;
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
                style: context.moniaryTypography.displaySmall.copyWith(
                  color: colors.textPrimary,
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
                      color: isSelected
                          ? colors.primary.withValues(alpha: 0.14)
                          : colors.surface.withValues(alpha: 0.64),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isSelected ? colors.primary : colors.outline,
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
                        color: isSelected
                            ? colors.primary
                            : colors.textSecondary,
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
    required this.isTodaySelected,
    required this.onTodayTap,
    required this.onResetTap,
  });

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
    final colors = context.moniaryColors;
    final inactiveFill = _controlFill(colors);
    final inactiveBorder = _controlBorder(colors);

    return SizedBox(
      height: 36,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _PillButton(
                    label: context.l10n.calendarAllFilter,
                    selected: isAll,
                    onTap: () =>
                        ref.read(calendarFilterProvider.notifier).reset(),
                    activeColor: colors.textPrimary,
                    activeTextColor: colors.backgroundSoft,
                    inactiveColor: inactiveFill,
                    inactiveBorderColor: inactiveBorder,
                  ),
                  const SizedBox(width: 7),
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
                    activeColor: colors.textPrimary,
                    activeTextColor: colors.backgroundSoft,
                    inactiveColor: inactiveFill,
                    inactiveBorderColor: inactiveBorder,
                  ),
                  const SizedBox(width: 7),
                  _PillButton(
                    label: context.l10n.calendarToday,
                    selected: isTodaySelected,
                    onTap: onTodayTap,
                    activeColor: colors.primary,
                    activeTextColor: colors.backgroundSoft,
                    inactiveColor: inactiveFill,
                    inactiveBorderColor: inactiveBorder,
                  ),
                  const SizedBox(width: 7),
                  _PillButton(
                    label: context.l10n.calendarSaved,
                    selected: filters.isStarredOnly,
                    onTap: () => ref
                        .read(calendarFilterProvider.notifier)
                        .toggleStarredOnly(),
                    activeColor: colors.warning,
                    activeTextColor: colors.textPrimary,
                    inactiveColor: inactiveFill,
                    inactiveBorderColor: inactiveBorder,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 7),
          _RoundIconButton(
            icon: Icons.refresh_outlined,
            tooltip: MaterialLocalizations.of(
              context,
            ).refreshIndicatorSemanticLabel,
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
      backgroundColor: context.moniaryColors.backgroundSoft,
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
    final colors = context.moniaryColors;
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
      padding: const EdgeInsets.fromLTRB(0, 2, 0, 0),
      child: Column(
        children: [
          Row(
            children: weekdayLabels
                .map(
                  (day) => Expanded(
                    child: Center(
                      child: Text(
                        day,
                        style: context.moniaryTypography.metadataStrong
                            .copyWith(
                              fontWeight: FontWeight.w800,
                              color: colors.textDim,
                              fontSize: 9,
                            ),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 9),
          ...monthData.weeks.map(
            (week) => Padding(
              padding: const EdgeInsets.only(bottom: 0),
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
    final colors = context.moniaryColors;
    final dominant = _DominantDayCategory.from(day.transactions, colors);
    final imageTransactions = _calendarImageTransactions(day.transactions);
    final transactionCount = day.transactions.length;
    final hasTransactions = transactionCount > 0;

    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: day.isCurrentMonth ? onTap : null,
      child: SizedBox(
        height: 46,
        child: Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            if (hasTransactions)
              Positioned(
                top: 0,
                child: _CalendarPhotoBlock(
                  day: day,
                  transactions: imageTransactions,
                  transactionCount: transactionCount,
                  accentColor: dominant.color,
                ),
              ),
            if (!hasTransactions)
              Align(
                alignment: Alignment.topCenter,
                child: Padding(
                  padding: const EdgeInsets.only(top: 3),
                  child: DecoratedBox(
                    decoration: day.isToday
                        ? BoxDecoration(
                            border: Border.all(
                              color: colors.primary.withValues(alpha: 0.8),
                              width: 1.2,
                            ),
                            borderRadius: BorderRadius.circular(7),
                          )
                        : const BoxDecoration(),
                    child: SizedBox(
                      width: 30,
                      height: 26,
                      child: Center(
                        child: Text(
                          '${day.date.day}',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                fontSize: 11.5,
                                color: day.isCurrentMonth
                                    ? (day.isToday
                                          ? colors.primary
                                          : colors.textPrimary.withValues(
                                              alpha: 0.46,
                                            ))
                                    : colors.textPrimary.withValues(
                                        alpha: 0.18,
                                      ),
                                fontWeight: day.isToday
                                    ? FontWeight.w800
                                    : FontWeight.w500,
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
    );
  }
}

class _CalendarPhotoBlock extends StatelessWidget {
  const _CalendarPhotoBlock({
    required this.day,
    required this.transactions,
    required this.transactionCount,
    required this.accentColor,
  });

  final CalendarDayData day;
  final List<TransactionEntry> transactions;
  final int transactionCount;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    final colors = context.moniaryColors;
    const size = 42.0;
    final radius = BorderRadius.circular(7);

    return Stack(
      clipBehavior: Clip.none,
      children: [
        if (transactions.length > 1)
          Positioned(
            top: 4,
            left: -4,
            child: _PhotoFrame(
              transaction: transactions[1],
              size: size - 2,
              radius: radius,
              borderColor: accentColor.withValues(alpha: 0.52),
            ),
          ),
        _PhotoFrame(
          transaction: transactions.first,
          size: size,
          radius: radius,
          borderColor: day.isToday ? colors.primary : accentColor,
          borderWidth: day.isToday ? 1.6 : 1.2,
          child: Stack(
            children: [
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: radius,
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        colors.textPrimary.withValues(alpha: 0.56),
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 7,
                bottom: 5,
                child: Text(
                  '${day.date.day}',
                  style: context.moniaryTypography.metadataStrong.copyWith(
                    color: AppTheme.surfaceRaised,
                    fontSize: 10,
                    letterSpacing: 0,
                    shadows: [
                      Shadow(
                        color: colors.textPrimary.withValues(alpha: 0.5),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                ),
              ),
              if (day.hasImportant)
                Positioned(
                  right: 6,
                  bottom: 5,
                  child: Icon(
                    Icons.star_rounded,
                    color: AppTheme.surfaceRaised.withValues(alpha: 0.92),
                    size: 10,
                  ),
                ),
            ],
          ),
        ),
        Positioned(
          top: 4,
          right: 4,
          child: Container(
            constraints: const BoxConstraints(minWidth: 15, minHeight: 15),
            padding: const EdgeInsets.symmetric(horizontal: 3),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Color.lerp(accentColor, colors.textPrimary, 0.25),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: colors.backgroundSoft.withValues(alpha: 0.76),
                width: 1,
              ),
            ),
            child: Text(
              '$transactionCount',
              style: context.moniaryTypography.metadataStrong.copyWith(
                color: _readableTextColor(accentColor),
                fontSize: 7.5,
                letterSpacing: 0,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _PhotoFrame extends StatelessWidget {
  const _PhotoFrame({
    required this.transaction,
    required this.size,
    required this.radius,
    required this.borderColor,
    this.borderWidth = 1.2,
    this.child,
  });

  final TransactionEntry transaction;
  final double size;
  final BorderRadius radius;
  final Color borderColor;
  final double borderWidth;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: radius,
        border: Border.all(color: borderColor, width: borderWidth),
        boxShadow: [
          BoxShadow(
            color: borderColor.withValues(alpha: 0.18),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: Stack(
          fit: StackFit.expand,
          children: [
            SupabaseImage(
              imagePath: transactionImagePathForDisplay(transaction),
              width: size,
              height: size,
              borderRadius: radius,
              fallbackIcon: Icons.receipt_long_outlined,
              fallbackBuilder: (context) => _CalendarAssetFallback(
                assetPath: transactionFallbackAssetPath(transaction),
                size: size,
                fallback: _CalendarReceiptFallback(
                  size: size,
                  accentColor: borderColor,
                ),
              ),
            ),
            ?child,
          ],
        ),
      ),
    );
  }
}

class _CalendarAssetFallback extends StatelessWidget {
  const _CalendarAssetFallback({
    required this.assetPath,
    required this.size,
    required this.fallback,
  });

  final String assetPath;
  final double size;
  final Widget fallback;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      assetPath,
      width: size,
      height: size,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) => fallback,
    );
  }
}

class _CalendarReceiptFallback extends StatelessWidget {
  const _CalendarReceiptFallback({
    required this.size,
    required this.accentColor,
  });

  final double size;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    final colors = context.moniaryColors;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.surfaceRaised,
            Color.lerp(AppTheme.surfaceRaised, accentColor, 0.12)!,
          ],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            left: 8,
            top: 8,
            right: 8,
            bottom: 7,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: colors.backgroundSoft.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: accentColor.withValues(alpha: 0.28),
                  width: 0.8,
                ),
              ),
            ),
          ),
          Positioned(
            left: 11,
            right: 11,
            top: 12,
            child: Container(
              height: 4,
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.78),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Positioned(
            left: 11,
            right: 15,
            top: 20,
            child: _ReceiptFallbackLine(
              color: colors.textPrimary.withValues(alpha: 0.32),
            ),
          ),
          Positioned(
            left: 11,
            right: 18,
            top: 26,
            child: _ReceiptFallbackLine(
              color: colors.textPrimary.withValues(alpha: 0.2),
            ),
          ),
          Positioned(
            left: 11,
            width: 12,
            bottom: 10,
            child: _ReceiptFallbackLine(
              color: accentColor.withValues(alpha: 0.64),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReceiptFallbackLine extends StatelessWidget {
  const _ReceiptFallbackLine({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 2,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(999),
      ),
    );
  }
}

class _DominantDayCategory {
  const _DominantDayCategory({required this.color});

  final Color color;

  static const _fallbackPalette = [
    Color(0xFF7E8CA0),
    Color(0xFF8E9B8F),
    Color(0xFFA98C86),
    Color(0xFFC2A98E),
    Color(0xFF8B7BA7),
    Color(0xFF6F8F95),
  ];

  static _DominantDayCategory from(
    List<TransactionEntry> transactions,
    MoniaryColors colors,
  ) {
    if (transactions.isEmpty) {
      return _DominantDayCategory(color: colors.textDim);
    }

    final totals = <String, double>{};
    final colorsByCategory = <String, String?>{};
    final namesByCategory = <String, String>{};
    for (final transaction in transactions) {
      totals.update(
        transaction.categoryId,
        (value) => value + transaction.amount.abs(),
        ifAbsent: () => transaction.amount.abs(),
      );
      colorsByCategory[transaction.categoryId] = transaction.categoryColor;
      namesByCategory[transaction.categoryId] = transaction.categoryName;
    }

    final dominantId = totals.entries.reduce((a, b) {
      return a.value >= b.value ? a : b;
    }).key;

    final fallback = _fallbackFor(namesByCategory[dominantId] ?? dominantId);
    return _DominantDayCategory(
      color: AppColor.fromHex(colorsByCategory[dominantId], fallback: fallback),
    );
  }

  static Color _fallbackFor(String value) {
    final index = value.hashCode.abs() % _fallbackPalette.length;
    return _fallbackPalette[index];
  }
}

List<TransactionEntry> _calendarImageTransactions(
  List<TransactionEntry> transactions,
) {
  final sorted = List<TransactionEntry>.from(transactions);
  sorted.sort((a, b) {
    final imageComparison = _calendarImagePriority(
      a,
    ).compareTo(_calendarImagePriority(b));
    if (imageComparison != 0) return imageComparison;
    if (a.isImportant != b.isImportant) return b.isImportant ? 1 : -1;
    return b.transactionDate.compareTo(a.transactionDate);
  });
  return sorted;
}

int _calendarImagePriority(TransactionEntry transaction) {
  final imagePath = transaction.imagePath?.trim();
  return imagePath == null || imagePath.isEmpty ? 1 : 0;
}

Color _readableTextColor(Color color) {
  return color.computeLuminance() > 0.42
      ? AppTheme.ink
      : AppTheme.surfaceRaised;
}

Color _controlFill(MoniaryColors colors) {
  return Color.lerp(colors.backgroundSoft, colors.textPrimary, 0.025)!;
}

Color _controlBorder(MoniaryColors colors) {
  return Color.lerp(colors.outline, colors.textPrimary, 0.08)!;
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
    final colors = context.moniaryColors;
    return Material(
      color: selected ? activeColor : inactiveColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: selected ? activeColor : inactiveBorderColor,
          width: 1.15,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 34),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: selected ? activeTextColor : colors.textSecondary,
                    fontSize: 12,
                    fontWeight: selected ? FontWeight.bold : FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RoundIconButton extends StatelessWidget {
  const _RoundIconButton({
    required this.icon,
    required this.onTap,
    required this.tooltip,
  });

  final IconData icon;
  final VoidCallback onTap;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    final colors = context.moniaryColors;
    final fill = _controlFill(colors);
    final border = _controlBorder(colors);
    return Tooltip(
      message: tooltip,
      child: Material(
        color: fill,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: border, width: 1.15),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: SizedBox(
            width: 36,
            height: 36,
            child: Icon(
              icon,
              size: 19,
              color: colors.textPrimary.withValues(alpha: 0.62),
            ),
          ),
        ),
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
  required String currencyCode,
}) {
  final sign = isNegative ? '-' : '+';
  return '$sign${formatCurrency(amount, currencyCode: currencyCode, locale: Localizations.localeOf(context).toString())}';
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
          body: context.l10n.calendarTodayEmptyMessage,
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
