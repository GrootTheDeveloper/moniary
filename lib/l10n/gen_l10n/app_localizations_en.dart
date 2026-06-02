// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'Moniary';

  @override
  String get commonSave => 'Save';

  @override
  String get commonCancel => 'Cancel';

  @override
  String get commonDelete => 'Delete';

  @override
  String get commonEdit => 'Edit';

  @override
  String get commonRetry => 'Retry';

  @override
  String get commonAdd => 'Add';

  @override
  String get commonClose => 'Close';

  @override
  String get commonSaving => 'Saving...';

  @override
  String get commonLoading => 'Loading...';

  @override
  String get commonCopy => 'Copy';

  @override
  String get commonShare => 'Share';

  @override
  String get commonOpen => 'Open';

  @override
  String get commonSelect => 'Select';

  @override
  String get commonCreate => 'Create';

  @override
  String get errorGeneric => 'An error occurred. Please try again.';

  @override
  String get errorNotLoggedIn => 'You are not logged in.';

  @override
  String get errorConnection => 'Connection error. Please try again.';

  @override
  String get loginTitle => 'Moniary';

  @override
  String get loginSubtitle => 'Personal expense manager';

  @override
  String get loginAnonymous => 'Start anonymous trial';

  @override
  String get loginTerms =>
      'By continuing, you agree to Moniary\'s terms of use and privacy policy.';

  @override
  String get loginFeatureSubtitle => 'Track expenses with photos';

  @override
  String get loginHeader => 'Sign In';

  @override
  String get loginGoogle => 'Sign in with Google (Coming soon)';

  @override
  String get loginApple => 'Sign in with Apple (Coming soon)';

  @override
  String get loginEmail => 'Sign in with Email (Coming soon)';

  @override
  String get loginOr => 'or';

  @override
  String get loginConnecting => 'Connecting to Supabase...';

  @override
  String get loginTryWithoutAuth => 'Try without logging in';

  @override
  String get loginSessionReady =>
      'Session ready. You can go straight to Calendar.';

  @override
  String get loginDataSecure => 'Your data is secure and synced with Supabase.';

  @override
  String get splashLoading => 'Loading app...';

  @override
  String get splashRetry => 'Retry';

  @override
  String get splashError =>
      'Cannot connect. Please check your network and try again.';

  @override
  String get splashErrorConnecting => 'Cannot connect';

  @override
  String get splashSubtitle => 'Track expenses with photos';

  @override
  String get splashDescription =>
      'Capture spending, save to calendar,\nmanage money as easily as saving memories.';

  @override
  String splashStarting(String appName) {
    return 'Starting $appName...';
  }

  @override
  String get onboardingSkip => 'Skip';

  @override
  String get onboardingStart => 'Start';

  @override
  String get onboardingNext => 'Next';

  @override
  String get onboardingNextPage => 'Next';

  @override
  String get onboardingFinish => 'Continue';

  @override
  String get onboardingMonthMock => 'May';

  @override
  String get onboardingPillCapture => 'Capture & save';

  @override
  String get onboardingPillCalendar => 'Daily view';

  @override
  String get onboardingPillStats => 'Stats';

  @override
  String get onboardingPage1Title1 => 'Track expenses';

  @override
  String get onboardingPage1Title2 => 'with photos';

  @override
  String get onboardingPage1Subtitle => 'Fast  •  Memorable  •  Never miss';

  @override
  String get onboardingPage1Caption =>
      'Save spending moments like a mini diary.';

  @override
  String get onboardingPage2Title1 => 'View calendar';

  @override
  String get onboardingPage2Title2 => 'intuitively';

  @override
  String get onboardingPage2Subtitle =>
      'Photos, totals, filters and alerts in one screen';

  @override
  String get onboardingPage2Caption =>
      'Each day is a cell, each transaction is a memory.';

  @override
  String get onboardingPage3Title1 => 'Analytics';

  @override
  String get onboardingPage3Title2 => 'made simple';

  @override
  String get onboardingPage3Subtitle =>
      'Track income/expenses without complex charts';

  @override
  String get onboardingPage3Caption =>
      'Moniary helps you view money in real context.';

  @override
  String get profileSetupTitle => 'Profile Setup';

  @override
  String get profileSetupSubtitle => 'Complete your info to get started';

  @override
  String get profileSetupDisplayName => 'Display Name';

  @override
  String get profileSetupDisplayNameHint => 'Enter your name';

  @override
  String get profileSetupCurrency => 'Currency';

  @override
  String get profileSetupStart => 'Start';

  @override
  String get profileSetupNameRequired => 'Please enter a display name.';

  @override
  String get calendarTitle => 'Calendar';

  @override
  String get calendarAllWallets => 'All wallets';

  @override
  String get calendarAllCategories => 'All categories';

  @override
  String get calendarNoTransactions => 'No transactions this month.';

  @override
  String get calendarIncome => 'Income';

  @override
  String get calendarExpense => 'Expense';

  @override
  String get calendarBalance => 'Balance';

  @override
  String get calendarSelectWalletFilter => 'Select wallet filter';

  @override
  String get calendarSelectCategoryFilter => 'Select category filter';

  @override
  String get calendarMonthlyExpense => 'Monthly Expense';

  @override
  String get calendarMonthlyIncome => 'Monthly Income';

  @override
  String get calendarEmptyMessage =>
      'No transactions this month. Add a transaction to start tracking.';

  @override
  String calendarStatsMessage(int count, int days) {
    return '$count transactions in $days active days. Loaded from Supabase.';
  }

  @override
  String calendarLoadError(String error) {
    return 'Could not load calendar: $error';
  }

  @override
  String get calendarStatsTab => 'Stats';

  @override
  String get calendarMon => 'Mon';

  @override
  String get calendarTue => 'Tue';

  @override
  String get calendarWed => 'Wed';

  @override
  String get calendarThu => 'Thu';

  @override
  String get calendarFri => 'Fri';

  @override
  String get calendarSat => 'Sat';

  @override
  String get calendarSun => 'Sun';

  @override
  String get calendarToday => 'Today';

  @override
  String get transactionSaveTransaction => 'Save transaction';

  @override
  String transactionLoadDayError(String error) {
    return 'Could not load transactions for this day.\n$error';
  }

  @override
  String get transactionTotalIncome => 'Total Income';

  @override
  String get transactionTotalExpense => 'Total Expense';

  @override
  String get transactionNetTotal => 'Net Total';

  @override
  String transactionCount(int count) {
    return '$count transactions';
  }

  @override
  String get transactionDayEmpty =>
      'No transactions for this day. Tap + to add one.';

  @override
  String transactionLoadDetailError(String error) {
    return 'Could not load transaction details.\n$error';
  }

  @override
  String get transactionNoteEmpty => 'No note for this transaction.';

  @override
  String get transactionDeleteTitleQuestion => 'Delete transaction?';

  @override
  String get transactionDeleteUndone => 'This action cannot be undone.';

  @override
  String get transactionAmount => 'Amount';

  @override
  String get transactionAmountSuffix => '₫';

  @override
  String get transactionWallet => 'Wallet';

  @override
  String get transactionCategory => 'Category';

  @override
  String get transactionNote => 'Note';

  @override
  String get transactionNoteHint => 'Bubble tea / Freelance pay / ...';

  @override
  String get transactionDate => 'Transaction date';

  @override
  String get transactionSelectWalletCategory =>
      'Select wallet and category before saving.';

  @override
  String get transactionAmountInvalid => 'Enter a valid amount.';

  @override
  String get transactionSaving => 'Saving...';

  @override
  String get transactionCreateTitle => 'Create transaction';

  @override
  String get transactionEditTitle => 'Edit transaction';

  @override
  String get transactionDeleteConfirm => 'Delete this transaction?';

  @override
  String get transactionDeleteSuccess => 'Transaction deleted.';

  @override
  String transactionSaveError(String error) {
    return 'Could not save transaction: $error';
  }

  @override
  String get transactionCreateSubtitle =>
      'Save transaction first, photo can be added in the next step.';

  @override
  String get transactionWalletCategoryLoadError =>
      'Could not load wallets/categories. Open data management to check.';

  @override
  String get transactionChangePhoto => 'Change photo';

  @override
  String get transactionEnterNote => 'Enter note...';

  @override
  String get transactionSelectCategory => 'Select category';

  @override
  String get transactionSelectWallet => 'Select wallet';

  @override
  String get transactionDateTime => 'Date & Time';

  @override
  String get transactionWalletAccount => 'Wallet / Account';

  @override
  String get transactionExpenseCategory => 'Expense category';

  @override
  String get transactionLoadingWalletCategory =>
      'Loading wallets and categories...';

  @override
  String get transactionWalletCategoryError =>
      'Could not load wallets or categories. Please try again.';

  @override
  String get transactionWalletCategoryRequired =>
      'An active wallet and expense category are required before saving.';

  @override
  String get transactionAmountPositive => 'Enter an amount greater than 0.';

  @override
  String get transactionType => 'Transaction type';

  @override
  String get walletTitle => 'Wallets / Accounts';

  @override
  String get walletDescription =>
      'Manage default wallet, initial balance and activation status.';

  @override
  String get walletEmpty => 'No wallets yet.';

  @override
  String get walletDefault => 'Default';

  @override
  String get walletActive => 'Active';

  @override
  String get walletInactive => 'Hidden';

  @override
  String get walletCreateTitle => 'Create wallet';

  @override
  String get walletEditTitle => 'Edit wallet';

  @override
  String get walletName => 'Wallet name';

  @override
  String get walletType => 'Wallet type';

  @override
  String get walletInitialBalance => 'Initial balance';

  @override
  String get walletSetDefault => 'Set as default wallet';

  @override
  String get walletActivated => 'Activated';

  @override
  String get walletSaving => 'Saving...';

  @override
  String get walletSave => 'Save wallet';

  @override
  String get walletNameRequired => 'Wallet name cannot be empty.';

  @override
  String get walletTypeCash => 'Cash';

  @override
  String get walletTypeBank => 'Bank';

  @override
  String get walletTypeEwallet => 'E-Wallet';

  @override
  String get walletTypeCredit => 'Credit Card';

  @override
  String get walletTypeOther => 'Other';

  @override
  String walletError(String error) {
    return 'Wallet error: $error';
  }

  @override
  String get walletNeedOneActive =>
      'You need at least 1 active wallet to create a transaction.';

  @override
  String get categoryTitle => 'Categories';

  @override
  String get categoryDescription =>
      'Manage income/expense categories for transactions.';

  @override
  String get categoryEmpty => 'No categories yet.';

  @override
  String get categoryNoData => 'No data.';

  @override
  String get categoryCreateTitle => 'Create category';

  @override
  String get categoryEditTitle => 'Edit category';

  @override
  String get categoryName => 'Category name';

  @override
  String get categoryType => 'Category type';

  @override
  String get categoryActivated => 'Activated';

  @override
  String get categorySaving => 'Saving...';

  @override
  String get categorySave => 'Save category';

  @override
  String get categoryNameRequired => 'Category name cannot be empty.';

  @override
  String categoryError(String error) {
    return 'Category error: $error';
  }

  @override
  String get categoryExpense => 'Expense';

  @override
  String get categoryIncome => 'Income';

  @override
  String get categoryNeedOneActive =>
      'You need at least 1 active category for this transaction type.';

  @override
  String get scanTitle => 'Scan receipt';

  @override
  String get scanTakePhoto => 'Take photo';

  @override
  String get scanChooseGallery => 'Choose from gallery';

  @override
  String get scanExtracting => 'Extracting data...';

  @override
  String get scanFailed => 'Cannot read receipt. Please try again.';

  @override
  String get scanReviewTitle => 'Review receipt';

  @override
  String get scanMerchant => 'Merchant';

  @override
  String scanOcrConfidence(int percent) {
    return 'OCR confidence: $percent%. Please verify before saving.';
  }

  @override
  String get scanItemsTitle => 'Detected items';

  @override
  String scanQuantity(int quantity) {
    return 'Quantity: $quantity';
  }

  @override
  String get scanSuccessMessage =>
      'Receipt read successfully. You can review and edit information.';

  @override
  String get scanScanning => 'Scanning...';

  @override
  String get scanExtractButton => 'Extract data';

  @override
  String get scanManualEntry => 'Enter transaction manually';

  @override
  String get scanNoReceipt => 'No receipt photo yet';

  @override
  String get scanNoReceiptSubtitle =>
      'Capture a receipt or choose from gallery to start.';

  @override
  String get scanImageError => 'Cannot display selected photo.';

  @override
  String get groupTitle => 'Group expenses';

  @override
  String get groupEmpty => 'No expense groups yet';

  @override
  String get groupEmptySubtitle =>
      'Create a group to track bills and split expenses.';

  @override
  String get groupCreate => 'Create group';

  @override
  String get groupCreateDialog => 'Create new group';

  @override
  String get groupNameLabel => 'Group name';

  @override
  String get groupNeedLogin => 'You need to be logged in to create a group.';

  @override
  String groupMemberCount(int count) {
    return '$count members';
  }

  @override
  String get groupLoadError => 'Could not load group list.';

  @override
  String get groupAddMember => 'Add member';

  @override
  String get groupMemberName => 'Member name';

  @override
  String get groupExpenses => 'Group expenses';

  @override
  String get groupAddExpense => 'Add expense';

  @override
  String get groupNoExpenses => 'No expenses yet.';

  @override
  String get groupNoMembers => 'No members in this group besides you.';

  @override
  String get groupDebtSummary => 'Debt summary';

  @override
  String get groupRemoveMemberConfirm => 'Remove this member?';

  @override
  String get groupDetailTitle => 'Group expenses';

  @override
  String get groupLoadSingleError => 'Could not load group.';

  @override
  String get groupNotExists => 'Group no longer exists.';

  @override
  String get groupMembersHeader => 'Members';

  @override
  String get groupExpenseHistory => 'Expense history';

  @override
  String get groupLoadExpensesError => 'Could not load group expenses.';

  @override
  String get groupDeletedMember => 'Deleted member';

  @override
  String get groupMemberEmailHint => 'Email (optional)';

  @override
  String get groupDeleteExpenseConfirmTitle => 'Delete expense?';

  @override
  String get groupDeleteExpenseConfirmMessage =>
      'This action will update group balances.';

  @override
  String groupPayerSubtitle(String payer, String date) {
    return '$payer paid • $date';
  }

  @override
  String get groupEmptyExpensesMessage =>
      'No expenses yet. Add the first expense to start splitting.';

  @override
  String get debtSummaryTitle => 'Debt summary';

  @override
  String get debtNoData => 'No expense data yet.';

  @override
  String get debtSettlementTitle => 'Settlement suggestions';

  @override
  String get debtNoSettlement => 'No debts to settle.';

  @override
  String debtOwes(String from, String to, String amount) {
    return '$from pays $to $amount';
  }

  @override
  String get debtSummaryAppBarTitle => 'Group balances';

  @override
  String get debtLoadError => 'Could not calculate debts.';

  @override
  String get debtExplanation =>
      'Positive indicates money to receive, negative indicates money to pay.';

  @override
  String debtOwesPayerToPayee(String from, String to) {
    return '$from pays $to';
  }

  @override
  String get debtMember => 'Member';

  @override
  String get debtToReceive => 'To receive';

  @override
  String get debtToPay => 'To pay';

  @override
  String get expenseFormTitle => 'Add group expense';

  @override
  String get expenseFormEditTitle => 'Edit expense';

  @override
  String get expenseAmount => 'Amount';

  @override
  String get expenseNote => 'Note';

  @override
  String get expenseDate => 'Date';

  @override
  String get expensePayer => 'Payer';

  @override
  String get expenseParticipants => 'Participants';

  @override
  String get expenseSplitEqual => 'Split equally';

  @override
  String get expenseSplitManual => 'Enter amounts manually';

  @override
  String get expenseSplitPercentage => 'By percentage';

  @override
  String get expenseSave => 'Save expense';

  @override
  String get expenseFormMinMembersNotice =>
      'Please add at least 2 members before splitting expenses.';

  @override
  String get expenseFormTotalCost => 'Total cost';

  @override
  String get expenseFormContentLabel => 'Description';

  @override
  String get expenseFormPayer => 'Paid by';

  @override
  String get expenseFormDate => 'Date';

  @override
  String get validationAmountPositive => 'Amount must be greater than 0.';

  @override
  String validationMinMembers(int min) {
    return 'Group must have at least $min members.';
  }

  @override
  String get validationSelectPayer => 'Select a payer.';

  @override
  String get validationSelectParticipant => 'Select at least one participant.';

  @override
  String validationSplitMismatch(String splitTotal, String total) {
    return 'Split total ($splitTotal) must equal expense total ($total).';
  }

  @override
  String get validationNegativeSplit => 'Split amounts cannot be negative.';

  @override
  String get validationInvalidParticipants => 'Invalid list of participants.';

  @override
  String get validationSplitCountMismatch =>
      'Each participant needs exactly one split.';

  @override
  String get profileTitle => 'Profile';

  @override
  String get profileUserDefault => 'Moniary User';

  @override
  String get profileAnonymous => 'Anonymous trial account';

  @override
  String get profileMyData => 'My data';

  @override
  String get profileExportData => 'Export data';

  @override
  String get profileExportSubtitle =>
      'Choose CSV, Excel, or PDF to download personal data.';

  @override
  String get profileImportData => 'Import Data';

  @override
  String get profileImportSubtitle => 'Import from CSV file';

  @override
  String get profilePrivacyCenter => 'Privacy Center';

  @override
  String get profilePrivacySubtitle =>
      'Manage privacy policy, data, and permissions.';

  @override
  String get profileAccount => 'Account';

  @override
  String get profileSignOut => 'Sign out';

  @override
  String get profileSignOutSubtitle =>
      'Sign out of current account on this device.';

  @override
  String get profileDeleteAccount => 'Delete account';

  @override
  String get profileDeleteSubtitle =>
      'Delete personal data, transactions, and saved photos.';

  @override
  String get privacyClearDataSubtitle => 'Clear all app data';

  @override
  String get notificationSettings => 'Notification Settings';

  @override
  String get emailReports => 'Automated Email Reports';

  @override
  String get emailReportsDesc => 'Receive periodic income/expense summaries.';

  @override
  String get dailyReport => 'Daily Report';

  @override
  String get weeklyReport => 'Weekly Report';

  @override
  String get monthlyReport => 'Monthly Report';

  @override
  String get yearlyReport => 'Yearly Report';

  @override
  String get deleteAccountTitle => 'Delete account';

  @override
  String get deleteAccountWarning =>
      'This action will permanently delete all your personal data, transactions, and transaction photos.';

  @override
  String get deleteAccountConfirm => 'Delete account';

  @override
  String get deleteAccountTitleQuestion => 'Delete account?';

  @override
  String get deleteAccountUndone =>
      'This action cannot be undone within the app.';

  @override
  String get deleteAccountConsequence1 =>
      'Delete profile and current login session.';

  @override
  String get deleteAccountConsequence2 =>
      'Delete wallets, categories, and all transactions.';

  @override
  String get deleteAccountConsequence3 =>
      'Delete transaction photos in Storage by user ID.';

  @override
  String get deleteAccountUnderstand =>
      'I understand that my data will be permanently deleted.';

  @override
  String get deleteAccountConfirmationText => 'DELETE ACCOUNT';

  @override
  String deleteAccountConfirmInput(String text) {
    return 'Enter $text to confirm';
  }

  @override
  String get exportTitle => 'Export data';

  @override
  String get exportFormat => 'File format';

  @override
  String get exportDateRange => 'Date range';

  @override
  String get exportAllTime => 'All time';

  @override
  String get exportDataTypes => 'Data types';

  @override
  String get exportButton => 'Export data';

  @override
  String get exportDone => 'Data exported';

  @override
  String get exportHistoryTitle => 'Export history';

  @override
  String get exportHistoryEmpty => 'No export files yet.';

  @override
  String get manageDataTitle => 'Manage data';

  @override
  String get cameraTakePhoto => 'Capture';

  @override
  String get cameraFlip => 'Flip camera';

  @override
  String get cameraNoPermission => 'Camera access required.';

  @override
  String get routeNotFound => 'Page not found';

  @override
  String get routeGoBack => 'Go back';

  @override
  String get statsDevelopingMessage =>
      'Statistics feature is under development.';

  @override
  String get transactionIsImportant => 'Important transaction';

  @override
  String get statsTitle => 'Expense Statistics';

  @override
  String get statsTotalIncome => 'Total Income';

  @override
  String get statsTotalExpense => 'Total Expense';

  @override
  String get statsNetBalance => 'Net Balance';

  @override
  String get statsExpenseButton => 'Total Expense';

  @override
  String get statsIncomeButton => 'Total Income';

  @override
  String get statsEmptyTitle => 'No transactions of this type yet';

  @override
  String get statsEmptySubtitle =>
      'Statistics charts will appear after you add transactions.';

  @override
  String get statsCategoryAllocation => 'Category allocation';

  @override
  String get statsDailyTrend => 'Daily trend';

  @override
  String get statsLargestTransactions => 'Largest transactions';

  @override
  String get profileProtectAccount => 'Protect your account';

  @override
  String get profileAnonymousWarning =>
      'You are logged in with a guest account. Please link your account to avoid data loss when switching devices.';

  @override
  String get profileLinkNow => 'Link now';

  @override
  String get profileLinkAccountTitle => 'Link account';

  @override
  String get profileLinkAccountSubtitle =>
      'Your account is currently anonymous. Link with Email or Google to store data permanently and sign in across devices.';

  @override
  String get profileNewPassword => 'New password';

  @override
  String get profileLinkEmail => 'Link Email';

  @override
  String get profileLinkGoogle => 'Link Google';

  @override
  String get profileLinkSuccess => 'Linked email account successfully!';

  @override
  String get profileLinkGoogleBrowser =>
      'Complete Google linking in browser to return to Moniary.';

  @override
  String profileLinkGoogleError(String error) {
    return 'Google linking error: $error';
  }

  @override
  String get profileEditInfo => 'Edit profile info';

  @override
  String get profileChangeTimezone => 'Change timezone';

  @override
  String get profileAnonymousBadge => 'Anonymous account';

  @override
  String profileVerifiedBadge(String provider) {
    return 'Verified ($provider)';
  }

  @override
  String get profileSignOutDialogTitle => 'Sign out';

  @override
  String get profileSignOutDialogMessage =>
      'Are you sure you want to sign out?';

  @override
  String get profileCancel => 'Cancel';

  @override
  String get exportSupportTitle => 'Export support';

  @override
  String get exportOpenData => 'Open data export';

  @override
  String get exportOpenHistory => 'Open export history';

  @override
  String get exportCreateSupportRequest => 'Create support request';

  @override
  String get legalDataDeletionPolicy => 'Data deletion policy';

  @override
  String get legalDataRetention => 'Data retention';

  @override
  String get legalFinancialDisclaimer => 'Financial disclaimer';

  @override
  String get legalContact => 'Legal contact';

  @override
  String get legalCopyAllContacts => 'Copy all contacts';

  @override
  String get legalCopyContactSuccess => 'Copied contact info.';

  @override
  String get legalPolicyAcceptance => 'Policy acceptance';

  @override
  String get legalViewPrivacyPolicy => 'View privacy policy';

  @override
  String get legalViewTermsOfUse => 'View terms of use';

  @override
  String get legalPolicyChangelog => 'Policy changelog';

  @override
  String get legalTermsOfUse => 'Terms of use';

  @override
  String get legalThirdPartyServices => 'Third-party services';

  @override
  String get legalUserRights => 'Data rights';

  @override
  String get privacyDataSafety => 'Data Safety';

  @override
  String get privacyMyData => 'My data';

  @override
  String get privacyPhotoData => 'Photo data';

  @override
  String get privacyDataFreshness => 'Data freshness';

  @override
  String get privacyLocalFiles => 'Local files';

  @override
  String get privacyTransactionPhotos => 'Transaction photos';

  @override
  String get privacyViewExportHistory => 'View export history';

  @override
  String get privacyPermissionRationale => 'Permission rationale';

  @override
  String get privacyFaq => 'Privacy & account FAQ';

  @override
  String get privacyCenter => 'Privacy center';

  @override
  String get privacyContact => 'Privacy contact';

  @override
  String get privacyUseTemplate => 'Use template';

  @override
  String get privacyCreateRequest => 'Create privacy request';

  @override
  String get privacyRequestCreated => 'Request created';

  @override
  String get privacyCopyEmail => 'Copy email';

  @override
  String get privacyCopyInstructions => 'Copy instructions';

  @override
  String get privacyPolicyTitle => 'Privacy policy';

  @override
  String get privacyRequestDetailTitle => 'Request detail';

  @override
  String get privacyCopyFilePath => 'Copy file path';

  @override
  String get privacyCopyFilePathSuccess => 'Copied file path';

  @override
  String get privacyCopyRequest => 'Copy request';

  @override
  String get privacyCopyRequestSuccess => 'Copied request';

  @override
  String get storeAboutMoniary => 'About Moniary';

  @override
  String get storeComplianceChecklist => 'Release checklist';

  @override
  String get storeTrustSafety => 'Trust & safety';

  @override
  String get supportHelpCenter => 'Help center';

  @override
  String get supportCopySuccess => 'Copied support info.';

  @override
  String get supportCopyDiagnostic => 'Copy diagnostic info';

  @override
  String get supportRequestChecklist => 'Support checklist';

  @override
  String get supportOpenHelpCenter => 'Open help center';

  @override
  String get transactionOcrSuccess => 'Data extracted successfully!';

  @override
  String get scanImageSelectError =>
      'Failed to select image. Please try again.';

  @override
  String get scanImageRequiredError => 'Please select a receipt image first.';

  @override
  String get scanReadError => 'Failed to read receipt. Please try again.';

  @override
  String get commonFeatureUnderDevelopment => 'Feature under development';

  @override
  String get appLockTitle => 'App Locked';

  @override
  String get appLockSubtitle => 'Please authenticate to continue';

  @override
  String get appLockUnlockButton => 'Unlock';

  @override
  String get privacyCenterAppLockTitle => 'App Lock';

  @override
  String get privacyCenterAppLockSubtitle =>
      'Require fingerprint or face to open the app.';

  @override
  String get privacyCenterHideBalancesTitle => 'Hide Balances Mode';

  @override
  String get privacyCenterHideBalancesSubtitle =>
      'Automatically blur all amounts in the app.';

  @override
  String get biometricReasonEnable => 'Authenticate to enable App Lock';

  @override
  String get biometricReasonUnlock => 'Unlock Moniary';

  @override
  String get importTitle => 'Import Data (CSV)';

  @override
  String get importSelectFile => 'Select CSV File';

  @override
  String get importCsvFormatTitle => 'CSV Format Required:';

  @override
  String get importCsvFormatBody =>
      '1. Transaction Date (YYYY-MM-DD)\n2. Amount (e.g. 100000)\n3. Type (Income / Expense)\n4. Category\n5. Note (Optional)\n\nNote: Skip header row if exists.';

  @override
  String get importConfirm => 'Confirm Import';

  @override
  String get importViewHistory => 'View import history';

  @override
  String get importHistoryTitle => 'Import history';

  @override
  String get importDetailTitle => 'Import detail';

  @override
  String get importNoHistory => 'No import history yet.';

  @override
  String get importDetailFileName => 'File name';

  @override
  String get importDetailImportedCount => 'Imported transactions';

  @override
  String get importDetailWallet => 'Target wallet';

  @override
  String get importDetailDate => 'Import date';

  @override
  String get importDetailStatus => 'Status';

  @override
  String get importDetailError => 'Error';

  @override
  String get importStatusPending => 'Importing';

  @override
  String get importStatusCompleted => 'Completed';

  @override
  String get importStatusFailed => 'Failed';

  @override
  String get settingsTitle => 'Settings';

  @override
  String importPreviewTitle(int count) {
    return 'Preview ($count valid rows)';
  }

  @override
  String importSuccess(int count) {
    return 'Imported $count transactions';
  }

  @override
  String get importNoWallets => 'No wallets found. Create a wallet first.';

  @override
  String get importSelectWallet => 'Select target wallet';

  @override
  String importErrorWallets(String error) {
    return 'Error loading wallets: $error';
  }

  @override
  String get importErrorUnknown => 'Unknown error';

  @override
  String get importErrorMissingColumns => 'Missing columns (expected 5)';

  @override
  String get importErrorInvalidDate => 'Invalid date format (use YYYY-MM-DD)';

  @override
  String get importErrorInvalidAmount => 'Invalid amount';

  @override
  String get importErrorInvalidType => 'Invalid transaction type';

  @override
  String get importErrorCategoryNotFound => 'Category was not found';

  @override
  String get importRetry => 'Try again';

  @override
  String get activeSessionsTitle => 'Devices & Sessions';

  @override
  String get activeSessionsEmpty => 'No active sessions found.';

  @override
  String activeSessionsError(String error) {
    return 'Error: $error';
  }

  @override
  String get activeSessionsUnknownDevice => 'Unknown device';

  @override
  String get activeSessionsThisDevice => 'This device';

  @override
  String activeSessionsFirstLogin(String date) {
    return 'First login: $date';
  }

  @override
  String activeSessionsLastActive(String date) {
    return 'Last active: $date';
  }

  @override
  String activeSessionsIp(String ip) {
    return 'IP: $ip';
  }

  @override
  String get activeSessionsRevokeTooltip => 'Log out this device';

  @override
  String get activeSessionsRevokeTitle => 'Log out device?';

  @override
  String get activeSessionsRevokeContent =>
      'This device will be immediately logged out of your account.';

  @override
  String get activeSessionsRevokeConfirm => 'Log out';

  @override
  String get restoreAccountTitle => 'Account Pending Deletion';

  @override
  String get restoreAccountBody =>
      'Your account has been deactivated and is in a 30-day grace period before permanent deletion.\n\nDo you want to restore your account?';

  @override
  String get restoreAccountButton => 'Restore Account';

  @override
  String get validationEmailRequired => 'Email is required';

  @override
  String get validationEmailInvalid => 'Invalid email';

  @override
  String validationPasswordMinLength(int min) {
    return 'Password must be at least $min characters';
  }

  @override
  String get exportFormatCsvDesc =>
      'Lightweight data sheet, opens in Excel or Google Sheets.';

  @override
  String get exportFormatXlsxDesc =>
      '.xlsx workbook for Excel, Sheets, or WPS Office.';

  @override
  String get exportFormatPdfDesc =>
      'Easy-to-read report to save or share with others.';

  @override
  String exportFileSavedAt(String path) {
    return 'File has been saved at:\n$path';
  }

  @override
  String get exportNoAppToShare => 'No suitable app found to share the file.';

  @override
  String get exportNoAppToOpen => 'No suitable app found to open the file.';

  @override
  String get commonComingSoon => 'Coming soon';

  @override
  String activeSessionsDeviceOn(String browser, String os) {
    return '$browser on $os';
  }

  @override
  String get activeSessionsOtherOs => 'Other OS';

  @override
  String get activeSessionsOtherBrowser => 'Other browser/app';
}
