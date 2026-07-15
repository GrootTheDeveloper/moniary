/// Canonical column contract shared by CSV import and CSV/XLSX export.
///
/// The stored keys stay stable for machine-readable files while the visible
/// headers may be localized for people opening the file in Excel or Sheets.
abstract final class SpreadsheetDataFormat {
  static const dataType = 'data_type';
  static const id = 'id';
  static const name = 'name';
  static const type = 'type';
  static const amount = 'amount';
  static const wallet = 'wallet';
  static const category = 'category';
  static const note = 'note';
  static const transactionDate = 'transaction_date';
  static const imagePath = 'image_path';
  static const createdAt = 'created_at';
  static const initialBalance = 'initial_balance';
  static const isDefault = 'is_default';
  static const isActive = 'is_active';

  static const fullColumnKeys = <String>[
    dataType,
    id,
    name,
    type,
    amount,
    wallet,
    category,
    note,
    transactionDate,
    imagePath,
    createdAt,
    initialBalance,
    isDefault,
    isActive,
  ];

  static const requiredTransactionColumns = <String>{
    type,
    amount,
    category,
    transactionDate,
  };

  static const _headerAliases = <String, List<String>>{
    dataType: ['data_type', 'data type', 'loại dữ liệu'],
    id: ['id'],
    name: ['name', 'tên'],
    type: ['type', 'transaction type', 'loại', 'loại giao dịch'],
    amount: ['amount', 'số tiền'],
    wallet: ['wallet', 'ví', 'account', 'ví / tài khoản'],
    category: ['category', 'danh mục', 'hạng mục'],
    note: ['note', 'ghi chú'],
    transactionDate: [
      'transaction_date',
      'transaction date',
      'date',
      'ngày giao dịch',
      'ngày',
    ],
    imagePath: ['image_path', 'image path', 'đường dẫn ảnh'],
    createdAt: ['created_at', 'created at', 'tạo lúc'],
    initialBalance: ['initial_balance', 'initial balance', 'số dư ban đầu'],
    isDefault: ['is_default', 'is default', 'default', 'mặc định'],
    isActive: ['is_active', 'is active', 'active', 'đang dùng'],
  };

  static String? resolveColumn(Object? header) {
    final normalized = _normalizeHeader(header?.toString() ?? '');
    if (normalized.isEmpty) return null;

    for (final entry in _headerAliases.entries) {
      if (entry.value.any((alias) => _normalizeHeader(alias) == normalized)) {
        return entry.key;
      }
    }
    return null;
  }

  static Map<String, int> indexHeaders(List<dynamic> headers) {
    final result = <String, int>{};
    for (var index = 0; index < headers.length; index++) {
      final column = resolveColumn(headers[index]);
      if (column != null) result.putIfAbsent(column, () => index);
    }
    return result;
  }

  static bool looksLikeHeader(Map<String, int> indexes) {
    if (indexes.containsKey(dataType)) return true;
    return indexes.keys.toSet().containsAll(requiredTransactionColumns);
  }

  static bool hasRequiredTransactionColumns(Map<String, int> indexes) {
    return indexes.keys.toSet().containsAll(requiredTransactionColumns);
  }

  static bool isTransactionDataType(Object? value) {
    final normalized = value?.toString().trim().toLowerCase() ?? '';
    return normalized == 'transaction' ||
        normalized == 'transactions' ||
        normalized == 'giao dịch';
  }

  static List<Object?> orderedValues(Map<String, Object?> values) {
    return fullColumnKeys.map((key) => values[key]).toList(growable: false);
  }

  static String _normalizeHeader(String value) {
    return value
        .replaceAll('\uFEFF', '')
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[\s_\-/]+'), '');
  }
}
