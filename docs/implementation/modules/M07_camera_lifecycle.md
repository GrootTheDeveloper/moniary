# M07 — Camera Lifecycle

## Goal
Camera release đúng khi app vào background, tránh battery drain và camera lock.

## Review Issues Handled
- #13: Camera screen không có `WidgetsBindingObserver` → camera không release khi background

## Severity: 🟡 High
## Difficulty: Medium (~30 phút)
## Dependencies: Không — độc lập

## Scope Lock
CHỈ sửa 1 file dưới đây. KHÔNG sửa file khác.

## Files to Change

| # | File | Thay đổi |
|---|---|---|
| 1 | `lib/features/transactions/presentation/camera/camera_screen.dart` | Thêm `WidgetsBindingObserver`, handle lifecycle |

## Step-by-step Implementation

1. Mở `camera_screen.dart`
2. Thêm `with WidgetsBindingObserver` vào State class
3. Trong `initState()`: `WidgetsBinding.instance.addObserver(this)`
4. Trong `dispose()`: `WidgetsBinding.instance.removeObserver(this)`
5. Override `didChangeAppLifecycleState`:
   ```dart
   @override
   void didChangeAppLifecycleState(AppLifecycleState state) {
     if (state == AppLifecycleState.inactive) {
       _controller?.dispose();
       _controller = null;
     } else if (state == AppLifecycleState.resumed) {
       _initializeCamera(); // gọi lại init method hiện có
     }
   }
   ```
6. Thêm null check `if (_controller == null) return;` trước mọi camera operation
7. Chạy build gate

## Acceptance Criteria
- [ ] Camera release khi app vào background
- [ ] Camera re-init khi app quay lại foreground
- [ ] Không crash nếu controller null
- [ ] `flutter analyze` pass

## Test/Build Commands
```bash
flutter analyze
flutter test
```

## Risks
Medium. Cần test trên device thật để verify lifecycle behavior.

## Dev Prompt
```
Bạn là Flutter engineer. Fix camera lifecycle trong Moniary:

File: lib/features/transactions/presentation/camera/camera_screen.dart

VẤN ĐỀ: Camera không release khi app vào background → battery drain, camera lock.

SỬA:
1. State class thêm `with WidgetsBindingObserver`
2. initState(): WidgetsBinding.instance.addObserver(this)
3. dispose(): WidgetsBinding.instance.removeObserver(this)
4. Override didChangeAppLifecycleState:
   - AppLifecycleState.inactive → _controller?.dispose(); _controller = null
   - AppLifecycleState.resumed → _initializeCamera()
5. Thêm null check trước mọi camera operation

KHÔNG sửa UI layout hay navigation. Chỉ lifecycle. Chạy: flutter analyze
```

## Handoff Checklist
- [ ] Code changed
- [ ] `flutter analyze` pass
- [ ] `flutter test` pass
- [ ] Commit: `fix(M07): add camera lifecycle handling with WidgetsBindingObserver`
- [ ] Update `handoff/current_status.md`
- [ ] Ghi issues mới (nếu có) vào `handoff/issues_backlog.md`
