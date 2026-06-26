# M12 — Profile & Data Fixes

## Goal
Fix data integrity issues: upsert logic, owner check, Riverpod usage.

## Review Issues Handled
- #18: Profile repository dùng `.update()` thay vì `.upsert()` → fail nếu row chưa tồn tại
- #30: `needsSetup` check `displayName == 'guest'` — fragile assumption
- #31: Group owner check bằng `index == 0` thay vì so sánh ID
- #34: `ref.read()` trong `build()` thay vì `ref.watch()` → không reactive

## Severity: 🟠 Medium
## Difficulty: Easy (~30 phút)
## Dependencies: M04 (AppException)

## Scope Lock
CHỈ sửa 4 files dưới đây. KHÔNG sửa file khác.

## Files to Change

| # | File | Thay đổi |
|---|---|---|
| 1 | `lib/features/profile/data/profile_repository.dart` | `.update()` → `.upsert()` |
| 2 | `lib/features/profile/domain/user_profile.dart` | Thêm comment documenting 'guest' assumption |
| 3 | `lib/features/groups/presentation/group_detail_screen.dart` | `index == 0` → `member.id == group.ownerId` |
| 4 | `lib/features/profile/application/profile_setup_controller.dart` | `ref.read()` → `ref.watch()` trong `build()` |

## Step-by-step Implementation

1. `profile_repository.dart`:
   - Tìm method có `.update(...)` call
   - Đổi `.update(...)` thành `.upsert(...)`
   - Giữ nguyên data payload và query chain

2. `user_profile.dart`:
   - Tìm `needsSetup` getter/property
   - Thêm comment: `// Assumption: default displayName from Supabase trigger is 'guest'`

3. `group_detail_screen.dart`:
   - Tìm logic check owner bằng `index == 0`
   - Đổi thành `member.id == group.ownerId`

4. `profile_setup_controller.dart`:
   - Trong `build()` method
   - Tìm `ref.read(profileRepositoryProvider)`
   - Đổi thành `ref.watch(profileRepositoryProvider)`

5. Chạy build gate

## Acceptance Criteria
- [ ] `upsertProfile` dùng `.upsert()`
- [ ] Group owner check bằng ID, không bằng index
- [ ] Profile setup controller dùng `ref.watch` trong `build()`
- [ ] `flutter analyze` + `flutter test` pass

## Test/Build Commands
```bash
flutter analyze
flutter test
```

## Risks
Thấp. `.update()` → `.upsert()` cần test với Supabase thật để verify behavior.

## Dev Prompt
```
Bạn là Flutter engineer. Fix data integrity bugs trong Moniary:

1. profile_repository.dart: .update() → .upsert()
2. group_detail_screen.dart: index == 0 → member.id == group.ownerId
3. profile_setup_controller.dart: ref.read() → ref.watch() trong build()

Chạy: flutter analyze && flutter test
```

## Handoff Checklist
- [ ] Code changed
- [ ] `flutter analyze` pass
- [ ] `flutter test` pass
- [ ] Commit: `fix(M12): profile upsert + group owner check by ID + ref.watch in build`
- [ ] Update `handoff/current_status.md`
- [ ] Ghi issues mới (nếu có) vào `handoff/issues_backlog.md`
