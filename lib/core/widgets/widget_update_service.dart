import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:home_widget/home_widget.dart';

import '../../l10n/gen_l10n/app_localizations.dart';

import 'dart:convert';
import '../../features/journal/application/journal_controller.dart';
import '../../features/categories/domain/models/category.dart';
import '../../features/budgets/application/budget_controller.dart';
import '../../features/profile/application/profile_setup_controller.dart';
import '../../features/transactions/data/repositories/transaction_repository.dart';
import '../../features/wallets/data/repositories/wallet_repository.dart';
import '../preferences/preferences_providers.dart';
import '../../shared/utils/currency_formatter.dart';
import '../../shared/utils/app_logger.dart';

final widgetUpdateServiceProvider = Provider<WidgetUpdateService>((ref) {
  final service = WidgetUpdateService(ref);

  // Auto-update widget dynamically whenever locale or preferred currency changes
  ref.listen<String>(preferredLocaleProvider, (prev, next) {
    service.updateWidget().ignore();
  });
  ref.listen<String>(preferredCurrencyProvider, (prev, next) {
    service.updateWidget().ignore();
  });

  return service;
});

class WidgetUpdateService {
  WidgetUpdateService(this._ref);

  final Ref _ref;

  static const _appGroupId = 'group.com.moniary';
  static const _iOSWidgetName = 'MoniaryWidget';

