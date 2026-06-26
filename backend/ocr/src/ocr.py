"""Tesseract wrappers for plain text and word-level receipt OCR."""

import os
import re
import time
from pathlib import Path

from PIL import Image

try:
    import pytesseract
    from pytesseract import Output, TesseractNotFoundError
except ImportError:  # Allows rule unit tests before dependencies are installed.
    pytesseract = None
    Output = None

    class TesseractNotFoundError(RuntimeError):
        pass


OCR_LANG = os.getenv("OCR_LANG", "vie+eng")
OCR_PSM = int(os.getenv("OCR_PSM", "6"))
TESSERACT_CMD = os.getenv("TESSERACT_CMD")


def _configure_tesseract() -> None:
    if pytesseract is None:
        raise RuntimeError(
            "pytesseract is not installed. Run `pip install -r requirements.txt`."
        )
    if TESSERACT_CMD:
        pytesseract.pytesseract.tesseract_cmd = TESSERACT_CMD


def _config(psm: int) -> str:
    return f"--oem 3 --psm {psm} -l {OCR_LANG}"


def _not_found_error() -> RuntimeError:
    return RuntimeError(
        "Tesseract was not found. Install tesseract-ocr with the "
        "`vie` and `eng` language packs, or set TESSERACT_CMD."
    )


def _quality_score(text: str) -> int:
    normalized = text.casefold()
    non_empty_lines = [line for line in text.splitlines() if line.strip()]
    useful_characters = sum(
        character.isalnum() or character in ".,:$%₫"
        for character in text
    )
    item_lines = len(
        re.findall(r"(?im)^\s*\d+(?:[.,]\d+)?\s*[x×]\s+\S+", text)
    )
    score = useful_characters + len(non_empty_lines) * 5 + item_lines * 20
    if "total" in normalized or "tổng" in normalized:
        score += 30
    if "receipt" in normalized or "hóa đơn" in normalized:
        score += 30
    return score


def _ocr_image(image_path: str, psm: int) -> str:
    with Image.open(Path(image_path)) as image:
        return pytesseract.image_to_string(image, config=_config(psm))


def run_ocr(image_path: str, fallback_image_path: str | None = None) -> str:
    """Run Tesseract and select the best text from processed/original images."""
    _configure_tesseract()
    started_at = time.perf_counter()
    candidates: list[str] = []
    paths = [image_path]
    if fallback_image_path and Path(fallback_image_path) != Path(image_path):
        paths.append(fallback_image_path)

    try:
        for path in paths:
            raw_text = _ocr_image(path, OCR_PSM)
            if len(raw_text.strip()) < 20 and OCR_PSM != 4:
                raw_text = _ocr_image(path, 4)
            candidates.append(raw_text)
    except TesseractNotFoundError as exc:
        raise _not_found_error() from exc

    elapsed = time.perf_counter() - started_at
    print(f"OCR completed in {elapsed:.2f}s")
    return max(candidates, key=_quality_score, default="")


def run_ocr_with_layout(image_path: str) -> list[dict[str, object]]:
    """Return Tesseract word data, excluding entries below confidence 30."""
    _configure_tesseract()
    try:
        with Image.open(Path(image_path)) as image:
            result = pytesseract.image_to_data(
                image,
                config=_config(OCR_PSM),
                output_type=Output.DICT,
            )
    except TesseractNotFoundError as exc:
        raise _not_found_error() from exc

    words: list[dict[str, object]] = []
    for index, text in enumerate(result["text"]):
        try:
            confidence = float(result["conf"][index])
        except (TypeError, ValueError):
            confidence = -1
        normalized = str(text).strip()
        if normalized and confidence >= 30:
            words.append(
                {
                    "text": normalized,
                    "conf": confidence,
                    "left": int(result["left"][index]),
                    "top": int(result["top"][index]),
                    "width": int(result["width"][index]),
                    "height": int(result["height"][index]),
                    "line_num": int(result["line_num"][index]),
                    "block_num": int(result["block_num"][index]),
                }
            )
    return words


def tesseract_info() -> tuple[str | None, list[str]]:
    """Return the installed Tesseract version and language list."""
    _configure_tesseract()
    try:
        version = str(pytesseract.get_tesseract_version())
        languages = sorted(pytesseract.get_languages(config=""))
        return version, languages
    except TesseractNotFoundError as exc:
        raise _not_found_error() from exc
