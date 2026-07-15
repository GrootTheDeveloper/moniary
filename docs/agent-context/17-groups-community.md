# Groups & Community — Detailed Reference Specification

**Document type**: `IMPLEMENTATION REFERENCE`
**Current implementation audit**: `2026-07-10`

The feature and its migration are implemented. Use `04-features.md`, current
Dart source, and `20260611000000_groups_community.sql` for current-state facts.
The requirements below remain useful for business rules and calculation intent.

## 1. Role and Objective

You are a senior Flutter engineer working on the Moniary mobile app.

Your task is to implement the **Nhóm & Cộng đồng** feature set for Moniary using:

- Dart
- Flutter
- Android Studio
- Supabase Auth
- Supabase PostgreSQL
- Supabase Storage
- Existing app architecture and conventions

Moniary is a photo-first expense tracking app. The group feature extends personal photo-based expense tracking into shared group expenses, debt calculation, repayment suggestions, confirmation flows, and member collaboration.

This feature must be implemented without breaking existing modules such as:

- Auth
- Calendar
- Personal transactions
- Wallets
- Categories
- Image upload
- Statistics
- Profile/settings

Before coding, read the current project structure carefully and follow the existing architecture, naming conventions, folder organization, routing, state management, and UI style.

---

## 2. High-Level Business Goal

The **Nhóm & Cộng đồng** feature allows users to:

1. Create spending groups.
2. Invite members.
3. Add photo-based group transactions.
4. Choose how the transaction should be split.
5. Record who actually paid the merchant/seller.
6. Calculate each member's balance.
7. Generate repayment suggestions.
8. Let users mark and confirm debt repayment.
9. Prevent users from leaving a group while unsettled debt still exists.
10. Allow comments for discussion and verification.
11. Keep a complete transaction and debt history for the group.

Group expenses are different from personal expenses because the system must track two separate financial concepts:

| Concept | Meaning |
|---|---|
| `shareAmount` | How much each member must bear or has used |
| `paidAmount` | How much each member actually paid upfront |

The final balance is always calculated as:

```text
balance = shareAmount - paidAmount
```

Meaning:

| Balance | Meaning |
|---:|---|
| `> 0` | This member owes money |
| `< 0` | This member should receive money |
| `= 0` | This member is settled |

---

## 3. Non-Negotiable Implementation Rules

Follow these rules strictly:

1. Do not use `double` for money.
2. Store money as integer minor units, for example VND amount as integer.
3. Do not hard-code user IDs.
4. Do not create fake production data.
5. Do not put split, balance, or settlement calculation inside Widgets.
6. Put calculation logic inside domain services such as:
   - `GroupSplitCalculator`
   - `SettlementCalculator`
7. Do not publicize group transaction images.
8. Store image paths as source of truth, not public URLs.
9. Use signed URLs only for display.
10. Keep Supabase Storage private.
11. Do not allow a user to edit a group transaction unless they created it.
12. Do not allow a user to leave a group if they still owe money or are still owed money.
13. Do not support inviting by email.
14. Do not implement percentage-based splitting.
15. Do not implement arbitrary custom percentage splitting.
16. Do not remove or rewrite existing personal transaction behavior.
17. If the codebase already has patterns for repository, provider, router, or service layers, follow them.

---

## 4. Recommended Flutter Module Structure

If the project does not already have a group module, create:

```text
lib/features/groups/
  data/
    datasources/
    models/
    repositories/
  domain/
    entities/
    repositories/
    services/
    usecases/
  presentation/
    providers/
    screens/
    widgets/
```

Required domain services:

```text
lib/features/groups/domain/services/group_split_calculator.dart
lib/features/groups/domain/services/settlement_calculator.dart
```

Suggested screens:

```text
lib/features/groups/presentation/screens/group_list_screen.dart
lib/features/groups/presentation/screens/create_group_screen.dart
lib/features/groups/presentation/screens/group_detail_screen.dart
lib/features/groups/presentation/screens/add_group_transaction_screen.dart
lib/features/groups/presentation/screens/debt_settlement_screen.dart
lib/features/groups/presentation/screens/group_transaction_detail_screen.dart
```

Suggested widgets:

```text
lib/features/groups/presentation/widgets/group_card.dart
lib/features/groups/presentation/widgets/member_picker.dart
lib/features/groups/presentation/widgets/payment_mode_selector.dart
lib/features/groups/presentation/widgets/split_mode_selector.dart
lib/features/groups/presentation/widgets/payer_amount_input_list.dart
lib/features/groups/presentation/widgets/member_share_input_list.dart
lib/features/groups/presentation/widgets/balance_table.dart
lib/features/groups/presentation/widgets/settlement_suggestion_card.dart
lib/features/groups/presentation/widgets/group_transaction_card.dart
lib/features/groups/presentation/widgets/comment_list.dart
```

