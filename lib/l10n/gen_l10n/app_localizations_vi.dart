// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Vietnamese (`vi`).
class AppLocalizationsVi extends AppLocalizations {
  AppLocalizationsVi([String locale = 'vi']) : super(locale);

  @override
  String get appName => 'Moniary';

  @override
  String get commonSave => 'Lưu';

  @override
  String get commonCancel => 'Hủy';

  @override
  String get commonDelete => 'Xóa';

  @override
  String get commonEdit => 'Sửa';

  @override
  String get commonRetry => 'Thử lại';

  @override
  String get commonAdd => 'Thêm';

  @override
  String get commonClose => 'Đóng';

  @override
  String get commonSaving => 'Đang lưu...';

  @override
  String get commonLoading => 'Đang tải...';

  @override
  String get commonCopy => 'Copy';

  @override
  String get commonShare => 'Chia sẻ';

  @override
  String get commonOpen => 'Mở';

  @override
  String get commonViewAll => 'Xem tất cả';

  @override
  String get commonSelect => 'Chọn';

  @override
  String get commonCreate => 'Tạo';

  @override
  String get commonConfirm => 'Xác nhận';

  @override
  String get errorGeneric => 'Đã xảy ra lỗi. Vui lòng thử lại.';

  @override
  String get errorNotLoggedIn => 'Bạn chưa đăng nhập.';

  @override
  String get errorNotFound => 'Dữ liệu không tồn tại.';

  @override
  String get errorConnection => 'Lỗi kết nối. Vui lòng thử lại.';

  @override
  String get loginTitle => 'Moniary';

  @override
  String get loginSubtitle => 'Quản lý chi tiêu cá nhân';

  @override
  String get loginAnonymous => 'Kết nối ẩn danh với Supabase';

  @override
  String get loginTerms =>
      'Bằng cách tiếp tục, bạn đồng ý với các điều khoản sử dụng và chính sách bảo mật của Moniary.';

  @override
  String get loginFeatureSubtitle => 'Ghi chi tiêu bằng ảnh';

  @override
  String get loginHeader => 'Đăng nhập';

  @override
  String get loginGoogle => 'Đăng nhập với Google';

  @override
  String get loginApple => 'Đăng nhập với Apple';

  @override
  String get loginEmail => 'Đăng nhập với Email';

  @override
  String get loginOr => 'hoặc';

  @override
  String get loginConnecting => 'Đang kết nối Supabase...';

  @override
  String get loginTryWithoutAuth => 'Dùng thử không cần đăng nhập';

  @override
  String get loginSessionReady =>
      'Phiên đăng nhập đã sẵn sàng. Bạn có thể vào thẳng Lịch.';

  @override
  String get loginDataSecure =>
      'Dữ liệu của bạn được bảo mật và đồng bộ với Supabase.';

  @override
  String get splashLoading => 'Đang tải ứng dụng...';

  @override
  String get splashRetry => 'Thử lại';

  @override
  String get splashError =>
      'Không thể kết nối. Vui lòng kiểm tra mạng và thử lại.';

  @override
  String get splashErrorConnecting => 'Không thể kết nối';

  @override
  String get splashSubtitle => 'Ghi chi tiêu bằng ảnh';

  @override
  String get splashDescription =>
      'Chụp lại khoản chi, lưu vào lịch,\nquản lý tiền dễ như lưu kỷ niệm.';

  @override
  String splashStarting(String appName) {
    return 'Đang khởi động $appName...';
  }

  @override
  String get onboardingSkip => 'Bỏ qua';

  @override
  String get onboardingStart => 'Bắt đầu';

  @override
  String get onboardingNext => 'Tiếp';

  @override
  String get onboardingNextPage => 'Xem tiếp';

  @override
  String get onboardingFinish => 'Tiếp tục';

  @override
  String get onboardingMonthMock => 'Tháng 5';

  @override
  String get onboardingPillCapture => 'Chụp & lưu';

  @override
  String get onboardingPillCalendar => 'Xem theo ngày';

  @override
  String get onboardingPillStats => 'Thống kê';

  @override
  String get onboardingPage1Title1 => 'Ghi chi tiêu';

  @override
  String get onboardingPage1Title2 => 'bằng ảnh';

  @override
  String get onboardingPage1Subtitle => 'Nhanh gọn  •  Dễ nhớ  •  Không bỏ sót';

  @override
  String get onboardingPage1Caption =>
      'Lưu khoảnh khắc chi tiêu như một cuốn nhật ký mini.';

  @override
  String get onboardingPage2Title1 => 'Xem lịch tháng';

  @override
  String get onboardingPage2Title2 => 'trực quan';

  @override
  String get onboardingPage2Subtitle =>
      'Ảnh, tổng chi, bộ lọc và nhắc nhở trong một màn hình';

  @override
  String get onboardingPage2Caption =>
      'Mỗi ngày là một ô nhỏ, mỗi giao dịch là một kỷ niệm.';

  @override
  String get onboardingPage3Title1 => 'Thống kê';

  @override
  String get onboardingPage3Title2 => 'dễ hiểu';

  @override
  String get onboardingPage3Subtitle =>
      'Theo dõi thu chi và thói quen tiêu dùng không cần bảng biểu khó';

  @override
  String get onboardingPage3Caption =>
      'Moniary giúp bạn nhìn tiền theo ngữ cảnh sống thật.';

  @override
  String get profileSetupTitle => 'Thiết lập hồ sơ';

  @override
  String get profileSetupSubtitle => 'Hoàn tất thông tin để bắt đầu';

  @override
  String get profileSetupDisplayName => 'Tên hiển thị';

  @override
  String get profileSetupDisplayNameHint => 'Nhập tên của bạn';

  @override
  String get profileSetupCurrency => 'Đơn vị tiền tệ';

  @override
  String get profileSetupStart => 'Bắt đầu';

  @override
  String get profileSetupNameRequired => 'Nhập tên hiển thị trước.';

  @override
  String get calendarTitle => 'Lịch';

  @override
  String get calendarAllWallets => 'Tất cả ví';

  @override
  String get calendarAllCategories => 'Tất cả danh mục';

  @override
  String get calendarNoTransactions => 'Không có giao dịch trong tháng này.';

  @override
  String get calendarIncome => 'Thu';

  @override
  String get calendarExpense => 'Chi';

  @override
  String get calendarBalance => 'Số dư';

  @override
  String get calendarSelectWalletFilter => 'Chọn ví lọc';

  @override
  String get calendarSelectCategoryFilter => 'Chọn danh mục lọc';

  @override
  String get calendarMonthlyExpense => 'Tổng chi tháng';

  @override
  String get calendarMonthlyIncome => 'Tổng thu tháng';

  @override
  String get calendarEmptyMessage =>
      'Chưa có giao dịch nào trong tháng này. Bước tiếp theo là thêm giao dịch để lịch hiện dữ liệu thật.';

  @override
  String calendarStatsMessage(int count, int days) {
    return '$count giao dịch trong $days ngày có hoạt động. Lịch đang đọc dữ liệu thật từ Supabase.';
  }

  @override
  String calendarLoadError(String error) {
    return 'Không tải được lịch tháng: $error';
  }

  @override
  String get calendarStatsTab => 'Thống kê';

  @override
  String get calendarMon => 'T2';

  @override
  String get calendarTue => 'T3';

  @override
  String get calendarWed => 'T4';

  @override
  String get calendarThu => 'T5';

  @override
  String get calendarFri => 'T6';

  @override
  String get calendarSat => 'T7';

  @override
  String get calendarSun => 'CN';

  @override
  String get calendarToday => 'Hôm nay';

  @override
  String get calendarSearchHint => 'Tìm theo ghi chú hoặc danh mục...';

  @override
  String get calendarSearchPrompt => 'Nhập ghi chú hoặc danh mục để tìm kiếm.';

  @override
  String get calendarSearchNoResults => 'Không tìm thấy giao dịch nào.';

  @override
  String get transactionSaveTransaction => 'Lưu giao dịch';

  @override
  String transactionLoadDayError(String error) {
    return 'Không tải được giao dịch trong ngày.\n$error';
  }

  @override
  String get transactionTotalIncome => 'Tổng thu';

  @override
  String get transactionTotalExpense => 'Tổng chi';

  @override
  String get transactionNetTotal => 'Tổng cộng';

  @override
  String transactionCount(int count) {
    return '$count giao dịch';
  }

  @override
  String get transactionDayEmpty =>
      'Ngày này chưa có giao dịch. Bạn có thể bấm nút + để thêm ngay.';

  @override
  String transactionLoadDetailError(String error) {
    return 'Không tải được chi tiết giao dịch.\n$error';
  }

  @override
  String get transactionNoteEmpty => 'Chưa có ghi chú cho giao dịch này.';

  @override
  String get transactionDeleteTitleQuestion => 'Xóa giao dịch?';

  @override
  String get transactionDeleteUndone => 'Hành động này không thể hoàn tác.';

  @override
  String get transactionAmount => 'Số tiền';

  @override
  String get transactionAmountSuffix => 'đ';

  @override
  String get transactionWallet => 'Ví';

  @override
  String get transactionCategory => 'Danh mục';

  @override
  String get transactionNote => 'Ghi chú';

  @override
  String get transactionNoteHint => 'Tra sua KOI / Luong freelance / ...';

  @override
  String get transactionDate => 'Ngày giao dịch';

  @override
  String get transactionSelectWalletCategory =>
      'Chọn ví và danh mục trước khi lưu.';

  @override
  String get transactionAmountInvalid => 'Nhập số tiền hợp lệ.';

  @override
  String get transactionSaving => 'Đang lưu...';

  @override
  String get transactionCreateTitle => 'Tạo giao dịch';

  @override
  String get transactionEditTitle => 'Sửa giao dịch';

  @override
  String get transactionDeleteConfirm => 'Xác nhận xóa giao dịch này?';

  @override
  String get transactionDeleteSuccess => 'Đã xóa giao dịch.';

  @override
  String transactionSaveError(String error) {
    return 'Không lưu được giao dịch: $error';
  }

  @override
  String get transactionCreateSubtitle =>
      'Lưu giao dịch trước, phần ảnh sẽ được thêm ở bước tiếp theo.';

  @override
  String get transactionWalletCategoryLoadError =>
      'Không tải được ví/danh mục. Mở quản lý dữ liệu để kiểm tra.';

  @override
  String get transactionChangePhoto => 'Thay đổi ảnh';

  @override
  String get transactionEnterNote => 'Nhập ghi chú...';

  @override
  String get transactionSelectCategory => 'Chọn danh mục';

  @override
  String get transactionSelectWallet => 'Chọn ví';

  @override
  String get transactionDateTime => 'Ngày giờ';

  @override
  String get transactionWalletAccount => 'Ví / Tài khoản';

  @override
  String get transactionExpenseCategory => 'Danh mục chi';

  @override
  String get transactionLoadingWalletCategory => 'Đang tải ví và danh mục...';

  @override
  String get transactionWalletCategoryError =>
      'Không tải được ví hoặc danh mục. Vui lòng thử lại.';

  @override
  String get transactionWalletCategoryRequired =>
      'Cần có ví và danh mục chi đang hoạt động trước khi lưu.';

  @override
  String get transactionAmountPositive => 'Nhập số tiền lớn hơn 0.';

  @override
  String get transactionType => 'Loại giao dịch';

  @override
  String get walletTitle => 'Ví / Tài khoản';

  @override
  String get walletDescription =>
      'Quản lý ví mặc định, số dư khởi tạo và trạng thái kích hoạt.';

  @override
  String get walletEmpty => 'Chưa có ví nào.';

  @override
  String get walletDefault => 'Mặc định';

  @override
  String get walletActive => 'Đang dùng';

  @override
  String get walletInactive => 'Đã ẩn';

  @override
  String get walletCreateTitle => 'Tạo ví';

  @override
  String get walletEditTitle => 'Sửa ví';

  @override
  String get walletName => 'Tên ví';

  @override
  String get walletType => 'Loại ví';

  @override
  String get walletInitialBalance => 'Số dư ban đầu';

  @override
  String get walletSetDefault => 'Đặt làm ví mặc định';

  @override
  String get walletActivated => 'Đang kích hoạt';

  @override
  String get walletSaving => 'Đang lưu...';

  @override
  String get walletSave => 'Lưu ví';

  @override
  String get walletNameRequired => 'Tên ví không được trống.';

  @override
  String get walletTypeCash => 'Tiền mặt';

  @override
  String get walletTypeBank => 'Ngân hàng';

  @override
  String get walletTypeEwallet => 'Ví điện tử';

  @override
  String get walletTypeCredit => 'Thẻ tín dụng';

  @override
  String get walletTypeOther => 'Khác';

  @override
  String walletError(String error) {
    return 'Lỗi ví: $error';
  }

  @override
  String get walletNeedOneActive =>
      'Bạn cần ít nhất 1 ví đang hoạt động để tạo giao dịch.';

  @override
  String get categoryTitle => 'Danh mục';

  @override
  String get categoryDescription =>
      'Quản lý danh mục thu/chi để chuẩn bị cho giao dịch.';

  @override
  String get categoryEmpty => 'Chưa có danh mục nào.';

  @override
  String get categoryNoData => 'Chưa có dữ liệu.';

  @override
  String get categoryCreateTitle => 'Tạo danh mục';

  @override
  String get categoryEditTitle => 'Sửa danh mục';

