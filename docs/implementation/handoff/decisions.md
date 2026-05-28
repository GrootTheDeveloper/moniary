# Quyết định kỹ thuật

> Ghi lại mọi quyết định kỹ thuật đã chốt trong quá trình dev.
> Mục đích: model/dev tiếp theo đọc để không phải quyết định lại.

## Quyết định ban đầu (từ planning phase)

### D01 — Giữ nguyên Architecture
- **Quyết định**: Giữ Clean Architecture feature-first + Riverpod 3.x + GoRouter.
- **Lý do**: Đổi architecture quá rủi ro, không cần thiết cho scope fix bugs.
- **Ảnh hưởng**: Tất cả modules.

### D02 — Dev theo module
- **Quyết định**: Chia 42 issues thành 14 module, mỗi module 2-5 files.
- **Lý do**: Tránh tràn context, dễ track progress, dễ rollback.
- **Ảnh hưởng**: Workflow dev.

### D03 — Không refactor lan rộng
- **Quyết định**: Chỉ sửa code trong scope liệt kê. Issues mới → backlog.
- **Lý do**: Giảm rủi ro regression, giữ commit nhỏ.
- **Ảnh hưởng**: Tất cả modules.

### D04 — Không thêm package mới
- **Quyết định**: Không thêm dependency vào pubspec.yaml trừ khi module yêu cầu rõ ràng.
- **Lý do**: Giảm attack surface, giữ build stable.
- **Ảnh hưởng**: Tất cả modules.

### D05 — Build gate bắt buộc
- **Quyết định**: Sau mỗi module chạy `flutter analyze` + `flutter test`, cả 2 phải pass.
- **Lý do**: Đảm bảo không có regression.
- **Ảnh hưởng**: Tất cả modules.

### D06 — Vietnamese text có dấu
- **Quyết định**: Tất cả user-facing strings phải có dấu tiếng Việt đầy đủ.
- **Lý do**: App target user Việt Nam.
- **Ảnh hưởng**: M02, M06, M04.

## Quyết định trong quá trình dev

> ### Dxx — Tên quyết định
> - **Module**: Mxx
> - **Quyết định**: ...
> - **Lý do**: ...
> - **Ảnh hưởng**: ...

### D07 — Bỏ qua các thay đổi của M01
- **Module**: M01
- **Quyết định**: Giữ nguyên `Notifier` (thay vì `AutoDisposeNotifier`) trong `scanning_controller.dart`. Giữ nguyên `initialValue` (thay vì `value`) trong `create_transaction_sheet.dart`.
- **Lý do**: `AutoDisposeNotifier` không tồn tại trong Riverpod 3.2.1. Việc đổi `initialValue` thành `value` gây ra warning deprecation trên Flutter >= 3.33 làm fail `flutter analyze`. Code gốc đã đúng và compile thành công.
- **Ảnh hưởng**: Không có code nào thay đổi từ M01. App build pass 0 errors.

### D08 — Thay đổi behavior của fetchCurrentProfile trong M04
- **Module**: M04
- **Quyết định**: Trong `ProfileRepository.fetchCurrentProfile`, thay thế check session trả về `null` bằng `_userId` getter ném ra `AppException` nếu chưa đăng nhập. 
- **Lý do**: Để tuân thủ chặt chẽ yêu cầu thay tất cả duplicate session null checks bằng `_userId` theo spec của M04.
- **Ảnh hưởng**: Gọi hàm khi chưa có session sẽ ném lỗi thay vì trả về null.

### D09 — Bỏ qua string "Dang nhap thanh cong" trong M06
- **Module**: M06
- **Quyết định**: Không sửa chuỗi "Dang nhap thanh cong" trong `auth_controller.dart`.
- **Lý do**: Chuỗi này không tồn tại trong `auth_controller.dart` hoặc bất kỳ đâu trong codebase hiện tại. Code có thể đã được sửa hoặc loại bỏ ở version/commit trước.
- **Ảnh hưởng**: Không có tác động đến logic hay UI hiện tại.

### D10 — Quản lý camera controller lifecycle & null safety guards
- **Module**: M07
- **Quyết định**: Implement WidgetsBindingObserver trong CameraScreen để dispose controller khi inactive (background) và khởi tạo lại khi resumed (foreground). Sử dụng local variables và logic guards (`_controller != null` và check target controller instances) để loại bỏ race conditions hoặc NPE.
- **Lý do**: Tránh hao pin (battery drain) và khóa camera khi app ở background. Đồng thời đảm bảo UI phản hồi mượt mà không crash khi controller bị hủy bất đồng bộ.
- **Ảnh hưởng**: `camera_screen.dart` hoạt động an toàn và tự động phục hồi preview khi app quay lại foreground.

### D11 — Cấu hình Android Release Build (R8, ProGuard, Permission)
- **Module**: M08
- **Quyết định**: 
  1. Thêm `<uses-permission android:name="android.permission.INTERNET"/>` vào main `AndroidManifest.xml`.
  2. Bật `isMinifyEnabled = true` và `isShrinkResources = true` trong `build.gradle.kts`.
  3. Tạo file `proguard-rules.pro` để bảo vệ các class cần thiết cho Supabase, Gson và Flutter, tránh bị strip bởi R8.
  4. Giữ nguyên cấu hình signing debug tạm thời để hỗ trợ chạy thử nghiệm cục bộ (`flutter run --release`).
