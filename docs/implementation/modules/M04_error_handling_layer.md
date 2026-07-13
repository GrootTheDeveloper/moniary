# M04 — Error Handling Layer

## Goal
Thêm `AppException` class + error handling có hệ thống cho data layer repositories.

## Review Issues Handled
- #6: Repositories không có try/catch — raw Supabase errors lộ cho user
- #33: Duplicate session null checks trong mọi repository method

## Severity: 🟡 High
## Difficulty: Medium (~1-2 giờ)
## Dependencies: M02 (splash đã có error UI)

## Scope Lock
CHỈ sửa 3 files (1 new + 2 modify). KHÔNG sửa file khác.

## Files to Change

| # | File | Thay đổi |
|---|---|---|
| 1 | `lib/core/supabase/app_exception.dart` | **[NEW]** Tạo `AppException` class |
| 2 | `lib/features/transactions/data/repositories/transaction_repository.dart` | Thêm `_userId` helper, wrap methods trong try/catch |
| 3 | `lib/features/profile/data/profile_repository.dart` | Wrap methods, fix Vietnamese diacritics error msgs |

## Step-by-step Implementation

1. Tạo `lib/core/supabase/app_exception.dart`:
   ```dart
   class AppException implements Exception {
     final String message;
     final String? code;
     const AppException(this.message, {this.code});
     @override
     String toString() => message;
   }
   ```

2. Sửa `transaction_repository.dart`:
   - Thêm private getter:
     ```dart
     String get _userId {
       final uid = _client.auth.currentSession?.user.id;
       if (uid == null) throw const AppException('Bạn chưa đăng nhập.');
       return uid;
     }
     ```
   - Thay tất cả duplicate session null checks bằng `_userId`
   - Wrap MỌI public method trong:
     ```dart
     try { ... }
     on PostgrestException catch (e) { throw AppException('Mô tả lỗi cụ thể'); }
     catch (e) { throw AppException('Lỗi kết nối. Vui lòng thử lại.'); }
     ```
   - KHÔNG thay đổi method signatures, return types, hay business logic

3. Sửa `profile_repository.dart`:
   - Áp dụng pattern tương tự
   - Fix `'Ban chua dang nhap.'` → `'Bạn chưa đăng nhập.'`

4. Chạy build gate

## Acceptance Criteria
- [ ] `AppException` class tồn tại trong `core/supabase/`
- [ ] `transaction_repository.dart` không còn duplicate session checks
- [ ] Tất cả repository methods có try/catch
- [ ] Error messages là tiếng Việt có dấu
- [ ] `flutter analyze` + `flutter test` pass

## Test/Build Commands
```bash
flutter analyze
flutter test
```

## Risks
Medium. Cần cẩn thận không thay đổi return type hay method signature — chỉ wrap error.

## Dev Prompt
```
Bạn là Flutter engineer. Thêm error handling layer cho Moniary repositories:

BƯỚC 1: Tạo file MỚI lib/core/supabase/app_exception.dart:
- Class AppException implements Exception
- Fields: String message, String? code
- const constructor, override toString() => message

BƯỚC 2: Sửa lib/features/transactions/data/repositories/transaction_repository.dart:
- Thêm private getter `String get _userId` extract session check → throw AppException
- Thay tất cả duplicate session null checks bằng `_userId`
- Wrap MỌI public method trong try/catch
- KHÔNG thay đổi method signatures hay business logic

BƯỚC 3: Sửa lib/features/profile/data/profile_repository.dart:
- Áp dụng pattern tương tự
- Fix 'Ban chua dang nhap.' → 'Bạn chưa đăng nhập.'

Chạy: flutter analyze && flutter test
```

## Handoff Checklist
- [ ] Code changed (1 new file + 2 modified)
- [ ] `flutter analyze` pass
- [ ] `flutter test` pass
- [ ] Commit: `feat(M04): add AppException + error handling in repositories`
- [ ] Update `../handoff/current_status.md`
- [ ] Ghi issues mới (nếu có) vào `../handoff/issues_backlog.md`