  @override
  String get categoryName => 'Tên danh mục';

  @override
  String get categoryType => 'Loại danh mục';

  @override
  String get categoryActivated => 'Đang kích hoạt';

  @override
  String get categorySaving => 'Đang lưu...';

  @override
  String get categorySave => 'Lưu danh mục';

  @override
  String get categoryNameRequired => 'Tên danh mục không được trống.';

  @override
  String categoryError(String error) {
    return 'Category error: $error';
  }

  @override
  String get categoryExpense => 'Chi';

  @override
  String get categoryIncome => 'Thu';

  @override
  String get categoryNeedOneActive =>
      'Bạn cần ít nhất 1 danh mục đang hoạt động cho loại giao dịch này.';

  @override
  String get scanTitle => 'Quét hóa đơn';

  @override
  String get scanTakePhoto => 'Chụp ảnh';

  @override
  String get scanChooseGallery => 'Chọn từ thư viện';

  @override
  String get scanExtracting => 'Đang trích xuất dữ liệu...';

  @override
  String get scanFailed => 'Không thể đọc hóa đơn. Vui lòng thử lại.';

  @override
  String get scanReviewTitle => 'Kiểm tra hóa đơn';

  @override
  String get scanMerchant => 'Cửa hàng';

  @override
  String scanOcrConfidence(int percent) {
    return 'Độ tin cậy OCR: $percent%. Hãy kiểm tra thông tin trước khi lưu.';
  }

  @override
  String get scanItemsTitle => 'Mục nhận diện';

  @override
  String scanQuantity(String quantity) {
    return 'Số lượng: $quantity';
  }

  @override
  String get scanSuccessMessage =>
      'Đã đọc hóa đơn. Bạn có thể kiểm tra và chỉnh sửa thông tin.';

  @override
  String get scanScanning => 'Đang quét...';

  @override
  String get scanExtractButton => 'Trích xuất dữ liệu';

  @override
  String get scanManualEntry => 'Nhập giao dịch thủ công';

  @override
  String get scanNoReceipt => 'Chưa có ảnh hóa đơn';

  @override
  String get scanNoReceiptSubtitle =>
      'Chụp ảnh hoặc chọn ảnh từ thư viện để bắt đầu.';

  @override
  String get scanImageError => 'Không thể hiển thị ảnh đã chọn.';

  @override
  String get groupTitle => 'Nhóm chi tiêu';

  @override
  String get groupEmpty => 'Chưa có nhóm chi tiêu';

  @override
  String get groupEmptySubtitle =>
      'Tạo nhóm để cùng theo dõi hóa đơn và chia tiền.';

  @override
  String get groupCreate => 'Tạo nhóm';

  @override
  String get groupCreateDialog => 'Tạo nhóm mới';

  @override
  String get groupNameLabel => 'Tên nhóm';

  @override
  String get groupNeedLogin => 'Bạn cần đăng nhập để tạo nhóm.';

  @override
  String groupMemberCount(int count) {
    return '$count thành viên';
  }

  @override
  String get groupLoadError => 'Không tải được danh sách nhóm.';

  @override
  String get groupAddMember => 'Thêm thành viên';

  @override
  String get groupMemberName => 'Tên thành viên';

  @override
  String get groupExpenses => 'Chi phí nhóm';

  @override
  String get groupAddExpense => 'Thêm chi phí';

  @override
  String get groupNoExpenses => 'Chưa có chi phí nào.';

  @override
  String get groupNoMembers => 'Nhóm chưa có thành viên nào ngoài bạn.';

  @override
  String get groupDebtSummary => 'Tổng hợp nợ';

  @override
  String get groupRemoveMemberConfirm => 'Xóa thành viên này?';

  @override
  String get groupDetailTitle => 'Chi tiêu nhóm';

  @override
  String get groupLoadSingleError => 'Không tải được nhóm.';

  @override
  String get groupNotExists => 'Nhóm không còn tồn tại.';

  @override
  String get groupMembersHeader => 'Thành viên';

  @override
  String get groupExpenseHistory => 'Lịch sử chi tiêu';

  @override
  String get groupLoadExpensesError => 'Không tải được chi phí nhóm.';

  @override
  String get groupDeletedMember => 'Thành viên đã xóa';

  @override
  String get groupMemberEmailHint => 'Email (không bắt buộc)';

  @override
  String get groupDeleteExpenseConfirmTitle => 'Xóa chi phí?';

  @override
  String get groupDeleteExpenseConfirmMessage =>
      'Thao tác này sẽ cập nhật lại công nợ của nhóm.';

  @override
  String groupPayerSubtitle(String payer, String date) {
    return '$payer đã trả • $date';
  }

  @override
  String get groupEmptyExpensesMessage =>
      'Chưa có chi phí. Thêm hóa đơn đầu tiên để bắt đầu tính nợ.';

  @override
  String get debtSummaryTitle => 'Tổng hợp nợ';

  @override
  String get debtNoData => 'Chưa có dữ liệu chi phí.';

  @override
  String get debtSettlementTitle => 'Gợi ý thanh toán';

  @override
  String get debtNoSettlement => 'Không có khoản nợ nào cần thanh toán.';

  @override
  String debtOwes(String from, String to, String amount) {
    return '$from trả $to $amount';
  }

  @override
  String get debtSummaryAppBarTitle => 'Tổng kết công nợ';

  @override
  String get debtLoadError => 'Không tính được công nợ.';

  @override
  String get debtExplanation =>
      'Số dương là số tiền cần nhận, số âm là số tiền cần trả.';

  @override
  String debtOwesPayerToPayee(String from, String to) {
    return '$from trả $to';
  }

  @override
  String get debtMember => 'Thành viên';

  @override
  String get debtToReceive => 'Sẽ nhận';

  @override
  String get debtToPay => 'Cần trả';

  @override
  String get expenseFormTitle => 'Thêm chi phí nhóm';

  @override
  String get expenseFormEditTitle => 'Sửa chi phí';

  @override
  String get expenseAmount => 'Số tiền';

  @override
  String get expenseNote => 'Ghi chú';

  @override
  String get expenseDate => 'Ngày';

  @override
  String get expensePayer => 'Người trả';

  @override
  String get expenseParticipants => 'Người tham gia';

  @override
  String get expenseSplitEqual => 'Chia đều';

  @override
  String get expenseSplitManual => 'Tự nhập số tiền';

  @override
  String get expenseSplitPercentage => 'Theo phần trăm';

  @override
  String get expenseSave => 'Lưu chi phí';

  @override
  String get expenseFormMinMembersNotice =>
      'Hãy thêm ít nhất 2 thành viên trước khi chia chi phí.';

  @override
  String get expenseFormTotalCost => 'Tổng chi phí';

  @override
  String get expenseFormContentLabel => 'Nội dung';

  @override
  String get expenseFormPayer => 'Người thanh toán';

  @override
  String get expenseFormDate => 'Ngày chi';

  @override
  String get validationAmountPositive => 'Số tiền phải lớn hơn 0.';

  @override
  String validationMinMembers(int min) {
    return 'Nhóm phải có ít nhất $min thành viên.';
  }

  @override
  String get validationSelectPayer => 'Chọn người trả tiền.';

  @override
  String get validationSelectParticipant => 'Chọn ít nhất một người tham gia.';

  @override
  String validationSplitMismatch(String splitTotal, String total) {
    return 'Tổng chia ($splitTotal) phải bằng tổng chi phí ($total).';
  }

  @override
  String get validationNegativeSplit => 'Phần chia không được âm.';

  @override
  String get validationInvalidParticipants =>
      'Danh sách người tham gia không hợp lệ.';

  @override
  String get validationSplitCountMismatch =>
      'Mỗi người tham gia cần đúng một phần chia.';

  @override
  String get profileTitle => 'Hồ sơ';

  @override
  String get profileUserDefault => 'Người dùng Moniary';

  @override
  String get profileAnonymous => 'Tài khoản dùng thử ẩn danh';

  @override
  String get profileMyData => 'Dữ liệu của tôi';

  @override
  String get profileExportData => 'Xuất dữ liệu';

  @override
  String get profileExportSubtitle => 'CSV, XLSX, PDF';

  @override
  String get profileImportData => 'Nhập dữ liệu';

  @override
  String get profileImportSubtitle => 'Nhập từ file CSV';

  @override
  String get profilePrivacyCenter => 'Bảo mật & quyền riêng tư';

  @override
  String get privacyGroupPrivacyTermsTitle => 'Quyền riêng tư & điều khoản';

  @override
  String get privacyGroupPrivacyTermsSubtitle =>
      'Chính sách, điều khoản và thông báo pháp lý.';

  @override
  String get privacyTermsPolicySubtitle =>
      'Dữ liệu cá nhân, tài chính, ảnh và dịch vụ bên thứ ba.';

  @override
  String get privacyTermsLimitationsTitle => 'Điều khoản & giới hạn';

  @override
  String get privacyTermsLimitationsSubtitle =>
      'Phạm vi sử dụng, trách nhiệm người dùng và miễn trừ tài chính.';

  @override
  String get privacyTermsRecordsTitle => 'Hồ sơ chính sách';

  @override
  String get privacyTermsRecordsSubtitle =>
      'Cập nhật chính sách, thông báo đồng ý và liên hệ pháp lý.';

  @override
  String get privacyGroupDataSafetyTitle => 'An toàn dữ liệu';

  @override
  String get privacyGroupDataSafetySubtitle =>
      'Dữ liệu, quyền truy cập và khai báo CH Play.';

  @override
  String get privacyDataOverviewTitle => 'Tổng quan dữ liệu';

  @override
  String get privacyDataOverviewSubtitle =>
      'Dữ liệu đã lưu, nhóm dữ liệu thu thập và tóm tắt tài khoản.';

  @override
  String get privacyDataControlsTitle => 'Kiểm soát dữ liệu';

  @override
  String get privacyDataControlsSubtitle =>
      'Quyền dữ liệu, lưu giữ dữ liệu và chính sách xóa.';

  @override
  String get privacyGroupHelpRequestsTitle => 'Hỗ trợ & yêu cầu';

  @override
  String get privacyGroupHelpRequestsSubtitle =>
      'Trợ giúp, liên hệ và yêu cầu quyền riêng tư.';

  @override
  String get privacyHelpCenterSubtitle =>
      'Hướng dẫn, xử lý sự cố và ghi chú sử dụng an toàn.';

  @override
  String get privacyRequestsTitle => 'Yêu cầu quyền riêng tư';

  @override
  String get privacyRequestsSubtitle =>
      'Liên hệ hỗ trợ hoặc yêu cầu trợ giúp về quyền riêng tư và xóa dữ liệu.';

  @override
  String get privacyAboutSubtitle =>
      'Mục đích app, trạng thái MVP và thông tin phát hành.';

  @override
  String get profileAccount => 'Tài khoản';

  @override
  String get profileSignOut => 'Đăng xuất';

  @override
  String get profileSignOutSubtitle =>
      'Thoát khỏi tài khoản hiện tại trên thiết bị này.';

  @override
  String get profileDeleteAccount => 'Xóa tài khoản';

  @override
  String get profileDeleteSubtitle =>
      'Xóa dữ liệu cá nhân, giao dịch và ảnh đã lưu.';

  @override
  String get privacyClearDataSubtitle => 'Xóa toàn bộ dữ liệu ứng dụng';

  @override
  String get notificationSettings => 'Cài đặt thông báo';

  @override
  String get emailReports => 'Báo cáo Email Tự động';

  @override
  String get emailReportsDesc => 'Nhận tổng hợp thu chi định kỳ qua email.';

  @override
  String get dailyReport => 'Báo cáo hàng ngày';

  @override
  String dailyReportDesc(String time) {
    return 'Mỗi ngày lúc $time';
  }

  @override
  String get weeklyReport => 'Báo cáo hàng tuần';

  @override
  String get weeklyReportDesc => 'Mỗi tuần một lần';

  @override
  String get monthlyReport => 'Báo cáo hàng tháng';

  @override
  String get monthlyReportDesc => 'Mỗi tháng một lần';

  @override
  String get yearlyReport => 'Báo cáo hàng năm';

  @override
  String get yearlyReportDesc => 'Mỗi năm một lần';

  @override
  String get deleteAccountTitle => 'Xóa tài khoản';

  @override
  String get deleteAccountWarning =>
      'Hành động này sẽ xóa toàn bộ dữ liệu cá nhân, giao dịch và ảnh giao dịch của bạn.';

  @override
  String get deleteAccountConfirm => 'Xóa tài khoản';

  @override
  String get deleteAccountTitleQuestion => 'Xóa tài khoản?';

  @override
  String get deleteAccountUndone =>
      'Thao tác này không thể hoàn tác trong app.';

  @override
  String get deleteAccountConsequence1 =>
      'Xóa hồ sơ và phiên đăng nhập hiện tại.';

  @override
  String get deleteAccountConsequence2 =>
      'Xóa ví, danh mục và toàn bộ giao dịch.';

  @override
  String get deleteAccountConsequence3 =>
      'Xóa ảnh giao dịch trong Storage theo user ID.';

  @override
  String get deleteAccountUnderstand =>
      'Tôi hiểu dữ liệu sẽ bị xóa khỏi tài khoản này.';

  @override
  String get exportTitle => 'Xuất dữ liệu';

  @override
  String get exportFormat => 'Định dạng file';

  @override
  String get exportDateRange => 'Khoảng ngày';

