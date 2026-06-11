"""Rules for extracting receipt line items."""

import re

from config.keywords import (
    DISCOUNT_KEYWORDS,
    SUBTOTAL_KEYWORDS,
    TOTAL_KEYWORDS,
    VAT_KEYWORDS,
)
from src.cleaner import normalize_money, normalize_quantity, remove_diacritics


ALL_IN_ONE_PATTERN = re.compile(
    r"^(.+?)\s{2,}(\d+(?:[.,]\d+)?)\s+"
    r"([$₫]?[\d.,]+)\s+([$₫]?[\d.,]+)\s*$"
)
MULTILINE_NUMBERS_PATTERN = re.compile(
    r"^(\d+(?:[.,]\d+)?)\s*[xX×]\s*"
    r"([$₫]?[\d.,]+)\s+([$₫]?[\d.,]+)\s*$"
)
NAME_AMOUNT_PATTERN = re.compile(
    r"^(.+?)\s{3,}(?:[$₫]\s*)?([\d.,]+)(?:\s*(?:đ|₫|VND|USD))?\s*$",
    re.IGNORECASE,
)
QUANTITY_NAME_PRICE_PATTERN = re.compile(
    r"^(\d+(?:[.,]\d+)?)\s*[xX×]\s+(.+?)\s+"
    r"(?:[$₫]\s*)?([\d.,]+)(?:\s*(?:đ|₫|VND|USD))?\s*$",
    re.IGNORECASE,
)
SEPARATOR_PATTERN = re.compile(r"^[\s\-_=.:]+$")

TOTAL_REGION_KEYWORDS = (
    SUBTOTAL_KEYWORDS + VAT_KEYWORDS + DISCOUNT_KEYWORDS + TOTAL_KEYWORDS
)


def _normalized(text: str) -> str:
    return remove_diacritics(text).casefold()


def _contains_keyword(line: str, keywords: list[str]) -> bool:
    normalized = _normalized(line)
    return any(_normalized(keyword) in normalized for keyword in keywords)


def _is_total_line(line: str) -> bool:
    return _contains_keyword(line, TOTAL_REGION_KEYWORDS)


def _valid_name(name: str) -> bool:
    stripped = name.strip(" :-")
    return len(stripped) >= 2 and any(character.isalpha() for character in stripped)


def extract_items(lines: list[str]) -> list[dict[str, object]]:
    """Extract line items using deterministic receipt patterns."""
    items: list[dict[str, object]] = []
    previous_name: str | None = None

    for raw_line in lines:
        line = raw_line.strip()
        if not line or len(line) < 3 or SEPARATOR_PATTERN.fullmatch(line):
            continue
        if _is_total_line(line):
            break

        quantity_name_match = QUANTITY_NAME_PRICE_PATTERN.match(line)
        if quantity_name_match:
            quantity = normalize_quantity(quantity_name_match.group(1))
            name = quantity_name_match.group(2).strip(" :-")
            amount = normalize_money(quantity_name_match.group(3))
            if _valid_name(name):
                items.append(
                    {
                        "name": name,
                        "qty": quantity,
                        "unit_price": amount / quantity if quantity else 0.0,
                        "amount": amount,
                    }
                )
                previous_name = None
                continue

        all_in_one_match = ALL_IN_ONE_PATTERN.match(line)
        if all_in_one_match:
            name = all_in_one_match.group(1).strip(" :-")
            if _valid_name(name):
                items.append(
                    {
                        "name": name,
                        "qty": normalize_quantity(all_in_one_match.group(2)),
                        "unit_price": normalize_money(all_in_one_match.group(3)),
                        "amount": normalize_money(all_in_one_match.group(4)),
                    }
                )
            previous_name = None
            continue

        multiline_match = MULTILINE_NUMBERS_PATTERN.match(line)
        if multiline_match and previous_name:
            quantity = normalize_quantity(multiline_match.group(1))
            unit_price = normalize_money(multiline_match.group(2))
            amount = normalize_money(multiline_match.group(3))
            items.append(
                {
                    "name": previous_name,
                    "qty": quantity,
                    "unit_price": unit_price,
                    "amount": amount or quantity * unit_price,
                }
            )
            previous_name = None
            continue

        name_amount_match = NAME_AMOUNT_PATTERN.match(line)
        if name_amount_match:
            name = name_amount_match.group(1).strip(" :-")
            if _valid_name(name):
                amount = normalize_money(name_amount_match.group(2))
                items.append(
                    {
                        "name": name,
                        "qty": 1.0,
                        "unit_price": amount,
                        "amount": amount,
                    }
                )
            previous_name = None
            continue

        normalized = _normalized(line)
        if (
            _valid_name(line)
            and not re.search(r"\d", line)
            and normalized not in {"receipt", "hoa don", "thank you", "cam on"}
        ):
            previous_name = line.strip(" :-")

    return items