---

## 5. Main Entities

Implement or adapt the following entities/models.

### 5.1. Group

Represents a spending group.

Fields:

```text
id
name
avatarUrl
description
type
createdBy
status
createdAt
updatedAt
```

Rules:

- `name` is required.
- `avatarUrl` is optional.
- `description` is optional.
- `type` is optional and user-defined.
- `type` is not a fixed dropdown.
- The UI should show placeholder text only.

Placeholder for type input:

```text
Ví dụ: Du lịch, Ăn uống, Ở chung, Couple, Bạn bè...
```

---

### 5.2. GroupMember

Represents a user inside a group.

Fields:

```text
id
groupId
userId
role
status
joinedAt
leftAt
```

Allowed roles:

```text
owner
admin
member
```

Allowed statuses:

```text
invited
active
declined
left
removed
```

Rules:

- The creator of a group becomes `owner`.
- The creator must also be inserted as an active group member.
- Do not hard-delete members who have historical transactions.
- If a user leaves, set `status = left`.
- Only active members participate in new group transaction calculations.

---

### 5.3. GroupTransaction

Represents a photo-based group expense.

Fields:

```text
id
groupId
createdBy
totalAmount
categoryId
caption
note
imagePath
imageUploadStatus
splitMode
paymentMode
splitStatus
transactionDate
createdAt
updatedAt
```

Required enums:

```text
splitMode: equal | unequal
paymentMode: everyone_paid | single_payer | multiple_payers
splitStatus: draft | pending_member_amount_input | amount_mismatch | posted | cancelled
imageUploadStatus: pending | uploading | uploaded | failed
```

Rules:

- `transactionDate` is the date/time the user posts the transaction to the group.
- Do not allow the user to manually edit `transactionDate` in this phase.
- Use `now()` for `transactionDate` and `createdAt`.
- A transaction may have at most one image in this phase.
- Image is recommended but not required.
- For equal split, the transaction can become `posted` immediately after validation and confirmation.
- For unequal split, the transaction becomes `pending_member_amount_input` until all active members submit their used amount.

---

### 5.4. GroupTransactionPayer

Represents who paid money upfront.

Fields:

```text
id
groupTransactionId
userId
paidAmount
createdAt
updatedAt
```

Rules:

- `paidAmount` must be greater than or equal to 0.
- For `multiple_payers`, each selected payer must have `paidAmount > 0`.
- For `single_payer`, only one payer exists and their `paidAmount = totalAmount`.
- For `everyone_paid`, each member's `paidAmount = shareAmount`.

---

### 5.5. GroupTransactionShare

Represents each member's share or used amount.

Fields:

```text
id
groupTransactionId
userId
shareAmount
inputStatus
submittedAt
createdAt
updatedAt
```

Allowed input statuses:

```text
pending
submitted
```

Rules:

- For equal split, the system creates all share rows automatically.
- For unequal split, each active member must submit their own used amount.
- `shareAmount` may be 0 if a member did not use anything.
- The transaction cannot become `posted` until all active members have submitted their used amount.
- For unequal split, total share amount must equal transaction total amount.

---

### 5.6. GroupBalance

This can be a table, view, or calculated DTO.

Fields:

```text
groupId
userId
totalShareAmount
totalPaidAmount
balance
```

Formula:

```text
balance = totalShareAmount - totalPaidAmount
```

Rules:

- Positive balance means the user owes money.
- Negative balance means the user should receive money.
- Zero balance means the user is settled.

---

### 5.7. GroupSettlementSuggestion

Represents one suggested repayment row.

Fields:

```text
id
groupId
fromUserId
toUserId
amount
status
payerMarkedPaidAt
receiverConfirmedAt
createdAt
updatedAt
```

Allowed statuses:

```text
pending
payer_marked_paid
completed
disputed
```

Rules:

- `fromUserId` is the person who must pay.
- `toUserId` is the person who should receive.
- The payer can only mark their own suggestion as paid.
- The receiver can only confirm after the payer has marked it as paid.
- Other members can view but cannot act on another user's settlement.

---

### 5.8. GroupTransactionComment

Represents comments under a group transaction.

Fields:

```text
id
groupTransactionId
userId
content
createdAt
updatedAt
```

Rules:

- Active members can comment.
- Comments do not modify transaction data.
- Comments are for discussion, verification, and dispute handling.
- Only the comment owner can edit/delete their own comment unless current app rules say otherwise.

