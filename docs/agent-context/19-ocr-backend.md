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

Required hosted environment variables:

```bash
export SUPABASE_URL=https://your-project-ref.supabase.co
export SUPABASE_ANON_KEY=your-publishable-or-anon-key
```

The OCR service uses these public project values to resolve the mobile bearer
session through `GET /auth/v1/user`; do not configure a service-role key.

Optional environment variables:

```bash
export TESSERACT_CMD=/usr/bin/tesseract
export OCR_LANG=vie+eng
export OCR_PSM=6
export MAX_IMAGE_PX=2000
export OCR_MAX_FILE_MB=15
export OCR_REQUESTS_PER_MINUTE=10
export OCR_MAX_CONCURRENT=2
export OCR_QUEUE_TIMEOUT_SECONDS=2
export OCR_ALLOWED_ORIGINS=https://your-web-client.example.com
# Local diagnostics only; leave false in hosted environments.
export OCR_ALLOW_DEBUG=false
```

## API

- `GET /health`: Tesseract version and installed languages.
- `POST /extract`: multipart image field named `file`; requires
  `Authorization: Bearer <SUPABASE_ACCESS_TOKEN>`.
- `POST /extract?debug=true`: also returns raw Tesseract text only when the
  server explicitly sets `OCR_ALLOW_DEBUG=true`.
- Responses include `field_confidence`, `processing_ms`, and a stable
  `suggested_category` key when the local keyword classifier has a match.
- `POST /extract/base64`: accepts base64 image JSON.
- Supported images: JPEG, PNG, WEBP, maximum 15 MB by default.
- Extraction is limited per authenticated user and by a process-wide OCR
  semaphore. Configure an Azure ingress/gateway rate limit as the additional
  cross-replica layer when scaling beyond one container replica.

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

Deploy the secured OCR container and set its two required Supabase variables
before distributing a mobile build containing this client change. An older
container may still accept the bearer header while silently leaving the
endpoint public, so a successful scan alone does not prove the security update
was deployed; an unauthenticated request must return HTTP 401.

## Azure Container Apps deployment

`azure.yaml` defines `backend/ocr` as the `ocr` Container Apps service. Use the
team's existing `azd` environment; do not create a second production
environment accidentally.

```bash
azd auth login
azd env select <team-environment>
azd env set SUPABASE_URL https://<same-project-as-mobile-env>.supabase.co
azd env set SUPABASE_ANON_KEY <same-public-anon-or-publishable-key-as-mobile-env>
azd env set OCR_ALLOW_DEBUG false
azd env set OCR_REQUESTS_PER_MINUTE 10
azd env set OCR_MAX_CONCURRENT 2
azd env set OCR_QUEUE_TIMEOUT_SECONDS 2
azd deploy ocr
```

Set `OCR_ALLOWED_ORIGINS` only to explicit HTTPS web origins when a browser
client is enabled. Native Android/iOS clients do not require a permissive CORS
origin. After deploy, test `/health`, then make a multipart `POST /extract`
without `Authorization`; it must return HTTP 401 before any image processing.
