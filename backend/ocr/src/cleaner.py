"""Text cleanup and locale-aware money normalization."""

import re
import unicodedata


OCR_FIXES = {
    "l0": "10",
    "O0": "00",
    "0O": "00",
    " |": " I",
    "| ": "I ",
    "rn": "m",
}
ALLOWED_PUNCTUATION = set(".,:-()/\\%+×xX$₫")


def remove_diacritics(text: str) -> str:
    """Remove combining marks while preserving the Vietnamese letter d."""
    normalized = unicodedata.normalize("NFD", text)
    without_marks = "".join(
        character
        for character in normalized
        if unicodedata.category(character) != "Mn"
    )
    return without_marks.replace("đ", "d").replace("Đ", "D")


def clean_text(raw: str) -> str:
    """Remove OCR noise while retaining Vietnamese and receipt punctuation."""
    cleaned = raw
    for source, replacement in OCR_FIXES.items():
        cleaned = cleaned.replace(source, replacement)

    output_lines: list[str] = []
    previous_blank = False
    for raw_line in cleaned.splitlines():
        line = "".join(
            character
            for character in raw_line
            if character.isalnum()
            or character.isspace()
            or character in ALLOWED_PUNCTUATION
            or unicodedata.category(character).startswith(("L", "M"))
        ).strip()
        if not line:
            if not previous_blank and output_lines:
                output_lines.append("")
            previous_blank = True
            continue
        output_lines.append(line)
        previous_blank = False

    while output_lines and not output_lines[-1]:
        output_lines.pop()
    return "\n".join(output_lines)


def normalize_money(text: str | int | float) -> float:
    """Parse Vietnamese/English formatted money into a float."""
    if isinstance(text, (int, float)):
        return float(text)

    value = str(text).strip().lower()
    multiplier = 1.0
    suffix_match = re.search(r"([km])\s*$", value, re.IGNORECASE)
    if suffix_match:
        multiplier = 1_000.0 if suffix_match.group(1).lower() == "k" else 1_000_000.0
        value = value[: suffix_match.start()]

    value = re.sub(r"(?:vnd|vnđ|usd|đ|₫|\$|dong)", "", value, flags=re.IGNORECASE)
    value = re.sub(r"\s+", "", value)
    value = re.sub(r"[^0-9,.\-]", "", value)
    if not value or value in {"-", ".", ","}:
        raise ValueError(f"Cannot parse money value: {text}")

    dot_count = value.count(".")
    comma_count = value.count(",")
    if dot_count and comma_count:
        decimal_separator = "." if value.rfind(".") > value.rfind(",") else ","
        thousands_separator = "," if decimal_separator == "." else "."
        value = value.replace(thousands_separator, "")
        value = value.replace(decimal_separator, ".")
    elif dot_count or comma_count:
        separator = "." if dot_count else ","
        parts = value.split(separator)
        if len(parts) > 2 or (len(parts) == 2 and len(parts[-1]) == 3):
            value = "".join(parts)
        else:
            value = ".".join(parts)

    try:
        return float(value) * multiplier
    except ValueError as exc:
        raise ValueError(f"Cannot parse money value: {text}") from exc


def normalize_quantity(text: str) -> float:
    """Parse a quantity independently from locale-specific money rules."""
    value = text.strip().replace(",", ".")
    return float(value)

