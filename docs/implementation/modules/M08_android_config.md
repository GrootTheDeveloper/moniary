# M08 — Android Config

## Goal
Fix Android build config cho release readiness: INTERNET permission, ProGuard, R8.

## Review Issues Handled
- #14: Không có ProGuard rules → release build không minify, dễ reverse engineer
- #15: Thiếu INTERNET permission trong main manifest
- #2: Debug signing cho release (TODO only — không tạo keystore)

## Severity: 🟡 High
## Difficulty: Medium (~45 phút)
## Dependencies: Không — độc lập

## Scope Lock
CHỈ sửa 3 files (1 new + 2 modify). KHÔNG sửa file khác.
**KHÔNG tạo release keystore** — đó là task DevOps riêng.

## Files to Change

| # | File | Thay đổi |
|---|---|---|
| 1 | `android/app/src/main/AndroidManifest.xml` | Thêm INTERNET permission |
| 2 | `android/app/build.gradle.kts` | Thêm minify + shrink + proguard config |
| 3 | `android/app/proguard-rules.pro` | **[NEW]** ProGuard rules cho Supabase + Flutter |

## Step-by-step Implementation

1. `AndroidManifest.xml`:
   - Thêm trước tag `<application>`:
     ```xml
     <uses-permission android:name="android.permission.INTERNET"/>
     ```

2. `build.gradle.kts` — trong `buildTypes { release { ... } }`:
   - Thêm `isMinifyEnabled = true`
   - Thêm `isShrinkResources = true`
   - Thêm `proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")`
   - Giữ nguyên comment TODO về release signing

3. Tạo `android/app/proguard-rules.pro`:
   ```
   -keepattributes Signature
   -keepattributes *Annotation*
   -keep class io.supabase.** { *; }
   -keep class com.google.gson.** { *; }
   -dontwarn io.flutter.embedding.**
   ```

4. Chạy `flutter build apk --release` để verify

## Acceptance Criteria
- [ ] INTERNET permission trong main manifest
- [ ] ProGuard enabled cho release build
- [ ] Release APK build thành công
- [ ] `flutter analyze` pass

## Test/Build Commands
```bash
flutter analyze
flutter build apk --release
```

## Risks
Medium. ProGuard rules có thể strip classes cần thiết — test release build kỹ.

## Dev Prompt
```
Bạn là Flutter engineer. Fix Android build config cho Moniary:

1. android/app/src/main/AndroidManifest.xml:
   - Thêm <uses-permission android:name="android.permission.INTERNET"/> TRƯỚC tag <application>

2. android/app/build.gradle.kts:
   - Trong buildTypes { release { ... } }:
     - Thêm isMinifyEnabled = true
     - Thêm isShrinkResources = true
     - Thêm proguardFiles(...)
   - GIỮ NGUYÊN comment TODO về signing

3. Tạo file MỚI android/app/proguard-rules.pro:
   - Keep rules cho Supabase, Gson, Flutter
   - -keepattributes Signature, *Annotation*

Chạy: flutter build apk --release
```

## Handoff Checklist
- [ ] Code changed (1 new file + 2 modified)
- [ ] `flutter analyze` pass
- [ ] `flutter build apk --release` pass
- [ ] Commit: `chore(M08): add INTERNET permission + ProGuard + R8 config`
- [ ] Update `../handoff/current_status.md`
- [ ] Ghi issues mới (nếu có) vào `../handoff/issues_backlog.md`
