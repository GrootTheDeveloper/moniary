"""Orchestrate preprocessing, OCR, cleanup, and rule extraction."""

from dataclasses import dataclass
from pathlib import Path

from src.cleaner import clean_text
from src.classifier import classify_category
from src.models import OCRTextLine, ReceiptData, ReceiptItem
from src.ocr import recognize_image
from src.preprocess import preprocess
from src.rules.header import extract_header
from src.rules.items import extract_items
from src.rules.totals import extract_totals


@dataclass(frozen=True)
class ExtractedReceipt:
    data: ReceiptData
    raw_text: str
    ocr_engine: str
    ocr_lines: list[OCRTextLine]


def extract_receipt_with_metadata(image_path: str) -> ExtractedReceipt:
    """Run the complete OCR pipeline and keep engine/layout metadata."""
    processed_path: str | None = None
    try:
        processed_path = preprocess(image_path)
        ocr_result = recognize_image(
            processed_path,
            fallback_image_path=image_path,
        )
        raw_text = ocr_result.text
        cleaned_text = clean_text(raw_text)
        lines = [line for line in cleaned_text.splitlines() if line.strip()]

        header = extract_header(lines)
        items = [ReceiptItem.model_validate(item) for item in extract_items(lines)]
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
        return ExtractedReceipt(
            data=data,
            raw_text=raw_text,
            ocr_engine=ocr_result.engine,
            ocr_lines=[
                OCRTextLine(**line.to_dict())
                for line in ocr_result.lines
            ],
        )
    finally:
        if processed_path:
            Path(processed_path).unlink(missing_ok=True)


def extract_receipt(image_path: str) -> tuple[ReceiptData, str]:
    """Compatibility wrapper returning only structured data and raw text."""
    result = extract_receipt_with_metadata(image_path)
    return result.data, result.raw_text
