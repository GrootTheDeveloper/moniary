# Roadmap tổng thể

## Bảng Roadmap

| Phase | Module | Mục tiêu | Severity | Files | Phụ thuộc | Output |
|:---:|---|---|:---:|:---:|---|---|
| **1** | M01 — Compile Fixes | Fix compile errors chặn build | 🔴 Critical | 2 | Không | App build thành công |
| **1** | M02 — Auth & Splash Bugs | Fix auth logic + splash stuck | 🔴 Critical | 3 | Không | Auth flow OK, splash không kẹt |
| **1** | M03 — Image URL Fix | Fix broken image (public URL trên private bucket) | 🔴 Critical | 2 | Không | Image hiển thị đúng |
| **2** | M04 — Error Handling Layer | Thêm AppException + try/catch repositories | 🟡 High | 4 | M02 | Errors không lộ raw cho user |
| **2** | M05 — Transaction Bugs | Fix double-throw, state-in-build, delete cleanup | 🟡 High | 3 | M03, M04 | Transaction CRUD ổn định |
| **2** | M06 — UI Dead States | Fix dead buttons, Vietnamese diacritics, hardcoded label | 🟡 High | 7 | Không | UI nhất quán |
| **2** | M07 — Camera Lifecycle | WidgetsBindingObserver cho camera | 🟡 High | 1 | Không | Camera release đúng khi bg |
| **2** | M08 — Android Config | INTERNET permission, ProGuard, signing TODO | 🟡 High | 3 | Không | Release build config ready |
| **3** | M09 — Shared Utils Extract | Extract `_money()`, fix architectural boundary | 🟠 Medium | 8 | Không | Code DRY |
| **3** | M10 — Calendar Performance | Bỏ SupabaseImage cells, cache getters, lazy list | 🟠 Medium | 4 | M09 | Calendar nhanh hơn |
| **3** | M11 — Router Hardening | Error page, localization delegates, safe casts | 🟠 Medium | 2 | Không | Không crash deep link |
| **3** | M12 — Profile & Data Fixes | upsert fix, owner check, ref.watch | 🟠 Medium | 4 | M04 | Data layer robust |
| **4** | M13 — Lint & Models Polish | Lint rules, timezone, theme tokens | 🟢 Low | 5 | Không | Code quality baseline |
| **4** | M14 — Test Coverage | 17+ unit tests | 🟢 Low | 6 new | M04, M05 | Coverage 8 → 25+ cases |

## Dependency Graph (text)

```
M01 ──────────────────────────────┐
M02 ──→ M04 ──→ M05 ──→ M14      │
M03 ──────────→ M05               │
                M04 ──→ M12       │
                                  ▼
M06  (độc lập)               M05 ← M01
M07  (độc lập)
M08  (độc lập)
M09 ──→ M10
M11  (độc lập)
M13  (độc lập)
```

### Modules hoàn toàn độc lập (làm bất kỳ lúc nào)
M06, M07, M08, M09, M11, M13

### Dependency chains
- M01 → M05 → M14
- M02 → M04 → M05 → M14
- M03 → M05
- M04 → M12
- M09 → M10

## Thứ tự commit đề xuất
| # | Commit | Module |
|---|---|---|
| 1 | `fix(M01): fix ScanningController + DropdownButtonFormField` | M01 |
| 2 | `fix(M02): splash error handling + auth re-throw` | M02 |
| 3 | `fix(M03): replace getPublicImageUrl with signed` | M03 |
| 4 | `feat(M04): add AppException + repo error handling` | M04 |
| 5 | `fix(M05): composer double-throw + state-in-build + delete cleanup` | M05 |
| 6 | `fix(M06): dead auth buttons + Vietnamese diacritics` | M06 |
| 7 | `fix(M07): camera lifecycle WidgetsBindingObserver` | M07 |
| 8 | `chore(M08): INTERNET permission + ProGuard` | M08 |
| 9 | `refactor(M09): extract formatVnd + move signedUrlProvider` | M09 |
| 10 | `perf(M10): calendar SupabaseImage removal + cache` | M10 |
| 11 | `fix(M11): localization delegates + router errorBuilder` | M11 |
| 12 | `fix(M12): profile upsert + group owner check` | M12 |
| 13 | `chore(M13): lint rules + theme docs + timezone` | M13 |
| 14 | `test(M14): 17+ unit tests` | M14 |
