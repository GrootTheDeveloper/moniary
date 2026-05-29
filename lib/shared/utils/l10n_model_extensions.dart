import 'package:flutter/widgets.dart';

import '../../features/categories/domain/models/category.dart';
import '../../features/groups/data/group_expense_validation_service.dart';
import '../../features/scanning/application/scanning_controller.dart';
import '../../features/wallets/domain/models/wallet.dart';
import '../../l10n/l10n_extension.dart';

extension TransactionTypeL10n on TransactionType {
  String getLabel(BuildContext context) {
    switch (this) {
      case TransactionType.income:
        return context.l10n.calendarIncome;
      case TransactionType.expense:
        return context.l10n.calendarExpense;
    }
  }
}

extension WalletTypeL10n on WalletType {
  String getLabel(BuildContext context) {
    final l10n = context.l10n;
    switch (this) {
      case WalletType.cash:
        return l10n.walletTypeCash;
      case WalletType.bank:
        return l10n.walletTypeBank;
      case WalletType.ewallet:
        return l10n.walletTypeEwallet;
      case WalletType.credit:
        return l10n.walletTypeCredit;
      case WalletType.other:
        return l10n.walletTypeOther;
    }
  }
}

extension ScanningErrorL10n on ScanningError {
  String getLabel(BuildContext context) {
    switch (this) {
      case ScanningError.imageSelect:
        return context.l10n.scanImageSelectError;
      case ScanningError.imageRequired:
        return context.l10n.scanImageRequiredError;
      case ScanningError.ocrFailed:
        return context.l10n.scanReadError;
    }
  }
}

extension SplitMethodL10n on SplitMethod {
  String getLabel(BuildContext context) {
    switch (this) {
      case SplitMethod.equal:
        return context.l10n.expenseSplitEqual;
      case SplitMethod.manual:
        return context.l10n.expenseSplitManual;
    }
  }
}
