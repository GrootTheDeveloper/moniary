enum TransactionType { income, expense }

extension TransactionTypeX on TransactionType {
  String get value => switch (this) {
    TransactionType.income => 'income',
    TransactionType.expense => 'expense',
  };

  String get label => switch (this) {
    TransactionType.income => 'Thu',
    TransactionType.expense => 'Chi',
  };

  static TransactionType fromValue(String value) {
    return TransactionType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => TransactionType.expense,
    );
  }
}

class Category {
  const Category({
    required this.id,
    required this.name,
    required this.type,
    required this.icon,
    required this.color,
    required this.isDefault,
    required this.isActive,
    required this.createdAt,
  });

  final String id;
  final String name;
  final TransactionType type;
  final String? icon;
  final String? color;
  final bool isDefault;
  final bool isActive;
  final DateTime createdAt;

  factory Category.fromMap(Map<String, dynamic> map) {
    return Category(
      id: map['id'] as String,
      name: map['name'] as String,
      type: TransactionTypeX.fromValue(map['type'] as String),
      icon: map['icon'] as String?,
      color: map['color'] as String?,
      isDefault: map['is_default'] as bool? ?? false,
      isActive: map['is_active'] as bool? ?? true,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}