  @override
  String get exportAllTime => 'Tất cả thời gian';

  @override
  String get exportDataTypes => 'Loại dữ liệu';

  @override
  String get exportDataTypeTransactions => 'Giao dịch';

  @override
  String get exportDataTypeWallets => 'Ví';

  @override
  String get exportDataTypeCategories => 'Danh mục';

  @override
  String get exportButton => 'Xuất dữ liệu';

  @override
  String get exportDone => 'Đã xuất dữ liệu';

  @override
  String get exportHistoryTitle => 'Lịch sử export';

  @override
  String get exportHistoryEmpty => 'Chưa có file export nào.';

  @override
  String get exportRecentTitle => 'Lần xuất gần đây';

  @override
  String get exportRecentHistoryError => 'Không tải được lần xuất gần đây.';

  @override
  String get manageDataTitle => 'Quản lý dữ liệu';

  @override
  String get cameraTakePhoto => 'Chụp';

  @override
  String get cameraFlip => 'Lật camera';

  @override
  String get cameraNoPermission => 'Không có quyền truy cập camera';

  @override
  String get cameraTitle => 'Chụp hóa đơn';

  @override
  String get cameraOcrScan => 'Quét OCR';

  @override
  String get cameraGallery => 'Thư viện';

  @override
  String get accountDeletionRequestTitle => 'Yêu cầu xóa dữ liệu';

  @override
  String get accountDeletionRequestDesc =>
      'Dùng lựa chọn này khi không thể xóa tài khoản trực tiếp trong app. Moniary sẽ tạo một file yêu cầu để bạn gửi cho kênh hỗ trợ quyền riêng tư.';

  @override
  String get accountDeletionRequestReasonLabel =>
      'Lý do hoặc ghi chú cho yêu cầu';

  @override
  String get accountDeletionRequestReasonHint =>
      'Ví dụ: Tôi không còn sử dụng app và muốn xóa toàn bộ dữ liệu.';

  @override
  String get accountDeletionRequestSubmit => 'Tạo yêu cầu xóa dữ liệu';

  @override
  String get accountDeletionRequestSuccessDesc =>
      'Yêu cầu đã được tạo. Vui lòng kiểm tra lịch sử và gửi yêu cầu thủ công.';

  @override
  String get deleteAccountHelpTitle => 'Hỗ trợ xóa tài khoản';

  @override
  String get deleteAccountHelpHero =>
      'Xóa tài khoản là thao tác quan trọng. Hướng dẫn này giúp người dùng chuẩn bị dữ liệu và biết cách gửi yêu cầu hỗ trợ khi cần.';

  @override
  String get deleteAccountHelpStep1Title => '1. Xuất dữ liệu trước khi xóa';

  @override
  String get deleteAccountHelpStep1Desc =>
      'Sau khi xóa tài khoản, dữ liệu app gắn với user hiện tại có thể không khôi phục được. Hãy export CSV, Excel hoặc PDF trước nếu cần giữ bản sao.';

  @override
  String get deleteAccountHelpStep2Title => '2. Kiểm tra ảnh giao dịch';

  @override
  String get deleteAccountHelpStep2Desc =>
      'Ảnh giao dịch được xử lý cùng dữ liệu tài khoản. Hãy tải hoặc lưu lại file cần thiết trước khi xóa.';

  @override
  String get deleteAccountHelpStep3Title => '3. Xác nhận kỹ trong app';

  @override
  String get deleteAccountHelpStep3Desc =>
      'Luồng xóa tài khoản yêu cầu xác nhận mạnh để tránh thao tác nhầm.';

  @override
  String get deleteAccountHelpStep4Title => '4. Dùng fallback nếu xóa thất bại';

  @override
  String get deleteAccountHelpStep4Desc =>
      'Nếu thao tác trực tiếp lỗi, tạo file yêu cầu xóa dữ liệu thủ công và gửi kèm mô tả lỗi cho kênh hỗ trợ.';

  @override
  String get deleteAccountHelpExportBefore => 'Xuất dữ liệu trước';

  @override
  String get deleteAccountHelpCreateRequest => 'Tạo request xóa dữ liệu';

  @override
  String get deleteAccountHelpContactPrivacy => 'Liên hệ privacy';

  @override
  String get legalContactHero =>
      'Các kênh liên hệ này giúp người dùng, reviewer hoặc team phát hành biết nơi gửi yêu cầu phù hợp.';

  @override
  String get legalContactPrivacyDesc =>
      'Yêu cầu dữ liệu cá nhân, xóa dữ liệu hoặc câu hỏi privacy.';

  @override
  String get legalContactSupportDesc =>
      'Hỗ trợ chung về app, file export hoặc thao tác người dùng.';

  @override
  String get legalContactLegalDesc =>
      'Vấn đề điều khoản, phát hành Store hoặc yêu cầu pháp lý.';

  @override
  String privacyDetailCreatedAt(String date) {
    return 'Tạo lúc $date';
  }

  @override
  String get privacyDetailExpectedResponse => 'Dự kiến phản hồi';

  @override
  String privacyDetailExpectedResponseDesc(String date, int days) {
    return '$date hoặc trong $days ngày làm việc sau khi gửi.';
  }

  @override
  String privacyDetailMarkStatus(String status) {
    return 'Đánh dấu: $status';
  }

  @override
  String get privacyDetailContentTitle => 'Nội dung yêu cầu';

  @override
  String get privacyDetailContentEmpty => 'Không có nội dung bổ sung.';

  @override
  String get privacyDetailFileTitle => 'File đã tạo';

  @override
  String get routeNotFound => 'Trang không tồn tại';

  @override
  String get routeGoBack => 'Quay lại';

  @override
  String get statsDevelopingMessage =>
      'Tính năng Thống kê đang được phát triển.';

  @override
  String get transactionIsImportant => 'Giao dịch quan trọng';

  @override
  String get statsTitle => 'Thống kê chi tiêu';

  @override
  String get statsTotalIncome => 'Tổng thu';

  @override
  String get statsTotalExpense => 'Tổng chi';

  @override
  String get statsNetBalance => 'Số dư ròng';

  @override
  String get statsExpenseButton => 'Tổng Chi';

  @override
  String get statsIncomeButton => 'Tổng Thu';

  @override
  String get statsEmptyTitle => 'Chưa có giao dịch nào loại này';

  @override
  String get statsEmptySubtitle =>
      'Các biểu đồ thống kê sẽ hiện ra sau khi bạn thêm giao dịch.';

  @override
  String get statsCategoryAllocation => 'Phân bổ danh mục';

  @override
  String get statsDailyTrend => 'Xu hướng hàng ngày';

  @override
  String get statsLargestTransactions => 'Giao dịch lớn nhất';

  @override
  String get statsCategoryTransactions => 'Giao dịch trong danh mục';

  @override
  String statsDayTooltip(int day, String amount) {
    return 'Ngày $day\n$amount';
  }

  @override
  String get profileProtectAccount => 'Bảo vệ tài khoản của bạn';

  @override
  String get profileAnonymousWarning =>
      'Bạn đang đăng nhập bằng tài khoản khách. Hãy liên kết tài khoản để tránh mất mát dữ liệu khi đổi thiết bị.';

  @override
  String get profileLinkNow => 'Liên kết ngay';

  @override
  String get profileLinkAccountTitle => 'Liên kết tài khoản';

  @override
  String get profileLinkAccountSubtitle =>
      'Tài khoản của bạn hiện là ẩn danh. Liên kết với Email hoặc Google để lưu trữ dữ liệu vĩnh viễn và đăng nhập trên nhiều thiết bị.';

  @override
  String get profileNewPassword => 'Mật khẩu mới';

  @override
  String get profileLinkEmail => 'Liên kết Email';

  @override
  String get profileLinkGoogle => 'Liên kết Google';

  @override
  String get profileLinkApple => 'Liên kết Apple';

  @override
  String get profileLinkSuccess => 'Liên kết tài khoản email thành công!';

  @override
  String get profileLinkGoogleBrowser =>
      'Hoàn tất liên kết Google trong trình duyệt để quay lại Moniary.';

  @override
  String get profileLinkAppleBrowser =>
      'Hoàn tất liên kết Apple trong trình duyệt để quay lại Moniary.';

  @override
  String profileLinkGoogleError(String error) {
    return 'Lỗi liên kết Google: $error';
  }

  @override
  String profileLinkAppleError(String error) {
    return 'Lỗi liên kết Apple: $error';
  }

  @override
  String get profileEditInfo => 'Chỉnh sửa thông tin';

  @override
  String get profileChangeTimezone => 'Thay đổi múi giờ';

  @override
  String get profileAnonymousBadge => 'Tài khoản Ẩn danh';

  @override
  String profileVerifiedBadge(String provider) {
    return 'Đã Xác thực ($provider)';
  }

  @override
  String get profileSignOutDialogTitle => 'Đăng xuất';

  @override
  String get profileSignOutDialogMessage =>
      'Bạn có chắc chắn muốn đăng xuất không?';

  @override
  String get profileCancel => 'Hủy';

  @override
  String get exportSupportTitle => 'Hỗ trợ export dữ liệu';

  @override
  String get exportOpenData => 'Mở export dữ liệu';

  @override
  String get exportOpenHistory => 'Mở lịch sử export';

  @override
  String get exportCreateSupportRequest => 'Tạo yêu cầu hỗ trợ';

  @override
  String get exportTroubleshootingHero =>
      'Hướng dẫn này giúp xử lý nhanh khi file CSV, Excel hoặc PDF không có dữ liệu, không mở được hoặc không tìm thấy sau khi export.';

  @override
  String get exportTroubleshootingTypeTitle =>
      '1. Kiểm tra loại dữ liệu đã chọn';

  @override
  String get exportTroubleshootingTypeDesc =>
      'Nếu file trống, hãy kiểm tra bạn đã chọn Giao dịch, Ví hoặc Danh mục trong bộ lọc export.';

  @override
  String get exportTroubleshootingDateTitle => '2. Kiểm tra khoảng ngày';

  @override
  String get exportTroubleshootingDateDesc =>
      'Nếu chọn khoảng ngày quá hẹp, file có thể không có giao dịch phù hợp.';

  @override
  String get exportTroubleshootingHistoryTitle => '3. Mở lại từ lịch sử export';

  @override
  String get exportTroubleshootingHistoryDesc =>
      'Sau khi tạo file, vào lịch sử export để mở lại đường dẫn file và chia sẻ khi cần.';

  @override
  String get exportTroubleshootingSupportTitle => '4. Tạo request hỗ trợ';

  @override
  String get exportTroubleshootingSupportDesc =>
      'Nếu file không tạo được hoặc không mở được, hãy tạo request privacy/support kèm mô tả lỗi.';

  @override
  String get legalDataDeletionPolicy => 'Chính sách xóa dữ liệu';

  @override
  String get legalDataRetention => 'Lưu giữ dữ liệu';

  @override
  String get legalFinancialDisclaimer => 'Miễn trừ tài chính';

  @override
  String get legalContact => 'Liên hệ pháp lý';

  @override
  String get legalCopyAllContacts => 'Copy tất cả liên hệ';

  @override
  String get legalCopyContactSuccess => 'Đã copy thông tin liên hệ.';

  @override
  String get legalPolicyAcceptance => 'Đồng ý chính sách';

  @override
  String get legalViewPrivacyPolicy => 'Xem chính sách bảo mật';

  @override
  String get legalViewTermsOfUse => 'Xem điều khoản sử dụng';

  @override
  String get legalPolicyChangelog => 'Lịch sử chính sách';

  @override
  String get legalTermsOfUse => 'Điều khoản sử dụng';

  @override
  String get legalThirdPartyServices => 'Dịch vụ bên thứ ba';

  @override
  String get legalUserRights => 'Quyền dữ liệu';

  @override
  String get privacyDataSafety => 'An toàn dữ liệu';

  @override
  String get privacyMyData => 'Dữ liệu của tôi';

  @override
  String get privacyPhotoData => 'Dữ liệu ảnh';

  @override
  String get privacyDataFreshness => 'Độ mới dữ liệu';

  @override
  String get privacyLocalFiles => 'File cục bộ';

  @override
  String get privacyTransactionPhotos => 'Ảnh giao dịch';

  @override
  String get privacyViewExportHistory => 'Xem lịch sử export';

  @override
  String get privacyPermissionRationale => 'Quyền truy cập';

  @override
  String get privacyFaq => 'FAQ privacy & tài khoản';

  @override
  String get privacyCenter => 'Trung tâm riêng tư';

  @override
  String get privacyContact => 'Liên hệ quyền riêng tư';

  @override
  String get privacyUseTemplate => 'Dùng mẫu nội dung';

  @override
  String get privacyCreateRequest => 'Tạo yêu cầu privacy';

  @override
  String get privacyRequestCreated => 'Đã tạo yêu cầu';

  @override
  String get privacyCopyEmail => 'Copy email';

  @override
  String get privacyCopyInstructions => 'Copy hướng dẫn';

  @override
  String get privacyPolicyTitle => 'Chính sách bảo mật';

  @override
  String get privacyRequestDetailTitle => 'Chi tiết yêu cầu';

  @override
  String get privacyCopyFilePath => 'Copy file path';

  @override
  String get privacyCopyFilePathSuccess => 'Đã copy đường dẫn file';

  @override
  String get privacyCopyRequest => 'Copy request';