---

## 6. Group Creation Pipeline

### 6.1. Create Group Screen

The user opens the Group tab and taps **Tạo nhóm mới**.

The form includes:

- Group name: required.
- Group avatar: optional.
- Description: optional.
- Group type: optional text input.

The group type field is free text, not a fixed dropdown. Use placeholder:

```text
Ví dụ: Du lịch, Ăn uống, Ở chung, Couple, Bạn bè...
```

If the user leaves group type empty, group creation is still valid.

After creation:

1. Insert `groups`.
2. Insert creator into `group_members`.
3. Set creator role to `owner`.
4. Set creator status to `active`.
5. Navigate to Group Detail Screen.

---

## 7. Invite Member Pipeline

Supported invite methods:

1. Invite by link.
2. Invite from existing friend list.
3. Invite by username.

Do not support invite by email.

### 7.1. Invite by Link

Requirements:

- Generate a shared link that expires after seven days; generating a replacement revokes the earlier active link.
- Opening the link shows a localized preview/confirmation screen with explicit join and dismiss actions.
- Dismissing a shared-link preview does not write a decline state because shared links are reusable and are not per-recipient invitations.
- The preview handles invalid, expired, revoked, used, and already-member states.
- If the recipient accepts, add or update their member status to `active` without consuming the shared link.

### 7.2. Invite from Friend List

Requirements:

- If a friend module already exists, show existing friends.
- Allow owner/admin to select one or multiple friends.
- Send invite notification to selected users.
- If no friend module exists, implement a clean abstraction and an empty state:

```text
Bạn chưa có bạn bè nào để mời.
```

### 7.3. Invite by Username

Requirements:

- Owner/admin enters username.
- App checks if username exists.
- If username does not exist, show:

```text
Không tìm thấy người dùng này.
```

Rules:

- Do not invite users who are already active members.
- Do not duplicate pending invitations.
- Only owner/admin can invite.
- Member cannot invite unless the existing project has a permission system allowing it.

---

## 8. Add Group Transaction Pipeline

This is the core feature. Without group transactions, split, debt, settlement, and comment flows have no data.

### 8.1. Form Fields

The Add Group Transaction Screen must include:

- Image or receipt photo: optional but recommended.
- Caption or note.
- Total amount: required and must be greater than 0.
- Category.
- Split mode: required.
- Payment mode: required.
- Payer information depending on payment mode.

Do not show manual transaction date input.

Set automatically:

```text
transactionDate = now()
createdAt = now()
```

### 8.2. Confirmation Dialog

When the user taps **Đăng**, do not save immediately.

Show confirmation dialog:

```text
Bạn đã chắc chắn chưa?
```

Buttons:

| Button | Behavior |
|---|---|
| Hủy | Close dialog and return to form |
| Đăng | Continue validation and save |

If user taps **Hủy**:

- Do not create transaction.
- Do not upload image.
- Do not calculate debt.

---

## 9. Split Mode and Payment Mode Logic

The form has two-level selection.

### 9.1. Split Mode

Split mode decides `shareAmount`.

Allowed values:

```text
equal
unequal
```

UI labels:

```text
Chia đều
Chia không đều
```

### 9.2. Payment Mode

Payment mode decides `paidAmount`.

Allowed values:

```text
everyone_paid
single_payer
multiple_payers
```

UI labels:

```text
Mọi người đều trả
Một người trả
Nhiều người trả
```

### 9.3. Core Formula

All cases must eventually use:

```text
balance = shareAmount - paidAmount
```

---

## 10. Equal Split Logic

Use when all active members bear the same amount.

Formula:

```text
baseShare = totalAmount ~/ activeMemberCount
remainder = totalAmount % activeMemberCount
```

Distribute the remainder by adding 1 unit of money to the first `remainder` members using a stable order such as `joinedAt` or `userId`.

Rules:

- Total share amount must always equal total amount.
- Use only active members.
- If no active member exists, throw validation error.
- The transaction can become `posted` immediately after valid save.

### 10.1. Equal Split + Everyone Paid

Meaning:

All members bear the same amount and each person already paid their exact share.

Implementation:

1. Calculate equal shares.
2. Set each active member's `paidAmount = shareAmount`.
3. Create payer rows for every active member.
4. Create share rows for every active member.
5. Balance for all members must be 0.
6. Do not create settlement suggestions.

Example:

| User | Share | Paid | Balance |
|---|---:|---:|---:|
| A | 300000 | 300000 | 0 |
| B | 300000 | 300000 | 0 |
| C | 300000 | 300000 | 0 |
| D | 300000 | 300000 | 0 |

---

### 10.2. Equal Split + Single Payer

