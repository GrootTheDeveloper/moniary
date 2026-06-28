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
  /// **'Sao chép'**
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

  /// No description provided for @commonViewAll.
  ///
  /// In vi, this message translates to:
  /// **'Xem tất cả'**
  String get commonViewAll;

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

  /// No description provided for @commonConfirm.
  ///
  /// In vi, this message translates to:
  /// **'Xác nhận'**
  String get commonConfirm;

  /// No description provided for @errorGeneric.
  ///
  /// In vi, this message translates to:
  /// **'Đã xảy ra lỗi. Vui lòng thử lại.'**
  String get errorGeneric;

  /// No description provided for @errorLocalAuthUnavailable.
  ///
  /// In vi, this message translates to:
  /// **'Thiết bị này không hỗ trợ xác thực sinh trắc học hoặc mã khóa màn hình.'**
  String get errorLocalAuthUnavailable;

  /// No description provided for @errorLocalAuthFailed.
  ///
  /// In vi, this message translates to:
  /// **'Không thể xác thực thiết bị. Vui lòng thử lại.'**
  String get errorLocalAuthFailed;

  /// No description provided for @errorNotLoggedIn.
  ///
  /// In vi, this message translates to:
  /// **'Bạn chưa đăng nhập.'**
  String get errorNotLoggedIn;

  /// No description provided for @errorNotFound.
  ///
  /// In vi, this message translates to:
  /// **'Dữ liệu không tồn tại.'**
  String get errorNotFound;

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
  /// **'Kết nối ẩn danh với Supabase'**
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
  /// **'Đăng nhập với Google'**
  String get loginGoogle;

  /// No description provided for @loginApple.
  ///
  /// In vi, this message translates to:
  /// **'Đăng nhập với Apple'**
  String get loginApple;

  /// No description provided for @loginEmail.
  ///
  /// In vi, this message translates to:
  /// **'Đăng nhập với Email'**
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

  /// No description provided for @calendarLoading.
  ///
  /// In vi, this message translates to:
  /// **'Đang đồng bộ lịch...'**
  String get calendarLoading;

  /// No description provided for @calendarEmptyTitle.
  ///
  /// In vi, this message translates to:
  /// **'Chưa có dữ liệu'**
  String get calendarEmptyTitle;

  /// No description provided for @calendarEmptyBody.
  ///
  /// In vi, this message translates to:
  /// **'Bạn chưa có giao dịch nào trong tháng này. Hãy thêm giao dịch để bắt đầu theo dõi.'**
  String get calendarEmptyBody;

  /// No description provided for @calendarErrorTitle.
  ///
  /// In vi, this message translates to:
  /// **'Lỗi tải dữ liệu'**
  String get calendarErrorTitle;

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

  /// No description provided for @calendarStarred.
  ///
  /// In vi, this message translates to:
  /// **'Quan trọng'**
  String get calendarStarred;

  /// No description provided for @calendarSearchHint.
  ///
  /// In vi, this message translates to:
  /// **'Tìm theo ghi chú hoặc danh mục...'**
  String get calendarSearchHint;

  /// No description provided for @calendarSearchPrompt.
  ///
  /// In vi, this message translates to:
  /// **'Nhập ghi chú hoặc danh mục để tìm kiếm.'**
  String get calendarSearchPrompt;

  /// No description provided for @calendarSearchNoResults.
  ///
  /// In vi, this message translates to:
  /// **'Không tìm thấy giao dịch nào.'**
  String get calendarSearchNoResults;

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

  /// No description provided for @walletUnknown.
  ///
  /// In vi, this message translates to:
  /// **'Ví không xác định'**
  String get walletUnknown;

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
  /// **'Lỗi danh mục: {error}'**
  String categoryError(String error);

  /// No description provided for @categoryOther.
  ///
  /// In vi, this message translates to:
  /// **'Khác'**
  String get categoryOther;

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
  String scanQuantity(String quantity);

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

  /// No description provided for @profileMoniarySetup.
  ///
  /// In vi, this message translates to:
  /// **'Thiết lập Moniary'**
  String get profileMoniarySetup;

  /// No description provided for @profileGeneralSection.
  ///
  /// In vi, this message translates to:
  /// **'Chung'**
  String get profileGeneralSection;

  /// No description provided for @profileSupportSection.
  ///
  /// In vi, this message translates to:
  /// **'Hỗ trợ'**
  String get profileSupportSection;

  /// No description provided for @profilePrivacySafetySection.
  ///
  /// In vi, this message translates to:
  /// **'Quyền riêng tư & an toàn'**
  String get profilePrivacySafetySection;

  /// No description provided for @profileDangerZoneSection.
  ///
  /// In vi, this message translates to:
  /// **'Vùng nguy hiểm'**
  String get profileDangerZoneSection;

  /// No description provided for @profileHowMoniaryWorksTitle.
  ///
  /// In vi, this message translates to:
  /// **'Cách Moniary hoạt động'**
  String get profileHowMoniaryWorksTitle;

  /// No description provided for @profileHowMoniaryWorksSubtitle.
  ///
  /// In vi, this message translates to:
  /// **'Hướng dẫn nhanh để ghi nhận và xem lại tài chính cá nhân.'**
  String get profileHowMoniaryWorksSubtitle;

  /// No description provided for @profileSetupGuideWalletTitle.
  ///
  /// In vi, this message translates to:
  /// **'Thiết lập ví'**
  String get profileSetupGuideWalletTitle;

  /// No description provided for @profileSetupGuideWalletBody.
  ///
  /// In vi, this message translates to:
  /// **'Tạo hoặc kiểm tra ví để mỗi giao dịch có nguồn tiền rõ ràng.'**
  String get profileSetupGuideWalletBody;

  /// No description provided for @profileSetupGuideTransactionTitle.
  ///
  /// In vi, this message translates to:
  /// **'Thêm giao dịch'**
  String get profileSetupGuideTransactionTitle;

  /// No description provided for @profileSetupGuideTransactionBody.
  ///
  /// In vi, this message translates to:
  /// **'Chụp chi tiêu bằng ảnh hoặc nhập giao dịch thủ công.'**
  String get profileSetupGuideTransactionBody;

  /// No description provided for @profileSetupGuideReviewTitle.
  ///
  /// In vi, this message translates to:
  /// **'Xem Calendar và Statistics'**
  String get profileSetupGuideReviewTitle;

  /// No description provided for @profileSetupGuideReviewBody.
  ///
  /// In vi, this message translates to:
  /// **'Dùng Calendar và Statistics để hiểu chi tiêu theo ngày và tháng.'**
  String get profileSetupGuideReviewBody;

  /// No description provided for @profileSetupGuideExportTitle.
  ///
  /// In vi, this message translates to:
  /// **'Xuất và bảo vệ dữ liệu'**
  String get profileSetupGuideExportTitle;

  /// No description provided for @profileSetupGuideExportBody.
  ///
  /// In vi, this message translates to:
  /// **'Xuất dữ liệu và kiểm tra quyền riêng tư khi cần.'**
  String get profileSetupGuideExportBody;

  /// No description provided for @profilePrivacyCenter.
  ///
  /// In vi, this message translates to:
  /// **'Bảo mật & quyền riêng tư'**
  String get profilePrivacyCenter;

  /// No description provided for @privacyGroupPrivacyTermsTitle.
  ///
  /// In vi, this message translates to:
  /// **'Quyền riêng tư & điều khoản'**
  String get privacyGroupPrivacyTermsTitle;

  /// No description provided for @privacyGroupPrivacyTermsSubtitle.
  ///
  /// In vi, this message translates to:
  /// **'Chính sách, điều khoản và thông báo pháp lý.'**
  String get privacyGroupPrivacyTermsSubtitle;

  /// No description provided for @privacyTermsPolicySubtitle.
  ///
  /// In vi, this message translates to:
  /// **'Dữ liệu cá nhân, tài chính, ảnh và dịch vụ bên thứ ba.'**
  String get privacyTermsPolicySubtitle;

  /// No description provided for @privacyTermsLimitationsTitle.
  ///
  /// In vi, this message translates to:
  /// **'Điều khoản & giới hạn'**
  String get privacyTermsLimitationsTitle;

  /// No description provided for @privacyTermsLimitationsSubtitle.
  ///
  /// In vi, this message translates to:
  /// **'Phạm vi sử dụng, trách nhiệm người dùng và miễn trừ tài chính.'**
  String get privacyTermsLimitationsSubtitle;

  /// No description provided for @privacyTermsRecordsTitle.
  ///
  /// In vi, this message translates to:
  /// **'Hồ sơ chính sách'**
  String get privacyTermsRecordsTitle;

  /// No description provided for @privacyTermsRecordsSubtitle.
  ///
  /// In vi, this message translates to:
  /// **'Cập nhật chính sách, thông báo đồng ý và liên hệ pháp lý.'**
  String get privacyTermsRecordsSubtitle;

  /// No description provided for @privacyGroupDataSafetyTitle.
  ///
  /// In vi, this message translates to:
  /// **'An toàn dữ liệu'**
  String get privacyGroupDataSafetyTitle;

  /// No description provided for @privacyGroupDataSafetySubtitle.
  ///
  /// In vi, this message translates to:
  /// **'Dữ liệu, quyền truy cập và khai báo CH Play.'**
  String get privacyGroupDataSafetySubtitle;

  /// No description provided for @privacyDataOverviewTitle.
  ///
  /// In vi, this message translates to:
  /// **'Tổng quan dữ liệu'**
  String get privacyDataOverviewTitle;

  /// No description provided for @privacyDataOverviewSubtitle.
  ///
  /// In vi, this message translates to:
  /// **'Dữ liệu đã lưu, nhóm dữ liệu thu thập và tóm tắt tài khoản.'**
  String get privacyDataOverviewSubtitle;

  /// No description provided for @privacyDataControlsTitle.
  ///
  /// In vi, this message translates to:
  /// **'Kiểm soát dữ liệu'**
  String get privacyDataControlsTitle;

  /// No description provided for @privacyDataControlsSubtitle.
  ///
  /// In vi, this message translates to:
  /// **'Quyền dữ liệu, lưu giữ dữ liệu và chính sách xóa.'**
  String get privacyDataControlsSubtitle;

  /// No description provided for @privacyGroupHelpRequestsTitle.
  ///
  /// In vi, this message translates to:
  /// **'Hỗ trợ & yêu cầu'**
  String get privacyGroupHelpRequestsTitle;

  /// No description provided for @privacyGroupHelpRequestsSubtitle.
  ///
  /// In vi, this message translates to:
  /// **'Trợ giúp, liên hệ và yêu cầu quyền riêng tư.'**
  String get privacyGroupHelpRequestsSubtitle;

  /// No description provided for @privacyHelpCenterSubtitle.
  ///
  /// In vi, this message translates to:
  /// **'Hướng dẫn, xử lý sự cố và ghi chú sử dụng an toàn.'**
  String get privacyHelpCenterSubtitle;

  /// No description provided for @privacyRequestsTitle.
  ///
  /// In vi, this message translates to:
  /// **'Yêu cầu quyền riêng tư'**
  String get privacyRequestsTitle;

  /// No description provided for @privacyRequestsSubtitle.
  ///
  /// In vi, this message translates to:
  /// **'Liên hệ hỗ trợ hoặc yêu cầu trợ giúp về quyền riêng tư và xóa dữ liệu.'**
  String get privacyRequestsSubtitle;

  /// No description provided for @privacyAboutSubtitle.
  ///
  /// In vi, this message translates to:
  /// **'Mục đích app, trạng thái MVP và thông tin phát hành.'**
  String get privacyAboutSubtitle;

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

  /// No description provided for @dailyReportDesc.
  ///
  /// In vi, this message translates to:
  /// **'Mỗi ngày lúc {time}'**
  String dailyReportDesc(String time);

  /// No description provided for @weeklyReport.
  ///
  /// In vi, this message translates to:
  /// **'Báo cáo hàng tuần'**
  String get weeklyReport;

  /// No description provided for @weeklyReportDesc.
  ///
  /// In vi, this message translates to:
  /// **'Mỗi tuần một lần'**
  String get weeklyReportDesc;

  /// No description provided for @monthlyReport.
  ///
  /// In vi, this message translates to:
  /// **'Báo cáo hàng tháng'**
  String get monthlyReport;

  /// No description provided for @monthlyReportDesc.
  ///
  /// In vi, this message translates to:
  /// **'Mỗi tháng một lần'**
  String get monthlyReportDesc;

  /// No description provided for @yearlyReport.
  ///
  /// In vi, this message translates to:
  /// **'Báo cáo hàng năm'**
  String get yearlyReport;

  /// No description provided for @yearlyReportDesc.
  ///
  /// In vi, this message translates to:
  /// **'Mỗi năm một lần'**
  String get yearlyReportDesc;

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

  /// No description provided for @exportDataTypeTransactions.
  ///
  /// In vi, this message translates to:
  /// **'Giao dịch'**
  String get exportDataTypeTransactions;

  /// No description provided for @exportDataTypeWallets.
  ///
  /// In vi, this message translates to:
  /// **'Ví'**
  String get exportDataTypeWallets;

  /// No description provided for @exportDataTypeCategories.
  ///
  /// In vi, this message translates to:
  /// **'Danh mục'**
  String get exportDataTypeCategories;

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
  /// **'Lịch sử export'**
  String get exportHistoryTitle;

  /// No description provided for @exportHistoryEmpty.
  ///
  /// In vi, this message translates to:
  /// **'Chưa có file export nào.'**
  String get exportHistoryEmpty;

  /// No description provided for @exportRecentTitle.
  ///
  /// In vi, this message translates to:
  /// **'Lần xuất gần đây'**
  String get exportRecentTitle;

  /// No description provided for @exportRecentHistoryError.
  ///
  /// In vi, this message translates to:
  /// **'Không tải được lần xuất gần đây.'**
  String get exportRecentHistoryError;

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
  /// **'Không có quyền truy cập camera'**
  String get cameraNoPermission;

  /// No description provided for @cameraTitle.
  ///
  /// In vi, this message translates to:
  /// **'Chụp hóa đơn'**
  String get cameraTitle;

  /// No description provided for @cameraOcrScan.
  ///
  /// In vi, this message translates to:
  /// **'Quét OCR'**
  String get cameraOcrScan;

  /// No description provided for @cameraGallery.
  ///
  /// In vi, this message translates to:
  /// **'Thư viện'**
  String get cameraGallery;

  /// No description provided for @accountDeletionRequestTitle.
  ///
  /// In vi, this message translates to:
  /// **'Yêu cầu xóa dữ liệu'**
  String get accountDeletionRequestTitle;

  /// No description provided for @accountDeletionRequestDesc.
  ///
  /// In vi, this message translates to:
  /// **'Dùng lựa chọn này khi không thể xóa tài khoản trực tiếp trong app. Moniary sẽ tạo một file yêu cầu để bạn gửi cho kênh hỗ trợ quyền riêng tư.'**
  String get accountDeletionRequestDesc;

  /// No description provided for @accountDeletionRequestReasonLabel.
  ///
  /// In vi, this message translates to:
  /// **'Lý do hoặc ghi chú cho yêu cầu'**
  String get accountDeletionRequestReasonLabel;

  /// No description provided for @accountDeletionRequestReasonHint.
  ///
  /// In vi, this message translates to:
  /// **'Ví dụ: Tôi không còn sử dụng app và muốn xóa toàn bộ dữ liệu.'**
  String get accountDeletionRequestReasonHint;

  /// No description provided for @accountDeletionRequestSubmit.
  ///
  /// In vi, this message translates to:
  /// **'Tạo yêu cầu xóa dữ liệu'**
  String get accountDeletionRequestSubmit;

  /// No description provided for @accountDeletionRequestSuccessDesc.
  ///
  /// In vi, this message translates to:
  /// **'Yêu cầu đã được tạo. Vui lòng kiểm tra lịch sử và gửi yêu cầu thủ công.'**
  String get accountDeletionRequestSuccessDesc;

  /// No description provided for @deleteAccountHelpTitle.
  ///
  /// In vi, this message translates to:
  /// **'Hỗ trợ xóa tài khoản'**
  String get deleteAccountHelpTitle;

  /// No description provided for @deleteAccountHelpHero.
  ///
  /// In vi, this message translates to:
  /// **'Xóa tài khoản là thao tác quan trọng. Hướng dẫn này giúp người dùng chuẩn bị dữ liệu và biết cách gửi yêu cầu hỗ trợ khi cần.'**
  String get deleteAccountHelpHero;

  /// No description provided for @deleteAccountHelpStep1Title.
  ///
  /// In vi, this message translates to:
  /// **'1. Xuất dữ liệu trước khi xóa'**
  String get deleteAccountHelpStep1Title;

  /// No description provided for @deleteAccountHelpStep1Desc.
  ///
  /// In vi, this message translates to:
  /// **'Sau khi xóa tài khoản, dữ liệu app gắn với user hiện tại có thể không khôi phục được. Hãy export CSV, Excel hoặc PDF trước nếu cần giữ bản sao.'**
  String get deleteAccountHelpStep1Desc;

  /// No description provided for @deleteAccountHelpStep2Title.
  ///
  /// In vi, this message translates to:
  /// **'2. Kiểm tra ảnh giao dịch'**
  String get deleteAccountHelpStep2Title;

  /// No description provided for @deleteAccountHelpStep2Desc.
  ///
  /// In vi, this message translates to:
  /// **'Ảnh giao dịch được xử lý cùng dữ liệu tài khoản. Hãy tải hoặc lưu lại file cần thiết trước khi xóa.'**
  String get deleteAccountHelpStep2Desc;

  /// No description provided for @deleteAccountHelpStep3Title.
  ///
  /// In vi, this message translates to:
  /// **'3. Xác nhận kỹ trong app'**
  String get deleteAccountHelpStep3Title;

  /// No description provided for @deleteAccountHelpStep3Desc.
  ///
  /// In vi, this message translates to:
  /// **'Luồng xóa tài khoản yêu cầu xác nhận mạnh để tránh thao tác nhầm.'**
  String get deleteAccountHelpStep3Desc;

  /// No description provided for @deleteAccountHelpStep4Title.
  ///
  /// In vi, this message translates to:
  /// **'4. Dùng fallback nếu xóa thất bại'**
  String get deleteAccountHelpStep4Title;

  /// No description provided for @deleteAccountHelpStep4Desc.
  ///
  /// In vi, this message translates to:
  /// **'Nếu thao tác trực tiếp lỗi, tạo file yêu cầu xóa dữ liệu thủ công và gửi kèm mô tả lỗi cho kênh hỗ trợ.'**
  String get deleteAccountHelpStep4Desc;

  /// No description provided for @deleteAccountHelpExportBefore.
  ///
  /// In vi, this message translates to:
  /// **'Xuất dữ liệu trước'**
  String get deleteAccountHelpExportBefore;

  /// No description provided for @deleteAccountHelpCreateRequest.
  ///
  /// In vi, this message translates to:
  /// **'Tạo request xóa dữ liệu'**
  String get deleteAccountHelpCreateRequest;

  /// No description provided for @deleteAccountHelpContactPrivacy.
  ///
  /// In vi, this message translates to:
  /// **'Liên hệ privacy'**
  String get deleteAccountHelpContactPrivacy;

  /// No description provided for @legalContactHero.
  ///
  /// In vi, this message translates to:
  /// **'Các kênh liên hệ này giúp người dùng, reviewer hoặc team phát hành biết nơi gửi yêu cầu phù hợp.'**
  String get legalContactHero;

  /// No description provided for @legalContactPrivacyDesc.
  ///
  /// In vi, this message translates to:
  /// **'Yêu cầu dữ liệu cá nhân, xóa dữ liệu hoặc câu hỏi privacy.'**
  String get legalContactPrivacyDesc;

  /// No description provided for @legalContactSupportDesc.
  ///
  /// In vi, this message translates to:
  /// **'Hỗ trợ chung về app, file export hoặc thao tác người dùng.'**
  String get legalContactSupportDesc;

  /// No description provided for @legalContactLegalDesc.
  ///
  /// In vi, this message translates to:
  /// **'Vấn đề điều khoản, phát hành Store hoặc yêu cầu pháp lý.'**
  String get legalContactLegalDesc;

  /// No description provided for @legalContactPrivacy.
  ///
  /// In vi, this message translates to:
  /// **'Quyền riêng tư'**
  String get legalContactPrivacy;

  /// No description provided for @legalContactSupport.
  ///
  /// In vi, this message translates to:
  /// **'Hỗ trợ'**
  String get legalContactSupport;

  /// No description provided for @legalContactLegal.
  ///
  /// In vi, this message translates to:
  /// **'Pháp lý'**
  String get legalContactLegal;

  /// No description provided for @privacyDetailCreatedAt.
  ///
  /// In vi, this message translates to:
  /// **'Tạo lúc {date}'**
  String privacyDetailCreatedAt(String date);

  /// No description provided for @privacyDetailExpectedResponse.
  ///
  /// In vi, this message translates to:
  /// **'Dự kiến phản hồi'**
  String get privacyDetailExpectedResponse;

  /// No description provided for @privacyDetailExpectedResponseDesc.
  ///
  /// In vi, this message translates to:
  /// **'{date} hoặc trong {days} ngày làm việc sau khi gửi.'**
  String privacyDetailExpectedResponseDesc(String date, int days);

  /// No description provided for @privacyDetailMarkStatus.
  ///
  /// In vi, this message translates to:
  /// **'Đánh dấu: {status}'**
  String privacyDetailMarkStatus(String status);

  /// No description provided for @privacyDetailContentTitle.
  ///
  /// In vi, this message translates to:
  /// **'Nội dung yêu cầu'**
  String get privacyDetailContentTitle;

  /// No description provided for @privacyDetailContentEmpty.
  ///
  /// In vi, this message translates to:
  /// **'Không có nội dung bổ sung.'**
  String get privacyDetailContentEmpty;

  /// No description provided for @privacyDetailFileTitle.
  ///
  /// In vi, this message translates to:
  /// **'File đã tạo'**
  String get privacyDetailFileTitle;

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

  /// No description provided for @starredTransactionsTitle.
  ///
  /// In vi, this message translates to:
  /// **'Giao dịch quan trọng'**
  String get starredTransactionsTitle;

  /// No description provided for @starredTransactionsEmpty.
  ///
  /// In vi, this message translates to:
  /// **'Chưa có giao dịch quan trọng nào'**
  String get starredTransactionsEmpty;

  /// No description provided for @statsCategoryTransactions.
  ///
  /// In vi, this message translates to:
  /// **'Giao dịch trong danh mục'**
  String get statsCategoryTransactions;

  /// No description provided for @statsDayTooltip.
  ///
  /// In vi, this message translates to:
  /// **'Ngày {day}\n{amount}'**
  String statsDayTooltip(int day, String amount);

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

  /// No description provided for @profileLinkApple.
  ///
  /// In vi, this message translates to:
  /// **'Liên kết Apple'**
  String get profileLinkApple;

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

  /// No description provided for @profileLinkAppleBrowser.
  ///
  /// In vi, this message translates to:
  /// **'Hoàn tất liên kết Apple trong trình duyệt để quay lại Moniary.'**
  String get profileLinkAppleBrowser;

  /// No description provided for @profileLinkGoogleError.
  ///
  /// In vi, this message translates to:
  /// **'Lỗi liên kết Google: {error}'**
  String profileLinkGoogleError(String error);

  /// No description provided for @profileLinkAppleError.
  ///
  /// In vi, this message translates to:
  /// **'Lỗi liên kết Apple: {error}'**
  String profileLinkAppleError(String error);

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

  /// No description provided for @exportTroubleshootingHero.
  ///
  /// In vi, this message translates to:
  /// **'Hướng dẫn này giúp xử lý nhanh khi file CSV, Excel hoặc PDF không có dữ liệu, không mở được hoặc không tìm thấy sau khi export.'**
  String get exportTroubleshootingHero;

  /// No description provided for @exportTroubleshootingTypeTitle.
  ///
  /// In vi, this message translates to:
  /// **'1. Kiểm tra loại dữ liệu đã chọn'**
  String get exportTroubleshootingTypeTitle;

  /// No description provided for @exportTroubleshootingTypeDesc.
  ///
  /// In vi, this message translates to:
  /// **'Nếu file trống, hãy kiểm tra bạn đã chọn Giao dịch, Ví hoặc Danh mục trong bộ lọc export.'**
  String get exportTroubleshootingTypeDesc;

  /// No description provided for @exportTroubleshootingDateTitle.
  ///
  /// In vi, this message translates to:
  /// **'2. Kiểm tra khoảng ngày'**
  String get exportTroubleshootingDateTitle;

  /// No description provided for @exportTroubleshootingDateDesc.
  ///
  /// In vi, this message translates to:
  /// **'Nếu chọn khoảng ngày quá hẹp, file có thể không có giao dịch phù hợp.'**
  String get exportTroubleshootingDateDesc;

  /// No description provided for @exportTroubleshootingHistoryTitle.
  ///
  /// In vi, this message translates to:
  /// **'3. Mở lại từ lịch sử export'**
  String get exportTroubleshootingHistoryTitle;

  /// No description provided for @exportTroubleshootingHistoryDesc.
  ///
  /// In vi, this message translates to:
  /// **'Sau khi tạo file, vào lịch sử export để mở lại đường dẫn file và chia sẻ khi cần.'**
  String get exportTroubleshootingHistoryDesc;

  /// No description provided for @exportTroubleshootingSupportTitle.
  ///
  /// In vi, this message translates to:
  /// **'4. Tạo request hỗ trợ'**
  String get exportTroubleshootingSupportTitle;

  /// No description provided for @exportTroubleshootingSupportDesc.
  ///
  /// In vi, this message translates to:
  /// **'Nếu file không tạo được hoặc không mở được, hãy tạo request privacy/support kèm mô tả lỗi.'**
  String get exportTroubleshootingSupportDesc;

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
  /// **'An toàn dữ liệu'**
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

  /// No description provided for @privacyCopyFilePathSuccess.
  ///
  /// In vi, this message translates to:
  /// **'Đã copy đường dẫn file'**
  String get privacyCopyFilePathSuccess;

  /// No description provided for @privacyCopyRequest.
  ///
  /// In vi, this message translates to:
  /// **'Copy request'**
  String get privacyCopyRequest;

  /// No description provided for @privacyCopyRequestSuccess.
  ///
  /// In vi, this message translates to:
  /// **'Đã copy nội dung yêu cầu'**
  String get privacyCopyRequestSuccess;

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
  /// **'1. Ngày giao dịch (YYYY-MM-DD)\n2. Số tiền (Ví dụ: 100000)\n3. Loại (Thu / Chi)\n4. Hạng mục\n5. Ghi chú (Tùy chọn)\n\nLưu ý: Bỏ qua dòng tiêu đề nếu có.'**
  String get importCsvFormatBody;

  /// No description provided for @importConfirm.
  ///
  /// In vi, this message translates to:
  /// **'Xác nhận nhập'**
  String get importConfirm;

  /// No description provided for @importRecentTitle.
  ///
  /// In vi, this message translates to:
  /// **'Lần nạp gần đây'**
  String get importRecentTitle;

  /// No description provided for @importRecentHistoryError.
  ///
  /// In vi, this message translates to:
  /// **'Không tải được lần nạp gần đây.'**
  String get importRecentHistoryError;

  /// No description provided for @importViewHistory.
  ///
  /// In vi, this message translates to:
  /// **'Xem lịch sử nạp'**
  String get importViewHistory;

  /// No description provided for @importHistoryTitle.
  ///
  /// In vi, this message translates to:
  /// **'Lịch sử nạp dữ liệu'**
  String get importHistoryTitle;

  /// No description provided for @importDetailTitle.
  ///
  /// In vi, this message translates to:
  /// **'Chi tiết nạp dữ liệu'**
  String get importDetailTitle;

  /// No description provided for @importNoHistory.
  ///
  /// In vi, this message translates to:
  /// **'Chưa có lịch sử nạp dữ liệu.'**
  String get importNoHistory;

  /// No description provided for @importDetailFileName.
  ///
  /// In vi, this message translates to:
  /// **'Tên file'**
  String get importDetailFileName;

  /// No description provided for @importDetailImportedCount.
  ///
  /// In vi, this message translates to:
  /// **'Số giao dịch nạp thành công'**
  String get importDetailImportedCount;

  /// No description provided for @importDetailWallet.
  ///
  /// In vi, this message translates to:
  /// **'Ví đích'**
  String get importDetailWallet;

  /// No description provided for @importDetailDate.
  ///
  /// In vi, this message translates to:
  /// **'Ngày nạp'**
  String get importDetailDate;

  /// No description provided for @importDetailStatus.
  ///
  /// In vi, this message translates to:
  /// **'Trạng thái'**
  String get importDetailStatus;

  /// No description provided for @importDetailError.
  ///
  /// In vi, this message translates to:
  /// **'Lỗi'**
  String get importDetailError;

  /// No description provided for @importStatusPending.
  ///
  /// In vi, this message translates to:
  /// **'Đang nạp'**
  String get importStatusPending;

  /// No description provided for @importStatusCompleted.
  ///
  /// In vi, this message translates to:
  /// **'Hoàn tất'**
  String get importStatusCompleted;

  /// No description provided for @importStatusFailed.
  ///
  /// In vi, this message translates to:
  /// **'Thất bại'**
  String get importStatusFailed;

  /// No description provided for @settingsTitle.
  ///
  /// In vi, this message translates to:
  /// **'Cài đặt'**
  String get settingsTitle;

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

  /// No description provided for @importErrorInvalidType.
  ///
  /// In vi, this message translates to:
  /// **'Loại giao dịch không hợp lệ'**
  String get importErrorInvalidType;

  /// No description provided for @importErrorCategoryNotFound.
  ///
  /// In vi, this message translates to:
  /// **'Không tìm thấy danh mục'**
  String get importErrorCategoryNotFound;

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

  /// No description provided for @exportFormatCsvLabel.
  ///
  /// In vi, this message translates to:
  /// **'CSV'**
  String get exportFormatCsvLabel;

  /// No description provided for @exportFormatCsvDesc.
  ///
  /// In vi, this message translates to:
  /// **'Bảng dữ liệu nhẹ, mở được bằng Excel hoặc Google Sheets.'**
  String get exportFormatCsvDesc;

  /// No description provided for @exportFormatXlsxLabel.
  ///
  /// In vi, this message translates to:
  /// **'Excel'**
  String get exportFormatXlsxLabel;

  /// No description provided for @exportFormatXlsxDesc.
  ///
  /// In vi, this message translates to:
  /// **'Workbook .xlsx cho Excel, Sheets hoặc WPS Office.'**
  String get exportFormatXlsxDesc;

  /// No description provided for @exportFormatPdfLabel.
  ///
  /// In vi, this message translates to:
  /// **'PDF'**
  String get exportFormatPdfLabel;

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

  /// No description provided for @exportDetailTitle.
  ///
  /// In vi, this message translates to:
  /// **'Chi tiết bản xuất'**
  String get exportDetailTitle;

  /// No description provided for @exportDetailFileInfo.
  ///
  /// In vi, this message translates to:
  /// **'Thông tin file'**
  String get exportDetailFileInfo;

  /// No description provided for @exportDetailTime.
  ///
  /// In vi, this message translates to:
  /// **'Thời gian'**
  String get exportDetailTime;

  /// No description provided for @exportDetailFormat.
  ///
  /// In vi, this message translates to:
  /// **'Định dạng'**
  String get exportDetailFormat;

  /// No description provided for @exportDetailStatus.
  ///
  /// In vi, this message translates to:
  /// **'Trạng thái'**
  String get exportDetailStatus;

  /// No description provided for @exportDetailReady.
  ///
  /// In vi, this message translates to:
  /// **'Sẵn sàng'**
  String get exportDetailReady;

  /// No description provided for @exportDetailMissing.
  ///
  /// In vi, this message translates to:
  /// **'File đã bị xóa'**
  String get exportDetailMissing;

  /// No description provided for @exportDetailDataConfig.
  ///
  /// In vi, this message translates to:
  /// **'Cấu hình dữ liệu'**
  String get exportDetailDataConfig;

  /// No description provided for @exportDetailDataRange.
  ///
  /// In vi, this message translates to:
  /// **'Thời gian dữ liệu'**
  String get exportDetailDataRange;

  /// No description provided for @exportDetailDataGroups.
  ///
  /// In vi, this message translates to:
  /// **'Các nhóm dữ liệu'**
  String get exportDetailDataGroups;

  /// No description provided for @exportDetailStoragePath.
  ///
  /// In vi, this message translates to:
  /// **'Đường dẫn lưu trữ'**
  String get exportDetailStoragePath;

  /// No description provided for @exportDetailLocation.
  ///
  /// In vi, this message translates to:
  /// **'Vị trí'**
  String get exportDetailLocation;

  /// No description provided for @exportDetailOpenFile.
  ///
  /// In vi, this message translates to:
  /// **'Mở xem file ngay'**
  String get exportDetailOpenFile;

  /// No description provided for @exportDetailShareFile.
  ///
  /// In vi, this message translates to:
  /// **'Chia sẻ qua Email / Zalo'**
  String get exportDetailShareFile;

  /// No description provided for @exportDetailMissingMessage.
  ///
  /// In vi, this message translates to:
  /// **'Tệp tin này không còn tồn tại trên thiết bị. Bạn có thể thực hiện xuất lại dữ liệu với các bộ lọc tương tự.'**
  String get exportDetailMissingMessage;

  /// No description provided for @exportDetailSuccessTitle.
  ///
  /// In vi, this message translates to:
  /// **'Xuất dữ liệu thành công'**
  String get exportDetailSuccessTitle;

  /// No description provided for @exportDetailReportSubtitle.
  ///
  /// In vi, this message translates to:
  /// **'Moniary Financial Report'**
  String get exportDetailReportSubtitle;

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

  /// No description provided for @privacyReqDataAccess.
  ///
  /// In vi, this message translates to:
  /// **'Xem dữ liệu đang lưu'**
  String get privacyReqDataAccess;

  /// No description provided for @privacyReqDataAccessDesc.
  ///
  /// In vi, this message translates to:
  /// **'Yêu cầu Moniary cung cấp thông tin về dữ liệu đang gắn với tài khoản.'**
  String get privacyReqDataAccessDesc;

  /// No description provided for @privacyReqExportHelp.
  ///
  /// In vi, this message translates to:
  /// **'Hỗ trợ xuất dữ liệu'**
  String get privacyReqExportHelp;

  /// No description provided for @privacyReqExportHelpDesc.
  ///
  /// In vi, this message translates to:
  /// **'Yêu cầu hỗ trợ khi không thể tự xuất dữ liệu trong app.'**
  String get privacyReqExportHelpDesc;

  /// No description provided for @privacyReqCorrection.
  ///
  /// In vi, this message translates to:
  /// **'Chỉnh sửa dữ liệu'**
  String get privacyReqCorrection;

  /// No description provided for @privacyReqCorrectionDesc.
  ///
  /// In vi, this message translates to:
  /// **'Yêu cầu điều chỉnh dữ liệu cá nhân hoặc dữ liệu tài chính bị sai.'**
  String get privacyReqCorrectionDesc;

  /// No description provided for @privacyReqDeletion.
  ///
  /// In vi, this message translates to:
  /// **'Xóa dữ liệu'**
  String get privacyReqDeletion;

  /// No description provided for @privacyReqDeletionDesc.
  ///
  /// In vi, this message translates to:
  /// **'Yêu cầu xóa dữ liệu hoặc hỗ trợ khi xóa tài khoản không thành công.'**
  String get privacyReqDeletionDesc;

  /// No description provided for @privacyReqComplaint.
  ///
  /// In vi, this message translates to:
  /// **'Khiếu nại quyền riêng tư'**
  String get privacyReqComplaint;

  /// No description provided for @privacyReqComplaintDesc.
  ///
  /// In vi, this message translates to:
  /// **'Gửi phản hồi về cách dữ liệu cá nhân được xử lý trong Moniary.'**
  String get privacyReqComplaintDesc;

  /// No description provided for @privacyStatusReady.
  ///
  /// In vi, this message translates to:
  /// **'Sẵn sàng gửi'**
  String get privacyStatusReady;

  /// No description provided for @privacyStatusReadyDesc.
  ///
  /// In vi, this message translates to:
  /// **'File request đã được tạo và đang chờ người dùng gửi đi.'**
  String get privacyStatusReadyDesc;

  /// No description provided for @privacyStatusSent.
  ///
  /// In vi, this message translates to:
  /// **'Đã gửi thủ công'**
  String get privacyStatusSent;

  /// No description provided for @privacyStatusSentDesc.
  ///
  /// In vi, this message translates to:
  /// **'Người dùng đã gửi request qua email hoặc kênh hỗ trợ.'**
  String get privacyStatusSentDesc;

  /// No description provided for @privacyStatusResolved.
  ///
  /// In vi, this message translates to:
  /// **'Đã xử lý'**
  String get privacyStatusResolved;

  /// No description provided for @privacyStatusResolvedDesc.
  ///
  /// In vi, this message translates to:
  /// **'Yêu cầu đã được xử lý xong hoặc không cần theo dõi nữa.'**
  String get privacyStatusResolvedDesc;

  /// No description provided for @privacyTplDataAccess.
  ///
  /// In vi, this message translates to:
  /// **'Tôi muốn biết Moniary hiện đang lưu những nhóm dữ liệu nào liên quan đến tài khoản của tôi.'**
  String get privacyTplDataAccess;

  /// No description provided for @privacyTplExportHelp.
  ///
  /// In vi, this message translates to:
  /// **'Tôi cần hỗ trợ xuất dữ liệu tài khoản vì không thể hoàn tất thao tác xuất dữ liệu trong app.'**
  String get privacyTplExportHelp;

  /// No description provided for @privacyTplCorrection.
  ///
  /// In vi, this message translates to:
  /// **'Tôi muốn yêu cầu chỉnh sửa dữ liệu chưa chính xác trong tài khoản của mình. Dữ liệu cần kiểm tra là:'**
  String get privacyTplCorrection;

  /// No description provided for @privacyTplDeletion.
  ///
  /// In vi, this message translates to:
  /// **'Tôi muốn yêu cầu xóa dữ liệu cá nhân và dữ liệu tài chính liên quan đến tài khoản của mình.'**
  String get privacyTplDeletion;

  /// No description provided for @privacyTplComplaint.
  ///
  /// In vi, this message translates to:
  /// **'Tôi muốn gửi phản hồi hoặc khiếu nại về cách Moniary xử lý dữ liệu cá nhân của tôi.'**
  String get privacyTplComplaint;

  /// No description provided for @privacyTplDefault.
  ///
  /// In vi, this message translates to:
  /// **'Tôi cần hỗ trợ về quyền riêng tư và dữ liệu cá nhân trong Moniary.'**
  String get privacyTplDefault;

  /// No description provided for @privacyContactRequestType.
  ///
  /// In vi, this message translates to:
  /// **'Loại yêu cầu'**
  String get privacyContactRequestType;

  /// No description provided for @privacyContactRequestContent.
  ///
  /// In vi, this message translates to:
  /// **'Nội dung yêu cầu'**
  String get privacyContactRequestContent;

  /// No description provided for @privacyContactRequestHint.
  ///
  /// In vi, this message translates to:
  /// **'Mô tả ngắn điều bạn muốn team hỗ trợ.'**
  String get privacyContactRequestHint;

  /// No description provided for @privacyContactPreview.
  ///
  /// In vi, this message translates to:
  /// **'Xem trước yêu cầu'**
  String get privacyContactPreview;

  /// No description provided for @privacyContactPreviewEmpty.
  ///
  /// In vi, this message translates to:
  /// **'Chưa nhập nội dung yêu cầu.'**
  String get privacyContactPreviewEmpty;

  /// No description provided for @privacyContactProcessTimeline.
  ///
  /// In vi, this message translates to:
  /// **'Quy trình phản hồi'**
  String get privacyContactProcessTimeline;

  /// No description provided for @privacyContactProcessStep1.
  ///
  /// In vi, this message translates to:
  /// **'Tạo request trong app'**
  String get privacyContactProcessStep1;

  /// No description provided for @privacyContactProcessStep1Desc.
  ///
  /// In vi, this message translates to:
  /// **'App chuẩn bị nội dung để bạn gửi cho kênh hỗ trợ.'**
  String get privacyContactProcessStep1Desc;

  /// No description provided for @privacyContactProcessStep2.
  ///
  /// In vi, this message translates to:
  /// **'Gửi request thủ công'**
  String get privacyContactProcessStep2;

  /// No description provided for @privacyContactProcessStep2Desc.
  ///
  /// In vi, this message translates to:
  /// **'Gửi yêu cầu qua email {email}.'**
  String privacyContactProcessStep2Desc(String email);

  /// No description provided for @privacyContactProcessStep3.
  ///
  /// In vi, this message translates to:
  /// **'Theo dõi phản hồi'**
  String get privacyContactProcessStep3;

  /// No description provided for @privacyContactProcessStep3Desc.
  ///
  /// In vi, this message translates to:
  /// **'Mốc phản hồi dự kiến là {days} ngày làm việc.'**
  String privacyContactProcessStep3Desc(int days);

  /// No description provided for @privacyContactShortcuts.
  ///
  /// In vi, this message translates to:
  /// **'Lối tắt hỗ trợ'**
  String get privacyContactShortcuts;

  /// No description provided for @privacyContactCopyEmailSuccess.
  ///
  /// In vi, this message translates to:
  /// **'Đã copy email support.'**
  String get privacyContactCopyEmailSuccess;

  /// No description provided for @privacyContactCopyGuide.
  ///
  /// In vi, this message translates to:
  /// **'Email: {email}\nChủ đề: Moniary privacy request\nNội dung: Dán nội dung yêu cầu đã copy từ app.'**
  String privacyContactCopyGuide(String email);

  /// No description provided for @privacyContactCopyGuideSuccess.
  ///
  /// In vi, this message translates to:
  /// **'Đã copy hướng dẫn gửi request.'**
  String get privacyContactCopyGuideSuccess;

  /// No description provided for @privacyContactHeroTitle.
  ///
  /// In vi, this message translates to:
  /// **'Yêu cầu về dữ liệu cá nhân'**
  String get privacyContactHeroTitle;

  /// No description provided for @privacyContactHeroDesc.
  ///
  /// In vi, this message translates to:
  /// **'Nếu không thể xử lý trực tiếp trong app, người dùng có thể liên hệ team để yêu cầu hỗ trợ về dữ liệu.'**
  String get privacyContactHeroDesc;

  /// No description provided for @privacyContactEmailTitle.
  ///
  /// In vi, this message translates to:
  /// **'Email hỗ trợ'**
  String get privacyContactEmailTitle;

  /// No description provided for @privacyContactEmailDesc.
  ///
  /// In vi, this message translates to:
  /// **'Dùng cho yêu cầu xóa dữ liệu, xuất dữ liệu hoặc câu hỏi về quyền riêng tư.'**
  String get privacyContactEmailDesc;

  /// No description provided for @privacyContactInfoTitle.
  ///
  /// In vi, this message translates to:
  /// **'Thông tin cần gửi'**
  String get privacyContactInfoTitle;

  /// No description provided for @privacyContactInfoValue.
  ///
  /// In vi, this message translates to:
  /// **'User ID hoặc email đăng nhập'**
  String get privacyContactInfoValue;

  /// No description provided for @privacyContactInfoDesc.
  ///
  /// In vi, this message translates to:
  /// **'Không gửi mật khẩu, access token, ảnh hóa đơn nhạy cảm hoặc số tiền chi tiết qua email.'**
  String get privacyContactInfoDesc;

  /// No description provided for @privacyContactTimeTitle.
  ///
  /// In vi, this message translates to:
  /// **'Thời gian phản hồi'**
  String get privacyContactTimeTitle;

  /// No description provided for @privacyContactTimeValue.
  ///
  /// In vi, this message translates to:
  /// **'Trong vòng 7 ngày làm việc'**
  String get privacyContactTimeValue;

  /// No description provided for @privacyContactTimeDesc.
  ///
  /// In vi, this message translates to:
  /// **'Team cần cập nhật thời gian thực tế trước khi phát hành production.'**
  String get privacyContactTimeDesc;

  /// No description provided for @privacyContactRecentRequests.
  ///
  /// In vi, this message translates to:
  /// **'Yêu cầu gần đây'**
  String get privacyContactRecentRequests;

  /// No description provided for @privacyContactRequestStatus.
  ///
  /// In vi, this message translates to:
  /// **'Trạng thái'**
  String get privacyContactRequestStatus;

  /// No description provided for @privacyContactRequestFile.
  ///
  /// In vi, this message translates to:
  /// **'File đính kèm'**
  String get privacyContactRequestFile;

  /// No description provided for @privacyRequestSuccessDesc.
  ///
  /// In vi, this message translates to:
  /// **'Yêu cầu đã được tạo. Vui lòng kiểm tra lịch sử và gửi yêu cầu thủ công.'**
  String get privacyRequestSuccessDesc;

  /// No description provided for @privacyAndAccountTitle.
  ///
  /// In vi, this message translates to:
  /// **'Privacy & tài khoản'**
  String get privacyAndAccountTitle;

  /// No description provided for @privacyAndAccountSubtitle.
  ///
  /// In vi, this message translates to:
  /// **'Xem quyền dữ liệu, yêu cầu privacy và các lựa chọn liên quan tài khoản.'**
  String get privacyAndAccountSubtitle;

  /// No description provided for @dataRightsTitle.
  ///
  /// In vi, this message translates to:
  /// **'Quyền dữ liệu'**
  String get dataRightsTitle;

  /// No description provided for @dataRightsSubtitle.
  ///
  /// In vi, this message translates to:
  /// **'Tóm tắt quyền xem, xuất, sửa/xóa dữ liệu và liên hệ privacy.'**
  String get dataRightsSubtitle;

  /// No description provided for @exportDataSubTitle.
  ///
  /// In vi, this message translates to:
  /// **'Xử lý khi export CSV, Excel hoặc PDF lỗi, trống hoặc không tìm thấy file.'**
  String get exportDataSubTitle;

  /// No description provided for @createExportFileTitle.
  ///
  /// In vi, this message translates to:
  /// **'Tạo file export'**
  String get createExportFileTitle;

  /// No description provided for @createExportFileSubtitle.
  ///
  /// In vi, this message translates to:
  /// **'Mở luồng export khi cần tạo bản sao dữ liệu cá nhân.'**
  String get createExportFileSubtitle;

  /// No description provided for @contactSupportSubtitle.
  ///
  /// In vi, this message translates to:
  /// **'Tạo request privacy hoặc copy thông tin liên hệ để gửi cho team hỗ trợ.'**
  String get contactSupportSubtitle;

  /// No description provided for @deleteAccountSubtitle.
  ///
  /// In vi, this message translates to:
  /// **'Chuẩn bị trước khi xóa, hiểu dữ liệu bị ảnh hưởng và fallback khi có lỗi.'**
  String get deleteAccountSubtitle;

  /// No description provided for @supportChecklistTitle.
  ///
  /// In vi, this message translates to:
  /// **'Checklist gửi hỗ trợ'**
  String get supportChecklistTitle;

  /// No description provided for @supportChecklistSubtitle.
  ///
  /// In vi, this message translates to:
  /// **'Chuẩn bị mô tả lỗi, file liên quan và diagnostic info trước khi gửi request.'**
  String get supportChecklistSubtitle;

  /// No description provided for @helpHeroText.
  ///
  /// In vi, this message translates to:
  /// **'Tìm nhanh các hướng dẫn liên quan đến dữ liệu, quyền riêng tư, export và hỗ trợ tài khoản trong Moniary.'**
  String get helpHeroText;

  /// No description provided for @supportDiagnosticTitle.
  ///
  /// In vi, this message translates to:
  /// **'Thông tin gửi support'**
  String get supportDiagnosticTitle;

  /// No description provided for @supportDiagnosticSubtitle.
  ///
  /// In vi, this message translates to:
  /// **'Copy version, build và kênh liên hệ để gửi kèm khi báo lỗi.'**
  String get supportDiagnosticSubtitle;

  /// No description provided for @helpCenterTitle.
  ///
  /// In vi, this message translates to:
  /// **'Trung tâm trợ giúp'**
  String get helpCenterTitle;

  /// No description provided for @helpCenterSubtitle.
  ///
  /// In vi, this message translates to:
  /// **'Tìm hướng dẫn về privacy, tài khoản, export dữ liệu và cách liên hệ hỗ trợ.'**
  String get helpCenterSubtitle;

  /// No description provided for @aboutMoniaryTitle.
  ///
  /// In vi, this message translates to:
  /// **'Giới thiệu Moniary'**
  String get aboutMoniaryTitle;

  /// No description provided for @aboutMoniarySubtitle.
  ///
  /// In vi, this message translates to:
  /// **'Xem mục đích app, định hướng dữ liệu và trạng thái MVP trước khi phát hành.'**
  String get aboutMoniarySubtitle;

  /// No description provided for @privacyPolicySubtitle.
  ///
  /// In vi, this message translates to:
  /// **'Xem cách Moniary xử lý dữ liệu cá nhân, tài chính và ảnh giao dịch.'**
  String get privacyPolicySubtitle;

  /// No description provided for @termsOfUseTitle.
  ///
  /// In vi, this message translates to:
  /// **'Điều khoản sử dụng'**
  String get termsOfUseTitle;

  /// No description provided for @termsOfUseSubtitle.
  ///
  /// In vi, this message translates to:
  /// **'Xem phạm vi sử dụng, trách nhiệm người dùng và giới hạn của phiên bản MVP.'**
  String get termsOfUseSubtitle;

  /// No description provided for @dataRetentionPolicyTitle.
  ///
  /// In vi, this message translates to:
  /// **'Chính sách lưu giữ dữ liệu'**
  String get dataRetentionPolicyTitle;

  /// No description provided for @dataRetentionPolicySubtitle.
  ///
  /// In vi, this message translates to:
  /// **'Xem dữ liệu nào được lưu trên cloud, dữ liệu nào nằm cục bộ và cách xử lý sau khi xóa tài khoản.'**
  String get dataRetentionPolicySubtitle;

  /// No description provided for @thirdPartyServicesTitle.
  ///
  /// In vi, this message translates to:
  /// **'Dịch vụ bên thứ ba'**
  String get thirdPartyServicesTitle;

  /// No description provided for @thirdPartyServicesSubtitle.
  ///
  /// In vi, this message translates to:
  /// **'Xem app đang dùng Supabase, Flutter/package và bộ nhớ thiết bị như thế nào.'**
  String get thirdPartyServicesSubtitle;

  /// No description provided for @thirdPartyHeroBody.
  ///
  /// In vi, this message translates to:
  /// **'Thông báo này giúp người dùng hiểu app dựa vào dịch vụ nào để đăng nhập, lưu trữ và vận hành dữ liệu.'**
  String get thirdPartyHeroBody;

  /// No description provided for @thirdPartySupabaseDescription.
  ///
  /// In vi, this message translates to:
  /// **'Được dùng cho đăng nhập, cơ sở dữ liệu, storage ảnh giao dịch và edge function xóa tài khoản.'**
  String get thirdPartySupabaseDescription;

  /// No description provided for @thirdPartyFlutterDescription.
  ///
  /// In vi, this message translates to:
  /// **'Framework giao diện chính của app, kèm các package hỗ trợ điều hướng, trạng thái, camera, chọn ảnh và xử lý file.'**
  String get thirdPartyFlutterDescription;

  /// No description provided for @thirdPartyDeviceStorageTitle.
  ///
  /// In vi, this message translates to:
  /// **'Bộ nhớ thiết bị'**
  String get thirdPartyDeviceStorageTitle;

  /// No description provided for @thirdPartyDeviceStorageDescription.
  ///
  /// In vi, this message translates to:
  /// **'File export, request privacy và lịch sử export/request được ghi trong thư mục tài liệu của app trên thiết bị.'**
  String get thirdPartyDeviceStorageDescription;

  /// No description provided for @thirdPartyNoAdsTitle.
  ///
  /// In vi, this message translates to:
  /// **'Không tích hợp quảng cáo'**
  String get thirdPartyNoAdsTitle;

  /// No description provided for @thirdPartyNoAdsDescription.
  ///
  /// In vi, this message translates to:
  /// **'MVP không dùng SDK quảng cáo, tracking marketing, danh bạ, SMS, email inbox hoặc kết nối ngân hàng tự động.'**
  String get thirdPartyNoAdsDescription;

  /// No description provided for @releaseChecklistTitle.
  ///
  /// In vi, this message translates to:
  /// **'Checklist phát hành'**
  String get releaseChecklistTitle;

  /// No description provided for @releaseChecklistSubtitle.
  ///
  /// In vi, this message translates to:
  /// **'Rà soát các mục privacy, data export, xóa tài khoản và contact trước khi lên Store.'**
  String get releaseChecklistSubtitle;

  /// No description provided for @trustSafetyTitle.
  ///
  /// In vi, this message translates to:
  /// **'Tin cậy & an toàn'**
  String get trustSafetyTitle;

  /// No description provided for @trustSafetySubtitle.
  ///
  /// In vi, this message translates to:
  /// **'Xem ghi chú về giới hạn tư vấn tài chính, dữ liệu người dùng và chia sẻ file.'**
  String get trustSafetySubtitle;

  /// No description provided for @financialDisclaimerTitle.
  ///
  /// In vi, this message translates to:
  /// **'Miễn trừ tài chính'**
  String get financialDisclaimerTitle;

  /// No description provided for @financialDisclaimerSubtitle.
  ///
  /// In vi, this message translates to:
  /// **'Xem giới hạn trách nhiệm: app không phải tư vấn đầu tư, thuế, kế toán hoặc pháp lý.'**
  String get financialDisclaimerSubtitle;

  /// No description provided for @policyChangelogTitle.
  ///
  /// In vi, this message translates to:
  /// **'Lịch sử chính sách'**
  String get policyChangelogTitle;

  /// No description provided for @policyChangelogSubtitle.
  ///
  /// In vi, this message translates to:
  /// **'Xem các mốc cập nhật privacy, legal và store readiness trong app.'**
  String get policyChangelogSubtitle;

  /// No description provided for @userDataRightsTitle.
  ///
  /// In vi, this message translates to:
  /// **'Quyền dữ liệu của người dùng'**
  String get userDataRightsTitle;

  /// No description provided for @userDataRightsSubtitle.
  ///
  /// In vi, this message translates to:
  /// **'Tóm tắt quyền xem dữ liệu, xuất dữ liệu, yêu cầu sửa/xóa và liên hệ privacy.'**
  String get userDataRightsSubtitle;

  /// No description provided for @policyAcceptanceNoticeTitle.
  ///
  /// In vi, this message translates to:
  /// **'Thông báo đồng ý chính sách'**
  String get policyAcceptanceNoticeTitle;

  /// No description provided for @policyAcceptanceNoticeSubtitle.
  ///
  /// In vi, this message translates to:
  /// **'Giải thích rằng việc tiếp tục sử dụng app áp dụng theo chính sách và điều khoản hiện tại.'**
  String get policyAcceptanceNoticeSubtitle;

  /// No description provided for @policyAcceptanceHero.
  ///
  /// In vi, this message translates to:
  /// **'Thông báo này giúp người dùng hiểu rằng các chính sách hiện tại áp dụng khi tiếp tục sử dụng Moniary.'**
  String get policyAcceptanceHero;

  /// No description provided for @policyAcceptanceBody.
  ///
  /// In vi, this message translates to:
  /// **'Khi tiếp tục dùng Moniary, người dùng xác nhận đã có cơ hội đọc Chính sách bảo mật, Điều khoản sử dụng, thông báo lưu giữ dữ liệu và các ghi chú an toàn liên quan.'**
  String get policyAcceptanceBody;

  /// No description provided for @legalContactTitle.
  ///
  /// In vi, this message translates to:
  /// **'Liên hệ pháp lý'**
  String get legalContactTitle;

  /// No description provided for @legalContactSubtitle.
  ///
  /// In vi, this message translates to:
  /// **'Xem và copy email privacy, support và legal dùng cho phát hành Store.'**
  String get legalContactSubtitle;

  /// No description provided for @dataSafetyTitle.
  ///
  /// In vi, this message translates to:
  /// **'An toàn dữ liệu'**
  String get dataSafetyTitle;

  /// No description provided for @dataSafetySubtitle.
  ///
  /// In vi, this message translates to:
  /// **'Tóm tắt các nhóm dữ liệu được thu thập hoặc không thu thập trong MVP.'**
  String get dataSafetySubtitle;

  /// No description provided for @myDataTitle.
  ///
  /// In vi, this message translates to:
  /// **'Dữ liệu của tôi'**
  String get myDataTitle;

  /// No description provided for @myDataSubtitle.
  ///
  /// In vi, this message translates to:
  /// **'Xem nhanh app đang lưu bao nhiêu dữ liệu trong tài khoản này.'**
  String get myDataSubtitle;

  /// No description provided for @permissionsTitle.
  ///
  /// In vi, this message translates to:
  /// **'Quyền truy cập'**
  String get permissionsTitle;

  /// No description provided for @permissionsSubtitle.
  ///
  /// In vi, this message translates to:
  /// **'Giải thích lý do Moniary dùng hoặc không dùng từng quyền Android.'**
  String get permissionsSubtitle;

  /// No description provided for @exportMyDataTitle.
  ///
  /// In vi, this message translates to:
  /// **'Xuất dữ liệu của tôi'**
  String get exportMyDataTitle;

  /// No description provided for @exportMyDataSubtitle.
  ///
  /// In vi, this message translates to:
  /// **'Chọn định dạng file và tạo bản sao dữ liệu cá nhân.'**
  String get exportMyDataSubtitle;

  /// No description provided for @exportHistorySubtitle.
  ///
  /// In vi, this message translates to:
  /// **'Xem các file CSV, Excel hoặc PDF đã tạo từ tài khoản này.'**
  String get exportHistorySubtitle;

  /// No description provided for @deleteAccountSubtitle2.
  ///
  /// In vi, this message translates to:
  /// **'Xóa hồ sơ, ví, danh mục, giao dịch và ảnh giao dịch đã lưu.'**
  String get deleteAccountSubtitle2;

  /// No description provided for @dataDeletionPolicyTitle.
  ///
  /// In vi, this message translates to:
  /// **'Chính sách xóa dữ liệu'**
  String get dataDeletionPolicyTitle;

  /// No description provided for @dataDeletionPolicySubtitle.
  ///
  /// In vi, this message translates to:
  /// **'Xem dữ liệu nào bị xóa và cách Moniary xử lý yêu cầu xóa.'**
  String get dataDeletionPolicySubtitle;

  /// No description provided for @dataDeletionRequestTitle.
  ///
  /// In vi, this message translates to:
  /// **'Yêu cầu xóa dữ liệu'**
  String get dataDeletionRequestTitle;

  /// No description provided for @dataDeletionRequestSubtitle.
  ///
  /// In vi, this message translates to:
  /// **'Tạo file yêu cầu xóa thủ công nếu xóa trực tiếp không thành công.'**
  String get dataDeletionRequestSubtitle;

  /// No description provided for @privacyContactTitle.
  ///
  /// In vi, this message translates to:
  /// **'Liên hệ quyền riêng tư'**
  String get privacyContactTitle;

  /// No description provided for @privacyContactSubtitle.
  ///
  /// In vi, this message translates to:
  /// **'Kênh hỗ trợ cho yêu cầu dữ liệu, xóa dữ liệu hoặc câu hỏi privacy.'**
  String get privacyContactSubtitle;

  /// No description provided for @trustHeroText.
  ///
  /// In vi, this message translates to:
  /// **'Các ghi chú này giúp người dùng hiểu rõ app làm gì, không làm gì và nên bảo vệ dữ liệu tài chính cá nhân ra sao.'**
  String get trustHeroText;

  /// No description provided for @notFinancialAdviceTitle.
  ///
  /// In vi, this message translates to:
  /// **'Không phải tư vấn tài chính'**
  String get notFinancialAdviceTitle;

  /// No description provided for @notFinancialAdviceDesc.
  ///
  /// In vi, this message translates to:
  /// **'Moniary chỉ giúp ghi chép và xem lại dữ liệu thu chi cá nhân. App không đưa ra lời khuyên đầu tư, thuế hoặc kế toán.'**
  String get notFinancialAdviceDesc;

  /// No description provided for @userEnteredDataTitle.
  ///
  /// In vi, this message translates to:
  /// **'Dữ liệu do người dùng nhập'**
  String get userEnteredDataTitle;

  /// No description provided for @userEnteredDataDesc.
  ///
  /// In vi, this message translates to:
  /// **'Số tiền, ghi chú, danh mục và ảnh giao dịch phụ thuộc vào dữ liệu người dùng tạo trong app.'**
  String get userEnteredDataDesc;

  /// No description provided for @noOverCollectionTitle.
  ///
  /// In vi, this message translates to:
  /// **'Không thu thập ngoài phạm vi'**
  String get noOverCollectionTitle;

  /// No description provided for @noOverCollectionDesc.
  ///
  /// In vi, this message translates to:
  /// **'MVP không đọc danh bạ, SMS, email inbox, vị trí hoặc tài khoản ngân hàng tự động.'**
  String get noOverCollectionDesc;

  /// No description provided for @carefulFileSharingTitle.
  ///
  /// In vi, this message translates to:
  /// **'Cẩn thận khi chia sẻ file'**
  String get carefulFileSharingTitle;

  /// No description provided for @carefulFileSharingDesc.
  ///
  /// In vi, this message translates to:
  /// **'File export có thể chứa dữ liệu tài chính cá nhân. Chỉ chia sẻ với người hoặc kênh hỗ trợ đáng tin cậy.'**
  String get carefulFileSharingDesc;

  /// No description provided for @exportDataTitle.
  ///
  /// In vi, this message translates to:
  /// **'Xuất dữ liệu'**
  String get exportDataTitle;

  /// No description provided for @supportContactTitle.
  ///
  /// In vi, this message translates to:
  /// **'Liên hệ hỗ trợ'**
  String get supportContactTitle;

  /// No description provided for @importSuccessWithHistoryError.
  ///
  /// In vi, this message translates to:
  /// **'Đã import thành công {count} giao dịch, nhưng lỗi khi lưu lịch sử cục bộ.'**
  String importSuccessWithHistoryError(int count);

  /// No description provided for @legalCopyContactValue.
  ///
  /// In vi, this message translates to:
  /// **'Đã copy {value}'**
  String legalCopyContactValue(String value);

  /// No description provided for @storeComplianceHero.
  ///
  /// In vi, this message translates to:
  /// **'Các mục dưới đây giúp rà soát nhanh những phần người dùng và reviewer cần thấy trước khi app được phát hành.'**
  String get storeComplianceHero;

  /// No description provided for @storeCompliancePrivacyTitle.
  ///
  /// In vi, this message translates to:
  /// **'Chính sách bảo mật'**
  String get storeCompliancePrivacyTitle;

  /// No description provided for @storeCompliancePrivacyDesc.
  ///
  /// In vi, this message translates to:
  /// **'Có màn privacy policy mô tả dữ liệu tài chính, ảnh giao dịch và cách xử lý dữ liệu.'**
  String get storeCompliancePrivacyDesc;

  /// No description provided for @storeComplianceDeleteTitle.
  ///
  /// In vi, this message translates to:
  /// **'Xóa tài khoản'**
  String get storeComplianceDeleteTitle;

  /// No description provided for @storeComplianceDeleteDesc.
  ///
  /// In vi, this message translates to:
  /// **'Có luồng xóa tài khoản trong app và fallback tạo request thủ công.'**
  String get storeComplianceDeleteDesc;

  /// No description provided for @storeComplianceExportTitle.
  ///
  /// In vi, this message translates to:
  /// **'Xuất dữ liệu'**
  String get storeComplianceExportTitle;

  /// No description provided for @storeComplianceExportDesc.
  ///
  /// In vi, this message translates to:
  /// **'Người dùng có thể export dữ liệu CSV, Excel hoặc PDF trước khi rời app.'**
  String get storeComplianceExportDesc;

  /// No description provided for @storeComplianceDataSafetyTitle.
  ///
  /// In vi, this message translates to:
  /// **'Data Safety'**
  String get storeComplianceDataSafetyTitle;

  /// No description provided for @storeComplianceDataSafetyDesc.
  ///
  /// In vi, this message translates to:
  /// **'Có phần tóm tắt nhóm dữ liệu được lưu và nhóm dữ liệu app không thu thập.'**
  String get storeComplianceDataSafetyDesc;

  /// No description provided for @storeComplianceContactTitle.
  ///
  /// In vi, this message translates to:
  /// **'Liên hệ privacy'**
  String get storeComplianceContactTitle;

  /// No description provided for @storeComplianceContactDesc.
  ///
  /// In vi, this message translates to:
  /// **'Có kênh hỗ trợ, request history và trạng thái xử lý yêu cầu privacy.'**
  String get storeComplianceContactDesc;

  /// No description provided for @storeComplianceTermsTitle.
  ///
  /// In vi, this message translates to:
  /// **'Điều khoản sử dụng'**
  String get storeComplianceTermsTitle;

  /// No description provided for @storeComplianceTermsDesc.
  ///
  /// In vi, this message translates to:
  /// **'Có terms of use và ghi chú giới hạn trách nhiệm của app MVP.'**
  String get storeComplianceTermsDesc;

  /// No description provided for @privacyNoData.
  ///
  /// In vi, this message translates to:
  /// **'Chưa có dữ liệu'**
  String get privacyNoData;

  /// No description provided for @privacyDataOverview.
  ///
  /// In vi, this message translates to:
  /// **'Tổng quan dữ liệu'**
  String get privacyDataOverview;

  /// No description provided for @privacyDataInventory.
  ///
  /// In vi, this message translates to:
  /// **'Nhóm dữ liệu đang lưu'**
  String get privacyDataInventory;

  /// No description provided for @privacySensitiveData.
  ///
  /// In vi, this message translates to:
  /// **'Lưu ý dữ liệu nhạy cảm'**
  String get privacySensitiveData;

  /// No description provided for @privacyTransparencyReport.
  ///
  /// In vi, this message translates to:
  /// **'Báo cáo minh bạch'**
  String get privacyTransparencyReport;

  /// No description provided for @privacyDataControl.
  ///
  /// In vi, this message translates to:
  /// **'Kiểm soát dữ liệu'**
  String get privacyDataControl;

  /// No description provided for @metricTransaction.
  ///
  /// In vi, this message translates to:
  /// **'Giao dịch'**
  String get metricTransaction;

  /// No description provided for @metricWallet.
  ///
  /// In vi, this message translates to:
  /// **'Ví'**
  String get metricWallet;

  /// No description provided for @metricCategory.
  ///
  /// In vi, this message translates to:
  /// **'Danh mục'**
  String get metricCategory;

  /// No description provided for @metricHasPhoto.
  ///
  /// In vi, this message translates to:
  /// **'Có ảnh'**
  String get metricHasPhoto;

  /// No description provided for @metricNoPhoto.
  ///
  /// In vi, this message translates to:
  /// **'Không ảnh'**
  String get metricNoPhoto;

  /// No description provided for @inventoryProfileTitle.
  ///
  /// In vi, this message translates to:
  /// **'Hồ sơ tài khoản'**
  String get inventoryProfileTitle;

  /// No description provided for @inventoryProfileDesc.
  ///
  /// In vi, this message translates to:
  /// **'Tên hiển thị, email, avatar, timezone và trạng thái đăng nhập.'**
  String get inventoryProfileDesc;

  /// No description provided for @inventoryWalletTitle.
  ///
  /// In vi, this message translates to:
  /// **'Ví'**
  String get inventoryWalletTitle;

  /// No description provided for @inventoryWalletDesc.
  ///
  /// In vi, this message translates to:
  /// **'Tên ví, loại ví, số dư ban đầu, trạng thái mặc định và hiển thị.'**
  String get inventoryWalletDesc;

  /// No description provided for @inventoryCategoryTitle.
  ///
  /// In vi, this message translates to:
  /// **'Danh mục'**
  String get inventoryCategoryTitle;

  /// No description provided for @inventoryCategoryDesc.
  ///
  /// In vi, this message translates to:
  /// **'Tên danh mục, loại thu/chi, trạng thái mặc định và hiển thị.'**
  String get inventoryCategoryDesc;

  /// No description provided for @inventoryTransactionTitle.
  ///
  /// In vi, this message translates to:
  /// **'Giao dịch'**
  String get inventoryTransactionTitle;

  /// No description provided for @inventoryTransactionDesc.
  ///
  /// In vi, this message translates to:
  /// **'Số tiền, loại giao dịch, ví, danh mục, ghi chú và ngày giờ.'**
  String get inventoryTransactionDesc;

  /// No description provided for @inventoryPhotoTitle.
  ///
  /// In vi, this message translates to:
  /// **'Ảnh giao dịch'**
  String get inventoryPhotoTitle;

  /// No description provided for @inventoryPhotoDesc.
  ///
  /// In vi, this message translates to:
  /// **'Đường dẫn ảnh trong Storage private bucket, hiển thị qua signed URL.'**
  String get inventoryPhotoDesc;

  /// No description provided for @inventorySettingsTitle.
  ///
  /// In vi, this message translates to:
  /// **'Thiết lập nhắc nhở'**
  String get inventorySettingsTitle;

  /// No description provided for @inventorySettingsDesc.
  ///
  /// In vi, this message translates to:
  /// **'Các tùy chọn nhắc ghi chi tiêu khi tính năng reminder được bật.'**
  String get inventorySettingsDesc;

  /// No description provided for @sensitiveDataDesc.
  ///
  /// In vi, this message translates to:
  /// **'Dữ liệu tài chính có thể gồm số tiền, ghi chú, ảnh hóa đơn và file đã xuất. Chỉ chia sẻ file export với người bạn tin cậy và xóa file cục bộ khi không còn cần dùng.'**
  String get sensitiveDataDesc;

  /// No description provided for @localFilesExportCount.
  ///
  /// In vi, this message translates to:
  /// **'{count} file đã xuất'**
  String localFilesExportCount(int count);

  /// No description provided for @localFilesLatest.
  ///
  /// In vi, this message translates to:
  /// **'Gần nhất: {date}'**
  String localFilesLatest(String date);

  /// No description provided for @localFilesNoExport.
  ///
  /// In vi, this message translates to:
  /// **'Chưa có file export'**
  String get localFilesNoExport;

  /// No description provided for @localFilesDesc.
  ///
  /// In vi, this message translates to:
  /// **'Các file CSV, Excel và PDF được tạo trên thiết bị này. Bạn có thể mở lại, chia sẻ hoặc tự xóa file trong bộ nhớ cục bộ.'**
  String get localFilesDesc;

  /// No description provided for @reportSummaryDesc.
  ///
  /// In vi, this message translates to:
  /// **'Tài khoản này hiện có {txs} giao dịch, {wallets} ví và {categories} danh mục.'**
  String reportSummaryDesc(int txs, int wallets, int categories);

  /// No description provided for @reportPhotoDesc.
  ///
  /// In vi, this message translates to:
  /// **'{percent}% giao dịch đang có ảnh đính kèm trong dữ liệu của bạn.'**
  String reportPhotoDesc(int percent);

  /// No description provided for @reportExportDesc.
  ///
  /// In vi, this message translates to:
  /// **'{count} file export đã được ghi nhận trên thiết bị này.'**
  String reportExportDesc(int count);

  /// No description provided for @reportPrivacyDesc.
  ///
  /// In vi, this message translates to:
  /// **'Moniary không bán dữ liệu cá nhân và chỉ dùng dữ liệu để vận hành trải nghiệm quản lý chi tiêu.'**
  String get reportPrivacyDesc;

  /// No description provided for @controlExportTitle.
  ///
  /// In vi, this message translates to:
  /// **'Xuất dữ liệu'**
  String get controlExportTitle;

  /// No description provided for @controlExportDesc.
  ///
  /// In vi, this message translates to:
  /// **'Tạo file CSV, Excel hoặc PDF từ dữ liệu tài khoản.'**
  String get controlExportDesc;

  /// No description provided for @controlContactTitle.
  ///
  /// In vi, this message translates to:
  /// **'Liên hệ quyền riêng tư'**
  String get controlContactTitle;

  /// No description provided for @controlContactDesc.
  ///
  /// In vi, this message translates to:
  /// **'Tạo yêu cầu hỗ trợ về dữ liệu, quyền riêng tư hoặc xóa dữ liệu.'**
  String get controlContactDesc;

  /// No description provided for @controlDeleteTitle.
  ///
  /// In vi, this message translates to:
  /// **'Xóa tài khoản'**
  String get controlDeleteTitle;

  /// No description provided for @controlDeleteDesc.
  ///
  /// In vi, this message translates to:
  /// **'Mở xác nhận xóa tài khoản và toàn bộ dữ liệu liên quan.'**
  String get controlDeleteDesc;

  /// No description provided for @freshOldestTx.
  ///
  /// In vi, this message translates to:
  /// **'Giao dịch cũ nhất'**
  String get freshOldestTx;

  /// No description provided for @freshNewestTx.
  ///
  /// In vi, this message translates to:
  /// **'Giao dịch mới nhất'**
  String get freshNewestTx;

  /// No description provided for @freshLatestExport.
  ///
  /// In vi, this message translates to:
  /// **'Lần xuất dữ liệu gần nhất'**
  String get freshLatestExport;

  /// No description provided for @supportChecklistHero.
  ///
  /// In vi, this message translates to:
  /// **'Chuẩn bị đủ thông tin trước khi gửi yêu cầu giúp team hỗ trợ nhanh hơn và tránh chia sẻ dữ liệu nhạy cảm không cần thiết.'**
  String get supportChecklistHero;

  /// No description provided for @supportChecklistActionTitle.
  ///
  /// In vi, this message translates to:
  /// **'Mô tả thao tác đã làm'**
  String get supportChecklistActionTitle;

  /// No description provided for @supportChecklistActionDesc.
  ///
  /// In vi, this message translates to:
  /// **'Ghi rõ bạn đang export, xóa tài khoản, tạo request hay mở file nào.'**
  String get supportChecklistActionDesc;

  /// No description provided for @supportChecklistErrorTitle.
  ///
  /// In vi, this message translates to:
  /// **'Thêm thông báo lỗi nếu có'**
  String get supportChecklistErrorTitle;

  /// No description provided for @supportChecklistErrorDesc.
  ///
  /// In vi, this message translates to:
  /// **'Copy nội dung lỗi hoặc mô tả màn hình đang hiển thị để team dễ kiểm tra.'**
  String get supportChecklistErrorDesc;

  /// No description provided for @supportChecklistFileTitle.
  ///
  /// In vi, this message translates to:
  /// **'Đính kèm file request/export khi phù hợp'**
  String get supportChecklistFileTitle;

  /// No description provided for @supportChecklistFileDesc.
  ///
  /// In vi, this message translates to:
  /// **'Nếu là yêu cầu privacy hoặc xóa dữ liệu thủ công, gửi kèm file JSON đã tạo.'**
  String get supportChecklistFileDesc;

  /// No description provided for @supportChecklistDiagnosticTitle.
  ///
  /// In vi, this message translates to:
  /// **'Copy diagnostic info'**
  String get supportChecklistDiagnosticTitle;

  /// No description provided for @supportChecklistDiagnosticDesc.
  ///
  /// In vi, this message translates to:
  /// **'Gửi kèm version, build và kênh release từ Trung tâm trợ giúp.'**
  String get supportChecklistDiagnosticDesc;

  /// No description provided for @supportChecklistSensitiveTitle.
  ///
  /// In vi, this message translates to:
  /// **'Không gửi dữ liệu quá nhạy cảm'**
  String get supportChecklistSensitiveTitle;

  /// No description provided for @supportChecklistSensitiveDesc.
  ///
  /// In vi, this message translates to:
  /// **'Không gửi mật khẩu, access token hoặc ảnh hóa đơn nhạy cảm nếu không thật sự cần thiết.'**
  String get supportChecklistSensitiveDesc;

  /// No description provided for @dataSafetyPersonalInfoTitle.
  ///
  /// In vi, this message translates to:
  /// **'Personal info'**
  String get dataSafetyPersonalInfoTitle;

  /// No description provided for @dataSafetyPersonalInfoStatus.
  ///
  /// In vi, this message translates to:
  /// **'Có, khi đăng nhập email hoặc Google'**
  String get dataSafetyPersonalInfoStatus;

  /// No description provided for @dataSafetyPersonalInfoDesc.
  ///
  /// In vi, this message translates to:
  /// **'Tên hiển thị, email, avatar và user ID dùng cho đăng nhập và đồng bộ dữ liệu.'**
  String get dataSafetyPersonalInfoDesc;

  /// No description provided for @dataSafetyFinancialInfoTitle.
  ///
  /// In vi, this message translates to:
  /// **'Financial info'**
  String get dataSafetyFinancialInfoTitle;

  /// No description provided for @dataSafetyFinancialInfoStatus.
  ///
  /// In vi, this message translates to:
  /// **'Có'**
  String get dataSafetyFinancialInfoStatus;

  /// No description provided for @dataSafetyFinancialInfoDesc.
  ///
  /// In vi, this message translates to:
  /// **'Ví, danh mục, số tiền, ghi chú và ngày giao dịch do người dùng nhập.'**
  String get dataSafetyFinancialInfoDesc;

  /// No description provided for @dataSafetyPhotosTitle.
  ///
  /// In vi, this message translates to:
  /// **'Photos'**
  String get dataSafetyPhotosTitle;

  /// No description provided for @dataSafetyPhotosStatus.
  ///
  /// In vi, this message translates to:
  /// **'Có, khi người dùng chủ động chọn/chụp'**
  String get dataSafetyPhotosStatus;

  /// No description provided for @dataSafetyPhotosDesc.
  ///
  /// In vi, this message translates to:
  /// **'Ảnh giao dịch được lưu trong private storage và chỉ hiển thị qua signed URL.'**
  String get dataSafetyPhotosDesc;

  /// No description provided for @dataSafetyUserIdTitle.
  ///
  /// In vi, this message translates to:
  /// **'User ID'**
  String get dataSafetyUserIdTitle;

  /// No description provided for @dataSafetyUserIdStatus.
  ///
  /// In vi, this message translates to:
  /// **'Có'**
  String get dataSafetyUserIdStatus;

  /// No description provided for @dataSafetyUserIdDesc.
  ///
  /// In vi, this message translates to:
  /// **'Dùng để gắn dữ liệu với đúng tài khoản và áp dụng RLS trên Supabase.'**
  String get dataSafetyUserIdDesc;

  /// No description provided for @dataSafetyLocationTitle.
  ///
  /// In vi, this message translates to:
  /// **'Location, Contacts, SMS'**
  String get dataSafetyLocationTitle;

  /// No description provided for @dataSafetyLocationStatus.
  ///
  /// In vi, this message translates to:
  /// **'Không thu thập trong MVP'**
  String get dataSafetyLocationStatus;

  /// No description provided for @dataSafetyLocationDesc.
  ///
  /// In vi, this message translates to:
  /// **'Moniary không xin quyền vị trí, danh bạ hoặc đọc SMS/email để import giao dịch.'**
  String get dataSafetyLocationDesc;

  /// No description provided for @aboutMoniaryHeroTitle.
  ///
  /// In vi, this message translates to:
  /// **'Moniary'**
  String get aboutMoniaryHeroTitle;

  /// No description provided for @aboutMoniaryHeroDesc.
  ///
  /// In vi, this message translates to:
  /// **'Sổ tay thu chi cá nhân có kiểm soát dữ liệu rõ ràng cho người dùng.'**
  String get aboutMoniaryHeroDesc;

  /// No description provided for @aboutMoniaryVersionLabel.
  ///
  /// In vi, this message translates to:
  /// **'Phiên bản'**
  String get aboutMoniaryVersionLabel;

  /// No description provided for @aboutMoniaryBuildLabel.
  ///
  /// In vi, this message translates to:
  /// **'Build'**
  String get aboutMoniaryBuildLabel;

  /// No description provided for @aboutMoniaryChannelLabel.
  ///
  /// In vi, this message translates to:
  /// **'Kênh phát hành'**
  String get aboutMoniaryChannelLabel;

  /// No description provided for @aboutMoniaryLicenseTitle.
  ///
  /// In vi, this message translates to:
  /// **'Giấy phép mã nguồn mở'**
  String get aboutMoniaryLicenseTitle;

  /// No description provided for @aboutMoniaryLicenseDesc.
  ///
  /// In vi, this message translates to:
  /// **'Xem license của Flutter và các package đang dùng trong app.'**
  String get aboutMoniaryLicenseDesc;

  /// No description provided for @aboutMoniaryPurposeTitle.
  ///
  /// In vi, this message translates to:
  /// **'Mục đích'**
  String get aboutMoniaryPurposeTitle;

  /// No description provided for @aboutMoniaryPurposeDesc.
  ///
  /// In vi, this message translates to:
  /// **'Moniary giúp người dùng ghi lại thu chi cá nhân, quản lý ví, danh mục và ảnh giao dịch trong một trải nghiệm đơn giản.'**
  String get aboutMoniaryPurposeDesc;

  /// No description provided for @aboutMoniaryDataDirTitle.
  ///
  /// In vi, this message translates to:
  /// **'Định hướng dữ liệu'**
  String get aboutMoniaryDataDirTitle;

  /// No description provided for @aboutMoniaryDataDirDesc.
  ///
  /// In vi, this message translates to:
  /// **'Dữ liệu tài chính thuộc về người dùng. App cung cấp công cụ xuất dữ liệu, xóa tài khoản và liên hệ privacy khi cần hỗ trợ.'**
  String get aboutMoniaryDataDirDesc;

  /// No description provided for @aboutMoniaryMvpStatusTitle.
  ///
  /// In vi, this message translates to:
  /// **'Trạng thái MVP'**
  String get aboutMoniaryMvpStatusTitle;

  /// No description provided for @aboutMoniaryMvpStatusDesc.
  ///
  /// In vi, this message translates to:
  /// **'Phiên bản hiện tại tập trung vào ghi chép chi tiêu, minh bạch dữ liệu và các yêu cầu cần thiết để chuẩn bị phát hành Store.'**
  String get aboutMoniaryMvpStatusDesc;

  /// No description provided for @permissionInternetTitle.
  ///
  /// In vi, this message translates to:
  /// **'Internet'**
  String get permissionInternetTitle;

  /// No description provided for @permissionInternetStatus.
  ///
  /// In vi, this message translates to:
  /// **'Cần thiết'**
  String get permissionInternetStatus;

  /// No description provided for @permissionInternetDesc.
  ///
  /// In vi, this message translates to:
  /// **'Dùng để đăng nhập, đồng bộ Supabase Database và tải ảnh giao dịch từ Storage.'**
  String get permissionInternetDesc;

  /// No description provided for @permissionCameraTitle.
  ///
  /// In vi, this message translates to:
  /// **'Camera'**
  String get permissionCameraTitle;

  /// No description provided for @permissionCameraStatus.
  ///
  /// In vi, this message translates to:
  /// **'Chỉ hỏi khi người dùng chụp ảnh'**
  String get permissionCameraStatus;

  /// No description provided for @permissionCameraDesc.
  ///
  /// In vi, this message translates to:
  /// **'Dùng để chụp hóa đơn hoặc hình ảnh liên quan đến giao dịch.'**
  String get permissionCameraDesc;

  /// No description provided for @permissionPhotoTitle.
  ///
  /// In vi, this message translates to:
  /// **'Photo Picker'**
  String get permissionPhotoTitle;

  /// No description provided for @permissionPhotoStatus.
  ///
  /// In vi, this message translates to:
  /// **'Chỉ mở khi người dùng chọn ảnh'**
  String get permissionPhotoStatus;

  /// No description provided for @permissionPhotoDesc.
  ///
  /// In vi, this message translates to:
  /// **'Dùng Android Photo Picker để chọn ảnh mà không cần đọc toàn bộ thư viện.'**
  String get permissionPhotoDesc;

  /// No description provided for @permissionNotiTitle.
  ///
  /// In vi, this message translates to:
  /// **'Notifications'**
  String get permissionNotiTitle;

  /// No description provided for @permissionNotiStatus.
  ///
  /// In vi, this message translates to:
  /// **'Chỉ dùng khi bật nhắc nhở'**
  String get permissionNotiStatus;

  /// No description provided for @permissionNotiDesc.
  ///
  /// In vi, this message translates to:
  /// **'MVP hiện không bắt buộc quyền này nếu chưa triển khai reminder production.'**
  String get permissionNotiDesc;

  /// No description provided for @permissionLocationTitle.
  ///
  /// In vi, this message translates to:
  /// **'Không dùng Location, Contacts, SMS'**
  String get permissionLocationTitle;

  /// No description provided for @permissionLocationStatus.
  ///
  /// In vi, this message translates to:
  /// **'Không khai báo trong MVP'**
  String get permissionLocationStatus;

  /// No description provided for @permissionLocationDesc.
  ///
  /// In vi, this message translates to:
  /// **'Moniary không cần vị trí, danh bạ hoặc SMS để ghi chi tiêu bằng ảnh.'**
  String get permissionLocationDesc;

  /// No description provided for @privacyPolicyLeadTitle.
  ///
  /// In vi, this message translates to:
  /// **'Moniary bảo vệ dữ liệu chi tiêu cá nhân của bạn.'**
  String get privacyPolicyLeadTitle;

  /// No description provided for @privacyPolicyLeadDesc.
  ///
  /// In vi, this message translates to:
  /// **'Nội dung này dùng cho màn hình trong app và làm bản nháp public Privacy Policy trước khi submit Google Play.'**
  String get privacyPolicyLeadDesc;

  /// No description provided for @privacyPolicyDataTitle.
  ///
  /// In vi, this message translates to:
  /// **'Dữ liệu Moniary xử lý'**
  String get privacyPolicyDataTitle;

  /// No description provided for @privacyPolicyDataItem1.
  ///
  /// In vi, this message translates to:
  /// **'Thông tự tài khoản như tên hiển thị, email, avatar và user ID khi người dùng đăng nhập.'**
  String get privacyPolicyDataItem1;

  /// No description provided for @privacyPolicyDataItem2.
  ///
  /// In vi, this message translates to:
  /// **'Dữ liệu tài chính do người dùng nhập gồm ví, danh mục, giao dịch, số tiền, ghi chú và ngày giờ.'**
  String get privacyPolicyDataItem2;

  /// No description provided for @privacyPolicyDataItem3.
  ///
  /// In vi, this message translates to:
  /// **'Ảnh giao dịch do người dùng chụp hoặc chọn từ thiết bị.'**
  String get privacyPolicyDataItem3;

  /// No description provided for @privacyPolicyDataItem4.
  ///
  /// In vi, this message translates to:
  /// **'Thiết lập ứng dụng như nhắc nhở và tùy chọn hồ sơ.'**
  String get privacyPolicyDataItem4;

  /// No description provided for @privacyPolicyPurposeTitle.
  ///
  /// In vi, this message translates to:
  /// **'Mục đích sử dụng'**
  String get privacyPolicyPurposeTitle;

  /// No description provided for @privacyPolicyPurposeItem1.
  ///
  /// In vi, this message translates to:
  /// **'Đăng nhập, đồng bộ dữ liệu và khôi phục dữ liệu khi đổi thiết bị.'**
  String get privacyPolicyPurposeItem1;

  /// No description provided for @privacyPolicyPurposeItem2.
  ///
  /// In vi, this message translates to:
  /// **'Hiển thị lịch chi tiêu, chi tiết giao dịch, bộ lọc và thống kê tháng.'**
  String get privacyPolicyPurposeItem2;

  /// No description provided for @privacyPolicyPurposeItem3.
  ///
  /// In vi, this message translates to:
  /// **'Lưu ảnh giao dịch trong Supabase Storage private bucket và cấp signed URL khi cần hiển thị.'**
  String get privacyPolicyPurposeItem3;

  /// No description provided for @privacyPolicyPurposeItem4.
  ///
  /// In vi, this message translates to:
  /// **'Bảo vệ tài khoản, kiểm soát truy cập bằng RLS và hỗ trợ người dùng khi có yêu cầu.'**
  String get privacyPolicyPurposeItem4;

  /// No description provided for @privacyPolicyShareTitle.
  ///
  /// In vi, this message translates to:
  /// **'Chia sẻ dữ liệu'**
  String get privacyPolicyShareTitle;

  /// No description provided for @privacyPolicyShareItem1.
  ///
  /// In vi, this message translates to:
  /// **'Moniary không bán dữ liệu cá nhân hoặc dữ liệu tài chính của người dùng.'**
  String get privacyPolicyShareItem1;

  /// No description provided for @privacyPolicyShareItem2.
  ///
  /// In vi, this message translates to:
  /// **'Dữ liệu được lưu trên Supabase để cung cấp Auth, Database và Storage cho ứng dụng.'**
  String get privacyPolicyShareItem2;

  /// No description provided for @privacyPolicyShareItem3.
  ///
  /// In vi, this message translates to:
  /// **'MVP không đọc vị trí, danh bạ, SMS, email cá nhân hoặc dữ liệu ngân hàng tự động.'**
  String get privacyPolicyShareItem3;

  /// No description provided for @privacyPolicyDeleteTitle.
  ///
  /// In vi, this message translates to:
  /// **'Xóa dữ liệu'**
  String get privacyPolicyDeleteTitle;

  /// No description provided for @privacyPolicyDeleteItem1.
  ///
  /// In vi, this message translates to:
  /// **'Người dùng có thể xóa từng giao dịch trong app.'**
  String get privacyPolicyDeleteItem1;

  /// No description provided for @privacyPolicyDeleteItem2.
  ///
  /// In vi, this message translates to:
  /// **'Người dùng có thể xuất dữ liệu CSV trước khi xóa tài khoản.'**
  String get privacyPolicyDeleteItem2;

  /// No description provided for @privacyPolicyDeleteItem3.
  ///
  /// In vi, this message translates to:
  /// **'Khi xóa tài khoản, Moniary yêu cầu xóa hồ sơ, ví, danh mục, giao dịch và ảnh trong Storage thuộc user ID hiện tại.'**
  String get privacyPolicyDeleteItem3;

  /// No description provided for @privacyPolicySafetyTitle.
  ///
  /// In vi, this message translates to:
  /// **'Khai báo Google Play Data Safety'**
  String get privacyPolicySafetyTitle;

  /// No description provided for @privacyPolicySafetyItem1.
  ///
  /// In vi, this message translates to:
  /// **'Personal info: chỉ thu thập khi người dùng đăng nhập bằng email hoặc Google.'**
  String get privacyPolicySafetyItem1;

  /// No description provided for @privacyPolicySafetyItem2.
  ///
  /// In vi, this message translates to:
  /// **'Financial info: thu thập để lưu và hiển thị thu chi cá nhân.'**
  String get privacyPolicySafetyItem2;

  /// No description provided for @privacyPolicySafetyItem3.
  ///
  /// In vi, this message translates to:
  /// **'Photos: chỉ thu thập ảnh người dùng chủ động chụp hoặc chọn.'**
  String get privacyPolicySafetyItem3;

  /// No description provided for @privacyPolicySafetyItem4.
  ///
  /// In vi, this message translates to:
  /// **'Location, Contacts, SMS: không thu thập trong MVP.'**
  String get privacyPolicySafetyItem4;

  /// No description provided for @privacyPolicyContactDesc.
  ///
  /// In vi, this message translates to:
  /// **'Trước khi phát hành, team cần đưa nội dung này lên một URL public và cập nhật email liên hệ chính thức trong Play Console.'**
  String get privacyPolicyContactDesc;

  /// No description provided for @deletionPolicyStep1Title.
  ///
  /// In vi, this message translates to:
  /// **'Trước khi xóa'**
  String get deletionPolicyStep1Title;

  /// No description provided for @deletionPolicyStep1Desc.
  ///
  /// In vi, this message translates to:
  /// **'Người dùng có thể xuất CSV để giữ lại lịch sử giao dịch cá nhân.'**
  String get deletionPolicyStep1Desc;

  /// No description provided for @deletionPolicyStep2Title.
  ///
  /// In vi, this message translates to:
  /// **'Dữ liệu sẽ bị xóa'**
  String get deletionPolicyStep2Title;

  /// No description provided for @deletionPolicyStep2Desc.
  ///
  /// In vi, this message translates to:
  /// **'Hồ sơ, ví, danh mục, giao dịch, thiết lập nhắc nhở và ảnh trong Storage thuộc user ID hiện tại.'**
  String get deletionPolicyStep2Desc;

  /// No description provided for @deletionPolicyStep3Title.
  ///
  /// In vi, this message translates to:
  /// **'Cách xóa'**
  String get deletionPolicyStep3Title;

  /// No description provided for @deletionPolicyStep3Desc.
  ///
  /// In vi, this message translates to:
  /// **'App gọi Edge Function delete-account. Function xác thực session, xóa ảnh giao dịch rồi xóa Auth user.'**
  String get deletionPolicyStep3Desc;

  /// No description provided for @deletionPolicyStep4Title.
  ///
  /// In vi, this message translates to:
  /// **'Dữ liệu ngoài app'**
  String get deletionPolicyStep4Title;

  /// No description provided for @deletionPolicyStep4Desc.
  ///
  /// In vi, this message translates to:
  /// **'Nếu cần xóa dữ liệu backup, log hoặc yêu cầu ngoài app, người dùng có thể liên hệ qua kênh privacy support của team.'**
  String get deletionPolicyStep4Desc;

  /// No description provided for @termsOfUseHeroDesc.
  ///
  /// In vi, this message translates to:
  /// **'Các điều khoản này tóm tắt cách người dùng nên sử dụng Moniary trong phiên bản MVP.'**
  String get termsOfUseHeroDesc;

  /// No description provided for @termsOfUseScopeTitle.
  ///
  /// In vi, this message translates to:
  /// **'1. Phạm vi sử dụng'**
  String get termsOfUseScopeTitle;

  /// No description provided for @termsOfUseScopeDesc.
  ///
  /// In vi, this message translates to:
  /// **'Moniary được cung cấp để người dùng ghi chép và tự quản lý dữ liệu thu chi cá nhân. Người dùng chịu trách nhiệm về độ chính xác của dữ liệu đã nhập.'**
  String get termsOfUseScopeDesc;

  /// No description provided for @termsOfUseAccountTitle.
  ///
  /// In vi, this message translates to:
  /// **'2. Dữ liệu tài khoản'**
  String get termsOfUseAccountTitle;

  /// No description provided for @termsOfUseAccountDesc.
  ///
  /// In vi, this message translates to:
  /// **'Người dùng có thể xuất dữ liệu, gửi yêu cầu privacy và xóa tài khoản theo các công cụ được cung cấp trong app.'**
  String get termsOfUseAccountDesc;

  /// No description provided for @termsOfUseContentTitle.
  ///
  /// In vi, this message translates to:
  /// **'3. Nội dung người dùng'**
  String get termsOfUseContentTitle;

  /// No description provided for @termsOfUseContentDesc.
  ///
  /// In vi, this message translates to:
  /// **'Ghi chú, số tiền và ảnh giao dịch do người dùng nhập hoặc tải lên chỉ nên phục vụ mục đích quản lý chi tiêu cá nhân.'**
  String get termsOfUseContentDesc;

  /// No description provided for @termsOfUseLiabilityTitle.
  ///
  /// In vi, this message translates to:
  /// **'4. Giới hạn trách nhiệm'**
  String get termsOfUseLiabilityTitle;

  /// No description provided for @termsOfUseLiabilityDesc.
  ///
  /// In vi, this message translates to:
  /// **'Moniary không phải công cụ tư vấn tài chính, kế toán, thuế hoặc pháp lý. Các thống kê trong app chỉ có tính tham khảo.'**
  String get termsOfUseLiabilityDesc;

  /// No description provided for @termsOfUseChangesTitle.
  ///
  /// In vi, this message translates to:
  /// **'5. Thay đổi điều khoản'**
  String get termsOfUseChangesTitle;

  /// No description provided for @termsOfUseChangesDesc.
  ///
  /// In vi, this message translates to:
  /// **'Điều khoản có thể được cập nhật khi app bổ sung tính năng hoặc chuẩn bị phát hành chính thức.'**
  String get termsOfUseChangesDesc;

  /// No description provided for @transactionOcrExtracting.
  ///
  /// In vi, this message translates to:
  /// **'Đang trích xuất dữ liệu...'**
  String get transactionOcrExtracting;

  /// No description provided for @exportSheetTransactions.
  ///
  /// In vi, this message translates to:
  /// **'Giao dịch'**
  String get exportSheetTransactions;

  /// No description provided for @exportColumnDataType.
  ///
  /// In vi, this message translates to:
  /// **'Loại dữ liệu'**
  String get exportColumnDataType;

  /// No description provided for @exportColumnId.
  ///
  /// In vi, this message translates to:
  /// **'ID'**
  String get exportColumnId;

  /// No description provided for @exportColumnName.
  ///
  /// In vi, this message translates to:
  /// **'Tên'**
  String get exportColumnName;

  /// No description provided for @exportColumnImagePath.
  ///
  /// In vi, this message translates to:
  /// **'Đường dẫn ảnh'**
  String get exportColumnImagePath;

  /// No description provided for @exportColumnCreatedAt.
  ///
  /// In vi, this message translates to:
  /// **'Tạo lúc'**
  String get exportColumnCreatedAt;

  /// No description provided for @exportReportGeneratedAt.
  ///
  /// In vi, this message translates to:
  /// **'Tạo báo cáo lúc'**
  String get exportReportGeneratedAt;

  /// No description provided for @exportReportRecentTransactions.
  ///
  /// In vi, this message translates to:
  /// **'Giao dịch gần đây'**
  String get exportReportRecentTransactions;

  /// No description provided for @dataRetentionCloudTitle.
  ///
  /// In vi, this message translates to:
  /// **'Dữ liệu trên cloud'**
  String get dataRetentionCloudTitle;

  /// No description provided for @dataRetentionCloudDesc.
  ///
  /// In vi, this message translates to:
  /// **'Hồ sơ, ví, danh mục, giao dịch và đường dẫn ảnh giao dịch được giữ khi tài khoản còn hoạt động để app có thể đồng bộ và hiển thị lại dữ liệu.'**
  String get dataRetentionCloudDesc;

  /// No description provided for @dataRetentionPhotosTitle.
  ///
  /// In vi, this message translates to:
  /// **'Ảnh giao dịch'**
  String get dataRetentionPhotosTitle;

  /// No description provided for @dataRetentionPhotosDesc.
  ///
  /// In vi, this message translates to:
  /// **'Ảnh giao dịch chỉ được lưu khi người dùng chủ động chụp hoặc chọn ảnh. Ảnh sẽ được xử lý cùng dữ liệu tài khoản khi xóa tài khoản.'**
  String get dataRetentionPhotosDesc;

  /// No description provided for @dataRetentionLocalFilesTitle.
  ///
  /// In vi, this message translates to:
  /// **'File cục bộ'**
  String get dataRetentionLocalFilesTitle;

  /// No description provided for @dataRetentionLocalFilesDesc.
  ///
  /// In vi, this message translates to:
  /// **'File export và lịch sử request được tạo trên thiết bị. Người dùng có thể tự quản lý, chia sẻ hoặc xóa các file này khỏi bộ nhớ cục bộ.'**
  String get dataRetentionLocalFilesDesc;

  /// No description provided for @dataRetentionDeleteTitle.
  ///
  /// In vi, this message translates to:
  /// **'Sau khi xóa tài khoản'**
  String get dataRetentionDeleteTitle;

  /// No description provided for @dataRetentionDeleteDesc.
  ///
  /// In vi, this message translates to:
  /// **'Moniary gọi luồng xóa tài khoản để gỡ dữ liệu app gắn với user hiện tại. Nếu thao tác thất bại, người dùng có thể tạo request xóa dữ liệu thủ công.'**
  String get dataRetentionDeleteDesc;

  /// No description provided for @financialDisclaimerInvestmentTitle.
  ///
  /// In vi, this message translates to:
  /// **'Không phải tư vấn đầu tư'**
  String get financialDisclaimerInvestmentTitle;

  /// No description provided for @financialDisclaimerInvestmentDesc.
  ///
  /// In vi, this message translates to:
  /// **'Moniary không đề xuất mua, bán, đầu tư hoặc phân bổ tài sản. Người dùng tự chịu trách nhiệm với quyết định tài chính của mình.'**
  String get financialDisclaimerInvestmentDesc;

  /// No description provided for @financialDisclaimerTaxTitle.
  ///
  /// In vi, this message translates to:
  /// **'Không phải tư vấn thuế/kế toán'**
  String get financialDisclaimerTaxTitle;

  /// No description provided for @financialDisclaimerTaxDesc.
  ///
  /// In vi, this message translates to:
  /// **'Dữ liệu trong app không thay thế chứng từ, báo cáo kế toán hoặc tư vấn thuế chuyên nghiệp.'**
  String get financialDisclaimerTaxDesc;

  /// No description provided for @financialDisclaimerReferenceTitle.
  ///
  /// In vi, this message translates to:
  /// **'Số liệu có tính tham khảo'**
  String get financialDisclaimerReferenceTitle;

  /// No description provided for @financialDisclaimerReferenceDesc.
  ///
  /// In vi, this message translates to:
  /// **'Tổng thu, tổng chi và các file export phụ thuộc vào dữ liệu người dùng nhập, có thể sai nếu nhập thiếu hoặc nhập nhầm.'**
  String get financialDisclaimerReferenceDesc;

  /// No description provided for @financialDisclaimerExpertTitle.
  ///
  /// In vi, this message translates to:
  /// **'Khi cần quyết định quan trọng'**
  String get financialDisclaimerExpertTitle;

  /// No description provided for @financialDisclaimerExpertDesc.
  ///
  /// In vi, this message translates to:
  /// **'Người dùng nên kiểm tra lại dữ liệu gốc và hỏi chuyên gia phù hợp trước các quyết định tài chính, thuế hoặc pháp lý.'**
  String get financialDisclaimerExpertDesc;

  /// No description provided for @policyChangelogEntry1Title.
  ///
  /// In vi, this message translates to:
  /// **'Bổ sung Legal & Policy Center'**
  String get policyChangelogEntry1Title;

  /// No description provided for @policyChangelogEntry1Desc.
  ///
  /// In vi, this message translates to:
  /// **'Thêm chính sách lưu giữ dữ liệu, thông báo dịch vụ bên thứ ba, miễn trừ tài chính và lịch sử thay đổi chính sách.'**
  String get policyChangelogEntry1Desc;

  /// No description provided for @policyChangelogEntry2Title.
  ///
  /// In vi, this message translates to:
  /// **'Bổ sung Privacy Requests & Support'**
  String get policyChangelogEntry2Title;

  /// No description provided for @policyChangelogEntry2Desc.
  ///
  /// In vi, this message translates to:
  /// **'Thêm loại yêu cầu privacy, mẫu nội dung, preview, lịch sử request, trạng thái và timeline phản hồi.'**
  String get policyChangelogEntry2Desc;

  /// No description provided for @policyChangelogEntry3Title.
  ///
  /// In vi, this message translates to:
  /// **'Bổ sung Store Readiness & Trust'**
  String get policyChangelogEntry3Title;

  /// No description provided for @policyChangelogEntry3Desc.
  ///
  /// In vi, this message translates to:
  /// **'Thêm About, Terms of Use, license entry, version/build info, checklist phát hành và liên hệ pháp lý.'**
  String get policyChangelogEntry3Desc;

  /// No description provided for @policyChangelogEntry4Title.
  ///
  /// In vi, this message translates to:
  /// **'Khởi tạo chính sách MVP'**
  String get policyChangelogEntry4Title;

  /// No description provided for @policyChangelogEntry4Desc.
  ///
  /// In vi, this message translates to:
  /// **'Thêm privacy policy, data safety, data deletion policy, export dữ liệu và xóa tài khoản.'**
  String get policyChangelogEntry4Desc;

  /// No description provided for @groupCreateNew.
  ///
  /// In vi, this message translates to:
  /// **'Tạo nhóm mới'**
  String get groupCreateNew;

  /// No description provided for @groupDescriptionLabel.
  ///
  /// In vi, this message translates to:
  /// **'Mô tả'**
  String get groupDescriptionLabel;

  /// No description provided for @groupTypeLabel.
  ///
  /// In vi, this message translates to:
  /// **'Loại nhóm'**
  String get groupTypeLabel;

  /// No description provided for @groupTypeHint.
  ///
  /// In vi, this message translates to:
  /// **'Ví dụ: Du lịch, Ăn uống, Ở chung, Couple, Bạn bè...'**
  String get groupTypeHint;

  /// No description provided for @groupAvatarLabel.
  ///
  /// In vi, this message translates to:
  /// **'Ảnh nhóm'**
  String get groupAvatarLabel;

  /// No description provided for @groupChooseImage.
  ///
  /// In vi, this message translates to:
  /// **'Chọn ảnh'**
  String get groupChooseImage;

  /// No description provided for @groupNameRequired.
  ///
  /// In vi, this message translates to:
  /// **'Tên nhóm là bắt buộc.'**
  String get groupNameRequired;

  /// No description provided for @groupTotalSpent.
  ///
  /// In vi, this message translates to:
  /// **'Tổng chi {amount}'**
  String groupTotalSpent(String amount);

  /// No description provided for @groupBalanceSettled.
  ///
  /// In vi, this message translates to:
  /// **'Đã cân bằng'**
  String get groupBalanceSettled;

  /// No description provided for @groupBalanceOwes.
  ///
  /// In vi, this message translates to:
  /// **'Bạn cần trả {amount}'**
  String groupBalanceOwes(String amount);

  /// No description provided for @groupBalanceReceives.
  ///
  /// In vi, this message translates to:
  /// **'Bạn sẽ nhận {amount}'**
  String groupBalanceReceives(String amount);

  /// No description provided for @groupUnresolvedBadge.
  ///
  /// In vi, this message translates to:
  /// **'Chưa xử lý'**
  String get groupUnresolvedBadge;

  /// No description provided for @groupOverviewTitle.
  ///
  /// In vi, this message translates to:
  /// **'Tổng quan'**
  String get groupOverviewTitle;

  /// No description provided for @groupTransactionsTitle.
  ///
  /// In vi, this message translates to:
  /// **'Giao dịch nhóm'**
  String get groupTransactionsTitle;

  /// No description provided for @groupDebtAreaTitle.
  ///
  /// In vi, this message translates to:
  /// **'Ai nợ ai'**
  String get groupDebtAreaTitle;

  /// No description provided for @groupLeave.
  ///
  /// In vi, this message translates to:
  /// **'Rời nhóm'**
  String get groupLeave;

  /// No description provided for @groupLeaveConfirmTitle.
  ///
  /// In vi, this message translates to:
  /// **'Rời nhóm này?'**
  String get groupLeaveConfirmTitle;

  /// No description provided for @groupLeaveConfirmMessage.
  ///
  /// In vi, this message translates to:
  /// **'Bạn chỉ có thể rời nhóm khi công nợ đã được xử lý và quyền owner đã được chuyển nếu cần.'**
  String get groupLeaveConfirmMessage;

  /// No description provided for @groupLeaveBlocked.
  ///
  /// In vi, this message translates to:
  /// **'Bạn ơi! bạn còn vài khoản thu chi chưa được xử lý kìa.'**
  String get groupLeaveBlocked;

  /// No description provided for @groupOwnerTransferRequired.
  ///
  /// In vi, this message translates to:
  /// **'Bạn cần chuyển quyền owner hoặc thêm một owner khác trước khi rời nhóm.'**
  String get groupOwnerTransferRequired;

  /// No description provided for @groupInviteTitle.
  ///
  /// In vi, this message translates to:
  /// **'Mời thành viên'**
  String get groupInviteTitle;

  /// No description provided for @groupInviteByUsername.
  ///
  /// In vi, this message translates to:
  /// **'Mời bằng username'**
  String get groupInviteByUsername;

  /// No description provided for @groupUsernameLabel.
  ///
  /// In vi, this message translates to:
  /// **'Username'**
  String get groupUsernameLabel;

  /// No description provided for @groupInviteAction.
  ///
  /// In vi, this message translates to:
  /// **'Gửi lời mời'**
  String get groupInviteAction;

  /// No description provided for @groupInviteLinkTitle.
  ///
  /// In vi, this message translates to:
  /// **'Link mời nhóm'**
  String get groupInviteLinkTitle;

  /// No description provided for @groupCreateInviteLink.
  ///
  /// In vi, this message translates to:
  /// **'Tạo link mời'**
  String get groupCreateInviteLink;

  /// No description provided for @groupInviteLinkCreated.
  ///
  /// In vi, this message translates to:
  /// **'Đã tạo link mời nhóm.'**
  String get groupInviteLinkCreated;

  /// No description provided for @groupInviteSent.
  ///
  /// In vi, this message translates to:
  /// **'Đã gửi lời mời.'**
  String get groupInviteSent;

  /// No description provided for @groupUserNotFound.
  ///
  /// In vi, this message translates to:
  /// **'Không tìm thấy người dùng này.'**
  String get groupUserNotFound;

  /// No description provided for @groupNoFriends.
  ///
  /// In vi, this message translates to:
  /// **'Bạn chưa có bạn bè nào để mời.'**
  String get groupNoFriends;

  /// No description provided for @groupFriendInviteTitle.
  ///
  /// In vi, this message translates to:
  /// **'Mời từ danh sách bạn bè'**
  String get groupFriendInviteTitle;

  /// No description provided for @groupMemberInvited.
  ///
  /// In vi, this message translates to:
  /// **'Đã mời'**
  String get groupMemberInvited;

  /// No description provided for @groupMemberActive.
  ///
  /// In vi, this message translates to:
  /// **'Đang tham gia'**
  String get groupMemberActive;

  /// No description provided for @groupAddTransaction.
  ///
  /// In vi, this message translates to:
  /// **'Thêm giao dịch nhóm'**
  String get groupAddTransaction;

  /// No description provided for @groupTransactionCaption.
  ///
  /// In vi, this message translates to:
  /// **'Caption'**
  String get groupTransactionCaption;

  /// No description provided for @groupTransactionNote.
  ///
  /// In vi, this message translates to:
  /// **'Ghi chú'**
  String get groupTransactionNote;

  /// No description provided for @groupTransactionTotal.
  ///
  /// In vi, this message translates to:
  /// **'Tổng tiền'**
  String get groupTransactionTotal;

  /// No description provided for @groupTransactionCategory.
  ///
  /// In vi, this message translates to:
  /// **'Danh mục'**
  String get groupTransactionCategory;

  /// No description provided for @groupTransactionImage.
  ///
  /// In vi, this message translates to:
  /// **'Ảnh hóa đơn'**
  String get groupTransactionImage;

  /// No description provided for @groupTransactionImageOptional.
  ///
  /// In vi, this message translates to:
  /// **'Ảnh không bắt buộc nhưng được khuyến khích.'**
  String get groupTransactionImageOptional;

  /// No description provided for @groupSplitModeTitle.
  ///
  /// In vi, this message translates to:
  /// **'Cách chia tiền'**
  String get groupSplitModeTitle;

  /// No description provided for @groupSplitEqual.
  ///
  /// In vi, this message translates to:
  /// **'Chia đều'**
  String get groupSplitEqual;

  /// No description provided for @groupSplitUnequal.
  ///
  /// In vi, this message translates to:
  /// **'Chia không đều'**
  String get groupSplitUnequal;

  /// No description provided for @groupPaymentModeTitle.
  ///
  /// In vi, this message translates to:
  /// **'Người đã trả tiền'**
  String get groupPaymentModeTitle;

  /// No description provided for @groupPaymentEveryone.
  ///
  /// In vi, this message translates to:
  /// **'Mọi người đều trả'**
  String get groupPaymentEveryone;

  /// No description provided for @groupPaymentSingle.
  ///
  /// In vi, this message translates to:
  /// **'Một người trả'**
  String get groupPaymentSingle;

  /// No description provided for @groupPaymentMultiple.
  ///
  /// In vi, this message translates to:
  /// **'Nhiều người trả'**
  String get groupPaymentMultiple;

  /// No description provided for @groupSelectPayer.
  ///
  /// In vi, this message translates to:
  /// **'Vui lòng chọn người đã trả tiền.'**
  String get groupSelectPayer;

  /// No description provided for @groupSelectAtLeastTwoPayers.
  ///
  /// In vi, this message translates to:
  /// **'Vui lòng chọn ít nhất 2 người đã trả tiền.'**
  String get groupSelectAtLeastTwoPayers;

  /// No description provided for @groupEnterPayerAmounts.
  ///
  /// In vi, this message translates to:
  /// **'Vui lòng nhập số tiền đã trả cho từng thành viên.'**
  String get groupEnterPayerAmounts;

  /// No description provided for @groupPayerAmountPositive.
  ///
  /// In vi, this message translates to:
  /// **'Số tiền đã trả phải lớn hơn 0.'**
  String get groupPayerAmountPositive;

  /// No description provided for @groupPaidTotalMismatch.
  ///
  /// In vi, this message translates to:
  /// **'Tổng số tiền đã trả chưa khớp với tổng giá trị giao dịch.'**
  String get groupPaidTotalMismatch;

  /// No description provided for @groupConfirmationTitle.
  ///
  /// In vi, this message translates to:
  /// **'Bạn đã chắc chắn chưa?'**
  String get groupConfirmationTitle;

  /// No description provided for @groupPost.
  ///
  /// In vi, this message translates to:
  /// **'Đăng'**
  String get groupPost;

  /// No description provided for @groupPosting.
  ///
  /// In vi, this message translates to:
  /// **'Đang đăng...'**
  String get groupPosting;

  /// No description provided for @groupTransactionPosted.
  ///
  /// In vi, this message translates to:
  /// **'Giao dịch nhóm đã được đăng thành công.'**
  String get groupTransactionPosted;

  /// No description provided for @groupTransactionPendingAmounts.
  ///
  /// In vi, this message translates to:
  /// **'Vui lòng nhập số tiền bạn đã sử dụng trong giao dịch này.'**
  String get groupTransactionPendingAmounts;

  /// No description provided for @groupTransactionAmountMismatch.
  ///
  /// In vi, this message translates to:
  /// **'Tổng số tiền các thành viên nhập chưa khớp với tổng tiền giao dịch. Vui lòng kiểm tra và nhập lại.'**
  String get groupTransactionAmountMismatch;

  /// No description provided for @groupTransactionMembersPending.
  ///
  /// In vi, this message translates to:
  /// **'Vẫn còn thành viên chưa nhập số tiền đã sử dụng.'**
  String get groupTransactionMembersPending;

  /// No description provided for @groupTransactionPendingStatus.
  ///
  /// In vi, this message translates to:
  /// **'Chờ thành viên nhập số tiền'**
  String get groupTransactionPendingStatus;

  /// No description provided for @groupTransactionMismatchStatus.
  ///
  /// In vi, this message translates to:
  /// **'Tổng tiền chưa khớp'**
  String get groupTransactionMismatchStatus;

  /// No description provided for @groupTransactionPostedStatus.
  ///
  /// In vi, this message translates to:
  /// **'Đã đăng'**
  String get groupTransactionPostedStatus;

  /// No description provided for @groupTransactionNoData.
  ///
  /// In vi, this message translates to:
  /// **'Chưa có giao dịch nhóm.'**
  String get groupTransactionNoData;

  /// No description provided for @groupTransactionLoadError.
  ///
  /// In vi, this message translates to:
  /// **'Không tải được giao dịch nhóm.'**
  String get groupTransactionLoadError;

  /// No description provided for @groupTransactionDetailTitle.
  ///
  /// In vi, this message translates to:
  /// **'Chi tiết giao dịch nhóm'**
  String get groupTransactionDetailTitle;

  /// No description provided for @groupTransactionCreator.
  ///
  /// In vi, this message translates to:
  /// **'Người đăng'**
  String get groupTransactionCreator;

  /// No description provided for @groupTransactionPayers.
  ///
  /// In vi, this message translates to:
  /// **'Người đã trả'**
  String get groupTransactionPayers;

  /// No description provided for @groupTransactionShares.
  ///
  /// In vi, this message translates to:
  /// **'Phần phải chịu'**
  String get groupTransactionShares;

  /// No description provided for @groupTransactionDeleteConfirm.
  ///
  /// In vi, this message translates to:
  /// **'Xóa giao dịch nhóm này?'**
  String get groupTransactionDeleteConfirm;

  /// No description provided for @groupTransactionCompletedEditWarning.
  ///
  /// In vi, this message translates to:
  /// **'Giao dịch này đã có khoản nợ được xác nhận. Nếu chỉnh sửa, hệ thống sẽ tính lại công nợ của nhóm. Bạn có chắc muốn tiếp tục không?'**
  String get groupTransactionCompletedEditWarning;

  /// No description provided for @groupTransactionCreatorOnly.
  ///
  /// In vi, this message translates to:
  /// **'Chỉ người tạo giao dịch mới được sửa hoặc xóa.'**
  String get groupTransactionCreatorOnly;

  /// No description provided for @groupAmountInputTitle.
  ///
  /// In vi, this message translates to:
  /// **'Số tiền bạn đã sử dụng'**
  String get groupAmountInputTitle;

  /// No description provided for @groupAmountUsedLabel.
  ///
  /// In vi, this message translates to:
  /// **'Số tiền đã sử dụng'**
  String get groupAmountUsedLabel;

  /// No description provided for @groupAmountSubmit.
  ///
  /// In vi, this message translates to:
  /// **'Gửi số tiền'**
  String get groupAmountSubmit;

  /// No description provided for @groupAmountNonNegative.
  ///
  /// In vi, this message translates to:
  /// **'Số tiền không được nhỏ hơn 0.'**
  String get groupAmountNonNegative;

  /// No description provided for @groupSettlementTitle.
  ///
  /// In vi, this message translates to:
  /// **'Công nợ nhóm'**
  String get groupSettlementTitle;

  /// No description provided for @groupBalanceTableTitle.
  ///
  /// In vi, this message translates to:
  /// **'Bảng công nợ'**
  String get groupBalanceTableTitle;

  /// No description provided for @groupYouNeedPay.
  ///
  /// In vi, this message translates to:
  /// **'Bạn cần trả'**
  String get groupYouNeedPay;

  /// No description provided for @groupOthersNeedPayYou.
  ///
  /// In vi, this message translates to:
  /// **'Người khác cần trả cho bạn'**
  String get groupOthersNeedPayYou;

  /// No description provided for @groupMarkPaid.
  ///
  /// In vi, this message translates to:
  /// **'Đã trả nợ'**
  String get groupMarkPaid;

  /// No description provided for @groupConfirmReceived.
  ///
  /// In vi, this message translates to:
  /// **'Xác nhận đã nhận'**
  String get groupConfirmReceived;

  /// No description provided for @groupSettlementPending.
  ///
  /// In vi, this message translates to:
  /// **'Chờ thanh toán'**
  String get groupSettlementPending;

  /// No description provided for @groupSettlementPayerMarked.
  ///
  /// In vi, this message translates to:
  /// **'Người trả đã báo thanh toán'**
  String get groupSettlementPayerMarked;

  /// No description provided for @groupSettlementCompleted.
  ///
  /// In vi, this message translates to:
  /// **'Đã hoàn tất'**
  String get groupSettlementCompleted;

  /// No description provided for @groupSettlementDisputed.
  ///
  /// In vi, this message translates to:
  /// **'Đang tranh chấp'**
  String get groupSettlementDisputed;

  /// No description provided for @groupSettlementEmpty.
  ///
  /// In vi, this message translates to:
  /// **'Không có khoản nợ cần xử lý.'**
  String get groupSettlementEmpty;

  /// No description provided for @groupSettlementFromTo.
  ///
  /// In vi, this message translates to:
  /// **'{from} trả {to}'**
  String groupSettlementFromTo(String from, String to);

  /// No description provided for @groupSharePaidBalance.
  ///
  /// In vi, this message translates to:
  /// **'Chịu {share} • Đã trả {paid} • Cân đối {balance}'**
  String groupSharePaidBalance(String share, String paid, String balance);

  /// No description provided for @groupCommentsTitle.
  ///
  /// In vi, this message translates to:
  /// **'Bình luận'**
  String get groupCommentsTitle;

  /// No description provided for @groupCommentHint.
  ///
  /// In vi, this message translates to:
  /// **'Nhập bình luận...'**
  String get groupCommentHint;

  /// No description provided for @groupCommentSend.
  ///
  /// In vi, this message translates to:
  /// **'Gửi'**
  String get groupCommentSend;

  /// No description provided for @groupCommentsEmpty.
  ///
  /// In vi, this message translates to:
  /// **'Chưa có bình luận.'**
  String get groupCommentsEmpty;

  /// No description provided for @groupCommentRequired.
  ///
  /// In vi, this message translates to:
  /// **'Vui lòng nhập nội dung bình luận.'**
  String get groupCommentRequired;

  /// No description provided for @groupUnknownMember.
  ///
  /// In vi, this message translates to:
  /// **'Thành viên'**
  String get groupUnknownMember;

  /// No description provided for @groupNoCategory.
  ///
  /// In vi, this message translates to:
  /// **'Chưa chọn danh mục'**
  String get groupNoCategory;

  /// No description provided for @groupChooseCategory.
  ///
  /// In vi, this message translates to:
  /// **'Chọn danh mục'**
  String get groupChooseCategory;

  /// No description provided for @groupAmountRequired.
  ///
  /// In vi, this message translates to:
  /// **'Vui lòng nhập tổng tiền lớn hơn 0.'**
  String get groupAmountRequired;

  /// No description provided for @groupActionFailed.
  ///
  /// In vi, this message translates to:
  /// **'Không thể thực hiện thao tác nhóm. Vui lòng thử lại.'**
  String get groupActionFailed;

  /// No description provided for @groupMemberAlreadyInvited.
  ///
  /// In vi, this message translates to:
  /// **'Người dùng này đã ở trong nhóm hoặc đang có lời mời.'**
  String get groupMemberAlreadyInvited;

  /// No description provided for @groupInviteLinkPlaceholder.
  ///
  /// In vi, this message translates to:
  /// **'Deep link đã được tạo. Màn hình chấp nhận lời mời sẽ được kết nối ở phase deep linking.'**
  String get groupInviteLinkPlaceholder;

  /// No description provided for @groupStatsPlaceholder.
  ///
  /// In vi, this message translates to:
  /// **'Thống kê nhóm cơ bản dùng tổng chi và công nợ hiện tại.'**
  String get groupStatsPlaceholder;

  /// No description provided for @groupLeaveWarningActivity.
  ///
  /// In vi, this message translates to:
  /// **'Có thành viên trong nhóm cố gắng rời khỏi nhóm khi chưa xử lý xong các khoản chi. Hãy cẩn thận.'**
  String get groupLeaveWarningActivity;

  /// No description provided for @cancel.
  ///
  /// In vi, this message translates to:
  /// **'Hủy'**
  String get cancel;

  /// No description provided for @retry.
  ///
  /// In vi, this message translates to:
  /// **'Thử lại'**
  String get retry;

  /// No description provided for @friendsTitle.
  ///
  /// In vi, this message translates to:
  /// **'Bạn bè'**
  String get friendsTitle;

  /// No description provided for @friendsProfileSubtitle.
  ///
  /// In vi, this message translates to:
  /// **'Quản lý bạn bè và lời mời kết bạn'**
  String get friendsProfileSubtitle;

  /// No description provided for @friendAdd.
  ///
  /// In vi, this message translates to:
  /// **'Thêm bạn'**
  String get friendAdd;

  /// No description provided for @friendSearchUsername.
  ///
  /// In vi, this message translates to:
  /// **'Tìm bằng username'**
  String get friendSearchUsername;

  /// No description provided for @friendSearchHint.
  ///
  /// In vi, this message translates to:
  /// **'Ví dụ: an_nguyen'**
  String get friendSearchHint;

  /// No description provided for @friendSearch.
  ///
  /// In vi, this message translates to:
  /// **'Tìm kiếm'**
  String get friendSearch;

  /// No description provided for @friendSearchPrompt.
  ///
  /// In vi, this message translates to:
  /// **'Nhập username để tìm người dùng Moniary.'**
  String get friendSearchPrompt;

  /// No description provided for @friendSearchEmpty.
  ///
  /// In vi, this message translates to:
  /// **'Không tìm thấy người dùng “{query}”.'**
  String friendSearchEmpty(String query);

  /// No description provided for @friendSearchError.
  ///
  /// In vi, this message translates to:
  /// **'Không thể tìm bạn bè. Vui lòng thử lại.'**
  String get friendSearchError;

  /// No description provided for @friendLoadError.
  ///
  /// In vi, this message translates to:
  /// **'Không tải được danh sách bạn bè.'**
  String get friendLoadError;

  /// No description provided for @friendNoFriends.
  ///
  /// In vi, this message translates to:
  /// **'Bạn chưa có bạn bè nào.'**
  String get friendNoFriends;

  /// No description provided for @friendNoFriendsSubtitle.
  ///
  /// In vi, this message translates to:
  /// **'Thêm bạn bè để mời vào nhóm chi tiêu nhanh hơn.'**
  String get friendNoFriendsSubtitle;

  /// No description provided for @friendIncomingRequests.
  ///
  /// In vi, this message translates to:
  /// **'Lời mời kết bạn'**
  String get friendIncomingRequests;

  /// No description provided for @friendOutgoingRequests.
  ///
  /// In vi, this message translates to:
  /// **'Đã gửi lời mời'**
  String get friendOutgoingRequests;

  /// No description provided for @friendAccept.
  ///
  /// In vi, this message translates to:
  /// **'Chấp nhận'**
  String get friendAccept;

  /// No description provided for @friendDecline.
  ///
  /// In vi, this message translates to:
  /// **'Từ chối'**
  String get friendDecline;

  /// No description provided for @friendCancel.
  ///
  /// In vi, this message translates to:
  /// **'Hủy lời mời'**
  String get friendCancel;

  /// No description provided for @friendRemove.
  ///
  /// In vi, this message translates to:
  /// **'Xóa bạn'**
  String get friendRemove;

  /// No description provided for @friendRemoveTitle.
  ///
  /// In vi, this message translates to:
  /// **'Xóa bạn bè?'**
  String get friendRemoveTitle;

  /// No description provided for @friendRemoveMessage.
  ///
  /// In vi, this message translates to:
  /// **'Bạn có chắc muốn xóa {name} khỏi danh sách bạn bè?'**
  String friendRemoveMessage(String name);

  /// No description provided for @friendRemoved.
  ///
  /// In vi, this message translates to:
  /// **'Đã xóa bạn bè.'**
  String get friendRemoved;

  /// No description provided for @friendRequestSent.
  ///
  /// In vi, this message translates to:
  /// **'Đã gửi lời mời kết bạn.'**
  String get friendRequestSent;

  /// No description provided for @friendRequestAccepted.
  ///
  /// In vi, this message translates to:
  /// **'Đã chấp nhận lời mời kết bạn.'**
  String get friendRequestAccepted;

  /// No description provided for @friendRequestDeclined.
  ///
  /// In vi, this message translates to:
  /// **'Đã từ chối lời mời kết bạn.'**
  String get friendRequestDeclined;

  /// No description provided for @friendRequestCancelled.
  ///
  /// In vi, this message translates to:
  /// **'Đã hủy lời mời kết bạn.'**
  String get friendRequestCancelled;

  /// No description provided for @friendRequestPending.
  ///
  /// In vi, this message translates to:
  /// **'Đang chờ phản hồi'**
  String get friendRequestPending;

  /// No description provided for @friendIncomingPending.
  ///
  /// In vi, this message translates to:
  /// **'Người này đã gửi lời mời cho bạn'**
  String get friendIncomingPending;

  /// No description provided for @friendSendRequest.
  ///
  /// In vi, this message translates to:
  /// **'Kết bạn'**
  String get friendSendRequest;

  /// No description provided for @friendAlreadyFriends.
  ///
  /// In vi, this message translates to:
  /// **'Đã là bạn bè'**
  String get friendAlreadyFriends;

  /// No description provided for @friendAlreadyExists.
  ///
  /// In vi, this message translates to:
  /// **'Hai bạn đã là bạn bè.'**
  String get friendAlreadyExists;

  /// No description provided for @friendUserNotFound.
  ///
  /// In vi, this message translates to:
  /// **'Không tìm thấy người dùng này.'**
  String get friendUserNotFound;

  /// No description provided for @friendCannotAddSelf.
  ///
  /// In vi, this message translates to:
  /// **'Bạn không thể tự kết bạn với chính mình.'**
  String get friendCannotAddSelf;

  /// No description provided for @friendRequestAlreadyPending.
  ///
  /// In vi, this message translates to:
  /// **'Đã có lời mời kết bạn đang chờ xử lý.'**
  String get friendRequestAlreadyPending;

  /// No description provided for @friendRequestNotFound.
  ///
  /// In vi, this message translates to:
  /// **'Không tìm thấy lời mời kết bạn.'**
  String get friendRequestNotFound;

  /// No description provided for @friendNotFound.
  ///
  /// In vi, this message translates to:
  /// **'Không tìm thấy bạn bè này.'**
  String get friendNotFound;

  /// No description provided for @friendShareInviteLink.
  ///
  /// In vi, this message translates to:
  /// **'Chia sẻ link kết bạn'**
  String get friendShareInviteLink;

  /// No description provided for @friendInviteShareDescription.
  ///
  /// In vi, this message translates to:
  /// **'Gửi link cho người khác để họ kết bạn với bạn nhanh hơn.'**
  String get friendInviteShareDescription;

  /// No description provided for @friendInviteShareMessage.
  ///
  /// In vi, this message translates to:
  /// **'Kết bạn với mình trên Moniary nhé: {link}'**
  String friendInviteShareMessage(String link);

  /// No description provided for @friendInviteAcceptTitle.
  ///
  /// In vi, this message translates to:
  /// **'Lời mời kết bạn'**
  String get friendInviteAcceptTitle;

  /// No description provided for @friendInviteAcceptSubtitle.
  ///
  /// In vi, this message translates to:
  /// **'{name} muốn kết bạn với bạn trên Moniary.'**
  String friendInviteAcceptSubtitle(String name);

  /// No description provided for @friendInviteAcceptButton.
  ///
  /// In vi, this message translates to:
  /// **'Kết bạn'**
  String get friendInviteAcceptButton;

  /// No description provided for @friendInviteAccepted.
  ///
  /// In vi, this message translates to:
  /// **'Đã kết bạn thành công.'**
  String get friendInviteAccepted;

  /// No description provided for @friendInviteLoading.
  ///
  /// In vi, this message translates to:
  /// **'Đang tải lời mời...'**
  String get friendInviteLoading;

  /// No description provided for @friendInvitePreviewError.
  ///
  /// In vi, this message translates to:
  /// **'Không tải được lời mời kết bạn.'**
  String get friendInvitePreviewError;

  /// No description provided for @friendInviteInvalid.
  ///
  /// In vi, this message translates to:
  /// **'Link kết bạn không hợp lệ.'**
  String get friendInviteInvalid;

  /// No description provided for @friendInviteExpired.
  ///
  /// In vi, this message translates to:
  /// **'Link kết bạn đã hết hạn.'**
  String get friendInviteExpired;

  /// No description provided for @friendInviteUsed.
  ///
  /// In vi, this message translates to:
  /// **'Link kết bạn đã được sử dụng.'**
  String get friendInviteUsed;

  /// No description provided for @friendInviteRevoked.
  ///
  /// In vi, this message translates to:
  /// **'Link kết bạn đã bị hủy.'**
  String get friendInviteRevoked;

  /// No description provided for @friendInviteSelf.
  ///
  /// In vi, this message translates to:
  /// **'Bạn không thể dùng link kết bạn của chính mình.'**
  String get friendInviteSelf;

  /// No description provided for @friendInviteAlreadyFriends.
  ///
  /// In vi, this message translates to:
  /// **'Hai bạn đã là bạn bè.'**
  String get friendInviteAlreadyFriends;

  /// No description provided for @friendInviteOpenFriends.
  ///
  /// In vi, this message translates to:
  /// **'Xem danh sách bạn bè'**
  String get friendInviteOpenFriends;

  /// No description provided for @profileUsernameHint.
  ///
  /// In vi, this message translates to:
  /// **'3-30 ký tự: chữ thường, số hoặc dấu gạch dưới'**
  String get profileUsernameHint;

  /// No description provided for @profileUsernameInvalid.
  ///
  /// In vi, this message translates to:
  /// **'Username phải có 3-30 ký tự và chỉ gồm chữ thường, số hoặc dấu gạch dưới.'**
  String get profileUsernameInvalid;

  /// No description provided for @privacyProtectionSettingsTitle.
  ///
  /// In vi, this message translates to:
  /// **'Thiết lập bảo vệ'**
  String get privacyProtectionSettingsTitle;

  /// No description provided for @privacyHideBalancesTitle.
  ///
  /// In vi, this message translates to:
  /// **'Ẩn số dư'**
  String get privacyHideBalancesTitle;

  /// No description provided for @privacyHideBalancesSubtitle.
  ///
  /// In vi, this message translates to:
  /// **'Che số tiền trên các màn hình tổng quan và chi tiết.'**
  String get privacyHideBalancesSubtitle;

  /// No description provided for @privacyExploreTitle.
  ///
  /// In vi, this message translates to:
  /// **'Thông tin và kiểm soát'**
  String get privacyExploreTitle;

  /// No description provided for @privacyStatusProtected.
  ///
  /// In vi, this message translates to:
  /// **'Đang bảo vệ'**
  String get privacyStatusProtected;

  /// No description provided for @privacyStatusReview.
  ///
  /// In vi, this message translates to:
  /// **'Cần kiểm tra'**
  String get privacyStatusReview;

  /// No description provided for @privacyRequestCount.
  ///
  /// In vi, this message translates to:
  /// **'{count} yêu cầu'**
  String privacyRequestCount(int count);

  /// No description provided for @biometricReasonDisable.
  ///
  /// In vi, this message translates to:
  /// **'Xác thực để tắt khóa ứng dụng'**
  String get biometricReasonDisable;

  /// No description provided for @biometricReasonDeleteAccount.
  ///
  /// In vi, this message translates to:
  /// **'Xác thực để yêu cầu xóa tài khoản'**
  String get biometricReasonDeleteAccount;

  /// No description provided for @deleteAccountGraceTitle.
  ///
  /// In vi, this message translates to:
  /// **'Tài khoản sẽ được xóa sau 30 ngày'**
  String get deleteAccountGraceTitle;

  /// No description provided for @deleteAccountGraceBody.
  ///
  /// In vi, this message translates to:
  /// **'Bạn sẽ được đăng xuất ngay. Trong 30 ngày, hãy đăng nhập bằng đúng phương thức hiện tại nếu muốn khôi phục tài khoản trước khi dữ liệu bị xóa vĩnh viễn.'**
  String get deleteAccountGraceBody;

  /// No description provided for @deleteGuestDataTitle.
  ///
  /// In vi, this message translates to:
  /// **'Xóa dữ liệu Guest'**
  String get deleteGuestDataTitle;

  /// No description provided for @deleteGuestDataBody.
  ///
  /// In vi, this message translates to:
  /// **'Dữ liệu Guest chỉ nằm trên thiết bị này và sẽ bị xóa ngay. Thiết lập ngôn ngữ, tiền tệ và trạng thái onboarding vẫn được giữ lại.'**
  String get deleteGuestDataBody;

  /// No description provided for @deleteGuestDataUnderstand.
  ///
  /// In vi, this message translates to:
  /// **'Tôi hiểu dữ liệu Guest trên thiết bị sẽ bị xóa ngay.'**
  String get deleteGuestDataUnderstand;

  /// No description provided for @deleteGuestDataAction.
  ///
  /// In vi, this message translates to:
  /// **'Xóa dữ liệu Guest'**
  String get deleteGuestDataAction;

  /// No description provided for @deleteAccountExportTitle.
  ///
  /// In vi, this message translates to:
  /// **'Giữ một bản sao trước khi xóa'**
  String get deleteAccountExportTitle;

  /// No description provided for @deleteAccountExportBody.
  ///
  /// In vi, this message translates to:
  /// **'Bạn có thể xuất dữ liệu trước khi gửi yêu cầu xóa. Lỗi xuất dữ liệu không ngăn bạn thực hiện quyền xóa tài khoản.'**
  String get deleteAccountExportBody;

  /// No description provided for @deleteAccountExportAction.
  ///
  /// In vi, this message translates to:
  /// **'Mở trang xuất dữ liệu'**
  String get deleteAccountExportAction;

  /// No description provided for @deleteAccountReasonTitle.
  ///
  /// In vi, this message translates to:
  /// **'Vì sao bạn rời Moniary?'**
  String get deleteAccountReasonTitle;

  /// No description provided for @deleteAccountReasonHint.
  ///
  /// In vi, this message translates to:
  /// **'Chọn một lý do'**
  String get deleteAccountReasonHint;

  /// No description provided for @deleteAccountDetailsLabel.
  ///
  /// In vi, this message translates to:
  /// **'Ghi chú bổ sung (không bắt buộc)'**
  String get deleteAccountDetailsLabel;

  /// No description provided for @deleteAccountDetailsHint.
  ///
  /// In vi, this message translates to:
  /// **'Điều gì có thể khiến trải nghiệm tốt hơn?'**
  String get deleteAccountDetailsHint;

  /// No description provided for @deleteAccountDetailsHelper.
  ///
  /// In vi, this message translates to:
  /// **'Không nhập email, thông tin tài chính hoặc dữ liệu nhạy cảm.'**
  String get deleteAccountDetailsHelper;

  /// No description provided for @deleteAccountGraceUnderstand.
  ///
  /// In vi, this message translates to:
  /// **'Tôi hiểu tài khoản sẽ bị khóa sử dụng và xóa vĩnh viễn sau 30 ngày nếu không khôi phục.'**
  String get deleteAccountGraceUnderstand;

  /// No description provided for @deleteAccountConfirmationPhrase.
  ///
  /// In vi, this message translates to:
  /// **'XÓA'**
  String get deleteAccountConfirmationPhrase;

  /// No description provided for @deleteAccountConfirmationLabel.
  ///
  /// In vi, this message translates to:
  /// **'Nhập {phrase} để xác nhận'**
  String deleteAccountConfirmationLabel(String phrase);

  /// No description provided for @deleteAccountScheduleAction.
  ///
  /// In vi, this message translates to:
  /// **'Yêu cầu xóa tài khoản'**
  String get deleteAccountScheduleAction;

  /// No description provided for @deleteReasonDifficultToUse.
  ///
  /// In vi, this message translates to:
  /// **'Khó sử dụng'**
  String get deleteReasonDifficultToUse;

  /// No description provided for @deleteReasonMissingFeatures.
  ///
  /// In vi, this message translates to:
  /// **'Thiếu tính năng'**
  String get deleteReasonMissingFeatures;

  /// No description provided for @deleteReasonTechnicalIssues.
  ///
  /// In vi, this message translates to:
  /// **'Gặp lỗi kỹ thuật'**
  String get deleteReasonTechnicalIssues;

  /// No description provided for @deleteReasonPrivacyConcerns.
  ///
  /// In vi, this message translates to:
  /// **'Lo ngại quyền riêng tư'**
  String get deleteReasonPrivacyConcerns;

  /// No description provided for @deleteReasonNoLongerNeeded.
  ///
  /// In vi, this message translates to:
  /// **'Không còn nhu cầu'**
  String get deleteReasonNoLongerNeeded;

  /// No description provided for @deleteReasonOther.
  ///
  /// In vi, this message translates to:
  /// **'Khác'**
  String get deleteReasonOther;

  /// No description provided for @deleteAccountImpactTitle.
  ///
  /// In vi, this message translates to:
  /// **'Dữ liệu bị ảnh hưởng'**
  String get deleteAccountImpactTitle;

  /// No description provided for @deleteAccountTransactionsCount.
  ///
  /// In vi, this message translates to:
  /// **'{count} giao dịch'**
  String deleteAccountTransactionsCount(int count);

  /// No description provided for @deleteAccountWalletsCount.
  ///
  /// In vi, this message translates to:
  /// **'{count} ví'**
  String deleteAccountWalletsCount(int count);

  /// No description provided for @deleteAccountPhotosCount.
  ///
  /// In vi, this message translates to:
  /// **'{count} ảnh'**
  String deleteAccountPhotosCount(int count);

  /// No description provided for @deleteAccountImpactUnavailable.
  ///
  /// In vi, this message translates to:
  /// **'Không thể tải số lượng chi tiết lúc này. Bạn vẫn có thể tiếp tục yêu cầu xóa.'**
  String get deleteAccountImpactUnavailable;

  /// No description provided for @restoreAccountPendingBody.
  ///
  /// In vi, this message translates to:
  /// **'Yêu cầu xóa được tạo ngày {requestedDate}. Dữ liệu sẽ bị xóa vĩnh viễn ngày {deletionDate}.\n\nKhôi phục tài khoản để tiếp tục sử dụng Moniary.'**
  String restoreAccountPendingBody(String requestedDate, String deletionDate);

  /// No description provided for @commonUnknown.
  ///
  /// In vi, this message translates to:
  /// **'Không xác định'**
  String get commonUnknown;

  /// No description provided for @loginEmailConfirmationSent.
  ///
  /// In vi, this message translates to:
  /// **'Vui lòng kiểm tra email để xác nhận tài khoản.'**
  String get loginEmailConfirmationSent;

  /// No description provided for @loginCreateAccount.
  ///
  /// In vi, this message translates to:
  /// **'Tạo tài khoản'**
  String get loginCreateAccount;

  /// No description provided for @loginEmailTitle.
  ///
  /// In vi, this message translates to:
  /// **'Đăng nhập bằng email'**
  String get loginEmailTitle;

  /// No description provided for @loginEmailLabel.
  ///
  /// In vi, this message translates to:
  /// **'Email'**
  String get loginEmailLabel;

  /// No description provided for @loginEmailRequired.
  ///
  /// In vi, this message translates to:
  /// **'Vui lòng nhập email'**
  String get loginEmailRequired;

  /// No description provided for @loginPasswordLabel.
  ///
  /// In vi, this message translates to:
  /// **'Mật khẩu'**
  String get loginPasswordLabel;

  /// No description provided for @loginPasswordMinLength.
  ///
  /// In vi, this message translates to:
  /// **'Mật khẩu cần ít nhất 6 ký tự'**
  String get loginPasswordMinLength;

  /// No description provided for @loginSignUp.
  ///
  /// In vi, this message translates to:
  /// **'Đăng ký'**
  String get loginSignUp;

  /// No description provided for @loginSignIn.
  ///
  /// In vi, this message translates to:
  /// **'Đăng nhập'**
  String get loginSignIn;

  /// No description provided for @loginAlreadyHaveAccount.
  ///
  /// In vi, this message translates to:
  /// **'Đã có tài khoản? Đăng nhập'**
  String get loginAlreadyHaveAccount;

  /// No description provided for @loginNeedAccount.
  ///
  /// In vi, this message translates to:
  /// **'Chưa có tài khoản? Đăng ký'**
  String get loginNeedAccount;

  /// No description provided for @cameraFallbackPermissionDenied.
  ///
  /// In vi, this message translates to:
  /// **'Không có quyền truy cập camera. Bạn có thể nhập giao dịch thủ công.'**
  String get cameraFallbackPermissionDenied;

  /// No description provided for @cameraFallbackGenericError.
  ///
  /// In vi, this message translates to:
  /// **'Không thể mở camera. Bạn có thể nhập giao dịch thủ công.'**
  String get cameraFallbackGenericError;
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