  @override
  String get privacyCopyRequestSuccess => 'Đã copy nội dung yêu cầu';

  @override
  String get storeAboutMoniary => 'Giới thiệu Moniary';

  @override
  String get storeComplianceChecklist => 'Checklist phát hành';

  @override
  String get storeTrustSafety => 'Tin cậy & an toàn';

  @override
  String get supportHelpCenter => 'Trung tâm trợ giúp';

  @override
  String get supportCopySuccess => 'Đã copy thông tin support.';

  @override
  String get supportCopyDiagnostic => 'Copy diagnostic info';

  @override
  String get supportRequestChecklist => 'Checklist gửi hỗ trợ';

  @override
  String get supportOpenHelpCenter => 'Mở trung tâm trợ giúp';

  @override
  String get transactionOcrSuccess => 'Tự động trích xuất dữ liệu thành công!';

  @override
  String get scanImageSelectError => 'Không thể chọn ảnh. Vui lòng thử lại.';

  @override
  String get scanImageRequiredError => 'Vui lòng chọn ảnh hóa đơn trước.';

  @override
  String get scanReadError => 'Không thể đọc hóa đơn. Vui lòng thử lại.';

  @override
  String get commonFeatureUnderDevelopment => 'Tính năng đang được phát triển';

  @override
  String get appLockTitle => 'Ứng dụng đã bị khóa';

  @override
  String get appLockSubtitle => 'Vui lòng xác thực để tiếp tục sử dụng';

  @override
  String get appLockUnlockButton => 'Mở khóa';

  @override
  String get privacyCenterAppLockTitle => 'Khóa ứng dụng';

  @override
  String get privacyCenterAppLockSubtitle =>
      'Yêu cầu vân tay hoặc khuôn mặt khi mở ứng dụng.';

  @override
  String get biometricReasonEnable => 'Xác thực để bật khóa ứng dụng';

  @override
  String get biometricReasonUnlock => 'Mở khóa Moniary';

  @override
  String get importTitle => 'Nhập dữ liệu (CSV)';

  @override
  String get importSelectFile => 'Chọn tệp CSV';

  @override
  String get importCsvFormatTitle => 'Định dạng CSV yêu cầu:';

  @override
  String get importCsvFormatBody =>
      '1. Ngày giao dịch (YYYY-MM-DD)\n2. Số tiền (Ví dụ: 100000)\n3. Loại (Thu / Chi)\n4. Hạng mục\n5. Ghi chú (Tùy chọn)\n\nLưu ý: Bỏ qua dòng tiêu đề nếu có.';

  @override
  String get importConfirm => 'Xác nhận nhập';

  @override
  String get importRecentTitle => 'Lần nạp gần đây';

  @override
  String get importRecentHistoryError => 'Không tải được lần nạp gần đây.';

  @override
  String get importViewHistory => 'Xem lịch sử nạp';

  @override
  String get importHistoryTitle => 'Lịch sử nạp dữ liệu';

  @override
  String get importDetailTitle => 'Chi tiết nạp dữ liệu';

  @override
  String get importNoHistory => 'Chưa có lịch sử nạp dữ liệu.';

  @override
  String get importDetailFileName => 'Tên file';

  @override
  String get importDetailImportedCount => 'Số giao dịch nạp thành công';

  @override
  String get importDetailWallet => 'Ví đích';

  @override
  String get importDetailDate => 'Ngày nạp';

  @override
  String get importDetailStatus => 'Trạng thái';

  @override
  String get importDetailError => 'Lỗi';

  @override
  String get importStatusPending => 'Đang nạp';

  @override
  String get importStatusCompleted => 'Hoàn tất';

  @override
  String get importStatusFailed => 'Thất bại';

  @override
  String get settingsTitle => 'Cài đặt';

  @override
  String importPreviewTitle(int count) {
    return 'Xem trước ($count dòng hợp lệ)';
  }

  @override
  String importSuccess(int count) {
    return 'Đã nhập $count giao dịch';
  }

  @override
  String get importNoWallets => 'Không tìm thấy ví. Hãy tạo ví trước.';

  @override
  String get importSelectWallet => 'Chọn ví đích';

  @override
  String importErrorWallets(String error) {
    return 'Lỗi tải danh sách ví: $error';
  }

  @override
  String get importErrorUnknown => 'Lỗi không xác định';

  @override
  String get importErrorMissingColumns => 'Thiếu cột (yêu cầu 5)';

  @override
  String get importErrorInvalidDate =>
      'Định dạng ngày không hợp lệ (dùng YYYY-MM-DD)';

  @override
  String get importErrorInvalidAmount => 'Số tiền không hợp lệ';

  @override
  String get importErrorInvalidType => 'Loại giao dịch không hợp lệ';

  @override
  String get importErrorCategoryNotFound => 'Không tìm thấy danh mục';

  @override
  String get importRetry => 'Thử lại';

  @override
  String get activeSessionsTitle => 'Thiết bị & Phiên';

  @override
  String get activeSessionsEmpty => 'Không có dữ liệu.';

  @override
  String activeSessionsError(String error) {
    return 'Lỗi: $error';
  }

  @override
  String get activeSessionsUnknownDevice => 'Thiết bị không xác định';

  @override
  String get activeSessionsThisDevice => 'Thiết bị này';

  @override
  String activeSessionsFirstLogin(String date) {
    return 'Đăng nhập lần đầu: $date';
  }

  @override
  String activeSessionsLastActive(String date) {
    return 'Hoạt động gần nhất: $date';
  }

  @override
  String activeSessionsIp(String ip) {
    return 'IP: $ip';
  }

  @override
  String get activeSessionsRevokeTooltip => 'Đăng xuất thiết bị này';

  @override
  String get activeSessionsRevokeTitle => 'Đăng xuất thiết bị?';

  @override
  String get activeSessionsRevokeContent =>
      'Thiết bị này sẽ bị đăng xuất khỏi tài khoản của bạn ngay lập tức.';

  @override
  String get activeSessionsRevokeConfirm => 'Đăng xuất';

  @override
  String get restoreAccountTitle => 'Tài khoản đang chờ xóa';

  @override
  String get restoreAccountBody =>
      'Tài khoản của bạn đã bị vô hiệu hóa và đang trong thời gian ân hạn 30 ngày trước khi bị xóa vĩnh viễn.\n\nBạn có muốn khôi phục lại tài khoản không?';

  @override
  String get restoreAccountButton => 'Khôi phục tài khoản';

  @override
  String get validationEmailRequired => 'Email không được trống';

  @override
  String get validationEmailInvalid => 'Email không hợp lệ';

  @override
  String validationPasswordMinLength(int min) {
    return 'Mật khẩu phải từ $min ký tự';
  }

  @override
  String get exportFormatCsvLabel => 'CSV';

  @override
  String get exportFormatCsvDesc =>
      'Bảng dữ liệu nhẹ, mở được bằng Excel hoặc Google Sheets.';

  @override
  String get exportFormatXlsxLabel => 'Excel';

  @override
  String get exportFormatXlsxDesc =>
      'Workbook .xlsx cho Excel, Sheets hoặc WPS Office.';

  @override
  String get exportFormatPdfLabel => 'PDF';

  @override
  String get exportFormatPdfDesc =>
      'Báo cáo dễ đọc để lưu hoặc gửi cho người khác.';

  @override
  String exportFileSavedAt(String path) {
    return 'File đã được lưu tại:\n$path';
  }

  @override
  String get exportNoAppToShare => 'Chưa tìm thấy app phù hợp để chia sẻ file.';

  @override
  String get exportNoAppToOpen => 'Chưa tìm thấy app phù hợp để mở file.';

  @override
  String get exportDetailTitle => 'Chi tiết bản xuất';

  @override
  String get exportDetailFileInfo => 'Thông tin file';

  @override
  String get exportDetailTime => 'Thời gian';

  @override
  String get exportDetailFormat => 'Định dạng';

  @override
  String get exportDetailStatus => 'Trạng thái';

  @override
  String get exportDetailReady => 'Sẵn sàng';

  @override
  String get exportDetailMissing => 'File đã bị xóa';

  @override
  String get exportDetailDataConfig => 'Cấu hình dữ liệu';

  @override
  String get exportDetailDataRange => 'Thời gian dữ liệu';

  @override
  String get exportDetailDataGroups => 'Các nhóm dữ liệu';

  @override
  String get exportDetailStoragePath => 'Đường dẫn lưu trữ';

  @override
  String get exportDetailLocation => 'Vị trí';

  @override
  String get exportDetailOpenFile => 'Mở xem file ngay';

  @override
  String get exportDetailShareFile => 'Chia sẻ qua Email / Zalo';

  @override
  String get exportDetailMissingMessage =>
      'Tệp tin này không còn tồn tại trên thiết bị. Bạn có thể thực hiện xuất lại dữ liệu với các bộ lọc tương tự.';

  @override
  String get exportDetailSuccessTitle => 'Xuất dữ liệu thành công';

  @override
  String get exportDetailReportSubtitle => 'Moniary Financial Report';

  @override
  String get commonComingSoon => 'Sắp có';

  @override
  String activeSessionsDeviceOn(String browser, String os) {
    return '$browser trên $os';
  }

  @override
  String get activeSessionsOtherOs => 'Hệ điều hành khác';

  @override
  String get activeSessionsOtherBrowser => 'Trình duyệt/App khác';

  @override
  String get privacyReqDataAccess => 'Xem dữ liệu đang lưu';

  @override
  String get privacyReqDataAccessDesc =>
      'Yêu cầu Moniary cung cấp thông tin về dữ liệu đang gắn với tài khoản.';

  @override
  String get privacyReqExportHelp => 'Hỗ trợ xuất dữ liệu';

  @override
  String get privacyReqExportHelpDesc =>
      'Yêu cầu hỗ trợ khi không thể tự xuất dữ liệu trong app.';

  @override
  String get privacyReqCorrection => 'Chỉnh sửa dữ liệu';

  @override
  String get privacyReqCorrectionDesc =>
      'Yêu cầu điều chỉnh dữ liệu cá nhân hoặc dữ liệu tài chính bị sai.';

  @override
  String get privacyReqDeletion => 'Xóa dữ liệu';

  @override
  String get privacyReqDeletionDesc =>
      'Yêu cầu xóa dữ liệu hoặc hỗ trợ khi xóa tài khoản không thành công.';

  @override
  String get privacyReqComplaint => 'Khiếu nại quyền riêng tư';

  @override
  String get privacyReqComplaintDesc =>
      'Gửi phản hồi về cách dữ liệu cá nhân được xử lý trong Moniary.';

  @override
  String get privacyStatusReady => 'Sẵn sàng gửi';

  @override
  String get privacyStatusReadyDesc =>
      'File request đã được tạo và đang chờ người dùng gửi đi.';

  @override
  String get privacyStatusSent => 'Đã gửi thủ công';

  @override
  String get privacyStatusSentDesc =>
      'Người dùng đã gửi request qua email hoặc kênh hỗ trợ.';

  @override
  String get privacyStatusResolved => 'Đã xử lý';

  @override
  String get privacyStatusResolvedDesc =>
      'Yêu cầu đã được xử lý xong hoặc không cần theo dõi nữa.';

  @override
  String get privacyTplDataAccess =>
      'Tôi muốn biết Moniary hiện đang lưu những nhóm dữ liệu nào liên quan đến tài khoản của tôi.';

  @override
  String get privacyTplExportHelp =>
      'Tôi cần hỗ trợ xuất dữ liệu tài khoản vì không thể hoàn tất thao tác xuất dữ liệu trong app.';

  @override
  String get privacyTplCorrection =>
      'Tôi muốn yêu cầu chỉnh sửa dữ liệu chưa chính xác trong tài khoản của mình. Dữ liệu cần kiểm tra là:';

  @override
  String get privacyTplDeletion =>
      'Tôi muốn yêu cầu xóa dữ liệu cá nhân và dữ liệu tài chính liên quan đến tài khoản của mình.';

  @override
  String get privacyTplComplaint =>
      'Tôi muốn gửi phản hồi hoặc khiếu nại về cách Moniary xử lý dữ liệu cá nhân của tôi.';

  @override
  String get privacyTplDefault =>
      'Tôi cần hỗ trợ về quyền riêng tư và dữ liệu cá nhân trong Moniary.';

  @override
  String get privacyContactRequestType => 'Loại yêu cầu';

  @override
  String get privacyContactRequestContent => 'Nội dung yêu cầu';

  @override
  String get privacyContactRequestHint =>
      'Mô tả ngắn điều bạn muốn team hỗ trợ.';

  @override
  String get privacyContactPreview => 'Xem trước yêu cầu';

  @override
  String get privacyContactPreviewEmpty => 'Chưa nhập nội dung yêu cầu.';

  @override
  String get privacyContactProcessTimeline => 'Quy trình phản hồi';

  @override
  String get privacyContactProcessStep1 => 'Tạo request trong app';

  @override
  String get privacyContactProcessStep1Desc =>
      'App chuẩn bị nội dung để bạn gửi cho kênh hỗ trợ.';

  @override
  String get privacyContactProcessStep2 => 'Gửi request thủ công';

  @override
  String privacyContactProcessStep2Desc(String email) {
    return 'Gửi yêu cầu qua email $email.';
  }

  @override
  String get privacyContactProcessStep3 => 'Theo dõi phản hồi';

  @override
  String privacyContactProcessStep3Desc(int days) {
    return 'Mốc phản hồi dự kiến là $days ngày làm việc.';
  }