Meaning:

All members bear the same amount, but one member paid the full total.

UI behavior:

1. Show active member list.
2. User selects exactly one payer.
3. Do not show amount input for this payer.
4. Set selected payer's `paidAmount = totalAmount`.
5. Set all other members' `paidAmount = 0`.

Validation:

- Exactly one active member must be selected.
- If not selected, show:

```text
Vui lòng chọn người đã trả tiền.
```

Example:

Total amount: 1200000  
Members: A, B, C, D  
A paid all.

| User | Share | Paid | Balance |
|---|---:|---:|---:|
| A | 300000 | 1200000 | -900000 |
| B | 300000 | 0 | 300000 |
| C | 300000 | 0 | 300000 |
| D | 300000 | 0 | 300000 |

Settlement suggestions:

| From | To | Amount |
|---|---|---:|
| B | A | 300000 |
| C | A | 300000 |
| D | A | 300000 |

---

### 10.3. Equal Split + Multiple Payers

Meaning:

All members bear the same amount, but multiple members paid upfront.

UI behavior:

1. Show active member list as checkboxes.
2. User selects at least two payers.
3. For each selected payer, show amount textbox.
4. User enters paid amount for each selected payer.

Validation:

- At least 2 payers must be selected.
- Each selected payer must have `paidAmount > 0`.
- Sum of paid amounts must equal total amount.
- Every payer must be an active member.

Error messages:

```text
Vui lòng chọn ít nhất 2 người đã trả tiền.
Vui lòng nhập số tiền đã trả cho từng thành viên.
Số tiền đã trả phải lớn hơn 0.
Tổng số tiền đã trả chưa khớp với tổng giá trị giao dịch.
```

Example:

Total amount: 1200000  
A paid 700000  
B paid 500000

| User | Share | Paid | Balance |
|---|---:|---:|---:|
| A | 300000 | 700000 | -400000 |
| B | 300000 | 500000 | -200000 |
| C | 300000 | 0 | 300000 |
| D | 300000 | 0 | 300000 |

Settlement suggestions:

| From | To | Amount |
|---|---|---:|
| C | A | 300000 |
| D | A | 100000 |
| D | B | 200000 |

---

## 11. Unequal Split Logic

Use when members use different amounts.

Examples:

- A eats 65000.
- B eats 50000.
- C eats 80000.

In unequal split, the app cannot calculate shares automatically. Each active member must submit their own used amount.

### 11.1. Unequal Split Pipeline

When the user chooses **Chia không đều**:

1. User enters image, caption, total amount, category, and optional note.
2. User selects payment mode:
   - Everyone paid
   - Single payer
   - Multiple payers
3. User enters payer data according to selected payment mode.
4. User taps **Đăng**.
5. Show confirmation dialog:

```text
Bạn đã chắc chắn chưa?
```

6. If user cancels, do nothing.
7. If user confirms, create a group transaction with:

```text
splitStatus = pending_member_amount_input
```

8. Notify all active members, including the creator:

```text
Vui lòng nhập số tiền bạn đã sử dụng trong giao dịch này.
```

9. Each active member opens the transaction and submits their used amount.
10. Save each submitted amount into `group_transaction_shares`.
11. When all active members have submitted, validate:

```text
sum(shareAmount) == totalAmount
```

12. If valid:
    - Set `splitStatus = posted`.
    - Calculate balances.
    - Create settlement suggestions if needed.
    - Notify all members:

```text
Giao dịch nhóm đã được đăng thành công.
```

13. If invalid:
    - Set `splitStatus = amount_mismatch`.
    - Do not calculate final debt.
    - Do not create settlements.
    - Notify members:

```text
Tổng số tiền các thành viên nhập chưa khớp với tổng tiền giao dịch. Vui lòng kiểm tra và nhập lại.
```

14. Members must correct their submitted used amounts.
15. Revalidate until the transaction becomes valid.

### 11.2. Important Validation Rule

Do not validate unequal split using:

```text
totalAmount - amountPaidByA
```

This is wrong because `amountPaidByA` is the amount A paid upfront, not the amount A used.

Correct validation:

```text
sum(all members' used amounts) == totalAmount
```

If A has already submitted their used amount, the remaining amount can be checked as:

```text
sum(B, C, D... used amounts) == totalAmount - A's used amount
```

Never use:

```text
totalAmount - A's paid amount
```

---

### 11.3. Unequal Split + Everyone Paid

Meaning:

Each member used a different amount and each member already paid exactly their own used amount.

Implementation:

