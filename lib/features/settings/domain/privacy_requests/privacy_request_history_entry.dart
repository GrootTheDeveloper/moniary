class PrivacyRequestHistoryEntry {
  const PrivacyRequestHistoryEntry({
    required this.id,
    required this.requestType,
    required this.message,
    required this.status,
    required this.createdAt,
    this.path,
  });

  final String id;
  final String requestType;
  final String message;
  final String status;
  final DateTime createdAt;
  final String? path;

  PrivacyRequestHistoryEntry copyWith({String? status}) {
    return PrivacyRequestHistoryEntry(
      id: id,
      requestType: requestType,
      message: message,
      status: status ?? this.status,
      createdAt: createdAt,
      path: path,
    );
  }

  factory PrivacyRequestHistoryEntry.fromMap(Map<String, dynamic> map) {
    return PrivacyRequestHistoryEntry(
      id: map['id'] as String? ?? '',
      requestType: map['request_type'] as String? ?? '',
      message: map['message'] as String? ?? '',
      status: map['status'] as String? ?? 'ready_to_send',
      createdAt:
          DateTime.tryParse(map['created_at'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      path: map['path'] as String?,
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
    };
  }
}

class PrivacyRequestStatusOption {
  const PrivacyRequestStatusOption({required this.id});

  final String id;
}

const privacyRequestStatusOptions = [
  PrivacyRequestStatusOption(id: 'ready_to_send'),
  PrivacyRequestStatusOption(id: 'sent_manually'),
  PrivacyRequestStatusOption(id: 'resolved'),
];

PrivacyRequestStatusOption privacyRequestStatusById(String id) {
  return privacyRequestStatusOptions.firstWhere(
    (status) => status.id == id,
    orElse: () => privacyRequestStatusOptions.first,
  );
}
