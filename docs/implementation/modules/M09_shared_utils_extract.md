# M09 — Shared Utils Extract

## Goal
DRY code: extract duplicate `_money()` helper, fix SupabaseImage cross-feature import.

## Review Issues Handled
- #16: `_money()` function duplicate trong 6+ files
- #23: `supabase_image.dart` (shared) import từ `features/transactions/` → vi phạm architectural boundary

## Severity: 🟠 Medium
## Difficulty: Easy-Medium (~45 phút)
## Dependencies: Không — độc lập

## Scope Lock
CHỈ sửa files dưới đây. KHÔNG sửa file khác.

## Files to Change

| # | File | Thay đổi |
|---|---|---|
| 1 | `lib/shared/utils/currency_formatter.dart` | **[NEW]** Tạo `formatVnd()` |
| 2 | `lib/features/scanning/presentation/ocr_review_screen.dart` | Import `formatVnd`, xóa local `_money()` |
| 3 | `lib/features/groups/presentation/debt_summary_screen.dart` | Import `formatVnd`, xóa local `_money()` |
| 4 | `lib/features/groups/presentation/group_detail_screen.dart` | Import `formatVnd`, xóa local `_money()` |
| 5 | `lib/features/groups/presentation/group_expense_form_screen.dart` | Import `formatVnd`, xóa local `_money()` |
| 6 | `lib/features/transactions/presentation/detail/day_detail_screen.dart` | Import `formatVnd`, xóa local `_money()` |
| 7 | `lib/features/transactions/presentation/detail/transaction_detail_screen.dart` | Import `formatVnd`, xóa local `_money()` |
| 8 | `lib/shared/widgets/supabase_image.dart` | Move `signedUrlProvider` ra `lib/core/supabase/signed_url_provider.dart` |

## Step-by-step Implementation

1. Tạo `lib/shared/utils/currency_formatter.dart`:
   ```dart
   import 'package:intl/intl.dart';
   String formatVnd(num amount) {
     return NumberFormat.currency(locale: 'vi_VN', symbol: '₫', decimalDigits: 0).format(amount);
   }
   ```

2. Grep `_money` trong `lib/` → lấy danh sách files

3. Trong MỖI file: import `currency_formatter.dart`, thay `_money(x)` → `formatVnd(x)`, XÓA local `_money()`

4. Tạo `lib/core/supabase/signed_url_provider.dart`, move `signedUrlProvider` từ `supabase_image.dart`

5. Update import trong `supabase_image.dart`

6. Chạy build gate

## Acceptance Criteria
- [ ] `_money()` không còn duplicate — chỉ 1 `formatVnd()` trong shared
- [ ] `supabase_image.dart` không import từ `features/transactions/`
- [ ] `flutter analyze` + `flutter test` pass

## Test/Build Commands
```bash
grep -r "_money" lib/
flutter analyze
flutter test
```

## Risks
Thấp. Search & replace cơ bản. Cẩn thận function signature match.

## Dev Prompt
```
Bạn là Flutter engineer. Extract shared utilities trong Moniary:

TASK 1: Extract _money() → formatVnd()
1. Tạo file MỚI lib/shared/utils/currency_formatter.dart
2. Grep "_money" trong lib/ — tìm tất cả files có local _money()
3. Trong MỖI file: import currency_formatter.dart, thay _money(x) → formatVnd(x), XÓA local _money()

TASK 2: Fix architectural boundary
1. Trong supabase_image.dart, tìm import từ features/transactions/
2. Move signedUrlProvider ra lib/core/supabase/signed_url_provider.dart
3. Update import trong supabase_image.dart

Chạy: flutter analyze && flutter test
```

## Handoff Checklist
- [ ] Code changed (2 new files + 7 modified)
- [ ] `flutter analyze` pass
- [ ] `flutter test` pass
- [ ] Commit: `refactor(M09): extract formatVnd + move signedUrlProvider to core`
- [ ] Update `handoff/current_status.md`
- [ ] Ghi issues mới (nếu có) vào `handoff/issues_backlog.md`