1. Collect each member's `shareAmount`.
2. Validate total share amount equals total amount.
3. Set `paidAmount = shareAmount` for each member.
4. Balance for all members must be 0.
5. Do not create settlement suggestions.

Example:

| User | Share | Paid | Balance |
|---|---:|---:|---:|
| A | 65000 | 65000 | 0 |
| B | 50000 | 50000 | 0 |
| C | 80000 | 80000 | 0 |

---

### 11.4. Unequal Split + Single Payer

Meaning:

Each member used a different amount, but one member paid the full total.

UI behavior:

1. Show active member list.
2. User selects exactly one payer.
3. Do not show amount input for selected payer.
4. Set selected payer's `paidAmount = totalAmount`.
5. Set all other members' `paidAmount = 0`.
6. Wait for all members to submit used amounts.
7. Validate sum of shares equals total amount.
8. Calculate balances.

Example:

Total: 195000  
A paid all.

| User | Share | Paid | Balance |
|---|---:|---:|---:|
| A | 65000 | 195000 | -130000 |
| B | 50000 | 0 | 50000 |
| C | 80000 | 0 | 80000 |

Settlement suggestions:

| From | To | Amount |
|---|---|---:|
| C | A | 80000 |
| B | A | 50000 |

---

### 11.5. Unequal Split + Multiple Payers

Meaning:

Each member used a different amount and multiple members paid upfront.

UI behavior:

1. Show active member list as checkboxes.
2. User selects at least two payers.
3. For each selected payer, show paid amount textbox.
4. Validate total paid amount equals total amount.
5. Wait for all members to submit used amounts.
6. Validate total share amount equals total amount.
7. Calculate balances.

Example:

Total: 300000  
Used amounts:

| User | Share |
|---|---:|
| A | 65000 |
| B | 50000 |
| C | 80000 |
| D | 105000 |

Paid amounts:

| User | Paid |
|---|---:|
| A | 200000 |
| C | 100000 |

Expected balances:

| User | Share | Paid | Balance |
|---|---:|---:|---:|
| A | 65000 | 200000 | -135000 |
| B | 50000 | 0 | 50000 |
| C | 80000 | 100000 | -20000 |
| D | 105000 | 0 | 105000 |

Settlement suggestions:

| From | To | Amount |
|---|---|---:|
| D | A | 105000 |
| B | A | 30000 |
| B | C | 20000 |

---

## 12. Settlement Suggestion Algorithm

After a group transaction is `posted`, calculate settlement suggestions from balances.

Rules:

- Members with positive balance are debtors.
- Members with negative balance are creditors.
- The largest debtor pays the largest creditor.
- After every payment suggestion, update both balances.
- Continue until all balances reach zero.

Algorithm:

1. Create a list of debtors where `balance > 0`.
2. Create a list of creditors where `balance < 0`.
3. Sort debtors by balance descending.
4. Sort creditors by balance ascending, meaning most negative first.
5. Let the current debtor pay the current creditor.
6. Payment amount is:

```text
min(debtor.balance, abs(creditor.balance))
```

7. Subtract amount from debtor balance.
8. Add amount to creditor balance.
9. If debtor reaches 0, move to next debtor.
10. If creditor reaches 0, move to next creditor.
11. Continue until both lists are exhausted.

Do not create settlement suggestions if every balance is 0.

---

## 13. Debt Settlement Confirmation

Each user must have a personal repayment area.

### 13.1. User Needs to Pay

Show rows where:

```text
fromUserId == currentUserId
```

Action button:

```text
Đã trả nợ
```

### 13.2. Other Users Need to Pay Current User

Show rows where:

```text
toUserId == currentUserId
```

Action button:

```text
Xác nhận đã nhận
```

### 13.3. Status Flow

Allowed status flow:

```text
pending -> payer_marked_paid -> completed
```

Dispute status can exist as:

```text
disputed
```

Rules:

- Payer can mark paid only when status is `pending`.
- Receiver can confirm only when status is `payer_marked_paid`.
- Receiver confirmation button must be disabled or hidden before payer marks paid.
- Other group members can only view status.
- Payer cannot confirm on behalf of receiver.
- Receiver cannot mark paid on behalf of payer.

---

## 14. Leave Group Rules

A user can leave a group only if all conditions are true:

1. Their balance is 0.
2. They are not involved in any settlement with status `pending`.
3. They are not involved in any settlement with status `payer_marked_paid`.
4. If they are owner, another owner must exist or ownership must be transferred first.

If the user has unresolved debt or unresolved receivables, block leaving the group.

Show this message to the user:

```text
Bạn ơi! bạn còn vài khoản thu chi chưa được xử lý kìa.
```

Notify other active members:

