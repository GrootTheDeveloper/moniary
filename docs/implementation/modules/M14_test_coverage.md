# M14 — Test Coverage

## Goal
Tăng test coverage từ 8 → 25+ test cases cho critical paths.

## Review Issues Handled
- #41: Test coverage rất thấp — chỉ có ~8 test cases

## Severity: 🟢 Low
## Difficulty: Hard (~2-3 giờ)
## Dependencies: M04 (AppException), M05 (transaction fixes)

## Scope Lock
CHỈ tạo 6 files TEST mới. KHÔNG sửa source code.

## Files to Create (ALL NEW)

| # | File | Nội dung |
|---|---|---|
| 1 | `test/core/supabase/app_exception_test.dart` | AppException toString, equality |
| 2 | `test/features/groups/debt_calculator_edge_cases_test.dart` | Empty list, single member, circular debts |
| 3 | `test/features/groups/group_expense_validation_full_test.dart` | < 2 members, missing payer, 0/negative amount |
| 4 | `test/features/scanning/scanning_controller_test.dart` | State transitions |
| 5 | `test/features/scanning/fast_api_ocr_service_test.dart` | Multipart upload, response mapping, API errors |
| 6 | `test/shared/utils/currency_formatter_test.dart` | formatVnd edge cases |

## Step-by-step Implementation

1. **`app_exception_test.dart`**:
   - `AppException('msg').toString()` == `'msg'`
   - `AppException('msg', code: 'ERR01').code` == `'ERR01'`

2. **`debt_calculator_edge_cases_test.dart`**:
   - `calculateBalances` với empty list → empty map
   - `calculateBalances` với 1 member (payer = participant) → balance 0
   - `simplifyDebts` với circular debts
   - `simplifyDebts` với balances near 0.01 threshold

3. **`group_expense_validation_full_test.dart`**:
   - validate < 2 members → error
   - validate amount = 0 → error
   - validate missing payer → error
   - validate no participants → error
   - validate duplicate participants → error
   - `createEqualSplits` với exactly divisible amount

4. **`scanning_controller_test.dart`**:
   - Initial state == `ScanningStatus.empty`
   - Sau `pickImage` → `imageReady`
   - Sau extract thành công → `success` với OcrResult
   - Sau extract fail → `failure` với error message

5. **`fast_api_ocr_service_test.dart`**:
   - Multipart image upload to `POST /extract`
   - Response mapping to `OcrResult`
   - HTTP and missing-image error handling

6. **`currency_formatter_test.dart`**:
   - `formatVnd(0)` → contains `'0'`
   - `formatVnd(125000)` → contains `'125.000'` hoặc `'125,000'`
   - `formatVnd(-50000)` → contains negative indicator

Chạy `flutter test` sau mỗi file.

## Acceptance Criteria
- [ ] 17+ new test cases thêm vào
- [ ] `flutter test` pass tất cả
- [ ] Debt calculator edge cases covered
- [ ] Validation edge cases covered
- [ ] ScanningController state machine tested

## Test/Build Commands
```bash
flutter test
flutter test --coverage  # optional
```

## Risks
Medium. Có thể phát hiện bugs mới khi viết tests — ghi vào `handoff/issues_backlog.md`.

## Dev Prompt
```
Bạn là Flutter engineer. Tăng test coverage cho Moniary:

Tạo 6 test files MỚI. Chạy flutter test sau mỗi file:

1. test/core/supabase/app_exception_test.dart — toString, code
2. test/features/groups/debt_calculator_edge_cases_test.dart — empty, single, circular
3. test/features/groups/group_expense_validation_full_test.dart — < 2 members, 0 amount, missing payer
4. test/features/scanning/scanning_controller_test.dart — state transitions
5. test/features/scanning/fast_api_ocr_service_test.dart — FastAPI contract checks
6. test/shared/utils/currency_formatter_test.dart — 0, positive, negative

Chạy: flutter test (ALL pass)
```

## Handoff Checklist
- [ ] 6 test files created
- [ ] `flutter test` pass (all tests)
- [ ] Commit: `test(M14): add 17+ unit tests for debt calc, validation, scanning, formatting`
- [ ] Update `handoff/current_status.md`
- [ ] Ghi issues mới (nếu có) vào `handoff/issues_backlog.md`
