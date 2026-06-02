import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';

import '../../../../l10n/l10n_extension.dart';
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
