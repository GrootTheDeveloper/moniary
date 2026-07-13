# Rule-based Receipt OCR Pipeline — Detailed Reference

**Document type**: `IMPLEMENTATION REFERENCE`
**Current implementation audit**: `2026-07-10`

The pipeline is implemented under `backend/ocr/`. Use the executable Python
source, tests, and `19-ocr-backend.md` for current run instructions. The task
sections below preserve the original design constraints and expected rules.

## Tổng quan dự án

Pipeline đọc ảnh bill/receipt chụp bằng camera, trích xuất dữ liệu có cấu trúc (items, VAT, discount, total, ...) và trả về JSON thông qua FastAPI.

**Phương pháp:** Hoàn toàn rule-based — không dùng AI, không dùng LLM, không dùng cloud API.  
**Stack:** Python 3.10+ · OpenCV · Pillow · Tesseract OCR (vie + eng) · Regex · FastAPI · Uvicorn  
**Ngôn ngữ bill hỗ trợ:** Tiếng Việt và Tiếng Anh (song ngữ)

---

## Cấu trúc thư mục

```
receipt-ocr/
├── AGENTS.md
├── main.py                        ← FastAPI entrypoint
├── cli.py                         ← CLI test nhanh
├── requirements.txt
├── src/
│   ├── __init__.py
│   ├── models.py                  ← Pydantic schemas
│   ├── preprocess.py              ← xử lý ảnh trước OCR
│   ├── ocr.py                     ← gọi Tesseract, lấy raw text
│   ├── cleaner.py                 ← làm sạch text sau OCR
│   ├── extractor.py               ← rule-based extraction (orchestrator)
│   ├── rules/
│   │   ├── __init__.py
│   │   ├── header.py              ← extract merchant, date, address
│   │   ├── items.py               ← extract line items (name, qty, price)
│   │   └── totals.py              ← extract subtotal, VAT, discount, total
│   └── validator.py               ← validate + normalize JSON output
├── config/
│   └── keywords.py                ← từ điển keyword VI + EN
├── tests/
│   ├── test_cleaner.py
│   ├── test_rules_header.py
│   ├── test_rules_items.py
│   ├── test_rules_totals.py
│   ├── test_validator.py
│   └── samples/                   ← ảnh bill mẫu để test
└── docs/
    └── regex_patterns.md          ← tài liệu giải thích các pattern
```

---

## Yêu cầu môi trường

### Tesseract OCR

```bash
# Ubuntu / Debian
sudo apt update
sudo apt install tesseract-ocr tesseract-ocr-vie tesseract-ocr-eng

# macOS
brew install tesseract
brew install tesseract-lang   # bao gồm vie

# Windows
# Tải installer tại: https://github.com/UB-Mannheim/tesseract/wiki
# Sau đó cài thêm gói ngôn ngữ: vie.traineddata vào thư mục tessdata

# Kiểm tra cài đặt
tesseract --version
tesseract --list-langs   # phải thấy vie và eng
```

### Python

```bash
python -m venv venv
source venv/bin/activate      # Windows: venv\Scripts\activate
pip install -r requirements.txt
```

---

## Nhiệm vụ Codex cần thực hiện

### Task 1 — Tạo `requirements.txt`

```
fastapi>=0.111.0
uvicorn[standard]>=0.29.0
python-multipart>=0.0.9
pytesseract>=0.3.10
opencv-python-headless>=4.9.0
Pillow>=10.3.0
pydantic>=2.7.0
numpy>=1.26.0
```

---

### Task 2 — Tạo `config/keywords.py`

File chứa từ điển keyword tiếng Việt và tiếng Anh để match các trường trên bill.