  @override
  String get privacyContactShortcuts => 'Lối tắt hỗ trợ';

  @override
  String get privacyContactCopyEmailSuccess => 'Đã copy email support.';

  @override
  String privacyContactCopyGuide(String email) {
    return 'Email: $email\nChủ đề: Moniary privacy request\nNội dung: Dán nội dung yêu cầu đã copy từ app.';
  }

  @override
  String get privacyContactCopyGuideSuccess => 'Đã copy hướng dẫn gửi request.';

  @override
  String get privacyContactHeroTitle => 'Yêu cầu về dữ liệu cá nhân';

  @override
  String get privacyContactHeroDesc =>
      'Nếu không thể xử lý trực tiếp trong app, người dùng có thể liên hệ team để yêu cầu hỗ trợ về dữ liệu.';

  @override
  String get privacyContactEmailTitle => 'Email hỗ trợ';

  @override
  String get privacyContactEmailDesc =>
      'Dùng cho yêu cầu xóa dữ liệu, xuất dữ liệu hoặc câu hỏi về quyền riêng tư.';

  @override
  String get privacyContactInfoTitle => 'Thông tin cần gửi';

  @override
  String get privacyContactInfoValue => 'User ID hoặc email đăng nhập';

  @override
  String get privacyContactInfoDesc =>
      'Không gửi mật khẩu, access token, ảnh hóa đơn nhạy cảm hoặc số tiền chi tiết qua email.';

  @override
  String get privacyContactTimeTitle => 'Thời gian phản hồi';

  @override
  String get privacyContactTimeValue => 'Trong vòng 7 ngày làm việc';

  @override
  String get privacyContactTimeDesc =>
      'Team cần cập nhật thời gian thực tế trước khi phát hành production.';

  @override
  String get privacyContactRecentRequests => 'Yêu cầu gần đây';

  @override
  String get privacyContactRequestStatus => 'Trạng thái';

  @override
  String get privacyContactRequestFile => 'File đính kèm';

  @override
  String get privacyRequestSuccessDesc =>
      'Yêu cầu đã được tạo. Vui lòng kiểm tra lịch sử và gửi yêu cầu thủ công.';

  @override
  String get privacyAndAccountTitle => 'Privacy & tài khoản';

  @override
  String get privacyAndAccountSubtitle =>
      'Xem quyền dữ liệu, yêu cầu privacy và các lựa chọn liên quan tài khoản.';

  @override
  String get dataRightsTitle => 'Quyền dữ liệu';

  @override
  String get dataRightsSubtitle =>
      'Tóm tắt quyền xem, xuất, sửa/xóa dữ liệu và liên hệ privacy.';

  @override
  String get exportDataSubTitle =>
      'Xử lý khi export CSV, Excel hoặc PDF lỗi, trống hoặc không tìm thấy file.';

  @override
  String get createExportFileTitle => 'Tạo file export';

  @override
  String get createExportFileSubtitle =>
      'Mở luồng export khi cần tạo bản sao dữ liệu cá nhân.';

  @override
  String get contactSupportSubtitle =>
      'Tạo request privacy hoặc copy thông tin liên hệ để gửi cho team hỗ trợ.';

  @override
  String get deleteAccountSubtitle =>
      'Chuẩn bị trước khi xóa, hiểu dữ liệu bị ảnh hưởng và fallback khi có lỗi.';

  @override
  String get supportChecklistTitle => 'Checklist gửi hỗ trợ';

  @override
  String get supportChecklistSubtitle =>
      'Chuẩn bị mô tả lỗi, file liên quan và diagnostic info trước khi gửi request.';

  @override
  String get helpHeroText =>
      'Tìm nhanh các hướng dẫn liên quan đến dữ liệu, quyền riêng tư, export và hỗ trợ tài khoản trong Moniary.';

  @override
  String get supportDiagnosticTitle => 'Thông tin gửi support';

  @override
  String get supportDiagnosticSubtitle =>
      'Copy version, build và kênh liên hệ để gửi kèm khi báo lỗi.';

  @override
  String get helpCenterTitle => 'Trung tâm trợ giúp';

  @override
  String get helpCenterSubtitle =>
      'Tìm hướng dẫn về privacy, tài khoản, export dữ liệu và cách liên hệ hỗ trợ.';

  @override
  String get aboutMoniaryTitle => 'Giới thiệu Moniary';

  @override
  String get aboutMoniarySubtitle =>
      'Xem mục đích app, định hướng dữ liệu và trạng thái MVP trước khi phát hành.';

  @override
  String get privacyPolicySubtitle =>
      'Xem cách Moniary xử lý dữ liệu cá nhân, tài chính và ảnh giao dịch.';

  @override
  String get termsOfUseTitle => 'Điều khoản sử dụng';

  @override
  String get termsOfUseSubtitle =>
      'Xem phạm vi sử dụng, trách nhiệm người dùng và giới hạn của phiên bản MVP.';

  @override
  String get dataRetentionPolicyTitle => 'Chính sách lưu giữ dữ liệu';

  @override
  String get dataRetentionPolicySubtitle =>
      'Xem dữ liệu nào được lưu trên cloud, dữ liệu nào nằm cục bộ và cách xử lý sau khi xóa tài khoản.';

  @override
  String get thirdPartyServicesTitle => 'Dịch vụ bên thứ ba';

  @override
  String get thirdPartyServicesSubtitle =>
      'Xem app đang dùng Supabase, Flutter/package và bộ nhớ thiết bị như thế nào.';

  @override
  String get releaseChecklistTitle => 'Checklist phát hành';

  @override
  String get releaseChecklistSubtitle =>
      'Rà soát các mục privacy, data export, xóa tài khoản và contact trước khi lên Store.';

  @override
  String get trustSafetyTitle => 'Tin cậy & an toàn';

  @override
  String get trustSafetySubtitle =>
      'Xem ghi chú về giới hạn tư vấn tài chính, dữ liệu người dùng và chia sẻ file.';

  @override
  String get financialDisclaimerTitle => 'Miễn trừ tài chính';

  @override
  String get financialDisclaimerSubtitle =>
      'Xem giới hạn trách nhiệm: app không phải tư vấn đầu tư, thuế, kế toán hoặc pháp lý.';

  @override
  String get policyChangelogTitle => 'Lịch sử chính sách';

  @override
  String get policyChangelogSubtitle =>
      'Xem các mốc cập nhật privacy, legal và store readiness trong app.';

  @override
  String get userDataRightsTitle => 'Quyền dữ liệu của người dùng';

  @override
  String get userDataRightsSubtitle =>
      'Tóm tắt quyền xem dữ liệu, xuất dữ liệu, yêu cầu sửa/xóa và liên hệ privacy.';

  @override
  String get policyAcceptanceNoticeTitle => 'Thông báo đồng ý chính sách';

  @override
  String get policyAcceptanceNoticeSubtitle =>
      'Giải thích rằng việc tiếp tục sử dụng app áp dụng theo chính sách và điều khoản hiện tại.';

  @override
  String get legalContactTitle => 'Liên hệ pháp lý';

  @override
  String get legalContactSubtitle =>
      'Xem và copy email privacy, support và legal dùng cho phát hành Store.';

  @override
  String get dataSafetyTitle => 'An toàn dữ liệu';

  @override
  String get dataSafetySubtitle =>
      'Tóm tắt các nhóm dữ liệu được thu thập hoặc không thu thập trong MVP.';

  @override
  String get myDataTitle => 'Dữ liệu của tôi';

  @override
  String get myDataSubtitle =>
      'Xem nhanh app đang lưu bao nhiêu dữ liệu trong tài khoản này.';

  @override
  String get permissionsTitle => 'Quyền truy cập';

  @override
  String get permissionsSubtitle =>
      'Giải thích lý do Moniary dùng hoặc không dùng từng quyền Android.';

  @override
  String get exportMyDataTitle => 'Xuất dữ liệu của tôi';

  @override
  String get exportMyDataSubtitle =>
      'Chọn định dạng file và tạo bản sao dữ liệu cá nhân.';

  @override
  String get exportHistorySubtitle =>
      'Xem các file CSV, Excel hoặc PDF đã tạo từ tài khoản này.';

  @override
  String get deleteAccountSubtitle2 =>
      'Xóa hồ sơ, ví, danh mục, giao dịch và ảnh giao dịch đã lưu.';

  @override
  String get dataDeletionPolicyTitle => 'Chính sách xóa dữ liệu';

  @override
  String get dataDeletionPolicySubtitle =>
      'Xem dữ liệu nào bị xóa và cách Moniary xử lý yêu cầu xóa.';

  @override
  String get dataDeletionRequestTitle => 'Yêu cầu xóa dữ liệu';

  @override
  String get dataDeletionRequestSubtitle =>
      'Tạo file yêu cầu xóa thủ công nếu xóa trực tiếp không thành công.';

  @override
  String get privacyContactTitle => 'Liên hệ quyền riêng tư';

  @override
  String get privacyContactSubtitle =>
      'Kênh hỗ trợ cho yêu cầu dữ liệu, xóa dữ liệu hoặc câu hỏi privacy.';

  @override
  String get trustHeroText =>
      'Các ghi chú này giúp người dùng hiểu rõ app làm gì, không làm gì và nên bảo vệ dữ liệu tài chính cá nhân ra sao.';

  @override
  String get notFinancialAdviceTitle => 'Không phải tư vấn tài chính';

  @override
  String get notFinancialAdviceDesc =>
      'Moniary chỉ giúp ghi chép và xem lại dữ liệu thu chi cá nhân. App không đưa ra lời khuyên đầu tư, thuế hoặc kế toán.';

  @override
  String get userEnteredDataTitle => 'Dữ liệu do người dùng nhập';

  @override
  String get userEnteredDataDesc =>
      'Số tiền, ghi chú, danh mục và ảnh giao dịch phụ thuộc vào dữ liệu người dùng tạo trong app.';

  @override
  String get noOverCollectionTitle => 'Không thu thập ngoài phạm vi';

  @override
  String get noOverCollectionDesc =>
      'MVP không đọc danh bạ, SMS, email inbox, vị trí hoặc tài khoản ngân hàng tự động.';

  @override
  String get carefulFileSharingTitle => 'Cẩn thận khi chia sẻ file';

  @override
  String get carefulFileSharingDesc =>
      'File export có thể chứa dữ liệu tài chính cá nhân. Chỉ chia sẻ với người hoặc kênh hỗ trợ đáng tin cậy.';

  @override
  String get exportDataTitle => 'Xuất dữ liệu';

  @override
  String get supportContactTitle => 'Liên hệ hỗ trợ';

  @override
  String importSuccessWithHistoryError(int count) {
    return 'Đã import thành công $count giao dịch, nhưng lỗi khi lưu lịch sử cục bộ.';
  }

  @override
  String legalCopyContactValue(String value) {
    return 'Đã copy $value';
  }

  @override
  String get storeComplianceHero =>
      'Các mục dưới đây giúp rà soát nhanh những phần người dùng và reviewer cần thấy trước khi app được phát hành.';

  @override
  String get storeCompliancePrivacyTitle => 'Chính sách bảo mật';

  @override
  String get storeCompliancePrivacyDesc =>
      'Có màn privacy policy mô tả dữ liệu tài chính, ảnh giao dịch và cách xử lý dữ liệu.';

  @override
  String get storeComplianceDeleteTitle => 'Xóa tài khoản';

  @override
  String get storeComplianceDeleteDesc =>
      'Có luồng xóa tài khoản trong app và fallback tạo request thủ công.';

  @override
  String get storeComplianceExportTitle => 'Xuất dữ liệu';

  @override
  String get storeComplianceExportDesc =>
      'Người dùng có thể export dữ liệu CSV, Excel hoặc PDF trước khi rời app.';

  @override
  String get storeComplianceDataSafetyTitle => 'Data Safety';

  @override
  String get storeComplianceDataSafetyDesc =>
      'Có phần tóm tắt nhóm dữ liệu được lưu và nhóm dữ liệu app không thu thập.';

  @override
  String get storeComplianceContactTitle => 'Liên hệ privacy';

  @override
  String get storeComplianceContactDesc =>
      'Có kênh hỗ trợ, request history và trạng thái xử lý yêu cầu privacy.';

  @override
  String get storeComplianceTermsTitle => 'Điều khoản sử dụng';

  @override
  String get storeComplianceTermsDesc =>
      'Có terms of use và ghi chú giới hạn trách nhiệm của app MVP.';

  @override
  String get privacyNoData => 'Chưa có dữ liệu';

  @override
  String get privacyDataOverview => 'Tổng quan dữ liệu';

  @override
  String get privacyDataInventory => 'Nhóm dữ liệu đang lưu';

  @override
  String get privacySensitiveData => 'Lưu ý dữ liệu nhạy cảm';

  @override
  String get privacyTransparencyReport => 'Báo cáo minh bạch';

  @override
  String get privacyDataControl => 'Kiểm soát dữ liệu';

  @override
  String get metricTransaction => 'Giao dịch';

  @override
  String get metricWallet => 'Ví';

  @override
  String get metricCategory => 'Danh mục';

  @override
  String get metricHasPhoto => 'Có ảnh';

  @override
  String get metricNoPhoto => 'Không ảnh';

  @override
  String get inventoryProfileTitle => 'Hồ sơ tài khoản';

