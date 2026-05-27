class PrivacyRequestType {
  const PrivacyRequestType({
    required this.id,
    required this.label,
    required this.description,
  });

  final String id;
  final String label;
  final String description;
}

const privacyRequestTypes = [
  PrivacyRequestType(
    id: 'data_access',
    label: 'Xem dữ liệu đang lưu',
    description:
        'Yêu cầu Moniary cung cấp thông tin về dữ liệu đang gắn với tài khoản.',
  ),
  PrivacyRequestType(
    id: 'data_export_help',
    label: 'Hỗ trợ xuất dữ liệu',
    description: 'Yêu cầu hỗ trợ khi không thể tự xuất dữ liệu trong app.',
  ),
  PrivacyRequestType(
    id: 'data_correction',
    label: 'Chỉnh sửa dữ liệu',
    description:
        'Yêu cầu điều chỉnh dữ liệu cá nhân hoặc dữ liệu tài chính bị sai.',
  ),
  PrivacyRequestType(
    id: 'data_deletion',
    label: 'Xóa dữ liệu',
    description:
        'Yêu cầu xóa dữ liệu hoặc hỗ trợ khi xóa tài khoản không thành công.',
  ),
  PrivacyRequestType(
    id: 'privacy_complaint',
    label: 'Khiếu nại quyền riêng tư',
    description:
        'Gửi phản hồi về cách dữ liệu cá nhân được xử lý trong Moniary.',
  ),
];

PrivacyRequestType privacyRequestTypeById(String id) {
  return privacyRequestTypes.firstWhere(
    (type) => type.id == id,
    orElse: () => privacyRequestTypes.first,
  );
}