```python
# config/keywords.py

DATE_KEYWORDS = [
    "ngày", "ngay", "hóa đơn ngày", "lập ngày",
    "giờ in", "thời gian", "giờ", "gio",
    "date", "time", "printed", "issued",
]

SUBTOTAL_KEYWORDS = [
    "tổng tiền hàng", "tổng cộng", "cộng", "tổng", "thành tiền",
    "tạm tính", "tam tinh", "tong tien hang", "tong cong",
    "subtotal", "sub total", "sub-total", "net amount",
]

VAT_KEYWORDS = [
    "thuế gtgt", "gtgt", "thuế vat", "thuế", "thue", "vat",
    "thuế 10%", "thuế 8%", "thuế 5%",
    "vat", "tax", "gst", "hst", "sales tax",
]

DISCOUNT_KEYWORDS = [
    "giảm giá", "khuyến mãi", "ưu đãi", "chiết khấu",
    "giam gia", "khuyen mai", "uu dai", "chiet khau",
    "voucher", "coupon",
    "discount", "promo", "promotion", "rebate",
]

TOTAL_KEYWORDS = [
    "tổng thanh toán", "thành tiền thanh toán", "khách trả",
    "tiền thanh toán", "tổng tiền thanh toán", "tong thanh toan",
    "tổng phải thanh toán", "thanh toán",
    "total", "grand total", "total amount", "amount due",
    "total due", "balance due",
]

PAYMENT_KEYWORDS = {
    "cash": ["tiền mặt", "cash", "tien mat"],
    "card": ["thẻ", "visa", "mastercard", "jcb", "atm", "card"],
    "transfer": ["chuyển khoản", "chuyen khoan", "banking", "momo", "vnpay", "zalopay"],
}

CURRENCY_MAP = {
    "đ": "VND", "vnd": "VND", "vnđ": "VND",
    "₫": "VND", "dong": "VND",
    "usd": "USD", "$": "USD",
}

ADDRESS_KEYWORDS = [
    "đường", "phố", "quận", "phường", "tp.", "tỉnh",
    "street", "district", "ward", "city", "số ",
]
```

---

### Task 3 — Tạo `src/models.py`

```python
from pydantic import BaseModel
from typing import Optional

class ReceiptItem(BaseModel):
    name: str
    qty: float = 1.0
    unit_price: float = 0.0
    amount: float = 0.0

class ReceiptData(BaseModel):
    merchant: Optional[str] = None
    address: Optional[str] = None
    date: Optional[str] = None          # ISO format YYYY-MM-DD
    time: Optional[str] = None          # HH:MM nếu có
    items: list[ReceiptItem] = []
    subtotal: float = 0.0
    discount: float = 0.0
    vat_rate: float = 0.0               # phần trăm, ví dụ 10.0
    vat_amount: float = 0.0
    total: float = 0.0
    currency: str = "VND"
    payment_method: Optional[str] = None

class ReceiptResponse(BaseModel):
    success: bool
    data: Optional[ReceiptData] = None
    raw_text: Optional[str] = None      # OCR text thô (chỉ khi debug=true)
    validation_issues: list[str] = []
    confidence: float = 0.0             # 0.0 – 1.0
    error: Optional[str] = None
```

---

### Task 4 — Tạo `src/preprocess.py`

Xử lý ảnh để tăng độ chính xác Tesseract OCR.

**Hàm `preprocess(image_path: str) -> str`:**
- Đọc ảnh bằng `cv2.imread()`, raise `ValueError` nếu không đọc được
- **Resize:** nếu cạnh dài > 2000px → resize giữ tỷ lệ (Tesseract cần ảnh lớn hơn Vision LLM)
- **Deskew:** gọi hàm `deskew()` riêng
- **Grayscale:** `cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)`
- **Denoise:** `cv2.fastNlMeansDenoising(gray, h=10)`
- **Adaptive binarization:** `cv2.adaptiveThreshold` với `ADAPTIVE_THRESH_GAUSSIAN_C`, blockSize=11, C=2
- **Sharpen:** kernel `[[0,-1,0],[-1,5,-1],[0,-1,0]]`
- Lưu ra `/tmp/receipt_<uuid4_8chars>.jpg` JPEG quality 95
- Trả về đường dẫn file đã xử lý

**Hàm `deskew(image: np.ndarray) -> np.ndarray`:**
- Dùng `cv2.Canny` → `cv2.HoughLinesP` để tìm góc các đường ngang
- Tính median angle của các đường gần nằm ngang (angle trong [-45°, 45°])
- Xoay ảnh nếu `abs(angle) > 0.5°` bằng `cv2.getRotationMatrix2D`
- Trả về ảnh đã xoay, hoặc ảnh gốc nếu không cần xoay

---

### Task 5 — Tạo `src/ocr.py`

```python
import pytesseract
from PIL import Image
import time

TESSERACT_CONFIG = r"--oem 3 --psm 6 -l vie+eng"
# oem 3 = LSTM engine; psm 6 = uniform text block; psm 4 = single column (fallback)

def run_ocr(image_path: str) -> str:
    """
    Chạy Tesseract OCR, trả về raw text.
    Thử psm 6 trước, nếu output quá ngắn (< 20 ký tự) thử lại psm 4.
    """
    ...

def run_ocr_with_layout(image_path: str) -> list[dict]:
    """
    Chạy Tesseract với image_to_data(), trả về list word-level data.
    Filter bỏ entry có conf < 30.
    """
    ...
```

