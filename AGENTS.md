# AGENTS.md — Moniary Flutter Mobile Tasks for Khánh

## 1. Project context

Moniary is a mobile personal finance application built with **Flutter** and **Dart**. The existing project already has several completed modules: anonymous login, first-time profile setup, calendar, transaction creation/editing, image upload to Supabase Storage, wallet/category management, Vietnamese localization, dark mode, account deletion, and CSV export.

This AGENTS.md focuses only on the tasks assigned to **Khánh** in the project assignment table.

## 2. Assigned owner

- **Owner:** Khánh
- **Platform:** Mobile app
- **Language:** Dart
- **Framework:** Flutter
- **Expected integration style:** Add new screens, models, services, and state-management logic into the existing Flutter project without breaking completed modules.

## 3. Khánh’s required features

From the assignment table, Khánh is responsible for the following unfinished features:

| Feature group | Feature | Status | Priority | Note |
|---|---|---:|---|---|
| OCR & AI | Màn hình Scanning | Chưa làm | Sau MVP | Có trong mockup nhưng chưa triển khai code |
| OCR & AI | Tự động trích xuất dữ liệu OCR | Chưa làm | Sau MVP | Chờ phase AI |
| Nhóm & Cộng đồng | Chi tiêu nhóm | Chưa làm | Sau MVP | Dành cho phase sau MVP |
| Nhóm & Cộng đồng | Chia tiền & tính nợ | Chưa làm | Sau MVP | Chưa triển khai |

## 4. Implementation principles

Codex must follow these principles when modifying the project:

1. Use **Flutter + Dart** only for the mobile implementation.
2. Keep the app style consistent with the existing Moniary UI: card-based layout, dark mode, Vietnamese labels, rounded corners, and clear finance-oriented interactions.
3. Do not rewrite already completed modules unless integration requires small changes.
4. Prefer modular structure: separate `screens`, `widgets`, `models`, `services`, and `providers/controllers`.
5. Keep Vietnamese text user-facing by default.
6. Add graceful loading, empty, and error states for every screen.
7. Avoid hard-coding user IDs, wallet IDs, category IDs, or Supabase paths.
8. Any AI/OCR behavior must be wrapped behind a service interface so the implementation can be replaced later.

## 5. Suggested folder structure

Add or update files using a structure similar to this:

```text
lib/
  features/
    scanning/
      screens/
        scanning_screen.dart
        ocr_review_screen.dart
      widgets/
        scan_camera_preview.dart
        scan_result_card.dart
        extracted_transaction_form.dart
      models/
        ocr_result.dart
        extracted_transaction.dart
      services/
        ocr_service.dart
        mock_ocr_service.dart
      providers/
        scanning_controller.dart

    groups/
      screens/
        groups_screen.dart
        group_detail_screen.dart
        group_expense_form_screen.dart
        debt_summary_screen.dart
      widgets/
        group_card.dart
        member_chip.dart
        split_method_selector.dart
        debt_balance_card.dart
      models/
        expense_group.dart
        group_member.dart
        group_expense.dart
        expense_split.dart
        debt_balance.dart
      services/
        group_expense_service.dart
        debt_calculator_service.dart
      providers/
        group_controller.dart
        debt_controller.dart
```

If the current project uses another architecture, adapt to the existing pattern instead of forcing this exact folder structure.

## 6. Feature 1 — Scanning screen

### Goal

Implement the **Scanning** screen shown in the mockup but not yet implemented in code.

### Requirements

1. Create a scanning entry screen named `ScanningScreen`.
2. The screen must allow users to:
   - open camera capture;
   - choose an image from album/gallery;
   - preview the selected receipt/image;
   - start OCR extraction;
   - navigate to a review screen after extraction.
3. Reuse the existing image picker/camera logic if the project already has it in the transaction module.
4. Show these states:
   - no image selected;
   - image selected;
   - scanning/loading;
   - OCR success;
   - OCR failed.
5. The UI should use Vietnamese labels, for example:
   - `Quét hóa đơn`
   - `Chụp ảnh`
   - `Chọn từ thư viện`
   - `Đang trích xuất dữ liệu...`
   - `Không thể đọc hóa đơn. Vui lòng thử lại.`

### Acceptance criteria

- User can open the Scanning screen from the app navigation.
- User can pick or capture an image.
- The selected image is displayed before extraction.
- Pressing the scan button triggers `OcrService.extractFromImage()`.
- Loading and error states are clearly visible.
- The implementation does not break the existing transaction image upload feature.

## 7. Feature 2 — Automatic OCR data extraction

### Goal

Create an OCR extraction flow that converts receipt/image content into structured transaction data.

### Important note

The real AI/OCR phase may not be available yet. Therefore, implement the OCR system behind an abstraction so that mock OCR can be used now and a real AI provider can be connected later.

