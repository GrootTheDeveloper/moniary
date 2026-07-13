# M02 — Auth & Splash Bugs

## Goal
Fix logic bugs trong auth flow — splash không kẹt khi network fail, auth không false-error.

## Review Issues Handled
- #3: Splash `_bootstrap()` không có try/catch → app kẹt vĩnh viễn nếu network fail
- #4: Auth controller catch `PostgrestException` rồi re-throw → mâu thuẫn với comment "Allow auth to succeed"

## Severity: 🔴 Critical
## Difficulty: Easy (~30 phút)
## Dependencies: Không — độc lập

## Scope Lock
CHỈ sửa 2 files dưới đây. KHÔNG sửa file khác.

## Files to Change

| # | File | Thay đổi |
|---|---|---|
| 1 | `lib/features/auth/application/auth_controller.dart` | Bỏ re-throw trong `on PostgrestException` catch, chỉ `debugPrint` |
| 2 | `lib/features/splash/presentation/splash_screen.dart` | Thêm try/catch + `_hasError` state + retry UI + fix Vietnamese diacritics |

## Step-by-step Implementation

1. Mở `auth_controller.dart`
2. Tìm `on PostgrestException catch (error)` trong method `signInAnonymously`
3. Thay `throw Exception(...)` bằng `debugPrint('initialize_user() failed (non-blocking): ${error.message}')`
4. Mở `splash_screen.dart`
5. Thêm `bool _hasError = false` trong State class
6. Wrap body của `_bootstrap()` (sau delay) trong try/catch
7. Trong catch: check `mounted`, rồi `setState(() => _hasError = true)`
8. Trong `build()`: nếu `_hasError`, hiện Column:
   - Icon error
   - Text `'Không thể kết nối'`
   - FilledButton `'Thử lại'` → `setState(() => _hasError = false)` rồi `_bootstrap()`
9. Fix strings thiếu dấu: `'Ghi chi tieu bang anh'` → `'Ghi chi tiêu bằng ảnh'`
10. Chạy build gate

## Acceptance Criteria
- [ ] Splash screen hiện retry button khi network fail
- [ ] Auth thành công kể cả khi `initialize_user` RPC fail
- [ ] Splash screen hiện Vietnamese có dấu
- [ ] `flutter analyze` pass

## Test/Build Commands
```bash
flutter analyze
flutter test
```

## Risks
Thấp. Splash thêm 1 state variable + UI. Auth chỉ bỏ 1 throw.

## Dev Prompt
```
Bạn là Flutter engineer. Sửa 2 bugs Critical trong auth flow Moniary:

BUG 1 — File: lib/features/auth/application/auth_controller.dart
- Tìm block `on PostgrestException catch (error)` trong method signInAnonymously
- Comment nói "Allow auth to succeed" nhưng code throw Exception → mâu thuẫn
- Sửa: thay `throw Exception(...)` bằng `debugPrint('initialize_user() failed (non-blocking): ${error.message}')`
- Giữ nguyên phần còn lại

BUG 2 — File: lib/features/splash/presentation/splash_screen.dart
- Method `_bootstrap()` không có try/catch → app kẹt nếu network fail
- Sửa:
  a. Thêm `bool _hasError = false` trong State class
  b. Wrap body của `_bootstrap()` (sau delay) trong try/catch
  c. Trong catch: check mounted, rồi setState(() => _hasError = true)
  d. Trong build(): nếu _hasError, hiện Column với icon error, text "Không thể kết nối", và FilledButton "Thử lại"
  e. Fix strings thiếu dấu: 'Ghi chi tieu bang anh' → 'Ghi chi tiêu bằng ảnh'

KHÔNG sửa file khác. Chạy: flutter analyze && flutter test
```

## Handoff Checklist
- [ ] Code changed
- [ ] `flutter analyze` pass
- [ ] `flutter test` pass
- [ ] Commit: `fix(M02): add splash error handling + fix auth controller re-throw`
- [ ] Update `../handoff/current_status.md`
- [ ] Ghi issues mới (nếu có) vào `../handoff/issues_backlog.md`
