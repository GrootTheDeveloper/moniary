"""Command-line interface for local receipt OCR testing."""

import argparse
import json
import sys
from pathlib import Path

from src.extractor import extract_receipt
from src.models import ReceiptResponse
from src.validator import validate


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        description="Extract receipt data using Tesseract and regex rules."
    )
    parser.add_argument("image", help="Path to a receipt image")
    parser.add_argument(
        "--debug",
        action="store_true",
        help="Include raw Tesseract text in the JSON response",
    )
    parser.add_argument("--output", help="Optional JSON output path")
    return parser


def main() -> int:
    args = build_parser().parse_args()
    try:
        data, raw_text = extract_receipt(args.image)
        validated, issues, confidence = validate(data)
        response = ReceiptResponse(
            success=True,
            data=validated,
            raw_text=raw_text if args.debug else None,
            validation_issues=issues,
            confidence=confidence,
        )
        output = json.dumps(
            response.model_dump(mode="json"),
            indent=2,
            ensure_ascii=False,
        )
        print(output)
        if args.output:
            Path(args.output).write_text(output + "\n", encoding="utf-8")

        print(f"Confidence: {confidence:.2f}", file=sys.stderr)
        for issue in issues:
            print(f"- {issue}", file=sys.stderr)
        return 0
    except Exception as exc:
        print(f"Error: {exc}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())

