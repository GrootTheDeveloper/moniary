enum BankConnectionStatus { pending, connected, error, revoked }

extension BankConnectionStatusX on BankConnectionStatus {
  String get value => switch (this) {
    BankConnectionStatus.pending => 'pending',
    BankConnectionStatus.connected => 'connected',
    BankConnectionStatus.error => 'error',
    BankConnectionStatus.revoked => 'revoked',
  };

  static BankConnectionStatus fromValue(String value) {
    return BankConnectionStatus.values.firstWhere(
      (status) => status.value == value,
      orElse: () => BankConnectionStatus.error,
    );
  }
}

class BankConnection {
  const BankConnection({
    required this.id,
    required this.institutionId,
    required this.institutionName,
    required this.status,
    required this.provider,
    required this.createdAt,
    this.institutionLogoUrl,
    this.maskedAccountNumber,
    this.lastSyncedAt,
    this.lastError,
  });

  final String id;
  final String institutionId;
  final String institutionName;
  final String? institutionLogoUrl;
  final String? maskedAccountNumber;
  final BankConnectionStatus status;
  final String provider;
  final DateTime? lastSyncedAt;
  final String? lastError;
  final DateTime createdAt;

  factory BankConnection.fromMap(Map<String, dynamic> map) {
    return BankConnection(
      id: map['id'] as String,
      institutionId: map['institution_id'] as String,
      institutionName: map['institution_name'] as String,
      institutionLogoUrl: map['institution_logo_url'] as String?,
      maskedAccountNumber: map['masked_account_number'] as String?,
      status: BankConnectionStatusX.fromValue(map['status'] as String),
      provider: map['provider'] as String,
      lastSyncedAt: map['last_synced_at'] is String
          ? DateTime.parse(map['last_synced_at'] as String)
          : null,
      lastError: map['last_error'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  BankConnection copyWith({
    BankConnectionStatus? status,
    DateTime? lastSyncedAt,
    String? lastError,
  }) {
    return BankConnection(
      id: id,
      institutionId: institutionId,
      institutionName: institutionName,
      institutionLogoUrl: institutionLogoUrl,
      maskedAccountNumber: maskedAccountNumber,
      status: status ?? this.status,
      provider: provider,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
      lastError: lastError ?? this.lastError,
      createdAt: createdAt,
    );
  }
}