### Data model

Create a model similar to:

```dart
class OcrResult {
  final String? merchantName;
  final double? totalAmount;
  final DateTime? transactionDate;
  final String? note;
  final List<OcrLineItem> items;
  final double confidence;

  const OcrResult({
    this.merchantName,
    this.totalAmount,
    this.transactionDate,
    this.note,
    this.items = const [],
    this.confidence = 0,
  });
}

class OcrLineItem {
  final String name;
  final int? quantity;
  final double? price;

  const OcrLineItem({
    required this.name,
    this.quantity,
    this.price,
  });
}
```

### Service interface

Create an interface similar to:

```dart
abstract class OcrService {
  Future<OcrResult> extractFromImage(String imagePath);
}
```

### Temporary mock implementation

Until the real OCR/AI provider is connected, create `MockOcrService` that returns sample data after a short delay:

```dart
class MockOcrService implements OcrService {
  @override
  Future<OcrResult> extractFromImage(String imagePath) async {
    await Future.delayed(const Duration(seconds: 2));
    return OcrResult(
      merchantName: 'Cửa hàng mẫu',
      totalAmount: 125000,
      transactionDate: DateTime.now(),
      note: 'Tự động trích xuất từ hóa đơn',
      confidence: 0.85,
    );
  }
}
```

### Review screen

After OCR extraction, navigate to `OcrReviewScreen`.

The review screen must allow users to:

1. See extracted merchant/name/note/date/amount.
2. Edit wrong fields manually.
3. Choose wallet and category using existing wallet/category data.
4. Save the reviewed data as a normal transaction.
5. Return to the calendar or transaction detail after saving.

### Acceptance criteria

- OCR extraction result is converted to an editable transaction form.
- User can correct the extracted values before saving.
- Saving creates a normal transaction using the existing transaction creation flow/service.
- OCR implementation can be swapped from mock to real provider without changing UI code heavily.

## 8. Feature 3 — Group expenses

### Goal

Implement group expense management for the post-MVP community feature.

### Main screens

1. `GroupsScreen`
   - list all user groups;
   - create a new group;
   - empty state when no groups exist.

2. `GroupDetailScreen`
   - show group name;
   - show members;
   - show group expenses;
   - navigate to add group expense;
   - navigate to debt summary.

3. `GroupExpenseFormScreen`
   - add/edit a group expense;
   - input amount, date, note, payer, participants, and split method.

### Suggested data models

```dart
class ExpenseGroup {
  final String id;
  final String name;
  final String ownerId;
  final DateTime createdAt;
  final List<GroupMember> members;

  const ExpenseGroup({
    required this.id,
    required this.name,
    required this.ownerId,
    required this.createdAt,
    this.members = const [],
  });
}

class GroupMember {
  final String id;
  final String displayName;
  final String? email;
  final String? avatarUrl;

  const GroupMember({
    required this.id,
    required this.displayName,
    this.email,
    this.avatarUrl,
  });
}

class GroupExpense {
  final String id;
  final String groupId;
  final String payerMemberId;
  final double amount;
  final String note;
  final DateTime date;
  final List<ExpenseSplit> splits;

  const GroupExpense({
    required this.id,
    required this.groupId,
    required this.payerMemberId,
    required this.amount,
    required this.note,
    required this.date,
    this.splits = const [],
  });
}

class ExpenseSplit {
  final String memberId;
  final double amount;

  const ExpenseSplit({
    required this.memberId,
    required this.amount,
  });
}
```

### Required group actions

- Create group.
- Add member.
- Remove member if no blocking expense exists.
- Add group expense.
- Edit group expense.
- Delete group expense.
- View group expense history.

### Split methods

Support at least:

1. **Chia đều** — split amount equally among selected members.
2. **Tự nhập số tiền** — user manually enters each member’s share.

Optional if time allows:

3. **Theo phần trăm** — user enters percentage for each member.

### Acceptance criteria

- User can create and open a group.
- User can add members to a group.
- User can add a group expense with payer and participants.
- The app validates that split total equals the expense total.
- Empty and error states are handled.

## 9. Feature 4 — Split bill and debt calculation

### Goal

Calculate how much each member owes or should receive after group expenses.

### Core calculation

For each group expense:

- The payer paid the full expense amount.
- Each participant owes their split amount.
- Net balance per member:
  - positive balance means the member should receive money;
  - negative balance means the member owes money.

### Example

Expense: 300,000 VND paid by A and split equally among A, B, C.

- A paid: 300,000
- A share: 100,000
- B share: 100,000
- C share: 100,000

Net result:

- A: +200,000
- B: -100,000
- C: -100,000

### Service

Create `DebtCalculatorService` with methods similar to:

