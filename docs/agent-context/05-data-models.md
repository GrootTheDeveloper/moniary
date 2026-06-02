# Domain Models & Entities

**Confidence / Verification Status**: `VERIFIED`

## Model: TransactionEntry
- **Path**: `lib/features/transactions/domain/models/transaction_entry.dart`
- **Type**: Domain Entity / DTO
- **Serialization**: `fromMap`, `toMap` matching Supabase schema.

## Model: Wallet & Category
- **Path**: `lib/features/wallets/domain/models/wallet.dart`, `lib/features/categories/domain/models/category.dart`
- **Type**: Domain Entity

## Model: ExpenseGroup & GroupMember
- **Path**: `lib/features/groups/domain/expense_group.dart`, `lib/features/groups/domain/group_member.dart`
- **Type**: Domain Entity

## Model: GroupExpense & ExpenseSplit
- **Path**: `lib/features/groups/domain/group_expense.dart`, `lib/features/groups/domain/expense_split.dart`
- **Type**: Domain Entity
- **Used by**: `DebtCalculatorService`

## Model: OcrResult
- **Path**: `lib/features/scanning/domain/ocr_result.dart`
- **Type**: DTO / UI Model
- **Used by**: `OcrService` and `OcrReviewScreen`

## Model: NotificationSettings
- **Path**: `lib/features/settings/domain/models/notification_settings.dart`
- **Type**: Domain Entity / DTO
- **Serialization**: `fromJson`, `toJson` matching Supabase schema.

## Model: ImportHistoryEntry
- **Path**: `lib/features/settings/domain/import/import_history_entry.dart`
- **Type**: Local history DTO
- **Serialization**: `fromMap`, `toMap` matching the local JSON import history file.
- **Status**: `pending`, `completed`, or `failed`. Import starts with a pending entry, then updates the same entry after the import finishes.
