# M01 — Compile Fixes

## Status: ✅ COMPLETED — No code changes needed

> **Cả 2 issues trong module này đều INVALIDATED.**
> Spec được viết dựa trên API versions cũ. Code hiện tại đã đúng.
> Xem quyết định D07 trong `../handoff/decisions.md`.

## Review Issues — INVALIDATED

### ~~#1: ScanningController extends Notifier~~ ❌ Invalid
- **Spec đề xuất**: Đổi `Notifier` → `AutoDisposeNotifier`
- **Thực tế**: Project dùng **Riverpod 3.2.1**. Từ Riverpod 3.0+, `AutoDisposeNotifier` **không còn tồn tại**. Auto-dispose được xử lý nội bộ tự động. `extends Notifier<T>` là **đúng chuẩn Riverpod 3**.
- **Nếu ép đổi**: Gây compile error `extends_non_class`.

### ~~#12: DropdownButtonFormField dùng initialValue~~ ❌ Invalid
- **Spec đề xuất**: Đổi `initialValue:` → `value:`
- **Thực tế**: Project dùng **Flutter 3.41.9**. Từ Flutter ~3.33+, `value` đã **deprecated**, Flutter khuyến nghị dùng `initialValue`. Code hiện tại dùng `initialValue:` là **đúng chuẩn Flutter mới nhất**.
- **Nếu ép đổi**: `flutter analyze` báo deprecation warning → fail build gate.

## Verification
```
flutter analyze → No issues found! ✅
flutter test   → Pass 100%          ✅
```

## Lesson Learned
Spec review cần verify API compatibility với **actual package versions** trong `pubspec.lock` trước khi áp dụng. Không assume API dựa trên docs cũ.