```text
Có thành viên trong nhóm cố gắng rời khỏi nhóm khi chưa xử lý xong các khoản chi. Hãy cẩn thận.
```

Rules:

- Do not hard-delete the member.
- If leaving is valid, set `group_members.status = left`.
- Keep historical group transactions visible to remaining members.
- If user repeatedly tries to leave with unresolved debt, keep blocking and show the same warning.

---

## 15. Group Transaction Image Rules

Group transaction image behavior should follow personal transaction image behavior as much as possible.

Rules:

- At most one image per group transaction in this phase.
- Image is optional but recommended.
- Compress the image before upload.
- Store image in a private Supabase Storage bucket.
- Store only `imagePath` in database.
- Do not store public URL as source of truth.
- Generate signed URL for display.
- If image upload fails:
  - Keep the transaction.
  - Set `imageUploadStatus = failed`.
  - Allow retry.

Recommended upload flow:

1. Create transaction row first.
2. Use transaction ID to build stable storage path.
3. Upload image.
4. If upload succeeds, update `imagePath` and `imageUploadStatus = uploaded`.
5. If upload fails, keep transaction and set `imageUploadStatus = failed`.

---

## 16. Comments and Edit Permissions

### 16.1. Comments

Rules:

- All active group members can comment under a group transaction.
- Comments are only for discussion and verification.
- Comments do not automatically change transaction data.
- Members may use comments to confirm transfers, ask questions, or resolve disputes.

Example comments:

```text
Mình đã chuyển khoản rồi, Khánh kiểm tra giúp mình.
Bill này hình như chưa tính phần nước.
Mình không thấy giao dịch chuyển khoản, bạn gửi lại ảnh giúp mình.
```

### 16.2. Edit Permissions

Rules:

- Only the creator of a group transaction can edit or delete it.
- Other members can view and comment only.
- Other members cannot edit amount, payer, image, category, note, or split data.
- If the creator edits a transaction, recalculate:
  - Shares
  - Payers
  - Balances
  - Settlement suggestions

If a transaction already has completed settlement rows, warn before editing:

```text
Giao dịch này đã có khoản nợ được xác nhận. Nếu chỉnh sửa, hệ thống sẽ tính lại công nợ của nhóm. Bạn có chắc muốn tiếp tục không?
```

---

## 17. Screen Requirements

### 17.1. Group List Screen

Show groups the current user participates in.

Each group card should include:

- Group image.
- Group name.
- Total group spending.
- Member count.
- Current user's debt status.
- Badge if there are unresolved settlements.

---

### 17.2. Create Group Screen

Fields:

- Group name.
- Group avatar.
- Optional group type.
- Optional description.
- Invite members.

---

### 17.3. Group Detail Screen

Tabs or sections:

- Overview
- Transactions
- Members
- Ai nợ ai
- Comments or activity

---

### 17.4. Add Group Transaction Screen

Fields:

- Image
- Caption/note
- Total amount
- Category
- Split mode
- Payment mode
- Payer selection
- Payer amount input if multiple payers
- Confirmation dialog before posting

For unequal split, after posting, show pending status until all members submit used amounts.

---

### 17.5. Member Amount Input Screen

Required for unequal split.

This screen allows each active member to enter their used amount.

Rules:

- Each active member can submit their own amount.
- Amount must be greater than or equal to 0.
- After submitting, set `inputStatus = submitted`.
- If total submitted shares do not match total transaction amount, show mismatch state.

---

### 17.6. Debt Settlement Screen

Must show:

- Balance summary table.
- Settlement suggestion list.
- Current user's "Bạn cần trả" section.
- Current user's "Người khác cần trả cho bạn" section.
- Button `Đã trả nợ`.
- Button `Xác nhận đã nhận`.
- Settlement status.

---

### 17.7. Group Transaction Detail Screen

Show:

- Image or receipt.
- Caption/note.
- Total amount.
- Category.
- Creator.
- Split mode.
- Payment mode.
- Payers.
- Shares.
- Balance result.
- Comments.
- Edit/delete buttons only if current user is the creator.

---

## 18. Supabase Database Requirements

Create a new migration for group feature tables.

Required tables:

```text
groups
group_members
group_transactions
group_transaction_payers
group_transaction_shares
group_settlement_suggestions
group_transaction_comments
```

Suggested additional tables if needed:

```text
group_invites
group_notifications
group_activities
```

### 18.1. Required Enums

Create enums if the project uses PostgreSQL enums:

