// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get budgetEditLimit => 'Edit limit';

  @override
  String get budgetQuickPresets => 'Quick presets';

  @override
  String get budgetWarningThreshold => 'Warn at';

  @override
  String get budgetCategoryDetailTitle => 'Budget detail';

  @override
  String get budgetTransactionsInLimit => 'Transactions in this limit';

  @override
  String get budgetNoTransactions => 'No transactions in this category yet.';

  @override
  String get appName => 'Moniary';

  @override
  String get commonSave => 'Save';

  @override
  String get commonSaved => 'Saved';

  @override
  String get commonCancel => 'Cancel';

  @override
  String get commonDelete => 'Delete';

  @override
  String get commonEdit => 'Edit';

  @override
  String get commonRetry => 'Retry';

  @override
  String get commonJustNow => 'Just now';

  @override
  String commonMinutesAgo(int count) {
    return '${count}m ago';
  }

  @override
  String commonHoursAgo(int count) {
    return '${count}h ago';
  }

  @override
  String commonDaysAgo(int count) {
    return '${count}d ago';
  }

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
  String get commonViewAll => 'View all';

  @override
  String get commonSelect => 'Select';

  @override
  String get commonCreate => 'Create';

  @override
  String get commonConfirm => 'Confirm';

  @override
  String get errorGeneric => 'An error occurred. Please try again.';

  @override
  String get errorLocalAuthUnavailable =>
      'This device does not support biometric or screen-lock authentication.';

  @override
  String get errorLocalAuthFailed =>
      'Device authentication failed. Please try again.';

  @override
  String get errorNotLoggedIn => 'You are not logged in.';

  @override
  String get errorNotFound => 'Data not found.';

  @override
  String get errorConnection => 'Connection error. Please try again.';

  @override
  String get loginTitle => 'Moniary';

  @override
  String get loginSubtitle => 'Personal expense manager';

  @override
  String get loginAnonymous => 'Continue as guest';

  @override
  String get loginTerms =>
      'By continuing, you agree to Moniary\'s terms of use and privacy policy.';

  @override
  String get loginFeatureSubtitle => 'Track expenses with photos';

  @override
  String get loginHeader => 'Sign In';

  @override
  String get loginGoogle => 'Sign in with Google';

  @override
  String get loginApple => 'Sign in with Apple';

  @override
  String get loginFacebook => 'Sign in with Facebook';

  @override
  String get loginEmail => 'Sign in with Email';

  @override
  String get loginOr => 'or';

  @override
  String get loginConnecting => 'Signing in...';

  @override
  String get loginTryWithoutAuth => 'Try without logging in';

  @override
  String get loginSessionReady =>
      'You\'re signed in. Opening your spending calendar...';

  @override
  String get loginDataSecure => 'Your data is protected and synced securely.';

  @override
  String get loginForgotPassword => 'Forgot password?';

  @override
  String get loginNoAccount => 'No account yet?';

  @override
  String get loginRegisterNow => 'Register now';

  @override
  String get loginHaveAccount => 'Already have an account?';

  @override
  String get loginSocialDivider => 'Or sign in with';

  @override
  String get loginDemoCta => 'DEMO';

  @override
  String get loginGuestCta => 'Try it now — no account needed →';

  @override
  String get loginPasswordResetSent =>
      'Password reset instructions were sent by email.';

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
  String get onboardingPage1Title1 => 'Scan a receipt,';

  @override
  String get onboardingPage1Title2 => 'save it in one tap';

  @override
  String get onboardingPage1Subtitle => 'Reading your receipt';

  @override
  String get onboardingPage1Caption =>
      'Scan a receipt and fill the amount, date, wallet and category automatically.';

  @override
  String get onboardingPage2Title1 => 'Every day becomes';

  @override
  String get onboardingPage2Title2 => 'a small photograph';

  @override
  String get onboardingPage2Subtitle =>
      'Look back at the month like an album, not a spreadsheet.';

  @override
  String get onboardingPage2Caption =>
      'Every transaction becomes a small piece of your diary.';

  @override
  String get onboardingPage3Title1 => 'A clear budget,';

  @override
  String get onboardingPage3Title2 => 'understood in seconds';

  @override
  String get onboardingPage3Subtitle =>
      'Track each category and get a warning before you cross its limit.';

  @override
  String get onboardingPage3Caption =>
      'Keep an eye on limits without reading complicated tables.';

  @override
  String get onboardingReceiptCategory => 'Food & dining';

  @override
  String get onboardingReceiptDate => '15 Jun';

  @override
  String get onboardingReceiptAmount => '385,000';

  @override
  String get onboardingPhotoAmount => '−145,000 ₫';

  @override
  String get onboardingBudgetPercent => '70%';

  @override
  String get onboardingBudgetLabel => 'Monthly budget';

  @override
  String get onboardingScanning => 'Reading receipt...';

  @override
  String get onboardingRecognized => 'Recognised!';

  @override
  String get onboardingCategoryFood => 'Food & dining';

  @override
  String get onboardingCategoryTransport => 'Transport';

  @override
  String get onboardingCategoryEntertainment => 'Entertainment';

  @override
  String get onboardingIncome => 'Income';

  @override
  String get onboardingExpenseLabel => 'Expense';

  @override
  String get onboardingStreakLabel => 'days';

  @override
  String get onboardingBudgetUsed => 'Used';

  @override
  String get onboardingBudgetWarning => 'Nearing limit!';

  @override
  String get onboardingInsightText => 'Food spending up 20%';

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
  String profileSurveyWelcomeTitle(String name) {
    return 'It is lovely to meet you, $name!';
  }

  @override
  String get profileSurveyWelcomeBody =>
      'A few quick choices will help Moniary prepare an experience that fits you.';

  @override
  String get profileSurveyFallbackName => 'friend';

  @override
  String get profileSurveyOccupationTitle => 'What do you currently do?';

  @override
  String get profileSurveyOccupationBody =>
      'Moniary will use this to suggest categories and a tracking style that fits you.';

  @override
  String get profileSurveyOccupationStudent => 'Student';

  @override
  String get profileSurveyOccupationOffice => 'Office worker';

  @override
  String get profileSurveyOccupationFreelancer => 'Freelancer';

  @override
  String get profileSurveyOccupationBusiness => 'Business owner';

  @override
  String get profileSurveyOccupationOther => 'Other';

  @override
  String get profileSurveyCurrencyTitle => 'Choose the currency you use';

  @override
  String get profileSurveyCurrencyBody =>
      'Moniary will use it for balances and reports.';

  @override
  String get profileSurveyCurrencyVnd => 'Vietnamese Dong';

  @override
  String get profileSurveyCurrencyVgo => 'Vietnamese Gold (SJC)';

  @override
  String get profileSurveyCurrencyUsd => 'United States Dollar';

  @override
  String get profileSurveyWalletTitle => 'Create your first Wallet';

  @override
  String get profileSurveyWalletBody =>
      'How much money is currently in this Wallet?';

  @override
  String get profileSurveyWalletName => 'Wallet name';

  @override
  String get profileSurveyWalletDefaultName => 'My Wallet';

  @override
  String get profileSurveyAmountLabel => 'Amount';

  @override
  String get profileSurveyAmountHint => '0';

  @override
  String get profileSurveyNext => 'Continue';

  @override
  String get profileSurveyFinish => 'Create wallet and start';

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
  String get calendarAllFilter => 'All';

  @override
  String get calendarSaved => 'Saved';

  @override
  String get calendarSearchLabel => 'Search';

  @override
  String get calendarWalletsCategoriesAction => 'Wallets';

  @override
  String get calendarMonthlyExpense => 'Monthly Expense';

  @override
  String get calendarMonthlyIncome => 'Monthly Income';

  @override
  String get calendarEmptyMessage =>
      'No transactions this month yet. You can still pick a day or tap + to add one.';

  @override
  String get calendarTodayEmptyMessage =>
      'No transactions today yet. Tap + to record a new income or expense.';

  @override
  String calendarStatsMessage(int count, int days) {
    return '$count transactions across $days active days. Calendar data is up to date.';
  }

  @override
  String calendarLoadError(String error) {
    return 'Could not load calendar: $error';
  }

  @override
  String get calendarStatsTab => 'Stats';

  @override
  String get navStatsLabel => 'Stats';

  @override
  String get navGroupsLabel => 'Groups';

  @override
  String get navProfileLabel => 'Me';

  @override
  String get calendarLoading => 'Syncing calendar...';

  @override
  String get calendarEmptyTitle => 'Nothing here!';

  @override
  String get calendarEmptyBody =>
      'You don\'t have any transactions this month. Add a new transaction to start tracking.';

  @override
  String get calendarErrorTitle => 'Data load error';

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
  String get calendarStarred => 'Starred';

  @override
  String get calendarSearchHint => 'Search by note or category...';

  @override
  String get calendarSearchPrompt => 'Enter a note or category to search.';

  @override
  String get calendarSearchNoResults => 'No transactions found.';

  @override
  String get calendarRecentSearches => 'Recent searches';

  @override
  String get calendarRecentSearchCoffee => 'coffee';

  @override
  String get calendarRecentSearchRide => 'grab';

  @override
  String get calendarRecentSearchMarket => 'market';

  @override
  String calendarSearchResultsHeader(String query, int count) {
    return 'Results · \"$query\" · $count';
  }

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
  String get transactionAddForDay => 'Add an entry for this day';

  @override
  String get transactionDayGridView => 'Grid';

  @override
  String get transactionDayListView => 'List';

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
  String get transactionAmountSuffix => 'đ';

  @override
  String get transactionAmountHint => '0';

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
  String get transactionCreateTitle => 'Add transaction';

  @override
  String get transactionEditTitle => 'Edit transaction';

  @override
  String get transactionDetailTitle => 'Transaction';

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
  String get transactionSource => 'Source';

  @override
  String get transactionSourceManual => 'Manual entry';

  @override
  String get transactionSourceReceiptImage => 'Receipt photo';

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
  String get walletUnknown => 'Unknown wallet';

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
  String get categoryOther => 'Other';

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
  String scanQuantity(String quantity) {
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
  String get groupListTitle => 'Groups';

  @override
  String groupListSection(int count) {
    return 'Your groups · $count';
  }

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
  String get groupDetailKindLabel => 'Group';

  @override
  String get groupMoreActions => 'Group actions';

  @override
  String groupTransactionCount(int count) {
    return '$count expenses';
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
  String get groupInvitationsTitle => 'Group invitations';

  @override
  String get groupInvitationsEmpty => 'You do not have any group invitations.';

  @override
  String get groupInvitationsEmptySubtitle =>
      'Invitations sent through username or friends will appear here.';

  @override
  String get groupInvitationsLoadError => 'Could not load group invitations.';

  @override
  String groupInvitationInvitedBy(String name) {
    return '$name invited you to join.';
  }

  @override
  String groupInvitationExpiresAt(String date) {
    return 'Expires on $date';
  }

  @override
  String get groupInvitationAccept => 'Accept';

  @override
  String get groupInvitationDecline => 'Decline';

  @override
  String get groupInvitationDeclinedSuccess => 'Group invitation declined.';

  @override
  String get groupInvitationPending => 'Pending';

  @override
  String get groupInvitationAccepted => 'Joined';

  @override
  String get groupInvitationDeclined => 'Declined';

  @override
  String get groupInvitationExpired => 'Expired';

  @override
  String get groupInvitationRevoked => 'Revoked';

  @override
  String get groupInvitationInvalid => 'This invitation is no longer valid.';

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
  String get editProfileTitle => 'Edit Profile';

  @override
  String get profileUserDefault => 'Moniary User';

  @override
  String get profileAnonymous => 'Guest account';

  @override
  String get profileMyData => 'My Data';

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
  String get profileMoniarySetup => 'Moniary Setup';

  @override
  String get profileGeneralSection => 'General';

  @override
  String get profileSupportSection => 'Support';

  @override
  String get profilePrivacySafetySection => 'Privacy & Safety';

  @override
  String get profileDangerZoneSection => 'Danger Zone';

  @override
  String get profileHowMoniaryWorksTitle => 'How Moniary works';

  @override
  String get profileHowMoniaryWorksSubtitle =>
      'Quick guide for recording and reviewing your finances.';

  @override
  String get profileSetupGuideWalletTitle => 'Set up wallets';

  @override
  String get profileSetupGuideWalletBody =>
      'Create or review wallets so transactions have a clear money source.';

  @override
  String get profileSetupGuideTransactionTitle => 'Add transactions';

  @override
  String get profileSetupGuideTransactionBody =>
      'Capture spending with photos or enter transactions manually.';

  @override
  String get profileSetupGuideReviewTitle => 'Review Calendar and Stats';

  @override
  String get profileSetupGuideReviewBody =>
      'Use Calendar and Statistics to understand spending by day and month.';

  @override
  String get profileSetupGuideExportTitle => 'Export and protect data';

  @override
  String get profileSetupGuideExportBody =>
      'Export your data and review privacy controls whenever needed.';

  @override
  String get profilePrivacyCenter => 'Privacy Center';

  @override
  String get privacyGroupPrivacyTermsTitle => 'Privacy & Terms';

  @override
  String get privacyGroupPrivacyTermsSubtitle =>
      'Policies, terms, and legal notices.';

  @override
  String get privacyTermsPolicySubtitle =>
      'Personal data, financial records, photos, and third-party services.';

  @override
  String get privacyTermsLimitationsTitle => 'Terms & Limitations';

  @override
  String get privacyTermsLimitationsSubtitle =>
      'Usage scope, user responsibilities, and financial disclaimer.';

  @override
  String get privacyTermsRecordsTitle => 'Policy Records';

  @override
  String get privacyTermsRecordsSubtitle =>
      'Policy updates, acceptance notice, and legal contact.';

  @override
  String get privacyGroupDataSafetyTitle => 'Data Safety';

  @override
  String get privacyGroupDataSafetySubtitle =>
      'Data, permissions, and Play Store disclosures.';

  @override
  String get privacyDataOverviewTitle => 'Data Overview';

  @override
  String get privacyDataOverviewSubtitle =>
      'Stored data, collected groups, and account data summary.';

  @override
  String get privacyDataControlsTitle => 'Data Controls';

  @override
  String get privacyDataControlsSubtitle =>
      'Data rights, retention, and deletion policies.';

  @override
  String get privacyGroupHelpRequestsTitle => 'Help & Requests';

  @override
  String get privacyGroupHelpRequestsSubtitle =>
      'Support, contacts, and privacy requests.';

  @override
  String get privacyHelpCenterSubtitle =>
      'Guides, troubleshooting, and safe use notes.';

  @override
  String get privacyRequestsTitle => 'Privacy Requests';

  @override
  String get privacyRequestsSubtitle =>
      'Contact support or request help with privacy and deletion.';

  @override
  String get privacyAboutSubtitle =>
      'App purpose, current version status, and release information.';

  @override
  String get profileAccount => 'Account';

  @override
  String get profileSignOut => 'Sign Out';

  @override
  String get profileSignOutSubtitle =>
      'Sign out of current account on this device.';

  @override
  String get profileDeleteAccount => 'Delete Account';

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
  String dailyReportDesc(String time) {
    return 'Every day at $time';
  }

  @override
  String get weeklyReport => 'Weekly Report';

  @override
  String get weeklyReportDesc => 'Once a week';

  @override
  String get monthlyReport => 'Monthly Report';

  @override
  String get monthlyReportDesc => 'Once a month';

  @override
  String get yearlyReport => 'Yearly Report';

  @override
  String get yearlyReportDesc => 'Once a year';

  @override
  String get reminderSectionTitle => 'Device reminders';

  @override
  String get reminderSectionDesc =>
      'A notification right on your phone, nudging you to log today\'s spending.';

  @override
  String get reminderDailyTitle => 'Daily logging reminder';

  @override
  String reminderDailyDesc(String time) {
    return 'Every day at $time';
  }

  @override
  String get reminderNotificationTitle =>
      'Don\'t forget to log your spending 💸';

  @override
  String get reminderNotificationBody =>
      'Take a few seconds to record today\'s transactions.';

  @override
  String get reminderPermissionDenied =>
      'Enable notification permission in system settings to receive reminders.';

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
      'Delete transaction photos linked to the current account.';

  @override
  String get deleteAccountUnderstand =>
      'I understand that my data will be permanently deleted.';

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
  String get exportDataTypeTransactions => 'Transactions';

  @override
  String get exportDataTypeWallets => 'Wallets';

  @override
  String get exportDataTypeCategories => 'Categories';

  @override
  String get exportButton => 'Export data';

  @override
  String get exportDone => 'Data exported';

  @override
  String get exportHistoryTitle => 'Export History';

  @override
  String get exportHistoryEmpty => 'No export files yet.';

  @override
  String get exportRecentTitle => 'Recent exports';

  @override
  String get exportRecentHistoryError => 'Could not load recent exports.';

  @override
  String get manageDataTitle => 'Manage data';

  @override
  String get manageDataWalletTab => 'Wallets';

  @override
  String get manageDataWalletCountLabel => 'wallets';

  @override
  String get manageDataCategoryCountLabel => 'categories';

  @override
  String get cameraTakePhoto => 'Capture';

  @override
  String get cameraFlip => 'Flip camera';

  @override
  String get cameraFlash => 'Flash';

  @override
  String get cameraNoPermission => 'No camera permission';

  @override
  String get cameraTitle => 'Take a photo of receipt';

  @override
  String get cameraOcrScan => 'OCR Scan';

  @override
  String get cameraGallery => 'Gallery';

  @override
  String get accountDeletionRequestTitle => 'Data Deletion Request';

  @override
  String get accountDeletionRequestDesc =>
      'Use this option when you cannot delete your account directly in the app. Moniary will create a request file for you to send to privacy support.';

  @override
  String get accountDeletionRequestReasonLabel =>
      'Reason or notes for the request';

  @override
  String get accountDeletionRequestReasonHint =>
      'Example: I no longer use the app and want to delete all data.';

  @override
  String get accountDeletionRequestSubmit => 'Create data deletion request';

  @override
  String get accountDeletionRequestSuccessDesc =>
      'The request has been created. Please check the history and send the request manually.';

  @override
  String get deleteAccountHelpTitle => 'Account Deletion Help';

  @override
  String get deleteAccountHelpHero =>
      'Deleting an account is a major action. This guide helps users prepare data and know how to send support requests when needed.';

  @override
  String get deleteAccountHelpStep1Title => '1. Export data before deleting';

  @override
  String get deleteAccountHelpStep1Desc =>
      'After deleting the account, app data linked to the current user may not be recoverable. Export CSV, Excel, or PDF first if you need a copy.';

  @override
  String get deleteAccountHelpStep2Title => '2. Check transaction images';

  @override
  String get deleteAccountHelpStep2Desc =>
      'Transaction images are processed along with account data. Download or save necessary files before deleting.';

  @override
  String get deleteAccountHelpStep3Title => '3. Confirm carefully in the app';

  @override
  String get deleteAccountHelpStep3Desc =>
      'The account deletion flow requires strong confirmation to avoid accidental actions.';

  @override
  String get deleteAccountHelpStep4Title => '4. Use fallback if deletion fails';

  @override
  String get deleteAccountHelpStep4Desc =>
      'If direct action fails, create a manual data deletion request file and attach an error description to the support channel.';

  @override
  String get deleteAccountHelpExportBefore => 'Export data first';

  @override
  String get deleteAccountHelpCreateRequest => 'Create data deletion request';

  @override
  String get deleteAccountHelpContactPrivacy => 'Contact privacy support';

  @override
  String get legalContactHero =>
      'Use these contact channels to send data, support, or legal requests to the right place.';

  @override
  String get legalContactPrivacyDesc =>
      'Personal data requests, data deletion, or privacy questions.';

  @override
  String get legalContactSupportDesc =>
      'General app support, file export, or user actions.';

  @override
  String get legalContactLegalDesc =>
      'Terms issues, release questions, or legal requests.';

  @override
  String get legalContactPrivacy => 'Privacy';

  @override
  String get legalContactSupport => 'Support';

  @override
  String get legalContactLegal => 'Legal';

  @override
  String privacyDetailCreatedAt(String date) {
    return 'Created at $date';
  }

  @override
  String get privacyDetailExpectedResponse => 'Expected response';

  @override
  String privacyDetailExpectedResponseDesc(String date, int days) {
    return '$date or within $days business days after submission.';
  }

  @override
  String privacyDetailMarkStatus(String status) {
    return 'Mark as: $status';
  }

  @override
  String get privacyDetailContentTitle => 'Request content';

  @override
  String get privacyDetailContentEmpty => 'No additional content.';

  @override
  String get privacyDetailFileTitle => 'Created file';

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
  String get statsWeeklySpending => 'Weekly spending';

  @override
  String get statsCategories => 'Categories';

  @override
  String statsMonthExpenseMeta(String month) {
    return 'Total expense · $month';
  }

  @override
  String statsExpenseLessThanPrevious(int percent) {
    return '↓ Less than last month by $percent%';
  }

  @override
  String statsExpenseMoreThanPrevious(int percent) {
    return '↑ Higher than last month by $percent%';
  }

  @override
  String get statsExpenseSameAsPrevious => 'About the same as last month';

  @override
  String get statsExpenseNoPrevious => 'No previous month data yet';

  @override
  String get statsInsightTitle => 'Smart insights';

  @override
  String statsInsightSavings(String percent) {
    return 'You saved $percent% of your income this month.';
  }

  @override
  String statsInsightWeekend(String percent) {
    return 'You spent $percent% of your budget on weekends. Be careful!';
  }

  @override
  String statsInsightCategorySurge(String category, String percent) {
    return '$category spending increased $percent% compared to last month.';
  }

  @override
  String get statsInsightPositive =>
      'You\'re managing your spending well! Keep it up.';

  @override
  String statsBudgetUsed(int percent) {
    return 'Budget · used $percent%';
  }

  @override
  String get statsBudgetNoLimit => 'Budget';

  @override
  String statsWeekLabel(int week) {
    return 'Week $week';
  }

  @override
  String get statsMillionShort => 'm';

  @override
  String get statsLargestTransactions => 'Largest transactions';

  @override
  String get starredTransactionsTitle => 'Starred Transactions';

  @override
  String get starredTransactionsEmpty => 'No starred transactions yet';

  @override
  String get statsCategoryTransactions => 'Transactions in this category';

  @override
  String statsDayTooltip(int day, String amount) {
    return 'Day $day\n$amount';
  }

  @override
  String get profileProtectAccount => 'Protect your account';

  @override
  String get profileAnonymousWarning =>
      'You are using a guest account. Link Email or Google to keep your data when switching devices.';

  @override
  String get profileLinkNow => 'Link now';

  @override
  String get profileLinkAccountTitle => 'Link account';

  @override
  String get profileLinkAccountSubtitle =>
      'Your account is currently a guest account. Link Email or Google to save your data and sign in across devices.';

  @override
  String get profileNewPassword => 'New password';

  @override
  String get profileLinkEmail => 'Link Email';

  @override
  String get profileLinkGoogle => 'Link Google';

  @override
  String get profileLinkApple => 'Link Apple';

  @override
  String get profileLinkSuccess => 'Linked account successfully!';

  @override
  String get profileLinkGoogleBrowser =>
      'Complete Google linking in browser to return to Moniary.';

  @override
  String get profileLinkAppleBrowser =>
      'Complete Apple linking in browser to return to Moniary.';

  @override
  String profileLinkGoogleError(String error) {
    return 'Google linking error: $error';
  }

  @override
  String profileLinkAppleError(String error) {
    return 'Apple linking error: $error';
  }

  @override
  String get profileEditInfo => 'Edit information';

  @override
  String get profileChangeTimezone => 'Change Timezone';

  @override
  String get profileMascotTitle => 'App Mascot';

  @override
  String get profileMascotSubtitle =>
      'Show the animated mascot on the bottom navigation bar.';

  @override
  String get profileLanguage => 'Language';

  @override
  String get currencyPickerTitle => 'Select Currency';

  @override
  String get currencyPickerSearch => 'Search currency...';

  @override
  String get currencyPickerNoResults => 'No currencies found';

  @override
  String get currencyPickerPopular => 'Popular Currencies';

  @override
  String get currencyPickerAll => 'All Currencies';

  @override
  String get profileFirstDayOfWeekLabel => 'First day of the week';

  @override
  String get profileFirstDayOfWeekMon => 'Monday';

  @override
  String get profileFirstDayOfWeekSun => 'Sunday';

  @override
  String get profileLanguageVi => 'Vietnamese';

  @override
  String get profileLanguageEn => 'English';

  @override
  String get timezonePickerSearch => 'Search timezone';

  @override
  String get timezonePickerNoResults => 'No timezones found';

  @override
  String get timezonePickerUseDevice => 'Use device timezone';

  @override
  String get profileAnonymousBadge => 'Guest account';

  @override
  String profileVerifiedBadge(String provider) {
    return 'Verified ($provider)';
  }

  @override
  String get profileSignOutDialogTitle => 'Sign Out';

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
  String get exportTroubleshootingHero =>
      'This guide helps you quickly troubleshoot CSV, Excel, or PDF files that are empty, cannot be opened, or cannot be found after export.';

  @override
  String get exportTroubleshootingTypeTitle => '1. Check selected data types';

  @override
  String get exportTroubleshootingTypeDesc =>
      'If the file is empty, check whether you selected Transactions, Wallets, or Categories in the export filters.';

  @override
  String get exportTroubleshootingDateTitle => '2. Check date range';

  @override
  String get exportTroubleshootingDateDesc =>
      'If the selected date range is too narrow, the file may not contain matching transactions.';

  @override
  String get exportTroubleshootingHistoryTitle =>
      '3. Reopen from export history';

  @override
  String get exportTroubleshootingHistoryDesc =>
      'After creating a file, open export history to access the file path and share it when needed.';

  @override
  String get exportTroubleshootingSupportTitle => '4. Create a support request';

  @override
  String get exportTroubleshootingSupportDesc =>
      'If the file cannot be created or opened, create a support request with an error description.';

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
  String legalCopyAllText(
    String privacyEmail,
    String supportEmail,
    String legalEmail,
  ) {
    return 'Privacy: $privacyEmail\nSupport: $supportEmail\nLegal: $legalEmail';
  }

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
  String get privacyFaqHeroBody =>
      'Frequently asked questions about personal data, export, account deletion, and privacy requests.';

  @override
  String get privacyFaqStoredDataQuestion => 'What data does Moniary store?';

  @override
  String get privacyFaqStoredDataAnswer =>
      'The app stores profiles, wallets, categories, transactions, notes, and transaction image paths when users create data in the app.';

  @override
  String get privacyFaqExportBeforeDeletionQuestion =>
      'Can I export my data before deleting my account?';

  @override
  String get privacyFaqExportBeforeDeletionAnswer =>
      'Yes. You can export data as CSV, Excel, or PDF in the Export my data section.';

  @override
  String get privacyFaqDeletionImagesQuestion =>
      'Does deleting my account also delete transaction images?';

  @override
  String get privacyFaqDeletionImagesAnswer =>
      'The account deletion flow is designed to delete app data and transaction images linked to the current user.';

  @override
  String get privacyFaqDeletionFailQuestion =>
      'What if direct account deletion fails?';

  @override
  String get privacyFaqDeletionFailAnswer =>
      'You can create a manual data deletion request file and send it to the privacy support channel.';

  @override
  String get privacyFaqExportLocationQuestion =>
      'Where are export files stored?';

  @override
  String get privacyFaqExportLocationAnswer =>
      'Export files are saved in the app\'s documents folder on the device and can be opened or shared from the export history.';

  @override
  String get privacyCenter => 'Privacy Center';

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
  String get privacyPolicyTitle => 'Privacy Policy';

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
  String get supportCopyDiagnostic => 'Copy support info';

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
  String get importRecentTitle => 'Recent imports';

  @override
  String get importRecentHistoryError => 'Could not load recent imports.';

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
  String get settingsAccountSection => 'Account';

  @override
  String get settingsDataSection => 'Data';

  @override
  String get settingsLegalSupportSection => 'Legal & Help';

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
  String get exportFormatCsvLabel => 'CSV';

  @override
  String get exportFormatCsvDesc =>
      'Lightweight data sheet, opens in Excel or Google Sheets.';

  @override
  String get exportFormatXlsxLabel => 'Excel';

  @override
  String get exportFormatXlsxDesc =>
      '.xlsx workbook for Excel, Sheets, or WPS Office.';

  @override
  String get exportFormatPdfLabel => 'PDF';

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
  String get exportDetailTitle => 'Export detail';

  @override
  String get exportDetailFileInfo => 'File information';

  @override
  String get exportDetailTime => 'Time';

  @override
  String get exportDetailFormat => 'Format';

  @override
  String get exportDetailStatus => 'Status';

  @override
  String get exportDetailReady => 'Ready';

  @override
  String get exportDetailMissing => 'File deleted';

  @override
  String get exportDetailDataConfig => 'Data configuration';

  @override
  String get exportDetailDataRange => 'Data time range';

  @override
  String get exportDetailDataGroups => 'Data groups';

  @override
  String get exportDetailStoragePath => 'Storage path';

  @override
  String get exportDetailLocation => 'Location';

  @override
  String get exportDetailOpenFile => 'Open file now';

  @override
  String get exportDetailShareFile => 'Share via Email / Zalo';

  @override
  String get exportDetailMissingMessage =>
      'This file no longer exists on this device. You can export the data again with similar filters.';

  @override
  String get exportDetailSuccessTitle => 'Data exported successfully';

  @override
  String get exportDetailReportSubtitle => 'Moniary Financial Report';

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

  @override
  String get privacyReqDataAccess => 'Data Access';

  @override
  String get privacyReqDataAccessDesc =>
      'Request Moniary to provide information about the data associated with your account.';

  @override
  String get privacyReqExportHelp => 'Data Export Help';

  @override
  String get privacyReqExportHelpDesc =>
      'Request assistance when unable to self-export data in the app.';

  @override
  String get privacyReqCorrection => 'Data Correction';

  @override
  String get privacyReqCorrectionDesc =>
      'Request to adjust incorrect personal or financial data.';

  @override
  String get privacyReqDeletion => 'Data Deletion';

  @override
  String get privacyReqDeletionDesc =>
      'Request to delete data or get help when account deletion fails.';

  @override
  String get privacyReqComplaint => 'Privacy Complaint';

  @override
  String get privacyReqComplaintDesc =>
      'Send feedback on how personal data is handled in Moniary.';

  @override
  String get privacyStatusReady => 'Ready to send';

  @override
  String get privacyStatusReadyDesc =>
      'The request file has been created and is waiting for you to send it.';

  @override
  String get privacyStatusSent => 'Sent manually';

  @override
  String get privacyStatusSentDesc =>
      'The user has sent the request via email or support channel.';

  @override
  String get privacyStatusResolved => 'Resolved';

  @override
  String get privacyStatusResolvedDesc =>
      'The request has been processed or no longer needs tracking.';

  @override
  String get privacyTplDataAccess =>
      'I want to know what data Moniary is currently storing about my account.';

  @override
  String get privacyTplExportHelp =>
      'I need help exporting account data as I cannot complete it within the app.';

  @override
  String get privacyTplCorrection =>
      'I want to request correction of inaccurate data in my account. The data to check is:';

  @override
  String get privacyTplDeletion =>
      'I want to request the deletion of my personal and financial data linked to my account.';

  @override
  String get privacyTplComplaint =>
      'I want to submit feedback or a complaint about how Moniary handles my personal data.';

  @override
  String get privacyTplDefault =>
      'I need support regarding privacy and personal data in Moniary.';

  @override
  String get privacyContactRequestType => 'Request Type';

  @override
  String get privacyContactRequestContent => 'Request Content';

  @override
  String get privacyContactRequestHint =>
      'Briefly describe what you need support with.';

  @override
  String get privacyContactPreview => 'Request Preview';

  @override
  String get privacyContactPreviewEmpty => 'Request content is empty.';

  @override
  String get privacyContactProcessTimeline => 'Response Process';

  @override
  String get privacyContactProcessStep1 => 'Create request in app';

  @override
  String get privacyContactProcessStep1Desc =>
      'The app prepares the content for you to send to support.';

  @override
  String get privacyContactProcessStep2 => 'Send request manually';

  @override
  String privacyContactProcessStep2Desc(String email) {
    return 'Send the request via email to $email.';
  }

  @override
  String get privacyContactProcessStep3 => 'Track response';

  @override
  String privacyContactProcessStep3Desc(int days) {
    return 'Expected response time is $days business days.';
  }

  @override
  String get privacyContactShortcuts => 'Support Shortcuts';

  @override
  String get privacyContactCopyEmailSuccess => 'Support email copied.';

  @override
  String privacyContactCopyGuide(String email) {
    return 'Email: $email\nSubject: Moniary support request\nContent: Paste the request content copied from the app.';
  }

  @override
  String get privacyContactCopyGuideSuccess => 'Request instructions copied.';

  @override
  String get privacyContactHeroTitle => 'Personal Data Requests';

  @override
  String get privacyContactHeroDesc =>
      'If something cannot be handled in the app, contact Moniary support for help with your data.';

  @override
  String get privacyContactEmailTitle => 'Support Email';

  @override
  String get privacyContactEmailDesc =>
      'Used for data deletion, export requests, or privacy questions.';

  @override
  String get privacyContactInfoTitle => 'Information to Send';

  @override
  String get privacyContactInfoValue => 'Account ID or login email';

  @override
  String get privacyContactInfoDesc =>
      'Do not send passwords, access codes, sensitive receipt photos, or detailed amounts via email.';

  @override
  String get privacyContactTimeTitle => 'Response Time';

  @override
  String get privacyContactTimeValue => 'Within 7 business days';

  @override
  String get privacyContactTimeDesc =>
      'Moniary will update actual response times before the public release.';

  @override
  String get privacyContactRecentRequests => 'Recent Requests';

  @override
  String get privacyContactRequestStatus => 'Status';

  @override
  String get privacyContactRequestFile => 'Attached file';

  @override
  String get privacyRequestSuccessDesc =>
      'Request created. Please check history and send the request manually.';

  @override
  String get privacyAndAccountTitle => 'Privacy & Account';

  @override
  String get privacyAndAccountSubtitle =>
      'View data rights, privacy requests, and account-related options.';

  @override
  String get dataRightsTitle => 'Data Rights';

  @override
  String get dataRightsSubtitle =>
      'Summary of rights to view, export, edit/delete data, and privacy contact.';

  @override
  String get exportDataSubTitle =>
      'Troubleshooting CSV, Excel, or PDF export errors, empty files, or missing files.';

  @override
  String get createExportFileTitle => 'Create Export File';

  @override
  String get createExportFileSubtitle =>
      'Open export flow to create a copy of your personal data.';

  @override
  String get contactSupportSubtitle =>
      'Create a privacy request or copy contact info to send to the support team.';

  @override
  String get deleteAccountSubtitle =>
      'Preparation before deletion, understanding affected data, and fallbacks.';

  @override
  String get supportChecklistTitle => 'Support Checklist';

  @override
  String get supportChecklistSubtitle =>
      'Prepare a bug description, related files, and support info before sending a request.';

  @override
  String get helpHeroText =>
      'Quickly find guides on data, privacy, export, and account support in Moniary.';

  @override
  String get supportDiagnosticTitle => 'Support Info';

  @override
  String get supportDiagnosticSubtitle =>
      'Copy version, build, and contact channels to include with bug reports.';

  @override
  String get helpCenterTitle => 'Help Center';

  @override
  String get helpCenterSubtitle =>
      'Find guides on privacy, accounts, data export, and contacting support.';

  @override
  String get aboutMoniaryTitle => 'About Moniary';

  @override
  String get aboutMoniarySubtitle =>
      'View app purpose, data direction, and current version status.';

  @override
  String get privacyPolicySubtitle =>
      'See how Moniary handles personal data, finances, and transaction photos.';

  @override
  String get termsOfUseTitle => 'Terms of Use';

  @override
  String get termsOfUseSubtitle =>
      'View scope of use, user responsibilities, and current version limitations.';

  @override
  String get dataRetentionPolicyTitle => 'Data Retention Policy';

  @override
  String get dataRetentionPolicySubtitle =>
      'See what is synced with your account, what stays on this device, and what happens after account deletion.';

  @override
  String get thirdPartyServicesTitle => 'Third-Party Services';

  @override
  String get thirdPartyServicesSubtitle =>
      'See how the app uses Supabase, Flutter packages, and device storage.';

  @override
  String get thirdPartyHeroBody =>
      'This notice helps users understand which services the app relies on for sign-in, storage, and data operations.';

  @override
  String get thirdPartySupabaseDescription =>
      'Used for sign-in, database, transaction image storage, and the account-deletion edge function.';

  @override
  String get thirdPartyFlutterDescription =>
      'The app\'s main UI framework, together with packages for navigation, state, camera, image picking, and file handling.';

  @override
  String get thirdPartyDeviceStorageTitle => 'Device storage';

  @override
  String get thirdPartyDeviceStorageDescription =>
      'Export files, privacy requests, and export/request history are written to the app\'s documents folder on the device.';

  @override
  String get thirdPartyNoAdsTitle => 'No advertising integration';

  @override
  String get thirdPartyNoAdsDescription =>
      'The MVP does not use advertising SDKs, marketing tracking, contacts, SMS, email inbox access, or automatic bank connections.';

  @override
  String get releaseChecklistTitle => 'Release Checklist';

  @override
  String get releaseChecklistSubtitle =>
      'Review privacy, data export, account deletion, and contacts before release.';

  @override
  String get trustSafetyTitle => 'Trust & Safety';

  @override
  String get trustSafetySubtitle =>
      'View notes on financial advice limits, user data, and file sharing.';

  @override
  String get financialDisclaimerTitle => 'Financial Disclaimer';

  @override
  String get financialDisclaimerSubtitle =>
      'Liability limit: app is not for investment, tax, accounting, or legal advice.';

  @override
  String get policyChangelogTitle => 'Policy Changelog';

  @override
  String get policyChangelogSubtitle =>
      'View milestones for privacy, legal, and release-readiness updates.';

  @override
  String get userDataRightsTitle => 'User Data Rights';

  @override
  String get userDataRightsSubtitle =>
      'Summary of data viewing, exporting, edit/delete requests, and privacy contact.';

  @override
  String get userRightsHeroBody =>
      'Users have the right to understand what data is stored, export their own data, and submit a privacy request when needed.';

  @override
  String get userRightsAccessTitle => 'View stored data';

  @override
  String get userRightsAccessDescription =>
      'Users can view a data overview, data groups, transaction images, and local files.';

  @override
  String get userRightsExportTitle => 'Export data';

  @override
  String get userRightsExportDescription =>
      'Users can export data in CSV, Excel, or PDF format before sharing or leaving the app.';

  @override
  String get userRightsCorrectionTitle => 'Request correction or support';

  @override
  String get userRightsCorrectionDescription =>
      'Users can submit a privacy request if their data needs review, correction, or further explanation.';

  @override
  String get userRightsDeletionTitle => 'Request data deletion';

  @override
  String get userRightsDeletionDescription =>
      'Users can delete their account in-app or submit a manual request if the direct flow fails.';

  @override
  String get policyAcceptanceNoticeTitle => 'Policy Acceptance Notice';

  @override
  String get policyAcceptanceNoticeSubtitle =>
      'Explains that continued use applies current policies and terms.';

  @override
  String get policyAcceptanceHero =>
      'This notice helps users understand that the current policies apply when continuing to use Moniary.';

  @override
  String get policyAcceptanceBody =>
      'By continuing to use Moniary, the user confirms they have had the opportunity to read the Privacy Policy, Terms of Use, data retention notice, and related safety notes.';

  @override
  String get legalContactTitle => 'Legal Contact';

  @override
  String get legalContactSubtitle =>
      'View and copy privacy, support, and legal emails.';

  @override
  String get dataSafetyTitle => 'Data Safety';

  @override
  String get dataSafetySubtitle =>
      'Summary of data groups collected or not collected in the current version.';

  @override
  String get myDataTitle => 'My Data';

  @override
  String get myDataSubtitle =>
      'Quick view of how much data the app stores for this account.';

  @override
  String get permissionsTitle => 'Permissions';

  @override
  String get permissionsSubtitle =>
      'Explanation of why Moniary uses or doesn\'t use each Android permission.';

  @override
  String get exportMyDataTitle => 'Export My Data';

  @override
  String get exportMyDataSubtitle =>
      'Choose file format and create a copy of your personal data.';

  @override
  String get exportHistorySubtitle =>
      'View CSV, Excel, or PDF files generated from this account.';

  @override
  String get deleteAccountSubtitle2 =>
      'Delete profile, wallets, categories, transactions, and saved photos.';

  @override
  String get dataDeletionPolicyTitle => 'Data Deletion Policy';

  @override
  String get dataDeletionPolicySubtitle =>
      'See what data is deleted and how Moniary handles deletion requests.';

  @override
  String get dataDeletionRequestTitle => 'Data Deletion Request';

  @override
  String get dataDeletionRequestSubtitle =>
      'Create manual deletion request file if direct deletion fails.';

  @override
  String get privacyContactTitle => 'Privacy Contact';

  @override
  String get privacyContactSubtitle =>
      'Support channel for data requests, deletion requests, or privacy questions.';

  @override
  String get trustHeroText =>
      'These notes clarify what the app does, doesn\'t do, and how to protect your financial data.';

  @override
  String get notFinancialAdviceTitle => 'Not Financial Advice';

  @override
  String get notFinancialAdviceDesc =>
      'Moniary only helps record and review personal income/expenses. No investment, tax, or accounting advice.';

  @override
  String get userEnteredDataTitle => 'User-Entered Data';

  @override
  String get userEnteredDataDesc =>
      'Amounts, notes, categories, and photos depend entirely on user-created data.';

  @override
  String get noOverCollectionTitle => 'No Over-Collection';

  @override
  String get noOverCollectionDesc =>
      'Moniary does not read contacts, SMS, personal emails, location, or automatically connect bank accounts.';

  @override
  String get carefulFileSharingTitle => 'Careful File Sharing';

  @override
  String get carefulFileSharingDesc =>
      'Export files contain personal financial data. Share only with trusted contacts or support.';

  @override
  String get exportDataTitle => 'Export Data';

  @override
  String get supportContactTitle => 'Support Contact';

  @override
  String importSuccessWithHistoryError(int count) {
    return 'Successfully imported $count transactions, but failed to save local history.';
  }

  @override
  String legalCopyContactValue(String value) {
    return 'Copied $value';
  }

  @override
  String get storeComplianceHero =>
      'These items help review user and reviewer-facing elements before release.';

  @override
  String get storeCompliancePrivacyTitle => 'Privacy Policy';

  @override
  String get storeCompliancePrivacyDesc =>
      'Privacy policy describes financial data, photos, and handling.';

  @override
  String get storeComplianceDeleteTitle => 'Delete Account';

  @override
  String get storeComplianceDeleteDesc =>
      'Account deletion flow and manual request fallback exist.';

  @override
  String get storeComplianceExportTitle => 'Export Data';

  @override
  String get storeComplianceExportDesc =>
      'Users can export CSV, Excel, or PDF data.';

  @override
  String get storeComplianceDataSafetyTitle => 'Data Safety';

  @override
  String get storeComplianceDataSafetyDesc =>
      'Summarizes data collected and not collected.';

  @override
  String get storeComplianceContactTitle => 'Privacy Contact';

  @override
  String get storeComplianceContactDesc =>
      'Support channels and request history exist.';

  @override
  String get storeComplianceTermsTitle => 'Terms of Use';

  @override
  String get storeComplianceTermsDesc =>
      'Terms of use and liability limits are defined.';

  @override
  String get privacyNoData => 'No data available';

  @override
  String get privacyDataOverview => 'Data Overview';

  @override
  String get privacyDataInventory => 'Stored Data Types';

  @override
  String get privacySensitiveData => 'Sensitive Data Notice';

  @override
  String get privacyTransparencyReport => 'Transparency Report';

  @override
  String get privacyDataControl => 'Data Controls';

  @override
  String get metricTransaction => 'Transactions';

  @override
  String get metricWallet => 'Wallets';

  @override
  String get metricCategory => 'Categories';

  @override
  String get metricHasPhoto => 'With Photo';

  @override
  String get metricNoPhoto => 'Without Photo';

  @override
  String get inventoryProfileTitle => 'Account Profile';

  @override
  String get inventoryProfileDesc =>
      'Display name, email, avatar, timezone, and login state.';

  @override
  String get inventoryWalletTitle => 'Wallets';

  @override
  String get inventoryWalletDesc =>
      'Wallet name, type, initial balance, default state, and visibility.';

  @override
  String get inventoryCategoryTitle => 'Categories';

  @override
  String get inventoryCategoryDesc =>
      'Category name, type, default state, and visibility.';

  @override
  String get inventoryTransactionTitle => 'Transactions';

  @override
  String get inventoryTransactionDesc =>
      'Amount, type, wallet, category, note, and date.';

  @override
  String get inventoryPhotoTitle => 'Transaction Photos';

  @override
  String get inventoryPhotoDesc =>
      'Transaction photo paths are stored securely and shown only when needed in the app.';

  @override
  String get inventorySettingsTitle => 'Reminder Settings';

  @override
  String get inventorySettingsDesc =>
      'Notification preferences when reminders are enabled.';

  @override
  String get sensitiveDataDesc =>
      'Financial data includes amounts, notes, photos, and exported files. Only share exports with trusted parties and delete local files when no longer needed.';

  @override
  String localFilesExportCount(int count) {
    return '$count exported files';
  }

  @override
  String localFilesLatest(String date) {
    return 'Latest: $date';
  }

  @override
  String get localFilesNoExport => 'No exported files yet';

  @override
  String get localFilesDesc =>
      'CSV, Excel, and PDF files are stored on this device. You can open, share, or delete them manually.';

  @override
  String reportSummaryDesc(int txs, int wallets, int categories) {
    return 'This account currently has $txs transactions, $wallets wallets, and $categories categories.';
  }

  @override
  String reportPhotoDesc(int percent) {
    return '$percent% of your transactions contain photos.';
  }

  @override
  String reportExportDesc(int count) {
    return '$count exported files have been recorded on this device.';
  }

  @override
  String get reportPrivacyDesc =>
      'Moniary does not sell personal data and uses it only to run the expense management experience.';

  @override
  String get controlExportTitle => 'Export Data';

  @override
  String get controlExportDesc =>
      'Create a CSV, Excel, or PDF file from your account data.';

  @override
  String get controlContactTitle => 'Privacy Contact';

  @override
  String get controlContactDesc =>
      'Create a support request regarding data, privacy, or account deletion.';

  @override
  String get controlDeleteTitle => 'Delete Account';

  @override
  String get controlDeleteDesc =>
      'Open confirmation to delete your account and all associated data.';

  @override
  String get freshOldestTx => 'Oldest transaction';

  @override
  String get freshNewestTx => 'Newest transaction';

  @override
  String get freshLatestExport => 'Latest data export';

  @override
  String get supportChecklistHero =>
      'Prepare enough information before submitting a request so support can resolve it faster and avoid unnecessary sensitive data sharing.';

  @override
  String get supportChecklistActionTitle => 'Describe what you did';

  @override
  String get supportChecklistActionDesc =>
      'Specify if you were exporting, deleting your account, creating a request, or opening a file.';

  @override
  String get supportChecklistErrorTitle => 'Include error messages if any';

  @override
  String get supportChecklistErrorDesc =>
      'Copy the error message or describe the screen so support can investigate.';

  @override
  String get supportChecklistFileTitle =>
      'Attach request or export files when relevant';

  @override
  String get supportChecklistFileDesc =>
      'For privacy requests or manual deletion requests, attach the file generated by the app.';

  @override
  String get supportChecklistDiagnosticTitle => 'Copy support info';

  @override
  String get supportChecklistDiagnosticDesc =>
      'Include version, build, and release channel from the Help Center.';

  @override
  String get supportChecklistSensitiveTitle =>
      'Do not send overly sensitive data';

  @override
  String get supportChecklistSensitiveDesc =>
      'Do not send passwords, access codes, or sensitive receipt photos unless absolutely necessary.';

  @override
  String get dataSafetyPersonalInfoTitle => 'Personal info';

  @override
  String get dataSafetyPersonalInfoStatus =>
      'Yes, when logging in with email or Google';

  @override
  String get dataSafetyPersonalInfoDesc =>
      'Display name, email, avatar, and account ID used for login and data synchronization.';

  @override
  String get dataSafetyFinancialInfoTitle => 'Financial info';

  @override
  String get dataSafetyFinancialInfoStatus => 'Yes';

  @override
  String get dataSafetyFinancialInfoDesc =>
      'Wallets, categories, amounts, notes, and transaction dates entered by the user.';

  @override
  String get dataSafetyPhotosTitle => 'Photos';

  @override
  String get dataSafetyPhotosStatus =>
      'Yes, when actively chosen/taken by the user';

  @override
  String get dataSafetyPhotosDesc =>
      'Transaction photos are stored securely and shown in the app only when needed.';

  @override
  String get dataSafetyUserIdTitle => 'Account ID';

  @override
  String get dataSafetyUserIdStatus => 'Yes';

  @override
  String get dataSafetyUserIdDesc =>
      'Used to associate data with the correct account and limit data access.';

  @override
  String get dataSafetyLocationTitle => 'Location, Contacts, SMS';

  @override
  String get dataSafetyLocationStatus => 'Not collected in the current version';

  @override
  String get dataSafetyLocationDesc =>
      'Moniary does not request location, contacts, or read SMS/email for transaction imports.';

  @override
  String get aboutMoniaryHeroTitle => 'Moniary';

  @override
  String get aboutMoniaryHeroDesc =>
      'A personal finance notebook with clear data control for users.';

  @override
  String get aboutMoniaryVersionLabel => 'Version';

  @override
  String get aboutMoniaryBuildLabel => 'Build';

  @override
  String get aboutMoniaryChannelLabel => 'Release channel';

  @override
  String get aboutMoniaryLicenseTitle => 'Open source licenses';

  @override
  String get aboutMoniaryLicenseDesc =>
      'View licenses for libraries used in this app.';

  @override
  String get aboutMoniaryPurposeTitle => 'Purpose';

  @override
  String get aboutMoniaryPurposeDesc =>
      'Moniary helps users record personal finances, manage wallets, categories, and transaction photos in a simple experience.';

  @override
  String get aboutMoniaryDataDirTitle => 'Data Philosophy';

  @override
  String get aboutMoniaryDataDirDesc =>
      'Financial data belongs to the user. The app provides tools to export data, delete accounts, and contact privacy support.';

  @override
  String get aboutMoniaryMvpStatusTitle => 'Version Status';

  @override
  String get aboutMoniaryMvpStatusDesc =>
      'The current version focuses on expense tracking, data transparency, and requirements needed for public release.';

  @override
  String get permissionInternetTitle => 'Internet';

  @override
  String get permissionInternetStatus => 'Required';

  @override
  String get permissionInternetDesc =>
      'Used for login, data synchronization, and loading transaction photos when needed.';

  @override
  String get permissionCameraTitle => 'Camera';

  @override
  String get permissionCameraStatus => 'Only asked when user takes a photo';

  @override
  String get permissionCameraDesc =>
      'Used to take photos of receipts or images related to transactions.';

  @override
  String get permissionPhotoTitle => 'Photo Picker';

  @override
  String get permissionPhotoStatus => 'Only opens when user selects a photo';

  @override
  String get permissionPhotoDesc =>
      'Uses Android Photo Picker to select photos without reading the entire gallery.';

  @override
  String get permissionNotiTitle => 'Notifications';

  @override
  String get permissionNotiStatus => 'Only used when reminders are enabled';

  @override
  String get permissionNotiDesc =>
      'This permission is only needed when you enable reminders.';

  @override
  String get permissionLocationTitle => 'Location, Contacts, SMS not used';

  @override
  String get permissionLocationStatus => 'Not used';

  @override
  String get permissionLocationDesc =>
      'Moniary does not need location, contacts, or SMS to record expenses with photos.';

  @override
  String get privacyPolicyLeadTitle =>
      'Moniary protects your personal spending data.';

  @override
  String get privacyPolicyLeadDesc =>
      'This explains how Moniary handles data and may be updated before the public release.';

  @override
  String get privacyPolicyDataTitle => 'Data processed by Moniary';

  @override
  String get privacyPolicyDataItem1 =>
      'Account information such as display name, email, avatar, and account ID upon login.';

  @override
  String get privacyPolicyDataItem2 =>
      'Financial data entered by the user including wallets, categories, transactions, amounts, notes, and dates.';

  @override
  String get privacyPolicyDataItem3 =>
      'Transaction photos taken or selected by the user.';

  @override
  String get privacyPolicyDataItem4 =>
      'App settings such as reminders and profile preferences.';

  @override
  String get privacyPolicyPurposeTitle => 'Purpose of use';

  @override
  String get privacyPolicyPurposeItem1 =>
      'Login, data synchronization, and data recovery when changing devices.';

  @override
  String get privacyPolicyPurposeItem2 =>
      'Display spending calendar, transaction details, filters, and monthly statistics.';

  @override
  String get privacyPolicyPurposeItem3 =>
      'Store transaction photos securely and show them in the app when needed.';

  @override
  String get privacyPolicyPurposeItem4 =>
      'Protect accounts, limit data access, and support users upon request.';

  @override
  String get privacyPolicyShareTitle => 'Data sharing';

  @override
  String get privacyPolicyShareItem1 =>
      'Moniary does not sell personal or financial data of users.';

  @override
  String get privacyPolicyShareItem2 =>
      'Data is stored on secure infrastructure to provide login, data sync, and photo storage for the app.';

  @override
  String get privacyPolicyShareItem3 =>
      'Moniary does not automatically read location, contacts, SMS, personal email, or bank data.';

  @override
  String get privacyPolicyDeleteTitle => 'Data deletion';

  @override
  String get privacyPolicyDeleteItem1 =>
      'Users can delete individual transactions within the app.';

  @override
  String get privacyPolicyDeleteItem2 =>
      'Users can export CSV data before deleting their account.';

  @override
  String get privacyPolicyDeleteItem3 =>
      'When deleting an account, Moniary requests deletion of profiles, wallets, categories, transactions, and photos belonging to the current account.';

  @override
  String get privacyPolicySafetyTitle => 'Data Safety Declaration';

  @override
  String get privacyPolicySafetyItem1 =>
      'Personal info: collected only when users log in with email or Google.';

  @override
  String get privacyPolicySafetyItem2 =>
      'Financial info: collected to store and display personal finances.';

  @override
  String get privacyPolicySafetyItem3 =>
      'Photos: collected only when users actively take or select photos.';

  @override
  String get privacyPolicySafetyItem4 =>
      'Location, Contacts, SMS: not collected in the current version.';

  @override
  String get privacyPolicyContactDesc =>
      'Moniary will update the policy content and official contact email before release.';

  @override
  String get deletionPolicyStep1Title => 'Before deleting';

  @override
  String get deletionPolicyStep1Desc =>
      'Users can export a CSV to retain their personal transaction history.';

  @override
  String get deletionPolicyStep2Title => 'Data to be deleted';

  @override
  String get deletionPolicyStep2Desc =>
      'Profiles, wallets, categories, transactions, reminder settings, and photos belonging to the current account.';

  @override
  String get deletionPolicyStep3Title => 'How to delete';

  @override
  String get deletionPolicyStep3Desc =>
      'Moniary verifies the request, removes related data, and then closes the account.';

  @override
  String get deletionPolicyStep4Title => 'Data outside the app';

  @override
  String get deletionPolicyStep4Desc =>
      'For additional help with data outside the app, users can contact Moniary privacy support.';

  @override
  String get termsOfUseHeroDesc =>
      'These terms summarize how users should use Moniary in the current version.';

  @override
  String get termsOfUseScopeTitle => '1. Scope of use';

  @override
  String get termsOfUseScopeDesc =>
      'Moniary is provided for users to record and self-manage personal financial data. Users are responsible for the accuracy of the entered data.';

  @override
  String get termsOfUseAccountTitle => '2. Account data';

  @override
  String get termsOfUseAccountDesc =>
      'Users can export data, submit privacy requests, and delete accounts using the tools provided in the app.';

  @override
  String get termsOfUseContentTitle => '3. User content';

  @override
  String get termsOfUseContentDesc =>
      'Notes, amounts, and transaction photos entered or uploaded by the user should only serve personal expense management purposes.';

  @override
  String get termsOfUseLiabilityTitle => '4. Limitation of liability';

  @override
  String get termsOfUseLiabilityDesc =>
      'Moniary is not a financial, accounting, tax, or legal advisory tool. In-app statistics are for reference only.';

  @override
  String get termsOfUseChangesTitle => '5. Changes to terms';

  @override
  String get termsOfUseChangesDesc =>
      'Terms may be updated when the app adds features or prepares for official release.';

  @override
  String get transactionOcrExtracting => 'Extracting data...';

  @override
  String get exportSheetTransactions => 'Transactions';

  @override
  String get exportColumnDataType => 'Data type';

  @override
  String get exportColumnId => 'ID';

  @override
  String get exportColumnName => 'Name';

  @override
  String get exportColumnImagePath => 'Image path';

  @override
  String get exportColumnCreatedAt => 'Created at';

  @override
  String get exportReportGeneratedAt => 'Generated at';

  @override
  String get exportReportRecentTransactions => 'Recent transactions';

  @override
  String get dataRetentionCloudTitle => 'Synced data';

  @override
  String get dataRetentionCloudDesc =>
      'Profiles, wallets, categories, transactions, and transaction image paths are kept while the account remains active so the app can sync and render the data again.';

  @override
  String get dataRetentionPhotosTitle => 'Transaction photos';

  @override
  String get dataRetentionPhotosDesc =>
      'Transaction photos are stored only when the user actively takes or selects an image. Photos are processed together with account data when deleting the account.';

  @override
  String get dataRetentionLocalFilesTitle => 'Files on this device';

  @override
  String get dataRetentionLocalFilesDesc =>
      'Export files and request history are created on the device. Users can manage, share, or delete these files from device storage.';

  @override
  String get dataRetentionDeleteTitle => 'After account deletion';

  @override
  String get dataRetentionDeleteDesc =>
      'Moniary runs the account deletion flow to remove app data tied to the current account. If it fails, users can create a manual data deletion request.';

  @override
  String get financialDisclaimerInvestmentTitle => 'Not investment advice';

  @override
  String get financialDisclaimerInvestmentDesc =>
      'Moniary does not recommend buying, selling, investing, or allocating assets. Users remain responsible for their own financial decisions.';

  @override
  String get financialDisclaimerTaxTitle => 'Not tax/accounting advice';

  @override
  String get financialDisclaimerTaxDesc =>
      'Data in the app does not replace receipts, accounting reports, or professional tax advice.';

  @override
  String get financialDisclaimerReferenceTitle => 'Figures are for reference';

  @override
  String get financialDisclaimerReferenceDesc =>
      'Income totals, expense totals, and export files depend on user-entered data and may be wrong if entries are missing or incorrect.';

  @override
  String get financialDisclaimerExpertTitle => 'For important decisions';

  @override
  String get financialDisclaimerExpertDesc =>
      'Users should verify source data and consult a qualified expert before making financial, tax, or legal decisions.';

  @override
  String get policyChangelogEntry1Title => 'Added Legal & Policy Center';

  @override
  String get policyChangelogEntry1Desc =>
      'Added data retention policy, third-party service notice, financial disclaimer, and policy changelog.';

  @override
  String get policyChangelogEntry2Title => 'Added Privacy Requests & Support';

  @override
  String get policyChangelogEntry2Desc =>
      'Added privacy request types, templates, previews, request history, status, and response timeline.';

  @override
  String get policyChangelogEntry3Title => 'Added Release Readiness & Trust';

  @override
  String get policyChangelogEntry3Desc =>
      'Added About, Terms of Use, license entry, version/build info, release checklist, and legal contact flow.';

  @override
  String get policyChangelogEntry4Title => 'Initialized first-version policies';

  @override
  String get policyChangelogEntry4Desc =>
      'Added privacy policy, data safety, data deletion policy, data export, and account deletion flow.';

  @override
  String get groupCreateNew => 'Create new group';

  @override
  String get groupDescriptionLabel => 'Description';

  @override
  String get groupTypeLabel => 'Group type';

  @override
  String get groupTypeHint =>
      'For example: Travel, Food, Housemates, Couple, Friends...';

  @override
  String get groupAvatarLabel => 'Group image';

  @override
  String get groupChooseImage => 'Choose image';

  @override
  String get groupNameRequired => 'Group name is required.';

  @override
  String groupTotalSpent(String amount) {
    return 'Total spent $amount';
  }

  @override
  String get groupBalanceSettled => 'Settled';

  @override
  String get groupBalanceSettledShort => 'Settled';

  @override
  String groupBalanceOwes(String amount) {
    return 'You need to pay $amount';
  }

  @override
  String groupBalanceReceives(String amount) {
    return 'You will receive $amount';
  }

  @override
  String get groupBalanceReceiveShort => 'To receive';

  @override
  String get groupBalancePayShort => 'To pay';

  @override
  String get groupBalanceReceiveSummary => 'You receive';

  @override
  String get groupBalancePaySummary => 'You pay';

  @override
  String get groupSettleAction => 'Settle';

  @override
  String get groupSettlementYou => 'You';

  @override
  String get groupSettlementConfirmAll => 'Confirm settled';

  @override
  String get groupSettlementWaitingForPayers =>
      'Waiting for payers to mark their payments first.';

  @override
  String groupSettlementOptimizedSubtitle(String groupName, int count) {
    return '$groupName · Optimized $count transactions';
  }

  @override
  String get groupUnresolvedBadge => 'Unresolved';

  @override
  String get groupOverviewTitle => 'Overview';

  @override
  String get groupTransactionsTitle => 'Group transactions';

  @override
  String get groupDebtAreaTitle => 'Who owes whom';

  @override
  String get groupLeave => 'Leave group';

  @override
  String get groupLeaveConfirmTitle => 'Leave this group?';

  @override
  String get groupLeaveConfirmMessage =>
      'You can leave only after balances are resolved and ownership is transferred when required.';

  @override
  String get groupLeaveBlocked => 'You still have unresolved group expenses.';

  @override
  String get groupOwnerTransferRequired =>
      'Transfer ownership or add another owner before leaving.';

  @override
  String get groupOwnerRequired => 'Only the group owner can do this.';

  @override
  String get groupOwnerTransferTargetRequired =>
      'Choose another active member to become owner.';

  @override
  String get groupTransferOwnership => 'Transfer owner';

  @override
  String groupTransferOwnershipConfirm(String member) {
    return 'Transfer group ownership to $member?';
  }

  @override
  String get groupTransferOwnershipDone => 'Group ownership transferred.';

  @override
  String get groupInviteTitle => 'Invite members';

  @override
  String get groupInviteAfterCreate => 'Invite members after creating';

  @override
  String get groupInviteByUsername => 'Invite by username';

  @override
  String get groupUsernameLabel => 'Username';

  @override
  String get groupInviteAction => 'Send invite';

  @override
  String get groupInviteLinkTitle => 'Group invite link';

  @override
  String get groupCreateInviteLink => 'Create invite link';

  @override
  String get groupInviteLinkCreated => 'Group invite link created.';

  @override
  String get groupInviteLinkActiveNote =>
      'This link can be used by multiple people for 7 days.';

  @override
  String get groupInviteCopyLink => 'Copy link';

  @override
  String get groupInviteLinkCopied => 'Invite link copied.';

  @override
  String get groupInviteRevokeLink => 'Revoke link';

  @override
  String get groupInviteLinkRevoked => 'Group invite link revoked.';

  @override
  String get groupInviteAcceptTitle => 'Group invite';

  @override
  String groupInviteAcceptSubtitle(String name, String group) {
    return '$name invited you to join $group.';
  }

  @override
  String get groupInvitePreviewNotice =>
      'You have not joined yet. Only tap Join group if you want to accept this invite.';

  @override
  String get groupInviteAcceptButton => 'Join group';

  @override
  String get groupInviteDismissButton => 'Not now';

  @override
  String get groupInviteAccepted => 'You joined the group.';

  @override
  String get groupInviteAlreadyMember =>
      'You are already a member of this group.';

  @override
  String get groupInviteLoading => 'Loading invite...';

  @override
  String get groupInvitePreviewError => 'Could not load the group invite.';

  @override
  String get groupInviteInvalid => 'This group invite link is invalid.';

  @override
  String get groupInviteExpired => 'This group invite link has expired.';

  @override
  String get groupInviteUsed => 'This group invite link has already been used.';

  @override
  String get groupInviteRevoked => 'This group invite link was revoked.';

  @override
  String get groupInviteOpenGroups => 'Open groups';

  @override
  String get groupCopyInviteLink => 'Copy link';

  @override
  String get groupShareInviteLink => 'Share link';

  @override
  String groupInviteShareMessage(String link) {
    return 'Join my Moniary expense group: $link';
  }

  @override
  String get groupInviteSent => 'Invite sent.';

  @override
  String get groupUserNotFound => 'User not found.';

  @override
  String get groupNoFriends => 'You do not have friends to invite yet.';

  @override
  String get groupFriendInviteTitle => 'Invite from friends';

  @override
  String get groupInviteAlreadyAccepted =>
      'This group invite link has already been used.';

  @override
  String get groupInviteGroupArchived => 'This group has been archived.';

  @override
  String get groupMemberInvited => 'Invited';

  @override
  String get groupMemberActive => 'Active';

  @override
  String get groupAddTransaction => 'Add group expense';

  @override
  String get groupTransactionCaption => 'Caption';

  @override
  String get groupTransactionNote => 'Note';

  @override
  String get groupTransactionTotal => 'Total amount';

  @override
  String get groupTransactionCategory => 'Category';

  @override
  String get groupTransactionImage => 'Receipt image';

  @override
  String get groupTransactionImageOptional =>
      'An image is optional but recommended.';

  @override
  String get groupTransactionImageUploadFailed =>
      'Image upload failed. Choose the image again to retry.';

  @override
  String get groupSplitModeTitle => 'Split method';

  @override
  String get groupSplitEqual => 'Equal split';

  @override
  String get groupSplitUnequal => 'Unequal split';

  @override
  String get groupPaymentModeTitle => 'Who paid';

  @override
  String get groupPaymentEveryone => 'Everyone paid';

  @override
  String get groupPaymentSingle => 'One person paid';

  @override
  String get groupPaymentMultiple => 'Multiple people paid';

  @override
  String get groupSelectPayer => 'Please select who paid.';

  @override
  String get groupSelectAtLeastTwoPayers => 'Please select at least 2 payers.';

  @override
  String get groupEnterPayerAmounts =>
      'Enter the amount paid by each selected member.';

  @override
  String get groupPayerAmountPositive => 'Paid amount must be greater than 0.';

  @override
  String get groupPaidTotalMismatch =>
      'Total paid does not match the transaction total.';

  @override
  String get groupConfirmationTitle => 'Are you sure?';

  @override
  String get groupPost => 'Post';

  @override
  String get groupPosting => 'Posting...';

  @override
  String get groupTransactionPosted => 'Group transaction posted successfully.';

  @override
  String get groupTransactionPendingAmounts =>
      'Please enter the amount you used in this transaction.';

  @override
  String get groupTransactionAmountMismatch =>
      'Member amounts do not match the transaction total. Please review and enter them again.';

  @override
  String get groupTransactionMembersPending =>
      'Some members have not entered their used amount.';

  @override
  String get groupTransactionPendingStatus => 'Waiting for member amounts';

  @override
  String get groupTransactionMismatchStatus => 'Amounts do not match';

  @override
  String get groupTransactionPostedStatus => 'Posted';

  @override
  String get groupTransactionNoData => 'No group transactions yet.';

  @override
  String get groupTransactionLoadError => 'Could not load group transactions.';

  @override
  String groupTransactionHistorySubtitle(String payer, int count) {
    return '$payer paid · Split $count people';
  }

  @override
  String get groupTransactionDetailTitle => 'Group transaction details';

  @override
  String get groupActivityCenterTitle => 'Group activity';

  @override
  String get groupActivityTabTimeline => 'Activity';

  @override
  String get groupActivityTabNotifications => 'Notifications';

  @override
  String get groupActivityEmpty => 'No activity yet';

  @override
  String get groupNotificationsEmptyState => 'No notifications yet';

  @override
  String get groupPhotoAlbumTitle => 'Photo album';

  @override
  String get groupPhotoAlbumEmpty => 'No transaction photos yet';

  @override
  String get groupPhotoAlbumLoadError => 'Could not load the photo album';

  @override
  String get groupTransactionFallback => 'Group transaction';

  @override
  String get groupMemberFallback => 'Member';

  @override
  String get groupBudgetTitle => 'Group budget';

  @override
  String get groupBudgetSubtitle =>
      'Set a shared monthly spending limit for this group.';

  @override
  String get groupBudgetMonthlyLimit => 'Monthly limit';

  @override
  String get groupBudgetWarningThreshold => 'Warning threshold';

  @override
  String get groupBudgetNotSet => 'No budget set';

  @override
  String get groupBudgetSet => 'Set budget';

  @override
  String get groupBudgetEditTitle => 'Edit group budget';

  @override
  String get groupBudgetInvalidAmount => 'Amount must be 0 or greater';

  @override
  String get groupBudgetSaved => 'Budget updated';

  @override
  String get groupBudgetCurrencySuffix => 'in your currency';

  @override
  String get groupBudgetAdminOnly =>
      'Only group owners and admins can change this budget.';

  @override
  String get groupBudgetInvalidLimit => 'Enter a valid non-negative limit.';

  @override
  String get groupNotificationPrefsTitle => 'Notification settings';

  @override
  String get groupNotificationPrefsMuteAll => 'Mute all';

  @override
  String get groupNotificationPrefsMuteAllHelp =>
      'Turn off every notification from this group';

  @override
  String get groupNotificationPrefsTransactions => 'New transactions';

  @override
  String get groupNotificationPrefsDebts => 'Debts and settlements';

  @override
  String get groupNotificationPrefsInvites => 'Invitations';

  @override
  String get groupNotificationPrefsMentions => 'Mentions';

  @override
  String get groupNotificationPrefsQuietHours => 'Quiet hours';

  @override
  String get groupNotificationPrefsQuietHoursHelp =>
      'Silence notifications during these hours';

  @override
  String get groupNotificationPrefsFrom => 'From';

  @override
  String get groupNotificationPrefsTo => 'To';

  @override
  String get groupNotificationPrefsSaved => 'Notification settings saved';

  @override
  String get groupNotificationPreferencesTitle => 'Notification preferences';

  @override
  String get groupNotificationPreferencesSubtitle =>
      'Choose which group events should notify you.';

  @override
  String get groupNotificationMuteAll => 'Mute all notifications';

  @override
  String get groupNotificationTransactions => 'Transaction updates';

  @override
  String get groupNotificationDebts => 'Debt and settlement updates';

  @override
  String get groupNotificationInvites => 'Invitations';

  @override
  String get groupNotificationMentions => 'Mentions';

  @override
  String get groupPublicProfileTitle => 'Public profile';

  @override
  String get groupPublicProfileComingSoon =>
      'Public sharing isn\'t live yet. These settings save your preferences for when it launches.';

  @override
  String get groupPublicProfileEnable => 'Enable public profile';

  @override
  String get groupPublicProfileEnableHelp =>
      'Allow this group to have a shareable public page';

  @override
  String get groupPublicProfileShowStats => 'Show group stats';

  @override
  String get groupPublicProfileShowStatsHelp =>
      'Include spending statistics on the public page';

  @override
  String get groupPublicProfileSlug => 'Public slug';

  @override
  String get groupPublicProfileSlugHint => 'my-group-name';

  @override
  String get groupPublicProfileSlugInvalid =>
      'Link must be 3-80 chars: lowercase letters, numbers, hyphens';

  @override
  String get groupPublicProfileSaved => 'Public profile updated';

  @override
  String get groupPublicProfileSettingsTitle => 'Public profile settings';

  @override
  String get groupPublicProfileSettingsSubtitle =>
      'Only safe group information is shown publicly.';

  @override
  String get groupPublicProfileEnabled => 'Enable public profile';

  @override
  String get groupPublicProfileShowStatsSubtitle =>
      'Shows aggregate counts and total spending only.';

  @override
  String get groupPublicProfileInvalidSlug =>
      'Use 3–80 lowercase letters, numbers, or hyphens.';

  @override
  String get groupPublicProfileFallbackName => 'Moniary group';

  @override
  String get groupPublicProfileMembers => 'Members';

  @override
  String get groupPublicProfileTransactions => 'Transactions';

  @override
  String get groupPublicProfileTotalSpent => 'Total spent';

  @override
  String get groupPublicProfileSafeNotice =>
      'Personal details and transaction-level data are not shown.';

  @override
  String get groupRecurringTitle => 'Recurring transactions';

  @override
  String get groupRecurringAdd => 'Add recurring';

  @override
  String get groupRecurringEdit => 'Edit recurring transaction';

  @override
  String get groupRecurringEmpty => 'No recurring transactions yet';

  @override
  String get groupRecurringName => 'Title';

  @override
  String get groupRecurringAmount => 'Amount';

  @override
  String get groupRecurringFrequency => 'Frequency';

  @override
  String get groupRecurringWeekly => 'Weekly';

  @override
  String get groupRecurringMonthly => 'Monthly';

  @override
  String get groupRecurringNextRun => 'Next run';

  @override
  String get groupRecurringNotifyBefore => 'Notify days before';

  @override
  String get groupRecurringActive => 'Active';

  @override
  String get groupRecurringDeleteTitle => 'Delete recurring transaction?';

  @override
  String get groupRecurringDeleteMessage =>
      'This recurring transaction will be permanently removed.';

  @override
  String get groupActivityTransactionReacted => 'reacted to a transaction';

  @override
  String get groupActivityTransactionCommented => 'commented on a transaction';

  @override
  String get groupActivityMemberJoined => 'joined the group';

  @override
  String get groupActivityMemberLeft => 'left the group';

  @override
  String get groupActivityInvitationAccepted => 'accepted a group invite';

  @override
  String get groupActivityInvitationDeclined => 'declined a group invite';

  @override
  String get groupNotificationTransactionPosted => 'New transaction posted';

  @override
  String get groupNotificationMemberAmountRequired =>
      'Your share amount is needed';

  @override
  String get groupNotificationDebtSettled => 'A debt was settled';

  @override
  String get groupNotificationGroupInvite => 'You have a new group invite';

  @override
  String get groupTransactionCreator => 'Posted by';

  @override
  String get groupTransactionPayers => 'Payers';

  @override
  String get groupTransactionShares => 'Member shares';

  @override
  String get groupTransactionDeleteConfirm => 'Delete this group transaction?';

  @override
  String get groupTransactionCompletedEditWarning =>
      'This transaction has a confirmed settlement. Editing it recalculates group balances. Continue?';

  @override
  String get groupTransactionCreatorOnly =>
      'Only the transaction creator can edit or delete it.';

  @override
  String get groupAmountInputTitle => 'Your used amount';

  @override
  String get groupAmountUsedLabel => 'Amount used';

  @override
  String get groupAmountSubmit => 'Submit amount';

  @override
  String get groupAmountNonNegative => 'Amount cannot be negative.';

  @override
  String get groupSettlementTitle => 'Group debt';

  @override
  String get groupBalanceTableTitle => 'Balance table';

  @override
  String get groupMemberBalanceTitle => 'Member balances';

  @override
  String get groupYouNeedPay => 'You need to pay';

  @override
  String get groupOthersNeedPayYou => 'Others need to pay you';

  @override
  String get groupDetailReceiveBack => 'You receive back';

  @override
  String get groupDetailYouPay => 'You need to pay';

  @override
  String get groupMarkPaid => 'Mark as paid';

  @override
  String get groupConfirmReceived => 'Confirm received';

  @override
  String get groupSettlementPending => 'Pending payment';

  @override
  String get groupSettlementPayerMarked => 'Payer marked as paid';

  @override
  String get groupSettlementCompleted => 'Completed';

  @override
  String get groupSettlementDisputed => 'Disputed';

  @override
  String get groupSettlementEmpty => 'No debt needs action.';

  @override
  String groupSettlementFromTo(String from, String to) {
    return '$from pays $to';
  }

  @override
  String groupSharePaidBalance(String share, String paid, String balance) {
    return 'Share $share • Paid $paid • Balance $balance';
  }

  @override
  String get groupCommentsTitle => 'Comments';

  @override
  String get groupCommentHint => 'Write a comment...';

  @override
  String get groupCommentSend => 'Send';

  @override
  String get groupCommentsEmpty => 'No comments yet.';

  @override
  String get groupCommentRequired => 'Enter a comment.';

  @override
  String get groupCommentDeleteConfirm => 'Delete this comment?';

  @override
  String get groupUnknownMember => 'Member';

  @override
  String get groupNoCategory => 'No category selected';

  @override
  String get groupChooseCategory => 'Choose category';

  @override
  String get groupAmountRequired => 'Enter a total amount greater than 0.';

  @override
  String get groupActionFailed =>
      'Could not complete the group action. Please try again.';

  @override
  String get groupMemberAlreadyInvited =>
      'This user is already in the group or has a pending invite.';

  @override
  String get groupInviteLinkPlaceholder =>
      'Create a link to invite multiple people to this group for 7 days.';

  @override
  String get groupStatsPlaceholder =>
      'Basic group statistics use current total spending and balances.';

  @override
  String get groupStatsLoadError => 'Could not load group statistics.';

  @override
  String get groupStatsTransactionCount => 'Transactions';

  @override
  String get groupStatsPendingCount => 'Pending';

  @override
  String get groupNotificationsTitle => 'Group notifications';

  @override
  String get groupNotificationsEmpty => 'No group notifications yet.';

  @override
  String get groupNotificationInvite => 'You have a group invite.';

  @override
  String get groupNotificationMemberJoined => 'A new member joined the group.';

  @override
  String get groupNotificationTransactionCreated =>
      'A new group transaction was created.';

  @override
  String get groupNotificationOwnerTransferred =>
      'Group ownership was transferred.';

  @override
  String get groupNotificationGeneric => 'There is a new group update.';

  @override
  String get groupActivitiesTitle => 'Group activity';

  @override
  String get groupActivitiesEmpty => 'No group activity yet.';

  @override
  String get groupActivitiesLoadError => 'Could not load group activity.';

  @override
  String groupActivityTransactionCreated(String actor) {
    return '$actor created a group transaction.';
  }

  @override
  String groupActivityTransactionPosted(String actor) {
    return '$actor posted a group transaction.';
  }

  @override
  String groupActivityOwnerTransferred(String actor) {
    return '$actor transferred group ownership.';
  }

  @override
  String groupActivityGeneric(String actor) {
    return '$actor updated the group.';
  }

  @override
  String get groupLeaveWarningActivity =>
      'A member tried to leave before resolving group expenses. Please be careful.';

  @override
  String get cancel => 'Cancel';

  @override
  String get retry => 'Retry';

  @override
  String get friendsTitle => 'Friends';

  @override
  String get friendsProfileSubtitle => 'Manage friends and friend requests';

  @override
  String get friendAdd => 'Add friend';

  @override
  String get friendSearchUsername => 'Search by username';

  @override
  String get friendSearchHint => 'For example: erling_haaland';

  @override
  String get friendSearch => 'Search';

  @override
  String get friendSearchPrompt => 'Enter a username to find a Moniary user.';

  @override
  String friendSearchEmpty(String query) {
    return 'No user found for “$query”.';
  }

  @override
  String get friendSearchError => 'Could not search friends. Please try again.';

  @override
  String get friendSearchPlaceholder => 'Search friends...';

  @override
  String get friendLoadError => 'Could not load friends.';

  @override
  String get friendNoFriends => 'You do not have friends yet.';

  @override
  String get friendNoFriendsSubtitle =>
      'Add friends to invite them to expense groups faster.';

  @override
  String friendListSection(int count) {
    return 'Friends · $count';
  }

  @override
  String friendSharedGroups(int count) {
    return '$count shared groups';
  }

  @override
  String get friendOwesYou => 'Owes you';

  @override
  String get friendYouOwe => 'You owe';

  @override
  String get friendBalanceSettled => 'Settled';

  @override
  String get friendIncomingRequests => 'Friend requests';

  @override
  String get friendOutgoingRequests => 'Sent requests';

  @override
  String get friendRequestsEmpty => 'No friend requests yet.';

  @override
  String get friendAccept => 'Accept';

  @override
  String get friendDecline => 'Decline';

  @override
  String get friendCancel => 'Cancel request';

  @override
  String get friendRemove => 'Remove friend';

  @override
  String get friendRemoveTitle => 'Remove friend?';

  @override
  String friendRemoveMessage(String name) {
    return 'Remove $name from your friends?';
  }

  @override
  String get friendRemoved => 'Friend removed.';

  @override
  String get friendRequestSent => 'Friend request sent.';

  @override
  String get friendRequestAccepted => 'Friend request accepted.';

  @override
  String get friendRequestDeclined => 'Friend request declined.';

  @override
  String get friendRequestCancelled => 'Friend request cancelled.';

  @override
  String get friendRequestPending => 'Waiting for response';

  @override
  String get friendIncomingPending => 'This user already sent you a request';

  @override
  String get friendSendRequest => 'Add';

  @override
  String get friendAlreadyFriends => 'Already friends';

  @override
  String get friendAlreadyExists => 'You are already friends.';

  @override
  String get friendUserNotFound => 'User not found.';

  @override
  String get friendCannotAddSelf => 'You cannot add yourself as a friend.';

  @override
  String get friendRequestAlreadyPending =>
      'A friend request is already pending.';

  @override
  String get friendRequestNotFound => 'Friend request not found.';

  @override
  String get friendNotFound => 'Friend not found.';

  @override
  String get friendShareInviteLink => 'Share friend link';

  @override
  String get friendInviteOr => 'Or';

  @override
  String get budgetTitle => 'Budget';

  @override
  String get budgetUsed => 'Used';

  @override
  String get budgetCategoryLimits => 'Category limits';

  @override
  String budgetSpentOfLimit(String spent, String limit) {
    return '$spent / $limit this month';
  }

  @override
  String get budgetAddCategory => 'Set a limit for another category';

  @override
  String get budgetChooseCategory => 'Choose a category';

  @override
  String get budgetMonthlyLimit => 'Monthly limit';

  @override
  String get budgetLimitHelper =>
      'Enter the maximum amount you want to spend in this category this month.';

  @override
  String get budgetRemoveLimit => 'Remove limit';

  @override
  String budgetLimitTitleForCategory(String category) {
    return 'Limit · $category';
  }

  @override
  String budgetUsedWarningLine(String spent, int percent, String status) {
    return 'Used $spent ($percent%) — $status';
  }

  @override
  String budgetAlertAtPercent(int percent) {
    return 'Alert at $percent%';
  }

  @override
  String get budgetSaveLimit => 'Save limit';

  @override
  String budgetSpentRemainingLine(
    String spent,
    String limit,
    String remaining,
  ) {
    return '$spent / $limit — $remaining left';
  }

  @override
  String budgetTransactionsInLimitCount(int count) {
    return 'Transactions in this limit · $count';
  }

  @override
  String budgetViewAllInStats(int count) {
    return 'View all $count transactions in Stats →';
  }

  @override
  String get budgetNearLimit => 'Near the limit';

  @override
  String get budgetOverLimit => 'Over the limit';

  @override
  String get budgetNearLimitShort => 'Near limit';

  @override
  String get budgetOverLimitShort => 'Over limit';

  @override
  String get budgetEmptyTitle => 'No limits yet';

  @override
  String get budgetEmptyBody =>
      'Choose a category to start tracking your monthly budget.';

  @override
  String get cameraFrameHint => 'Place the receipt inside the frame';

  @override
  String get assistantTitle => 'Financial assistant';

  @override
  String get assistantNavLabel => 'AI';

  @override
  String get assistantIntroSkip => 'Skip';

  @override
  String get assistantIntroNext => 'Continue';

  @override
  String get assistantIntroStart => 'Get started';

  @override
  String get assistantIntroTitle1 => 'Ask anything about your spending';

  @override
  String get assistantIntroBody1 =>
      'Get answers from the information you already record in Moniary.';

  @override
  String get assistantIntroTitle2 => 'Spot unusual spending early';

  @override
  String get assistantIntroBody2 =>
      'Find sharp increases or repeated charges before they get out of hand.';

  @override
  String get assistantIntroTitle3 => 'Get practical next steps';

  @override
  String get assistantIntroBody3 =>
      'See how much to reduce and in which category, without vague advice.';

  @override
  String get assistantPermissionTitle =>
      'Let the assistant understand your finances';

  @override
  String get assistantPermissionBody =>
      'You control what data can be read and can change it at any time.';

  @override
  String get assistantPermissionDateRange =>
      'AI only reads data from 01/01/2025 to today';

  @override
  String get assistantAnalyzeAll => 'Analyze all data';

  @override
  String get assistantTransactionsAccess => 'Income and expense records';

  @override
  String get assistantTransactionsAccessBody =>
      'Use transactions to analyze cash flow and spending habits.';

  @override
  String get assistantWalletsAccess => 'Wallets and balances';

  @override
  String get assistantWalletsAccessBody =>
      'Use balances to put spending figures in context.';

  @override
  String get assistantBudgetsAccess => 'Spending limits';

  @override
  String get assistantBudgetsAccessBody =>
      'Track usage and warn when a limit is close.';

  @override
  String get assistantSavingsAccess => 'Savings and goals';

  @override
  String get assistantSavingsAccessBody =>
      'Track savings goals and suggest a practical plan.';

  @override
  String get assistantUpcomingBadge => 'Coming soon';

  @override
  String get assistantPermissionConfirm => 'Confirm';

  @override
  String get assistantPrivacyNote =>
      'Analysis uses your Moniary data and does not automatically send it to a third party.';

  @override
  String assistantGreeting(String name) {
    return 'Hello $name';
  }

  @override
  String get assistantHomePrompt => 'What can I help you with today?';

  @override
  String get assistantInputHint => 'Type your question';

  @override
  String get assistantSuggestionsTitle => 'Suggestions for you';

  @override
  String get assistantQuestionsTitle => 'Quick questions';

  @override
  String get assistantOpenLibrary => 'Browse question library';

  @override
  String get assistantQuestionLibraryTitle => 'Suggested questions';

  @override
  String get assistantFilterAll => 'All';

  @override
  String get assistantFilterUnderstand => 'Understand spending';

  @override
  String get assistantFilterAlerts => 'Unusual activity';

  @override
  String get assistantFilterActions => 'Actions';

  @override
  String get assistantQuestionMonthly => 'How much have I spent this month?';

  @override
  String get assistantQuestionWeekly =>
      'How does this week\'s spending compare with last week?';

  @override
  String get assistantQuestionDaily =>
      'How much do I spend per day on average?';

  @override
  String get assistantQuestionTopCategory =>
      'Which category costs me the most this month?';

  @override
  String get assistantQuestionRecurring =>
      'Are there repeated expenses I may not have noticed?';

  @override
  String get assistantQuestionSaving => 'Where can I cut back to save more?';

  @override
  String assistantMonthlyAnswer(String amount) {
    return 'You have spent $amount this month.';
  }

  @override
  String assistantMonthlyCompare(String direction, String percent) {
    return '$direction by $percent% compared with last month.';
  }

  @override
  String get assistantDirectionMore => 'More';

  @override
  String get assistantDirectionLess => 'Less';

  @override
  String assistantWeeklyAnswer(
    String current,
    String direction,
    String percent,
  ) {
    return 'You spent $current this week, $direction by $percent% from last week.';
  }

  @override
  String assistantDailyAnswer(String amount) {
    return 'You spend an average of $amount per day this month.';
  }

  @override
  String assistantTopCategoryAnswer(
    String category,
    String amount,
    String percent,
  ) {
    return '$category ranks first at $amount, or $percent% of total spending.';
  }

  @override
  String assistantRecurringAnswer(String label, int count, String amount) {
    return '“$label” appears $count times for a total of $amount.';
  }

  @override
  String assistantSavingAnswer(String category, String amount) {
    return 'Reducing $category by about 15% could save roughly $amount this month.';
  }

  @override
  String get assistantNoData =>
      'There is not enough data to answer yet. Record a few more transactions and try again.';

  @override
  String get assistantAnalysisError =>
      'Analysis is unavailable right now. Please try again later.';

  @override
  String get journalRecapTitle => 'Money Story';

  @override
  String journalRecapMonth(String month) {
    return '$month Money Story';
  }

  @override
  String journalMoneyStoryMonth(String month) {
    return '$month';
  }

  @override
  String get journalMoneyStoryExpenseLabel => 'This month\'s spending';

  @override
  String journalRecordedCount(int count) {
    return 'You recorded $count expenses';
  }

  @override
  String journalRecapSummary(String amount, String category) {
    return 'A total of $amount. Your largest category was $category.';
  }

  @override
  String get journalHighestDay => 'Highest-spend day';

  @override
  String journalHighestDayValue(String date, String amount) {
    return '$date — $amount in one day';
  }

  @override
  String get journalComparedPrevious => 'Compared with last month';

  @override
  String get journalSpentMore => 'Spent more';

  @override
  String get journalSpentLess => 'Spent less';

  @override
  String get journalTopCategories => 'Top categories';

  @override
  String get journalShareRecap => 'Share story';

  @override
  String get journalMoneyStoryCashFlow => 'This month\'s cash flow';

  @override
  String get journalMoneyStoryIncome => 'Income';

  @override
  String get journalMoneyStoryExpense => 'Expense';

  @override
  String get journalMoneyStoryNet => 'Left over';

  @override
  String get journalMoneyStoryAverageDay => 'Average / recording day';

  @override
  String journalMoneyStoryActiveDays(int count) {
    return '$count recording days';
  }

  @override
  String journalMoneyStoryCategoryShare(String category, int percent) {
    return '$category took $percent%';
  }

  @override
  String journalMoneyStoryCategoryPercent(int percent) {
    return '$percent%';
  }

  @override
  String get journalMoneyStoryHighestDayEmpty =>
      'No standout spending day yet this month.';

  @override
  String journalMoneyStoryHighestDayTransactions(int count) {
    return '$count entries on this day';
  }

  @override
  String get journalMoneyStoryInsightsTitle => 'What this month tells you';

  @override
  String journalMoneyStoryInsightSpendingDown(int percent) {
    return 'You spent $percent% less than last month.';
  }

  @override
  String journalMoneyStoryInsightSpendingUp(int percent) {
    return 'Spending rose $percent% compared with last month.';
  }

  @override
  String journalMoneyStoryInsightTopCategory(String category, int percent) {
    return '$category was the biggest theme at $percent% of spending.';
  }

  @override
  String journalMoneyStoryInsightWeekend(int percent) {
    return 'Weekends made up $percent% of this month\'s spending.';
  }

  @override
  String journalMoneyStoryInsightRecording(int count) {
    return 'You recorded spending on $count days, enough rhythm to see patterns.';
  }

  @override
  String get journalMoneyStoryInsightQuiet =>
      'This month is still quiet. Add a few more entries so the story has more to tell.';

  @override
  String get journalMoneyStoryShareTitle => 'Ready to keep this month';

  @override
  String get journalMoneyStoryShareBody =>
      'Create a polished poster to share or save privately.';

  @override
  String get journalMoneyStoryNoTransactionsTitle =>
      'This month\'s story is empty';

  @override
  String get journalMoneyStoryNoTransactionsBody =>
      'Record a few expenses so Moniary can tell your month through numbers and images.';

  @override
  String get journalExportTitle => 'Export Money Story';

  @override
  String get journalExportPost => 'Post';

  @override
  String get journalExportSave => 'Save image';

  @override
  String get journalExportBrand => 'Moniary · Money Story';

  @override
  String get journalExportSaved => 'Your Money Story image is ready to share.';

  @override
  String get journalExportWholeMonth => 'Whole month';

  @override
  String get journalExportToday => 'Today';

  @override
  String get journalExportCustomRange => 'Custom range';

  @override
  String get journalExportNoTransactions => 'No transactions in this range';

  @override
  String get journalCollectionsTitle => 'Collections';

  @override
  String get journalCreateCollection => 'Create a new collection';

  @override
  String get journalCollectionName => 'Collection name';

  @override
  String get journalCollectionNameHint => 'For example: Da Lat in June';

  @override
  String get journalCollectionEmptyTitle => 'No collections yet';

  @override
  String get journalCollectionEmptyBody =>
      'Gather expenses from a trip or special occasion so you can revisit them later.';

  @override
  String journalCollectionMeta(int count, String amount) {
    return '$count entries · $amount';
  }

  @override
  String get journalAddTransaction => 'Add an entry to this collection';

  @override
  String get journalChooseTransaction => 'Choose a transaction';

  @override
  String get journalCollectionNoTransactions =>
      'This collection has no transactions yet.';

  @override
  String get journalStreakTitle => 'Recording streak';

  @override
  String get journalStreakBreadcrumb => 'Home — recording streak';

  @override
  String journalStreakDays(int count) {
    return '$count days in a row';
  }

  @override
  String journalStreakBody(int count) {
    return 'You have recorded spending every day for the past $count days.';
  }

  @override
  String get journalStreakRecord => 'Your record';

  @override
  String journalStreakRecordDays(int count) {
    return '$count days';
  }

  @override
  String get friendInviteShareDescription =>
      'Send a link so others can add you faster.';

  @override
  String friendInviteShareMessage(String link) {
    return 'Add me on Moniary: $link';
  }

  @override
  String get friendInviteAcceptTitle => 'Friend invite';

  @override
  String friendInviteAcceptSubtitle(String name) {
    return '$name wants to add you on Moniary.';
  }

  @override
  String get friendInviteAcceptButton => 'Add friend';

  @override
  String get friendInviteAccepted => 'Friend added.';

  @override
  String get friendInviteLoading => 'Loading invite...';

  @override
  String get friendInvitePreviewError => 'Could not load the friend invite.';

  @override
  String get friendInviteInvalid => 'This friend link is invalid.';

  @override
  String get friendInviteExpired => 'This friend link has expired.';

  @override
  String get friendInviteUsed => 'This friend link has already been used.';

  @override
  String get friendInviteRevoked => 'This friend link was revoked.';

  @override
  String get friendInviteSelf => 'You cannot use your own friend link.';

  @override
  String get friendInviteAlreadyFriends => 'You are already friends.';

  @override
  String get friendInviteOpenFriends => 'Open friends';

  @override
  String get profileUsernameHint => 'For example: erling_haaland';

  @override
  String get profileUsernameInvalid =>
      'Username must be 3-30 characters using lowercase letters, numbers, or underscores only.';

  @override
  String get privacyProtectionSettingsTitle => 'Protection settings';

  @override
  String get privacyHideBalancesTitle => 'Hide balances';

  @override
  String get privacyHideBalancesSubtitle =>
      'Mask monetary amounts on overview and detail screens.';

  @override
  String get privacyExploreTitle => 'Information and controls';

  @override
  String get privacyStatusProtected => 'Protected';

  @override
  String get privacyStatusReview => 'Review';

  @override
  String privacyRequestCount(int count) {
    return '$count requests';
  }

  @override
  String get biometricReasonDisable => 'Authenticate to disable app lock';

  @override
  String get biometricReasonDeleteAccount =>
      'Authenticate to request account deletion';

  @override
  String get deleteAccountGraceTitle =>
      'Your account will be deleted after 30 days';

  @override
  String get deleteAccountGraceBody =>
      'You will be signed out immediately. During the next 30 days, sign in with the same method to restore your account before its data is permanently deleted.';

  @override
  String get deleteGuestDataTitle => 'Delete guest account data';

  @override
  String get deleteGuestDataBody =>
      'Guest account data is stored only on this device and will be deleted immediately. Language, currency, and first-run preferences will be kept.';

  @override
  String get deleteGuestDataUnderstand =>
      'I understand that guest account data on this device will be deleted immediately.';

  @override
  String get deleteGuestDataAction => 'Delete guest data';

  @override
  String get deleteAccountExportTitle => 'Keep a copy before deletion';

  @override
  String get deleteAccountExportBody =>
      'You can export your data before requesting deletion. An export error never blocks your right to delete the account.';

  @override
  String get deleteAccountExportAction => 'Open data export';

  @override
  String get deleteAccountReasonTitle => 'Why are you leaving Moniary?';

  @override
  String get deleteAccountReasonHint => 'Choose a reason';

  @override
  String get deleteAccountDetailsLabel => 'Additional note (optional)';

  @override
  String get deleteAccountDetailsHint =>
      'What could have made the experience better?';

  @override
  String get deleteAccountDetailsHelper =>
      'Do not enter email, financial information, or sensitive data.';

  @override
  String get deleteAccountGraceUnderstand =>
      'I understand the account will be unavailable and permanently deleted after 30 days unless I restore it.';

  @override
  String get deleteAccountConfirmationPhrase => 'DELETE';

  @override
  String deleteAccountConfirmationLabel(String phrase) {
    return 'Type $phrase to confirm';
  }

  @override
  String get deleteAccountScheduleAction => 'Request account deletion';

  @override
  String get deleteReasonDifficultToUse => 'Difficult to use';

  @override
  String get deleteReasonMissingFeatures => 'Missing features';

  @override
  String get deleteReasonTechnicalIssues => 'Technical issues';

  @override
  String get deleteReasonPrivacyConcerns => 'Privacy concerns';

  @override
  String get deleteReasonNoLongerNeeded => 'No longer needed';

  @override
  String get deleteReasonOther => 'Other';

  @override
  String get deleteAccountImpactTitle => 'Data affected';

  @override
  String deleteAccountTransactionsCount(int count) {
    return '$count transactions';
  }

  @override
  String deleteAccountWalletsCount(int count) {
    return '$count wallets';
  }

  @override
  String deleteAccountPhotosCount(int count) {
    return '$count photos';
  }

  @override
  String get deleteAccountImpactUnavailable =>
      'Detailed counts are unavailable right now. You can still continue with deletion.';

  @override
  String restoreAccountPendingBody(String requestedDate, String deletionDate) {
    return 'The deletion request was created on $requestedDate. Your data will be permanently deleted on $deletionDate.\n\nRestore the account to continue using Moniary.';
  }

  @override
  String get commonUnknown => 'Unknown';

  @override
  String get loginEmailConfirmationSent =>
      'Check your email to confirm the account.';

  @override
  String get loginCreateAccount => 'Create account';

  @override
  String get loginEmailTitle => 'Sign in with email';

  @override
  String get loginEmailLabel => 'Email';

  @override
  String get loginEmailRequired => 'Enter your email';

  @override
  String get loginPasswordLabel => 'Password';

  @override
  String get loginPasswordMinLength =>
      'Password must contain at least 6 characters';

  @override
  String get loginSignUp => 'Sign up';

  @override
  String get loginSignIn => 'Sign in';

  @override
  String get loginAlreadyHaveAccount => 'Already have an account? Sign in';

  @override
  String get loginNeedAccount => 'Need an account? Sign up';

  @override
  String get cameraFallbackPermissionDenied =>
      'Camera permission denied. You can enter the transaction manually.';

  @override
  String get cameraFallbackGenericError =>
      'Could not open camera. You can enter the transaction manually.';

  @override
  String get scanSuggestionNotice =>
      'Fields marked as AI suggestions were filled from the receipt. Review them before saving.';

  @override
  String get scanAiSuggestion => 'AI suggestion';

  @override
  String get scanSuggestionNeedsReview => 'AI suggestion - review recommended';

  @override
  String get friendQrTitle => 'Friend QR';

  @override
  String get friendQrMyCode => 'My code';

  @override
  String get friendQrScan => 'Scan';

  @override
  String get friendQrRetry => 'Try again';

  @override
  String get friendQrShare => 'Share code';

  @override
  String get friendQrLoadError => 'The camera could not be started.';

  @override
  String get friendQrTorch => 'Toggle flashlight';

  @override
  String get friendQrSwitchCamera => 'Switch camera';

  @override
  String get friendQrInvalid => 'This is not a valid Moniary friend QR code.';

  @override
  String get friendRateLimited =>
      'Too many friend requests. Please try again later.';

  @override
  String get groupSplitExact => 'Exact amounts';

  @override
  String get groupParticipantsTitle => 'Participants in this expense';

  @override
  String get groupSettlementDisputeTitle => 'Report a settlement issue';

  @override
  String get groupSettlementDisputeReasonHint => 'Describe what is incorrect';

  @override
  String get groupSettlementDisputeReasonRequired =>
      'Enter a reason for the dispute.';

  @override
  String get groupSettlementDisputeAction => 'Dispute';

  @override
  String get groupTransferOwnershipAction => 'Transfer ownership';

  @override
  String get groupRemoveMemberAction => 'Remove member';

  @override
  String get groupMemberRemoveUnresolved =>
      'This member still has an unsettled balance and cannot be removed.';

  @override
  String get groupMemberActionForbidden =>
      'You do not have permission to manage this member.';

  @override
  String get mascotFirstTransaction =>
      'Hey there! Add your first transaction so piggy can track it! 🐷';

  @override
  String mascotOverBudget(String category) {
    return '$category is over budget! Your wallet is crying! 🛑';
  }

  @override
  String mascotNearBudget(String category) {
    return 'Careful! $category is nearly at its budget limit! ⚠️';
  }

  @override
  String get mascotZeroExpenseToday =>
      'No spending today! Piggy is proud of you! 🐖💖';

  @override
  String mascotGoodSavings(String percent) {
    return 'Saved $percent% this month. Amazing! 🏆';
  }

  @override
  String get mascotFunQuote1 => 'Have you logged your expenses today? 📝';

  @override
  String get mascotFunQuote2 => 'Listen to piggy, don\'t buy that! 🐽';

  @override
  String get mascotFunQuote3 => 'A penny saved is a penny earned! 💰';

  @override
  String get mascotFunQuote4 => 'Feed the piggy bank and go on a trip! 🐖';

  @override
  String get mascotFunQuote5 => 'Tap the pig for some advice! 🐷';
}
