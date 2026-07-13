enum AssistantQuestionKind {
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
  });

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
}

class AssistantInsight {
  const AssistantInsight({required this.kind, required this.snapshot});

  final AssistantQuestionKind kind;
  final FinancialAssistantSnapshot snapshot;
}

class AssistantMessage {
  const AssistantMessage.user(this.text) : insight = null, isError = false;

  const AssistantMessage.assistant(this.insight) : text = null, isError = false;

  const AssistantMessage.error() : text = null, insight = null, isError = true;

  final String? text;
  final AssistantInsight? insight;
  final bool isError;

  bool get isUser => text != null;
}
