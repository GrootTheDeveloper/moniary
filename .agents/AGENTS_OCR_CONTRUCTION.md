## 1. Tổng Quan Kiến Trúc & Công Nghệ

Hệ thống được thiết kế theo cấu trúc mô-đun hóa, dễ dàng tích hợp vào ứng dụng di động (Android Native với Kotlin & Jetpack Compose) và có thể mở rộng phần xử lý nặng (OCR Engine) lên Backend nếu cần độ chính xác cao hơn.

### Thành phần công nghệ khuyến nghị:
- **Mobile Client:** Android SDK, CameraX Core, Photo Picker API.
- **Tiền xử lý ảnh:** OpenCV cho Android hoặc thư viện xử lý Bitmap thuần.
- **OCR Engine (Lựa chọn mô-đun):**
  - *Option A (On-device):* Google ML Kit Text Recognition V2 (Hỗ trợ tiếng Việt, miễn phí, ngoại tuyến).
  - *Option B (Server-side):* PaddleOCR (Open-source, độ chính xác cực cao với tiếng Việt).
- **Trích xuất dữ liệu:** Regular Expression (Regex) tối ưu riêng cho định dạng số tiền VND.

---

## 2. Quy Trình Xử Lý Chi Tiết (Pipeline Flow)

Mô hình xử lý bao gồm 5 bước tuần tự:

```
[Ảnh Đầu Vào] -> (1. Thu Thập) -> (2. Tiền Xử Lý) -> (3. OCR Engine) -> (4. Regex Trích Xuất) -> (5. Giao Diện Xác Thực) -> [Kết Quả Số Nguyên]
```

### Bước 1: Thu Thập Hình Ảnh (Image Acquisition)
- **Chụp ảnh qua Camera:** Sử dụng `CameraX` để khởi tạo `PreviewView`. Thiết lập cấu hình `ImageCapture` với chất lượng ảnh tối ưu (`CaptureMode.MAXIMIZE_QUALITY`). Bật hỗ trợ đèn Flash (Auto/On/Off) để giải quyết vấn đề thiếu sáng khi chụp hóa đơn.
- **Tải ảnh từ thư viện:** Sử dụng `ActivityResultContracts.PickVisualMedia()` (Photo Picker) để đảm bảo quyền truy cập tối giản và bảo mật.
- **Đầu ra mong muốn:** Một file ảnh cục bộ dạng `File` hoặc một luồng dữ liệu ảnh `Bitmap` có độ phân giải đủ lớn (tối thiểu 1080p).

### Bước 2: Tiền Xử Lý Hình Ảnh (Image Preprocessing)
*Mục tiêu: Tăng độ tương phản, giảm nhiễu để bộ OCR không bị đọc sai ký tự.*
- **Xử lý hình học:** Triển khai tính năng cắt ảnh (Crop) để người dùng chủ động khoanh vùng khu vực có số tiền hoặc tự động nhận diện cạnh hóa đơn bằng thuật toán tìm đường biên (Contour Detection).
- **Xử lý pixel:** - Chuyển ảnh màu sang ảnh xám (Grayscale).
  - Áp dụng kỹ thuật nhị phân hóa thích nghi (Adaptive Thresholding) để tách biệt rõ ràng giữa chữ đen và nền trắng của hóa đơn.
  - Sử dụng bộ lọc Gaussian Blur nhẹ để khử nhiễu hạt (noise) sinh ra do camera.

### Bước 3: Nhận Diện Văn Bản (OCR Engine)
Hệ thống cần cung cấp interface cấu hình linh hoạt cho một trong hai giải pháp sau:
- **Hướng triển khai On-device (ML Kit):**
  - Khởi tạo `TextRecognizer` sử dụng mã ngôn ngữ Tiếng Việt.
  - Chuyển đổi `Bitmap` đã tiền xử lý thành `InputImage`.
  - Gọi phương thức `process(image)` để nhận về đối tượng `Text` chứa danh sách các `TextBlock`, `Line`, và `Element`.
