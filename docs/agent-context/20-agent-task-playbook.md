# Agent Task Playbook

**Confidence / Verification Status**: `VERIFIED AGAINST SOURCE`
**Last source audit**: `2026-07-10`

Đây là quy trình mặc định khi agent thay đổi Moniary. `AGENTS.md` và yêu cầu
cụ thể của task luôn có ưu tiên cao hơn.

## Trước mọi thay đổi không nhỏ

1. Đọc `AGENTS.md`, `00-index.md`, `03-architecture.md`, và docs của
   feature.
2. Kiểm tra `git status --short`; giữ nguyên thay đổi không liên quan của user.
3. Trace code từ route/screen đến provider/controller, repository, data source,
   migration và test.
4. Xác định cả Supabase mode và guest/mock mode.
5. Ghi rõ assumption nếu behavior không thể suy ra từ code/test.

## Thêm hoặc mở rộng feature

1. Kiểm tra `04-features.md` và feature hiện có để tránh tạo module trùng.
2. Chọn layer/path theo `16-directory-guide.md`; không bắt buộc tạo đủ bốn
   folder nếu feature nhỏ.
3. Định nghĩa domain model/repository contract trước khi UI cần dữ liệu mới.
4. Data implementation phải preserve `useMockDataModeProvider`.
5. Mutation đi qua controller; query dùng provider và invalidate đúng family key.
6. UI dùng theme tokens và l10n; có loading/empty/error/retry phù hợp.
7. Thêm route an toàn với typed extra/fallback và cập nhật route docs.
8. Nếu đổi schema/RLS/RPC, thêm migration mới; không sửa lịch sử đã deploy.
9. Thêm/cập nhật test theo pattern gần nhất.
10. Cập nhật docs current-state trong cùng change.

## Sửa bug

1. Reproduce bằng test hoặc mô tả state/data cụ thể.
2. Fix root cause ở đúng layer, không vá bằng raw UI/backend call.
3. Kiểm tra lỗi có xảy ra ở cả Supabase và mock/guest hay không.
4. Với mutation, kiểm tra invalidation, async mounted, error mapping và partial
   success.
5. Thêm regression test nếu có pattern test phù hợp.

## Thêm screen/route

1. Đặt screen trong feature `presentation/`.
2. Data access qua provider/controller.
3. Thêm `static const routePath` nếu phù hợp.
4. Trong router, cast `state.extra` an toàn và có fallback không crash.
5. Cập nhật `07-routing-navigation.md`.

## Localization và design

1. Sửa cả `app_vi.arb` và `app_en.arb`.
2. Chạy `flutter gen-l10n`/build; không sửa generated files.
3. Dùng `context.moniaryColors`, `context.moniaryTypography`, shared
   primitives, outlined icons và privacy-aware amount widgets.
4. Kiểm tra overflow ở kích thước màn hình nhỏ.

## Backend và dữ liệu

1. Migration là nguồn sự thật cho schema, policy, view, trigger và RPC.
2. Không coi client-side filter là security boundary; thêm/test RLS.
3. Multi-row financial/group mutations cần transaction/RPC atomic khi tính nhất
   quán yêu cầu.
4. Không log hoặc commit secret/token.
5. Nếu thêm external processor/API, cập nhật privacy/integration docs.

## Validation

```bash
flutter pub get
dart format --set-exit-if-changed .
flutter analyze
flutter test
```

Với OCR Python, chạy thêm `pytest` trong `backend/ocr/`. Với docs-only,
kiểm tra local Markdown links/references, tên route/file, contradiction search,
và `git diff --check`.

## Handoff

Báo rõ file đã đổi, behavior/docs chính đã đồng bộ, lệnh kiểm tra và kết quả,
cùng các rủi ro hoặc việc cần xác nhận ở môi trường ngoài repo. Không cập nhật
`docs/implementation/handoff/current_status.md` như thể M01-M14 còn là roadmap;
đó là hồ sơ lịch sử đã hoàn thành.
