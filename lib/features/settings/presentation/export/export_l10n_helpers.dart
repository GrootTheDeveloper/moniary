import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';

import '../../../../l10n/l10n_extension.dart';
import '../../domain/export/export_file_text.dart';
import '../../domain/export/export_filters.dart';
import '../../domain/export/export_history_entry.dart';

extension ExportDataTypeL10n on ExportDataType {
  String getLabel(BuildContext context) {
    return switch (this) {
      ExportDataType.transactions => context.l10n.exportDataTypeTransactions,
      ExportDataType.wallets => context.l10n.exportDataTypeWallets,
      ExportDataType.categories => context.l10n.exportDataTypeCategories,
    };
  }
}

ExportFileText buildExportFileText(BuildContext context) {
  return ExportFileText(
    xlsxSheetName: context.l10n.exportSheetTransactions,
    xlsxHeaders: [
      context.l10n.exportColumnDataType,
      context.l10n.exportColumnId,
      context.l10n.exportColumnName,
      context.l10n.transactionType,
      context.l10n.transactionAmount,
      context.l10n.transactionWallet,
      context.l10n.transactionCategory,
      context.l10n.transactionNote,
      context.l10n.transactionDate,
      context.l10n.exportColumnImagePath,
      context.l10n.exportColumnCreatedAt,
      context.l10n.walletInitialBalance,
      context.l10n.walletDefault,
      context.l10n.walletActive,
    ],
    pdfTitle: context.l10n.exportDetailReportSubtitle,
    pdfGeneratedAtLabel: context.l10n.exportReportGeneratedAt,
    pdfDataTypesLabel: context.l10n.exportDataTypes,
    pdfTransactionsLabel: context.l10n.exportDataTypeTransactions,
    pdfWalletsLabel: context.l10n.exportDataTypeWallets,
    pdfCategoriesLabel: context.l10n.exportDataTypeCategories,
    pdfIncomeTotalLabel: context.l10n.statsTotalIncome,
    pdfExpenseTotalLabel: context.l10n.statsTotalExpense,
    pdfRecentTransactionsLabel: context.l10n.exportReportRecentTransactions,
    pdfIncomeTypeLabel: context.l10n.categoryIncome,
    pdfExpenseTypeLabel: context.l10n.categoryExpense,
    dataTypeLabels: {
      ExportDataType.transactions: context.l10n.exportDataTypeTransactions,
      ExportDataType.wallets: context.l10n.exportDataTypeWallets,
      ExportDataType.categories: context.l10n.exportDataTypeCategories,
    },
  );
}

String localizedExportDataTypeKey(BuildContext context, String value) {
  return switch (value) {
    'transactions' || 'Giao dịch' => context.l10n.exportDataTypeTransactions,
    'wallets' || 'Ví' => context.l10n.exportDataTypeWallets,
    'categories' || 'Danh mục' => context.l10n.exportDataTypeCategories,
    _ => value,
  };
}

String localizedExportDataTypeList(
  BuildContext context,
  Iterable<String> keys,
) {
  return keys.map((key) => localizedExportDataTypeKey(context, key)).join(', ');
}

String localizedExportDateRange(
  BuildContext context,
  ExportHistoryEntry entry,
) {
  if (entry.hasDateRange) {
    final start = _dateLabel(entry.startDate);
    final end = _dateLabel(entry.endDate);
    return '$start - $end';
  }

  final legacy = entry.legacyDateRange?.trim();
  if (legacy == null || legacy.isEmpty) {
    return context.l10n.exportAllTime;
  }

  return switch (legacy) {
    'Tất cả thời gian' ||
    'Táº¥t cáº£ thá»i gian' => context.l10n.exportAllTime,
    _ => legacy,
  };
}

String _dateLabel(DateTime? date) {
  if (date == null) {
    return '...';
  }
  return DateFormat('dd/MM/yyyy').format(date);
}
