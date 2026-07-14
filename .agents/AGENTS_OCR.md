# AGENTS_OCR.md — Kiến Trúc Backend OCR

Tài liệu này mô tả kiến trúc cụ thể của `backend/ocr` sau khi đối chiếu với
`.agents/AGENTS_OCR_CONTRUCTION.md`.

## Phạm vi

`backend/ocr` triển khai nhánh **server-side OCR** của kiến trúc tổng thể:

```text
Android Camera/Photo Picker
  -> FastAPI upload/base64
  -> Image preprocessing
  -> OCR engine adapter
  -> Regex/rule extraction
  -> Validation response for UI confirmation
```

Các phần Android như CameraX, Photo Picker, crop UI, `OutlinedTextField` xác
thực và lưu database thuộc mobile client, không nằm trong package backend này.

## Kết luận đối chiếu

Backend hiện đã đi theo kiến trúc 5 bước trong file construction:

| Bước | Module backend | Trạng thái |
|---|---|---|
| 1. Thu thập ảnh | `main.py` nhận multipart hoặc base64 từ Android | Đúng phạm vi backend |
| 2. Tiền xử lý ảnh | `src/preprocess.py` | Đã có resize, deskew, grayscale, denoise, adaptive threshold, sharpen |
| 3. OCR engine | `src/ocr.py` | Đã tách engine adapter: `auto`, `paddleocr`, `tesseract` |
| 4. Regex trích xuất | `src/cleaner.py`, `src/rules/*`, `src/extractor.py` | Đã rule-based cho header, items, totals |
| 5. Hậu xử lý/xác thực | `src/validator.py`, `src/models.py`, API response | Đã chuẩn hóa JSON, issues, confidence, debug raw/layout |

Điểm lệch cũ đã được sửa: backend trước đây hardcode Tesseract và tài liệu cũ
ghi “không dùng PaddleOCR”. Kiến trúc hiện tại dùng **OCR engine adapter** để
hỗ trợ PaddleOCR server-side theo construction, đồng thời giữ Tesseract làm
fallback nhẹ cho local/dev.

## Cấu trúc thư mục

```text
backend/ocr/
├── main.py                       # FastAPI entrypoint
├── cli.py                        # CLI chạy pipeline cục bộ
├── requirements.txt              # dependencies cơ bản
├── requirements-paddle.txt       # optional PaddleOCR dependency
├── config/
│   └── keywords.py               # keyword VI/EN cho rules
├── src/
│   ├── models.py                 # Pydantic response/data schemas
│   ├── preprocess.py             # OpenCV preprocessing
│   ├── ocr.py                    # OCR adapter: PaddleOCR/Tesseract
│   ├── cleaner.py                # OCR text cleanup + money normalization
│   ├── extractor.py              # orchestrator pipeline
│   ├── validator.py              # arithmetic validation + confidence
│   └── rules/
│       ├── header.py             # merchant/address/date/time
│       ├── items.py              # receipt item rows
│       └── totals.py             # subtotal/VAT/discount/total/payment
├── tests/
└── docs/
    └── regex_patterns.md
```

## Pipeline chi tiết

### 1. Image Acquisition

Backend nhận ảnh từ mobile qua:

- `POST /extract`: multipart `file` cho JPG/PNG/WEBP, tối đa 15MB.
- `POST /extract/base64`: JSON `{ "image": "...", "filename": "...", "debug": false }`.

`main.py` ghi ảnh upload ra `/tmp/receipt_upload_<uuid>.<ext>` và luôn xóa file
tạm trong `finally`.

### 2. Image Preprocessing

`src/preprocess.py` nhận path ảnh gốc và tạo ảnh tạm đã xử lý:

- `cv2.imread()` và raise `ValueError` nếu ảnh lỗi.
- Resize cạnh dài về `MAX_IMAGE_PX` mặc định `2000`.
- Cảnh báo nếu cạnh ngắn dưới `300px`.
- `deskew()` bằng Canny + HoughLinesP + median angle.
- Grayscale, denoise bằng `fastNlMeansDenoising`.
- Adaptive threshold Gaussian.
- Sharpen bằng kernel `[[0,-1,0],[-1,5,-1],[0,-1,0]]`.
- Ghi `/tmp/receipt_<uuid8>.jpg` quality 95.

### 3. OCR Engine Adapter

`src/ocr.py` định nghĩa contract engine chung:

```python
OCRResult(
    text: str,
    lines: list[OCRLine],
    engine: str,
    elapsed_seconds: float,
)

OCRLine(
    text: str,
    confidence: float | None,
    bbox: list[list[float]] | None,
)
```

Engine được chọn bằng biến môi trường:

```bash
export OCR_ENGINE=auto       # mặc định: ưu tiên PaddleOCR nếu đã cài, fallback Tesseract
export OCR_ENGINE=paddleocr  # bắt buộc dùng PaddleOCR local
export OCR_ENGINE=tesseract  # dùng Tesseract local
```

