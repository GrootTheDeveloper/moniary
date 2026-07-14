# Domain Models & Entities

**Confidence / Verification Status**: `VERIFIED AGAINST SOURCE`
**Last source audit**: `2026-07-12`

## Core finance

| Model | Path | Notes |
|---|---|---|
| `TransactionEntry` | `lib/features/transactions/domain/models/transaction_entry.dart` | Transaction aggregate/DTO; maps Supabase rows and includes joined category/wallet display fields |
| `TransactionMutationResult` | `lib/features/transactions/domain/models/transaction_mutation_result.dart` | Describes old/new transaction dates so month queries can be invalidated |
| `Wallet` | `lib/features/wallets/domain/models/wallet.dart` | Wallet identity, type, balance/default/active state |
| `Category` | `lib/features/categories/domain/models/category.dart` | Income/expense category |
| `CalendarMonthData`, `CalendarFilters` | `lib/features/calendar/domain/month/` | Read models for the month grid and filters |
| `MonthlyBudget`, `CategoryBudget` | `lib/features/budgets/domain/monthly_budget.dart` | Computed limit/spend/progress models, including warning ratio and category transactions |

## Journal and assistant

| Model | Path | Notes |
|---|---|---|
| `MonthlyRecap`, `MonthlyRecapInsight` | `lib/features/journal/domain/journal_models.dart` | Money Story metrics for income, expense, net, active days, highest day, top categories, and deterministic insight types |
| `RecordingStreak` | same file | Current/longest streak plus recorded dates |
| `JournalCollectionSummary` | same file | Collection metadata hydrated with transaction entries |
| `AssistantAccess` | `lib/features/assistant/domain/assistant_models.dart` | Locally persisted consent/access flags |
| `FinancialAssistantSnapshot` | same file | Deterministic transaction-derived metrics |
| `AssistantMessage`, `AssistantInsight` | same file | Conversation presentation/domain state; not a remote chat payload |

## Profile and collaboration

| Model | Path | Notes |
|---|---|---|
| `UserProfile` | `lib/features/profile/domain/user_profile.dart` | Profile, username, occupation, preferred currency, and setup/survey status |
| Friend entities | `lib/features/friends/domain/entities/friend_profile.dart` | Minimal friend/search/request representations |
| Group entities | `lib/features/groups/domain/entities/` | Current group, transaction, payer/share, settlement, shared-link preview/acceptance result, direct invitation, and enum models |
| Group calculation models | `lib/features/groups/domain/` | Balance/split data used by pure calculators and repository mapping |

The groups directory also contains older-compatible domain types
(`expense_group.dart`, `group_expense.dart`, and related files) used by
calculation/validation tests. Do not delete or merge the two sets without
tracing all call sites.

## Scanning and settings

| Model | Path | Notes |
|---|---|---|
| `OcrResult` | `lib/features/scanning/domain/ocr_result.dart` | DTO consumed by OCR repository/review UI |
| `NotificationSettings` | `lib/features/settings/domain/models/notification_settings.dart` | Supabase/mock notification and report preferences |
| `CsvTransactionRow` | `lib/features/settings/domain/models/csv_transaction_row.dart` | Parsed import row with validation state |
| `ImportHistoryEntry` | `lib/features/settings/domain/import/import_history_entry.dart` | Local JSON history with pending/completed/failed status |
| `ExportHistoryEntry` | `lib/features/settings/domain/export/export_history_entry.dart` | Local JSON export record using stable data-type keys |
| Account/privacy models | `lib/features/settings/domain/account/`, `privacy_requests/` | Active sessions, deletion state/feedback, privacy request type/SLA/history |

## Mapping rule

Domain/data serialization uses stable technical keys. Labels and error messages
are localized only in presentation. When adding a field, update the Dart model,
repository/data-source mapping, relevant Supabase migration or local JSON
compatibility handling, and tests together.