- **Hướng triển khai Server-side (PaddleOCR API):**
  - Nén ảnh `Bitmap` dưới định dạng JPEG/PNG, chuyển thành Base64 hoặc Multipart Body.
  - Gửi HTTP Request POST lên endpoint Backend.
  - Backend chạy PaddleOCR (Python/NodeJS) và trả về mảng chuỗi văn bản (JSON) kèm tọa độ boundbox.

### Bước 4: Trích Xuất Tổng Tiền Bằng Thuật Toán & Regex
Văn bản trả về từ OCR thường là một danh sách các chuỗi văn bản hỗn hợp. Thuật toán trích xuất cần thực hiện theo các bước:

1. **Chuẩn hóa chuỗi (Sanitization):** Chuyển tất cả chữ về dạng viết thường (lowercase), loại bỏ khoảng trắng thừa.
2. **Tìm từ khóa neo (Anchor Keywords):** Quét tìm các từ khóa đặc trưng cho tổng tiền của hóa đơn Việt Nam:
   - `tổng tiền`, `tong tien`, `tổng cộng`, `tong cong`, `thành tiền`, `thanh tien`, `thanh toán`, `thanh toan`, `total amount`, `total`.
3. **Áp dụng Regex cục bộ:** Định vị các dòng văn bản nằm ngay bên cạnh hoặc ngay phía dưới từ khóa neo, sau đó áp dụng mẫu Regex quét số tiền VND:
   - Mẫu Regex đề xuất: `(?:tổng tiền|thanh toán|tổng cộng|thành tiền)[\s:.\-]*([\d.,]+)\s*(?:vnđ|vnd|đ)?`
   - Biểu thức bắt số độc lập: ` \d{1,3}(?:[.,]\d{3})+ ` (Hỗ trợ bắt các cấu trúc dạng `150.000` hoặc `1,250,000`).

### Bước 5: Hậu Xử Lý Dữ Liệu & Giao Diện Xác Thực (UI/UX Validation)
- **Chuẩn hóa số nguyên:** Chuỗi bắt được từ Regex (Ví dụ: `"150.000"`) phải được loại bỏ tất cả dấu chấm `.` hoặc dấu phẩy `,` để ép kiểu về dạng số nguyên lớn (`Long` trong Kotlin) thành `150000`.
- **Thiết kế UI Jetpack Compose:**
  - Hiển thị ảnh hóa đơn đã chụp/tải lên ở nửa trên màn hình.
  - Kết quả số tiền tự động trích xuất sẽ được điền vào một thành phần `OutlinedTextField`.
  - Cung cấp bàn phím số (`KeyboardType.Number`) để người dùng có thể chỉnh sửa thủ công ngay lập tức nếu OCR nhận diện sai (ví dụ số `0` thành chữ `o` hoặc số `8` thành `B`).
  - Nút "Xác nhận" (Confirm) để lưu giá trị cuối cùng vào cơ sở dữ liệu hệ thống.

---

## 3. Chỉ Dẫn Kiểm Thử & Nghiệm Thu (Acceptance Criteria)

Khi Codex sinh mã nguồn, cần đảm bảo vượt qua các kịch bản kiểm thử sau:
1. **Định dạng số phổ biến:** Nhận diện đúng số tiền khi viết dưới dạng `50000`, `50.000`, `50,000`, `50.000đ`, `50,000 VND`.
2. **Khả năng chịu lỗi cấu trúc:** Thuật toán vẫn tìm được tổng tiền nếu từ khóa viết hoa, viết thường hoặc không dấu (`Tong cong`, `tổNg TiỀn`).
3. **Xử lý ngoại lệ:** Nếu không tìm thấy bất kỳ số tiền nào phù hợp, hệ thống không được crash mà phải để trống `OutlinedTextField` và thông báo nhẹ cho người dùng nhập tay.
4. **Hiệu năng:** Thời gian xử lý từ lúc nhấn nút OCR đến khi hiển thị kết quả trên thiết bị không quá 3 giây (đối với On-device) hoặc không quá 5 giây (đối với Server-side tùy thuộc tốc độ mạng).