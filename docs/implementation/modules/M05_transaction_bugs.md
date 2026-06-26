# M05 — Transaction Bugs

## Goal
Fix bugs trong transaction CRUD flow: double-throw, state-in-build, delete không cleanup image.

## Review Issues Handled
- #7: Composer controller `throw state.error!` sau `AsyncValue.guard()` → double-throw
- #17: `build()` method có side effects (set state variables) → infinite rebuild risk
- #20: `deleteTransaction` không xóa image từ Storage → orphaned files

## Severity: 🟡 High
## Difficulty: Medium (~1 giờ)
## Dependencies: M03 (image URL), M04 (AppException)

## Scope Lock
CHỈ sửa 3 files dưới đây. KHÔNG sửa file khác.

## Files to Change

| # | File | Thay đổi |
|---|---|---|
| 1 | `lib/features/transactions/application/composer/transaction_composer_controller.dart` | Bỏ `if (state.hasError) throw state.error!` |
| 2 | `lib/features/transactions/presentation/form/transaction_form_sheet.dart` | Move state mutation từ `build()` sang `initState()` |
| 3 | `lib/features/transactions/data/repositories/transaction_repository.dart` | Trong `deleteTransaction`, thêm storage image cleanup |

## Step-by-step Implementation

1. Sửa `transaction_composer_controller.dart`:
   - Tìm `if (state.hasError) throw state.error!` sau `AsyncValue.guard()`
   - XÓA dòng đó — error đã nằm trong `AsyncValue` state, UI check `state.hasError`

2. Sửa `transaction_form_sheet.dart`:
   - Tìm `walletAsync.whenData(...)` và `categoryAsync.whenData(...)` trong `build()`
   - Move logic set `_selectedWalletId` / `_selectedCategoryId` sang `initState()` dùng `WidgetsBinding.instance.addPostFrameCallback` hoặc `didChangeDependencies`
   - Đảm bảo default wallet/category vẫn được set khi data load lần đầu

3. Sửa `transaction_repository.dart`:
   - Trong `deleteTransaction()`:
     - Trước khi delete record, fetch transaction để lấy `imagePath`
     - Nếu `imagePath != null`:
       ```dart
       try {
         await _client.storage.from('transaction-images').remove([imagePath]);
       } catch (_) {
         // Best effort — storage cleanup failure không block deletion
       }
       ```
   - Sau đó delete record bình thường

4. Chạy build gate

## Acceptance Criteria
- [ ] Không còn `throw state.error!` sau `AsyncValue.guard()`
- [ ] Không còn state mutation trong `build()` method
- [ ] Delete transaction xóa luôn image từ Storage (best effort)
- [ ] `flutter analyze` + `flutter test` pass

## Test/Build Commands
```bash
flutter analyze
flutter test
```

## Risks
Medium. State-in-build fix cần test kỹ trên UI để đảm bảo wallet/category default selection vẫn hoạt động.

## Dev Prompt
```
Bạn là Flutter engineer. Fix 3 transaction bugs trong Moniary:

BUG 1 — File: lib/features/transactions/application/composer/transaction_composer_controller.dart
- Tìm dòng `if (state.hasError) throw state.error!` (sau AsyncValue.guard)
- XÓA dòng đó. Error đã nằm trong AsyncValue state, UI check state.hasError.

BUG 2 — File: lib/features/transactions/presentation/form/transaction_form_sheet.dart
- Trong build(), có đoạn walletAsync.whenData(...) set _selectedWalletId — side effect trong build
- Move logic sang initState() dùng addPostFrameCallback hoặc didChangeDependencies

BUG 3 — File: lib/features/transactions/data/repositories/transaction_repository.dart
- Trong deleteTransaction():
  a. Fetch transaction để lấy imagePath
  b. Nếu imagePath != null, gọi storage.remove([imagePath]) trong try/catch riêng
  c. Storage cleanup failure KHÔNG block transaction deletion

Chạy: flutter analyze && flutter test
```

## Handoff Checklist
- [ ] Code changed
- [ ] `flutter analyze` pass
- [ ] `flutter test` pass
- [ ] Commit: `fix(M05): fix composer double-throw + state-in-build + delete image cleanup`
- [ ] Update `handoff/current_status.md`
- [ ] Ghi issues mới (nếu có) vào `handoff/issues_backlog.md`