```text
group_role: owner | admin | member
group_member_status: invited | active | declined | left | removed
group_status: active | archived
split_mode: equal | unequal
payment_mode: everyone_paid | single_payer | multiple_payers
split_status: draft | pending_member_amount_input | amount_mismatch | posted | cancelled
share_input_status: pending | submitted
settlement_status: pending | payer_marked_paid | completed | disputed
image_upload_status: pending | uploading | uploaded | failed
```

If the project avoids PostgreSQL enums, use text columns with check constraints.

### 18.2. RLS Requirements

Enable RLS on all group-related tables.

Policy requirements:

- Users can read groups where they are members.
- Users can read group members for groups they belong to.
- Users can read group transactions for groups they belong to.
- Users can create group transactions only in groups where they are active members.
- Users can edit/delete group transactions only if they are `created_by`.
- Active members can comment.
- Users can edit/delete their own comments.
- Only owner/admin can invite members.
- A user can mark a settlement paid only if `from_user_id = auth.uid()`.
- A user can confirm a settlement only if `to_user_id = auth.uid()` and status is `payer_marked_paid`.

For complex validation, prefer RPC or Edge Function to ensure atomic updates.

---

## 19. Technical Transaction Boundaries

Group transaction creation must be atomic as much as possible.

For equal split:

1. Validate form.
2. Create transaction.
3. Create payer rows.
4. Create share rows.
5. Calculate balances.
6. Create settlement suggestions if needed.
7. Upload image or set upload status.

For unequal split:

1. Validate form and payer data.
2. Create transaction with `pending_member_amount_input`.
3. Create payer rows.
4. Create pending share rows for all active members.
5. Notify all active members to enter used amount.
6. Do not calculate final balance until shares are complete and valid.
7. Once all shares are submitted and total matches:
   - Set transaction to `posted`.
   - Calculate balances.
   - Create settlement suggestions.
   - Notify members.

---

## 20. Required Unit Tests

Write tests for calculation logic.

### 20.1. Split Tests

Required cases:

1. Equal split without remainder.
2. Equal split with remainder.
3. Equal split + everyone paid.
4. Equal split + single payer.
5. Equal split + multiple payers.
6. Multiple payers total paid mismatch.
7. Unequal split + everyone paid.
8. Unequal split + single payer.
9. Unequal split + multiple payers.
10. Unequal split total share mismatch.
11. Unequal split with pending member input.
12. Zero used amount in unequal split.
13. No active members should fail validation.

### 20.2. Settlement Tests

Required cases:

1. No settlement if all balances are 0.
2. One debtor pays one creditor.
3. One debtor pays multiple creditors.
4. Multiple debtors pay one creditor.
5. Multiple debtors and multiple creditors.
6. Largest positive pays largest negative.
7. All balances become 0 after generated suggestions.
8. Total debt equals total credit before settlement.

### 20.3. Permission Tests

If possible, add tests for:

1. Only creator can edit transaction.
2. Non-creator cannot edit transaction.
3. Payer can mark paid.
4. Non-payer cannot mark paid.
5. Receiver can confirm only after payer marked paid.
6. User with unresolved balance cannot leave group.

---

## 21. Widget or Integration Tests

If the project already has widget tests, add tests for:

1. Split mode selector shows:
   - Chia đều
   - Chia không đều
2. Payment mode selector shows:
   - Mọi người đều trả
   - Một người trả
   - Nhiều người trả
3. Single payer mode shows member picker.
4. Multiple payer mode shows checkbox list and amount inputs.
5. Unequal split creates pending member amount flow.
6. Pressing `Đăng` shows confirmation dialog.
7. Pressing `Hủy` in confirmation dialog does not save.
8. Receiver confirmation button is disabled before payer marks paid.

---

## 22. User-Facing Vietnamese Text

Use these exact strings where applicable:

```text
Bạn đã chắc chắn chưa?
Vui lòng chọn người đã trả tiền.
Vui lòng chọn ít nhất 2 người đã trả tiền.
Vui lòng nhập số tiền đã trả cho từng thành viên.
Số tiền đã trả phải lớn hơn 0.
Tổng số tiền đã trả chưa khớp với tổng giá trị giao dịch.
Vui lòng nhập số tiền bạn đã sử dụng trong giao dịch này.
Vẫn còn thành viên chưa nhập số tiền đã sử dụng.
Tổng số tiền các thành viên nhập chưa khớp với tổng tiền giao dịch. Vui lòng kiểm tra và nhập lại.
Giao dịch nhóm đã được đăng thành công.
Bạn ơi! bạn còn vài khoản thu chi chưa được xử lý kìa.
Có thành viên trong nhóm cố gắng rời khỏi nhóm khi chưa xử lý xong các khoản chi. Hãy cẩn thận.
Không tìm thấy người dùng này.
Bạn chưa có bạn bè nào để mời.
Giao dịch này đã có khoản nợ được xác nhận. Nếu chỉnh sửa, hệ thống sẽ tính lại công nợ của nhóm. Bạn có chắc muốn tiếp tục không?
```