  /// Fetch latest real data from database and update the iOS Home Screen Widget.
  Future<void> updateWidget() async {
    // Skip if running inside unit/widget tests without platform channel handlers.
    if (Platform.environment.containsKey('FLUTTER_TEST')) {
      return;
    }

    // This project currently ships only the iOS Widget Extension. Android does
    // not define an AppWidgetProvider, so calling HomeWidget.updateWidget there
    // makes the plugin look for `com.moniary.moniary.null`.
    if (!Platform.isIOS) {
      return;
    }

    try {
      // 1. Configure App Group for shared preferences
      await HomeWidget.setAppGroupId(_appGroupId);

      // 2. Fetch all wallets directly from repository to ensure fresh real data
      final wallets = await _ref.read(walletRepositoryProvider).fetchWallets();
      final totalBalance = wallets
          .where((w) => w.isActive)
          .fold(0.0, (sum, w) => sum + w.initialBalance);

      // 3. Fetch today's transactions directly from repository
      final today = DateTime.now();
      final transactions = await _ref
          .read(transactionRepositoryProvider)
          .fetchTransactionsForDay(today);

      final todaySpending = transactions
          .where((t) => t.type == TransactionType.expense)
          .fold(0.0, (sum, t) => sum + t.amount);

      // Retrieve streak days, longest streak, and active days list
      final streakData = _ref.read(recordingStreakProvider).asData?.value;
      final streak = streakData?.currentDays ?? 0;
      final longestStreak = streakData?.longestDays ?? 0;
      final recordedDays = streakData?.recordedDays ?? const <DateTime>{};
      final recordedDaysList = recordedDays
          .map(
            (d) =>
                "${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}",
          )
          .toList();
      final recordedDaysJson = jsonEncode(recordedDaysList);

      // Retrieve user profile name
      final profile = _ref.read(currentProfileProvider).asData?.value;
      final userName = profile?.fullName ?? '';

      // Retrieve budget metrics
      final now = DateTime.now();
      final budgetVal = _ref
          .read(monthlyBudgetProvider(DateTime(now.year, now.month)))
          .asData
          ?.value;
      final budgetLimit = budgetVal?.totalLimit ?? 0.0;
      final budgetSpent = budgetVal?.totalSpent ?? 0.0;
      final budgetRemaining = (budgetLimit - budgetSpent).clamp(
        0.0,
        double.infinity,
      );
      final budgetProgress = budgetVal?.progress ?? 0.0;

      // 4. Retrieve preferred user currency and locale
      final currencyCode = _ref.read(preferredCurrencyProvider);
      final locale = _ref.read(preferredLocaleProvider);

      final l10n = lookupAppLocalizations(Locale(locale));
      final labelBalance = l10n.widgetTotalBalance;
      final labelSpending = l10n.widgetTodaySpending;
      final labelQuickAdd = l10n.widgetQuickAdd;
      final labelScanReceipt = l10n.widgetScanReceipt;

      final labelStreak = l10n.widgetStreakTitle;
      final labelLongest = l10n.widgetLongestStreak;
      final labelDays = l10n.widgetDays(streak);
      final labelLongestDays = l10n.widgetDays(longestStreak);
      final labelBudget = l10n.widgetBudgetTitle;
      final labelBudgetSpent = l10n.widgetBudgetSpent;
      final labelBudgetRemaining = l10n.widgetBudgetRemaining;
      final labelOverBudget = l10n.widgetOverBudget;

      final formattedBalance = formatCurrency(
        totalBalance,
        currencyCode: currencyCode,
        locale: locale.toString(),
      );

      final formattedSpending = formatCurrency(
        todaySpending,
        currencyCode: currencyCode,
        locale: locale.toString(),
      );

      final formattedBudgetLimit = formatCurrency(
        budgetLimit,
        currencyCode: currencyCode,
        locale: locale.toString(),
      );

      final formattedBudgetSpent = formatCurrency(
        budgetSpent,
        currencyCode: currencyCode,
        locale: locale.toString(),
      );

      final formattedBudgetRemaining = formatCurrency(
        budgetRemaining,
        currencyCode: currencyCode,
        locale: locale.toString(),
      );

      // 5. Save formatted data & labels to shared preferences (App Group)
      await HomeWidget.saveWidgetData<String>('user_name', userName);
      await HomeWidget.saveWidgetData<String>(
        'total_balance',
        formattedBalance,
      );
      await HomeWidget.saveWidgetData<String>(
        'today_spending',
        formattedSpending,
      );
      await HomeWidget.saveWidgetData<String>(
        'total_balance_label',
        labelBalance,
      );
      await HomeWidget.saveWidgetData<String>(
        'today_spending_label',
        labelSpending,
      );
      await HomeWidget.saveWidgetData<String>('quick_add_label', labelQuickAdd);
      await HomeWidget.saveWidgetData<String>(
        'scan_receipt_label',
        labelScanReceipt,
      );

      await HomeWidget.saveWidgetData<int>('recording_streak', streak);
      await HomeWidget.saveWidgetData<int>('longest_streak', longestStreak);
      await HomeWidget.saveWidgetData<String>(
        'recorded_days_json',
        recordedDaysJson,
      );

      await HomeWidget.saveWidgetData<String>(
        'budget_limit',
        formattedBudgetLimit,
      );
      await HomeWidget.saveWidgetData<String>(
        'budget_spent',
        formattedBudgetSpent,
      );
      await HomeWidget.saveWidgetData<String>(
        'budget_remaining',
        formattedBudgetRemaining,
      );
      await HomeWidget.saveWidgetData<double>(
        'budget_progress',
        budgetProgress,
      );

      await HomeWidget.saveWidgetData<String>('label_streak', labelStreak);
      await HomeWidget.saveWidgetData<String>('label_longest', labelLongest);
      await HomeWidget.saveWidgetData<String>('label_days', labelDays);
      await HomeWidget.saveWidgetData<String>(
        'label_longest_days',
        labelLongestDays,
      );
      await HomeWidget.saveWidgetData<String>('label_budget', labelBudget);
      await HomeWidget.saveWidgetData<String>(
        'label_budget_spent',
        labelBudgetSpent,
      );
      await HomeWidget.saveWidgetData<String>(
        'label_budget_remaining',
        labelBudgetRemaining,
      );
      await HomeWidget.saveWidgetData<String>(
        'label_over_budget',
        labelOverBudget,
      );

      // 6. Request Widget Extension timeline reload
      await HomeWidget.updateWidget(iOSName: _iOSWidgetName);

      AppLogger.info(
        'iOS Widget updated successfully. Balance: $formattedBalance, Spend: $formattedSpending',
      );
    } catch (error, stackTrace) {
      AppLogger.error(
        'Failed to update iOS Home Screen Widget',
        error,
        stackTrace,
      );
    }
  }
}
