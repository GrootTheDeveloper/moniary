// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Vietnamese (`vi`).
class AppLocalizationsVi extends AppLocalizations {
  AppLocalizationsVi([String locale = 'vi']) : super(locale);

  @override
  String get budgetEditLimit => 'Chỉnh sửa hạn mức';

  @override
  String get budgetQuickPresets => 'Gợi ý nhanh';

  @override
  String get budgetWarningThreshold => 'Cảnh báo khi chạm';

  @override
  String get budgetCategoryDetailTitle => 'Chi tiết ngân sách';

  @override
  String get budgetTransactionsInLimit => 'Giao dịch tính vào hạn mức';

  @override
  String get budgetNoTransactions =>
      'Chưa có giao dịch nào trong danh mục này.';

  @override
  String get appName => 'Moniary';

  @override
  String get commonSave => 'Lưu';

  @override
  String get commonSaved => 'Đã lưu';

  @override
  String get commonCancel => 'Hủy';

  @override
  String get commonDelete => 'Xóa';

  @override
  String get commonEdit => 'Sửa';

  @override
  String get commonRetry => 'Thử lại';

  @override
  String get commonJustNow => 'Vừa xong';

  @override
  String commonMinutesAgo(int count) {
    return '$count phút trước';
  }

  @override
  String commonHoursAgo(int count) {
    return '$count giờ trước';
  }

  @override
  String commonDaysAgo(int count) {
    return '$count ngày trước';
  }

  @override
  String get commonAdd => 'Thêm';

  @override
  String get commonClose => 'Đóng';

  @override
  String get commonSaving => 'Đang lưu...';

  @override
  String get commonLoading => 'Đang tải...';

  @override
  String get commonCopy => 'Sao chép';

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
  String get errorLocalAuthUnavailable =>
      'Thiết bị này không hỗ trợ xác thực sinh trắc học hoặc mã khóa màn hình.';

  @override
  String get errorLocalAuthFailed =>
      'Không thể xác thực thiết bị. Vui lòng thử lại.';

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
  String get loginFacebook => 'Đăng nhập với Facebook';

  @override
  String get loginEmail => 'Đăng nhập với Email';

  @override
  String get loginOr => 'hoặc';

  @override
  String get loginConnecting => 'Đang đăng nhập...';

  @override
  String get loginTryWithoutAuth => 'Dùng thử không cần đăng nhập';

  @override
  String get loginSessionReady => 'Bạn đã đăng nhập. Đang mở lịch chi tiêu...';

  @override
  String get loginDataSecure =>
      'Dữ liệu của bạn được bảo vệ và đồng bộ an toàn.';

  @override
  String get loginForgotPassword => 'Quên mật khẩu?';

  @override
  String get loginNoAccount => 'Chưa có tài khoản?';

  @override
  String get loginRegisterNow => 'Đăng ký ngay';

  @override
  String get loginHaveAccount => 'Đã có tài khoản?';

  @override
  String get loginSocialDivider => 'Hoặc đăng nhập bằng';

  @override
  String get loginPasswordResetSent =>
      'Đã gửi hướng dẫn đặt lại mật khẩu qua email.';

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
  String get onboardingPillCapture => 'Chụp & lưu';

  @override
  String get onboardingPillCalendar => 'Xem theo ngày';

  @override
  String get onboardingPillStats => 'Thống kê';

  @override
  String get onboardingPage1Title1 => 'Quét hoá đơn,';

  @override
  String get onboardingPage1Title2 => 'ghi chép trong 1 chạm';

  @override
  String get onboardingPage1Subtitle => 'Đang nhận diện hoá đơn';

  @override
  String get onboardingPage1Caption =>
      'Quét hoá đơn và tự động điền số tiền, ngày, ví và danh mục.';

  @override
  String get onboardingPage2Title1 => 'Mỗi ngày là';

  @override
  String get onboardingPage2Title2 => 'một tấm ảnh nhỏ';

  @override
  String get onboardingPage2Subtitle =>
      'Cuối tháng nhìn lại như một cuốn album, không phải một bảng số.';

  @override
  String get onboardingPage2Caption =>
      'Mỗi giao dịch là một mảnh nhỏ trong nhật ký của bạn.';

  @override
  String get onboardingPage3Title1 => 'Ngân sách rõ ràng,';

  @override
  String get onboardingPage3Title2 => 'nhìn 3 giây là hiểu';

  @override
  String get onboardingPage3Subtitle =>
      'Vòng tiến độ theo từng danh mục, báo trước khi bạn sắp vượt hạn mức.';

  @override
  String get onboardingPage3Caption =>
      'Theo dõi hạn mức mà không cần đọc những bảng số phức tạp.';

  @override
  String get onboardingReceiptCategory => 'Ăn uống';

  @override
  String get onboardingReceiptDate => '15/6';

  @override
  String get onboardingReceiptAmount => '385.000';

  @override
  String get onboardingPhotoAmount => '−145.000 ₫';

  @override
  String get onboardingBudgetPercent => '70%';

  @override
  String get onboardingBudgetLabel => 'Ngân sách tháng';

  @override
  String get onboardingScanning => 'Đang nhận diện...';

  @override
  String get onboardingRecognized => 'Đã nhận diện!';

  @override
  String get onboardingCategoryFood => 'Ăn uống';

  @override
  String get onboardingCategoryTransport => 'Di chuyển';

  @override
  String get onboardingCategoryEntertainment => 'Giải trí';

  @override
  String get onboardingIncome => 'Thu nhập';

  @override
  String get onboardingExpenseLabel => 'Chi tiêu';

  @override
  String get onboardingStreakLabel => 'ngày';

  @override
  String get onboardingBudgetUsed => 'Đã dùng';

  @override
  String get onboardingBudgetWarning => 'Sắp vượt hạn mức!';

  @override
  String get onboardingInsightText => 'Chi ăn uống tăng 20%';

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
  String profileSurveyWelcomeTitle(String name) {
    return 'Rất vui được chào đón bạn, $name!';
  }

  @override
  String get profileSurveyWelcomeBody =>
      'Một vài lựa chọn ngắn sẽ giúp Moniary chuẩn bị trải nghiệm phù hợp với bạn.';

  @override
  String get profileSurveyFallbackName => 'bạn';

  @override
  String get profileSurveyOccupationTitle => 'Hiện tại bạn đang làm nghề gì?';

  @override
  String get profileSurveyOccupationBody =>
      'Để Moniary gợi ý danh mục và cách ghi chép phù hợp với bạn.';

  @override
  String get profileSurveyOccupationStudent => 'Sinh viên';

  @override
  String get profileSurveyOccupationOffice => 'Nhân viên văn phòng';

  @override
  String get profileSurveyOccupationFreelancer => 'Làm việc tự do';

  @override
  String get profileSurveyOccupationBusiness => 'Kinh doanh';

  @override
  String get profileSurveyOccupationOther => 'Khác';

  @override
  String get profileSurveyCurrencyTitle => 'Chọn loại tiền tệ bạn đang dùng';

  @override
  String get profileSurveyCurrencyBody =>
      'Moniary sẽ dùng đơn vị này khi hiển thị số dư và báo cáo.';

  @override
  String get profileSurveyCurrencyVnd => 'Vietnamese Dong';

  @override
  String get profileSurveyCurrencyVgo => 'Vietnamese Gold (SJC)';

  @override
  String get profileSurveyCurrencyUsd => 'United States Dollar';

  @override
  String get profileSurveyWalletTitle => 'Hãy tạo cho mình một chiếc Ví';

  @override
  String get profileSurveyWalletBody => 'Bạn đang có bao nhiêu tiền trong Ví?';

  @override
  String get profileSurveyWalletName => 'Tên ví';

  @override
  String get profileSurveyWalletDefaultName => 'Ví của tôi';

  @override
  String get profileSurveyAmountLabel => 'Số tiền';

  @override
  String get profileSurveyAmountHint => '0';

  @override
  String get profileSurveyNext => 'Tiếp tục';

  @override
  String get profileSurveyFinish => 'Tạo ví và bắt đầu';

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
  String get calendarAllFilter => 'Tất cả';

  @override
  String get calendarSaved => 'Đã lưu';

  @override
  String get calendarSearchLabel => 'Tìm';

  @override
  String get calendarWalletsCategoriesAction => 'Ví & mục';

  @override
  String get calendarMonthlyExpense => 'Tổng chi tháng';

  @override
  String get calendarMonthlyIncome => 'Tổng thu tháng';

  @override
  String get calendarEmptyMessage =>
      'Chưa có giao dịch nào trong tháng này. Bạn vẫn có thể chọn ngày hoặc nhấn + để thêm giao dịch.';

  @override
  String get calendarTodayEmptyMessage =>
      'Hôm nay chưa có giao dịch nào. Nhấn + để ghi lại khoản thu chi mới.';

  @override
  String calendarStatsMessage(int count, int days) {
    return '$count giao dịch trong $days ngày có hoạt động. Dữ liệu lịch đã được cập nhật.';
  }

  @override
  String calendarLoadError(String error) {
    return 'Không tải được lịch tháng: $error';
  }

  @override
  String get calendarStatsTab => 'Thống kê';

  @override
  String get navStatsLabel => 'Số liệu';

  @override
  String get navGroupsLabel => 'Nhóm';

  @override
  String get navProfileLabel => 'Tôi';

  @override
  String get calendarLoading => 'Đang đồng bộ lịch...';

  @override
  String get calendarEmptyTitle => 'Chưa có dữ liệu';

  @override
  String get calendarEmptyBody =>
      'Bạn chưa có giao dịch nào trong tháng này. Hãy thêm giao dịch để bắt đầu theo dõi.';

  @override
  String get calendarErrorTitle => 'Lỗi tải dữ liệu';

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
  String get calendarStarred => 'Quan trọng';

  @override
  String get calendarSearchHint => 'Tìm theo ghi chú hoặc danh mục...';

  @override
  String get calendarSearchPrompt => 'Nhập ghi chú hoặc danh mục để tìm kiếm.';

  @override
  String get calendarSearchNoResults => 'Không tìm thấy giao dịch nào.';

  @override
  String get calendarRecentSearches => 'Tìm gần đây';

  @override
  String get calendarRecentSearchCoffee => 'cà phê';

  @override
  String get calendarRecentSearchRide => 'grab';

  @override
  String get calendarRecentSearchMarket => 'siêu thị';

  @override
  String calendarSearchResultsHeader(String query, int count) {
    return 'Kết quả · \"$query\" · $count';
  }

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
  String get transactionAddForDay => 'Thêm khoản cho ngày này';

  @override
  String get transactionDayGridView => 'Ảnh';

  @override
  String get transactionDayListView => 'Danh sách';

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
  String get transactionAmountHint => '0';

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
  String get transactionCreateTitle => 'Thêm giao dịch';

  @override
  String get transactionEditTitle => 'Sửa giao dịch';

  @override
  String get transactionDetailTitle => 'Giao dịch';

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
  String get transactionSource => 'Nguồn';

  @override
  String get transactionSourceManual => 'Nhập thủ công';

