# M13 — Lint & Models Polish

## Goal
Nâng code quality baseline: thêm lint rules, document theme colors, timezone.

## Review Issues Handled
- #35: Global `cameras` variable trong `main.dart`
- #38: Hardcoded timezone `'Asia/Ho_Chi_Minh'`
- #39: Theme hardcoded colors trong textTheme
- #40: Missing lint rules (`avoid_print`, `unawaited_futures`, etc.)

## Severity: 🟢 Low
## Difficulty: Easy (~30 phút)
## Dependencies: Không — độc lập

## Scope Lock
CHỈ sửa 4 files dưới đây. KHÔNG sửa file khác.

## Files to Change

| # | File | Thay đổi |
|---|---|---|
| 1 | `analysis_options.yaml` | Thêm lint rules |
| 2 | `lib/app/app_theme.dart` | Document hardcoded colors |
| 3 | `lib/features/profile/presentation/profile_setup_screen.dart` | Thêm TODO comment cho timezone |
| 4 | `lib/main.dart` | Document global `cameras` |

## Step-by-step Implementation

1. `analysis_options.yaml` — thêm rules:
   ```yaml
   linter:
     rules:
       - avoid_print
       - unawaited_futures
       - cancel_subscriptions
       - close_sinks
   ```
   Chạy `flutter analyze`, fix bất kỳ warning mới nào TRONG SCOPE files hiện tại.

2. `app_theme.dart`:
   - Tìm `bodyLarge` color: `Color(0xFFBECCD9)`
   - Thêm comment: `// Custom onSurfaceVariant — design token`
   - Tìm `bodyMedium` color: `Color(0xFF9CB0C2)`
   - Thêm comment tương tự
   - Không cần đổi giá trị nếu design intentional

3. `profile_setup_screen.dart`:
   - Tìm `'Asia/Ho_Chi_Minh'` hardcoded
   - Thêm comment: `// TODO: detect timezone from device`

4. `main.dart`:
   - Tìm global `cameras` variable
   - Thêm comment: `// Global camera list — initialized once at app start. Low priority refactor.`

5. Chạy build gate

## Acceptance Criteria
- [ ] New lint rules active
- [ ] `flutter analyze` pass (0 warnings từ new rules)
- [ ] Theme colors documented
- [ ] Timezone has TODO comment
- [ ] `cameras` documented

## Test/Build Commands
```bash
flutter analyze
flutter test
```

## Risks
Thấp. Thêm lint rules có thể surface warnings ở files khác — chỉ fix trong scope 4 files này.

## Dev Prompt
```
Bạn là Flutter engineer. Polish code quality trong Moniary:

1. analysis_options.yaml: thêm avoid_print, unawaited_futures, cancel_subscriptions, close_sinks
2. app_theme.dart: document hardcoded colors với comments
3. profile_setup_screen.dart: timezone TODO comment
4. main.dart: document global cameras

Chạy: flutter analyze (0 errors, 0 warnings)
```

## Handoff Checklist
- [ ] Code changed
- [ ] `flutter analyze` pass (0 warnings)
- [ ] `flutter test` pass
- [ ] Commit: `chore(M13): add lint rules + document theme colors + timezone TODO`
- [ ] Update `../handoff/current_status.md`
- [ ] Ghi issues mới (nếu có) vào `../handoff/issues_backlog.md`
