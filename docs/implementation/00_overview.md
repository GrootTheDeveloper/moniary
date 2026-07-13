# Moniary — Project Overview

**Archive notice (2026-07-10)**: This is the May 2026 M01-M14 stabilization-plan snapshot, not the current product overview or roadmap. Use `docs/agent-context/` and current source for system facts.

## Project
- **Tên**: Moniary — ứng dụng quản lý tài chính cá nhân trên mobile.
- **Platform**: Flutter (Dart)
- **Min SDK**: Android 23 (6.0)

## Tech Stack
| Layer | Công nghệ |
|---|---|
| Framework | Flutter 3.x |
| State Management | Riverpod 3.x (`AsyncNotifier`, `NotifierProvider`) |
| Routing | GoRouter 17.x |
| Backend | Supabase (Auth, Database, Storage) |
| Architecture | Clean Architecture — feature-first |

## Cấu trúc thư mục chính
```
lib/
  app/            → app.dart, app_router.dart, app_theme.dart
  core/           → constants, preferences, supabase client
  shared/         → widgets dùng chung (aurora_background, supabase_image, ...)
  features/
    auth/         → đăng nhập ẩn danh
    calendar/     → lịch tháng, filter
    categories/   → quản lý danh mục
    groups/       → chi tiêu nhóm (post-MVP)
    onboarding/   → màn hình giới thiệu
    profile/      → setup profile, settings
    scanning/     → OCR hóa đơn (post-MVP)
    settings/     → cài đặt, xuất CSV, xóa tài khoản
    splash/       → splash screen
    transactions/ → CRUD giao dịch, camera, form
    wallets/      → quản lý ví
```

Mỗi feature có 4 layer:
```
feature/
  application/   → controllers (Riverpod Notifier)
  data/          → repositories (Supabase calls)
  domain/        → models, entities
  presentation/  → screens, widgets
```

## Mục tiêu hiện tại
Fix **42 issues** từ code review, chia thành **14 module**, **4 phase** (Critical → High → Medium → Low).

## Nguyên tắc cốt lõi
1. **KHÔNG** rewrite app hay đổi architecture.
2. **KHÔNG** thêm package mới trừ khi module yêu cầu rõ ràng.
3. Mỗi module chạm **2-5 files**, build được sau khi xong.
4. Ưu tiên: Critical → High → Medium → Low.

## Tài liệu liên quan
- `01_rules.md` — quy tắc dev chi tiết
- `02_roadmap.md` — bảng roadmap + dependency
- `03_module_index.md` — danh sách 14 module
- `modules/Mxx_*.md` — chi tiết từng module
- `handoff/current_status.md` — trạng thái hiện tại
- `handoff/issues_backlog.md` — issues phát hiện thêm
- `handoff/decisions.md` — quyết định kỹ thuật đã chốt
