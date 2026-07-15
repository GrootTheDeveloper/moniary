# AI Agent Directory Guide

**Confidence / Verification Status**: `VERIFIED AGAINST SOURCE`
**Last source audit**: `2026-07-10`

Tài liệu này giúp agent đặt code mới đúng vị trí trong cấu trúc feature-first
hiện tại. Không dùng lại các path cũ chỉ vì chúng xuất hiện trong lịch sử Git
hoặc tài liệu triển khai M01-M14.

## Nguyên tắc

- Product code nằm trong `lib/features/<feature>/`.
- Hướng phụ thuộc chuẩn:
  `presentation -> application -> domain/repository -> data source`.
- Feature nhỏ có thể không cần đủ bốn folder; không tạo folder rỗng chỉ để đối
  xứng.
- Widget dùng trong một feature đặt trong
  `features/<feature>/presentation/widgets/`; widget dùng nhiều feature đặt
  trong `lib/shared/widgets/`.
- Cross-feature infrastructure (Supabase, preferences, deep link, constants)
  đặt trong `lib/core/`.
- SQL/RLS/RPC thay đổi bằng migration mới trong `supabase/migrations/`.
- Edge Function đặt trong `supabase/functions/<function-name>/`.
- OCR Python chỉ đặt trong `backend/ocr/`.

## Feature hiện tại

```text
lib/features/
  assistant/      application/ data/ domain/ presentation/
  auth/           application/ data/ presentation/
  budgets/        application/ data/ domain/ presentation/
  calendar/       application/month/ domain/month/ presentation/month/
  categories/     application/ data/repositories/ domain/models/ presentation/
  friends/        application/ data/{datasources,models,repositories}/
                  domain/{entities,repositories}/ presentation/{screens,widgets}/
  groups/         application/ data/{datasources,models,repositories}/
                  domain/{entities,repositories,services}/
                  presentation/{screens,widgets}/
  journal/        application/ data/ domain/ presentation/
  onboarding/     presentation/
  profile/        application/ data/ domain/ presentation/
  scanning/       application/ data/ domain/ presentation/
  settings/       application/ data/ domain/ presentation/
  splash/         presentation/
  statistics/     presentation/
  transactions/   application/{composer,queries}/ data/repositories/
                  domain/models/ presentation/{camera,detail,form,starred}/
  wallets/        application/ data/repositories/ domain/models/ presentation/
```

## Chọn vị trí theo loại code

### Screen, sheet, widget

- Screen lớn: `presentation/<area>/<name>_screen.dart`.
- Sheet/form: `presentation/<area>/<name>_sheet.dart`.
- Widget riêng feature: `presentation/widgets/<name>.dart`.
- Primitive dùng toàn app: `lib/shared/widgets/<name>.dart`.

Ví dụ:

- `calendar/presentation/month/calendar_screen.dart`
- `transactions/presentation/form/transaction_form_sheet.dart`
- `groups/presentation/screens/group_detail_screen.dart`
- `budgets/presentation/widgets/budget_limit_editor.dart`

### Provider/controller/query

- Mutation/state machine: `application/<name>_controller.dart`.
- Read query/provider: `application/<area>/<name>_provider.dart` hoặc
  `<name>_queries.dart`, theo style của feature.
- Provider phụ thuộc repository, không gọi Supabase trực tiếp.

Ví dụ:

- `transactions/application/composer/transaction_composer_controller.dart`
- `transactions/application/queries/transaction_queries.dart`
- `calendar/application/month/calendar_month_provider.dart`
- `journal/application/journal_controller.dart`

### Domain

- Entity/model thuần: `domain/<area>/<name>.dart` hoặc `domain/models/`.
- Repository interface: `domain/.../<name>_repository.dart`.
- Pure calculation service: `domain/services/`.
- Không import Flutter UI/l10n vào domain.

### Data

- Repository implementation: `data/repositories/` hoặc trực tiếp `data/`
  theo cấu trúc sẵn có của feature.
- Supabase data source: `data/datasources/` hoặc cặp class trong một file
  data source.
- File/export/external service: `data/<area>/`.
- Không thêm demo/mock fallback cho module có backend state.

## Path hiện hành cần dùng

- Transaction model:
  `features/transactions/domain/models/transaction_entry.dart`.
- Transaction form:
  `features/transactions/presentation/form/transaction_form_sheet.dart`.
- Calendar screen:
  `features/calendar/presentation/month/calendar_screen.dart`.
- Category/wallet models:
  `features/categories/domain/models/category.dart` và
  `features/wallets/domain/models/wallet.dart`.
- Router: `lib/app/app_router.dart`.
- Theme: `lib/app/app_theme.dart`.
- ARB: `lib/l10n/app_vi.arb`, `lib/l10n/app_en.arb`.

## Checklist

1. Đọc `AGENTS.md` và docs liên quan.
2. Xác định feature, layer và runtime modes bị ảnh hưởng.
3. Tìm provider/repository/widget hiện có trước khi tạo abstraction mới.
4. Nếu thêm route, cập nhật `app_router.dart` và
   `07-routing-navigation.md`.
5. Nếu thêm field backend, tạo migration và cập nhật mapper/model/test.
6. Nếu thêm UI text, cập nhật cả hai ARB, không sửa generated l10n.
7. Chạy format/analyze/test phù hợp và rà soát diff.
