# M06 — UI Dead States

## Goal
Fix dead buttons, Vietnamese diacritics thiếu dấu, hardcoded day label.

## Review Issues Handled
- #8: 3 auth buttons (Google/Apple/Email) không có onTap — dead UI
- #11: Multiple strings thiếu dấu tiếng Việt
- #28: `'Hôm nay'` hardcoded cho mọi ngày trong day detail

## Severity: 🟡 High
## Difficulty: Easy (~30 phút)
## Dependencies: Không — hoàn toàn độc lập

## Scope Lock
CHỈ sửa files dưới đây. KHÔNG sửa file khác.

## Files to Change

| # | File | Thay đổi |
|---|---|---|
| 1 | `lib/features/auth/presentation/login_screen.dart` | Wrap dead buttons `Opacity(0.5)` + label `"(Sắp có)"` |
| 2 | `lib/features/auth/application/auth_controller.dart` | Fix `'Dang nhap thanh cong...'` → dấu |
| 3 | `lib/features/profile/data/profile_repository.dart` | Fix `'Ban chua dang nhap.'` → dấu (nếu chưa fix ở M04) |
| 4 | `lib/features/transactions/presentation/detail/transaction_detail_screen.dart` | Fix `'Sua'` → `'Sửa'` |
| 5 | `lib/features/transactions/presentation/form/create_transaction_sheet.dart` | Fix `'Them giao dich'`, `'So tien'` → dấu |
| 6 | `lib/features/transactions/presentation/detail/day_detail_screen.dart` | `'Hôm nay'` hardcoded → check `isToday` |
| 7 | `android/app/src/main/kotlin/com/moniary/moniary/MainActivity.kt` | English chooser titles → Vietnamese |

## Step-by-step Implementation

1. `login_screen.dart`:
   - Tìm 3 `_AuthButton` (Google, Apple, Email)
   - Wrap mỗi cái trong `Opacity(opacity: 0.5, child: ...)`
   - Thêm `' (Sắp có)'` vào cuối label text

2. Grep `lib/` cho strings thiếu dấu, sửa từng cái:
   - `'Dang nhap thanh cong'` → `'Đăng nhập thành công'`
   - `'Ban chua dang nhap.'` → `'Bạn chưa đăng nhập.'`
   - `'Sua'` → `'Sửa'`
   - `'Them giao dich'` → `'Thêm giao dịch'`
   - `'So tien'` → `'Số tiền'`

3. `day_detail_screen.dart`:
   - Tìm `'Hôm nay'` hardcoded
   - Thay bằng: `date == today ? 'Hôm nay' : DateFormat('EEEE, d/M', 'vi_VN').format(date)`

4. `MainActivity.kt`:
   - `"Open exported file"` → `"Mở file đã xuất"`
   - `"Share exported file"` → `"Chia sẻ file"`

5. Chạy build gate

## Acceptance Criteria
- [ ] 3 auth buttons mờ + label "(Sắp có)"
- [ ] Tất cả strings tiếng Việt có dấu
- [ ] Day detail hiện đúng tên ngày, không hardcode "Hôm nay"
- [ ] Kotlin chooser titles tiếng Việt
- [ ] `flutter analyze` pass

## Test/Build Commands
```bash
flutter analyze
flutter test
```

## Risks
Thấp. Chỉ sửa text/UI, không ảnh hưởng logic.

## Dev Prompt
```
Bạn là Flutter engineer. Fix UI dead states và Vietnamese text trong Moniary:

1. lib/features/auth/presentation/login_screen.dart:
   - 3 _AuthButton (Google, Apple, Email) là Container không có onTap — dead UI
   - Wrap mỗi button trong Opacity(opacity: 0.5)
   - Thêm ' (Sắp có)' vào cuối label text

2. Fix Vietnamese diacritics (tìm exact string, thay thế):
   - transaction_detail_screen.dart: 'Sua' → 'Sửa'
   - create_transaction_sheet.dart: fix TẤT CẢ strings thiếu dấu
   - profile_repository.dart: 'Ban chua dang nhap.' → 'Bạn chưa đăng nhập.' (nếu chưa fix)

3. day_detail_screen.dart: 'Hôm nay' hardcoded → check isToday

4. MainActivity.kt: "Open exported file" → "Mở file đã xuất"

KHÔNG sửa logic. Chỉ text/UI. Chạy: flutter analyze
```

## Handoff Checklist
- [ ] Code changed
- [ ] `flutter analyze` pass
- [ ] `flutter test` pass
- [ ] Commit: `fix(M06): fix dead auth buttons + Vietnamese diacritics + day label`
- [ ] Update `../handoff/current_status.md`
- [ ] Ghi issues mới (nếu có) vào `../handoff/issues_backlog.md`
