import 'privacy_request_type.dart';

String privacyRequestTemplateFor(PrivacyRequestType type) {
  switch (type.id) {
    case 'data_access':
      return 'Tôi muốn biết Moniary hiện đang lưu những nhóm dữ liệu nào liên quan đến tài khoản của tôi.';
    case 'data_export_help':
      return 'Tôi cần hỗ trợ xuất dữ liệu tài khoản vì không thể hoàn tất thao tác xuất dữ liệu trong app.';
    case 'data_correction':
      return 'Tôi muốn yêu cầu chỉnh sửa dữ liệu chưa chính xác trong tài khoản của mình. Dữ liệu cần kiểm tra là:';
    case 'data_deletion':
      return 'Tôi muốn yêu cầu xóa dữ liệu cá nhân và dữ liệu tài chính liên quan đến tài khoản của mình.';
    case 'privacy_complaint':
      return 'Tôi muốn gửi phản hồi hoặc khiếu nại về cách Moniary xử lý dữ liệu cá nhân của tôi.';
    default:
      return 'Tôi cần hỗ trợ về quyền riêng tư và dữ liệu cá nhân trong Moniary.';
  }
}
