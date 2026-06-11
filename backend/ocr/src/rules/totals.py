"""Rules for subtotal, VAT, discount, total, currency, and payment."""

import re

from config.keywords import (
    DISCOUNT_KEYWORDS,
    PAYMENT_KEYWORDS,
    SUBTOTAL_KEYWORDS,
    TOTAL_KEYWORDS,
    VAT_KEYWORDS,
)
from src.cleaner import normalize_money, remove_diacritics


ENDING_AMOUNT_PATTERN = re.compile(
    r"(?:[$₫]\s*)?(-?[\d.,]+)\s*(?:đ|₫|VND|USD)?\s*$",
    re.IGNORECASE,
)
VAT_RATE_PATTERN = re.compile(r"(\d+(?:[.,]\d+)?)\s*%")


def _normalized(text: str) -> str:
    return remove_diacritics(text).casefold()


def _contains(line: str, keywords: list[str]) -> bool:
    normalized = _normalized(line)
    return any(_normalized(keyword) in normalized for keyword in keywords)


def _ending_amount(line: str) -> float | None:
    match = ENDING_AMOUNT_PATTERN.search(line)
    if not match:
        return None
    try:
        return abs(normalize_money(match.group(1)))
    except ValueError:
        return None


def _detect_currency(lines: list[str]) -> str:
    joined = "\n".join(lines).casefold()
    normalized = _normalized(joined)
    for marker in ("$", "usd"):
        if marker in joined:
            return "USD"
    for marker in ("₫", "vnd", "vnđ", "dong"):
        target = _normalized(marker)
        if marker == "₫" and marker in joined:
            return "VND"
        if re.search(rf"\b{re.escape(target)}\b", normalized):
            return "VND"
    if re.search(r"(?<![^\W\d_])đ(?![^\W\d_])", joined):
        return "VND"
    return "VND"


def _detect_payment(lines: list[str]) -> str | None:
    normalized = _normalized("\n".join(lines))
    for method, keywords in PAYMENT_KEYWORDS.items():
        if any(_normalized(keyword) in normalized for keyword in keywords):
            return method
    return None


def extract_totals(lines: list[str]) -> dict[str, object]:
    """Extract totals by scanning receipt lines from bottom to top."""
    subtotal = 0.0
    discount = 0.0
    vat_rate = 0.0
    vat_amount = 0.0
    total = 0.0

    for line in reversed(lines):
        amount = _ending_amount(line)
        if _contains(line, DISCOUNT_KEYWORDS):
            if amount is not None and discount == 0:
                discount = amount
            continue
        if _contains(line, VAT_KEYWORDS):
            if amount is not None and vat_amount == 0:
                vat_amount = amount
            rate_match = VAT_RATE_PATTERN.search(line)
            if rate_match and vat_rate == 0:
                vat_rate = float(rate_match.group(1).replace(",", "."))
            continue
        if _contains(line, SUBTOTAL_KEYWORDS):
            if amount is not None and subtotal == 0:
                subtotal = amount
            continue
        if _contains(line, TOTAL_KEYWORDS):
            if amount is not None and total == 0:
                total = amount

    if subtotal > 0 and total > 0 and subtotal > total:
        subtotal, total = total, subtotal

    return {
        "subtotal": subtotal,
        "discount": discount,
        "vat_rate": vat_rate,
        "vat_amount": vat_amount,
        "total": total,
        "currency": _detect_currency(lines),
        "payment_method": _detect_payment(lines),
    }
