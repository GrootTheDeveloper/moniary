# OCR Backend Integration

**Confidence / Verification Status**: `VERIFIED AGAINST SOURCE`
**Last source audit**: `2026-07-10`

The OCR backend in `backend/ocr` uses Tesseract, OpenCV, regex, and keyword
matching as its deterministic foundation. When configured, Gemini receives the
cleaned OCR text and rule candidates to normalize field meaning. The original
image is not sent to Gemini, and provider failure falls back to rules.

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

Required hosted environment variables:

```bash
export SUPABASE_URL=https://your-project-ref.supabase.co
export SUPABASE_ANON_KEY=your-publishable-or-anon-key
export GEMINI_API_KEY=your-server-only-key
```

The two Supabase public project values are used only to resolve the mobile
bearer session through `GET /auth/v1/user`; never configure a service-role key.
`GEMINI_API_KEY` is required for semantic enrichment but OCR still falls back
to deterministic extraction when the provider is temporarily unavailable.

Optional environment variables:

```bash
export TESSERACT_CMD=/usr/bin/tesseract
export OCR_LANG=vie+eng
export OCR_PSM=6
export MAX_IMAGE_PX=2000
export GEMINI_MODEL=gemini-2.5-flash
export GEMINI_BLOCKED_KEY_SHA256=
export OCR_LLM_ENABLED=true
export OCR_LLM_TIMEOUT_SECONDS=8
export OCR_MAX_FILE_MB=15
export OCR_REQUESTS_PER_MINUTE=10
export OCR_MAX_CONCURRENT=2
export OCR_QUEUE_TIMEOUT_SECONDS=2
export OCR_ALLOW_DEBUG=false
```

## API

- `GET /health`: Tesseract version and installed languages.
- `POST /extract`: multipart image field named `file`; requires
  `Authorization: Bearer <SUPABASE_ACCESS_TOKEN>`.
- `POST /extract?debug=true`: also returns raw Tesseract text.
- Responses include `field_confidence`, `field_sources`, `extraction_method`,
  `processing_ms`, and a stable `suggested_category` key. `field_sources`
  identifies values normalized by Gemini so Flutter can preserve suggestion
  provenance.
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
  -H "Authorization: Bearer $SUPABASE_ACCESS_TOKEN" \
  -F "file=@../../receipt_1.jpg"
```

## Azure Container Apps deployment

Use the existing team `azd` environment. Do not create a second Container Apps
environment. The Bicep templates inject Supabase/Gemini values into the current
Container App and keep keys as Container App secrets.

```bash
azd auth login
azd env select <team-environment>
azd env set SUPABASE_URL https://<project>.supabase.co
azd env set SUPABASE_ANON_KEY <public-anon-or-publishable-key>
azd env set GEMINI_API_KEY <server-only-gemini-key>
azd provision
azd deploy ocr
```

After deployment, `/health` must report `llm_enrichment: gemini`. A multipart
`POST /extract` without `Authorization` must return HTTP 401; then verify a scan
from a signed-in account returns `extraction_method: ocr+gemini`. `azd deploy`
alone updates the image but does not apply changed Bicep environment settings.
