import {
  allowedAssistantKinds,
  sanitizeAssistantSnapshot,
} from './logic.ts';

function assert(condition: unknown, message: string) {
  if (!condition) throw new Error(message);
}

Deno.test('assistant kinds are explicit and reject arbitrary labels', () => {
  assert(allowedAssistantKinds.has('monthlyTotal'), 'known kind missing');
  assert(!allowedAssistantKinds.has('bypassConsent'), 'unknown kind accepted');
});

Deno.test('snapshot strips wallet and budget values without persisted access', () => {
  const snapshot = sanitizeAssistantSnapshot(
    {
      monthlyExpense: 100,
      walletsIncluded: true,
      totalWalletBalance: 999,
      budgetsIncluded: true,
      budgetLimit: 500,
      secret: 'must not leave the server',
    },
    { transactions: true, wallets: false, budgets: false },
    'monthlyTotal',
  );
  assert(snapshot?.monthlyExpense === 100, 'transaction value missing');
  assert(snapshot?.walletsIncluded === false, 'wallet consent bypassed');
  assert(!('totalWalletBalance' in (snapshot ?? {})), 'wallet value leaked');
  assert(snapshot?.budgetsIncluded === false, 'budget consent bypassed');
  assert(!('budgetLimit' in (snapshot ?? {})), 'budget value leaked');
  assert(!('secret' in (snapshot ?? {})), 'unknown key leaked');
});

Deno.test('non-financial kinds cannot forward a snapshot', () => {
  const snapshot = sanitizeAssistantSnapshot(
    { monthlyExpense: 100 },
    { transactions: true, wallets: true, budgets: true },
    'greeting',
  );
  assert(snapshot === null, 'non-financial snapshot was forwarded');
});

Deno.test('financial kinds receive only the facts needed for that question', () => {
  const snapshot = sanitizeAssistantSnapshot(
    {
      monthlyExpense: 100,
      previousMonthExpense: 90,
      currentWeekExpense: 80,
      recurringAmount: 70,
      walletsIncluded: true,
      totalWalletBalance: 60,
      budgetsIncluded: true,
      budgetLimit: 50,
    },
    { transactions: true, wallets: true, budgets: true },
    'monthlyTotal',
  );
  assert(snapshot?.monthlyExpense === 100, 'monthly fact missing');
  assert(snapshot?.previousMonthExpense === 90, 'comparison fact missing');
  assert(!('currentWeekExpense' in (snapshot ?? {})), 'weekly fact leaked');
  assert(!('recurringAmount' in (snapshot ?? {})), 'recurring fact leaked');
  assert(snapshot?.walletsIncluded === false, 'wallet context leaked');
  assert(snapshot?.budgetsIncluded === false, 'budget context leaked');
});
