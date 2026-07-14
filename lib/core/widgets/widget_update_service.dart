import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:home_widget/home_widget.dart';

import '../../l10n/gen_l10n/app_localizations.dart';

import '../../features/journal/application/journal_controller.dart';
import '../../features/categories/domain/models/category.dart';
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

  /// Fetch latest real data from database and update iOS Home Screen Widget
  Future<void> updateWidget() async {
    // Skip if running inside unit/widget tests where platform channels are not mocked
    if (Platform.environment.containsKey('FLUTTER_TEST')) {
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

      final streak = _ref.read(recordingStreakProvider).whenOrNull(
        data: (s) => s.currentDays,
      ) ?? 0;

      // 4. Retrieve preferred user currency and locale
      final currencyCode = _ref.read(preferredCurrencyProvider);
      final locale = _ref.read(preferredLocaleProvider);

      final l10n = lookupAppLocalizations(Locale(locale));
      final labelBalance = l10n.widgetTotalBalance;
      final labelSpending = l10n.widgetTodaySpending;
      final labelQuickAdd = l10n.widgetQuickAdd;
      final labelScanReceipt = l10n.widgetScanReceipt;

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

      // 5. Save formatted data & labels to shared preferences (App Group)
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
      await HomeWidget.saveWidgetData<int>(
        'recording_streak',
        streak,
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
