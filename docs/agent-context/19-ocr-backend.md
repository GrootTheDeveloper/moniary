# OCR Backend Integration

**Confidence / Verification Status**: `VERIFIED AGAINST SOURCE`
**Last source audit**: `2026-07-10`

The OCR backend in `backend/ocr` uses Tesseract, OpenCV, regex, and keyword
matching. It does not use Ollama, an LLM, a cloud OCR API, or another AI model.

## Install system dependencies

macOS:

```bash
brew install tesseract tesseract-lang
```

Ubuntu/Debian:

```bash
sudo apt update
sudo apt install tesseract-ocr tesseract-ocr-vie tesseract-ocr-eng
```

Verify both languages are available:

```bash
tesseract --version
tesseract --list-langs
```

## Start FastAPI

```bash
cd backend/ocr
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
uvicorn main:app --host 0.0.0.0 --port 8000
```

Optional environment variables:

```bash
export TESSERACT_CMD=/usr/bin/tesseract
export OCR_LANG=vie+eng
export OCR_PSM=6
export MAX_IMAGE_PX=2000
```

## API

- `GET /health`: Tesseract version and installed languages.
- `POST /extract`: multipart image field named `file`.
- `POST /extract?debug=true`: also returns raw Tesseract text.
- Responses include `field_confidence`, `processing_ms`, and a stable
  `suggested_category` key when the local keyword classifier has a match.
- `POST /extract/base64`: accepts base64 image JSON.
- Supported images: JPEG, PNG, WEBP, maximum 15 MB.

The app now defaults to the Azure Container Apps OCR endpoint. Local Android
emulator development can override it with `http://10.0.2.2:8000`; any hosted
backend can be selected with:

```bash
flutter run --dart-define=OCR_API_URL=https://your-ocr-api.example.com
```

## Verify

```bash
cd backend/ocr
pytest
python cli.py ../../receipt_1.jpg --debug
curl http://localhost:8000/health
curl -X POST http://localhost:8000/extract \
  -F "file=@../../receipt_1.jpg"
```
