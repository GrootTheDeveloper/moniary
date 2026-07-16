export const financialKinds = new Set([
  'monthlyTotal',
  'weeklyComparison',
  'dailyAverage',
  'topCategory',
  'recurringExpenses',
  'savingSuggestion',
]);

export const allowedAssistantKinds = new Set([
  'greeting',
  'userIdentity',
  'assistantIdentity',
  'unsupported',
  ...financialKinds,
]);

export type AssistantAccessFlags = {
  transactions: boolean;
  wallets: boolean;
  budgets: boolean;
};

const numberKeysByKind: Record<string, readonly string[]> = {
  monthlyTotal: ['monthlyExpense', 'previousMonthExpense', 'monthlyIncome'],
  weeklyComparison: ['currentWeekExpense', 'previousWeekExpense'],
  dailyAverage: ['dailyAverage', 'monthlyExpense'],
  topCategory: ['topCategoryAmount', 'topCategoryShare'],
  recurringExpenses: ['recurringCount', 'recurringAmount'],
  savingSuggestion: [
    'suggestedSaving',
    'monthlyExpense',
    'monthlyIncome',
    'topCategoryAmount',
  ],
};
const stringKeysByKind: Record<string, readonly string[]> = {
  topCategory: ['topCategoryName'],
  recurringExpenses: ['recurringLabel'],
  savingSuggestion: ['topCategoryName'],
};
const walletNumberKeys = ['totalWalletBalance', 'activeWalletCount'] as const;
const budgetNumberKeys = [
  'budgetLimit',
  'budgetSpent',
  'budgetProgress',
  'overBudgetAmount',
] as const;
const budgetStringKeys = ['overBudgetCategoryName'] as const;

export function sanitizeAssistantSnapshot(
  value: unknown,
  access: AssistantAccessFlags,
  kind: string,
) {
  if (!financialKinds.has(kind) || !access.transactions) return null;
  if (!value || typeof value !== 'object' || Array.isArray(value)) return null;

  const input = value as Record<string, unknown>;
  const output: Record<string, unknown> = {};
  copyFiniteNumbers(input, output, numberKeysByKind[kind] ?? []);
  copyNullableStrings(input, output, stringKeysByKind[kind] ?? []);

  const mayUsePlanningContext = kind === 'savingSuggestion';
  const walletsIncluded =
    mayUsePlanningContext && access.wallets && input.walletsIncluded === true;
  output.walletsIncluded = walletsIncluded;
  if (walletsIncluded) {
    copyFiniteNumbers(input, output, walletNumberKeys);
  }

  const budgetsIncluded =
    mayUsePlanningContext && access.budgets && input.budgetsIncluded === true;
  output.budgetsIncluded = budgetsIncluded;
  if (budgetsIncluded) {
    copyFiniteNumbers(input, output, budgetNumberKeys);
    copyNullableStrings(input, output, budgetStringKeys);
  }

  return output;
}

function copyFiniteNumbers(
  input: Record<string, unknown>,
  output: Record<string, unknown>,
  keys: readonly string[],
) {
  for (const key of keys) {
    const value = input[key];
    if (typeof value === 'number' && Number.isFinite(value)) {
      output[key] = value;
    }
  }
}

function copyNullableStrings(
  input: Record<string, unknown>,
  output: Record<string, unknown>,
  keys: readonly string[],
) {
  for (const key of keys) {
    const value = input[key];
    if (value === null) {
      output[key] = null;
    } else if (typeof value === 'string') {
      output[key] = value.replace(/\s+/g, ' ').trim().slice(0, 120);
    }
  }
}
