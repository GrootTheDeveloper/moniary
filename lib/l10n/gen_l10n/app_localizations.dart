import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_vi.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'gen_l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('vi'),
  ];

  /// No description provided for @appName.
  ///
  /// In vi, this message translates to:
  /// **'Moniary'**
  String get appName;

  /// No description provided for @commonSave.
  ///
  /// In vi, this message translates to:
  /// **'Lưu'**
  String get commonSave;

  /// No description provided for @commonCancel.
  ///
  /// In vi, this message translates to:
  /// **'Hủy'**
  String get commonCancel;

  /// No description provided for @commonDelete.
  ///
  /// In vi, this message translates to:
  /// **'Xóa'**
  String get commonDelete;

  /// No description provided for @commonEdit.
  ///
  /// In vi, this message translates to:
  /// **'Sửa'**
  String get commonEdit;

  /// No description provided for @commonRetry.
  ///
  /// In vi, this message translates to:
  /// **'Thử lại'**
  String get commonRetry;

  /// No description provided for @commonAdd.
  ///
  /// In vi, this message translates to:
  /// **'Thêm'**
  String get commonAdd;

  /// No description provided for @commonClose.
  ///
  /// In vi, this message translates to:
  /// **'Đóng'**
  String get commonClose;

  /// No description provided for @commonSaving.
  ///
  /// In vi, this message translates to:
  /// **'Đang lưu...'**
  String get commonSaving;

  /// No description provided for @commonLoading.
  ///
  /// In vi, this message translates to:
  /// **'Đang tải...'**
  String get commonLoading;

  /// No description provided for @commonCopy.
  ///
  /// In vi, this message translates to:
  /// **'Copy'**
  String get commonCopy;

  /// No description provided for @commonShare.
  ///
  /// In vi, this message translates to:
  /// **'Chia sẻ'**
  String get commonShare;

  /// No description provided for @commonOpen.
  ///
  /// In vi, this message translates to:
  /// **'Mở'**
  String get commonOpen;

  /// No description provided for @commonSelect.
  ///
  /// In vi, this message translates to:
  /// **'Chọn'**
  String get commonSelect;

  /// No description provided for @commonCreate.
  ///
  /// In vi, this message translates to:
  /// **'Tạo'**
  String get commonCreate;

  /// No description provided for @errorGeneric.
  ///
  /// In vi, this message translates to:
  /// **'Đã xảy ra lỗi. Vui lòng thử lại.'**
  String get errorGeneric;

  /// No description provided for @errorNotLoggedIn.
  ///
  /// In vi, this message translates to:
  /// **'Bạn chưa đăng nhập.'**
  String get errorNotLoggedIn;

  /// No description provided for @errorConnection.
  ///
  /// In vi, this message translates to:
  /// **'Lỗi kết nối. Vui lòng thử lại.'**
  String get errorConnection;

  /// No description provided for @loginTitle.
  ///
  /// In vi, this message translates to:
  /// **'Moniary'**
  String get loginTitle;

  /// No description provided for @loginSubtitle.
  ///
  /// In vi, this message translates to:
  /// **'Quản lý chi tiêu cá nhân'**
  String get loginSubtitle;

  /// No description provided for @loginAnonymous.
  ///
  /// In vi, this message translates to:
  /// **'Bắt đầu dùng thử ẩn danh'**
  String get loginAnonymous;

  /// No description provided for @loginTerms.
  ///
  /// In vi, this message translates to:
  /// **'Bằng cách tiếp tục, bạn đồng ý với các điều khoản sử dụng và chính sách bảo mật của Moniary.'**
  String get loginTerms;

  /// No description provided for @loginFeatureSubtitle.
  ///
  /// In vi, this message translates to:
  /// **'Ghi chi tiêu bằng ảnh'**
  String get loginFeatureSubtitle;

  /// No description provided for @loginHeader.
  ///
  /// In vi, this message translates to:
  /// **'Đăng nhập'**
  String get loginHeader;

  /// No description provided for @loginGoogle.
  ///
  /// In vi, this message translates to:
  /// **'Đăng nhập với Google (Sắp có)'**
  String get loginGoogle;

  /// No description provided for @loginApple.
  ///
  /// In vi, this message translates to:
  /// **'Đăng nhập với Apple (Sắp có)'**
  String get loginApple;

  /// No description provided for @loginEmail.
  ///
  /// In vi, this message translates to:
  /// **'Đăng nhập với Email (Sắp có)'**
  String get loginEmail;

  /// No description provided for @loginOr.
  ///
  /// In vi, this message translates to:
  /// **'hoặc'**
  String get loginOr;

  /// No description provided for @loginConnecting.
  ///
  /// In vi, this message translates to:
  /// **'Đang kết nối Supabase...'**
  String get loginConnecting;

  /// No description provided for @loginTryWithoutAuth.
  ///
  /// In vi, this message translates to:
  /// **'Dùng thử không cần đăng nhập'**
  String get loginTryWithoutAuth;

  /// No description provided for @loginSessionReady.
  ///
  /// In vi, this message translates to:
  /// **'Phiên đăng nhập đã sẵn sàng. Bạn có thể vào thẳng Lịch.'**
  String get loginSessionReady;

  /// No description provided for @loginDataSecure.
  ///
  /// In vi, this message translates to:
  /// **'Dữ liệu của bạn được bảo mật và đồng bộ với Supabase.'**
  String get loginDataSecure;

  /// No description provided for @splashLoading.
  ///
  /// In vi, this message translates to:
  /// **'Đang tải ứng dụng...'**
  String get splashLoading;

  /// No description provided for @splashRetry.
  ///
  /// In vi, this message translates to:
  /// **'Thử lại'**
  String get splashRetry;

  /// No description provided for @splashError.
  ///
  /// In vi, this message translates to:
  /// **'Không thể kết nối. Vui lòng kiểm tra mạng và thử lại.'**
  String get splashError;

  /// No description provided for @splashErrorConnecting.
  ///
  /// In vi, this message translates to:
  /// **'Không thể kết nối'**
  String get splashErrorConnecting;

  /// No description provided for @splashSubtitle.
  ///
  /// In vi, this message translates to:
  /// **'Ghi chi tiêu bằng ảnh'**
  String get splashSubtitle;

  /// No description provided for @splashDescription.
  ///
  /// In vi, this message translates to:
  /// **'Chụp lại khoản chi, lưu vào lịch,\nquản lý tiền dễ như lưu kỷ niệm.'**
  String get splashDescription;

  /// No description provided for @splashStarting.
  ///
  /// In vi, this message translates to:
  /// **'Đang khởi động {appName}...'**
  String splashStarting(String appName);

  /// No description provided for @onboardingSkip.
  ///
  /// In vi, this message translates to:
  /// **'Bỏ qua'**
  String get onboardingSkip;

  /// No description provided for @onboardingStart.
  ///
  /// In vi, this message translates to:
  /// **'Bắt đầu'**
  String get onboardingStart;

  /// No description provided for @onboardingNext.
  ///
  /// In vi, this message translates to:
  /// **'Tiếp'**
  String get onboardingNext;

  /// No description provided for @onboardingNextPage.
  ///
  /// In vi, this message translates to:
  /// **'Xem tiếp'**
  String get onboardingNextPage;

  /// No description provided for @onboardingFinish.
  ///
  /// In vi, this message translates to:
  /// **'Tiếp tục'**
  String get onboardingFinish;

  /// No description provided for @onboardingMonthMock.
  ///
  /// In vi, this message translates to:
  /// **'Tháng 5'**
  String get onboardingMonthMock;

  /// No description provided for @onboardingPillCapture.
  ///
  /// In vi, this message translates to:
  /// **'Chụp & lưu'**
  String get onboardingPillCapture;

  /// No description provided for @onboardingPillCalendar.
  ///
  /// In vi, this message translates to:
  /// **'Xem theo ngày'**
  String get onboardingPillCalendar;

  /// No description provided for @onboardingPillStats.
  ///
  /// In vi, this message translates to:
  /// **'Thống kê'**
  String get onboardingPillStats;

  /// No description provided for @onboardingPage1Title1.
  ///
  /// In vi, this message translates to:
  /// **'Ghi chi tiêu'**
  String get onboardingPage1Title1;

  /// No description provided for @onboardingPage1Title2.
  ///
  /// In vi, this message translates to:
  /// **'bằng ảnh'**
  String get onboardingPage1Title2;

  /// No description provided for @onboardingPage1Subtitle.
  ///
  /// In vi, this message translates to:
  /// **'Nhanh gọn  •  Dễ nhớ  •  Không bỏ sót'**
  String get onboardingPage1Subtitle;

  /// No description provided for @onboardingPage1Caption.
  ///
  /// In vi, this message translates to:
  /// **'Lưu khoảnh khắc chi tiêu như một cuốn nhật ký mini.'**
  String get onboardingPage1Caption;

  /// No description provided for @onboardingPage2Title1.
  ///
  /// In vi, this message translates to:
  /// **'Xem lịch tháng'**
  String get onboardingPage2Title1;

  /// No description provided for @onboardingPage2Title2.
  ///
  /// In vi, this message translates to:
  /// **'trực quan'**
  String get onboardingPage2Title2;

  /// No description provided for @onboardingPage2Subtitle.
  ///
  /// In vi, this message translates to:
  /// **'Ảnh, tổng chi, bộ lọc và nhắc nhở trong một màn hình'**
  String get onboardingPage2Subtitle;

  /// No description provided for @onboardingPage2Caption.
  ///
  /// In vi, this message translates to:
  /// **'Mỗi ngày là một ô nhỏ, mỗi giao dịch là một kỷ niệm.'**
  String get onboardingPage2Caption;

  /// No description provided for @onboardingPage3Title1.
  ///
  /// In vi, this message translates to:
  /// **'Thống kê'**
  String get onboardingPage3Title1;

  /// No description provided for @onboardingPage3Title2.
  ///
  /// In vi, this message translates to:
  /// **'dễ hiểu'**
  String get onboardingPage3Title2;

  /// No description provided for @onboardingPage3Subtitle.
  ///
  /// In vi, this message translates to:
  /// **'Theo dõi thu chi và thói quen tiêu dùng không cần bảng biểu khó'**
  String get onboardingPage3Subtitle;

  /// No description provided for @onboardingPage3Caption.
  ///
  /// In vi, this message translates to:
  /// **'Moniary giúp bạn nhìn tiền theo ngữ cảnh sống thật.'**
  String get onboardingPage3Caption;

  /// No description provided for @profileSetupTitle.
  ///
  /// In vi, this message translates to:
  /// **'Thiết lập hồ sơ'**
  String get profileSetupTitle;

  /// No description provided for @profileSetupSubtitle.
  ///
  /// In vi, this message translates to:
  /// **'Hoàn tất thông tin để bắt đầu'**
  String get profileSetupSubtitle;

  /// No description provided for @profileSetupDisplayName.
  ///
  /// In vi, this message translates to:
  /// **'Tên hiển thị'**
  String get profileSetupDisplayName;

  /// No description provided for @profileSetupDisplayNameHint.
  ///
  /// In vi, this message translates to:
  /// **'Nhập tên của bạn'**
  String get profileSetupDisplayNameHint;

  /// No description provided for @profileSetupCurrency.
  ///
  /// In vi, this message translates to:
  /// **'Đơn vị tiền tệ'**
  String get profileSetupCurrency;

  /// No description provided for @profileSetupStart.
  ///
  /// In vi, this message translates to:
  /// **'Bắt đầu'**
  String get profileSetupStart;

  /// No description provided for @profileSetupNameRequired.
  ///
  /// In vi, this message translates to:
  /// **'Nhập tên hiển thị trước.'**
  String get profileSetupNameRequired;

  /// No description provided for @calendarTitle.
  ///
  /// In vi, this message translates to:
  /// **'Lịch'**
  String get calendarTitle;

  /// No description provided for @calendarAllWallets.
  ///
  /// In vi, this message translates to:
  /// **'Tất cả ví'**
  String get calendarAllWallets;

  /// No description provided for @calendarAllCategories.
  ///
  /// In vi, this message translates to:
  /// **'Tất cả danh mục'**
  String get calendarAllCategories;

  /// No description provided for @calendarNoTransactions.
  ///
  /// In vi, this message translates to:
  /// **'Không có giao dịch trong tháng này.'**
  String get calendarNoTransactions;

  /// No description provided for @calendarIncome.
  ///
  /// In vi, this message translates to:
  /// **'Thu'**
  String get calendarIncome;

  /// No description provided for @calendarExpense.
  ///
  /// In vi, this message translates to:
  /// **'Chi'**
  String get calendarExpense;

  /// No description provided for @calendarBalance.
  ///
  /// In vi, this message translates to:
  /// **'Số dư'**
  String get calendarBalance;

  /// No description provided for @calendarSelectWalletFilter.
  ///
  /// In vi, this message translates to:
  /// **'Chọn ví lọc'**
  String get calendarSelectWalletFilter;

  /// No description provided for @calendarSelectCategoryFilter.
  ///
  /// In vi, this message translates to:
  /// **'Chọn danh mục lọc'**
  String get calendarSelectCategoryFilter;

  /// No description provided for @calendarMonthlyExpense.
  ///
  /// In vi, this message translates to:
  /// **'Tổng chi tháng'**
  String get calendarMonthlyExpense;

  /// No description provided for @calendarMonthlyIncome.
  ///
  /// In vi, this message translates to:
  /// **'Tổng thu tháng'**
  String get calendarMonthlyIncome;

  /// No description provided for @calendarEmptyMessage.
  ///
  /// In vi, this message translates to:
  /// **'Chưa có giao dịch nào trong tháng này. Bước tiếp theo là thêm giao dịch để lịch hiện dữ liệu thật.'**
  String get calendarEmptyMessage;

  /// No description provided for @calendarStatsMessage.
  ///
  /// In vi, this message translates to:
  /// **'{count} giao dịch trong {days} ngày có hoạt động. Lịch đang đọc dữ liệu thật từ Supabase.'**
  String calendarStatsMessage(int count, int days);

  /// No description provided for @calendarLoadError.
  ///
  /// In vi, this message translates to:
  /// **'Không tải được lịch tháng: {error}'**
  String calendarLoadError(String error);

  /// No description provided for @calendarStatsTab.
  ///
  /// In vi, this message translates to:
  /// **'Thống kê'**
  String get calendarStatsTab;

  /// No description provided for @calendarMon.
  ///
  /// In vi, this message translates to:
  /// **'T2'**
  String get calendarMon;

  /// No description provided for @calendarTue.
  ///
  /// In vi, this message translates to:
  /// **'T3'**
  String get calendarTue;

  /// No description provided for @calendarWed.
  ///
  /// In vi, this message translates to:
  /// **'T4'**
  String get calendarWed;

  /// No description provided for @calendarThu.
  ///
  /// In vi, this message translates to:
  /// **'T5'**
  String get calendarThu;

  /// No description provided for @calendarFri.
  ///
  /// In vi, this message translates to:
  /// **'T6'**
  String get calendarFri;

  /// No description provided for @calendarSat.
  ///
  /// In vi, this message translates to:
  /// **'T7'**
  String get calendarSat;

  /// No description provided for @calendarSun.
  ///
  /// In vi, this message translates to:
  /// **'CN'**
  String get calendarSun;

  /// No description provided for @calendarToday.
  ///
  /// In vi, this message translates to:
  /// **'Hôm nay'**
  String get calendarToday;

  /// No description provided for @transactionSaveTransaction.
  ///
  /// In vi, this message translates to:
  /// **'Lưu giao dịch'**
  String get transactionSaveTransaction;

  /// No description provided for @transactionLoadDayError.
  ///
  /// In vi, this message translates to:
  /// **'Không tải được giao dịch trong ngày.\n{error}'**
  String transactionLoadDayError(String error);

  /// No description provided for @transactionTotalIncome.
  ///
  /// In vi, this message translates to:
  /// **'Tổng thu'**
  String get transactionTotalIncome;

  /// No description provided for @transactionTotalExpense.
  ///
  /// In vi, this message translates to:
  /// **'Tổng chi'**
  String get transactionTotalExpense;

  /// No description provided for @transactionNetTotal.
  ///
  /// In vi, this message translates to:
  /// **'Tổng cộng'**
  String get transactionNetTotal;

  /// No description provided for @transactionCount.
  ///
  /// In vi, this message translates to:
  /// **'{count} giao dịch'**
  String transactionCount(int count);

  /// No description provided for @transactionDayEmpty.
  ///
  /// In vi, this message translates to:
  /// **'Ngày này chưa có giao dịch. Bạn có thể bấm nút + để thêm ngay.'**
  String get transactionDayEmpty;

  /// No description provided for @transactionLoadDetailError.
  ///
  /// In vi, this message translates to:
  /// **'Không tải được chi tiết giao dịch.\n{error}'**
  String transactionLoadDetailError(String error);

  /// No description provided for @transactionNoteEmpty.
  ///
  /// In vi, this message translates to:
  /// **'Chưa có ghi chú cho giao dịch này.'**
  String get transactionNoteEmpty;

  /// No description provided for @transactionDeleteTitleQuestion.
  ///
  /// In vi, this message translates to:
  /// **'Xóa giao dịch?'**
  String get transactionDeleteTitleQuestion;

  /// No description provided for @transactionDeleteUndone.
  ///
  /// In vi, this message translates to:
  /// **'Hành động này không thể hoàn tác.'**
  String get transactionDeleteUndone;

  /// No description provided for @transactionAmount.
  ///
  /// In vi, this message translates to:
  /// **'Số tiền'**
  String get transactionAmount;

  /// No description provided for @transactionAmountSuffix.
  ///
  /// In vi, this message translates to:
  /// **'đ'**
  String get transactionAmountSuffix;

  /// No description provided for @transactionWallet.
  ///
  /// In vi, this message translates to:
  /// **'Ví'**
  String get transactionWallet;

  /// No description provided for @transactionCategory.
  ///
  /// In vi, this message translates to:
  /// **'Danh mục'**
  String get transactionCategory;

  /// No description provided for @transactionNote.
  ///
  /// In vi, this message translates to:
  /// **'Ghi chú'**
  String get transactionNote;

  /// No description provided for @transactionNoteHint.
  ///
  /// In vi, this message translates to:
  /// **'Tra sua KOI / Luong freelance / ...'**
  String get transactionNoteHint;

  /// No description provided for @transactionDate.
  ///
  /// In vi, this message translates to:
  /// **'Ngày giao dịch'**
  String get transactionDate;

  /// No description provided for @transactionSelectWalletCategory.
  ///
  /// In vi, this message translates to:
  /// **'Chọn ví và danh mục trước khi lưu.'**
  String get transactionSelectWalletCategory;

  /// No description provided for @transactionAmountInvalid.
  ///
  /// In vi, this message translates to:
  /// **'Nhập số tiền hợp lệ.'**
  String get transactionAmountInvalid;

  /// No description provided for @transactionSaving.
  ///
  /// In vi, this message translates to:
  /// **'Đang lưu...'**
  String get transactionSaving;

  /// No description provided for @transactionCreateTitle.
  ///
  /// In vi, this message translates to:
  /// **'Tạo giao dịch'**
  String get transactionCreateTitle;

  /// No description provided for @transactionEditTitle.
  ///
  /// In vi, this message translates to:
  /// **'Sửa giao dịch'**
  String get transactionEditTitle;

  /// No description provided for @transactionDeleteConfirm.
  ///
  /// In vi, this message translates to:
  /// **'Xác nhận xóa giao dịch này?'**
  String get transactionDeleteConfirm;

  /// No description provided for @transactionDeleteSuccess.
  ///
  /// In vi, this message translates to:
  /// **'Đã xóa giao dịch.'**
  String get transactionDeleteSuccess;

  /// No description provided for @transactionSaveError.
  ///
  /// In vi, this message translates to:
  /// **'Không lưu được giao dịch: {error}'**
  String transactionSaveError(String error);

  /// No description provided for @transactionCreateSubtitle.
  ///
  /// In vi, this message translates to:
  /// **'Lưu giao dịch trước, phần ảnh sẽ được thêm ở bước tiếp theo.'**
  String get transactionCreateSubtitle;

  /// No description provided for @transactionWalletCategoryLoadError.
  ///
  /// In vi, this message translates to:
  /// **'Không tải được ví/danh mục. Mở quản lý dữ liệu để kiểm tra.'**
  String get transactionWalletCategoryLoadError;

  /// No description provided for @transactionChangePhoto.
  ///
  /// In vi, this message translates to:
  /// **'Thay đổi ảnh'**
  String get transactionChangePhoto;

  /// No description provided for @transactionEnterNote.
  ///
  /// In vi, this message translates to:
  /// **'Nhập ghi chú...'**
  String get transactionEnterNote;

  /// No description provided for @transactionSelectCategory.
  ///
  /// In vi, this message translates to:
  /// **'Chọn danh mục'**
  String get transactionSelectCategory;

  /// No description provided for @transactionSelectWallet.
  ///
  /// In vi, this message translates to:
  /// **'Chọn ví'**
  String get transactionSelectWallet;

  /// No description provided for @transactionDateTime.
  ///
  /// In vi, this message translates to:
  /// **'Ngày giờ'**
  String get transactionDateTime;

  /// No description provided for @transactionWalletAccount.
  ///
  /// In vi, this message translates to:
  /// **'Ví / Tài khoản'**
  String get transactionWalletAccount;

  /// No description provided for @transactionExpenseCategory.
  ///
  /// In vi, this message translates to:
  /// **'Danh mục chi'**
  String get transactionExpenseCategory;

  /// No description provided for @transactionLoadingWalletCategory.
  ///
  /// In vi, this message translates to:
  /// **'Đang tải ví và danh mục...'**
  String get transactionLoadingWalletCategory;

  /// No description provided for @transactionWalletCategoryError.
  ///
  /// In vi, this message translates to:
  /// **'Không tải được ví hoặc danh mục. Vui lòng thử lại.'**
  String get transactionWalletCategoryError;

  /// No description provided for @transactionWalletCategoryRequired.
  ///
  /// In vi, this message translates to:
  /// **'Cần có ví và danh mục chi đang hoạt động trước khi lưu.'**
  String get transactionWalletCategoryRequired;

  /// No description provided for @transactionAmountPositive.
  ///
  /// In vi, this message translates to:
  /// **'Nhập số tiền lớn hơn 0.'**
  String get transactionAmountPositive;

  /// No description provided for @transactionType.
  ///
  /// In vi, this message translates to:
  /// **'Loại giao dịch'**
  String get transactionType;

  /// No description provided for @walletTitle.
  ///
  /// In vi, this message translates to:
  /// **'Ví / Tài khoản'**
  String get walletTitle;

  /// No description provided for @walletDescription.
  ///
  /// In vi, this message translates to:
  /// **'Quản lý ví mặc định, số dư khởi tạo và trạng thái kích hoạt.'**
  String get walletDescription;

  /// No description provided for @walletEmpty.
  ///
  /// In vi, this message translates to:
  /// **'Chưa có ví nào.'**
  String get walletEmpty;

  /// No description provided for @walletDefault.
  ///
  /// In vi, this message translates to:
  /// **'Mặc định'**
  String get walletDefault;

  /// No description provided for @walletActive.
  ///
  /// In vi, this message translates to:
  /// **'Đang dùng'**
  String get walletActive;

  /// No description provided for @walletInactive.
  ///
  /// In vi, this message translates to:
  /// **'Đã ẩn'**
  String get walletInactive;

  /// No description provided for @walletCreateTitle.
  ///
  /// In vi, this message translates to:
  /// **'Tạo ví'**
  String get walletCreateTitle;

  /// No description provided for @walletEditTitle.
  ///
  /// In vi, this message translates to:
  /// **'Sửa ví'**
  String get walletEditTitle;

  /// No description provided for @walletName.
  ///
  /// In vi, this message translates to:
  /// **'Tên ví'**
  String get walletName;

  /// No description provided for @walletType.
  ///
  /// In vi, this message translates to:
  /// **'Loại ví'**
  String get walletType;

  /// No description provided for @walletInitialBalance.
  ///
  /// In vi, this message translates to:
  /// **'Số dư ban đầu'**
  String get walletInitialBalance;

  /// No description provided for @walletSetDefault.
  ///
  /// In vi, this message translates to:
  /// **'Đặt làm ví mặc định'**
  String get walletSetDefault;

  /// No description provided for @walletActivated.
  ///
  /// In vi, this message translates to:
  /// **'Đang kích hoạt'**
  String get walletActivated;

  /// No description provided for @walletSaving.
  ///
  /// In vi, this message translates to:
  /// **'Đang lưu...'**
  String get walletSaving;

  /// No description provided for @walletSave.
  ///
  /// In vi, this message translates to:
  /// **'Lưu ví'**
  String get walletSave;

  /// No description provided for @walletNameRequired.
  ///
  /// In vi, this message translates to:
  /// **'Tên ví không được trống.'**
  String get walletNameRequired;

  /// No description provided for @walletTypeCash.
  ///
  /// In vi, this message translates to:
  /// **'Tiền mặt'**
  String get walletTypeCash;

  /// No description provided for @walletTypeBank.
  ///
  /// In vi, this message translates to:
  /// **'Ngân hàng'**
  String get walletTypeBank;

  /// No description provided for @walletTypeEwallet.
  ///
  /// In vi, this message translates to:
  /// **'Ví điện tử'**
  String get walletTypeEwallet;

  /// No description provided for @walletTypeCredit.
  ///
  /// In vi, this message translates to:
  /// **'Thẻ tín dụng'**
  String get walletTypeCredit;

  /// No description provided for @walletTypeOther.
  ///
  /// In vi, this message translates to:
  /// **'Khác'**
  String get walletTypeOther;

  /// No description provided for @walletError.
  ///
  /// In vi, this message translates to:
  /// **'Lỗi ví: {error}'**
  String walletError(String error);

  /// No description provided for @walletNeedOneActive.
  ///
  /// In vi, this message translates to:
  /// **'Bạn cần ít nhất 1 ví đang hoạt động để tạo giao dịch.'**
  String get walletNeedOneActive;

  /// No description provided for @categoryTitle.
  ///
  /// In vi, this message translates to:
  /// **'Danh mục'**
  String get categoryTitle;

  /// No description provided for @categoryDescription.
  ///
  /// In vi, this message translates to:
  /// **'Quản lý danh mục thu/chi để chuẩn bị cho giao dịch.'**
  String get categoryDescription;

  /// No description provided for @categoryEmpty.
  ///
  /// In vi, this message translates to:
  /// **'Chưa có danh mục nào.'**
  String get categoryEmpty;

  /// No description provided for @categoryNoData.
  ///
  /// In vi, this message translates to:
  /// **'Chưa có dữ liệu.'**
  String get categoryNoData;

  /// No description provided for @categoryCreateTitle.
  ///
  /// In vi, this message translates to:
  /// **'Tạo danh mục'**
  String get categoryCreateTitle;

  /// No description provided for @categoryEditTitle.
  ///
  /// In vi, this message translates to:
  /// **'Sửa danh mục'**
  String get categoryEditTitle;

  /// No description provided for @categoryName.
  ///
  /// In vi, this message translates to:
  /// **'Tên danh mục'**
  String get categoryName;

  /// No description provided for @categoryType.
  ///
  /// In vi, this message translates to:
  /// **'Loại danh mục'**
  String get categoryType;

  /// No description provided for @categoryActivated.
  ///
  /// In vi, this message translates to:
  /// **'Đang kích hoạt'**
  String get categoryActivated;

  /// No description provided for @categorySaving.
  ///
  /// In vi, this message translates to:
  /// **'Đang lưu...'**
  String get categorySaving;

  /// No description provided for @categorySave.
  ///
  /// In vi, this message translates to:
  /// **'Lưu danh mục'**
  String get categorySave;

  /// No description provided for @categoryNameRequired.
  ///
  /// In vi, this message translates to:
  /// **'Tên danh mục không được trống.'**
  String get categoryNameRequired;

  /// No description provided for @categoryError.
  ///
  /// In vi, this message translates to:
  /// **'Category error: {error}'**
  String categoryError(String error);

  /// No description provided for @categoryExpense.
  ///
  /// In vi, this message translates to:
  /// **'Chi'**
  String get categoryExpense;

  /// No description provided for @categoryIncome.
  ///
  /// In vi, this message translates to:
  /// **'Thu'**
  String get categoryIncome;

  /// No description provided for @categoryNeedOneActive.
  ///
  /// In vi, this message translates to:
  /// **'Bạn cần ít nhất 1 danh mục đang hoạt động cho loại giao dịch này.'**
  String get categoryNeedOneActive;

  /// No description provided for @scanTitle.
  ///
  /// In vi, this message translates to:
  /// **'Quét hóa đơn'**
  String get scanTitle;

  /// No description provided for @scanTakePhoto.
  ///
  /// In vi, this message translates to:
  /// **'Chụp ảnh'**
  String get scanTakePhoto;

  /// No description provided for @scanChooseGallery.
  ///
  /// In vi, this message translates to:
  /// **'Chọn từ thư viện'**
  String get scanChooseGallery;

  /// No description provided for @scanExtracting.
  ///
  /// In vi, this message translates to:
  /// **'Đang trích xuất dữ liệu...'**
  String get scanExtracting;

  /// No description provided for @scanFailed.
  ///
  /// In vi, this message translates to:
  /// **'Không thể đọc hóa đơn. Vui lòng thử lại.'**
  String get scanFailed;

  /// No description provided for @scanReviewTitle.
  ///
  /// In vi, this message translates to:
  /// **'Kiểm tra hóa đơn'**
  String get scanReviewTitle;

  /// No description provided for @scanMerchant.
  ///
  /// In vi, this message translates to:
  /// **'Cửa hàng'**
  String get scanMerchant;

  /// No description provided for @scanOcrConfidence.
  ///
  /// In vi, this message translates to:
  /// **'Độ tin cậy OCR: {percent}%. Hãy kiểm tra thông tin trước khi lưu.'**
  String scanOcrConfidence(int percent);

  /// No description provided for @scanItemsTitle.
  ///
  /// In vi, this message translates to:
  /// **'Mục nhận diện'**
  String get scanItemsTitle;

  /// No description provided for @scanQuantity.
  ///
  /// In vi, this message translates to:
  /// **'Số lượng: {quantity}'**
  String scanQuantity(int quantity);

  /// No description provided for @scanSuccessMessage.
  ///
  /// In vi, this message translates to:
  /// **'Đã đọc hóa đơn. Bạn có thể kiểm tra và chỉnh sửa thông tin.'**
  String get scanSuccessMessage;

  /// No description provided for @scanScanning.
  ///
  /// In vi, this message translates to:
  /// **'Đang quét...'**
  String get scanScanning;

  /// No description provided for @scanExtractButton.
  ///
  /// In vi, this message translates to:
  /// **'Trích xuất dữ liệu'**
  String get scanExtractButton;

  /// No description provided for @scanManualEntry.
  ///
  /// In vi, this message translates to:
  /// **'Nhập giao dịch thủ công'**
  String get scanManualEntry;

  /// No description provided for @scanNoReceipt.
  ///
  /// In vi, this message translates to:
  /// **'Chưa có ảnh hóa đơn'**
  String get scanNoReceipt;

  /// No description provided for @scanNoReceiptSubtitle.
  ///
  /// In vi, this message translates to:
  /// **'Chụp ảnh hoặc chọn ảnh từ thư viện để bắt đầu.'**
  String get scanNoReceiptSubtitle;

  /// No description provided for @scanImageError.
  ///
  /// In vi, this message translates to:
  /// **'Không thể hiển thị ảnh đã chọn.'**
  String get scanImageError;

  /// No description provided for @groupTitle.
  ///
  /// In vi, this message translates to:
  /// **'Nhóm chi tiêu'**
  String get groupTitle;

  /// No description provided for @groupEmpty.
  ///
  /// In vi, this message translates to:
  /// **'Chưa có nhóm chi tiêu'**
  String get groupEmpty;

  /// No description provided for @groupEmptySubtitle.
  ///
  /// In vi, this message translates to:
  /// **'Tạo nhóm để cùng theo dõi hóa đơn và chia tiền.'**
  String get groupEmptySubtitle;

  /// No description provided for @groupCreate.
  ///
  /// In vi, this message translates to:
  /// **'Tạo nhóm'**
  String get groupCreate;

  /// No description provided for @groupCreateDialog.
  ///
  /// In vi, this message translates to:
  /// **'Tạo nhóm mới'**
  String get groupCreateDialog;

  /// No description provided for @groupNameLabel.
  ///
  /// In vi, this message translates to:
  /// **'Tên nhóm'**
  String get groupNameLabel;

  /// No description provided for @groupNeedLogin.
  ///
  /// In vi, this message translates to:
  /// **'Bạn cần đăng nhập để tạo nhóm.'**
  String get groupNeedLogin;

  /// No description provided for @groupMemberCount.
  ///
  /// In vi, this message translates to:
  /// **'{count} thành viên'**
  String groupMemberCount(int count);

  /// No description provided for @groupLoadError.
  ///
  /// In vi, this message translates to:
  /// **'Không tải được danh sách nhóm.'**
  String get groupLoadError;

  /// No description provided for @groupAddMember.
  ///
  /// In vi, this message translates to:
  /// **'Thêm thành viên'**
  String get groupAddMember;

  /// No description provided for @groupMemberName.
  ///
  /// In vi, this message translates to:
  /// **'Tên thành viên'**
  String get groupMemberName;

  /// No description provided for @groupExpenses.
  ///
  /// In vi, this message translates to:
  /// **'Chi phí nhóm'**
  String get groupExpenses;

  /// No description provided for @groupAddExpense.
  ///
  /// In vi, this message translates to:
  /// **'Thêm chi phí'**
  String get groupAddExpense;

  /// No description provided for @groupNoExpenses.
  ///
  /// In vi, this message translates to:
  /// **'Chưa có chi phí nào.'**
  String get groupNoExpenses;

  /// No description provided for @groupNoMembers.
  ///
  /// In vi, this message translates to:
  /// **'Nhóm chưa có thành viên nào ngoài bạn.'**
  String get groupNoMembers;

  /// No description provided for @groupDebtSummary.
  ///
  /// In vi, this message translates to:
  /// **'Tổng hợp nợ'**
  String get groupDebtSummary;

  /// No description provided for @groupRemoveMemberConfirm.
  ///
  /// In vi, this message translates to:
  /// **'Xóa thành viên này?'**
  String get groupRemoveMemberConfirm;

  /// No description provided for @groupDetailTitle.
  ///
  /// In vi, this message translates to:
  /// **'Chi tiêu nhóm'**
  String get groupDetailTitle;

  /// No description provided for @groupLoadSingleError.
  ///
  /// In vi, this message translates to:
  /// **'Không tải được nhóm.'**
  String get groupLoadSingleError;

  /// No description provided for @groupNotExists.
  ///
  /// In vi, this message translates to:
  /// **'Nhóm không còn tồn tại.'**
  String get groupNotExists;

  /// No description provided for @groupMembersHeader.
  ///
  /// In vi, this message translates to:
  /// **'Thành viên'**
  String get groupMembersHeader;

  /// No description provided for @groupExpenseHistory.
  ///
  /// In vi, this message translates to:
  /// **'Lịch sử chi tiêu'**
  String get groupExpenseHistory;

  /// No description provided for @groupLoadExpensesError.
  ///
  /// In vi, this message translates to:
  /// **'Không tải được chi phí nhóm.'**
  String get groupLoadExpensesError;

  /// No description provided for @groupDeletedMember.
  ///
  /// In vi, this message translates to:
  /// **'Thành viên đã xóa'**
  String get groupDeletedMember;

  /// No description provided for @groupMemberEmailHint.
  ///
  /// In vi, this message translates to:
  /// **'Email (không bắt buộc)'**
  String get groupMemberEmailHint;

  /// No description provided for @groupDeleteExpenseConfirmTitle.
  ///
  /// In vi, this message translates to:
  /// **'Xóa chi phí?'**
  String get groupDeleteExpenseConfirmTitle;

  /// No description provided for @groupDeleteExpenseConfirmMessage.
  ///
  /// In vi, this message translates to:
  /// **'Thao tác này sẽ cập nhật lại công nợ của nhóm.'**
  String get groupDeleteExpenseConfirmMessage;

  /// No description provided for @groupPayerSubtitle.
  ///
  /// In vi, this message translates to:
  /// **'{payer} đã trả • {date}'**
  String groupPayerSubtitle(String payer, String date);

  /// No description provided for @groupEmptyExpensesMessage.
  ///
  /// In vi, this message translates to:
  /// **'Chưa có chi phí. Thêm hóa đơn đầu tiên để bắt đầu tính nợ.'**
  String get groupEmptyExpensesMessage;

  /// No description provided for @debtSummaryTitle.
  ///
  /// In vi, this message translates to:
  /// **'Tổng hợp nợ'**
  String get debtSummaryTitle;

  /// No description provided for @debtNoData.
  ///
  /// In vi, this message translates to:
  /// **'Chưa có dữ liệu chi phí.'**
  String get debtNoData;

  /// No description provided for @debtSettlementTitle.
  ///
  /// In vi, this message translates to:
  /// **'Gợi ý thanh toán'**
  String get debtSettlementTitle;

  /// No description provided for @debtNoSettlement.
  ///
  /// In vi, this message translates to:
  /// **'Không có khoản nợ nào cần thanh toán.'**
  String get debtNoSettlement;

  /// No description provided for @debtOwes.
  ///
  /// In vi, this message translates to:
  /// **'{from} trả {to} {amount}'**
  String debtOwes(String from, String to, String amount);

  /// No description provided for @debtSummaryAppBarTitle.
  ///
  /// In vi, this message translates to:
  /// **'Tổng kết công nợ'**
  String get debtSummaryAppBarTitle;

  /// No description provided for @debtLoadError.
  ///
  /// In vi, this message translates to:
  /// **'Không tính được công nợ.'**
  String get debtLoadError;

  /// No description provided for @debtExplanation.
  ///
  /// In vi, this message translates to:
  /// **'Số dương là số tiền cần nhận, số âm là số tiền cần trả.'**
  String get debtExplanation;

  /// No description provided for @debtOwesPayerToPayee.
  ///
  /// In vi, this message translates to:
  /// **'{from} trả {to}'**
  String debtOwesPayerToPayee(String from, String to);

  /// No description provided for @debtMember.
  ///
  /// In vi, this message translates to:
  /// **'Thành viên'**
  String get debtMember;

  /// No description provided for @debtToReceive.
  ///
  /// In vi, this message translates to:
  /// **'Sẽ nhận'**
  String get debtToReceive;

  /// No description provided for @debtToPay.
  ///
  /// In vi, this message translates to:
  /// **'Cần trả'**
  String get debtToPay;

  /// No description provided for @expenseFormTitle.
  ///
  /// In vi, this message translates to:
  /// **'Thêm chi phí nhóm'**
  String get expenseFormTitle;

  /// No description provided for @expenseFormEditTitle.
  ///
  /// In vi, this message translates to:
  /// **'Sửa chi phí'**
  String get expenseFormEditTitle;

  /// No description provided for @expenseAmount.
  ///
  /// In vi, this message translates to:
  /// **'Số tiền'**
  String get expenseAmount;

  /// No description provided for @expenseNote.
  ///
  /// In vi, this message translates to:
  /// **'Ghi chú'**
  String get expenseNote;

  /// No description provided for @expenseDate.
  ///
  /// In vi, this message translates to:
  /// **'Ngày'**
  String get expenseDate;

  /// No description provided for @expensePayer.
  ///
  /// In vi, this message translates to:
  /// **'Người trả'**
  String get expensePayer;

  /// No description provided for @expenseParticipants.
  ///
  /// In vi, this message translates to:
  /// **'Người tham gia'**
  String get expenseParticipants;

  /// No description provided for @expenseSplitEqual.
  ///
  /// In vi, this message translates to:
  /// **'Chia đều'**
  String get expenseSplitEqual;

  /// No description provided for @expenseSplitManual.
  ///
  /// In vi, this message translates to:
  /// **'Tự nhập số tiền'**
  String get expenseSplitManual;

  /// No description provided for @expenseSplitPercentage.
  ///
  /// In vi, this message translates to:
  /// **'Theo phần trăm'**
  String get expenseSplitPercentage;

  /// No description provided for @expenseSave.
  ///
  /// In vi, this message translates to:
  /// **'Lưu chi phí'**
  String get expenseSave;

  /// No description provided for @expenseFormMinMembersNotice.
  ///
  /// In vi, this message translates to:
  /// **'Hãy thêm ít nhất 2 thành viên trước khi chia chi phí.'**
  String get expenseFormMinMembersNotice;

  /// No description provided for @expenseFormTotalCost.
  ///
  /// In vi, this message translates to:
  /// **'Tổng chi phí'**
  String get expenseFormTotalCost;

  /// No description provided for @expenseFormContentLabel.
  ///
  /// In vi, this message translates to:
  /// **'Nội dung'**
  String get expenseFormContentLabel;

  /// No description provided for @expenseFormPayer.
  ///
  /// In vi, this message translates to:
  /// **'Người thanh toán'**
  String get expenseFormPayer;

  /// No description provided for @expenseFormDate.
  ///
  /// In vi, this message translates to:
  /// **'Ngày chi'**
  String get expenseFormDate;

  /// No description provided for @validationAmountPositive.
  ///
  /// In vi, this message translates to:
  /// **'Số tiền phải lớn hơn 0.'**
  String get validationAmountPositive;

  /// No description provided for @validationMinMembers.
  ///
  /// In vi, this message translates to:
  /// **'Nhóm phải có ít nhất {min} thành viên.'**
  String validationMinMembers(int min);

  /// No description provided for @validationSelectPayer.
  ///
  /// In vi, this message translates to:
  /// **'Chọn người trả tiền.'**
  String get validationSelectPayer;

  /// No description provided for @validationSelectParticipant.
  ///
  /// In vi, this message translates to:
  /// **'Chọn ít nhất một người tham gia.'**
  String get validationSelectParticipant;

  /// No description provided for @validationSplitMismatch.
  ///
  /// In vi, this message translates to:
  /// **'Tổng chia ({splitTotal}) phải bằng tổng chi phí ({total}).'**
  String validationSplitMismatch(String splitTotal, String total);

  /// No description provided for @validationNegativeSplit.
  ///
  /// In vi, this message translates to:
  /// **'Phần chia không được âm.'**
  String get validationNegativeSplit;

  /// No description provided for @validationInvalidParticipants.
  ///
  /// In vi, this message translates to:
  /// **'Danh sách người tham gia không hợp lệ.'**
  String get validationInvalidParticipants;

  /// No description provided for @validationSplitCountMismatch.
  ///
  /// In vi, this message translates to:
  /// **'Mỗi người tham gia cần đúng một phần chia.'**
  String get validationSplitCountMismatch;

  /// No description provided for @profileTitle.
  ///
  /// In vi, this message translates to:
  /// **'Hồ sơ'**
  String get profileTitle;

  /// No description provided for @profileUserDefault.
  ///
  /// In vi, this message translates to:
  /// **'Người dùng Moniary'**
  String get profileUserDefault;

  /// No description provided for @profileAnonymous.
  ///
  /// In vi, this message translates to:
  /// **'Tài khoản dùng thử ẩn danh'**
  String get profileAnonymous;

  /// No description provided for @profileMyData.
  ///
  /// In vi, this message translates to:
  /// **'Dữ liệu của tôi'**
  String get profileMyData;

  /// No description provided for @profileExportData.
  ///
  /// In vi, this message translates to:
  /// **'Xuất dữ liệu'**
  String get profileExportData;

  /// No description provided for @profileExportSubtitle.
  ///
  /// In vi, this message translates to:
  /// **'CSV, XLSX, PDF'**
  String get profileExportSubtitle;

  /// No description provided for @profileImportData.
  ///
  /// In vi, this message translates to:
  /// **'Nhập dữ liệu'**
  String get profileImportData;

  /// No description provided for @profileImportSubtitle.
  ///
  /// In vi, this message translates to:
  /// **'Nhập từ file CSV'**
  String get profileImportSubtitle;

  /// No description provided for @profilePrivacyCenter.
  ///
  /// In vi, this message translates to:
  /// **'Bảo mật & Quyền riêng tư'**
  String get profilePrivacyCenter;

  /// No description provided for @profilePrivacySubtitle.
  ///
  /// In vi, this message translates to:
  /// **'Quản lý privacy policy, dữ liệu và quyền truy cập.'**
  String get profilePrivacySubtitle;

  /// No description provided for @profileAccount.
  ///
  /// In vi, this message translates to:
  /// **'Tài khoản'**
  String get profileAccount;

  /// No description provided for @profileSignOut.
  ///
  /// In vi, this message translates to:
  /// **'Đăng xuất'**
  String get profileSignOut;

  /// No description provided for @profileSignOutSubtitle.
  ///
  /// In vi, this message translates to:
  /// **'Thoát khỏi tài khoản hiện tại trên thiết bị này.'**
  String get profileSignOutSubtitle;

  /// No description provided for @profileDeleteAccount.
  ///
  /// In vi, this message translates to:
  /// **'Xóa tài khoản'**
  String get profileDeleteAccount;

  /// No description provided for @profileDeleteSubtitle.
  ///
  /// In vi, this message translates to:
  /// **'Xóa dữ liệu cá nhân, giao dịch và ảnh đã lưu.'**
  String get profileDeleteSubtitle;

  /// No description provided for @privacyClearDataSubtitle.
  ///
  /// In vi, this message translates to:
  /// **'Xóa toàn bộ dữ liệu ứng dụng'**
  String get privacyClearDataSubtitle;

  /// No description provided for @notificationSettings.
  ///
  /// In vi, this message translates to:
  /// **'Cài đặt thông báo'**
  String get notificationSettings;

  /// No description provided for @emailReports.
  ///
  /// In vi, this message translates to:
  /// **'Báo cáo Email Tự động'**
  String get emailReports;

  /// No description provided for @emailReportsDesc.
  ///
  /// In vi, this message translates to:
  /// **'Nhận tổng hợp thu chi định kỳ qua email.'**
  String get emailReportsDesc;

  /// No description provided for @dailyReport.
  ///
  /// In vi, this message translates to:
  /// **'Báo cáo hàng ngày'**
  String get dailyReport;

  /// No description provided for @weeklyReport.
  ///
  /// In vi, this message translates to:
  /// **'Báo cáo hàng tuần'**
  String get weeklyReport;

  /// No description provided for @monthlyReport.
  ///
  /// In vi, this message translates to:
  /// **'Báo cáo hàng tháng'**
  String get monthlyReport;

  /// No description provided for @yearlyReport.
  ///
  /// In vi, this message translates to:
  /// **'Báo cáo hàng năm'**
  String get yearlyReport;

  /// No description provided for @deleteAccountTitle.
  ///
  /// In vi, this message translates to:
  /// **'Xóa tài khoản'**
  String get deleteAccountTitle;

  /// No description provided for @deleteAccountWarning.
  ///
  /// In vi, this message translates to:
  /// **'Hành động này sẽ xóa toàn bộ dữ liệu cá nhân, giao dịch và ảnh giao dịch của bạn.'**
  String get deleteAccountWarning;

  /// No description provided for @deleteAccountConfirm.
  ///
  /// In vi, this message translates to:
  /// **'Xóa tài khoản'**
  String get deleteAccountConfirm;

  /// No description provided for @deleteAccountTitleQuestion.
  ///
  /// In vi, this message translates to:
  /// **'Xóa tài khoản?'**
  String get deleteAccountTitleQuestion;

  /// No description provided for @deleteAccountUndone.
  ///
  /// In vi, this message translates to:
  /// **'Thao tác này không thể hoàn tác trong app.'**
  String get deleteAccountUndone;

  /// No description provided for @deleteAccountConsequence1.
  ///
  /// In vi, this message translates to:
  /// **'Xóa hồ sơ và phiên đăng nhập hiện tại.'**
  String get deleteAccountConsequence1;

  /// No description provided for @deleteAccountConsequence2.
  ///
  /// In vi, this message translates to:
  /// **'Xóa ví, danh mục và toàn bộ giao dịch.'**
  String get deleteAccountConsequence2;

  /// No description provided for @deleteAccountConsequence3.
  ///
  /// In vi, this message translates to:
  /// **'Xóa ảnh giao dịch trong Storage theo user ID.'**
  String get deleteAccountConsequence3;

  /// No description provided for @deleteAccountUnderstand.
  ///
  /// In vi, this message translates to:
  /// **'Tôi hiểu dữ liệu sẽ bị xóa khỏi tài khoản này.'**
  String get deleteAccountUnderstand;

  /// No description provided for @deleteAccountConfirmationText.
  ///
  /// In vi, this message translates to:
  /// **'XOA TAI KHOAN'**
  String get deleteAccountConfirmationText;

  /// No description provided for @deleteAccountConfirmInput.
  ///
  /// In vi, this message translates to:
  /// **'Nhập {text} để xác nhận'**
  String deleteAccountConfirmInput(String text);

  /// No description provided for @exportTitle.
  ///
  /// In vi, this message translates to:
  /// **'Xuất dữ liệu'**
  String get exportTitle;

  /// No description provided for @exportFormat.
  ///
  /// In vi, this message translates to:
  /// **'Định dạng file'**
  String get exportFormat;

  /// No description provided for @exportDateRange.
  ///
  /// In vi, this message translates to:
  /// **'Khoảng ngày'**
  String get exportDateRange;

  /// No description provided for @exportAllTime.
  ///
  /// In vi, this message translates to:
  /// **'Tất cả thời gian'**
  String get exportAllTime;

  /// No description provided for @exportDataTypes.
  ///
  /// In vi, this message translates to:
  /// **'Loại dữ liệu'**
  String get exportDataTypes;

  /// No description provided for @exportButton.
  ///
  /// In vi, this message translates to:
  /// **'Xuất dữ liệu'**
  String get exportButton;

  /// No description provided for @exportDone.
  ///
  /// In vi, this message translates to:
  /// **'Đã xuất dữ liệu'**
  String get exportDone;

  /// No description provided for @exportHistoryTitle.
  ///
  /// In vi, this message translates to:
  /// **'Lịch sử xuất dữ liệu'**
  String get exportHistoryTitle;

  /// No description provided for @exportHistoryEmpty.
  ///
  /// In vi, this message translates to:
  /// **'Chưa có file export nào.'**
  String get exportHistoryEmpty;

  /// No description provided for @manageDataTitle.
  ///
  /// In vi, this message translates to:
  /// **'Quản lý dữ liệu'**
  String get manageDataTitle;

  /// No description provided for @cameraTakePhoto.
  ///
  /// In vi, this message translates to:
  /// **'Chụp'**
  String get cameraTakePhoto;

  /// No description provided for @cameraFlip.
  ///
  /// In vi, this message translates to:
  /// **'Lật camera'**
  String get cameraFlip;

  /// No description provided for @cameraNoPermission.
  ///
  /// In vi, this message translates to:
  /// **'Cần quyền truy cập camera.'**
  String get cameraNoPermission;

  /// No description provided for @routeNotFound.
  ///
  /// In vi, this message translates to:
  /// **'Trang không tồn tại'**
  String get routeNotFound;

  /// No description provided for @routeGoBack.
  ///
  /// In vi, this message translates to:
  /// **'Quay lại'**
  String get routeGoBack;

  /// No description provided for @statsDevelopingMessage.
  ///
  /// In vi, this message translates to:
  /// **'Tính năng Thống kê đang được phát triển.'**
  String get statsDevelopingMessage;

  /// No description provided for @transactionIsImportant.
  ///
  /// In vi, this message translates to:
  /// **'Giao dịch quan trọng'**
  String get transactionIsImportant;

  /// No description provided for @statsTitle.
  ///
  /// In vi, this message translates to:
  /// **'Thống kê chi tiêu'**
  String get statsTitle;

  /// No description provided for @statsTotalIncome.
  ///
  /// In vi, this message translates to:
  /// **'Tổng thu'**
  String get statsTotalIncome;

  /// No description provided for @statsTotalExpense.
  ///
  /// In vi, this message translates to:
  /// **'Tổng chi'**
  String get statsTotalExpense;

  /// No description provided for @statsNetBalance.
  ///
  /// In vi, this message translates to:
  /// **'Số dư ròng'**
  String get statsNetBalance;

  /// No description provided for @statsExpenseButton.
  ///
  /// In vi, this message translates to:
  /// **'Tổng Chi'**
  String get statsExpenseButton;

  /// No description provided for @statsIncomeButton.
  ///
  /// In vi, this message translates to:
  /// **'Tổng Thu'**
  String get statsIncomeButton;

  /// No description provided for @statsEmptyTitle.
  ///
  /// In vi, this message translates to:
  /// **'Chưa có giao dịch nào loại này'**
  String get statsEmptyTitle;

  /// No description provided for @statsEmptySubtitle.
  ///
  /// In vi, this message translates to:
  /// **'Các biểu đồ thống kê sẽ hiện ra sau khi bạn thêm giao dịch.'**
  String get statsEmptySubtitle;

  /// No description provided for @statsCategoryAllocation.
  ///
  /// In vi, this message translates to:
  /// **'Phân bổ danh mục'**
  String get statsCategoryAllocation;

  /// No description provided for @statsDailyTrend.
  ///
  /// In vi, this message translates to:
  /// **'Xu hướng hàng ngày'**
  String get statsDailyTrend;

  /// No description provided for @statsLargestTransactions.
  ///
  /// In vi, this message translates to:
  /// **'Giao dịch lớn nhất'**
  String get statsLargestTransactions;

  /// No description provided for @profileProtectAccount.
  ///
  /// In vi, this message translates to:
  /// **'Bảo vệ tài khoản của bạn'**
  String get profileProtectAccount;

  /// No description provided for @profileAnonymousWarning.
  ///
  /// In vi, this message translates to:
  /// **'Bạn đang đăng nhập bằng tài khoản khách. Hãy liên kết tài khoản để tránh mất mát dữ liệu khi đổi thiết bị.'**
  String get profileAnonymousWarning;

  /// No description provided for @profileLinkNow.
  ///
  /// In vi, this message translates to:
  /// **'Liên kết ngay'**
  String get profileLinkNow;

  /// No description provided for @profileLinkAccountTitle.
  ///
  /// In vi, this message translates to:
  /// **'Liên kết tài khoản'**
  String get profileLinkAccountTitle;

  /// No description provided for @profileLinkAccountSubtitle.
  ///
  /// In vi, this message translates to:
  /// **'Tài khoản của bạn hiện là ẩn danh. Liên kết với Email hoặc Google để lưu trữ dữ liệu vĩnh viễn và đăng nhập trên nhiều thiết bị.'**
  String get profileLinkAccountSubtitle;

  /// No description provided for @profileNewPassword.
  ///
  /// In vi, this message translates to:
  /// **'Mật khẩu mới'**
  String get profileNewPassword;

  /// No description provided for @profileLinkEmail.
  ///
  /// In vi, this message translates to:
  /// **'Liên kết Email'**
  String get profileLinkEmail;

  /// No description provided for @profileLinkGoogle.
  ///
  /// In vi, this message translates to:
  /// **'Liên kết Google'**
  String get profileLinkGoogle;

  /// No description provided for @profileLinkSuccess.
  ///
  /// In vi, this message translates to:
  /// **'Liên kết tài khoản email thành công!'**
  String get profileLinkSuccess;

  /// No description provided for @profileLinkGoogleBrowser.
  ///
  /// In vi, this message translates to:
  /// **'Hoàn tất liên kết Google trong trình duyệt để quay lại Moniary.'**
  String get profileLinkGoogleBrowser;

  /// No description provided for @profileLinkGoogleError.
  ///
  /// In vi, this message translates to:
  /// **'Lỗi liên kết Google: {error}'**
  String profileLinkGoogleError(String error);

  /// No description provided for @profileEditInfo.
  ///
  /// In vi, this message translates to:
  /// **'Chỉnh sửa thông tin'**
  String get profileEditInfo;

  /// No description provided for @profileChangeTimezone.
  ///
  /// In vi, this message translates to:
  /// **'Thay đổi múi giờ'**
  String get profileChangeTimezone;

  /// No description provided for @profileAnonymousBadge.
  ///
  /// In vi, this message translates to:
  /// **'Tài khoản Ẩn danh'**
  String get profileAnonymousBadge;

  /// No description provided for @profileVerifiedBadge.
  ///
  /// In vi, this message translates to:
  /// **'Đã Xác thực ({provider})'**
  String profileVerifiedBadge(String provider);

  /// No description provided for @profileSignOutDialogTitle.
  ///
  /// In vi, this message translates to:
  /// **'Đăng xuất'**
  String get profileSignOutDialogTitle;

  /// No description provided for @profileSignOutDialogMessage.
  ///
  /// In vi, this message translates to:
  /// **'Bạn có chắc chắn muốn đăng xuất không?'**
  String get profileSignOutDialogMessage;

  /// No description provided for @profileCancel.
  ///
  /// In vi, this message translates to:
  /// **'Hủy'**
  String get profileCancel;

  /// No description provided for @exportSupportTitle.
  ///
  /// In vi, this message translates to:
  /// **'Hỗ trợ export dữ liệu'**
  String get exportSupportTitle;

  /// No description provided for @exportOpenData.
  ///
  /// In vi, this message translates to:
  /// **'Mở export dữ liệu'**
  String get exportOpenData;

  /// No description provided for @exportOpenHistory.
  ///
  /// In vi, this message translates to:
  /// **'Mở lịch sử export'**
  String get exportOpenHistory;

  /// No description provided for @exportCreateSupportRequest.
  ///
  /// In vi, this message translates to:
  /// **'Tạo yêu cầu hỗ trợ'**
  String get exportCreateSupportRequest;

  /// No description provided for @legalDataDeletionPolicy.
  ///
  /// In vi, this message translates to:
  /// **'Chính sách xóa dữ liệu'**
  String get legalDataDeletionPolicy;

  /// No description provided for @legalDataRetention.
  ///
  /// In vi, this message translates to:
  /// **'Lưu giữ dữ liệu'**
  String get legalDataRetention;

  /// No description provided for @legalFinancialDisclaimer.
  ///
  /// In vi, this message translates to:
  /// **'Miễn trừ tài chính'**
  String get legalFinancialDisclaimer;

  /// No description provided for @legalContact.
  ///
  /// In vi, this message translates to:
  /// **'Liên hệ pháp lý'**
  String get legalContact;

  /// No description provided for @legalCopyAllContacts.
  ///
  /// In vi, this message translates to:
  /// **'Copy tất cả liên hệ'**
  String get legalCopyAllContacts;

  /// No description provided for @legalCopyContactSuccess.
  ///
  /// In vi, this message translates to:
  /// **'Đã copy thông tin liên hệ.'**
  String get legalCopyContactSuccess;

  /// No description provided for @legalPolicyAcceptance.
  ///
  /// In vi, this message translates to:
  /// **'Đồng ý chính sách'**
  String get legalPolicyAcceptance;

  /// No description provided for @legalViewPrivacyPolicy.
  ///
  /// In vi, this message translates to:
  /// **'Xem chính sách bảo mật'**
  String get legalViewPrivacyPolicy;

  /// No description provided for @legalViewTermsOfUse.
  ///
  /// In vi, this message translates to:
  /// **'Xem điều khoản sử dụng'**
  String get legalViewTermsOfUse;

  /// No description provided for @legalPolicyChangelog.
  ///
  /// In vi, this message translates to:
  /// **'Lịch sử chính sách'**
  String get legalPolicyChangelog;

  /// No description provided for @legalTermsOfUse.
  ///
  /// In vi, this message translates to:
  /// **'Điều khoản sử dụng'**
  String get legalTermsOfUse;

  /// No description provided for @legalThirdPartyServices.
  ///
  /// In vi, this message translates to:
  /// **'Dịch vụ bên thứ ba'**
  String get legalThirdPartyServices;

  /// No description provided for @legalUserRights.
  ///
  /// In vi, this message translates to:
  /// **'Quyền dữ liệu'**
  String get legalUserRights;

  /// No description provided for @privacyDataSafety.
  ///
  /// In vi, this message translates to:
  /// **'Data Safety'**
  String get privacyDataSafety;

  /// No description provided for @privacyMyData.
  ///
  /// In vi, this message translates to:
  /// **'Dữ liệu của tôi'**
  String get privacyMyData;

  /// No description provided for @privacyPhotoData.
  ///
  /// In vi, this message translates to:
  /// **'Dữ liệu ảnh'**
  String get privacyPhotoData;

  /// No description provided for @privacyDataFreshness.
  ///
  /// In vi, this message translates to:
  /// **'Độ mới dữ liệu'**
  String get privacyDataFreshness;

  /// No description provided for @privacyLocalFiles.
  ///
  /// In vi, this message translates to:
  /// **'File cục bộ'**
  String get privacyLocalFiles;

  /// No description provided for @privacyTransactionPhotos.
  ///
  /// In vi, this message translates to:
  /// **'Ảnh giao dịch'**
  String get privacyTransactionPhotos;

  /// No description provided for @privacyViewExportHistory.
  ///
  /// In vi, this message translates to:
  /// **'Xem lịch sử export'**
  String get privacyViewExportHistory;

  /// No description provided for @privacyPermissionRationale.
  ///
  /// In vi, this message translates to:
  /// **'Quyền truy cập'**
  String get privacyPermissionRationale;

  /// No description provided for @privacyFaq.
  ///
  /// In vi, this message translates to:
  /// **'FAQ privacy & tài khoản'**
  String get privacyFaq;

  /// No description provided for @privacyCenter.
  ///
  /// In vi, this message translates to:
  /// **'Trung tâm riêng tư'**
  String get privacyCenter;

  /// No description provided for @privacyContact.
  ///
  /// In vi, this message translates to:
  /// **'Liên hệ quyền riêng tư'**
  String get privacyContact;

  /// No description provided for @privacyUseTemplate.
  ///
  /// In vi, this message translates to:
  /// **'Dùng mẫu nội dung'**
  String get privacyUseTemplate;

  /// No description provided for @privacyCreateRequest.
  ///
  /// In vi, this message translates to:
  /// **'Tạo yêu cầu privacy'**
  String get privacyCreateRequest;

  /// No description provided for @privacyRequestCreated.
  ///
  /// In vi, this message translates to:
  /// **'Đã tạo yêu cầu'**
  String get privacyRequestCreated;

  /// No description provided for @privacyCopyEmail.
  ///
  /// In vi, this message translates to:
  /// **'Copy email'**
  String get privacyCopyEmail;

  /// No description provided for @privacyCopyInstructions.
  ///
  /// In vi, this message translates to:
  /// **'Copy hướng dẫn'**
  String get privacyCopyInstructions;

  /// No description provided for @privacyPolicyTitle.
  ///
  /// In vi, this message translates to:
  /// **'Chính sách bảo mật'**
  String get privacyPolicyTitle;

  /// No description provided for @privacyRequestDetailTitle.
  ///
  /// In vi, this message translates to:
  /// **'Chi tiết yêu cầu'**
  String get privacyRequestDetailTitle;

  /// No description provided for @privacyCopyFilePath.
  ///
  /// In vi, this message translates to:
  /// **'Copy file path'**
  String get privacyCopyFilePath;

  /// No description provided for @privacyCopyRequest.
  ///
  /// In vi, this message translates to:
  /// **'Copy request'**
  String get privacyCopyRequest;

  /// No description provided for @storeAboutMoniary.
  ///
  /// In vi, this message translates to:
  /// **'Giới thiệu Moniary'**
  String get storeAboutMoniary;

  /// No description provided for @storeComplianceChecklist.
  ///
  /// In vi, this message translates to:
  /// **'Checklist phát hành'**
  String get storeComplianceChecklist;

  /// No description provided for @storeTrustSafety.
  ///
  /// In vi, this message translates to:
  /// **'Tin cậy & an toàn'**
  String get storeTrustSafety;

  /// No description provided for @supportHelpCenter.
  ///
  /// In vi, this message translates to:
  /// **'Trung tâm trợ giúp'**
  String get supportHelpCenter;

  /// No description provided for @supportCopySuccess.
  ///
  /// In vi, this message translates to:
  /// **'Đã copy thông tin support.'**
  String get supportCopySuccess;

  /// No description provided for @supportCopyDiagnostic.
  ///
  /// In vi, this message translates to:
  /// **'Copy diagnostic info'**
  String get supportCopyDiagnostic;

  /// No description provided for @supportRequestChecklist.
  ///
  /// In vi, this message translates to:
  /// **'Checklist gửi hỗ trợ'**
  String get supportRequestChecklist;

  /// No description provided for @supportOpenHelpCenter.
  ///
  /// In vi, this message translates to:
  /// **'Mở trung tâm trợ giúp'**
  String get supportOpenHelpCenter;

  /// No description provided for @transactionOcrSuccess.
  ///
  /// In vi, this message translates to:
  /// **'Tự động trích xuất dữ liệu thành công!'**
  String get transactionOcrSuccess;

  /// No description provided for @scanImageSelectError.
  ///
  /// In vi, this message translates to:
  /// **'Không thể chọn ảnh. Vui lòng thử lại.'**
  String get scanImageSelectError;

  /// No description provided for @scanImageRequiredError.
  ///
  /// In vi, this message translates to:
  /// **'Vui lòng chọn ảnh hóa đơn trước.'**
  String get scanImageRequiredError;

  /// No description provided for @scanReadError.
  ///
  /// In vi, this message translates to:
  /// **'Không thể đọc hóa đơn. Vui lòng thử lại.'**
  String get scanReadError;

  /// No description provided for @commonFeatureUnderDevelopment.
  ///
  /// In vi, this message translates to:
  /// **'Tính năng đang được phát triển'**
  String get commonFeatureUnderDevelopment;

  /// No description provided for @appLockTitle.
  ///
  /// In vi, this message translates to:
  /// **'Ứng dụng đã bị khóa'**
  String get appLockTitle;

  /// No description provided for @appLockSubtitle.
  ///
  /// In vi, this message translates to:
  /// **'Vui lòng xác thực để tiếp tục sử dụng'**
  String get appLockSubtitle;

  /// No description provided for @appLockUnlockButton.
  ///
  /// In vi, this message translates to:
  /// **'Mở khóa'**
  String get appLockUnlockButton;

  /// No description provided for @privacyCenterAppLockTitle.
  ///
  /// In vi, this message translates to:
  /// **'Khóa ứng dụng'**
  String get privacyCenterAppLockTitle;

  /// No description provided for @privacyCenterAppLockSubtitle.
  ///
  /// In vi, this message translates to:
  /// **'Yêu cầu vân tay hoặc khuôn mặt khi mở ứng dụng.'**
  String get privacyCenterAppLockSubtitle;

  /// No description provided for @privacyCenterHideBalancesTitle.
  ///
  /// In vi, this message translates to:
  /// **'Chế độ ẩn số dư'**
  String get privacyCenterHideBalancesTitle;

  /// No description provided for @privacyCenterHideBalancesSubtitle.
  ///
  /// In vi, this message translates to:
  /// **'Tự động làm mờ tất cả số tiền trên ứng dụng.'**
  String get privacyCenterHideBalancesSubtitle;

  /// No description provided for @biometricReasonEnable.
  ///
  /// In vi, this message translates to:
  /// **'Xác thực để bật khóa ứng dụng'**
  String get biometricReasonEnable;

  /// No description provided for @biometricReasonUnlock.
  ///
  /// In vi, this message translates to:
  /// **'Mở khóa Moniary'**
  String get biometricReasonUnlock;

  /// No description provided for @importTitle.
  ///
  /// In vi, this message translates to:
  /// **'Nhập dữ liệu (CSV)'**
  String get importTitle;

  /// No description provided for @importSelectFile.
  ///
  /// In vi, this message translates to:
  /// **'Chọn tệp CSV'**
  String get importSelectFile;

  /// No description provided for @importCsvFormatTitle.
  ///
  /// In vi, this message translates to:
  /// **'Định dạng CSV yêu cầu:'**
  String get importCsvFormatTitle;

  /// No description provided for @importCsvFormatBody.
  ///
  /// In vi, this message translates to:
  /// **'Dòng 1 được bỏ qua (tiêu đề).\n1. Ngày (YYYY-MM-DD)\n2. Số tiền\n3. Loại (Income/Expense/Thu/Chi)\n4. Tên danh mục\n5. Ghi chú'**
  String get importCsvFormatBody;

  /// No description provided for @importConfirm.
  ///
  /// In vi, this message translates to:
  /// **'Xác nhận nhập'**
  String get importConfirm;

  /// No description provided for @importPreviewTitle.
  ///
  /// In vi, this message translates to:
  /// **'Xem trước ({count} dòng hợp lệ)'**
  String importPreviewTitle(int count);

  /// No description provided for @importSuccess.
  ///
  /// In vi, this message translates to:
  /// **'Đã nhập {count} giao dịch'**
  String importSuccess(int count);

  /// No description provided for @importNoWallets.
  ///
  /// In vi, this message translates to:
  /// **'Không tìm thấy ví. Hãy tạo ví trước.'**
  String get importNoWallets;

  /// No description provided for @importSelectWallet.
  ///
  /// In vi, this message translates to:
  /// **'Chọn ví đích'**
  String get importSelectWallet;

  /// No description provided for @importErrorWallets.
  ///
  /// In vi, this message translates to:
  /// **'Lỗi tải danh sách ví: {error}'**
  String importErrorWallets(String error);

  /// No description provided for @importErrorUnknown.
  ///
  /// In vi, this message translates to:
  /// **'Lỗi không xác định'**
  String get importErrorUnknown;

  /// No description provided for @importErrorMissingColumns.
  ///
  /// In vi, this message translates to:
  /// **'Thiếu cột (yêu cầu 5)'**
  String get importErrorMissingColumns;

  /// No description provided for @importErrorInvalidDate.
  ///
  /// In vi, this message translates to:
  /// **'Định dạng ngày không hợp lệ (dùng YYYY-MM-DD)'**
  String get importErrorInvalidDate;

  /// No description provided for @importErrorInvalidAmount.
  ///
  /// In vi, this message translates to:
  /// **'Số tiền không hợp lệ'**
  String get importErrorInvalidAmount;

  /// No description provided for @importRetry.
  ///
  /// In vi, this message translates to:
  /// **'Thử lại'**
  String get importRetry;

  /// No description provided for @activeSessionsTitle.
  ///
  /// In vi, this message translates to:
  /// **'Thiết bị & Phiên'**
  String get activeSessionsTitle;

  /// No description provided for @activeSessionsEmpty.
  ///
  /// In vi, this message translates to:
  /// **'Không có dữ liệu.'**
  String get activeSessionsEmpty;

  /// No description provided for @activeSessionsError.
  ///
  /// In vi, this message translates to:
  /// **'Lỗi: {error}'**
  String activeSessionsError(String error);

  /// No description provided for @activeSessionsUnknownDevice.
  ///
  /// In vi, this message translates to:
  /// **'Thiết bị không xác định'**
  String get activeSessionsUnknownDevice;

  /// No description provided for @activeSessionsThisDevice.
  ///
  /// In vi, this message translates to:
  /// **'Thiết bị này'**
  String get activeSessionsThisDevice;

  /// No description provided for @activeSessionsFirstLogin.
  ///
  /// In vi, this message translates to:
  /// **'Đăng nhập lần đầu: {date}'**
  String activeSessionsFirstLogin(String date);

  /// No description provided for @activeSessionsLastActive.
  ///
  /// In vi, this message translates to:
  /// **'Hoạt động gần nhất: {date}'**
  String activeSessionsLastActive(String date);

  /// No description provided for @activeSessionsIp.
  ///
  /// In vi, this message translates to:
  /// **'IP: {ip}'**
  String activeSessionsIp(String ip);

  /// No description provided for @activeSessionsRevokeTooltip.
  ///
  /// In vi, this message translates to:
  /// **'Đăng xuất thiết bị này'**
  String get activeSessionsRevokeTooltip;

  /// No description provided for @activeSessionsRevokeTitle.
  ///
  /// In vi, this message translates to:
  /// **'Đăng xuất thiết bị?'**
  String get activeSessionsRevokeTitle;

  /// No description provided for @activeSessionsRevokeContent.
  ///
  /// In vi, this message translates to:
  /// **'Thiết bị này sẽ bị đăng xuất khỏi tài khoản của bạn ngay lập tức.'**
  String get activeSessionsRevokeContent;

  /// No description provided for @activeSessionsRevokeConfirm.
  ///
  /// In vi, this message translates to:
  /// **'Đăng xuất'**
  String get activeSessionsRevokeConfirm;

  /// No description provided for @restoreAccountTitle.
  ///
  /// In vi, this message translates to:
  /// **'Tài khoản đang chờ xóa'**
  String get restoreAccountTitle;

  /// No description provided for @restoreAccountBody.
  ///
  /// In vi, this message translates to:
  /// **'Tài khoản của bạn đã bị vô hiệu hóa và đang trong thời gian ân hạn 30 ngày trước khi bị xóa vĩnh viễn.\n\nBạn có muốn khôi phục lại tài khoản không?'**
  String get restoreAccountBody;

  /// No description provided for @restoreAccountButton.
  ///
  /// In vi, this message translates to:
  /// **'Khôi phục tài khoản'**
  String get restoreAccountButton;

  /// No description provided for @validationEmailRequired.
  ///
  /// In vi, this message translates to:
  /// **'Email không được trống'**
  String get validationEmailRequired;

  /// No description provided for @validationEmailInvalid.
  ///
  /// In vi, this message translates to:
  /// **'Email không hợp lệ'**
  String get validationEmailInvalid;

  /// No description provided for @validationPasswordMinLength.
  ///
  /// In vi, this message translates to:
  /// **'Mật khẩu phải từ {min} ký tự'**
  String validationPasswordMinLength(int min);

  /// No description provided for @exportFormatCsvDesc.
  ///
  /// In vi, this message translates to:
  /// **'Bảng dữ liệu nhẹ, mở được bằng Excel hoặc Google Sheets.'**
  String get exportFormatCsvDesc;

  /// No description provided for @exportFormatXlsxDesc.
  ///
  /// In vi, this message translates to:
  /// **'Workbook .xlsx cho Excel, Sheets hoặc WPS Office.'**
  String get exportFormatXlsxDesc;

  /// No description provided for @exportFormatPdfDesc.
  ///
  /// In vi, this message translates to:
  /// **'Báo cáo dễ đọc để lưu hoặc gửi cho người khác.'**
  String get exportFormatPdfDesc;

  /// No description provided for @exportFileSavedAt.
  ///
  /// In vi, this message translates to:
  /// **'File đã được lưu tại:\n{path}'**
  String exportFileSavedAt(String path);

  /// No description provided for @exportNoAppToShare.
  ///
  /// In vi, this message translates to:
  /// **'Chưa tìm thấy app phù hợp để chia sẻ file.'**
  String get exportNoAppToShare;

  /// No description provided for @exportNoAppToOpen.
  ///
  /// In vi, this message translates to:
  /// **'Chưa tìm thấy app phù hợp để mở file.'**
  String get exportNoAppToOpen;

  /// No description provided for @commonComingSoon.
  ///
  /// In vi, this message translates to:
  /// **'Sắp có'**
  String get commonComingSoon;

  /// No description provided for @activeSessionsDeviceOn.
  ///
  /// In vi, this message translates to:
  /// **'{browser} trên {os}'**
  String activeSessionsDeviceOn(String browser, String os);

  /// No description provided for @activeSessionsOtherOs.
  ///
  /// In vi, this message translates to:
  /// **'Hệ điều hành khác'**
  String get activeSessionsOtherOs;

  /// No description provided for @activeSessionsOtherBrowser.
  ///
  /// In vi, this message translates to:
  /// **'Trình duyệt/App khác'**
  String get activeSessionsOtherBrowser;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'vi'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'vi':
      return AppLocalizationsVi();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