- Log thời gian OCR ra stdout: `f"OCR completed in {elapsed:.2f}s"`
- Raise `RuntimeError` với hướng dẫn cài đặt nếu bắt được `TesseractNotFoundError`

---

### Task 6 — Tạo `src/cleaner.py`

**Hàm `clean_text(raw: str) -> str`:**

1. Apply `OCR_FIXES` dict cho lỗi OCR phổ biến:
   ```python
   OCR_FIXES = {
       "l0": "10", "O0": "00", "0O": "00",
       " |": " I", "| ": "I ",
       "rn": "m",
   }
   ```
2. Loại bỏ dòng trống liên tiếp (giữ tối đa 1 dòng trắng)
3. Loại ký tự rác — giữ lại: chữ cái (bao gồm toàn bộ Unicode tiếng Việt), chữ số, khoảng trắng, và các ký tự `.,:-()/\%+×xX`
4. Strip từng dòng
5. Trả về text đã clean

**Hàm `normalize_money(text: str) -> float`:**
- Xử lý: `"1.500.000"` → `1500000.0`, `"1,500,000"` → `1500000.0`, `"150.000đ"` → `150000.0`, `"150K"` → `150000.0`, `"1.5M"` → `1500000.0`
- Quy tắc: nếu có cả `.` và `,` → dấu sau cùng là decimal separator; nếu chỉ có `.` mà phần sau `.` có đúng 3 chữ số → là ngàn separator
- Loại bỏ ký tự tiền tệ trước khi parse
- Raise `ValueError` nếu không parse được

**Hàm `remove_diacritics(text: str) -> str`:**
- Dùng `unicodedata.normalize("NFD", text)` + filter `Mn` category
- Dùng để so sánh keyword không phân biệt dấu tiếng Việt

---

### Task 7 — Tạo `src/rules/header.py`

**Hàm `extract_header(lines: list[str]) -> dict`:**

```python
{
    "merchant": str | None,
    "address": str | None,
    "date": str | None,      # YYYY-MM-DD
    "time": str | None,      # HH:MM
}
```

Logic (chỉ scan 10 dòng đầu):

1. **Merchant:** Dòng đầu tiên không rỗng, ≥ 3 ký tự, không phải số thuần túy, không phải địa chỉ
2. **Address:** Dòng chứa keyword từ `ADDRESS_KEYWORDS` trong `config/keywords.py`
3. **Date patterns:**
   ```python
   DATE_PATTERNS = [
       r"(\d{1,2})[/\-\.](\d{1,2})[/\-\.](\d{2,4})",   # DD/MM/YYYY
       r"(\d{4})[/\-\.](\d{1,2})[/\-\.](\d{1,2})",      # YYYY-MM-DD
       r"ngày\s+(\d{1,2})\s+tháng\s+(\d{1,2})\s+năm\s+(\d{4})",
   ]
   ```
   Ưu tiên DD/MM/YYYY (chuẩn Việt Nam), convert sang ISO YYYY-MM-DD
4. **Time:** `r"(\d{1,2}):(\d{2})(?::\d{2})?(?:\s*(?:AM|PM|am|pm))?"`

---

### Task 8 — Tạo `src/rules/items.py`

**Hàm `extract_items(lines: list[str]) -> list[dict]`:**

Mỗi item: `{"name": str, "qty": float, "unit_price": float, "amount": float}`

Logic:

1. **Xác định vùng items:** Cắt sau header (dòng 3 trở đi) đến trước keyword subtotal/total
2. **Bỏ qua dòng:** separator `---`, dòng < 3 ký tự, dòng chứa keyword totals
3. **3 pattern parse (thử theo thứ tự):**

   **Pattern 1 — all-in-one line:**
   ```
   Cà phê sữa đá       2    25.000   50.000
   ```
   Regex: `r"^(.+?)\s{2,}(\d+(?:[.,]\d+)?)\s+([\d.,]+)\s+([\d.,]+)\s*$"`

   **Pattern 2 — tên + dòng số:**
   ```
   Cà phê sữa đá
   2 x 25.000         50.000
   ```
   Regex dòng số: `r"(\d+(?:[.,]\d+)?)\s*[xX×]\s*([\d.,]+)\s+([\d.,]+)"`

   **Pattern 3 — tên + amount (không có qty/unit_price):**
   ```
   Bánh mì thịt nướng                    35.000
   ```
   Regex: `r"^(.+?)\s{3,}([\d.,]+(?:đ|₫)?)\s*$"`

