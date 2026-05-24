enum WalletType { cash, bank, ewallet, credit, other }

extension WalletTypeX on WalletType {
  String get value => switch (this) {
        WalletType.cash => 'cash',
        WalletType.bank => 'bank',
        WalletType.ewallet => 'ewallet',
        WalletType.credit => 'credit',
        WalletType.other => 'other',
      };

  String get label => switch (this) {
        WalletType.cash => 'Tiền mặt',
        WalletType.bank => 'Ngân hàng',
        WalletType.ewallet => 'Ví điện tử',
        WalletType.credit => 'Thẻ tín dụng',
        WalletType.other => 'Khác',
      };

  static WalletType fromValue(String value) {
    return WalletType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => WalletType.other,
    );
  }
}

class Wallet {
  const Wallet({
    required this.id,
    required this.name,
    required this.type,
    required this.icon,
    required this.color,
    required this.initialBalance,
    required this.isDefault,
    required this.isActive,
    required this.createdAt,
  });

  final String id;
  final String name;
  final WalletType type;
  final String? icon;
  final String? color;
  final double initialBalance;
  final bool isDefault;
  final bool isActive;
  final DateTime createdAt;

  factory Wallet.fromMap(Map<String, dynamic> map) {
    return Wallet(
      id: map['id'] as String,
      name: map['name'] as String,
      type: WalletTypeX.fromValue(map['type'] as String),
      icon: map['icon'] as String?,
      color: map['color'] as String?,
      initialBalance: (map['initial_balance'] as num).toDouble(),
      isDefault: map['is_default'] as bool? ?? false,
      isActive: map['is_active'] as bool? ?? true,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}

