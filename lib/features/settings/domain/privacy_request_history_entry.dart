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

class PrivacyRequestStatusOption {
  const PrivacyRequestStatusOption({
    required this.id,
    required this.label,
    required this.description,
  });

  final String id;
  final String label;
  final String description;
}

const privacyRequestStatusOptions = [
  PrivacyRequestStatusOption(
    id: 'ready_to_send',
    label: 'Sẵn sàng gửi',
    description: 'File request đã được tạo và đang chờ người dùng gửi đi.',
  ),
  PrivacyRequestStatusOption(
    id: 'sent_manually',
    label: 'Đã gửi thủ công',
    description: 'Người dùng đã gửi request qua email hoặc kênh hỗ trợ.',
  ),
  PrivacyRequestStatusOption(
    id: 'resolved',
    label: 'Đã xử lý',
    description: 'Yêu cầu đã được xử lý xong hoặc không cần theo dõi nữa.',
  ),
];

PrivacyRequestStatusOption privacyRequestStatusById(String id) {
  return privacyRequestStatusOptions.firstWhere(
    (status) => status.id == id,
    orElse: () => privacyRequestStatusOptions.first,
  );
}
