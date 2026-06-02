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
  String get errorGeneric => 'Đã xảy ra lỗi. Vui lòng thử lại.';

  @override
  String get errorNotLoggedIn => 'Bạn chưa đăng nhập.';

  @override
  String get errorConnection => 'Lỗi kết nối. Vui lòng thử lại.';

  @override
  String get loginTitle => 'Moniary';

  @override
  String get loginSubtitle => 'Quản lý chi tiêu cá nhân';

  @override
  String get loginAnonymous => 'Bắt đầu dùng thử ẩn danh';

  @override
  String get loginTerms =>
      'Bằng cách tiếp tục, bạn đồng ý với các điều khoản sử dụng và chính sách bảo mật của Moniary.';

  @override
  String get loginFeatureSubtitle => 'Ghi chi tiêu bằng ảnh';

  @override
  String get loginHeader => 'Đăng nhập';

  @override
  String get loginGoogle => 'Đăng nhập với Google (Sắp có)';

  @override
  String get loginApple => 'Đăng nhập với Apple (Sắp có)';

  @override
  String get loginEmail => 'Đăng nhập với Email (Sắp có)';

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
  String scanQuantity(int quantity) {
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
  String get profilePrivacyCenter => 'Bảo mật & Quyền riêng tư';

  @override
  String get profilePrivacySubtitle =>
      'Quản lý privacy policy, dữ liệu và quyền truy cập.';

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
  String get weeklyReport => 'Báo cáo hàng tuần';

  @override
  String get monthlyReport => 'Báo cáo hàng tháng';

  @override
  String get yearlyReport => 'Báo cáo hàng năm';

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
  String get deleteAccountConfirmationText => 'XOA TAI KHOAN';

  @override
  String deleteAccountConfirmInput(String text) {
    return 'Nhập $text để xác nhận';
  }

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
  String get exportHistoryTitle => 'Lịch sử xuất dữ liệu';

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
  String get cameraNoPermission => 'Cần quyền truy cập camera.';

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
  String get profileLinkSuccess => 'Liên kết tài khoản email thành công!';

  @override
  String get profileLinkGoogleBrowser =>
      'Hoàn tất liên kết Google trong trình duyệt để quay lại Moniary.';

  @override
  String profileLinkGoogleError(String error) {
    return 'Lỗi liên kết Google: $error';
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
  String get privacyDataSafety => 'Data Safety';

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
  String get privacyCenterHideBalancesTitle => 'Chế độ ẩn số dư';

  @override
  String get privacyCenterHideBalancesSubtitle =>
      'Tự động làm mờ tất cả số tiền trên ứng dụng.';

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
}
