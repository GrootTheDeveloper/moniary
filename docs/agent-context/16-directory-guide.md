# AI Agent Directory Guide

Tài liệu này dùng để đưa cho AI Agent trước khi Khánh hoặc Khoa dev tiếp trên repo Moniary. Mục tiêu là giúp agent hiểu cấu trúc thư mục hiện tại và đặt code mới đúng vị trí, không quay lại layout cũ.

## Nguyên tắc chung

- Code chính nằm trong `lib/features/`.
- Mỗi feature nên giữ theo cấu trúc Clean Architecture nhẹ:
  - `application/`: state management, controller, provider, query, use-case orchestration.
  - `data/`: repository, service gọi Supabase, local storage, file IO, external API.
  - `domain/`: model/entity/value object và các kiểu dữ liệu thuần logic.
  - `presentation/`: screen, sheet, widget UI thuộc riêng feature đó.
- Nếu một feature lớn có nhiều nhóm chức năng, hãy tạo folder con theo area, ví dụ `presentation/form`, `presentation/detail`, `domain/models`, `data/repositories`.
- Không cần tách quá sâu nếu folder chỉ có 1 file và chưa có khả năng mở rộng rõ ràng.
- Widget dùng chung trong riêng một feature thì đặt ở `lib/features/<feature>/presentation/widgets/`.
- Widget dùng chung toàn app thì đặt ở `lib/shared/widgets/`.
- Khi di chuyển hoặc tạo file mới, luôn cập nhật import path và chạy format/analyze.

## Cấu trúc hiện tại cần tuân theo

```text
lib/
  app/
  core/
  shared/
    widgets/
  features/
    auth/
      application/
      presentation/
    calendar/
      application/
        month/
      domain/
        month/
      presentation/
        month/
    categories/
      application/
      data/
        repositories/
      domain/
        models/
      presentation/
    onboarding/
      presentation/
    profile/
      application/
      data/
      domain/
      presentation/
    settings/
      application/
        account/
      data/
        account/
        export/
      domain/
        export/
        privacy_requests/
        store/
        transparency/
      presentation/
        account/
        export/
        legal/
        privacy/
        store/
        support/
        widgets/
    splash/
      presentation/
    transactions/
      application/
        composer/
        queries/
      data/
        repositories/
      domain/
        models/
      presentation/
        camera/
        detail/
        form/
    wallets/
      application/
      data/
        repositories/
      domain/
        models/
      presentation/
```

## Quy tắc đặt file theo loại code

### Screen hoặc UI

- Screen chính: `lib/features/<feature>/presentation/<area>/<name>_screen.dart`
- Bottom sheet/form: `lib/features/<feature>/presentation/<area>/<name>_sheet.dart`
- UI component chỉ dùng trong feature: `lib/features/<feature>/presentation/widgets/<name>.dart`
- UI component dùng nhiều feature: `lib/shared/widgets/<name>.dart`

Ví dụ hiện tại:

- Calendar month screen: `lib/features/calendar/presentation/month/calendar_screen.dart`
- Transaction form: `lib/features/transactions/presentation/form/transaction_form_sheet.dart`
- Transaction detail: `lib/features/transactions/presentation/detail/transaction_detail_screen.dart`
- Settings reusable tile: `lib/features/settings/presentation/widgets/settings_action_tile.dart`

### Controller, provider, query

- Controller/provider điều phối UI state: `lib/features/<feature>/application/<area>/<name>_controller.dart`
- Query/provider đọc dữ liệu phục vụ màn hình: `lib/features/<feature>/application/<area>/<name>_queries.dart`
- Nếu feature nhỏ, có thể đặt trực tiếp trong `application/`.

Ví dụ hiện tại:

- Transaction composer: `lib/features/transactions/application/composer/transaction_composer_controller.dart`
- Transaction queries: `lib/features/transactions/application/queries/transaction_queries.dart`
- Calendar month provider: `lib/features/calendar/application/month/calendar_month_provider.dart`
- Wallet controller: `lib/features/wallets/application/wallets_controller.dart`

### Repository và data service

- Repository gọi Supabase hoặc nguồn dữ liệu ngoài: `lib/features/<feature>/data/repositories/<name>_repository.dart`
- Service xử lý file/export/external tool: `lib/features/<feature>/data/<area>/<name>_service.dart`

Ví dụ hiện tại:

- Transaction repository: `lib/features/transactions/data/repositories/transaction_repository.dart`
- Wallet repository: `lib/features/wallets/data/repositories/wallet_repository.dart`
- Category repository: `lib/features/categories/data/repositories/category_repository.dart`
- Export file action service: `lib/features/settings/data/export/file_action_service.dart`

### Domain model

- Model/entity thuần dữ liệu: `lib/features/<feature>/domain/models/<name>.dart`
- Nếu domain thuộc area riêng, đặt theo area: `lib/features/<feature>/domain/<area>/<name>.dart`

Ví dụ hiện tại:

- Transaction entry: `lib/features/transactions/domain/models/transaction_entry.dart`
- Wallet model: `lib/features/wallets/domain/models/wallet.dart`
- Category model: `lib/features/categories/domain/models/category.dart`
- Privacy request history: `lib/features/settings/domain/privacy_requests/privacy_request_history_entry.dart`

## Quy tắc import

- Ưu tiên relative import theo style hiện tại của repo.
- Khi file được đặt sâu thêm 1 folder, kiểm tra lại số lượng `../`.
- Không import từ path cũ sau refactor, ví dụ tránh:
  - `features/transactions/presentation/transaction_form_sheet.dart`
  - `features/transactions/domain/transaction_entry.dart`
  - `features/calendar/presentation/calendar_screen.dart`
  - `features/categories/domain/category.dart`
  - `features/wallets/domain/wallet.dart`
- Hãy dùng path mới:
  - `features/transactions/presentation/form/transaction_form_sheet.dart`
  - `features/transactions/domain/models/transaction_entry.dart`
  - `features/calendar/presentation/month/calendar_screen.dart`
  - `features/categories/domain/models/category.dart`
  - `features/wallets/domain/models/wallet.dart`

## Checklist trước khi sửa code

1. Xác định feature mình đang dev thuộc feature folder nào trong `lib/features/`.
2. Xác định loại code: UI, controller/provider, repository/service, hay domain model.
3. Đặt file theo đúng layer và area hiện có.
4. Tái sử dụng widget/helper hiện có trước khi tạo widget mới.
5. Không sửa phần không thuộc phạm vi feature nếu không cần thiết.
6. Sau khi sửa, chạy:

```powershell
dart format lib
dart analyze
```

Ghi chú: repo hiện có thể còn một số `info` lint cũ. Không tự ý refactor lan rộng chỉ để dọn lint nếu không liên quan trực tiếp đến task.

## Prompt gợi ý cho AI Agent

```text
Bạn đang dev trong repo Flutter Moniary. Hãy tuân theo cấu trúc thư mục hiện tại trong docs/ai_agent_directory_guide.md.

Trước khi tạo file mới, hãy xác định đúng feature và layer:
- application: controller/provider/query
- data: repository/service
- domain: model/entity/value object
- presentation: screen/sheet/widget UI

Không đặt file mới ở layout cũ. Không đổi behavior ngoài phạm vi task. Sau khi sửa, chạy dart format và dart analyze, rồi báo rõ các file đã thay đổi.
```