  @override
  String get inventoryProfileDesc =>
      'Tên hiển thị, email, avatar, timezone và trạng thái đăng nhập.';

  @override
  String get inventoryWalletTitle => 'Ví';

  @override
  String get inventoryWalletDesc =>
      'Tên ví, loại ví, số dư ban đầu, trạng thái mặc định và hiển thị.';

  @override
  String get inventoryCategoryTitle => 'Danh mục';

  @override
  String get inventoryCategoryDesc =>
      'Tên danh mục, loại thu/chi, trạng thái mặc định và hiển thị.';

  @override
  String get inventoryTransactionTitle => 'Giao dịch';

  @override
  String get inventoryTransactionDesc =>
      'Số tiền, loại giao dịch, ví, danh mục, ghi chú và ngày giờ.';

  @override
  String get inventoryPhotoTitle => 'Ảnh giao dịch';

  @override
  String get inventoryPhotoDesc =>
      'Đường dẫn ảnh trong Storage private bucket, hiển thị qua signed URL.';

  @override
  String get inventorySettingsTitle => 'Thiết lập nhắc nhở';

  @override
  String get inventorySettingsDesc =>
      'Các tùy chọn nhắc ghi chi tiêu khi tính năng reminder được bật.';

  @override
  String get sensitiveDataDesc =>
      'Dữ liệu tài chính có thể gồm số tiền, ghi chú, ảnh hóa đơn và file đã xuất. Chỉ chia sẻ file export với người bạn tin cậy và xóa file cục bộ khi không còn cần dùng.';

  @override
  String localFilesExportCount(int count) {
    return '$count file đã xuất';
  }

  @override
  String localFilesLatest(String date) {
    return 'Gần nhất: $date';
  }

  @override
  String get localFilesNoExport => 'Chưa có file export';

  @override
  String get localFilesDesc =>
      'Các file CSV, Excel và PDF được tạo trên thiết bị này. Bạn có thể mở lại, chia sẻ hoặc tự xóa file trong bộ nhớ cục bộ.';

  @override
  String reportSummaryDesc(int txs, int wallets, int categories) {
    return 'Tài khoản này hiện có $txs giao dịch, $wallets ví và $categories danh mục.';
  }

  @override
  String reportPhotoDesc(int percent) {
    return '$percent% giao dịch đang có ảnh đính kèm trong dữ liệu của bạn.';
  }

  @override
  String reportExportDesc(int count) {
    return '$count file export đã được ghi nhận trên thiết bị này.';
  }

  @override
  String get reportPrivacyDesc =>
      'Moniary không bán dữ liệu cá nhân và chỉ dùng dữ liệu để vận hành trải nghiệm quản lý chi tiêu.';

  @override
  String get controlExportTitle => 'Xuất dữ liệu';

  @override
  String get controlExportDesc =>
      'Tạo file CSV, Excel hoặc PDF từ dữ liệu tài khoản.';

  @override
  String get controlContactTitle => 'Liên hệ quyền riêng tư';

  @override
  String get controlContactDesc =>
      'Tạo yêu cầu hỗ trợ về dữ liệu, quyền riêng tư hoặc xóa dữ liệu.';

  @override
  String get controlDeleteTitle => 'Xóa tài khoản';

  @override
  String get controlDeleteDesc =>
      'Mở xác nhận xóa tài khoản và toàn bộ dữ liệu liên quan.';

  @override
  String get freshOldestTx => 'Giao dịch cũ nhất';

  @override
  String get freshNewestTx => 'Giao dịch mới nhất';

  @override
  String get freshLatestExport => 'Lần xuất dữ liệu gần nhất';

  @override
  String get supportChecklistHero =>
      'Chuẩn bị đủ thông tin trước khi gửi yêu cầu giúp team hỗ trợ nhanh hơn và tránh chia sẻ dữ liệu nhạy cảm không cần thiết.';

  @override
  String get supportChecklistActionTitle => 'Mô tả thao tác đã làm';

  @override
  String get supportChecklistActionDesc =>
      'Ghi rõ bạn đang export, xóa tài khoản, tạo request hay mở file nào.';

  @override
  String get supportChecklistErrorTitle => 'Thêm thông báo lỗi nếu có';

  @override
  String get supportChecklistErrorDesc =>
      'Copy nội dung lỗi hoặc mô tả màn hình đang hiển thị để team dễ kiểm tra.';

  @override
  String get supportChecklistFileTitle =>
      'Đính kèm file request/export khi phù hợp';

  @override
  String get supportChecklistFileDesc =>
      'Nếu là yêu cầu privacy hoặc xóa dữ liệu thủ công, gửi kèm file JSON đã tạo.';

  @override
  String get supportChecklistDiagnosticTitle => 'Copy diagnostic info';

  @override
  String get supportChecklistDiagnosticDesc =>
      'Gửi kèm version, build và kênh release từ Trung tâm trợ giúp.';

  @override
  String get supportChecklistSensitiveTitle => 'Không gửi dữ liệu quá nhạy cảm';

  @override
  String get supportChecklistSensitiveDesc =>
      'Không gửi mật khẩu, access token hoặc ảnh hóa đơn nhạy cảm nếu không thật sự cần thiết.';

  @override
  String get dataSafetyPersonalInfoTitle => 'Personal info';

  @override
  String get dataSafetyPersonalInfoStatus =>
      'Có, khi đăng nhập email hoặc Google';

  @override
  String get dataSafetyPersonalInfoDesc =>
      'Tên hiển thị, email, avatar và user ID dùng cho đăng nhập và đồng bộ dữ liệu.';

  @override
  String get dataSafetyFinancialInfoTitle => 'Financial info';

  @override
  String get dataSafetyFinancialInfoStatus => 'Có';

  @override
  String get dataSafetyFinancialInfoDesc =>
      'Ví, danh mục, số tiền, ghi chú và ngày giao dịch do người dùng nhập.';

  @override
  String get dataSafetyPhotosTitle => 'Photos';

  @override
  String get dataSafetyPhotosStatus => 'Có, khi người dùng chủ động chọn/chụp';

  @override
  String get dataSafetyPhotosDesc =>
      'Ảnh giao dịch được lưu trong private storage và chỉ hiển thị qua signed URL.';

  @override
  String get dataSafetyUserIdTitle => 'User ID';

  @override
  String get dataSafetyUserIdStatus => 'Có';

  @override
  String get dataSafetyUserIdDesc =>
      'Dùng để gắn dữ liệu với đúng tài khoản và áp dụng RLS trên Supabase.';

  @override
  String get dataSafetyLocationTitle => 'Location, Contacts, SMS';

  @override
  String get dataSafetyLocationStatus => 'Không thu thập trong MVP';

  @override
  String get dataSafetyLocationDesc =>
      'Moniary không xin quyền vị trí, danh bạ hoặc đọc SMS/email để import giao dịch.';

  @override
  String get aboutMoniaryHeroTitle => 'Moniary';

  @override
  String get aboutMoniaryHeroDesc =>
      'Sổ tay thu chi cá nhân có kiểm soát dữ liệu rõ ràng cho người dùng.';

  @override
  String get aboutMoniaryVersionLabel => 'Phiên bản';

  @override
  String get aboutMoniaryBuildLabel => 'Build';

  @override
  String get aboutMoniaryChannelLabel => 'Kênh phát hành';

  @override
  String get aboutMoniaryLicenseTitle => 'Giấy phép mã nguồn mở';

  @override
  String get aboutMoniaryLicenseDesc =>
      'Xem license của Flutter và các package đang dùng trong app.';

  @override
  String get aboutMoniaryPurposeTitle => 'Mục đích';

  @override
  String get aboutMoniaryPurposeDesc =>
      'Moniary giúp người dùng ghi lại thu chi cá nhân, quản lý ví, danh mục và ảnh giao dịch trong một trải nghiệm đơn giản.';

  @override
  String get aboutMoniaryDataDirTitle => 'Định hướng dữ liệu';

  @override
  String get aboutMoniaryDataDirDesc =>
      'Dữ liệu tài chính thuộc về người dùng. App cung cấp công cụ xuất dữ liệu, xóa tài khoản và liên hệ privacy khi cần hỗ trợ.';

  @override
  String get aboutMoniaryMvpStatusTitle => 'Trạng thái MVP';

  @override
  String get aboutMoniaryMvpStatusDesc =>
      'Phiên bản hiện tại tập trung vào ghi chép chi tiêu, minh bạch dữ liệu và các yêu cầu cần thiết để chuẩn bị phát hành Store.';

  @override
  String get permissionInternetTitle => 'Internet';

  @override
  String get permissionInternetStatus => 'Cần thiết';

  @override
  String get permissionInternetDesc =>
      'Dùng để đăng nhập, đồng bộ Supabase Database và tải ảnh giao dịch từ Storage.';

  @override
  String get permissionCameraTitle => 'Camera';

  @override
  String get permissionCameraStatus => 'Chỉ hỏi khi người dùng chụp ảnh';

  @override
  String get permissionCameraDesc =>
      'Dùng để chụp hóa đơn hoặc hình ảnh liên quan đến giao dịch.';

  @override
  String get permissionPhotoTitle => 'Photo Picker';

  @override
  String get permissionPhotoStatus => 'Chỉ mở khi người dùng chọn ảnh';

  @override
  String get permissionPhotoDesc =>
      'Dùng Android Photo Picker để chọn ảnh mà không cần đọc toàn bộ thư viện.';

  @override
  String get permissionNotiTitle => 'Notifications';

  @override
  String get permissionNotiStatus => 'Chỉ dùng khi bật nhắc nhở';

  @override
  String get permissionNotiDesc =>
      'MVP hiện không bắt buộc quyền này nếu chưa triển khai reminder production.';

  @override
  String get permissionLocationTitle => 'Không dùng Location, Contacts, SMS';

  @override
  String get permissionLocationStatus => 'Không khai báo trong MVP';

  @override
  String get permissionLocationDesc =>
      'Moniary không cần vị trí, danh bạ hoặc SMS để ghi chi tiêu bằng ảnh.';

  @override
  String get privacyPolicyLeadTitle =>
      'Moniary bảo vệ dữ liệu chi tiêu cá nhân của bạn.';

  @override
  String get privacyPolicyLeadDesc =>
      'Nội dung này dùng cho màn hình trong app và làm bản nháp public Privacy Policy trước khi submit Google Play.';

  @override
  String get privacyPolicyDataTitle => 'Dữ liệu Moniary xử lý';

  @override
  String get privacyPolicyDataItem1 =>
      'Thông tự tài khoản như tên hiển thị, email, avatar và user ID khi người dùng đăng nhập.';

  @override
  String get privacyPolicyDataItem2 =>
      'Dữ liệu tài chính do người dùng nhập gồm ví, danh mục, giao dịch, số tiền, ghi chú và ngày giờ.';

  @override
  String get privacyPolicyDataItem3 =>
      'Ảnh giao dịch do người dùng chụp hoặc chọn từ thiết bị.';

  @override
  String get privacyPolicyDataItem4 =>
      'Thiết lập ứng dụng như nhắc nhở và tùy chọn hồ sơ.';

  @override
  String get privacyPolicyPurposeTitle => 'Mục đích sử dụng';

  @override
  String get privacyPolicyPurposeItem1 =>
      'Đăng nhập, đồng bộ dữ liệu và khôi phục dữ liệu khi đổi thiết bị.';

  @override
  String get privacyPolicyPurposeItem2 =>
      'Hiển thị lịch chi tiêu, chi tiết giao dịch, bộ lọc và thống kê tháng.';

  @override
  String get privacyPolicyPurposeItem3 =>
      'Lưu ảnh giao dịch trong Supabase Storage private bucket và cấp signed URL khi cần hiển thị.';

  @override
  String get privacyPolicyPurposeItem4 =>
      'Bảo vệ tài khoản, kiểm soát truy cập bằng RLS và hỗ trợ người dùng khi có yêu cầu.';

  @override
  String get privacyPolicyShareTitle => 'Chia sẻ dữ liệu';

  @override
  String get privacyPolicyShareItem1 =>
      'Moniary không bán dữ liệu cá nhân hoặc dữ liệu tài chính của người dùng.';

  @override
  String get privacyPolicyShareItem2 =>
      'Dữ liệu được lưu trên Supabase để cung cấp Auth, Database và Storage cho ứng dụng.';

  @override
  String get privacyPolicyShareItem3 =>
      'MVP không đọc vị trí, danh bạ, SMS, email cá nhân hoặc dữ liệu ngân hàng tự động.';

  @override
  String get privacyPolicyDeleteTitle => 'Xóa dữ liệu';

  @override
  String get privacyPolicyDeleteItem1 =>
      'Người dùng có thể xóa từng giao dịch trong app.';

  @override
  String get privacyPolicyDeleteItem2 =>
      'Người dùng có thể xuất dữ liệu CSV trước khi xóa tài khoản.';

  @override
  String get privacyPolicyDeleteItem3 =>
      'Khi xóa tài khoản, Moniary yêu cầu xóa hồ sơ, ví, danh mục, giao dịch và ảnh trong Storage thuộc user ID hiện tại.';

  @override
  String get privacyPolicySafetyTitle => 'Khai báo Google Play Data Safety';

  @override
  String get privacyPolicySafetyItem1 =>
      'Personal info: chỉ thu thập khi người dùng đăng nhập bằng email hoặc Google.';

