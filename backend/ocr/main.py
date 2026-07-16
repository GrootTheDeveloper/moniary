"""FastAPI entrypoint for modular server-side receipt OCR."""

import base64
import asyncio
import binascii
import mimetypes
import os
import time
import uuid
from pathlib import Path
from typing import Annotated

from fastapi import Depends, FastAPI, File, HTTPException, Query, UploadFile
from fastapi.concurrency import run_in_threadpool
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from pydantic import BaseModel, Field

from security import authorize_ocr_request, positive_float_env, positive_int_env
from src.extractor import extract_receipt_with_metadata
from src.models import ReceiptResponse
from src.ocr import ocr_health
from src.validator import field_confidence, validate


MAX_FILE_SIZE_MB = positive_int_env("OCR_MAX_FILE_MB", 15)
MAX_FILE_SIZE = MAX_FILE_SIZE_MB * 1024 * 1024
MAX_BASE64_SIZE = ((MAX_FILE_SIZE + 2) // 3) * 4 + 128
MAX_CONCURRENT_OCR = positive_int_env("OCR_MAX_CONCURRENT", 2)
OCR_QUEUE_TIMEOUT_SECONDS = positive_float_env("OCR_QUEUE_TIMEOUT_SECONDS", 2)
ALLOW_DEBUG = os.getenv("OCR_ALLOW_DEBUG", "false").lower() == "true"
ACCEPTED_MIME_TYPES = {"image/jpeg", "image/png", "image/webp"}
MIME_EXTENSIONS = {
    "image/jpeg": ".jpg",
    "image/png": ".png",
    "image/webp": ".webp",
}

app = FastAPI(
    title="Receipt OCR API",
    description="Receipt extraction using a configurable OCR engine and regex",
    version="2.0.0",
)
app.add_middleware(
    CORSMiddleware,
    allow_origins=[
        origin.strip()
        for origin in os.getenv("OCR_ALLOWED_ORIGINS", "").split(",")
        if origin.strip()
    ],
    allow_methods=["GET", "POST"],
    allow_headers=["Authorization", "Content-Type"],
)

_ocr_slots = asyncio.Semaphore(MAX_CONCURRENT_OCR)


class Base64ImageRequest(BaseModel):
    image: str = Field(min_length=1, max_length=MAX_BASE64_SIZE)
    filename: str = "receipt.jpg"
    debug: bool = False


def _error_response(status_code: int, error: str) -> JSONResponse:
    payload = ReceiptResponse(success=False, error=error)
    return JSONResponse(
        status_code=status_code,
        content=payload.model_dump(mode="json"),
    )


def _write_temp_image(content: bytes, mime_type: str) -> Path:
    if len(content) > MAX_FILE_SIZE:
        raise HTTPException(
            status_code=413,
            detail=f"File exceeds {MAX_FILE_SIZE_MB}MB limit",
        )
    if not content:
        raise HTTPException(status_code=422, detail="Image file is empty")
    if mime_type not in ACCEPTED_MIME_TYPES:
        raise HTTPException(
            status_code=415,
            detail="Only JPEG, PNG, and WEBP images are accepted",
        )

    path = Path("/tmp") / (
        f"receipt_upload_{uuid.uuid4().hex}{MIME_EXTENSIONS[mime_type]}"
    )
    path.write_bytes(content)
    return path


def _mime_from_payload(payload: str, filename: str) -> tuple[str, str]:
    image_data = payload.strip()
    mime_type = mimetypes.guess_type(filename)[0]
    if image_data.startswith("data:") and "," in image_data:
        header, image_data = image_data.split(",", 1)
        mime_type = header[5:].split(";", 1)[0]
    if mime_type not in ACCEPTED_MIME_TYPES:
        raise HTTPException(
            status_code=415,
            detail="Only JPEG, PNG, and WEBP images are accepted",
        )
    return image_data, mime_type


def _process_image(image_path: Path, debug: bool) -> ReceiptResponse:
    started_at = time.perf_counter()
    extracted = extract_receipt_with_metadata(str(image_path))
    validated, issues, confidence = validate(extracted.data)
    return ReceiptResponse(
        success=True,
        data=validated,
        raw_text=extracted.raw_text if debug else None,
        ocr_engine=extracted.ocr_engine,
        ocr_lines=extracted.ocr_lines if debug else None,
        validation_issues=issues,
        confidence=confidence,
        field_confidence=field_confidence(validated, issues),
        processing_ms=round((time.perf_counter() - started_at) * 1000),
    )


async def _process_image_with_capacity(
    image_path: Path,
    debug: bool,
) -> ReceiptResponse:
    try:
        await asyncio.wait_for(
            _ocr_slots.acquire(),
            timeout=OCR_QUEUE_TIMEOUT_SECONDS,
        )
    except TimeoutError as exc:
        raise HTTPException(
            status_code=503,
            detail="OCR capacity is temporarily exhausted",
        ) from exc
    try:
        return await run_in_threadpool(_process_image, image_path, debug)
    finally:
        _ocr_slots.release()


def _validate_debug_access(debug: bool) -> None:
    if debug and not ALLOW_DEBUG:
        raise HTTPException(
            status_code=403,
            detail="Raw OCR debug output is disabled",
        )


@app.get("/health")
def health() -> dict[str, object]:
    return ocr_health()


@app.post("/extract", response_model=ReceiptResponse)
async def extract(
    _user_id: Annotated[str, Depends(authorize_ocr_request)],
    file: UploadFile = File(...),
    debug: bool = Query(False),
) -> ReceiptResponse | JSONResponse:
    _validate_debug_access(debug)
    if file.content_type not in ACCEPTED_MIME_TYPES:
        raise HTTPException(
            status_code=415,
            detail="Only JPEG, PNG, and WEBP images are accepted",
        )

    temp_path: Path | None = None
    try:
        content = await file.read(MAX_FILE_SIZE + 1)
        temp_path = _write_temp_image(content, file.content_type)
        return await _process_image_with_capacity(temp_path, debug)
    except HTTPException:
        raise
    except ValueError as exc:
        return _error_response(422, str(exc))
    except RuntimeError as exc:
        return _error_response(503, str(exc))
    finally:
        if temp_path:
            temp_path.unlink(missing_ok=True)
        await file.close()


@app.post("/extract/base64", response_model=ReceiptResponse)
async def extract_base64(
    request: Base64ImageRequest,
    _user_id: Annotated[str, Depends(authorize_ocr_request)],
) -> ReceiptResponse | JSONResponse:
    _validate_debug_access(request.debug)
    temp_path: Path | None = None
    try:
        image_data, mime_type = _mime_from_payload(
            request.image,
            request.filename,
        )
        try:
            content = base64.b64decode(image_data, validate=True)
        except (binascii.Error, ValueError) as exc:
            raise HTTPException(
                status_code=400,
                detail="Invalid base64 image payload",
            ) from exc
        temp_path = _write_temp_image(content, mime_type)
        return await _process_image_with_capacity(
            temp_path,
            request.debug,
        )
    except HTTPException:
        raise
    except ValueError as exc:
        return _error_response(422, str(exc))
    except RuntimeError as exc:
        return _error_response(503, str(exc))
    finally:
        if temp_path:
            temp_path.unlink(missing_ok=True)
