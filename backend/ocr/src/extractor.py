"""Orchestrate preprocessing, OCR, cleanup, and rule extraction."""

from pathlib import Path

from src.cleaner import clean_text
from src.classifier import classify_category
from src.models import ReceiptData
from src.ocr import run_ocr
from src.preprocess import preprocess
from src.rules.header import extract_header
from src.rules.items import extract_items
from src.rules.totals import extract_totals


def extract_receipt(image_path: str) -> tuple[ReceiptData, str]:
    """Run the complete rule-based OCR pipeline."""
    processed_path: str | None = None
    try:
        processed_path = preprocess(image_path)
        raw_text = run_ocr(processed_path, fallback_image_path=image_path)
        cleaned_text = clean_text(raw_text)
        lines = [line for line in cleaned_text.splitlines() if line.strip()]

        header = extract_header(lines)
        items = extract_items(lines)
        totals = extract_totals(lines)
        suggested_category, _ = classify_category(header.get("merchant"), items)
        data = ReceiptData(
            merchant=header.get("merchant"),
            address=header.get("address"),
            date=header.get("date"),
            time=header.get("time"),
            items=items,
            suggested_category=suggested_category,
            **totals,
        )
        return data, raw_text
    finally:
        if processed_path:
            Path(processed_path).unlink(missing_ok=True)
