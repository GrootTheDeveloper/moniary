# M03 — Image URL Fix

## Goal
Fix broken image display do dùng `getPublicUrl()` trên private Supabase Storage bucket.

## Review Issues Handled
- #5: `getPublicImageUrl()` gọi `getPublicUrl()` trên private bucket → URL không hoạt động

## Severity: 🔴 Critical
## Difficulty: Easy (~15 phút)
## Dependencies: Không — độc lập

## Scope Lock
CHỈ sửa 2 files dưới đây. KHÔNG sửa file khác.

## Files to Change

| # | File | Thay đổi |
|---|---|---|
| 1 | `lib/features/transactions/data/repositories/transaction_repository.dart` | Deprecate/remove `getPublicImageUrl()` |
| 2 | `lib/shared/widgets/supabase_image.dart` | Verify dùng signed URL, không dùng public URL |

## Step-by-step Implementation

1. Mở `transaction_repository.dart`
2. Tìm method `getPublicImageUrl`
3. Grep codebase: `grep -r "getPublicImageUrl" lib/` — liệt kê callers
4. Nếu có callers → thay bằng `getSignedImageUrl` (đã có sẵn trong cùng file)
5. Nếu không còn callers → xóa method hoặc đánh `@Deprecated`
6. Mở `supabase_image.dart`
7. Verify đang dùng `signedUrlProvider` (signed URL)
8. Nếu dùng public URL → sửa sang signed URL
9. Chạy build gate

## Acceptance Criteria
- [ ] Không còn call nào tới `getPublicImageUrl` trong codebase
- [ ] `supabase_image.dart` dùng signed URL
- [ ] `flutter analyze` pass

## Test/Build Commands
```bash
grep -r "getPublicImageUrl" lib/
flutter analyze
flutter test
```

## Risks
Thấp. Kiểm tra kỹ signed URL đang hoạt động trước khi xóa public URL.

## Dev Prompt
```
Bạn là Flutter engineer. Fix image display bug trong Moniary:

VẤN ĐỀ: transaction_repository.dart có method `getPublicImageUrl()` gọi `getPublicUrl()` trên PRIVATE Supabase Storage bucket → URL trả về không hoạt động.

BƯỚC 1: Grep toàn bộ lib/ cho "getPublicImageUrl" — liệt kê tất cả callers
BƯỚC 2: Thay tất cả callers bằng `getSignedImageUrl()` (đã có sẵn trong cùng file)
BƯỚC 3: Xóa method `getPublicImageUrl()` hoặc đánh @Deprecated
BƯỚC 4: Verify `lib/shared/widgets/supabase_image.dart` dùng signed URL provider
BƯỚC 5: Chạy flutter analyze && flutter test

KHÔNG sửa logic khác. Chỉ thay public → signed URL.
```

## Handoff Checklist
- [ ] Code changed
- [ ] `flutter analyze` pass
- [ ] `flutter test` pass
- [ ] Commit: `fix(M03): replace getPublicImageUrl with getSignedImageUrl`
- [ ] Update `handoff/current_status.md`
- [ ] Ghi issues mới (nếu có) vào `handoff/issues_backlog.md`