  @override
  String get transactionSourceReceiptImage => 'Ảnh hóa đơn';

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
  String get walletUnknown => 'Ví không xác định';

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
    return 'Lỗi danh mục: $error';
  }

  @override
  String get categoryOther => 'Khác';

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
  String get groupListTitle => 'Nhóm';

  @override
  String groupListSection(int count) {
    return 'Nhóm của bạn · $count';
  }

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
  String get groupDetailKindLabel => 'Nhóm';

  @override
  String get groupMoreActions => 'Tác vụ nhóm';

  @override
  String groupTransactionCount(int count) {
    return '$count khoản';
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
  String get groupInvitationsTitle => 'Lời mời nhóm';

  @override
  String get groupInvitationsEmpty => 'Bạn chưa có lời mời nhóm nào.';

  @override
  String get groupInvitationsEmptySubtitle =>
      'Các lời mời qua username hoặc bạn bè sẽ xuất hiện tại đây.';

  @override
  String get groupInvitationsLoadError => 'Không thể tải lời mời nhóm.';

  @override
  String groupInvitationInvitedBy(String name) {
    return '$name đã mời bạn tham gia.';
  }

  @override
  String groupInvitationExpiresAt(String date) {
    return 'Hết hạn ngày $date';
  }

  @override
  String get groupInvitationAccept => 'Chấp nhận';

  @override
  String get groupInvitationDecline => 'Từ chối';

  @override
  String get groupInvitationDeclinedSuccess => 'Đã từ chối lời mời nhóm.';

  @override
  String get groupInvitationPending => 'Đang chờ';

  @override
  String get groupInvitationAccepted => 'Đã tham gia';

  @override
  String get groupInvitationDeclined => 'Đã từ chối';

  @override
  String get groupInvitationExpired => 'Đã hết hạn';

  @override
  String get groupInvitationRevoked => 'Đã thu hồi';

  @override
  String get groupInvitationInvalid => 'Lời mời không còn hợp lệ.';

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
  String get editProfileTitle => 'Chỉnh sửa hồ sơ';

  @override
  String get profileUserDefault => 'Người dùng Moniary';

  @override
  String get profileAnonymous => 'Chưa có email';

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
  String get profileMoniarySetup => 'Thiết lập Moniary';

  @override
  String get profileGeneralSection => 'Chung';

  @override
  String get profileSupportSection => 'Hỗ trợ';

  @override
  String get profilePrivacySafetySection => 'Quyền riêng tư & an toàn';

  @override
  String get profileDangerZoneSection => 'Vùng nguy hiểm';

  @override
  String get profileHowMoniaryWorksTitle => 'Cách Moniary hoạt động';

  @override
  String get profileHowMoniaryWorksSubtitle =>
      'Hướng dẫn nhanh để ghi nhận và xem lại tài chính cá nhân.';

  @override
  String get profileSetupGuideWalletTitle => 'Thiết lập ví';

  @override
  String get profileSetupGuideWalletBody =>
      'Tạo hoặc kiểm tra ví để mỗi giao dịch có nguồn tiền rõ ràng.';

  @override
  String get profileSetupGuideTransactionTitle => 'Thêm giao dịch';

  @override
  String get profileSetupGuideTransactionBody =>
      'Chụp chi tiêu bằng ảnh hoặc nhập giao dịch thủ công.';

  @override
  String get profileSetupGuideReviewTitle => 'Xem Calendar và Statistics';

  @override
  String get profileSetupGuideReviewBody =>
      'Dùng Calendar và Statistics để hiểu chi tiêu theo ngày và tháng.';

  @override
  String get profileSetupGuideExportTitle => 'Xuất và bảo vệ dữ liệu';

  @override
  String get profileSetupGuideExportBody =>
      'Xuất dữ liệu và kiểm tra quyền riêng tư khi cần.';

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
      'Mục đích app, trạng thái phiên bản hiện tại và thông tin phát hành.';

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
  String get reminderSectionTitle => 'Nhắc nhở trên thiết bị';

  @override
  String get reminderSectionDesc =>
      'Thông báo ngay trên máy, nhắc bạn ghi lại chi tiêu trong ngày.';

  @override
  String get reminderDailyTitle => 'Nhắc ghi chép hàng ngày';

  @override
  String reminderDailyDesc(String time) {
    return 'Mỗi ngày lúc $time';
  }

  @override
  String get reminderNotificationTitle => 'Đừng quên ghi lại chi tiêu nhé 💸';

  @override
  String get reminderNotificationBody =>
      'Dành vài giây ghi lại các giao dịch hôm nay của bạn.';

  @override
  String get reminderPermissionDenied =>
      'Hãy bật quyền thông báo trong cài đặt hệ thống để nhận nhắc nhở.';

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
      'Xóa ảnh giao dịch gắn với tài khoản hiện tại.';

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
  String get manageDataWalletTab => 'Ví';

  @override
  String get manageDataWalletCountLabel => 'ví';

  @override
  String get manageDataCategoryCountLabel => 'danh mục';

  @override
  String get cameraTakePhoto => 'Chụp';

  @override
  String get cameraFlip => 'Lật camera';

  @override
  String get cameraFlash => 'Đèn flash';

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
  String get deleteAccountHelpCreateRequest => 'Tạo yêu cầu xóa dữ liệu';

  @override
  String get deleteAccountHelpContactPrivacy => 'Liên hệ quyền riêng tư';

  @override
  String get legalContactHero =>
      'Các kênh liên hệ này giúp bạn gửi đúng yêu cầu về dữ liệu, hỗ trợ hoặc pháp lý.';

  @override
  String get legalContactPrivacyDesc =>
      'Yêu cầu dữ liệu cá nhân, xóa dữ liệu hoặc câu hỏi về quyền riêng tư.';

  @override
  String get legalContactSupportDesc =>
      'Hỗ trợ chung về app, file xuất dữ liệu hoặc thao tác người dùng.';

  @override
  String get legalContactLegalDesc =>
      'Vấn đề điều khoản, phát hành hoặc yêu cầu pháp lý.';

  @override
  String get legalContactPrivacy => 'Quyền riêng tư';

  @override
  String get legalContactSupport => 'Hỗ trợ';

  @override
  String get legalContactLegal => 'Pháp lý';

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
  String get statsWeeklySpending => 'Chi theo tuần';

  @override
  String get statsCategories => 'Danh mục';

  @override
  String statsMonthExpenseMeta(String month) {
    return 'Tổng chi · $month';
  }

  @override
  String statsExpenseLessThanPrevious(int percent) {
    return '↓ Ít hơn tháng trước là $percent%';
  }

  @override
  String statsExpenseMoreThanPrevious(int percent) {
    return '↑ Cao hơn tháng trước là $percent%';
  }

  @override
  String get statsExpenseSameAsPrevious => 'Gần bằng tháng trước';

  @override
  String get statsExpenseNoPrevious => 'Chưa có dữ liệu tháng trước';

  @override
  String get statsInsightTitle => 'Gợi ý thông minh';

  @override
  String statsInsightSavings(String percent) {
    return 'Bạn đã tiết kiệm được $percent% thu nhập trong tháng này.';
  }

  @override
  String statsInsightWeekend(String percent) {
    return 'Bạn chi tiêu $percent% ngân sách vào cuối tuần. Hãy cẩn thận!';
  }

  @override
  String statsInsightCategorySurge(String category, String percent) {
    return 'Chi tiêu $category tăng $percent% so với tháng trước.';
  }

  @override
  String get statsInsightPositive =>
      'Bạn đang quản lý chi tiêu rất tốt! Hãy tiếp tục duy trì nhé.';

  @override
  String statsBudgetUsed(int percent) {
    return 'Ngân sách · đã dùng $percent%';
  }

  @override
  String get statsBudgetNoLimit => 'Ngân sách';

  @override
  String statsWeekLabel(int week) {
    return 'Tuần $week';
  }

  @override
  String get statsMillionShort => 'tr';

  @override
  String get statsLargestTransactions => 'Giao dịch lớn nhất';

  @override
  String get starredTransactionsTitle => 'Giao dịch quan trọng';

  @override
  String get searchFilterType => 'Loại';

  @override
  String get searchFilterAll => 'Tất cả';

  @override
  String get searchFilterIncome => 'Thu nhập';

  @override
  String get searchFilterExpense => 'Chi tiêu';

  @override
  String get searchFilterCategory => 'Danh mục';

  @override
  String get searchFilterAllCategories => 'Tất cả danh mục';

  @override
  String get searchFilterDate => 'Ngày';

  @override
  String get searchFilterAmount => 'Số tiền';

  @override
  String get searchFilterAmountMin => 'Tối thiểu';

  @override
  String get searchFilterAmountMax => 'Tối đa';

  @override
  String get searchFilterApply => 'Áp dụng';

  @override
  String get searchFilterClearAll => 'Xóa bộ lọc';

  @override
  String get searchFilterImportance => 'Ưu tiên';

  @override
  String get searchImportanceImportant => 'Quan trọng';

  @override
  String get searchImportanceNotImportant => 'Không quan trọng';

  @override
  String get searchFilterSubscription => 'Đăng ký';

  @override
  String get searchSubscriptionYes => 'Từ đăng ký';

  @override
  String get searchSubscriptionNo => 'Không đăng ký';

  @override
  String get searchAmountRangeError => 'Số tiền tối đa phải lớn hơn tối thiểu';

  @override
  String get searchRecentClear => 'Xóa';

  @override
  String get recurringTitle => 'Định kỳ & đăng ký';

  @override
  String get recurringSubtitle =>
      'Đăng ký, lương, tiền thuê và các khoản lặp lại khác';

  @override
  String get recurringAdd => 'Thêm định kỳ';

  @override
  String get recurringEdit => 'Sửa định kỳ';

  @override
  String get recurringEmpty => 'Chưa có khoản định kỳ nào';

  @override
  String get recurringAmount => 'Số tiền';

  @override
  String get recurringType => 'Loại';

  @override
  String get recurringIncome => 'Thu nhập';

  @override
  String get recurringExpense => 'Chi tiêu';

  @override
  String get recurringWallet => 'Ví';

  @override
  String get recurringCategory => 'Danh mục';

  @override
  String get recurringNote => 'Ghi chú (tùy chọn)';

  @override
  String get recurringFrequency => 'Tần suất';

  @override
  String get recurringInterval => 'Mỗi';

  @override
  String get recurringDaily => 'Hàng ngày';

  @override
  String get recurringWeekly => 'Hàng tuần';

  @override
  String get recurringMonthly => 'Hàng tháng';

  @override
  String get recurringYearly => 'Hàng năm';

  @override
  String recurringEvery(int interval, String unit) {
    return 'Mỗi $interval × $unit';
  }

  @override
  String get recurringStartDate => 'Ngày bắt đầu';

  @override
  String get recurringNextRun => 'Lần chạy tới';

  @override
  String get recurringNextRunLabel => 'Kế tiếp';

  @override
  String get recurringEndDate => 'Ngày kết thúc';

  @override
  String get recurringNoEndDate => 'Không có ngày kết thúc';

  @override
  String get recurringAutoPost => 'Tự động ghi giao dịch';

  @override
  String get recurringAutoPostHelp => 'Tự động tạo giao dịch vào mỗi ngày chạy';

  @override
  String get recurringActive => 'Đang hoạt động';

  @override
  String get recurringPaused => 'Tạm dừng';

  @override
  String get recurringDeleteTitle => 'Xóa khoản định kỳ?';

  @override
  String get recurringDeleteMessage =>
      'Quy tắc định kỳ này sẽ bị xóa. Các giao dịch đã tạo vẫn được giữ lại.';

  @override
  String get recurringSaved => 'Đã lưu khoản định kỳ';

  @override
  String get recurringAmountRequired => 'Nhập số tiền lớn hơn 0';

  @override
  String get recurringNoWallets => 'Hãy tạo ví trước khi thêm khoản định kỳ';

  @override
  String get recurringNoCategories => 'Hãy tạo danh mục phù hợp trước';

  @override
  String get recurringApplyTitle => 'Cập nhật đăng ký?';

  @override
  String recurringApplyMessage(int count) {
    return 'Lưu thay đổi sẽ xóa $count giao dịch mà đăng ký này đã tạo và tạo lại theo thông tin mới.';
  }

  @override
  String get recurringApplyFutureOnly => 'Chỉ áp dụng từ lần tới';

  @override
  String get recurringApplyUpdate => 'Cập nhật các giao dịch đã tạo';

  @override
  String get recurringApplyDelete => 'Xóa hết và tạo lại';

  @override
  String get recurringDeleteKeepTx => 'Giữ lại giao dịch';

  @override
  String get recurringDeleteRemoveTx => 'Xóa luôn giao dịch';

  @override
  String recurringDeleteGeneratedMessage(int count) {
    return 'Đăng ký này đã tạo $count giao dịch. Bạn muốn xử lý chúng thế nào?';
  }

  @override
  String get starredTransactionsEmpty => 'Chưa có giao dịch quan trọng nào';

  @override
  String get statsCategoryTransactions => 'Giao dịch trong danh mục';

  @override
  String statsDayTooltip(int day, String amount) {
    return 'Ngày $day\n$amount';
  }

  @override
  String get profileProtectAccount => 'Bảo vệ tài khoản của bạn';

  @override
  String get profileLinkNow => 'Liên kết ngay';

  @override
  String get profileLinkAccountTitle => 'Liên kết tài khoản';

  @override
  String get profileLinkAccountSubtitle =>
      'Liên kết Email hoặc Google để đăng nhập trên nhiều thiết bị.';

  @override
  String get profileNewPassword => 'Mật khẩu mới';

  @override
  String get profileLinkEmail => 'Liên kết Email';

  @override
  String get profileLinkGoogle => 'Liên kết Google';

  @override
  String get profileLinkApple => 'Liên kết Apple';

  @override
  String get profileLinkFacebook => 'Liên kết Facebook';

  @override
  String get profileLinkSuccess => 'Liên kết tài khoản email thành công!';

  @override
  String get profileLinkGoogleBrowser =>
      'Hoàn tất liên kết Google trong trình duyệt để quay lại Moniary.';

  @override
  String get profileLinkAppleBrowser =>
      'Hoàn tất liên kết Apple trong trình duyệt để quay lại Moniary.';

  @override
  String get profileLinkFacebookBrowser =>
      'Hoàn tất liên kết Facebook trong trình duyệt để quay lại Moniary.';

  @override
  String profileLinkGoogleError(String error) {
    return 'Lỗi liên kết Google: $error';
  }

  @override
  String profileLinkAppleError(String error) {
    return 'Lỗi liên kết Apple: $error';
  }

  @override
  String profileLinkFacebookError(String error) {
    return 'Lỗi liên kết Facebook: $error';
  }

  @override
  String get profileEditInfo => 'Chỉnh sửa thông tin';

  @override
  String get profileChangeTimezone => 'Thay đổi múi giờ';

  @override
  String get profileMascotTitle => 'Linh vật ứng dụng';

  @override
  String get profileMascotSubtitle =>
      'Hiện linh vật hoạt hình trên thanh điều hướng dưới cùng.';

  @override
  String get profileLanguage => 'Ngôn ngữ';

  @override
  String get currencyPickerTitle => 'Chọn tiền tệ';

  @override
  String get currencyPickerSearch => 'Tìm tiền tệ...';

  @override
  String get currencyPickerNoResults => 'Không tìm thấy tiền tệ';

  @override
  String get currencyPickerPopular => 'Tiền tệ phổ biến';

  @override
  String get currencyPickerAll => 'Tất cả tiền tệ';

  @override
  String get profileFirstDayOfWeekLabel => 'Ngày đầu tuần';

  @override
  String get profileFirstDayOfWeekMon => 'Thứ Hai';

  @override
  String get profileFirstDayOfWeekSun => 'Chủ Nhật';

  @override
  String get profileLanguageVi => 'Tiếng Việt';

  @override
  String get profileLanguageEn => 'English';

  @override
  String get timezonePickerSearch => 'Tìm múi giờ';

  @override
  String get timezonePickerNoResults => 'Không tìm thấy múi giờ';

  @override
  String get timezonePickerUseDevice => 'Dùng múi giờ thiết bị';

  @override
  String get profileAnonymousBadge => 'Tài khoản chưa liên kết';

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
  String get exportTroubleshootingSupportTitle => '4. Tạo yêu cầu hỗ trợ';

  @override
  String get exportTroubleshootingSupportDesc =>
      'Nếu file không tạo được hoặc không mở được, hãy tạo yêu cầu hỗ trợ kèm mô tả lỗi.';

  @override
  String get legalDataDeletionPolicy => 'Chính sách xóa dữ liệu';

  @override
  String get legalDataRetention => 'Lưu giữ dữ liệu';

  @override
  String get legalFinancialDisclaimer => 'Miễn trừ tài chính';

  @override
  String get legalContact => 'Liên hệ pháp lý';

  @override
  String get legalCopyAllContacts => 'Sao chép tất cả liên hệ';

  @override
  String legalCopyAllText(
    String privacyEmail,
    String supportEmail,
    String legalEmail,
  ) {
    return 'Quyền riêng tư: $privacyEmail\nHỗ trợ: $supportEmail\nPháp lý: $legalEmail';
  }

  @override
  String get legalCopyContactSuccess => 'Đã sao chép thông tin liên hệ.';

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
  String get privacyLocalFiles => 'File trên thiết bị';

  @override
  String get privacyTransactionPhotos => 'Ảnh giao dịch';

  @override
  String get privacyViewExportHistory => 'Xem lịch sử xuất dữ liệu';

  @override
  String get privacyPermissionRationale => 'Quyền truy cập';

  @override
  String get privacyFaq => 'FAQ quyền riêng tư & tài khoản';

  @override
  String get privacyFaqHeroBody =>
      'Các câu hỏi thường gặp về dữ liệu cá nhân, xuất dữ liệu, xóa tài khoản và yêu cầu quyền riêng tư.';

  @override
  String get privacyFaqStoredDataQuestion => 'Moniary lưu những dữ liệu nào?';

  @override
  String get privacyFaqStoredDataAnswer =>
      'App lưu hồ sơ, ví, danh mục, giao dịch, ghi chú và đường dẫn ảnh giao dịch khi người dùng tạo dữ liệu trong app.';

  @override
  String get privacyFaqExportBeforeDeletionQuestion =>
      'Tôi có thể xuất dữ liệu trước khi xóa tài khoản không?';

  @override
  String get privacyFaqExportBeforeDeletionAnswer =>
      'Có. Bạn có thể xuất dữ liệu thành CSV, Excel hoặc PDF trong phần Xuất dữ liệu của tôi.';

  @override
  String get privacyFaqDeletionImagesQuestion =>
      'Xóa tài khoản có xóa ảnh giao dịch không?';

  @override
  String get privacyFaqDeletionImagesAnswer =>
      'Luồng xóa tài khoản được thiết kế để xóa dữ liệu app và ảnh giao dịch gắn với người dùng hiện tại.';

  @override
  String get privacyFaqDeletionFailQuestion =>
      'Nếu xóa tài khoản trực tiếp thất bại thì sao?';

  @override
  String get privacyFaqDeletionFailAnswer =>
      'Bạn có thể tạo file yêu cầu xóa dữ liệu thủ công và gửi cho kênh hỗ trợ quyền riêng tư.';

  @override
  String get privacyFaqExportLocationQuestion => 'File xuất dữ liệu nằm ở đâu?';

  @override
  String get privacyFaqExportLocationAnswer =>
      'File xuất dữ liệu được lưu trong thư mục tài liệu của app trên thiết bị và có thể mở hoặc chia sẻ từ lịch sử xuất dữ liệu.';

  @override
  String get privacyCenter => 'Trung tâm riêng tư';

  @override
  String get privacyContact => 'Liên hệ quyền riêng tư';

  @override
  String get privacyUseTemplate => 'Dùng mẫu nội dung';

  @override
  String get privacyCreateRequest => 'Tạo yêu cầu quyền riêng tư';

  @override
  String get privacyRequestCreated => 'Đã tạo yêu cầu';

  @override
  String get privacyCopyEmail => 'Sao chép email';

  @override
  String get privacyCopyInstructions => 'Sao chép hướng dẫn';

  @override
  String get privacyPolicyTitle => 'Chính sách bảo mật';

  @override
  String get privacyRequestDetailTitle => 'Chi tiết yêu cầu';

  @override
  String get privacyCopyFilePath => 'Sao chép đường dẫn file';

  @override
  String get privacyCopyFilePathSuccess => 'Đã sao chép đường dẫn file';

  @override
  String get privacyCopyRequest => 'Sao chép yêu cầu';

  @override
  String get privacyCopyRequestSuccess => 'Đã sao chép nội dung yêu cầu';

  @override
  String get storeAboutMoniary => 'Giới thiệu Moniary';

  @override
  String get storeComplianceChecklist => 'Checklist phát hành';

  @override
  String get storeTrustSafety => 'Tin cậy & an toàn';

  @override
  String get supportHelpCenter => 'Trung tâm trợ giúp';

  @override
  String get supportCopySuccess => 'Đã sao chép thông tin hỗ trợ.';

  @override
  String get supportCopyDiagnostic => 'Sao chép thông tin hỗ trợ';

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
  String get settingsAccountSection => 'Tài khoản';

  @override
  String get settingsDataSection => 'Dữ liệu';

  @override
  String get settingsLegalSupportSection => 'Pháp lý & trợ giúp';

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
  String get privacyContactCopyEmailSuccess => 'Đã sao chép email hỗ trợ.';

  @override
  String privacyContactCopyGuide(String email) {
    return 'Email: $email\nChủ đề: Yêu cầu hỗ trợ Moniary\nNội dung: Dán nội dung yêu cầu đã sao chép từ app.';
  }

  @override
  String get privacyContactCopyGuideSuccess =>
      'Đã sao chép hướng dẫn gửi yêu cầu.';

  @override
  String get privacyContactHeroTitle => 'Yêu cầu về dữ liệu cá nhân';

  @override
  String get privacyContactHeroDesc =>
      'Nếu không thể xử lý trực tiếp trong app, bạn có thể liên hệ nhóm hỗ trợ Moniary để được hỗ trợ về dữ liệu.';

  @override
  String get privacyContactEmailTitle => 'Email hỗ trợ';

  @override
  String get privacyContactEmailDesc =>
      'Dùng cho yêu cầu xóa dữ liệu, xuất dữ liệu hoặc câu hỏi về quyền riêng tư.';

  @override
  String get privacyContactInfoTitle => 'Thông tin cần gửi';

  @override
  String get privacyContactInfoValue => 'Mã tài khoản hoặc email đăng nhập';

  @override
  String get privacyContactInfoDesc =>
      'Không gửi mật khẩu, mã truy cập, ảnh hóa đơn nhạy cảm hoặc số tiền chi tiết qua email.';

  @override
  String get privacyContactTimeTitle => 'Thời gian phản hồi';

  @override
  String get privacyContactTimeValue => 'Trong vòng 7 ngày làm việc';

  @override
  String get privacyContactTimeDesc =>
      'Moniary sẽ cập nhật thời gian phản hồi thực tế khi phát hành chính thức.';

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
  String get privacyAndAccountTitle => 'Quyền riêng tư & tài khoản';

  @override
  String get privacyAndAccountSubtitle =>
      'Xem quyền dữ liệu, yêu cầu hỗ trợ và các lựa chọn liên quan tài khoản.';

  @override
  String get dataRightsTitle => 'Quyền dữ liệu';

  @override
  String get dataRightsSubtitle =>
      'Tóm tắt quyền xem, xuất, sửa/xóa dữ liệu và liên hệ quyền riêng tư.';

  @override
  String get exportDataSubTitle =>
      'Xử lý khi xuất CSV, Excel hoặc PDF lỗi, trống hoặc không tìm thấy file.';

  @override
  String get createExportFileTitle => 'Tạo file xuất dữ liệu';

  @override
  String get createExportFileSubtitle =>
      'Mở luồng xuất dữ liệu khi cần tạo bản sao dữ liệu cá nhân.';

  @override
  String get contactSupportSubtitle =>
      'Tạo yêu cầu quyền riêng tư hoặc sao chép thông tin liên hệ để gửi cho nhóm hỗ trợ.';

  @override
  String get deleteAccountSubtitle =>
      'Chuẩn bị trước khi xóa, hiểu dữ liệu bị ảnh hưởng và phương án xử lý khi có lỗi.';

  @override
  String get supportChecklistTitle => 'Checklist gửi hỗ trợ';

  @override
  String get supportChecklistSubtitle =>
      'Chuẩn bị mô tả lỗi, file liên quan và thông tin hỗ trợ trước khi gửi yêu cầu.';

  @override
  String get helpHeroText =>
      'Tìm nhanh các hướng dẫn liên quan đến dữ liệu, quyền riêng tư, xuất dữ liệu và hỗ trợ tài khoản trong Moniary.';

  @override
  String get supportDiagnosticTitle => 'Thông tin gửi hỗ trợ';

  @override
  String get supportDiagnosticSubtitle =>
      'Sao chép phiên bản, bản dựng và kênh liên hệ để gửi kèm khi báo lỗi.';

  @override
  String get helpCenterTitle => 'Trung tâm trợ giúp';

  @override
  String get helpCenterSubtitle =>
      'Tìm hướng dẫn về quyền riêng tư, tài khoản, xuất dữ liệu và cách liên hệ hỗ trợ.';

  @override
  String get aboutMoniaryTitle => 'Giới thiệu Moniary';

  @override
  String get aboutMoniarySubtitle =>
      'Xem mục đích app, định hướng dữ liệu và trạng thái phiên bản hiện tại.';

  @override
  String get privacyPolicySubtitle =>
      'Xem cách Moniary xử lý dữ liệu cá nhân, tài chính và ảnh giao dịch.';

  @override
  String get termsOfUseTitle => 'Điều khoản sử dụng';

  @override
  String get termsOfUseSubtitle =>
      'Xem phạm vi sử dụng, trách nhiệm người dùng và giới hạn của phiên bản hiện tại.';

  @override
  String get dataRetentionPolicyTitle => 'Chính sách lưu giữ dữ liệu';

  @override
  String get dataRetentionPolicySubtitle =>
      'Xem dữ liệu nào được đồng bộ theo tài khoản, dữ liệu nào nằm trên thiết bị và cách xử lý sau khi xóa tài khoản.';

  @override
  String get thirdPartyServicesTitle => 'Dịch vụ bên thứ ba';

  @override
  String get thirdPartyServicesSubtitle =>
      'Xem app đang dùng Supabase, Google Gemini, Flutter/package và bộ nhớ thiết bị như thế nào.';

  @override
  String get thirdPartyHeroBody =>
      'Thông báo này giúp người dùng hiểu app dựa vào dịch vụ nào để đăng nhập, lưu trữ và vận hành dữ liệu.';

  @override
  String get thirdPartySupabaseDescription =>
      'Được dùng cho đăng nhập, cơ sở dữ liệu, storage ảnh giao dịch, xóa tài khoản và edge function của trợ lý AI.';

  @override
  String get thirdPartyGeminiDescription =>
      'Chỉ dùng khi bạn bật trợ lý AI. Moniary gửi ngữ cảnh tài chính đã chọn qua Supabase Edge Function để tạo câu trả lời.';

  @override
  String get thirdPartyFlutterDescription =>
      'Framework giao diện chính của app, kèm các package hỗ trợ điều hướng, trạng thái, camera, chọn ảnh và xử lý file.';

  @override
  String get thirdPartyDeviceStorageTitle => 'Bộ nhớ thiết bị';

  @override
  String get thirdPartyDeviceStorageDescription =>
      'File export, request privacy và lịch sử export/request được ghi trong thư mục tài liệu của app trên thiết bị.';

  @override
  String get thirdPartyNoAdsTitle => 'Không tích hợp quảng cáo';

  @override
  String get thirdPartyNoAdsDescription =>
      'MVP không dùng SDK quảng cáo, tracking marketing, danh bạ, SMS, email inbox hoặc kết nối ngân hàng tự động.';

  @override
  String get releaseChecklistTitle => 'Checklist phát hành';

  @override
  String get releaseChecklistSubtitle =>
      'Rà soát quyền riêng tư, xuất dữ liệu, xóa tài khoản và kênh liên hệ trước khi phát hành.';

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
      'Xem các mốc cập nhật quyền riêng tư, pháp lý và chuẩn bị phát hành trong app.';

  @override
  String get userDataRightsTitle => 'Quyền dữ liệu của người dùng';

  @override
  String get userDataRightsSubtitle =>
      'Tóm tắt quyền xem dữ liệu, xuất dữ liệu, yêu cầu sửa/xóa và liên hệ privacy.';

  @override
  String get userRightsHeroBody =>
      'Người dùng có quyền hiểu dữ liệu nào đang được lưu, xuất dữ liệu của mình và gửi yêu cầu privacy khi cần.';

  @override
  String get userRightsAccessTitle => 'Xem dữ liệu đang lưu';

  @override
  String get userRightsAccessDescription =>
      'Người dùng có thể xem tổng quan dữ liệu, nhóm dữ liệu, ảnh giao dịch và file cục bộ.';

  @override
  String get userRightsExportTitle => 'Xuất dữ liệu';

  @override
  String get userRightsExportDescription =>
      'Người dùng có thể xuất dữ liệu ở định dạng CSV, Excel hoặc PDF trước khi chia sẻ hoặc rời app.';

  @override
  String get userRightsCorrectionTitle => 'Yêu cầu sửa hoặc hỗ trợ';

  @override
  String get userRightsCorrectionDescription =>
      'Người dùng có thể tạo yêu cầu privacy nếu dữ liệu cần kiểm tra, sửa hoặc giải thích thêm.';

  @override
  String get userRightsDeletionTitle => 'Yêu cầu xóa dữ liệu';

  @override
  String get userRightsDeletionDescription =>
      'Người dùng có thể xóa tài khoản trong app hoặc tạo request thủ công khi luồng trực tiếp thất bại.';

  @override
  String get policyAcceptanceNoticeTitle => 'Thông báo đồng ý chính sách';

  @override
  String get policyAcceptanceNoticeSubtitle =>
      'Giải thích rằng việc tiếp tục sử dụng app áp dụng theo chính sách và điều khoản hiện tại.';

  @override
  String get policyAcceptanceHero =>
      'Thông báo này giúp người dùng hiểu rằng các chính sách hiện tại áp dụng khi tiếp tục sử dụng Moniary.';

  @override
  String get policyAcceptanceBody =>
      'Khi tiếp tục dùng Moniary, người dùng xác nhận đã có cơ hội đọc Chính sách bảo mật, Điều khoản sử dụng, thông báo lưu giữ dữ liệu và các ghi chú an toàn liên quan.';

  @override
  String get legalContactTitle => 'Liên hệ pháp lý';

  @override
  String get legalContactSubtitle =>
      'Xem và sao chép email quyền riêng tư, hỗ trợ và pháp lý.';

  @override
  String get dataSafetyTitle => 'An toàn dữ liệu';

  @override
  String get dataSafetySubtitle =>
      'Tóm tắt các nhóm dữ liệu được thu thập hoặc không thu thập trong phiên bản hiện tại.';

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
      'Kênh hỗ trợ cho yêu cầu dữ liệu, xóa dữ liệu hoặc câu hỏi về quyền riêng tư.';

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
      'Moniary không đọc danh bạ, SMS, email cá nhân, vị trí hoặc tự động kết nối tài khoản ngân hàng.';

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
    return 'Đã sao chép $value';
  }

  @override
  String get storeComplianceHero =>
      'Các mục dưới đây giúp rà soát nhanh những phần người dùng và reviewer cần thấy trước khi app được phát hành.';

  @override
  String get storeCompliancePrivacyTitle => 'Chính sách bảo mật';

  @override
  String get storeCompliancePrivacyDesc =>
      'Có màn chính sách quyền riêng tư mô tả dữ liệu tài chính, ảnh giao dịch và cách xử lý dữ liệu.';

  @override
  String get storeComplianceDeleteTitle => 'Xóa tài khoản';

  @override
  String get storeComplianceDeleteDesc =>
      'Có luồng xóa tài khoản trong app và phương án gửi yêu cầu thủ công khi cần.';

  @override
  String get storeComplianceExportTitle => 'Xuất dữ liệu';

  @override
  String get storeComplianceExportDesc =>
      'Người dùng có thể xuất dữ liệu CSV, Excel hoặc PDF trước khi rời app.';

  @override
  String get storeComplianceDataSafetyTitle => 'An toàn dữ liệu';

  @override
  String get storeComplianceDataSafetyDesc =>
      'Có phần tóm tắt nhóm dữ liệu được lưu và nhóm dữ liệu app không thu thập.';

  @override
  String get storeComplianceContactTitle => 'Liên hệ quyền riêng tư';

  @override
  String get storeComplianceContactDesc =>
      'Có kênh hỗ trợ, lịch sử yêu cầu và trạng thái xử lý yêu cầu quyền riêng tư.';

  @override
  String get storeComplianceTermsTitle => 'Điều khoản sử dụng';

  @override
  String get storeComplianceTermsDesc =>
      'Có điều khoản sử dụng và ghi chú giới hạn trách nhiệm của app.';

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
      'Đường dẫn ảnh giao dịch được lưu an toàn và chỉ hiển thị khi cần trong app.';

  @override
  String get inventorySettingsTitle => 'Thiết lập nhắc nhở';

  @override
  String get inventorySettingsDesc =>
      'Các tùy chọn nhắc ghi chi tiêu khi tính năng reminder được bật.';

  @override
  String get sensitiveDataDesc =>
      'Dữ liệu tài chính có thể gồm số tiền, ghi chú, ảnh hóa đơn và file đã xuất. Chỉ chia sẻ file xuất dữ liệu với người bạn tin cậy và xóa file trên thiết bị khi không còn cần dùng.';

  @override
  String localFilesExportCount(int count) {
    return '$count file đã xuất';
  }

  @override
  String localFilesLatest(String date) {
    return 'Gần nhất: $date';
  }

  @override
  String get localFilesNoExport => 'Chưa có file xuất dữ liệu';

  @override
  String get localFilesDesc =>
      'Các file CSV, Excel và PDF được tạo trên thiết bị này. Bạn có thể mở lại, chia sẻ hoặc tự xóa file trong bộ nhớ thiết bị.';

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
      'Chuẩn bị đủ thông tin trước khi gửi yêu cầu giúp nhóm hỗ trợ xử lý nhanh hơn và tránh chia sẻ dữ liệu nhạy cảm không cần thiết.';

  @override
  String get supportChecklistActionTitle => 'Mô tả thao tác đã làm';

  @override
  String get supportChecklistActionDesc =>
      'Ghi rõ bạn đang xuất dữ liệu, xóa tài khoản, tạo yêu cầu hay mở file nào.';

  @override
  String get supportChecklistErrorTitle => 'Thêm thông báo lỗi nếu có';

  @override
  String get supportChecklistErrorDesc =>
      'Sao chép nội dung lỗi hoặc mô tả màn hình đang hiển thị để nhóm hỗ trợ dễ kiểm tra.';

  @override
  String get supportChecklistFileTitle =>
      'Đính kèm file yêu cầu hoặc file xuất dữ liệu khi phù hợp';

  @override
  String get supportChecklistFileDesc =>
      'Nếu là yêu cầu quyền riêng tư hoặc xóa dữ liệu thủ công, gửi kèm file đã tạo.';

  @override
  String get supportChecklistDiagnosticTitle => 'Sao chép thông tin hỗ trợ';

  @override
  String get supportChecklistDiagnosticDesc =>
      'Gửi kèm phiên bản, bản dựng và kênh phát hành từ Trung tâm trợ giúp.';

  @override
  String get supportChecklistSensitiveTitle => 'Không gửi dữ liệu quá nhạy cảm';

  @override
  String get supportChecklistSensitiveDesc =>
      'Không gửi mật khẩu, mã truy cập hoặc ảnh hóa đơn nhạy cảm nếu không thật sự cần thiết.';

  @override
  String get dataSafetyPersonalInfoTitle => 'Thông tin cá nhân';

  @override
  String get dataSafetyPersonalInfoStatus =>
      'Có, khi đăng nhập email hoặc Google';

  @override
  String get dataSafetyPersonalInfoDesc =>
      'Tên hiển thị, email, avatar và mã tài khoản dùng cho đăng nhập và đồng bộ dữ liệu.';

  @override
  String get dataSafetyFinancialInfoTitle => 'Thông tin tài chính';

  @override
  String get dataSafetyFinancialInfoStatus => 'Có';

  @override
  String get dataSafetyFinancialInfoDesc =>
      'Ví, danh mục, số tiền, ghi chú và ngày giao dịch do người dùng nhập.';

  @override
  String get dataSafetyPhotosTitle => 'Ảnh';

  @override
  String get dataSafetyPhotosStatus => 'Có, khi người dùng chủ động chọn/chụp';

  @override
  String get dataSafetyPhotosDesc =>
      'Ảnh giao dịch được lưu an toàn và chỉ hiển thị trong app khi cần.';

  @override
  String get dataSafetyUserIdTitle => 'Mã tài khoản';

  @override
  String get dataSafetyUserIdStatus => 'Có';

  @override
  String get dataSafetyUserIdDesc =>
      'Dùng để gắn dữ liệu với đúng tài khoản và giới hạn quyền truy cập dữ liệu.';

  @override
  String get dataSafetyLocationTitle => 'Vị trí, danh bạ, SMS';

  @override
  String get dataSafetyLocationStatus =>
      'Không thu thập trong phiên bản hiện tại';

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
      'Xem giấy phép của các thư viện đang dùng trong app.';

  @override
  String get aboutMoniaryPurposeTitle => 'Mục đích';

  @override
  String get aboutMoniaryPurposeDesc =>
      'Moniary giúp người dùng ghi lại thu chi cá nhân, quản lý ví, danh mục và ảnh giao dịch trong một trải nghiệm đơn giản.';

  @override
  String get aboutMoniaryDataDirTitle => 'Định hướng dữ liệu';

  @override
  String get aboutMoniaryDataDirDesc =>
      'Dữ liệu tài chính thuộc về người dùng. App cung cấp công cụ xuất dữ liệu, xóa tài khoản và liên hệ quyền riêng tư khi cần hỗ trợ.';

  @override
  String get aboutMoniaryMvpStatusTitle => 'Trạng thái phiên bản';

  @override
  String get aboutMoniaryMvpStatusDesc =>
      'Phiên bản hiện tại tập trung vào ghi chép chi tiêu, minh bạch dữ liệu và các yêu cầu cần thiết để chuẩn bị phát hành chính thức.';

  @override
  String get permissionInternetTitle => 'Internet';

  @override
  String get permissionInternetStatus => 'Cần thiết';

  @override
  String get permissionInternetDesc =>
      'Dùng để đăng nhập, đồng bộ dữ liệu và tải ảnh giao dịch khi cần hiển thị.';

  @override
  String get permissionCameraTitle => 'Camera';

  @override
  String get permissionCameraStatus => 'Chỉ hỏi khi người dùng chụp ảnh';

  @override
  String get permissionCameraDesc =>
      'Dùng để chụp hóa đơn hoặc hình ảnh liên quan đến giao dịch.';

  @override
  String get permissionPhotoTitle => 'Chọn ảnh';

  @override
  String get permissionPhotoStatus => 'Chỉ mở khi người dùng chọn ảnh';

  @override
  String get permissionPhotoDesc =>
      'Dùng Android Photo Picker để chọn ảnh mà không cần đọc toàn bộ thư viện.';

  @override
  String get permissionNotiTitle => 'Thông báo';

  @override
  String get permissionNotiStatus => 'Chỉ dùng khi bật nhắc nhở';

  @override
  String get permissionNotiDesc => 'Quyền này chỉ cần khi bạn bật nhắc nhở.';

  @override
  String get permissionLocationTitle => 'Không dùng vị trí, danh bạ, SMS';

  @override
  String get permissionLocationStatus => 'Không sử dụng';

  @override
  String get permissionLocationDesc =>
      'Moniary không cần vị trí, danh bạ hoặc SMS để ghi chi tiêu bằng ảnh.';

  @override
  String get privacyPolicyLeadTitle =>
      'Moniary bảo vệ dữ liệu chi tiêu cá nhân của bạn.';

  @override
  String get privacyPolicyLeadDesc =>
      'Nội dung này giải thích cách Moniary xử lý dữ liệu và có thể được cập nhật khi app phát hành chính thức.';

  @override
  String get privacyPolicyDataTitle => 'Dữ liệu Moniary xử lý';

  @override
  String get privacyPolicyDataItem1 =>
      'Thông tin tài khoản như tên hiển thị, email, avatar và mã tài khoản khi người dùng đăng nhập.';

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
      'Lưu ảnh giao dịch an toàn và chỉ hiển thị trong app khi cần.';

  @override
  String get privacyPolicyPurposeItem4 =>
      'Bảo vệ tài khoản, giới hạn quyền truy cập dữ liệu và hỗ trợ người dùng khi có yêu cầu.';

  @override
  String get privacyPolicyShareTitle => 'Chia sẻ dữ liệu';

  @override
  String get privacyPolicyShareItem1 =>
      'Moniary không bán dữ liệu cá nhân hoặc dữ liệu tài chính của người dùng.';

  @override
  String get privacyPolicyShareItem2 =>
      'Dữ liệu được lưu trên hạ tầng bảo mật để cung cấp đăng nhập, đồng bộ dữ liệu, lưu trữ ảnh và các tính năng trợ lý AI đã bật.';

  @override
  String get privacyPolicyShareItem3 =>
      'Khi bật trợ lý AI, ngữ cảnh tài chính đã chọn có thể được gửi qua Supabase Edge Functions tới Google Gemini để tạo câu trả lời. Moniary không đọc vị trí, danh bạ, SMS, email cá nhân hoặc dữ liệu ngân hàng tự động.';

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
      'Khi xóa tài khoản, Moniary yêu cầu xóa hồ sơ, ví, danh mục, giao dịch và ảnh thuộc tài khoản hiện tại.';

  @override
  String get privacyPolicySafetyTitle => 'Khai báo an toàn dữ liệu';

  @override
  String get privacyPolicySafetyItem1 =>
      'Thông tin cá nhân: chỉ thu thập khi người dùng đăng nhập bằng email hoặc Google.';

  @override
  String get privacyPolicySafetyItem2 =>
      'Thông tin tài chính: thu thập để lưu và hiển thị thu chi cá nhân.';

  @override
  String get privacyPolicySafetyItem3 =>
      'Ảnh: chỉ thu thập ảnh người dùng chủ động chụp hoặc chọn.';

  @override
  String get privacyPolicySafetyItem4 =>
      'Vị trí, danh bạ, SMS: không thu thập trong phiên bản hiện tại.';

  @override
  String get privacyPolicyContactDesc =>
      'Moniary sẽ cập nhật nội dung chính sách và email liên hệ chính thức khi phát hành.';

  @override
  String get deletionPolicyStep1Title => 'Trước khi xóa';

  @override
  String get deletionPolicyStep1Desc =>
      'Người dùng có thể xuất CSV để giữ lại lịch sử giao dịch cá nhân.';

  @override
  String get deletionPolicyStep2Title => 'Dữ liệu sẽ bị xóa';

  @override
  String get deletionPolicyStep2Desc =>
      'Hồ sơ, ví, danh mục, giao dịch, thiết lập nhắc nhở và ảnh thuộc tài khoản hiện tại.';

  @override
  String get deletionPolicyStep3Title => 'Cách xóa';

  @override
  String get deletionPolicyStep3Desc =>
      'Moniary xác thực yêu cầu, xóa dữ liệu liên quan rồi đóng tài khoản.';

  @override
  String get deletionPolicyStep4Title => 'Dữ liệu ngoài app';

  @override
  String get deletionPolicyStep4Desc =>
      'Nếu cần hỗ trợ thêm về dữ liệu ngoài app, người dùng có thể liên hệ kênh hỗ trợ quyền riêng tư của Moniary.';

  @override
  String get termsOfUseHeroDesc =>
      'Các điều khoản này tóm tắt cách người dùng nên sử dụng Moniary trong phiên bản hiện tại.';

  @override
  String get termsOfUseScopeTitle => '1. Phạm vi sử dụng';

  @override
  String get termsOfUseScopeDesc =>
      'Moniary được cung cấp để người dùng ghi chép và tự quản lý dữ liệu thu chi cá nhân. Người dùng chịu trách nhiệm về độ chính xác của dữ liệu đã nhập.';

  @override
  String get termsOfUseAccountTitle => '2. Dữ liệu tài khoản';

  @override
  String get termsOfUseAccountDesc =>
      'Người dùng có thể xuất dữ liệu, gửi yêu cầu quyền riêng tư và xóa tài khoản theo các công cụ được cung cấp trong app.';

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
  String get dataRetentionCloudTitle => 'Dữ liệu được đồng bộ';

  @override
  String get dataRetentionCloudDesc =>
      'Hồ sơ, ví, danh mục, giao dịch và đường dẫn ảnh giao dịch được giữ khi tài khoản còn hoạt động để app có thể đồng bộ và hiển thị lại dữ liệu.';

  @override
  String get dataRetentionPhotosTitle => 'Ảnh giao dịch';

  @override
  String get dataRetentionPhotosDesc =>
      'Ảnh giao dịch chỉ được lưu khi người dùng chủ động chụp hoặc chọn ảnh. Ảnh sẽ được xử lý cùng dữ liệu tài khoản khi xóa tài khoản.';

  @override
  String get dataRetentionLocalFilesTitle => 'File trên thiết bị';

  @override
  String get dataRetentionLocalFilesDesc =>
      'File xuất dữ liệu và lịch sử yêu cầu được tạo trên thiết bị. Người dùng có thể tự quản lý, chia sẻ hoặc xóa các file này khỏi bộ nhớ thiết bị.';

  @override
  String get dataRetentionDeleteTitle => 'Sau khi xóa tài khoản';

  @override
  String get dataRetentionDeleteDesc =>
      'Moniary dùng luồng xóa tài khoản để gỡ dữ liệu app gắn với tài khoản hiện tại. Nếu thao tác thất bại, người dùng có thể tạo yêu cầu xóa dữ liệu thủ công.';

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
      'Tổng thu, tổng chi và các file xuất dữ liệu phụ thuộc vào dữ liệu người dùng nhập, có thể sai nếu nhập thiếu hoặc nhập nhầm.';

  @override
  String get financialDisclaimerExpertTitle => 'Khi cần quyết định quan trọng';

  @override
  String get financialDisclaimerExpertDesc =>
      'Người dùng nên kiểm tra lại dữ liệu gốc và hỏi chuyên gia phù hợp trước các quyết định tài chính, thuế hoặc pháp lý.';

  @override
  String get policyChangelogEntry1Title =>
      'Bổ sung trung tâm pháp lý & chính sách';

  @override
  String get policyChangelogEntry1Desc =>
      'Thêm chính sách lưu giữ dữ liệu, thông báo dịch vụ bên thứ ba, miễn trừ tài chính và lịch sử thay đổi chính sách.';

  @override
  String get policyChangelogEntry2Title =>
      'Bổ sung yêu cầu quyền riêng tư & hỗ trợ';

  @override
  String get policyChangelogEntry2Desc =>
      'Thêm loại yêu cầu quyền riêng tư, mẫu nội dung, xem trước, lịch sử yêu cầu, trạng thái và tiến trình phản hồi.';

  @override
  String get policyChangelogEntry3Title =>
      'Bổ sung tin cậy & chuẩn bị phát hành';

  @override
  String get policyChangelogEntry3Desc =>
      'Thêm giới thiệu, điều khoản sử dụng, giấy phép, thông tin phiên bản/bản dựng, checklist phát hành và liên hệ pháp lý.';

  @override
  String get policyChangelogEntry4Title => 'Khởi tạo chính sách phiên bản đầu';

  @override
  String get policyChangelogEntry4Desc =>
      'Thêm chính sách quyền riêng tư, an toàn dữ liệu, chính sách xóa dữ liệu, xuất dữ liệu và xóa tài khoản.';

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
  String get groupBalanceSettledShort => 'Đã cân';

  @override
  String groupBalanceOwes(String amount) {
    return 'Bạn cần trả $amount';
  }

  @override
  String groupBalanceReceives(String amount) {
    return 'Bạn sẽ nhận $amount';
  }

  @override
  String get groupBalanceReceiveShort => 'Được nhận';

  @override
  String get groupBalancePayShort => 'Cần trả';

  @override
  String get groupBalanceReceiveSummary => 'Bạn được nhận';

  @override
  String get groupBalancePaySummary => 'Bạn cần trả';

  @override
  String get groupSettleAction => 'Tất toán';

  @override
  String get groupSettlementYou => 'Bạn';

  @override
  String get groupSettlementConfirmAll => 'Xác nhận đã tất toán';

  @override
  String get groupSettlementWaitingForPayers =>
      'Chờ người trả đánh dấu đã thanh toán trước.';

  @override
  String groupSettlementOptimizedSubtitle(String groupName, int count) {
    return '$groupName · Tối ưu $count giao dịch';
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
  String get groupLeaveIncompleteTransaction =>
      'Hãy hoàn tất hoặc huỷ các giao dịch nhóm chưa xong trước khi rời nhóm.';

  @override
  String get groupLeaveDisputedSettlement =>
      'Hãy xử lý khoản tất toán đang tranh chấp trước khi rời nhóm.';

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
  String get groupLeaveBlockedTitle => 'Chưa thể rời nhóm';

  @override
  String get groupLeaveViewSettlements => 'Xem khoản tất toán';

  @override
  String get groupLeaveViewGroup => 'Xem giao dịch nhóm';

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
  String get groupInviteLinkActiveNote =>
      'Link có thể được nhiều người dùng trong 7 ngày.';

  @override
  String get groupInviteCopyLink => 'Sao chép link';

  @override
  String get groupInviteLinkCopied => 'Đã sao chép link mời.';

  @override
  String get groupInviteRevokeLink => 'Thu hồi link';

  @override
  String get groupInviteLinkRevoked => 'Đã thu hồi link mời nhóm.';

  @override
  String get groupInviteAcceptTitle => 'Lời mời vào nhóm';

  @override
  String groupInviteAcceptSubtitle(String name, String group) {
    return '$name mời bạn tham gia nhóm $group.';
  }

  @override
  String get groupInvitePreviewNotice =>
      'Bạn chưa tham gia nhóm. Chỉ bấm Tham gia nhóm khi bạn muốn nhận lời mời này.';

  @override
  String get groupInviteAcceptButton => 'Tham gia nhóm';

  @override
  String get groupInviteDismissButton => 'Không tham gia';

  @override
  String get groupInviteAccepted => 'Bạn đã tham gia nhóm.';

  @override
  String get groupInviteAlreadyMember => 'Bạn đã tham gia nhóm này.';

  @override
  String get groupInviteLoading => 'Đang tải lời mời...';

  @override
  String get groupInvitePreviewError => 'Không thể tải lời mời vào nhóm.';

  @override
  String get groupInviteInvalid => 'Link mời nhóm không hợp lệ.';

  @override
  String get groupInviteExpired => 'Link mời nhóm đã hết hạn.';

  @override
  String get groupInviteUsed => 'Link mời nhóm này đã được sử dụng.';

  @override
  String get groupInviteRevoked => 'Link mời nhóm đã bị thu hồi.';

  @override
  String get groupInviteOpenGroups => 'Mở nhóm';

  @override
  String get groupCopyInviteLink => 'Sao chép link';

  @override
  String get groupShareInviteLink => 'Chia sẻ link';

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
  String get groupInviteAlreadyAccepted => 'Link mời nhóm đã được sử dụng.';

  @override
  String get groupInviteGroupArchived => 'Nhóm này đã được lưu trữ.';

  @override
  String get groupMemberInvited => 'Đã mời';

  @override
  String get groupMemberActive => 'Đang tham gia';

  @override
  String get groupAddTransaction => 'Thêm khoản chi nhóm';

  @override
  String get groupTransactionCaption => 'Caption';

  @override
  String get groupTransactionNote => 'Ghi chú';

  @override
  String get groupTransactionTotal => 'Tổng tiền';

  @override
  String get groupTransactionCurrency => 'Tiền tệ giao dịch';

  @override
  String groupTransactionCurrencySubtitle(String currency) {
    return 'Tiền tệ chung của nhóm: $currency';
  }

  @override
  String get groupTransactionExchangeRate => 'Tỷ giá quy đổi về tiền tệ chung';

  @override
  String groupTransactionExchangeRateSubtitle(String from, String to) {
    return '1 $from = ? $to';
  }

  @override
  String get groupTransactionExchangeRateInvalid =>
      'Hãy nhập tỷ giá dương hợp lệ.';

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
  String get groupTransactionSearchHint =>
      'Tìm theo nội dung, danh mục hoặc người đăng';

  @override
  String get groupTransactionFilterAll => 'Tất cả';

  @override
  String get groupTransactionFilterNoResults =>
      'Không tìm thấy giao dịch phù hợp.';

  @override
  String get groupTransactionLoadMore => 'Tải thêm giao dịch';

  @override
  String get groupTransactionLoadError => 'Không tải được giao dịch nhóm.';

  @override
  String groupTransactionHistorySubtitle(String payer, int count) {
    return '$payer trả · Chia $count người';
  }

  @override
  String get groupTransactionDetailTitle => 'Chi tiết giao dịch nhóm';

  @override
  String get groupActivityCenterTitle => 'Hoạt động nhóm';

  @override
  String get groupActivityTabTimeline => 'Hoạt động';

  @override
  String get groupActivityTabNotifications => 'Thông báo';

  @override
  String get groupActivityEmpty => 'Chưa có hoạt động nào';

  @override
  String get groupNotificationsEmptyState => 'Chưa có thông báo nào';

  @override
  String get groupPhotoAlbumTitle => 'Album ảnh';

  @override
  String get groupPhotoAlbumEmpty => 'Chưa có ảnh giao dịch';

  @override
  String get groupPhotoAlbumLoadError => 'Không thể tải album ảnh';

  @override
  String get groupTransactionFallback => 'Giao dịch nhóm';

  @override
  String get groupMemberFallback => 'Thành viên';

  @override
  String get groupBudgetTitle => 'Ngân sách nhóm';

  @override
  String get groupBudgetSubtitle =>
      'Đặt giới hạn chi tiêu chung mỗi tháng cho nhóm.';

  @override
  String get groupBudgetProgressTitle => 'Tiến độ ngân sách tháng này';

  @override
  String get groupBudgetNoLimit => 'Chưa đặt giới hạn ngân sách.';

  @override
  String get groupBudgetOverLimit => 'Nhóm đã vượt giới hạn ngân sách.';

  @override
  String groupBudgetSpentOfLimit(String spent, String limit) {
    return 'Đã chi $spent trên $limit';
  }

  @override
  String groupBudgetThresholdNotice(int percent) {
    return 'Cảnh báo khi đạt $percent% ngân sách.';
  }

  @override
  String get groupBudgetMonthlyLimit => 'Giới hạn mỗi tháng';

  @override
  String get groupBudgetWarningThreshold => 'Ngưỡng cảnh báo';

  @override
  String get groupBudgetNotSet => 'Chưa đặt ngân sách';

  @override
  String get groupBudgetSet => 'Đặt ngân sách';

  @override
  String get groupBudgetEditTitle => 'Chỉnh sửa ngân sách nhóm';

  @override
  String get groupBudgetInvalidAmount => 'Số tiền phải >= 0';

  @override
  String get groupBudgetSaved => 'Đã cập nhật ngân sách';

  @override
  String get groupBudgetCurrencySuffix => 'theo tiền tệ của bạn';

  @override
  String get groupBudgetAdminOnly =>
      'Chỉ chủ nhóm và quản trị viên được sửa ngân sách.';

  @override
  String get groupBudgetInvalidLimit => 'Nhập giới hạn hợp lệ, không âm.';

  @override
  String get groupNotificationPrefsTitle => 'Cài đặt thông báo';

  @override
  String get groupNotificationPrefsMuteAll => 'Tắt tất cả';

  @override
  String get groupNotificationPrefsMuteAllHelp =>
      'Tắt mọi thông báo từ nhóm này';

  @override
  String get groupNotificationPrefsTransactions => 'Giao dịch mới';

  @override
  String get groupNotificationPrefsDebts => 'Nợ và tất toán';

  @override
  String get groupNotificationPrefsInvites => 'Lời mời';

  @override
  String get groupNotificationPrefsMentions => 'Nhắc đến';

  @override
  String get groupNotificationPrefsQuietHours => 'Giờ yên lặng';

  @override
  String get groupNotificationPrefsQuietHoursHelp =>
      'Tắt thông báo trong khoảng giờ này';

  @override
  String get groupNotificationPrefsFrom => 'Từ';

  @override
  String get groupNotificationPrefsTo => 'Đến';

  @override
  String get groupNotificationPrefsSaved => 'Đã lưu cài đặt thông báo';

  @override
  String get groupNotificationPreferencesTitle => 'Tuỳ chọn thông báo';

  @override
  String get groupNotificationPreferencesSubtitle =>
      'Chọn loại sự kiện nhóm bạn muốn nhận thông báo.';

  @override
  String get groupNotificationMuteAll => 'Tắt tất cả thông báo';

  @override
  String get groupNotificationTransactions => 'Cập nhật giao dịch';

  @override
  String get groupNotificationDebts => 'Cập nhật nợ và tất toán';

  @override
  String get groupNotificationInvites => 'Lời mời';

  @override
  String get groupNotificationMentions => 'Lượt nhắc tên';

  @override
  String get groupNotificationCommunitySection => 'Cập nhật cộng đồng';

  @override
  String get groupNotificationComments => 'Bình luận và trả lời';

  @override
  String get groupNotificationReactions => 'Lượt reaction';

  @override
  String get groupNotificationQuietHoursSection => 'Khung giờ yên lặng';

  @override
  String get groupNotificationQuietStart => 'Bắt đầu từ';

  @override
  String get groupNotificationQuietEnd => 'Kết thúc lúc';

  @override
  String get groupNotificationQuietNotSet => 'Không giới hạn';

  @override
  String get groupNotificationQuietClear => 'Xóa khung giờ yên lặng';

  @override
  String get groupNotificationQuietPairRequired =>
      'Hãy chọn đủ giờ bắt đầu và kết thúc.';

  @override
  String get groupPublicProfileShowStats => 'Hiển thị thống kê nhóm';

  @override
  String get groupPublicProfileSlug => 'Slug công khai';

  @override
  String get groupPublicProfileTitle => 'Trang công khai nhóm';

  @override
  String get groupPublicProfileSettingsTitle => 'Cài đặt trang công khai';

  @override
  String get groupPublicProfileSettingsSubtitle =>
      'Chỉ thông tin an toàn của nhóm được hiển thị công khai.';

  @override
  String get groupPublicProfileEnabled => 'Bật trang công khai';

  @override
  String get groupPublicProfileShowStatsSubtitle =>
      'Chỉ hiển thị số lượng tổng hợp và tổng chi tiêu.';

  @override
  String get groupPublicProfileShowDescription => 'Hiển thị mô tả';

  @override
  String get groupPublicProfileShowDescriptionSubtitle =>
      'Mô tả nhóm sẽ hiển thị cho bất kỳ ai có đường dẫn công khai.';

  @override
  String get groupPublicProfileShowType => 'Hiển thị loại nhóm';

  @override
  String get groupPublicProfileShowAvatar => 'Hiển thị ảnh nhóm';

  @override
  String get groupPublicProfileShowAvatarSubtitle =>
      'Chỉ ảnh public-safe được tải riêng mới đủ điều kiện; ảnh riêng tư của nhóm không bao giờ bị lộ.';

  @override
  String get groupPublicProfileShareTitle => 'Chia sẻ trang công khai';

  @override
  String get groupPublicProfileCopy => 'Sao chép link';

  @override
  String get groupPublicProfileCopied => 'Đã sao chép link trang công khai.';

  @override
  String get groupPublicProfilePreview => 'Xem trước';

  @override
  String get groupPublicProfileInvalidSlug =>
      'Dùng 3–80 chữ thường, số hoặc dấu gạch ngang.';

  @override
  String get groupPublicProfileFallbackName => 'Nhóm Moniary';

  @override
  String get groupPublicProfileMembers => 'Thành viên';

  @override
  String get groupPublicProfileTransactions => 'Giao dịch';

  @override
  String get groupPublicProfileTotalSpent => 'Tổng chi';

  @override
  String get groupPublicProfileSafeNotice =>
      'Không hiển thị thông tin cá nhân hay dữ liệu giao dịch chi tiết.';

  @override
  String get groupRecurringTitle => 'Giao dịch định kỳ';

  @override
  String get groupRecurringAdd => 'Thêm giao dịch định kỳ';

  @override
  String get groupRecurringEdit => 'Sửa giao dịch định kỳ';

  @override
  String get groupRecurringEmpty => 'Chưa có giao dịch định kỳ';

  @override
  String get groupRecurringName => 'Tên giao dịch';

  @override
  String get groupRecurringAmount => 'Số tiền';

  @override
  String get groupRecurringFrequency => 'Tần suất';

  @override
  String get groupRecurringWeekly => 'Hàng tuần';

  @override
  String get groupRecurringMonthly => 'Hàng tháng';

  @override
  String get groupRecurringNextRun => 'Lần chạy tiếp theo';

  @override
  String get groupRecurringNotifyBefore => 'Báo trước số ngày';

  @override
  String get groupRecurringActive => 'Đang hoạt động';

  @override
  String get groupRecurringAutoPost => 'Tự động ghi nhận khi đến hạn';

  @override
  String get groupRecurringAutoPostSubtitle =>
      'Tạo giao dịch chia đều theo tiền tệ chung của nhóm.';

  @override
  String get groupRecurringDeleteTitle => 'Xoá giao dịch định kỳ?';

  @override
  String get groupRecurringDeleteMessage =>
      'Giao dịch định kỳ này sẽ bị xoá vĩnh viễn.';

  @override
  String get groupToolsTitle => 'Công cụ nhóm';

  @override
  String get groupToolsSubtitle =>
      'Quản lý nhóm mà vẫn luôn thấy rõ dòng tiền chung.';

  @override
  String get groupToolsFinanceSection => 'Tài chính';

  @override
  String get groupToolsCommunitySection => 'Cộng đồng';

  @override
  String get groupToolsSettingsSection => 'Cài đặt';

  @override
  String get groupToolsBudgetSubtitle =>
      'Giới hạn chi tiêu tháng và ngưỡng cảnh báo.';

  @override
  String get groupToolsSummarySubtitle =>
      'Tổng hợp chi tiêu theo tháng, thành viên và lịch sử tất toán.';

  @override
  String get groupToolsRecurringSubtitle => 'Khoản chi định kỳ và lời nhắc.';

  @override
  String get groupToolsActivitySubtitle =>
      'Dòng hoạt động, thông báo nhóm và cập nhật cộng đồng.';

  @override
  String get groupToolsAlbumSubtitle =>
      'Ảnh hoá đơn gắn với các khoản chi nhóm.';

  @override
  String get groupToolsNotificationsSubtitle =>
      'Chọn cập nhật nhóm và cộng đồng bạn muốn nhận.';

  @override
  String get groupToolsPublicProfileSubtitle =>
      'Kiểm soát trang công khai an toàn của nhóm.';

  @override
  String get groupToolsLeaveSubtitle =>
      'Chỉ rời nhóm sau khi xử lý xong công nợ và giao dịch đang chờ.';

  @override
  String get groupSummaryTitle => 'Tổng quan tài chính';

  @override
  String get groupSummarySubtitle =>
      'Theo dõi chi tiêu và các khoản tất toán của nhóm theo từng tháng.';

  @override
  String get groupSummaryPreviousMonth => 'Tháng trước';

  @override
  String get groupSummaryNextMonth => 'Tháng sau';

  @override
  String get groupSummaryTotalSpent => 'Tổng chi';

  @override
  String get groupSummaryTransactions => 'Giao dịch';

  @override
  String get groupSummaryCategories => 'Theo danh mục';

  @override
  String get groupSummaryMembers => 'Theo thành viên';

  @override
  String get groupSummarySettlementHistory => 'Lịch sử tất toán';

  @override
  String get groupSummaryNoData => 'Chưa có dữ liệu trong tháng này.';

  @override
  String get groupSummaryNoHistory => 'Chưa có lịch sử tất toán.';

  @override
  String get groupSummaryChartsTitle => 'Tổng quan chi tiêu';

  @override
  String get groupSummaryTrendTitle => 'Xu hướng chi tiêu 6 tháng';

  @override
  String get groupSettlementBadgeTitle => 'Đã tất toán';

  @override
  String get groupSettlementBadgeSubtitle =>
      'Nhóm không còn số dư cần thanh toán trong tháng này.';

  @override
  String groupSummaryTransactionCount(int count) {
    return '$count giao dịch';
  }

  @override
  String groupSummaryMemberAmounts(String share, String paid) {
    return 'Chịu $share · Đã trả $paid';
  }

  @override
  String groupSummarySettlementPair(String from, String to) {
    return '$from trả $to';
  }

  @override
  String get groupActivityTransactionReacted =>
      'đã thả cảm xúc vào một giao dịch';

  @override
  String get groupActivityTransactionCommented =>
      'đã bình luận vào một giao dịch';

  @override
  String get groupActivityMemberJoined => 'đã tham gia nhóm';

  @override
  String get groupActivityMemberLeft => 'đã rời nhóm';

  @override
  String get groupActivityInvitationAccepted => 'đã chấp nhận lời mời vào nhóm';

  @override
  String get groupActivityInvitationDeclined => 'đã từ chối lời mời vào nhóm';

  @override
  String get groupActivityMemberRemoved => 'đã xóa một thành viên khỏi nhóm';

  @override
  String get groupActivityOwnerTransferred => 'đã chuyển quyền chủ nhóm';

  @override
  String get groupActivitySettlementDisputed =>
      'đã báo cáo tranh chấp khoản tất toán';

  @override
  String get groupActivityLeaveBlocked =>
      'đã cố rời nhóm khi còn việc chưa xử lý';

  @override
  String get groupNotificationTransactionPosted => 'Có giao dịch mới';

  @override
  String get groupNotificationMemberAmountRequired =>
      'Cần bạn nhập số tiền của mình';

  @override
  String get groupNotificationDebtSettled => 'Một khoản nợ đã được tất toán';

  @override
  String get groupNotificationGroupInvite => 'Bạn có lời mời vào nhóm mới';

  @override
  String get groupNotificationSettlementMarkedPaid =>
      'Một khoản tất toán đã được đánh dấu đã trả';

  @override
  String get groupNotificationSettlementCompleted =>
      'Một khoản tất toán đã hoàn tất';

  @override
  String get groupNotificationSettlementDisputed =>
      'Một khoản tất toán đang bị tranh chấp';

  @override
  String get groupNotificationMemberRemoved =>
      'Một thành viên đã bị xóa khỏi nhóm';

  @override
  String get groupActivityTabGroupNotifications => 'Nhóm';

  @override
  String get groupActivityTabCommunityNotifications => 'Cộng đồng';

  @override
  String get communityNotificationsEmptyState => 'Chưa có thông báo cộng đồng';

  @override
  String get groupNotificationMemberLeft => 'Một thành viên đã rời nhóm';

  @override
  String get groupNotificationLeaveBlocked =>
      'Một thành viên cố rời nhóm khi còn khoản chưa xử lý';

  @override
  String get groupNotificationCommentAdded => 'Có bình luận mới';

  @override
  String get groupNotificationReactionAdded =>
      'Có người đã thả cảm xúc vào giao dịch';

  @override
  String get groupNotificationMention => 'Bạn được nhắc tên trong cộng đồng';

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
  String get groupMemberBalanceTitle => 'Số dư thành viên';

  @override
  String get groupYouNeedPay => 'Bạn cần trả';

  @override
  String get groupOthersNeedPayYou => 'Người khác cần trả cho bạn';

  @override
  String get groupDetailReceiveBack => 'Bạn được nhận lại';

  @override
  String get groupDetailYouPay => 'Bạn cần trả';

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
      'Tạo link để mời nhiều người vào nhóm trong thời hạn 7 ngày.';

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
  String groupActivityTransactionCreated(String actor) {
    return '$actor đã tạo giao dịch nhóm.';
  }

  @override
  String groupActivityTransactionPosted(String actor) {
    return '$actor đã đăng giao dịch nhóm.';
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
  String get friendSearchHint => 'Ví dụ: erling_haaland';

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
  String get friendSearchPlaceholder => 'Tìm bạn bè...';

  @override
  String get friendLoadError => 'Không tải được danh sách bạn bè.';

  @override
  String get friendNoFriends => 'Bạn chưa có bạn bè nào.';

  @override
  String get friendNoFriendsSubtitle =>
      'Thêm bạn bè để mời vào nhóm chi tiêu nhanh hơn.';

  @override
  String friendListSection(int count) {
    return 'Bạn bè · $count';
  }

  @override
  String friendSharedGroups(int count) {
    return '$count nhóm chung';
  }

  @override
  String get friendOwesYou => 'Nợ bạn';

  @override
  String get friendYouOwe => 'Bạn nợ';

  @override
  String get friendBalanceSettled => 'Đã cân';

  @override
  String get friendIncomingRequests => 'Lời mời kết bạn';

  @override
  String get friendOutgoingRequests => 'Đã gửi lời mời';

  @override
  String get friendRequestsEmpty => 'Chưa có lời mời kết bạn nào.';

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
  String get friendInviteOr => 'Hoặc';

  @override
  String get budgetTitle => 'Ngân sách';

  @override
  String get budgetUsed => 'Đã dùng';

  @override
  String get budgetCategoryLimits => 'Hạn mức danh mục';

  @override
  String budgetSpentOfLimit(String spent, String limit) {
    return '$spent / $limit tháng này';
  }

  @override
  String get budgetAddCategory => 'Đặt hạn mức cho danh mục khác';

  @override
  String get budgetChooseCategory => 'Chọn danh mục';

  @override
  String get budgetMonthlyLimit => 'Hạn mức tháng';

  @override
  String get budgetLimitHelper =>
      'Nhập số tiền tối đa bạn muốn chi cho danh mục này trong tháng.';

  @override
  String get budgetRemoveLimit => 'Bỏ hạn mức';

  @override
  String budgetLimitTitleForCategory(String category) {
    return 'Hạn mức · $category';
  }

  @override
  String budgetUsedWarningLine(String spent, int percent, String status) {
    return 'Đã dùng $spent ($percent%) — $status';
  }

  @override
  String budgetAlertAtPercent(int percent) {
    return 'Báo khi đạt $percent%';
  }

  @override
  String get budgetSaveLimit => 'Lưu hạn mức';

  @override
  String budgetSpentRemainingLine(
    String spent,
    String limit,
    String remaining,
  ) {
    return '$spent / $limit — còn $remaining';
  }

  @override
  String budgetTransactionsInLimitCount(int count) {
    return 'Giao dịch tính vào hạn mức · $count';
  }

  @override
  String budgetViewAllInStats(int count) {
    return 'Xem đủ $count giao dịch trong Số liệu →';
  }

  @override
  String get budgetNearLimit => 'Sắp vượt hạn mức';

  @override
  String get budgetOverLimit => 'Đã vượt hạn mức';

  @override
  String get budgetNearLimitShort => 'Sắp vượt';

  @override
  String get budgetOverLimitShort => 'Vượt hạn';

  @override
  String get budgetEmptyTitle => 'Chưa đặt hạn mức';

  @override
  String get budgetEmptyBody =>
      'Chọn một danh mục để bắt đầu theo dõi ngân sách tháng.';

  @override
  String get cameraFrameHint => 'Đưa hóa đơn vào khung';

  @override
  String get assistantTitle => 'Trợ lý tài chính';

  @override
  String get assistantNavLabel => 'AI';

  @override
  String get assistantIntroSkip => 'Bỏ qua';

  @override
  String get assistantIntroNext => 'Tiếp tục';

  @override
  String get assistantIntroStart => 'Bắt đầu';

  @override
  String get assistantIntroTitle1 => 'Hỏi bất cứ điều gì về chi tiêu của bạn';

  @override
  String get assistantIntroBody1 =>
      'Nhận câu trả lời ngay từ chính dữ liệu bạn đã ghi trong Moniary.';

  @override
  String get assistantIntroTitle2 => 'Nhận diện chi tiêu bất thường sớm';

  @override
  String get assistantIntroBody2 =>
      'Phát hiện khoản tăng vọt hoặc lặp lại nhiều lần trước khi bạn mất kiểm soát.';

  @override
  String get assistantIntroTitle3 => 'Gợi ý hành động thực tế';

  @override
  String get assistantIntroBody3 =>
      'Chỉ rõ cần giảm bao nhiêu và ở danh mục nào, không dùng lời khuyên mơ hồ.';

  @override
  String get assistantPermissionTitle =>
      'Cho phép trợ lý hiểu tài chính của bạn';

  @override
  String get assistantPermissionBody =>
      'Bạn quyết định phạm vi dữ liệu được đọc. Có thể thay đổi bất cứ lúc nào.';

  @override
  String get assistantPermissionDateRange =>
      'AI chỉ dùng các phạm vi dữ liệu đã bật cần cho câu hỏi hiện tại';

  @override
  String get assistantAnalyzeAll => 'Phân tích tất cả dữ liệu';

  @override
  String get assistantTransactionsAccess => 'Ghi chép thu chi';

  @override
  String get assistantTransactionsAccessBody =>
      'Dùng giao dịch để phân tích dòng tiền và thói quen chi tiêu.';

  @override
  String get assistantWalletsAccess => 'Ví và số dư';

  @override
  String get assistantWalletsAccessBody =>
      'Dùng số dư để đặt các con số chi tiêu vào đúng bối cảnh.';

  @override
  String get assistantBudgetsAccess => 'Hạn mức chi';

  @override
  String get assistantBudgetsAccessBody =>
      'Kiểm tra mức sử dụng và cảnh báo khi gần chạm hạn mức.';

  @override
  String get assistantSavingsAccess => 'Tiết kiệm và tích luỹ';

  @override
  String get assistantSavingsAccessBody =>
      'Theo dõi mục tiêu tiết kiệm và gợi ý kế hoạch phù hợp.';

  @override
  String get assistantUpcomingBadge => 'Sắp ra mắt';

  @override
  String get assistantPermissionConfirm => 'Xác nhận';

  @override
  String get assistantPrivacyNote =>
      'Khi bật AI, ngữ cảnh Moniary đã chọn có thể được gửi qua Supabase tới Google Gemini để tạo câu trả lời.';

  @override
  String assistantGreeting(String name) {
    return 'Chào $name';
  }

  @override
  String get assistantHomePrompt => 'Hôm nay mình có thể giúp gì cho bạn?';

  @override
  String get assistantInputHint => 'Nhập câu hỏi của bạn';

  @override
  String get assistantSuggestionsTitle => 'Gợi ý cho bạn';

  @override
  String get assistantQuestionsTitle => 'Câu hỏi nhanh';

  @override
  String get assistantOpenLibrary => 'Xem thư viện câu hỏi';

  @override
  String get assistantQuestionLibraryTitle => 'Câu hỏi gợi ý';

  @override
  String get assistantFilterAll => 'Tất cả';

  @override
  String get assistantFilterUnderstand => 'Thấu hiểu chi tiêu';

  @override
  String get assistantFilterAlerts => 'Cảnh báo bất thường';

  @override
  String get assistantFilterActions => 'Hành động';

  @override
  String get assistantQuestionMonthly =>
      'Tháng này tôi đã tiêu hết bao nhiêu tiền rồi?';

  @override
  String get assistantQuestionWeekly => 'Chi tiêu tuần này so với tuần trước?';

  @override
  String get assistantQuestionDaily =>
      'Trung bình mỗi ngày tôi tiêu bao nhiêu?';

  @override
  String get assistantQuestionTopCategory =>
      'Hạng mục nào tôi chi nhiều tiền nhất tháng này?';

  @override
  String get assistantQuestionRecurring =>
      'Có khoản chi nào lặp lại nhiều lần mà tôi không chú ý không?';

  @override
  String get assistantQuestionSaving => 'Cắt giảm ở đâu để tiết kiệm thêm?';

  @override
  String assistantMonthlyAnswer(String amount) {
    return 'Bạn đã chi $amount trong tháng này.';
  }

  @override
  String assistantMonthlyCompare(String direction, String percent) {
    return '$direction $percent% so với tháng trước.';
  }

  @override
  String get assistantDirectionMore => 'Nhiều hơn';

  @override
  String get assistantDirectionLess => 'Ít hơn';

  @override
  String assistantWeeklyAnswer(
    String current,
    String direction,
    String percent,
  ) {
    return 'Tuần này bạn đã chi $current, $direction $percent% so với tuần trước.';
  }

  @override
  String assistantDailyAnswer(String amount) {
    return 'Trung bình bạn chi $amount mỗi ngày trong tháng này.';
  }

  @override
  String assistantTopCategoryAnswer(
    String category,
    String amount,
    String percent,
  ) {
    return '$category đang đứng đầu với $amount, chiếm $percent% tổng chi.';
  }

  @override
  String assistantRecurringAnswer(String label, int count, String amount) {
    return 'Khoản “$label” xuất hiện $count lần, tổng cộng $amount.';
  }

  @override
  String assistantSavingAnswer(String category, String amount) {
    return 'Nếu giảm khoảng 15% ở $category, bạn có thể tiết kiệm gần $amount trong tháng.';
  }

  @override
  String get assistantNoData =>
      'Chưa có đủ dữ liệu để trả lời câu này. Hãy ghi thêm vài giao dịch rồi thử lại.';

  @override
  String get assistantAnalysisError =>
      'Không thể phân tích lúc này. Hãy thử lại sau.';

  @override
  String get journalRecapTitle => 'Money Story';

  @override
  String journalRecapMonth(String month) {
    return 'Money Story $month';
  }

  @override
  String journalMoneyStoryMonth(String month) {
    return 'Tháng $month';
  }

  @override
  String get journalMoneyStoryExpenseLabel => 'Tổng chi tháng này';

  @override
  String journalRecordedCount(int count) {
    return 'Bạn đã ghi lại $count khoản chi';
  }

  @override
  String journalRecapSummary(String amount, String category) {
    return 'Tổng cộng $amount. Danh mục lớn nhất là $category.';
  }

  @override
  String get journalHighestDay => 'Ngày chi nhiều nhất';

  @override
  String journalHighestDayValue(String date, String amount) {
    return '$date — $amount trong một ngày';
  }

  @override
  String get journalComparedPrevious => 'So với tháng trước';

  @override
  String get journalSpentMore => 'Chi nhiều hơn';

  @override
  String get journalSpentLess => 'Chi ít hơn';

  @override
  String get journalTopCategories => 'Top danh mục';

  @override
  String get journalShareRecap => 'Chia sẻ story';

  @override
  String get journalMoneyStoryCashFlow => 'Dòng tiền tháng này';

  @override
  String get journalMoneyStoryIncome => 'Thu vào';

  @override
  String get journalMoneyStoryExpense => 'Chi ra';

  @override
  String get journalMoneyStoryNet => 'Còn lại';

  @override
  String get journalMoneyStoryAverageDay => 'Trung bình / ngày ghi';

  @override
  String journalMoneyStoryActiveDays(int count) {
    return '$count ngày có ghi chép';
  }

  @override
  String journalMoneyStoryCategoryShare(String category, int percent) {
    return '$category chiếm $percent%';
  }

  @override
  String journalMoneyStoryCategoryPercent(int percent) {
    return '$percent%';
  }

  @override
  String get journalMoneyStoryHighestDayEmpty =>
      'Chưa có ngày chi nổi bật trong tháng này.';

  @override
  String journalMoneyStoryHighestDayTransactions(int count) {
    return '$count khoản trong ngày này';
  }

  @override
  String get journalMoneyStoryInsightsTitle => 'Những điều tháng này kể lại';

  @override
  String journalMoneyStoryInsightSpendingDown(int percent) {
    return 'Bạn chi ít hơn $percent% so với tháng trước.';
  }

  @override
  String journalMoneyStoryInsightSpendingUp(int percent) {
    return 'Chi tiêu tăng $percent% so với tháng trước.';
  }

  @override
  String journalMoneyStoryInsightTopCategory(String category, int percent) {
    return '$category là điểm rơi lớn nhất, chiếm $percent% tổng chi.';
  }

  @override
  String journalMoneyStoryInsightWeekend(int percent) {
    return 'Cuối tuần chiếm $percent% chi tiêu của tháng.';
  }

  @override
  String journalMoneyStoryInsightRecording(int count) {
    return 'Bạn ghi chép trong $count ngày, đủ đều để nhìn ra thói quen.';
  }

  @override
  String get journalMoneyStoryInsightQuiet =>
      'Tháng này còn khá yên ắng. Ghi thêm vài khoản để story kể được nhiều hơn.';

  @override
  String get journalMoneyStoryShareTitle => 'Sẵn sàng lưu lại tháng này';

  @override
  String get journalMoneyStoryShareBody =>
      'Tạo poster gọn đẹp để chia sẻ hoặc giữ riêng trong máy.';

  @override
  String get journalMoneyStoryNoTransactionsTitle =>
      'Story tháng này còn trống';

  @override
  String get journalMoneyStoryNoTransactionsBody =>
      'Ghi vài khoản chi để Moniary kể lại tháng của bạn bằng số liệu và hình ảnh.';

  @override
  String get journalExportTitle => 'Xuất Money Story';

  @override
  String get journalExportPost => 'Đăng';

  @override
  String get journalExportSave => 'Lưu ảnh về máy';

  @override
  String get journalExportBrand => 'Moniary · Money Story';

  @override
  String get journalExportSaved => 'Đã tạo ảnh Money Story để bạn chia sẻ.';

  @override
  String get journalExportWholeMonth => 'Cả tháng';

  @override
  String get journalExportToday => 'Hôm nay';

  @override
  String get journalExportCustomRange => 'Tùy chọn ngày';

  @override
  String get journalExportNoTransactions =>
      'Chưa có giao dịch trong khoảng này';

  @override
  String get journalCollectionsTitle => 'Bộ sưu tập';

  @override
  String get journalCreateCollection => 'Tạo bộ sưu tập mới';

  @override
  String get journalCollectionName => 'Tên bộ sưu tập';

  @override
  String get journalCollectionNameHint => 'Ví dụ: Đà Lạt tháng 6';

  @override
  String get journalCollectionEmptyTitle => 'Chưa có bộ sưu tập';

  @override
  String get journalCollectionEmptyBody =>
      'Gom những khoản chi của một chuyến đi hoặc dịp đặc biệt để xem lại sau.';

  @override
  String journalCollectionMeta(int count, String amount) {
    return '$count khoản · $amount';
  }

  @override
  String get journalAddTransaction => 'Thêm khoản vào bộ sưu tập';

  @override
  String get journalChooseTransaction => 'Chọn giao dịch';

  @override
  String get journalCollectionNoTransactions =>
      'Bộ sưu tập này chưa có giao dịch.';

  @override
  String get journalStreakTitle => 'Chuỗi ghi chép';

  @override
  String get journalStreakBreadcrumb => 'Trang chủ — chuỗi ghi chép';

  @override
  String journalStreakDays(int count) {
    return '$count ngày liên tiếp';
  }

  @override
  String journalStreakBody(int count) {
    return 'Bạn đã ghi lại chi tiêu mỗi ngày trong $count ngày gần đây.';
  }

  @override
  String get journalStreakRecord => 'Kỷ lục của bạn';

  @override
  String journalStreakRecordDays(int count) {
    return '$count ngày';
  }

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
  String get friendInviteAgreeButton => 'Đồng ý';

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
  String get profileUsernameHint => 'Ví dụ: erling_haaland';

  @override
  String get profileUsernameInvalid =>
      'Username phải có 3-30 ký tự và chỉ gồm chữ thường, số hoặc dấu gạch dưới.';

  @override
  String get privacyProtectionSettingsTitle => 'Thiết lập bảo vệ';

  @override
  String get privacyHideBalancesTitle => 'Ẩn số dư';

  @override
  String get privacyHideBalancesSubtitle =>
      'Che số tiền trên các màn hình tổng quan và chi tiết.';

  @override
  String get privacyExploreTitle => 'Thông tin và kiểm soát';

  @override
  String get privacyStatusProtected => 'Đang bảo vệ';

  @override
  String get privacyStatusReview => 'Cần kiểm tra';

  @override
  String privacyRequestCount(int count) {
    return '$count yêu cầu';
  }

  @override
  String get biometricReasonDisable => 'Xác thực để tắt khóa ứng dụng';

  @override
  String get biometricReasonDeleteAccount =>
      'Xác thực để yêu cầu xóa tài khoản';

  @override
  String get deleteAccountGraceTitle => 'Tài khoản sẽ được xóa sau 30 ngày';

  @override
  String get deleteAccountGraceBody =>
      'Bạn sẽ được đăng xuất ngay. Trong 30 ngày, hãy đăng nhập bằng đúng phương thức hiện tại nếu muốn khôi phục tài khoản trước khi dữ liệu bị xóa vĩnh viễn.';

  @override
  String get deleteAccountExportTitle => 'Giữ một bản sao trước khi xóa';

  @override
  String get deleteAccountExportBody =>
      'Bạn có thể xuất dữ liệu trước khi gửi yêu cầu xóa. Lỗi xuất dữ liệu không ngăn bạn thực hiện quyền xóa tài khoản.';

  @override
  String get deleteAccountExportAction => 'Mở trang xuất dữ liệu';

  @override
  String get deleteAccountReasonTitle => 'Vì sao bạn rời Moniary?';

  @override
  String get deleteAccountReasonHint => 'Chọn một lý do';

  @override
  String get deleteAccountDetailsLabel => 'Ghi chú bổ sung (không bắt buộc)';

  @override
  String get deleteAccountDetailsHint =>
      'Điều gì có thể khiến trải nghiệm tốt hơn?';

  @override
  String get deleteAccountDetailsHelper =>
      'Không nhập email, thông tin tài chính hoặc dữ liệu nhạy cảm.';

  @override
  String get deleteAccountGraceUnderstand =>
      'Tôi hiểu tài khoản sẽ bị khóa sử dụng và xóa vĩnh viễn sau 30 ngày nếu không khôi phục.';

  @override
  String get deleteAccountConfirmationPhrase => 'XÓA';

  @override
  String deleteAccountConfirmationLabel(String phrase) {
    return 'Nhập $phrase để xác nhận';
  }

  @override
  String get deleteAccountScheduleAction => 'Yêu cầu xóa tài khoản';

  @override
  String get deleteReasonDifficultToUse => 'Khó sử dụng';

  @override
  String get deleteReasonMissingFeatures => 'Thiếu tính năng';

  @override
  String get deleteReasonTechnicalIssues => 'Gặp lỗi kỹ thuật';

  @override
  String get deleteReasonPrivacyConcerns => 'Lo ngại quyền riêng tư';

  @override
  String get deleteReasonNoLongerNeeded => 'Không còn nhu cầu';

  @override
  String get deleteReasonOther => 'Khác';

  @override
  String get deleteAccountImpactTitle => 'Dữ liệu bị ảnh hưởng';

  @override
  String deleteAccountTransactionsCount(int count) {
    return '$count giao dịch';
  }

  @override
  String deleteAccountWalletsCount(int count) {
    return '$count ví';
  }

  @override
  String deleteAccountPhotosCount(int count) {
    return '$count ảnh';
  }

  @override
  String get deleteAccountImpactUnavailable =>
      'Không thể tải số lượng chi tiết lúc này. Bạn vẫn có thể tiếp tục yêu cầu xóa.';

  @override
  String restoreAccountPendingBody(String requestedDate, String deletionDate) {
    return 'Yêu cầu xóa được tạo ngày $requestedDate. Dữ liệu sẽ bị xóa vĩnh viễn ngày $deletionDate.\n\nKhôi phục tài khoản để tiếp tục sử dụng Moniary.';
  }

  @override
  String get commonUnknown => 'Không xác định';

  @override
  String get loginEmailConfirmationSent =>
      'Vui lòng kiểm tra email để xác nhận tài khoản.';

  @override
  String get loginCreateAccount => 'Tạo tài khoản';

  @override
  String get loginEmailTitle => 'Đăng nhập bằng email';

  @override
  String get loginEmailLabel => 'Email';

  @override
  String get loginEmailRequired => 'Vui lòng nhập email';

  @override
  String get loginPasswordLabel => 'Mật khẩu';

  @override
  String get loginPasswordMinLength => 'Mật khẩu cần ít nhất 6 ký tự';

  @override
  String get loginSignUp => 'Đăng ký';

  @override
  String get loginSignIn => 'Đăng nhập';

  @override
  String get loginAlreadyHaveAccount => 'Đã có tài khoản? Đăng nhập';

  @override
  String get loginNeedAccount => 'Chưa có tài khoản? Đăng ký';

  @override
  String get resetPasswordTitle => 'Đặt mật khẩu mới';

  @override
  String get resetPasswordSubtitle =>
      'Nhập mật khẩu mới cho tài khoản của bạn.';

  @override
  String get resetPasswordConfirmLabel => 'Xác nhận mật khẩu mới';

  @override
  String get resetPasswordMismatch => 'Mật khẩu xác nhận không khớp';

  @override
  String get resetPasswordSubmit => 'Đặt lại mật khẩu';

  @override
  String get resetPasswordSuccess => 'Mật khẩu của bạn đã được cập nhật.';

  @override
  String get authErrorInvalidCredentials => 'Email hoặc mật khẩu không đúng.';

  @override
  String get authErrorEmailNotConfirmed =>
      'Vui lòng xác nhận email trước khi đăng nhập.';

  @override
  String get authErrorEmailAlreadyRegistered => 'Email này đã được đăng ký.';

  @override
  String get authErrorWeakPassword =>
      'Mật khẩu chưa đủ mạnh. Hãy thử mật khẩu dài hơn kèm số hoặc ký tự đặc biệt.';

  @override
  String get authErrorRateLimited =>
      'Bạn đã thử quá nhiều lần. Vui lòng thử lại sau.';

  @override
  String get authErrorUserBanned => 'Tài khoản này đã bị tạm khóa.';

  @override
  String get cameraFallbackPermissionDenied =>
      'Không có quyền truy cập camera. Bạn có thể nhập giao dịch thủ công.';

  @override
  String get cameraFallbackGenericError =>
      'Không thể mở camera. Bạn có thể nhập giao dịch thủ công.';

  @override
  String get scanSuggestionNotice =>
      'Thông tin trên hóa đơn đã được tự động điền. Hãy kiểm tra trước khi lưu.';

  @override
  String get scanAiSuggestion => 'Từ hóa đơn';

  @override
  String get scanSuggestionNeedsReview => 'Từ hóa đơn - nên kiểm tra lại';

  @override
  String get scanDetectedSummary => 'Thông tin nhận diện từ hóa đơn';

  @override
  String scanDetectedItemsCount(int count) {
    return 'Đã nhận diện $count mặt hàng';
  }

  @override
  String get scanPaymentMethod => 'Phương thức thanh toán';

  @override
  String get scanPaymentCash => 'Tiền mặt';

  @override
  String get scanPaymentCard => 'Thẻ';

  @override
  String get scanPaymentTransfer => 'Chuyển khoản';

  @override
  String get scanPaymentOther => 'Khác';

  @override
  String scanCurrency(String currency) {
    return 'Loại tiền: $currency';
  }

  @override
  String get scanValidationNotice =>
      'Một số thông tin nhận diện có thể cần bạn kiểm tra nhanh.';

  @override
  String get friendQrTitle => 'QR kết bạn';

  @override
  String get friendQrMyCode => 'Mã của tôi';

  @override
  String get friendQrScan => 'Quét mã';

  @override
  String get friendQrRetry => 'Thử lại';

  @override
  String get friendQrShare => 'Chia sẻ mã';

  @override
  String get friendQrLoadError => 'Không thể khởi động camera.';

  @override
  String get friendQrTorch => 'Bật hoặc tắt đèn pin';

  @override
  String get friendQrSwitchCamera => 'Đổi camera';

  @override
  String get friendQrInvalid => 'Đây không phải mã QR kết bạn Moniary hợp lệ.';

  @override
  String get friendRateLimited =>
      'Bạn đã gửi quá nhiều lời mời kết bạn. Vui lòng thử lại sau.';

  @override
  String get paymentQrTitle => 'Mã QR nhận tiền';

  @override
  String get paymentQrProfileSubtitle =>
      'Lưu một lần để thành viên nhóm mở khi thanh toán.';

  @override
  String get paymentQrMyTitle => 'Mã QR của tôi';

  @override
  String get paymentQrDescription =>
      'Thành viên trong cùng nhóm có thể mở mã này khi cần chuyển tiền cho bạn.';

  @override
  String paymentQrMemberDescription(String name) {
    return 'Mã QR nhận tiền của $name.';
  }

  @override
  String get paymentQrAdd => 'Lưu ảnh mã QR';

  @override
  String get paymentQrReplace => 'Thay ảnh mã QR';

  @override
  String get paymentQrRemove => 'Xóa mã QR';

  @override
  String get paymentQrPrivacyNote =>
      'Mã QR được lưu riêng tư và chỉ hiển thị cho thành viên cùng nhóm.';

  @override
  String get paymentQrSaved => 'Đã lưu mã QR nhận tiền.';

  @override
  String get paymentQrRemoved => 'Đã xóa mã QR nhận tiền.';

  @override
  String get paymentQrViewForPayment => 'Mở QR để thanh toán';

  @override
  String get paymentQrEmptyOwner => 'Bạn chưa lưu ảnh mã QR nhận tiền.';

  @override
  String get paymentQrEmptyMember => 'Thành viên này chưa lưu mã QR nhận tiền.';

  @override
  String get groupSettingsTitle => 'Cài đặt nhóm';

  @override
  String get groupSettingsSubtitle =>
      'Chỉnh thông tin nhóm và chỉ đóng nhóm sau khi đã tất toán.';

  @override
  String get groupSettingsName => 'Tên nhóm';

  @override
  String get groupSettingsDescription => 'Mô tả';

  @override
  String get groupSettingsType => 'Loại nhóm';

  @override
  String get groupSettingsBaseCurrency => 'Tiền tệ chung của nhóm';

  @override
  String get groupSettingsBaseCurrencySubtitle =>
      'Tất toán và ngân sách dùng tiền tệ này. Giao dịch ngoại tệ cần nhập tỷ giá rõ ràng.';

  @override
  String get groupSettingsSave => 'Lưu thay đổi';

  @override
  String get groupSettingsSaved => 'Đã cập nhật thông tin nhóm.';

  @override
  String get groupSettingsArchiveTitle => 'Đóng nhóm';

  @override
  String get groupSettingsArchiveSubtitle =>
      'Nhóm sẽ ẩn khỏi danh sách và không nhận giao dịch mới. Công nợ chưa xử lý sẽ chặn thao tác này.';

  @override
  String get groupSettingsArchiveAction => 'Đóng nhóm';

  @override
  String get groupSettingsArchiveConfirmTitle => 'Đóng nhóm này?';

  @override
  String get groupSettingsArchiveConfirmMessage =>
      'Chỉ nên đóng nhóm sau khi mọi thành viên đã hoàn tất thanh toán.';

  @override
  String get groupSettingsArchiveBlocked =>
      'Chưa thể đóng nhóm vì vẫn còn công nợ, giao dịch chờ xử lý hoặc tranh chấp.';

  @override
  String get groupSettingsAdminRequired =>
      'Chỉ chủ nhóm hoặc quản trị viên mới có quyền thực hiện thao tác này.';

  @override
  String get groupAuditLogTitle => 'Nhật ký quản trị';

  @override
  String get groupAuditLogSubtitle =>
      'Theo dõi thay đổi thành viên, giao dịch và cài đặt nhóm.';

  @override
  String get groupAuditLogEmpty =>
      'Chưa có hoạt động quản trị nào được ghi nhận.';

  @override
  String get groupAuditSystem => 'Hệ thống';

  @override
  String get groupParticipationTitle => 'Hoạt động cùng nhóm';

  @override
  String get groupParticipationSubtitle =>
      'Cùng bình chọn và biến mục tiêu chung thành tiến độ.';

  @override
  String get groupPollsTitle => 'Bình chọn';

  @override
  String get groupPollsEmpty => 'Chưa có bình chọn.';

  @override
  String get groupPollCreate => 'Tạo bình chọn';

  @override
  String get groupPollQuestion => 'Câu hỏi';

  @override
  String get groupPollOptionsHint => 'Các lựa chọn, mỗi dòng một lựa chọn';

  @override
  String get groupChallengesTitle => 'Thử thách tiết kiệm';

  @override
  String get groupChallengesEmpty => 'Chưa có thử thách tiết kiệm.';

  @override
  String get groupChallengeCreate => 'Tạo thử thách';

  @override
  String get groupChallengeName => 'Tên thử thách';

  @override
  String get groupChallengeTarget => 'Số tiền mục tiêu';

  @override
  String get groupChallengeContribute => 'Đóng góp';

  @override
  String get groupPulsePersonalTitle => 'Việc tiếp theo của bạn';

  @override
  String get groupPulsePersonalMessage =>
      'Có một khoản cần bạn xử lý để nhóm tiếp tục nhẹ nhàng hơn.';

  @override
  String get groupPulseUpcomingTitle => 'Sắp đến lịch chung';

  @override
  String groupPulseUpcomingMessage(String title) {
    return '$title sắp đến hạn. Cùng chuẩn bị trước để không bỏ lỡ.';
  }

  @override
  String get groupPulseTogetherTitle => 'Cùng giữ nhịp nhóm';

  @override
  String get groupPulseTogetherMessage =>
      'Mở dòng hoạt động để mọi người cùng cập nhật và phản hồi.';

  @override
  String get groupPulseAllClearTitle => 'Nhóm đang rất ổn';

  @override
  String get groupPulseAllClearMessage =>
      'Không còn khoản chờ xử lý. Thêm một khoản chi mới để cả nhóm cùng thấy tiến độ.';

  @override
  String get groupSpotlightTitle => 'Điểm chạm mới nhất';

  @override
  String get groupSpotlightComment => 'Xem và phản hồi';

  @override
  String get groupSummaryContributionTitle => 'Đóng góp nổi bật';

  @override
  String groupSummaryContributionMessage(String name) {
    return '$name đang giúp nhóm giữ nhịp đều đặn trong tháng này.';
  }

  @override
  String groupSummaryContributionCount(int count) {
    return '$count hoạt động';
  }

  @override
  String get groupSplitExact => 'Số tiền cụ thể';

  @override
  String get groupParticipantsTitle => 'Người tham gia khoản chi';

  @override
  String get groupSettlementDisputeTitle => 'Báo cáo vấn đề thanh toán';

  @override
  String get groupSettlementDisputeReasonHint =>
      'Mô tả thông tin chưa chính xác';

  @override
  String get groupSettlementDisputeReasonRequired =>
      'Vui lòng nhập lý do tranh chấp.';

  @override
  String get groupSettlementDisputeAction => 'Tranh chấp';

  @override
  String get groupTransferOwnershipAction => 'Chuyển quyền chủ nhóm';

  @override
  String get groupRemoveMemberAction => 'Xóa thành viên';

  @override
  String get groupMemberRemoveUnresolved =>
      'Thành viên này vẫn còn số dư chưa quyết toán nên chưa thể xóa.';

  @override
  String get groupMemberActionForbidden =>
      'Bạn không có quyền quản lý thành viên này.';

  @override
  String get mascotFirstTransaction =>
      'Chào bạn! Hãy thêm giao dịch đầu tiên để heo theo dõi nhé! 🐷';

  @override
  String mascotOverBudget(String category) {
    return 'Ví đang khóc vì mục $category vượt trần rồi kìa! 🛑';
  }

  @override
  String mascotNearBudget(String category) {
    return 'Coi chừng mục $category sắp chạm trần ngân sách nha! ⚠️';
  }

  @override
  String get mascotZeroExpenseToday =>
      'Hôm nay chưa tiêu đồng nào! Heo tự hào về bạn! 🐖💖';

  @override
  String mascotGoodSavings(String percent) {
    return 'Tháng này tiết kiệm được $percent%. Quá siêu! 🏆';
  }

  @override
  String get mascotFunQuote1 => 'Hôm nay bạn đã ghi chép chi tiêu chưa? 📝';

  @override
  String get mascotFunQuote2 => 'Nghe heo đi, đừng mua món đó! 🐽';

  @override
  String get mascotFunQuote3 => 'Tiết kiệm một đồng là kiếm được một đồng! 💰';

  @override
  String get mascotFunQuote4 => 'Nuôi heo đất mau lớn để đi chơi thôi! 🐖';

  @override
  String get mascotFunQuote5 => 'Bấm vào heo để nhận lời khuyên nè! 🐷';

  @override
  String mascotStreakPraise(int days) {
    return 'Bạn đã ghi chép liên tục $days ngày rồi! Siêu quá heo ơi! 🐷🔥';
  }

  @override
  String get widgetTotalBalance => 'Số dư tổng';

  @override
  String get widgetTodaySpending => 'Chi tiêu hôm nay';

  @override
  String get widgetQuickAdd => 'Ghi chép';

  @override
  String get widgetScanReceipt => 'Quét ảnh';

  @override
  String get mascotMorningGreeting =>
      'Chào buổi sáng! Hôm nay bạn có dự định chi tiêu gì chưa? 🐷☀️';

  @override
  String get mascotNightGreeting =>
      'Khuya rồi, nghỉ ngơi thôi heo ơi! Chúc bạn ngủ ngon nhé! 🐷💤';

  @override
  String get mascotTapReaction1 => 'Ối! Đừng chọc heo nha, nhột lắm đó! 🐷';

  @override
  String get mascotTapReaction2 =>
      'Chào bạn! Cùng heo ghi chép chi tiêu đầy đủ nhé! 🐷💰';

  @override
  String get mascotTapReaction3 =>
      'Bạn có biết ghi chép đều đặn giúp tiết kiệm tới 20% không? 🐷✨';

  @override
  String get widgetStreakTitle => 'Chuỗi ghi';

  @override
  String get widgetLongestStreak => 'Kỷ lục';

  @override
  String widgetDays(int count) {
    return '$count ngày';
  }

  @override
  String get widgetBudgetTitle => 'Ngân sách';

  @override
  String get widgetBudgetSpent => 'Đã chi';

  @override
  String get widgetBudgetRemaining => 'Còn lại';

  @override
  String get widgetOverBudget => 'Vượt hạn mức';

  @override
  String get mascotFeedAction => 'Cho Heo ăn 🍎';

  @override
  String get mascotFedResponse => 'Ngon quá! Heo no bụng rồi, cảm ơn nha! 💖🐷';

  @override
  String get notificationsTitle => 'Thông báo';

  @override
  String get notificationsFilterAll => 'Tất cả';

  @override
  String get notificationsCategoryPersonal => 'Cá nhân';

  @override
  String get notificationsCategoryGroup => 'Group';

  @override
  String get notificationsCategoryCommunity => 'Cộng đồng';

  @override
  String get notificationsCategorySystem => 'Hệ thống';

  @override
  String get notificationsMarkAllRead => 'Đã đọc hết';

  @override
  String get notificationsEmpty => 'Chưa có thông báo trong 30 ngày qua';

  @override
  String get notificationFriendRequest => 'Bạn có lời mời kết bạn mới';

  @override
  String get notificationFriendAccepted => 'Lời mời kết bạn đã được chấp nhận';

  @override
  String get notificationGroupTransaction => 'Có giao dịch mới trong group';

  @override
  String get notificationAmountRequired => 'Bạn cần nhập phần tiền của mình';

  @override
  String get notificationGroupInvite => 'Bạn được mời vào một group';

  @override
  String get notificationDebtSettled =>
      'Một khoản nợ trong group đã được tất toán';

  @override
  String get notificationCommunityComment => 'Có bình luận mới trong cộng đồng';

  @override
  String get notificationCommunityReaction =>
      'Có người tương tác với giao dịch';

  @override
  String get notificationCommunityMention =>
      'Bạn được nhắc tên trong cộng đồng';

  @override
  String get notificationGeneric => 'Bạn có cập nhật mới';

  @override
  String get pushNotificationSectionTitle => 'Thông báo trên điện thoại';

  @override
  String get pushNotificationSectionDesc =>
      'Chọn loại thông báo được phép hiển thị khi Moniary không mở.';

  @override
  String get pushNotificationAllTitle => 'Cho phép thông báo đẩy';

  @override
  String get pushNotificationAllSubtitle =>
      'Tắt chỉ chặn thông báo trên điện thoại; lịch sử vẫn ở trong inbox.';

  @override
  String get pushNotificationCategorySubtitle =>
      'Thông báo vẫn được lưu trong inbox trong 30 ngày.';
}