---

## 23. Implementation Order

## Current UX extensions

- Group tools now include owner/admin group settings with server-guarded edit
  and archive actions. Archiving is blocked while balances, pending expenses,
  or settlement disputes remain.
- Members can save one private payment QR image on their profile. A member of
  the same active group can open that QR from a settlement card; the storage
  object is not public and is protected by storage policies.
- The activity center now includes a personalized next-step card, an upcoming
  recurring-expense cue, a latest-transaction spotlight with quick reactions,
  and a deep link to comments/details.
- Monthly summary includes a contribution spotlight derived from existing
  member activity; it is a lightweight recognition cue, not a ranking or
  financial permission.

The migration `20260715030000_group_collaboration_and_payment_qr.sql` adds the
payment QR field, guarded group lifecycle RPCs, and private storage policies.
Migration `20260715030001_payment_qr_profile_privacy_hardening.sql` restricts
shared profile reads to active members only.

Implement in this order:

### Phase 1 — Foundation

1. Add database migration.
2. Add entities and models.
3. Add repository interfaces.
4. Add Supabase datasources.
5. Add domain services:
   - `GroupSplitCalculator`
   - `SettlementCalculator`
6. Add unit tests for calculators.

### Phase 2 — Core UI

1. Group List Screen.
2. Create Group Screen.
3. Group Detail Screen.
4. Invite member UI.
5. Add Group Transaction Screen.
6. Equal split flow.
7. Equal split tests.

### Phase 3 — Unequal Split

1. Unequal split pending transaction flow.
2. Member amount input screen.
3. Share validation logic.
4. Mismatch handling.
5. Notification or activity placeholder.
6. Unequal split tests.

### Phase 4 — Settlement

1. Balance summary table.
2. Settlement suggestions.
3. `Đã trả nợ` action.
4. `Xác nhận đã nhận` action.
5. Settlement status flow.
6. Settlement tests.

### Phase 5 — Community and Controls

1. Comments.
2. Creator-only edit/delete.
3. Leave group validation.
4. Group activity/notification placeholder.
5. Group statistics placeholder or basic summary.

---

## 24. Deliverable Requirements

## Current finance/community controls (2026-07-15)

- Groups have an immutable-safe base currency policy. New foreign-currency
  transactions keep the original amount and exchange rate, while the ledger,
  balances, budgets, and charts use the converted base amount.
- Recurring items can opt into server-side auto-posting. Posting is guarded by
  a unique `(recurring_transaction_id, scheduled_for)` key and runs in one
  transaction, so retries do not duplicate expenses.
- Public profiles expose description, type, statistics, and avatar separately.
  Avatar exposure is opt-in and only accepts a `public-group-avatars/` path;
  private group avatar paths are never returned by the public RPC.
- Administrative changes are recorded in `group_audit_logs`; only owner/admin
  roles can read the audit RPC.
- Group participation includes member polls and admin-created savings
  challenges with member contributions. A settled-balance badge is derived in
  the monthly summary when all member balances are zero.

Migrations for these controls are `20260715040000_group_finance_controls.sql`
and `20260715050000_group_polls_and_savings_challenges.sql`.

After implementation, report back with:

1. Summary of completed work.
2. Files created.
3. Files modified.
4. Migration file name.
5. How to run migration.
6. How to run the Flutter app in Android Studio.
7. Tests added.
8. Test results.
9. Any placeholders left.
10. Any environment variables or Supabase configuration still needed.

Run before final response:

```bash
flutter analyze
flutter test
```

If the full test suite cannot run, explain why and run the most relevant tests.

---

## 25. Acceptance Criteria

The implementation is acceptable only if:

1. Users can create groups.
2. Users can invite members without email invite.
3. Users can add group transactions with image support.
4. Users can choose equal or unequal split.
5. Users can choose one of three payment modes.
6. Equal split correctly generates shares.
7. Unequal split waits for all members to submit used amounts.
8. Unequal split validates total share amount equals total transaction amount.
9. Payer data validates total paid amount equals total transaction amount when required.
10. Balances use `balance = shareAmount - paidAmount`.
11. Settlement suggestions correctly reduce all balances to zero.
12. Users can mark paid and confirm received according to status rules.
13. Users cannot leave a group while unsettled balances exist.
14. Only transaction creator can edit/delete transaction.
15. Active members can comment.
16. Money is stored as integers.
17. Existing app features still work.
