class PrivacyRequestHistoryEntry {
  const PrivacyRequestHistoryEntry({
    required this.id,
    required this.requestType,
    required this.message,
    required this.status,
    required this.createdAt,
    required this.path,
  });

  final String id;
  final String requestType;
  final String message;
  final String status;
  final DateTime createdAt;
  final String path;

  factory PrivacyRequestHistoryEntry.fromMap(Map<String, dynamic> map) {
    return PrivacyRequestHistoryEntry(
      id: map['id'] as String? ?? '',
      requestType: map['request_type'] as String? ?? '',
      message: map['message'] as String? ?? '',
      status: map['status'] as String? ?? 'ready_to_send',
      createdAt:
          DateTime.tryParse(map['created_at'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      path: map['path'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'request_type': requestType,
      'message': message,
      'status': status,
      'created_at': createdAt.toIso8601String(),
      'path': path,
    };
  }
}