4. Gọi `normalize_money()` cho tất cả giá trị số
5. **Sanity check:** Nếu `qty > 0` và `unit_price > 0` và `amount == 0`: tính `amount = qty * unit_price`

---

### Task 9 — Tạo `src/rules/totals.py`

**Hàm `extract_totals(lines: list[str]) -> dict`:**

```python
{
    "subtotal": float, "discount": float,
    "vat_rate": float, "vat_amount": float,
    "total": float, "currency": str,
    "payment_method": str | None,
}
```

Logic:

1. Scan từ **cuối file lên** (totals thường ở cuối)
2. Với mỗi dòng, so sánh (case-insensitive, bỏ dấu) với keyword dict
3. Extract số tiền cuối dòng: `r"([\d.,]+)\s*(?:đ|₫|VND|vnd)?\s*$"`
4. **VAT rate:** Tìm `%` trên dòng VAT: `r"(\d+(?:\.\d+)?)\s*%"`
5. **Phân biệt subtotal vs total:** Nếu có cả hai → số lớn hơn là `total`, số nhỏ hơn là `subtotal`
6. **Currency:** Scan toàn bộ bill với `CURRENCY_MAP`, mặc định `"VND"`
7. **Payment method:** Match với `PAYMENT_KEYWORDS`

---

### Task 10 — Tạo `src/extractor.py`

Orchestrator gọi tất cả module theo thứ tự:

```python
def extract_receipt(image_path: str) -> tuple[ReceiptData, str]:
    """
    Full pipeline: image → ReceiptData.
    Returns (data, raw_ocr_text).
    """
    processed_path = preprocess(image_path)
    raw_text = run_ocr(processed_path)
    cleaned_text = clean_text(raw_text)
    lines = [l for l in cleaned_text.splitlines() if l.strip()]

    header = extract_header(lines)
    items  = extract_items(lines)
    totals = extract_totals(lines)

    data = ReceiptData(
        merchant=header.get("merchant"),
        address=header.get("address"),
        date=header.get("date"),
        time=header.get("time"),
        items=items,
        **totals,
    )
    return data, raw_text
```

---

### Task 11 — Tạo `src/validator.py`

**Hàm `validate(data: ReceiptData) -> tuple[ReceiptData, list[str], float]`:**

Validation rules:

1. **Items sum:** `items_total = sum(item.amount for item in data.items)`
    - Nếu `subtotal == 0` và `items_total > 0`: auto-fill subtotal
    - Nếu `|items_total - subtotal| > 500`: thêm issue

2. **VAT:**
    - Nếu `vat_rate > 0` và `subtotal > 0` và `vat_amount == 0`: tính `vat_amount = round(subtotal * vat_rate / 100)`
    - Nếu `vat_amount > 0` và `vat_rate == 0` và `subtotal > 0`: tính ngược `vat_rate = round(vat_amount / subtotal * 100, 1)`
    - Nếu lệch > 500: thêm issue

3. **Total:** `expected = subtotal + vat_amount - discount`
    - Nếu `total == 0`: auto-fill
    - Nếu `|total - expected| > 500`: thêm issue

4. **Confidence score:**
   ```python
   score = 0.0
   if data.merchant:     score += 0.10
   if data.date:         score += 0.10
   if data.items:        score += 0.30
   if data.total > 0:    score += 0.20
   if data.subtotal > 0: score += 0.10
   if not issues:        score += 0.20
   ```

---

### Task 12 — Tạo `main.py`

**Endpoints:**

#### `GET /health`
```json
{"status": "ok", "tesseract_version": "5.x.x", "languages": ["eng", "vie"], "ocr_engine": "tesseract"}
```

#### `POST /extract`
- `file: UploadFile` (JPG/PNG/WEBP, max 15MB)
- Query param: `?debug=false`
- Trả về `ReceiptResponse`
- HTTP 422 nếu ảnh lỗi, HTTP 503 nếu Tesseract không tìm thấy
- Xóa file tạm trong `finally`

#### `POST /extract/base64`
- Body: `{"image": "<base64>", "filename": "receipt.jpg", "debug": false}`
- Dành cho Android gửi ảnh dạng base64

CORS: `allow_origins=["*"]`

---

### Task 13 — Tạo `cli.py`

```bash
python cli.py receipt.jpg
python cli.py receipt.jpg --debug
python cli.py receipt.jpg --output result.json
```

- Dùng `argparse`
- JSON ra stdout với `indent=2, ensure_ascii=False`
- Issues + confidence ra stderr
- Exit code 0/1

---

### Task 14 — Tạo tests

