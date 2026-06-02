import 'package:flutter/widgets.dart';

import '../../../../l10n/l10n_extension.dart';
import '../../domain/export/export_filters.dart';

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