  @override
  String get privacyPolicySafetyItem2 =>
      'Financial info: thu thập để lưu và hiển thị thu chi cá nhân.';

  @override
  String get privacyPolicySafetyItem3 =>
      'Photos: chỉ thu thập ảnh người dùng chủ động chụp hoặc chọn.';

  @override
  String get privacyPolicySafetyItem4 =>
      'Location, Contacts, SMS: không thu thập trong MVP.';

  @override
  String get privacyPolicyContactDesc =>
      'Trước khi phát hành, team cần đưa nội dung này lên một URL public và cập nhật email liên hệ chính thức trong Play Console.';

  @override
  String get deletionPolicyStep1Title => 'Trước khi xóa';

  @override
  String get deletionPolicyStep1Desc =>
      'Người dùng có thể xuất CSV để giữ lại lịch sử giao dịch cá nhân.';

  @override
  String get deletionPolicyStep2Title => 'Dữ liệu sẽ bị xóa';

  @override
  String get deletionPolicyStep2Desc =>
      'Hồ sơ, ví, danh mục, giao dịch, thiết lập nhắc nhở và ảnh trong Storage thuộc user ID hiện tại.';

  @override
  String get deletionPolicyStep3Title => 'Cách xóa';

  @override
  String get deletionPolicyStep3Desc =>
      'App gọi Edge Function delete-account. Function xác thực session, xóa ảnh giao dịch rồi xóa Auth user.';

  @override
  String get deletionPolicyStep4Title => 'Dữ liệu ngoài app';

  @override
  String get deletionPolicyStep4Desc =>
      'Nếu cần xóa dữ liệu backup, log hoặc yêu cầu ngoài app, người dùng có thể liên hệ qua kênh privacy support của team.';

  @override
  String get termsOfUseHeroDesc =>
      'Các điều khoản này tóm tắt cách người dùng nên sử dụng Moniary trong phiên bản MVP.';

  @override
  String get termsOfUseScopeTitle => '1. Phạm vi sử dụng';

  @override
  String get termsOfUseScopeDesc =>
      'Moniary được cung cấp để người dùng ghi chép và tự quản lý dữ liệu thu chi cá nhân. Người dùng chịu trách nhiệm về độ chính xác của dữ liệu đã nhập.';

  @override
  String get termsOfUseAccountTitle => '2. Dữ liệu tài khoản';

  @override
  String get termsOfUseAccountDesc =>
      'Người dùng có thể xuất dữ liệu, gửi yêu cầu privacy và xóa tài khoản theo các công cụ được cung cấp trong app.';

  @override
  String get termsOfUseContentTitle => '3. Nội dung người dùng';

  @override
  String get termsOfUseContentDesc =>
      'Ghi chú, số tiền và ảnh giao dịch do người dùng nhập hoặc tải lên chỉ nên phục vụ mục đích quản lý chi tiêu cá nhân.';

  @override
  String get termsOfUseLiabilityTitle => '4. Giới hạn trách nhiệm';

  @override
  String get termsOfUseLiabilityDesc =>
      'Moniary không phải công cụ tư vấn tài chính, kế toán, thuế hoặc pháp lý. Các thống kê trong app chỉ có tính tham khảo.';

  @override
  String get termsOfUseChangesTitle => '5. Thay đổi điều khoản';

  @override
  String get termsOfUseChangesDesc =>
      'Điều khoản có thể được cập nhật khi app bổ sung tính năng hoặc chuẩn bị phát hành chính thức.';

  @override
  String get transactionOcrExtracting => 'Đang trích xuất dữ liệu...';

  @override
  String get exportSheetTransactions => 'Giao dịch';

  @override
  String get exportColumnDataType => 'Loại dữ liệu';

  @override
  String get exportColumnId => 'ID';

  @override
  String get exportColumnName => 'Tên';

  @override
  String get exportColumnImagePath => 'Đường dẫn ảnh';

  @override
  String get exportColumnCreatedAt => 'Tạo lúc';

  @override
  String get exportReportGeneratedAt => 'Tạo báo cáo lúc';

  @override
  String get exportReportRecentTransactions => 'Giao dịch gần đây';

  @override
  String get dataRetentionCloudTitle => 'Dữ liệu trên cloud';

  @override
  String get dataRetentionCloudDesc =>
      'Hồ sơ, ví, danh mục, giao dịch và đường dẫn ảnh giao dịch được giữ khi tài khoản còn hoạt động để app có thể đồng bộ và hiển thị lại dữ liệu.';

  @override
  String get dataRetentionPhotosTitle => 'Ảnh giao dịch';

  @override
  String get dataRetentionPhotosDesc =>
      'Ảnh giao dịch chỉ được lưu khi người dùng chủ động chụp hoặc chọn ảnh. Ảnh sẽ được xử lý cùng dữ liệu tài khoản khi xóa tài khoản.';

  @override
  String get dataRetentionLocalFilesTitle => 'File cục bộ';

  @override
  String get dataRetentionLocalFilesDesc =>
      'File export và lịch sử request được tạo trên thiết bị. Người dùng có thể tự quản lý, chia sẻ hoặc xóa các file này khỏi bộ nhớ cục bộ.';

  @override
  String get dataRetentionDeleteTitle => 'Sau khi xóa tài khoản';

  @override
  String get dataRetentionDeleteDesc =>
      'Moniary gọi luồng xóa tài khoản để gỡ dữ liệu app gắn với user hiện tại. Nếu thao tác thất bại, người dùng có thể tạo request xóa dữ liệu thủ công.';

  @override
  String get financialDisclaimerInvestmentTitle => 'Không phải tư vấn đầu tư';

  @override
  String get financialDisclaimerInvestmentDesc =>
      'Moniary không đề xuất mua, bán, đầu tư hoặc phân bổ tài sản. Người dùng tự chịu trách nhiệm với quyết định tài chính của mình.';

  @override
  String get financialDisclaimerTaxTitle => 'Không phải tư vấn thuế/kế toán';

  @override
  String get financialDisclaimerTaxDesc =>
      'Dữ liệu trong app không thay thế chứng từ, báo cáo kế toán hoặc tư vấn thuế chuyên nghiệp.';

  @override
  String get financialDisclaimerReferenceTitle => 'Số liệu có tính tham khảo';

  @override
  String get financialDisclaimerReferenceDesc =>
      'Tổng thu, tổng chi và các file export phụ thuộc vào dữ liệu người dùng nhập, có thể sai nếu nhập thiếu hoặc nhập nhầm.';

  @override
  String get financialDisclaimerExpertTitle => 'Khi cần quyết định quan trọng';

  @override
  String get financialDisclaimerExpertDesc =>
      'Người dùng nên kiểm tra lại dữ liệu gốc và hỏi chuyên gia phù hợp trước các quyết định tài chính, thuế hoặc pháp lý.';

  @override
  String get policyChangelogEntry1Title => 'Bổ sung Legal & Policy Center';

  @override
  String get policyChangelogEntry1Desc =>
      'Thêm chính sách lưu giữ dữ liệu, thông báo dịch vụ bên thứ ba, miễn trừ tài chính và lịch sử thay đổi chính sách.';

  @override
  String get policyChangelogEntry2Title => 'Bổ sung Privacy Requests & Support';

  @override
  String get policyChangelogEntry2Desc =>
      'Thêm loại yêu cầu privacy, mẫu nội dung, preview, lịch sử request, trạng thái và timeline phản hồi.';

  @override
  String get policyChangelogEntry3Title => 'Bổ sung Store Readiness & Trust';

  @override
  String get policyChangelogEntry3Desc =>
      'Thêm About, Terms of Use, license entry, version/build info, checklist phát hành và liên hệ pháp lý.';

  @override
  String get policyChangelogEntry4Title => 'Khởi tạo chính sách MVP';

  @override
  String get policyChangelogEntry4Desc =>
      'Thêm privacy policy, data safety, data deletion policy, export dữ liệu và xóa tài khoản.';

  @override
  String get groupCreateNew => 'Tạo nhóm mới';

  @override
  String get groupDescriptionLabel => 'Mô tả';

  @override
  String get groupTypeLabel => 'Loại nhóm';

  @override
  String get groupTypeHint =>
      'Ví dụ: Du lịch, Ăn uống, Ở chung, Couple, Bạn bè...';

  @override
  String get groupAvatarLabel => 'Ảnh nhóm';

  @override
  String get groupChooseImage => 'Chọn ảnh';

  @override
  String get groupNameRequired => 'Tên nhóm là bắt buộc.';

  @override
  String groupTotalSpent(String amount) {
    return 'Tổng chi $amount';
  }

  @override
  String get groupBalanceSettled => 'Đã cân bằng';

  @override
  String groupBalanceOwes(String amount) {
    return 'Bạn cần trả $amount';
  }

  @override
  String groupBalanceReceives(String amount) {
    return 'Bạn sẽ nhận $amount';
  }

  @override
  String get groupUnresolvedBadge => 'Chưa xử lý';

  @override
  String get groupOverviewTitle => 'Tổng quan';

  @override
  String get groupTransactionsTitle => 'Giao dịch nhóm';

  @override
  String get groupDebtAreaTitle => 'Ai nợ ai';

  @override
  String get groupLeave => 'Rời nhóm';

  @override
  String get groupLeaveConfirmTitle => 'Rời nhóm này?';

  @override
  String get groupLeaveConfirmMessage =>
      'Bạn chỉ có thể rời nhóm khi công nợ đã được xử lý và quyền owner đã được chuyển nếu cần.';

  @override
  String get groupLeaveBlocked =>
      'Bạn ơi! bạn còn vài khoản thu chi chưa được xử lý kìa.';

  @override
  String get groupOwnerTransferRequired =>
      'Bạn cần chuyển quyền owner hoặc thêm một owner khác trước khi rời nhóm.';

  @override
  String get groupOwnerRequired =>
      'Chỉ owner của nhóm mới có thể thực hiện thao tác này.';

  @override
  String get groupOwnerTransferTargetRequired =>
      'Vui lòng chọn một thành viên đang tham gia khác để làm owner.';

  @override
  String get groupTransferOwnership => 'Chuyển owner';

  @override
  String groupTransferOwnershipConfirm(String member) {
    return 'Chuyển quyền owner của nhóm cho $member?';
  }

  @override
  String get groupTransferOwnershipDone => 'Đã chuyển quyền owner của nhóm.';

  @override
  String get groupInviteTitle => 'Mời thành viên';

  @override
  String get groupInviteAfterCreate => 'Mời thành viên sau khi tạo nhóm';

  @override
  String get groupInviteByUsername => 'Mời bằng username';

  @override
  String get groupUsernameLabel => 'Username';

  @override
  String get groupInviteAction => 'Gửi lời mời';

  @override
  String get groupInviteLinkTitle => 'Link mời nhóm';

  @override
  String get groupCreateInviteLink => 'Tạo link mời';

  @override
  String get groupInviteLinkCreated => 'Đã tạo link mời nhóm.';

  @override
  String get groupCopyInviteLink => 'Sao chép link';

  @override
  String get groupShareInviteLink => 'Chia sẻ link';

  @override
  String get groupInviteLinkCopied => 'Đã sao chép link mời nhóm.';

  @override
  String groupInviteShareMessage(String link) {
    return 'Tham gia nhóm chi tiêu của mình trên Moniary nhé: $link';
  }

  @override
  String get groupInviteSent => 'Đã gửi lời mời.';

  @override
  String get groupUserNotFound => 'Không tìm thấy người dùng này.';

  @override
  String get groupNoFriends => 'Bạn chưa có bạn bè nào để mời.';

  @override
  String get groupFriendInviteTitle => 'Mời từ danh sách bạn bè';

  @override
  String get groupInviteAcceptTitle => 'Lời mời vào nhóm';

  @override
  String groupInviteAcceptSubtitle(String group, String inviter) {
    return 'Bạn được mời tham gia nhóm $group bởi $inviter.';
  }

  @override
  String get groupInviteAcceptButton => 'Tham gia nhóm';

  @override
  String get groupInviteDeclineButton => 'Từ chối';

  @override
  String get groupInviteAccepted => 'Đã tham gia nhóm thành công.';

  @override
  String get groupInviteDeclined => 'Đã từ chối lời mời nhóm.';

  @override
  String get groupInviteLoading => 'Đang tải lời mời nhóm...';

  @override
  String get groupInvitePreviewError => 'Không tải được lời mời nhóm.';

  @override
  String get groupInviteInvalid => 'Link mời nhóm không hợp lệ.';

  @override
  String get groupInviteExpired => 'Link mời nhóm đã hết hạn.';

  @override
  String get groupInviteAlreadyMember => 'Bạn đã là thành viên của nhóm này.';

  @override
  String get groupInviteAlreadyAccepted => 'Link mời nhóm đã được sử dụng.';

  @override
  String get groupInviteDeclinedStatus => 'Link mời nhóm đã bị từ chối.';

  @override
  String get groupInviteGroupArchived => 'Nhóm này đã được lưu trữ.';

  @override
  String get groupInviteOpenGroups => 'Xem nhóm chi tiêu';

  @override
  String groupInviteMemberCount(int count) {
    return '$count thành viên';
  }

  @override
  String get groupMemberInvited => 'Đã mời';

  @override
  String get groupMemberActive => 'Đang tham gia';

  @override
  String get groupAddTransaction => 'Thêm giao dịch nhóm';

  @override
  String get groupTransactionCaption => 'Caption';

  @override
  String get groupTransactionNote => 'Ghi chú';