#### `tests/test_cleaner.py`
```python
def test_normalize_vnd_dot_separator():       # "1.500.000" → 1500000.0
def test_normalize_comma_separator():         # "25,000" → 25000.0
def test_normalize_suffix_k():                # "150K" → 150000.0
def test_normalize_strips_currency():         # "50.000đ" → 50000.0
def test_clean_preserves_vietnamese():        # "Cà phê sữa đá" không bị xoá dấu
def test_clean_removes_garbage():             # "|||@@#" bị loại
```

#### `tests/test_rules_items.py`
```python
def test_parse_single_line_item():            # "Cà phê  2  25.000  50.000"
def test_parse_multiline_item():              # "Bánh mì\n1 x 35.000  35.000"
def test_parse_name_amount_only():            # "Nước suối         10.000"
def test_skip_separator_lines():              # "---" bị bỏ qua
def test_skip_total_lines():                  # "Tổng cộng 100.000" không thành item
```

#### `tests/test_rules_totals.py`
```python
def test_extract_total_vietnamese():          # "Tổng thanh toán: 150.000đ"
def test_extract_vat_with_rate():             # "Thuế GTGT (10%): 13.636"
def test_extract_discount():                  # "Giảm giá: 10.000"
def test_extract_total_english():             # "Grand Total: 250,000"
def test_extract_subtotal_and_total():        # phân biệt đúng subtotal vs total
```

#### `tests/test_validator.py`
```python
def test_autofill_total():                    # subtotal+vat → total được tính tự động
def test_autofill_vat_amount():               # vat_rate=10, subtotal=100000 → vat_amount=10000
def test_autofill_vat_rate():                 # tính ngược rate từ amount
def test_confidence_full_data():              # data đầy đủ → confidence >= 0.7
def test_confidence_minimal_data():           # chỉ có total → confidence thấp
```

---

## Thứ tự thực hiện

```
1.  requirements.txt
2.  config/__init__.py
3.  config/keywords.py
4.  src/__init__.py
5.  src/models.py
6.  src/preprocess.py
7.  src/ocr.py
8.  src/cleaner.py
9.  src/rules/__init__.py
10. src/rules/header.py
11. src/rules/items.py
12. src/rules/totals.py
13. src/extractor.py
14. src/validator.py
15. main.py
16. cli.py
17. tests/test_cleaner.py
18. tests/test_rules_items.py
19. tests/test_rules_totals.py
20. tests/test_validator.py
21. docs/regex_patterns.md
```

---

## Lệnh chạy sau khi Codex hoàn thành

```bash
# 1. Kiểm tra Tesseract
tesseract --list-langs          # phải có: eng, vie

# 2. Cài dependencies
pip install -r requirements.txt

# 3. Chạy unit tests
python -m pytest tests/ -v

# 4. Test CLI
python cli.py tests/samples/receipt.jpg --debug

# 5. Chạy API
uvicorn main:app --host 0.0.0.0 --port 8000 --reload

# 6. Test API
curl -X POST http://localhost:8000/extract \
  -F "file=@tests/samples/receipt.jpg"

# 7. Health check
curl http://localhost:8000/health
```

---

## Ràng buộc kỹ thuật

| Tham số | Giá trị |
|---|---|
| Python | ≥ 3.10 |
| Tesseract | ≥ 4.1 (LSTM engine, oem 3) |
| OCR language | `vie+eng` (mặc định) |
| Tesseract PSM | 6 (uniform block), fallback 4 nếu output < 20 ký tự |
| Max image upload | 15MB |
| Max image dimension | resize về 2000px cạnh dài |
| Min image dimension | cảnh báo nếu cạnh ngắn < 300px |
| API port | 8000 |
| Confidence warn threshold | < 0.4 |

---

## Biến môi trường (tùy chọn)

```bash
export TESSERACT_CMD=/usr/bin/tesseract
export OCR_LANG=vie+eng
export OCR_PSM=6
export MAX_IMAGE_PX=2000
export API_PORT=8000
```

---

## Ghi chú cho Codex

- **Không** dùng AI API, LLM, cloud service, Docling, EasyOCR, PaddleOCR
- Chỉ dùng **Tesseract + regex + keyword matching thuần Python**
- Tất cả hàm phải **stateless**
- Encoding **UTF-8** toàn bộ — đặc biệt quan trọng cho tiếng Việt
- Dùng `pathlib.Path` thay `os.path`
- Mỗi module có **docstring** mô tả chức năng
- Không hardcode đường dẫn tuyệt đối — dùng `Path(__file__).parent`
- Xử lý `finally` để xóa file tạm dù thành công hay lỗi