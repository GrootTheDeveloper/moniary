"""Rules for merchant, address, date, and time extraction."""

import re
from datetime import date

from config.keywords import ADDRESS_KEYWORDS
from src.cleaner import remove_diacritics


DATE_DMY_PATTERN = re.compile(
    r"(?<!\d)(\d{1,2})[/\-.](\d{1,2})[/\-.](\d{2,4})(?!\d)"
)
DATE_YMD_PATTERN = re.compile(
    r"(?<!\d)(\d{4})[/\-.](\d{1,2})[/\-.](\d{1,2})(?!\d)"
)
DATE_VI_PATTERN = re.compile(
    r"ng[aà]y\s+(\d{1,2})\s+th[aá]ng\s+(\d{1,2})\s+n[aă]m\s+(\d{4})",
    re.IGNORECASE,
)
TIME_PATTERN = re.compile(
    r"(?<!\d)(\d{1,2}):(\d{2})(?::\d{2})?(?:\s*(AM|PM))?(?!\d)",
    re.IGNORECASE,
)
ITEM_LINE_PATTERN = re.compile(
    r"^\s*\d+(?:[.,]\d+)?\s*[xX×]\s+\S+.*[\d.,]+\s*$"
)


def _normalized(text: str) -> str:
    return remove_diacritics(text).casefold()


def _contains_address_keyword(line: str) -> bool:
    normalized = _normalized(line)
    return any(_normalized(keyword) in normalized for keyword in ADDRESS_KEYWORDS)


def _iso_date(year: int, month: int, day: int) -> str | None:
    if year < 100:
        year += 2000
    try:
        return date(year, month, day).isoformat()
    except ValueError:
        return None


def _extract_date(line: str) -> str | None:
    match = DATE_YMD_PATTERN.search(line)
    if match:
        return _iso_date(
            int(match.group(1)),
            int(match.group(2)),
            int(match.group(3)),
        )

    match = DATE_DMY_PATTERN.search(line)
    if match:
        return _iso_date(
            int(match.group(3)),
            int(match.group(2)),
            int(match.group(1)),
        )

    match = DATE_VI_PATTERN.search(line)
    if match:
        return _iso_date(
            int(match.group(3)),
            int(match.group(2)),
            int(match.group(1)),
        )
    return None


def _extract_time(line: str) -> str | None:
    match = TIME_PATTERN.search(line)
    if not match:
        return None

    hour = int(match.group(1))
    minute = int(match.group(2))
    meridiem = (match.group(3) or "").upper()
    if minute > 59 or hour > 23:
        return None
    if meridiem:
        if not 1 <= hour <= 12:
            return None
        if meridiem == "AM" and hour == 12:
            hour = 0
        elif meridiem == "PM" and hour != 12:
            hour += 12
    return f"{hour:02d}:{minute:02d}"


def extract_header(lines: list[str]) -> dict[str, str | None]:
    """Extract header fields from the first ten non-empty OCR lines."""
    header_lines = [line.strip() for line in lines[:10] if line.strip()]
    merchant = None
    address = None
    extracted_date = None
    extracted_time = None

    for line in header_lines:
        if address is None and _contains_address_keyword(line):
            address = line
        if extracted_date is None:
            extracted_date = _extract_date(line)
        if extracted_time is None:
            extracted_time = _extract_time(line)

    for line in header_lines:
        if len(line) < 3 or line.replace(" ", "").isdigit():
            continue
        if _contains_address_keyword(line):
            continue
        if _extract_date(line) or _extract_time(line):
            continue
        if ITEM_LINE_PATTERN.match(line):
            continue
        merchant = line
        break

    return {
        "merchant": merchant,
        "address": address,
        "date": extracted_date,
        "time": extracted_time,
    }
