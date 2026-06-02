enum ImportHistoryStatus {
  pending,
  completed,
  failed;

  static ImportHistoryStatus fromValue(String? value) {
    return ImportHistoryStatus.values.firstWhere(
      (status) => status.name == value,
      orElse: () => ImportHistoryStatus.completed,
    );
  }
}

class ImportHistoryEntry {
  const ImportHistoryEntry({
    required this.id,
    required this.fileName,
    required this.importedCount,
    required this.walletName,
    required this.createdAt,
    this.status = ImportHistoryStatus.completed,
    this.errorMessage,
  });

  final String id;
  final String fileName;
  final int importedCount;
  final String walletName;
  final DateTime createdAt;
  final ImportHistoryStatus status;
  final String? errorMessage;

  factory ImportHistoryEntry.fromMap(Map<String, dynamic> map) {
    return ImportHistoryEntry(
      id: map['id'] as String? ?? '',
      fileName: map['file_name'] as String? ?? 'unknown.csv',
      importedCount: map['imported_count'] as int? ?? 0,
      walletName: map['wallet_name'] as String? ?? 'Unknown',
      createdAt:
          DateTime.tryParse(map['created_at'] as String? ?? '') ??
          DateTime.now(),
      status: ImportHistoryStatus.fromValue(map['status'] as String?),
      errorMessage: map['error_message'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'file_name': fileName,
      'imported_count': importedCount,
      'wallet_name': walletName,
      'created_at': createdAt.toIso8601String(),
      'status': status.name,
      'error_message': errorMessage,
    };
  }

  ImportHistoryEntry copyWith({
    int? importedCount,
    ImportHistoryStatus? status,
    String? Function()? errorMessage,
  }) {
    return ImportHistoryEntry(
      id: id,
      fileName: fileName,
      importedCount: importedCount ?? this.importedCount,
      walletName: walletName,
      createdAt: createdAt,
      status: status ?? this.status,
      errorMessage: errorMessage != null ? errorMessage() : this.errorMessage,
    );
  }
}
