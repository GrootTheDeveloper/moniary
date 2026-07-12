# Module Index

**Archive notice (2026-07-10)**: Toàn bộ M01-M14 đã đóng. Trạng thái hệ thống hiện tại nằm trong `docs/agent-context/` và source code.

| Module | Mục tiêu (1 dòng) | Files chính | Phụ thuộc | Status |
|---|---|---|---|---|
| **M01** | ~~Fix compile errors~~ — Issues invalidated (Riverpod 3 / Flutter 3.41) | _(no changes)_ | Không | ✅ Completed |
| **M02** | Fix splash stuck + auth false-error | `auth_controller.dart`, `splash_screen.dart` | Không | ✅ Completed |
| **M03** | Fix broken image (public→signed URL) | `transaction_repository.dart`, `supabase_image.dart` | Không | ✅ Completed |
| **M04** | Thêm AppException + error handling repos | `app_exception.dart` (new), `transaction_repository.dart`, `profile_repository.dart` | M02 | ✅ Completed |
| **M05** | Fix transaction CRUD bugs | `transaction_composer_controller.dart`, `transaction_form_sheet.dart`, `transaction_repository.dart` | M03, M04 | ✅ Completed |
| **M06** | Fix dead UI + Vietnamese diacritics | `login_screen.dart`, `transaction_detail_screen.dart`, `create_transaction_sheet.dart`, `day_detail_screen.dart`, `MainActivity.kt` | Không | ✅ Completed |
| **M07** | Camera lifecycle handling | `camera_screen.dart` | Không | ✅ Completed |
| **M08** | Android release build config | `AndroidManifest.xml`, `build.gradle.kts`, `proguard-rules.pro` (new) | Không | ✅ Completed |
| **M09** | Extract `_money()` + fix arch boundary | `currency_formatter.dart` (new), `signed_url_provider.dart` (new), 6 presentation files | Không | ✅ Completed |
| **M10** | Calendar performance optimization | `calendar_screen.dart`, `calendar_month_data.dart`, `day_detail_screen.dart`, `calendar_filters.dart` | M09 | ✅ Completed |
| **M11** | Router error page + localization | `app.dart`, `app_router.dart` | Không | ✅ Completed |
| **M12** | Profile upsert + group owner check | `profile_repository.dart`, `user_profile.dart`, `group_detail_screen.dart`, `profile_setup_controller.dart` | M04 | ✅ Completed |
| **M13** | Lint rules + theme docs + timezone | `analysis_options.yaml`, `app_theme.dart`, `profile_setup_screen.dart`, `main.dart` | Không | ✅ Completed |
| **M14** | Unit tests cho critical paths | 6 new test files | M04, M05 | ✅ Completed |

## Status Legend
- ⬜ Not Started
- 🔄 In Progress
- ✅ Completed
- ❌ Blocked
