"""Fast keyword classifier for supported Moniary expense categories."""

import re
import unicodedata

from src.models import ReceiptItem


CATEGORY_KEYWORDS: dict[str, tuple[str, ...]] = {
    "food": (
        "cafe", "coffee", "restaurant", "quan an", "tra sua", "banh mi",
        "com", "pho", "bun", "nuoc", "highlands", "phuc long", "starbucks",
    ),
    "transport": (
        "taxi", "grab", "be car", "xanh sm", "parking", "giu xe", "xang",
        "petrol", "fuel", "bus",
    ),
    "shopping": (
        "supermarket", "sieu thi", "mart", "store", "shop", "fashion",
        "clothing", "guardian", "watsons", "circle k", "winmart", "coopmart",
    ),
}


def _normalize(value: str) -> str:
    decomposed = unicodedata.normalize("NFD", value.lower())
    ascii_text = "".join(
        character
        for character in decomposed
        if unicodedata.category(character) != "Mn"
    )
    return re.sub(r"[^a-z0-9]+", " ", ascii_text).strip()


def _contains_phrase(text: str, phrase: str) -> bool:
    return f" {phrase} " in f" {text} "


def classify_category(
    merchant: str | None,
    items: list[ReceiptItem],
) -> tuple[str | None, float]:
    """Return a stable category key and a conservative confidence score."""
    merchant_text = _normalize(merchant or "")
    item_text = _normalize(" ".join(item.name for item in items))
    scores: dict[str, int] = {}
    for category, keywords in CATEGORY_KEYWORDS.items():
        score = 0
        for keyword in keywords:
            normalized_keyword = _normalize(keyword)
            if _contains_phrase(merchant_text, normalized_keyword):
                score += 3
            if _contains_phrase(item_text, normalized_keyword):
                score += 1
        scores[category] = score

    category, score = max(scores.items(), key=lambda item: item[1])
    if score == 0:
        return None, 0.0
    confidence = min(0.55 + score * 0.08, 0.95)
    return category, round(confidence, 2)
