class PrivacyRequestHistoryEntry {
  const PrivacyRequestHistoryEntry({
    required this.id,
    required this.requestType,
    required this.message,
    required this.status,
    required this.createdAt,
    this.path,
    this.adminNote,
    this.resolvedAt,
  });

  final String id;
  final String requestType;
  final String message;
  final String status;
  final DateTime createdAt;
  final String? path;
  final String? adminNote;
  final DateTime? resolvedAt;

  factory PrivacyRequestHistoryEntry.fromMap(Map<String, dynamic> map) {
    return PrivacyRequestHistoryEntry(
      id: map['id'] as String? ?? '',
      requestType: map['request_type'] as String? ?? '',
      message: map['message'] as String? ?? '',
      status: map['status'] as String? ?? 'submitted',
      createdAt:
          DateTime.tryParse(
            (map['submitted_at'] ?? map['created_at']) as String? ?? '',
          ) ??
          DateTime.fromMillisecondsSinceEpoch(0),
      path: map['path'] as String?,
      adminNote: _trimmedOrNull(map['admin_note']),
      resolvedAt: DateTime.tryParse(map['resolved_at'] as String? ?? ''),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'request_type': requestType,
      'message': message,
      'status': status,
      'created_at': createdAt.toIso8601String(),
      if (path != null) 'path': path,
      if (adminNote != null) 'admin_note': adminNote,
      if (resolvedAt != null) 'resolved_at': resolvedAt!.toIso8601String(),
    };
  }

  static String? _trimmedOrNull(Object? value) {
    if (value is! String) return null;
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }
}

class PrivacyRequestStatusOption {
  const PrivacyRequestStatusOption({required this.id});

  final String id;
}

const privacyRequestStatusOptions = [
  PrivacyRequestStatusOption(id: 'submitted'),
  PrivacyRequestStatusOption(id: 'in_review'),
  PrivacyRequestStatusOption(id: 'resolved'),
  PrivacyRequestStatusOption(id: 'rejected'),
];

PrivacyRequestStatusOption privacyRequestStatusById(String id) {
  return privacyRequestStatusOptions.firstWhere(
    (status) => status.id == id,
    orElse: () => privacyRequestStatusOptions.first,
  );
}