```dart
class DebtCalculatorService {
  Map<String, double> calculateBalances(List<GroupExpense> expenses) {
    final balances = <String, double>{};

    for (final expense in expenses) {
      balances[expense.payerMemberId] =
          (balances[expense.payerMemberId] ?? 0) + expense.amount;

      for (final split in expense.splits) {
        balances[split.memberId] =
            (balances[split.memberId] ?? 0) - split.amount;
      }
    }

    return balances;
  }
}
```

Optional advanced method:

```dart
class DebtSettlement {
  final String fromMemberId;
  final String toMemberId;
  final double amount;

  const DebtSettlement({
    required this.fromMemberId,
    required this.toMemberId,
    required this.amount,
  });
}
```

Add a method to simplify balances into a list of payments:

```dart
List<DebtSettlement> simplifyDebts(Map<String, double> balances)
```

### Debt summary screen

Create `DebtSummaryScreen` showing:

- member balance list;
- who owes money;
- who should receive money;
- suggested settlement list, for example: `B trả A 100.000đ`.

### Acceptance criteria

- Debt calculation is correct for equal split.
- Debt calculation is correct for manual split.
- The UI shows positive and negative balances clearly.
- Settlement suggestions are generated.
- Add unit tests for debt calculation.

## 10. Supabase/backend integration guidance

If the current project already uses Supabase, implement data access through service classes. Do not call Supabase directly from widgets.

Suggested tables for later backend integration:

```sql
expense_groups (
  id uuid primary key,
  owner_id uuid not null,
  name text not null,
  created_at timestamptz default now()
);

group_members (
  id uuid primary key,
  group_id uuid references expense_groups(id),
  user_id uuid null,
  display_name text not null,
  email text null,
  avatar_url text null,
  created_at timestamptz default now()
);

group_expenses (
  id uuid primary key,
  group_id uuid references expense_groups(id),
  payer_member_id uuid references group_members(id),
  amount numeric not null,
  note text,
  expense_date date not null,
  created_at timestamptz default now()
);

group_expense_splits (
  id uuid primary key,
  expense_id uuid references group_expenses(id),
  member_id uuid references group_members(id),
  amount numeric not null
);
```

If backend schema is not ready, use local mock repositories first, but keep method names compatible with future Supabase implementation.

## 11. Navigation requirements

Add navigation entries only if they fit the existing app shell.

Suggested navigation:

- Add `ScanningScreen` as a main action or tab item if mockup expects it.
- Add `GroupsScreen` as a separate tab/menu item named `Nhóm` or `Cộng đồng`.

Do not remove existing calendar, transaction, wallet, category, or settings navigation.

## 12. State management

Use the state-management approach already present in the project. If the project has no clear pattern, use one of the following:

- `ChangeNotifier` for simple implementation;
- `Riverpod` if the project already uses Riverpod;
- `Bloc/Cubit` if the project already uses Bloc.

Do not introduce a new state-management package if the project already has one.

## 13. Validation rules

### OCR review form

- Amount must be greater than 0.
- Date must not be empty.
- Wallet must be selected.
- Category must be selected.
- User must be able to edit extracted data before saving.

### Group expense form

- Group must have at least 2 members for split bill.
- Amount must be greater than 0.
- Payer must be selected.
- At least one participant must be selected.
- Sum of split amounts must equal total amount.
- Manual split cannot contain negative values.

## 14. Testing requirements

Add tests for:

1. `DebtCalculatorService.calculateBalances()`.
2. Equal split generation.
3. Manual split validation.
4. OCR mock service returns valid sample data.
5. Group expense form validation logic if validation is extracted into a service/helper.

Suggested test file paths:

```text
test/features/groups/debt_calculator_service_test.dart
test/features/groups/group_expense_validation_test.dart
test/features/scanning/mock_ocr_service_test.dart
```

## 15. Definition of done

The task is done when:

- Scanning screen is visible and usable.
- OCR mock extraction flow works end-to-end.
- OCR result can be reviewed and saved as a transaction.
- Group list, group detail, group expense form, and debt summary screens are implemented.
- Split bill logic works for equal and manual splits.
- Unit tests for debt calculation pass.
- Existing completed app features still run without regression.
- All user-facing text is Vietnamese.
- The app builds successfully with `flutter analyze` and `flutter test`.

## 16. Commands Codex should run

After implementation, run:

```bash
flutter pub get
flutter analyze
flutter test
```

If the project has code generation, also run the existing build command, for example:

```bash
dart run build_runner build --delete-conflicting-outputs
```

Only run code generation if the project already uses generated files.

## 17. Do not do

- Do not implement unrelated features assigned to Khang, Khoa, or Hoàng.
- Do not remove existing Supabase transaction/image upload logic.
- Do not hard-code mock OCR forever; keep the service replaceable.
- Do not store real OCR provider API keys inside Flutter source code.
- Do not skip validation for split amounts.
- Do not create English-only UI for these features.