PaddleOCR là engine server-side đúng với construction. Cài khi cần:

```bash
pip install -r requirements-paddle.txt
```

Tesseract vẫn được giữ để local/dev chạy nhẹ:

```bash
brew install tesseract tesseract-lang
export OCR_LANG=vie+eng
export OCR_PSM=6
```

Các hàm compatibility vẫn tồn tại:

- `run_ocr(image_path, fallback_image_path=None) -> str`
- `run_ocr_with_layout(image_path) -> list[dict]`
- `tesseract_info() -> tuple[str | None, list[str]]`

Luồng mới nên dùng:

- `recognize_image(image_path, fallback_image_path=None) -> OCRResult`
- `ocr_health() -> dict`

### 4. Regex/Rule Extraction

`src/extractor.py` là orchestrator:

```text
preprocess(image)
  -> recognize_image(processed, fallback_image)
  -> clean_text(raw_text)
  -> extract_header(lines)
  -> extract_items(lines)
  -> extract_totals(lines)
  -> ReceiptData
```

Rules hiện tại:

- `header.py`: merchant, address, date ISO `YYYY-MM-DD`, time `HH:MM`.
- `items.py`: all-in-one item line, multiline item, name + amount, quantity-name-price.
- `totals.py`: subtotal, VAT rate/amount, discount, total, currency, payment method.
- `cleaner.py`: bỏ noise OCR, giữ Unicode tiếng Việt, normalize tiền VND/USD.

Keyword matching không phân biệt hoa/thường và không phụ thuộc dấu tiếng Việt
nhờ `remove_diacritics()`.

### 5. Validation & API Response

`src/validator.py` thực hiện:

- Auto-fill subtotal từ tổng items nếu thiếu.
- Auto-fill VAT amount hoặc VAT rate khi có đủ dữ kiện.
- Auto-fill total từ `subtotal + vat_amount - discount`.
- Ghi `validation_issues` khi sai lệch quá `500`.
- Tính `confidence` từ merchant/date/items/total/subtotal/issues.

`ReceiptResponse` gồm:

```json
{
  "success": true,
  "data": {},
  "raw_text": null,
  "ocr_engine": "paddleocr",
  "ocr_lines": null,
  "validation_issues": [],
  "confidence": 0.8,
  "error": null
}
```

Khi `debug=true`, API trả thêm `raw_text` và `ocr_lines` gồm text, confidence,
bbox để mobile có thể highlight vùng OCR hoặc hỗ trợ màn hình xác thực.

## API

### `GET /health`

Trả engine đang được cấu hình và trạng thái dependency:

```json
{
  "requested_ocr_engine": "auto",
  "status": "ok",
  "ocr_engine": "paddleocr",
  "paddleocr_lang": "vi",
  "layout": "line_bbox"
}
```

Với Tesseract fallback, response có thêm `tesseract_version` và `languages`.

### `POST /extract`

- Input: multipart `file`.
- Query: `debug=false`.
- Output: `ReceiptResponse`.
- Lỗi ảnh không đọc được: response `success=false`, HTTP 422.
- OCR dependency thiếu: response `success=false`, HTTP 503.

### `POST /extract/base64`

- Input JSON: `image`, `filename`, `debug`.
- Dành cho Android khi gửi ảnh dạng base64.

## Biến môi trường

| Biến | Mặc định | Ý nghĩa |
|---|---:|---|
| `OCR_ENGINE` | `auto` | `auto`, `paddleocr`, hoặc `tesseract` |
| `PADDLEOCR_LANG` | `vi` | Ngôn ngữ PaddleOCR |
| `PADDLEOCR_USE_ANGLE_CLS` | `true` | Bật angle classifier nếu runtime hỗ trợ |
| `OCR_LANG` | `vie+eng` | Ngôn ngữ Tesseract fallback |
| `OCR_PSM` | `6` | Page segmentation mode của Tesseract |
| `TESSERACT_CMD` | unset | Đường dẫn binary Tesseract |
| `MAX_IMAGE_PX` | `2000` | Cạnh dài tối đa sau resize |

## Lệnh kiểm thử

```bash
cd backend/ocr
python -m pytest tests/ -q
python cli.py tests/samples/receipt.jpg --debug
uvicorn main:app --host 0.0.0.0 --port 8000 --reload
curl http://localhost:8000/health
```

## Acceptance Criteria chính

- Nhận dạng số tiền: `50000`, `50.000`, `50,000`, `50.000đ`, `50,000 VND`.
- Từ khóa tổng tiền chịu được viết hoa/thường và không dấu: `Tong cong`,
  `Tổng tiền`, `TOTAL AMOUNT`.
- Không crash khi không tìm thấy số tiền; response có `success=true` nhưng
  `total=0`/confidence thấp để mobile yêu cầu người dùng nhập tay.
- Debug mode trả raw OCR và line bbox để hỗ trợ màn hình xác thực.
- Không dùng LLM/cloud OCR API; PaddleOCR và Tesseract đều chạy local.