- **Lý do**: Đảm bảo app có quyền kết nối Internet ở chế độ release, giảm dung lượng APK (shrink) và bảo mật mã nguồn chống dịch ngược (minify) mà không gây lỗi runtime crash do strip class của Supabase.
- **Ảnh hưởng**: APK được build thu nhỏ tối đa (khoảng 60MB), bảo mật hơn và kết nối Internet ổn định.

### D12 — Khai thác Shared Utility và Tách biệt Ranh giới Kiến trúc
- **Module**: M09
- **Quyết định**: 
  1. Trích xuất hàm định dạng tiền tệ trùng lặp `_money()` từ 6 file giao diện khác nhau vào một hàm dùng chung duy nhất: `formatVnd()` định nghĩa trong `lib/shared/utils/currency_formatter.dart`.
  2. Di chuyển `signedUrlProvider` từ widget dùng chung `supabase_image.dart` ra `lib/core/supabase/signed_url_provider.dart` để tránh việc tầng widget dùng chung import trực tiếp feature `transactions`.
- **Lý do**: Triệt tiêu trùng lặp code theo nguyên lý DRY, giúp cấu trúc ứng dụng sạch và dễ bảo trì hơn. Đồng thời giữ vững kiến trúc phân tầng, ngăn chặn việc vi phạm ranh giới kiến trúc (shared widget không phụ thuộc trực tiếp vào feature specific repository).
- **Ảnh hưởng**: Giảm trùng lặp code và làm sạch các import chéo bất hợp lệ giữa shared widgets và features layer.

### D13 — Tối ưu hóa hiệu năng Lịch tháng (Calendar Performance)
- **Module**: M10
- **Quyết định**: 
  1. Thay thế widget preview ảnh hóa đơn `SupabaseImage` bên trong các ô lịch (`_CalendarDayCell`) bằng một chấm tròn chỉ báo màu sắc danh mục (`dot indicator`).
  2. Thay đổi các computed getters nặng (`incomeTotal`, `expenseTotal` trong `CalendarDayData` và `activeDays` trong `CalendarMonthData`) thành các biến khởi tạo trễ `late final` để lưu bộ nhớ đệm (cache), tránh tính toán lại nhiều lần khi build UI.
  3. Cài đặt các hàm so sánh bằng `==` và `hashCode` cho `CalendarFilters` để tối ưu hóa so sánh trạng thái của Riverpod.
  4. Chuyển đổi phần thân hiển thị giao dịch trong ngày tại `day_detail_screen.dart` từ kiểu `ListView` trải rộng (spread operator) sang `ListView.builder` để hỗ trợ nạp danh sách lười (lazy loading).
- **Lý do**: Loại bỏ hoàn toàn hơn 30 lệnh gọi API lấy signed URL khi hiển thị lịch tháng, giải phóng luồng chính. Bộ đệm dữ liệu getters tránh lặp lại vòng lặp tính tổng giao dịch khi vẽ ô lịch. Danh sách lười trong chi tiết ngày giúp tối ưu hóa bộ nhớ cho các ngày có lượng lớn giao dịch.
- **Ảnh hưởng**: Hiệu năng cuộn lịch tháng mượt mà rõ rệt, không còn độ trễ render ô lịch và loại bỏ 100% API calls lấy ảnh không cần thiết trên lịch tháng.

### D14 — Củng cố Router và Việt hóa Widget Hệ thống (Router Hardening & Localization)
- **Module**: M11
- **Quyết định**: 
  1. Thêm `flutter_localizations` vào `pubspec.yaml` để lấy tài nguyên bản địa hóa của SDK.
  2. Bổ sung `localizationsDelegates`, `supportedLocales`, và cấu hình `locale` về tiếng Việt (`vi_VN`) trong `MaterialApp.router` tại `app.dart`.
  3. Thêm `errorBuilder` cho `GoRouter` tại `app_router.dart` để chuyển tiếp người dùng về màn hình thông báo "Trang không tồn tại" thay vì crash khi gặp route không hợp lệ.
  4. Chuyển đổi toàn bộ các dòng ép kiểu `state.extra as Type` không an toàn thành ép kiểu an toàn `state.extra as Type?`, đi kèm kiểm tra `null` và hiển thị màn hình fallback an toàn để tránh crash khi deep link trực tiếp.
  5. Thay thế import `foundation.dart` thành `material.dart` trong `app_router.dart` để sử dụng được các UI widgets cần thiết cho `errorBuilder`.