  @override
  String get groupTransactionTotal => 'Tổng tiền';

  @override
  String get groupTransactionCategory => 'Danh mục';

  @override
  String get groupTransactionImage => 'Ảnh hóa đơn';

  @override
  String get groupTransactionImageOptional =>
      'Ảnh không bắt buộc nhưng được khuyến khích.';

  @override
  String get groupTransactionImageUploadFailed =>
      'Upload ảnh thất bại. Hãy chọn lại ảnh để thử lại.';

  @override
  String get groupSplitModeTitle => 'Cách chia tiền';

  @override
  String get groupSplitEqual => 'Chia đều';

  @override
  String get groupSplitUnequal => 'Chia không đều';

  @override
  String get groupPaymentModeTitle => 'Người đã trả tiền';

  @override
  String get groupPaymentEveryone => 'Mọi người đều trả';

  @override
  String get groupPaymentSingle => 'Một người trả';

  @override
  String get groupPaymentMultiple => 'Nhiều người trả';

  @override
  String get groupSelectPayer => 'Vui lòng chọn người đã trả tiền.';

  @override
  String get groupSelectAtLeastTwoPayers =>
      'Vui lòng chọn ít nhất 2 người đã trả tiền.';

  @override
  String get groupEnterPayerAmounts =>
      'Vui lòng nhập số tiền đã trả cho từng thành viên.';

  @override
  String get groupPayerAmountPositive => 'Số tiền đã trả phải lớn hơn 0.';

  @override
  String get groupPaidTotalMismatch =>
      'Tổng số tiền đã trả chưa khớp với tổng giá trị giao dịch.';

  @override
  String get groupConfirmationTitle => 'Bạn đã chắc chắn chưa?';

  @override
  String get groupPost => 'Đăng';

  @override
  String get groupPosting => 'Đang đăng...';

  @override
  String get groupTransactionPosted =>
      'Giao dịch nhóm đã được đăng thành công.';

  @override
  String get groupTransactionPendingAmounts =>
      'Vui lòng nhập số tiền bạn đã sử dụng trong giao dịch này.';

  @override
  String get groupTransactionAmountMismatch =>
      'Tổng số tiền các thành viên nhập chưa khớp với tổng tiền giao dịch. Vui lòng kiểm tra và nhập lại.';

  @override
  String get groupTransactionMembersPending =>
      'Vẫn còn thành viên chưa nhập số tiền đã sử dụng.';

  @override
  String get groupTransactionPendingStatus => 'Chờ thành viên nhập số tiền';

  @override
  String get groupTransactionMismatchStatus => 'Tổng tiền chưa khớp';

  @override
  String get groupTransactionPostedStatus => 'Đã đăng';

  @override
  String get groupTransactionNoData => 'Chưa có giao dịch nhóm.';

  @override
  String get groupTransactionLoadError => 'Không tải được giao dịch nhóm.';

  @override
  String get groupTransactionDetailTitle => 'Chi tiết giao dịch nhóm';

  @override
  String get groupTransactionCreator => 'Người đăng';

  @override
  String get groupTransactionPayers => 'Người đã trả';

  @override
  String get groupTransactionShares => 'Phần phải chịu';

  @override
  String get groupTransactionDeleteConfirm => 'Xóa giao dịch nhóm này?';

  @override
  String get groupTransactionCompletedEditWarning =>
      'Giao dịch này đã có khoản nợ được xác nhận. Nếu chỉnh sửa, hệ thống sẽ tính lại công nợ của nhóm. Bạn có chắc muốn tiếp tục không?';

  @override
  String get groupTransactionCreatorOnly =>
      'Chỉ người tạo giao dịch mới được sửa hoặc xóa.';

  @override
  String get groupAmountInputTitle => 'Số tiền bạn đã sử dụng';

  @override
  String get groupAmountUsedLabel => 'Số tiền đã sử dụng';

  @override
  String get groupAmountSubmit => 'Gửi số tiền';

  @override
  String get groupAmountNonNegative => 'Số tiền không được nhỏ hơn 0.';

  @override
  String get groupSettlementTitle => 'Công nợ nhóm';

  @override
  String get groupBalanceTableTitle => 'Bảng công nợ';

  @override
  String get groupYouNeedPay => 'Bạn cần trả';

  @override
  String get groupOthersNeedPayYou => 'Người khác cần trả cho bạn';

  @override
  String get groupMarkPaid => 'Đã trả nợ';

  @override
  String get groupConfirmReceived => 'Xác nhận đã nhận';

  @override
  String get groupSettlementPending => 'Chờ thanh toán';

  @override
  String get groupSettlementPayerMarked => 'Người trả đã báo thanh toán';

  @override
  String get groupSettlementCompleted => 'Đã hoàn tất';

  @override
  String get groupSettlementDisputed => 'Đang tranh chấp';

  @override
  String get groupSettlementEmpty => 'Không có khoản nợ cần xử lý.';

  @override
  String groupSettlementFromTo(String from, String to) {
    return '$from trả $to';
  }

  @override
  String groupSharePaidBalance(String share, String paid, String balance) {
    return 'Chịu $share • Đã trả $paid • Cân đối $balance';
  }

  @override
  String get groupCommentsTitle => 'Bình luận';

  @override
  String get groupCommentHint => 'Nhập bình luận...';

  @override
  String get groupCommentSend => 'Gửi';

  @override
  String get groupCommentsEmpty => 'Chưa có bình luận.';

  @override
  String get groupCommentRequired => 'Vui lòng nhập nội dung bình luận.';

  @override
  String get groupCommentDeleteConfirm => 'Xóa bình luận này?';

  @override
  String get groupUnknownMember => 'Thành viên';

  @override
  String get groupNoCategory => 'Chưa chọn danh mục';

  @override
  String get groupChooseCategory => 'Chọn danh mục';

  @override
  String get groupAmountRequired => 'Vui lòng nhập tổng tiền lớn hơn 0.';

  @override
  String get groupActionFailed =>
      'Không thể thực hiện thao tác nhóm. Vui lòng thử lại.';

  @override
  String get groupMemberAlreadyInvited =>
      'Người dùng này đã ở trong nhóm hoặc đang có lời mời.';

  @override
  String get groupInviteLinkPlaceholder =>
      'Sao chép hoặc chia sẻ link để mời thành viên vào nhóm.';

  @override
  String get groupStatsPlaceholder =>
      'Thống kê nhóm cơ bản dùng tổng chi và công nợ hiện tại.';

  @override
  String get groupStatsLoadError => 'Không tải được thống kê nhóm.';

  @override
  String get groupStatsTransactionCount => 'Số giao dịch';

  @override
  String get groupStatsPendingCount => 'Chờ xử lý';

  @override
  String get groupNotificationsTitle => 'Thông báo nhóm';

  @override
  String get groupNotificationsEmpty => 'Chưa có thông báo nhóm.';

  @override
  String get groupNotificationInvite => 'Bạn có lời mời vào nhóm.';

  @override
  String get groupNotificationMemberJoined =>
      'Có thành viên mới tham gia nhóm.';

  @override
  String get groupNotificationTransactionCreated => 'Có giao dịch nhóm mới.';

  @override
  String get groupNotificationOwnerTransferred =>
      'Quyền owner của nhóm đã được chuyển.';

  @override
  String get groupNotificationGeneric => 'Có cập nhật mới trong nhóm.';

  @override
  String get groupActivitiesTitle => 'Hoạt động nhóm';

  @override
  String get groupActivitiesEmpty => 'Chưa có hoạt động nhóm.';

  @override
  String get groupActivitiesLoadError => 'Không tải được hoạt động nhóm.';

  @override
  String groupActivityMemberJoined(String actor) {
    return '$actor đã tham gia nhóm.';
  }

  @override
  String groupActivityMemberLeft(String actor) {
    return '$actor đã rời nhóm.';
  }

  @override
  String groupActivityTransactionCreated(String actor) {
    return '$actor đã tạo giao dịch nhóm.';
  }

  @override
  String groupActivityTransactionPosted(String actor) {
    return '$actor đã đăng giao dịch nhóm.';
  }

  @override
  String groupActivityOwnerTransferred(String actor) {
    return '$actor đã chuyển quyền owner của nhóm.';
  }

  @override
  String groupActivityGeneric(String actor) {
    return '$actor đã cập nhật nhóm.';
  }

  @override
  String get groupLeaveWarningActivity =>
      'Có thành viên trong nhóm cố gắng rời khỏi nhóm khi chưa xử lý xong các khoản chi. Hãy cẩn thận.';

  @override
  String get cancel => 'Hủy';

  @override
  String get retry => 'Thử lại';

  @override
  String get friendsTitle => 'Bạn bè';

  @override
  String get friendsProfileSubtitle => 'Quản lý bạn bè và lời mời kết bạn';

  @override
  String get friendAdd => 'Thêm bạn';

  @override
  String get friendSearchUsername => 'Tìm bằng username';

  @override
  String get friendSearchHint => 'Ví dụ: an_nguyen';

  @override
  String get friendSearch => 'Tìm kiếm';

  @override
  String get friendSearchPrompt => 'Nhập username để tìm người dùng Moniary.';

  @override
  String friendSearchEmpty(String query) {
    return 'Không tìm thấy người dùng “$query”.';
  }

  @override
  String get friendSearchError => 'Không thể tìm bạn bè. Vui lòng thử lại.';

  @override
  String get friendLoadError => 'Không tải được danh sách bạn bè.';

  @override
  String get friendNoFriends => 'Bạn chưa có bạn bè nào.';

  @override
  String get friendNoFriendsSubtitle =>
      'Thêm bạn bè để mời vào nhóm chi tiêu nhanh hơn.';

  @override
  String get friendIncomingRequests => 'Lời mời kết bạn';

  @override
  String get friendOutgoingRequests => 'Đã gửi lời mời';

  @override
  String get friendAccept => 'Chấp nhận';

  @override
  String get friendDecline => 'Từ chối';

  @override
  String get friendCancel => 'Hủy lời mời';

  @override
  String get friendRemove => 'Xóa bạn';

  @override
  String get friendRemoveTitle => 'Xóa bạn bè?';

  @override
  String friendRemoveMessage(String name) {
    return 'Bạn có chắc muốn xóa $name khỏi danh sách bạn bè?';
  }

  @override
  String get friendRemoved => 'Đã xóa bạn bè.';

  @override
  String get friendRequestSent => 'Đã gửi lời mời kết bạn.';

  @override
  String get friendRequestAccepted => 'Đã chấp nhận lời mời kết bạn.';

  @override
  String get friendRequestDeclined => 'Đã từ chối lời mời kết bạn.';

  @override
  String get friendRequestCancelled => 'Đã hủy lời mời kết bạn.';

  @override
  String get friendRequestPending => 'Đang chờ phản hồi';

  @override
  String get friendIncomingPending => 'Người này đã gửi lời mời cho bạn';

  @override
  String get friendSendRequest => 'Kết bạn';

  @override
  String get friendAlreadyFriends => 'Đã là bạn bè';

  @override
  String get friendAlreadyExists => 'Hai bạn đã là bạn bè.';

  @override
  String get friendUserNotFound => 'Không tìm thấy người dùng này.';

  @override
  String get friendCannotAddSelf => 'Bạn không thể tự kết bạn với chính mình.';

  @override
  String get friendRequestAlreadyPending =>
      'Đã có lời mời kết bạn đang chờ xử lý.';

  @override
  String get friendRequestNotFound => 'Không tìm thấy lời mời kết bạn.';

  @override
  String get friendNotFound => 'Không tìm thấy bạn bè này.';

  @override
  String get friendShareInviteLink => 'Chia sẻ link kết bạn';

  @override
  String get friendInviteShareDescription =>
      'Gửi link cho người khác để họ kết bạn với bạn nhanh hơn.';

  @override
  String friendInviteShareMessage(String link) {
    return 'Kết bạn với mình trên Moniary nhé: $link';
  }

  @override
  String get friendInviteAcceptTitle => 'Lời mời kết bạn';

  @override
  String friendInviteAcceptSubtitle(String name) {
    return '$name muốn kết bạn với bạn trên Moniary.';
  }

  @override
  String get friendInviteAcceptButton => 'Kết bạn';

  @override
  String get friendInviteAccepted => 'Đã kết bạn thành công.';

  @override
  String get friendInviteLoading => 'Đang tải lời mời...';

  @override
  String get friendInvitePreviewError => 'Không tải được lời mời kết bạn.';

  @override
  String get friendInviteInvalid => 'Link kết bạn không hợp lệ.';

  @override
  String get friendInviteExpired => 'Link kết bạn đã hết hạn.';

  @override
  String get friendInviteUsed => 'Link kết bạn đã được sử dụng.';

  @override
  String get friendInviteRevoked => 'Link kết bạn đã bị hủy.';

  @override
  String get friendInviteSelf =>
      'Bạn không thể dùng link kết bạn của chính mình.';

  @override
  String get friendInviteAlreadyFriends => 'Hai bạn đã là bạn bè.';

  @override
  String get friendInviteOpenFriends => 'Xem danh sách bạn bè';

  @override
  String get profileUsernameHint =>
      '3-30 ký tự: chữ thường, số hoặc dấu gạch dưới';

  @override
  String get profileUsernameInvalid =>
      'Username phải có 3-30 ký tự và chỉ gồm chữ thường, số hoặc dấu gạch dưới.';
}
