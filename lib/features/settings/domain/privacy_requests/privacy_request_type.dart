class PrivacyRequestType {
  const PrivacyRequestType({required this.id});

  final String id;
}

const privacyRequestTypes = [
  PrivacyRequestType(id: 'data_access'),
  PrivacyRequestType(id: 'data_export_help'),
  PrivacyRequestType(id: 'data_correction'),
  PrivacyRequestType(id: 'data_deletion'),
  PrivacyRequestType(id: 'privacy_complaint'),
];

/// Resolves a stored privacy request value to its corresponding `PrivacyRequestType`.
/// This acts as a backwards-compatibility mapper for legacy persisted labels
/// (e.g. "Xóa dữ liệu") returning the stable ID enum.
PrivacyRequestType privacyRequestTypeByStoredValue(String storedValue) {
  final trimmedValue = storedValue.trim();
  final normalizedId = switch (trimmedValue.toLowerCase()) {
    // Legacy Vietnamese labels
    'xem dữ liệu đang lưu' => 'data_access',
    'hỗ trợ xuất dữ liệu' => 'data_export_help',
    'chỉnh sửa dữ liệu' => 'data_correction',
    'xóa dữ liệu' => 'data_deletion',
    'khiếu nại quyền riêng tư' => 'privacy_complaint',

    // Legacy English labels
    'data access' => 'data_access',
    'export help' => 'data_export_help',
    'data correction' => 'data_correction',
    'account deletion' => 'data_deletion',
    'data deletion' => 'data_deletion',
    'privacy complaint' => 'privacy_complaint',

    _ => trimmedValue,
  };

  return privacyRequestTypes.firstWhere(
    (type) => type.id == normalizedId,
    orElse: () => PrivacyRequestType(id: trimmedValue),
  );
}