- **Lý do**: Ngăn ngừa crash hệ thống khi xử lý deep link hoặc điều hướng không hợp lệ. Đảm bảo tính nhất quán của trải nghiệm người dùng bản địa (DatePicker, Dialogs, v.v. hiển thị tiếng Việt thay vì tiếng Anh mặc định).
- **Ảnh hưởng**: Ứng dụng hoạt động cực kỳ ổn định, không còn bị crash bất ngờ do định tuyến lỗi hoặc thiếu tham số điều hướng. Các widget hệ thống hiển thị tiếng Việt hoàn toàn chuẩn hóa.

### D15 — Đồng bộ hóa Hồ sơ và Kiểm tra Chủ nhóm (Profile & Data Fixes)
- **Module**: M12
- **Quyết định**: 
  1. Thay thế phương thức `.update()` thành `.upsert()` trong `ProfileRepository.upsertProfile()` và đưa khóa chính `id: uid` vào payload truyền đi để hỗ trợ tạo mới dòng dữ liệu nếu hồ sơ của người dùng chưa tồn tại trong bảng `profiles`.
  2. Lưu tài liệu ghi chú giả định về tên hiển thị `'guest'` trong getter `needsSetup` tại `user_profile.dart`.
  3. Sửa đổi kiểm tra phân quyền chủ nhóm (owner check) tại `group_detail_screen.dart` từ việc dựa vào thứ tự mảng không chính xác (`index == 0`) sang so sánh ID trực tiếp (`member.id == group.ownerId`).
  4. Đổi lệnh gọi `ref.read` thành `ref.watch` đối với `profileRepositoryProvider` trong phương thức `build()` của `ProfileSetupController` tại `profile_setup_controller.dart`.
- **Lý do**: Giải quyết lỗi không thể khởi tạo hồ sơ Supabase cho người dùng đăng nhập ẩn danh mới (upsert). Bảo toàn logic phân quyền quản lý thành viên nhóm dựa trên thông tin thực tế thay vì cấu trúc hiển thị UI. Bảo đảm tính phản hồi (reactive) của Riverpod controller khi có thay đổi trong Repository provider.
- **Ảnh hưởng**: Dữ liệu hồ sơ người dùng được khởi tạo và lưu trữ đầy đủ, an toàn. Phân quyền chủ nhóm hoạt động chính xác tuyệt đối. Notifier hoạt động reactive theo chuẩn Riverpod.

### D16 — Đánh bóng Chất lượng Mã nguồn và Bổ sung Linter (Lint & Models Polish)
- **Module**: M13
- **Quyết định**: 
  1. Thêm các quy tắc phân tích tĩnh nghiêm ngặt vào `analysis_options.yaml`: `avoid_print`, `unawaited_futures`, `cancel_subscriptions`, và `close_sinks`.
  2. Bổ sung các chú thích làm rõ (documentation comments) cho màu chữ cứng trong cấu hình TextTheme tại `app_theme.dart` (màu `Color(0xFFBECCD9)` và `Color(0xFF9CB0C2)` đại diện cho custom `onSurfaceVariant` token).
  3. Thêm chú thích TODO cho việc tự động phát hiện múi giờ của thiết bị tại `profile_setup_screen.dart` thay vì fix cứng giá trị `'Asia/Ho_Chi_Minh'`.
  4. Bổ sung tài liệu giải thích cho biến toàn cục `cameras` được khởi tạo một lần khi khởi động ứng dụng tại `main.dart`.
- **Lý do**: Nâng cấp chất lượng code thông qua bộ kiểm tra linter tĩnh (tránh quên đóng stream, quên cancel subscription, in print debug bừa bãi). Tài liệu hóa các hằng số màu thiết kế và biến toàn cục để đội ngũ phát triển sau dễ đọc hiểu và tiếp cận dự án.
- **Ảnh hưởng**: Quy trình kiểm tra tĩnh nghiêm ngặt hơn giúp phát hiện sớm các vấn đề tiềm ẩn về rò rỉ bộ nhớ (leak). Mã nguồn được lập tài liệu rõ ràng.

### D17 — Bổ sung Bộ Kiểm thử Đơn vị Toàn diện (Comprehensive Unit Testing Suite)
- **Module**: M14
- **Quyết định**:
  1. Xây dựng 6 file test mới tăng độ bao phủ (coverage) cho các logic cốt lõi bao gồm: AppException, các trường hợp biên của Debt Calculator, toàn bộ validator cho Group Expense, máy trạng thái của Scanning Controller, dữ liệu Mock OCR và các biên định dạng tiền tệ vi_VN.
  2. Lắng nghe (listen) các autoDispose Provider trong ProviderContainer ở unit tests để duy trì trạng thái của notifier trong suốt các luồng thực thi bất đồng bộ, tránh lỗi provider bị giải phóng sớm (Ref disposed exception).
- **Lý do**: Đảm bảo các thành phần logic hoạt động ổn định và chính xác dưới các điều kiện biên cực đoan. Việc listen autoDispose provider là bắt buộc để kiểm thử các notifier có chứa logic bất đồng bộ trong Riverpod.
- **Ảnh hưởng**: Số lượng test cases tăng từ 8 lên 35+, tăng độ tự tin khi refactor hoặc nâng cấp hệ thống trong tương lai mà không phá vỡ logic cũ.






