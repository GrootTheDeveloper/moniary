enum AssistantQuestionKind {
  greeting,
  userIdentity,
  assistantIdentity,
  unsupported,
  monthlyTotal,
  weeklyComparison,
  dailyAverage,
  topCategory,
  recurringExpenses,
  savingSuggestion,
}

class AssistantAccess {
  const AssistantAccess({
    this.introSeen = false,
    this.enabled = false,
    this.transactions = true,
    this.wallets = true,
    this.budgets = true,
  });

  final bool introSeen;
  final bool enabled;
  final bool transactions;
  final bool wallets;
  final bool budgets;

  AssistantAccess copyWith({
    bool? introSeen,
    bool? enabled,
    bool? transactions,
    bool? wallets,
    bool? budgets,
  }) {
    return AssistantAccess(
      introSeen: introSeen ?? this.introSeen,
      enabled: enabled ?? this.enabled,
      transactions: transactions ?? this.transactions,
      wallets: wallets ?? this.wallets,
      budgets: budgets ?? this.budgets,
    );
  }
}

class FinancialAssistantSnapshot {
  const FinancialAssistantSnapshot({
    required this.monthlyExpense,
    required this.previousMonthExpense,
    required this.currentWeekExpense,
    required this.previousWeekExpense,
    required this.dailyAverage,
    required this.topCategoryName,
    required this.topCategoryAmount,
    required this.topCategoryShare,
    required this.recurringLabel,
    required this.recurringCount,
    required this.recurringAmount,
    required this.suggestedSaving,
    this.monthlyIncome = 0,
    this.walletsIncluded = false,
    this.totalWalletBalance = 0,
    this.activeWalletCount = 0,
    this.budgetsIncluded = false,
    this.budgetLimit = 0,
    this.budgetSpent = 0,
    this.budgetProgress = 0,
    this.overBudgetCategoryName,
    this.overBudgetAmount = 0,
  });

  const FinancialAssistantSnapshot.empty()
    : monthlyExpense = 0,
      previousMonthExpense = 0,
      currentWeekExpense = 0,
      previousWeekExpense = 0,
      dailyAverage = 0,
      topCategoryName = null,
      topCategoryAmount = 0,
      topCategoryShare = 0,
      recurringLabel = null,
      recurringCount = 0,
      recurringAmount = 0,
      suggestedSaving = 0,
      monthlyIncome = 0,
      walletsIncluded = false,
      totalWalletBalance = 0,
      activeWalletCount = 0,
      budgetsIncluded = false,
      budgetLimit = 0,
      budgetSpent = 0,
      budgetProgress = 0,
      overBudgetCategoryName = null,
      overBudgetAmount = 0;

  final double monthlyExpense;
  final double previousMonthExpense;
  final double currentWeekExpense;
  final double previousWeekExpense;
  final double dailyAverage;
  final String? topCategoryName;
  final double topCategoryAmount;
  final double topCategoryShare;
  final String? recurringLabel;
  final int recurringCount;
  final double recurringAmount;
  final double suggestedSaving;
  final double monthlyIncome;
  final bool walletsIncluded;
  final double totalWalletBalance;
  final int activeWalletCount;
  final bool budgetsIncluded;
  final double budgetLimit;
  final double budgetSpent;
  final double budgetProgress;
  final String? overBudgetCategoryName;
  final double overBudgetAmount;

  Map<String, Object?> toJson() {
    return {
      'monthlyExpense': monthlyExpense,
      'previousMonthExpense': previousMonthExpense,
      'currentWeekExpense': currentWeekExpense,
      'previousWeekExpense': previousWeekExpense,
      'dailyAverage': dailyAverage,
      'topCategoryName': topCategoryName,
      'topCategoryAmount': topCategoryAmount,
      'topCategoryShare': topCategoryShare,
      'recurringLabel': recurringLabel,
      'recurringCount': recurringCount,
      'recurringAmount': recurringAmount,
      'suggestedSaving': suggestedSaving,
      'monthlyIncome': monthlyIncome,
      'walletsIncluded': walletsIncluded,
      'totalWalletBalance': totalWalletBalance,
      'activeWalletCount': activeWalletCount,
      'budgetsIncluded': budgetsIncluded,
      'budgetLimit': budgetLimit,
      'budgetSpent': budgetSpent,
      'budgetProgress': budgetProgress,
      'overBudgetCategoryName': overBudgetCategoryName,
      'overBudgetAmount': overBudgetAmount,
    };
  }
}

class AssistantSnapshotWindow {
  const AssistantSnapshotWindow({
    required this.now,
    required this.previousMonthStart,
    required this.currentMonthStart,
    required this.nextMonthStart,
    required this.previousWeekStart,
    required this.currentWeekStart,
    required this.budgetMonth,
    required this.daysElapsed,
  });

  factory AssistantSnapshotWindow.local(
    DateTime now, {
    int firstDayOfWeek = DateTime.monday,
  }) {
    final today = DateTime(now.year, now.month, now.day);
    final firstDay = firstDayOfWeek == DateTime.sunday
        ? DateTime.sunday
        : DateTime.monday;
    final delta = (today.weekday - firstDay + 7) % 7;
    final currentWeekStart = today.subtract(Duration(days: delta));
    return AssistantSnapshotWindow(
      now: now,
      previousMonthStart: DateTime(today.year, today.month - 1),
      currentMonthStart: DateTime(today.year, today.month),
      nextMonthStart: DateTime(today.year, today.month + 1),
      previousWeekStart: currentWeekStart.subtract(const Duration(days: 7)),
      currentWeekStart: currentWeekStart,
      budgetMonth: DateTime(today.year, today.month),
      daysElapsed: today.day,
    );
  }

  final DateTime now;
  final DateTime previousMonthStart;
  final DateTime currentMonthStart;
  final DateTime nextMonthStart;
  final DateTime previousWeekStart;
  final DateTime currentWeekStart;
  final DateTime budgetMonth;
  final int daysElapsed;
}

class AssistantInsight {
  const AssistantInsight({required this.kind, required this.snapshot});

  final AssistantQuestionKind kind;
  final FinancialAssistantSnapshot snapshot;
}

class AssistantMessage {
  const AssistantMessage.user(this.text)
    : insight = null,
      assistantText = null,
      isError = false;

  const AssistantMessage.assistant(this.insight, {this.assistantText})
    : text = null,
      isError = false;

  const AssistantMessage.assistantText(this.assistantText)
    : text = null,
      insight = null,
      isError = false;

  const AssistantMessage.error()
    : text = null,
      insight = null,
      assistantText = null,
      isError = true;

  final String? text;
  final AssistantInsight? insight;
  final String? assistantText;
  final bool isError;

  bool get isUser => text != null;

  String? get displayText {
    if (isUser) return text;
    return assistantText;
  }

  Map<String, String>? toHistoryJson() {
    final value = displayText?.trim();
    if (value == null || value.isEmpty || isError) return null;
    return {'role': isUser ? 'user' : 'assistant', 'text': value};
  }
}

class AssistantConversationState {
  const AssistantConversationState({
    this.messages = const [],
    this.isSending = false,
    this.generation = 0,
  });

  final List<AssistantMessage> messages;
  final bool isSending;
  final int generation;

  AssistantConversationState copyWith({
    List<AssistantMessage>? messages,
    bool? isSending,
    int? generation,
  }) {
    return AssistantConversationState(
      messages: messages ?? this.messages,
      isSending: isSending ?? this.isSending,
      generation: generation ?? this.generation,
    );
  }
}
