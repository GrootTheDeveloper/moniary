# M11 — Router Hardening

## Goal
Router không crash khi deep link, Material widgets hiện tiếng Việt.

## Review Issues Handled
- #24: Thiếu localization delegates → DatePicker hiện tiếng Anh
- #25: GoRouter không có `errorBuilder` → crash khi unknown route
- #19: `state.extra as Type` unsafe cast → crash khi extra null

## Severity: 🟠 Medium
## Difficulty: Medium (~45 phút)
## Dependencies: Không — độc lập

## Scope Lock
CHỈ sửa 2 files dưới đây. KHÔNG sửa file khác.

## Files to Change

| # | File | Thay đổi |
|---|---|---|
| 1 | `lib/app/app.dart` | Thêm `localizationsDelegates`, `supportedLocales`, `locale` |
| 2 | `lib/app/app_router.dart` | Thêm `errorBuilder`, safe-cast `state.extra` |

## Step-by-step Implementation

1. `app.dart` — trong `MaterialApp.router(...)`:
   ```dart
   localizationsDelegates: const [
     GlobalMaterialLocalizations.delegate,
     GlobalWidgetsLocalizations.delegate,
     GlobalCupertinoLocalizations.delegate,
   ],
   supportedLocales: const [Locale('vi', 'VN')],
   locale: const Locale('vi', 'VN'),
   ```
   - Thêm import: `import 'package:flutter_localizations/flutter_localizations.dart';`
   - Note: `flutter_localizations` là part of Flutter SDK, chỉ cần thêm vào `pubspec.yaml`:
     ```yaml
     dependencies:
       flutter_localizations:
         sdk: flutter
     ```

2. `app_router.dart`:
   - Thêm `errorBuilder` cho GoRouter:
     ```dart
     errorBuilder: (context, state) => Scaffold(
       body: Center(
         child: Column(
           mainAxisSize: MainAxisSize.min,
           children: [
             const Text('Trang không tồn tại'),
             FilledButton(
               onPressed: () => context.go('/'),
               child: const Text('Quay về trang chính'),
             ),
           ],
         ),
       ),
     ),
     ```
   - Với MỖI route dùng `state.extra as SomeType`:
     - Đổi thành `state.extra as SomeType?`
     - Nếu null: redirect về home hoặc hiện error

3. Chạy build gate

## Acceptance Criteria
- [ ] DatePicker hiện tiếng Việt
- [ ] Unknown routes hiện error page thay vì crash
- [ ] Navigate trực tiếp tới route cần `extra` → không crash
- [ ] `flutter analyze` pass

## Test/Build Commands
```bash
flutter analyze
flutter test
```

## Risks
Medium. Safe-cast cần fallback logic cho mỗi route — cần xem xét từng case.

## Dev Prompt
```
Bạn là Flutter engineer. Harden router trong Moniary:

1. lib/app/app.dart:
   - Thêm localizationsDelegates, supportedLocales, locale cho vi_VN
   - flutter_localizations là SDK package, thêm vào pubspec.yaml nếu chưa có

2. lib/app/app_router.dart:
   - Thêm errorBuilder: Scaffold "Trang không tồn tại" + nút quay về
   - Safe-cast state.extra: SomeType? thay vì SomeType, handle null

Chạy: flutter analyze
```

## Handoff Checklist
- [ ] Code changed
- [ ] `flutter analyze` pass
- [ ] `flutter test` pass
- [ ] Commit: `fix(M11): add localization delegates + router errorBuilder + safe extra casts`
- [ ] Update `handoff/current_status.md`
- [ ] Ghi issues mới (nếu có) vào `handoff/issues_backlog.md`
