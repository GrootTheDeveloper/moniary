"""Arithmetic validation and confidence scoring for OCR results."""

from src.models import ReceiptData
from src.classifier import classify_category


MONEY_TOLERANCE = 500.0


def validate(data: ReceiptData) -> tuple[ReceiptData, list[str], float]:
    """Normalize derived totals and return issues with a confidence score."""
    normalized = data.model_copy(deep=True)
    issues: list[str] = []
    items_total = sum(item.amount for item in normalized.items)

    if normalized.subtotal == 0 and items_total > 0:
        normalized.subtotal = items_total
    elif (
        normalized.subtotal > 0
        and items_total > 0
        and abs(items_total - normalized.subtotal) > MONEY_TOLERANCE
    ):
        issues.append("Items total không khớp subtotal")

    if (
        normalized.vat_rate > 0
        and normalized.subtotal > 0
        and normalized.vat_amount == 0
    ):
        normalized.vat_amount = round(
            normalized.subtotal * normalized.vat_rate / 100,
            2,
        )
    elif (
        normalized.vat_amount > 0
        and normalized.vat_rate == 0
        and normalized.subtotal > 0
    ):
        normalized.vat_rate = round(
            normalized.vat_amount / normalized.subtotal * 100,
            1,
        )

    if normalized.vat_rate > 0 and normalized.subtotal > 0:
        expected_vat = normalized.subtotal * normalized.vat_rate / 100
        if abs(normalized.vat_amount - expected_vat) > MONEY_TOLERANCE:
            issues.append("VAT amount không khớp VAT rate")

    expected_total = (
        normalized.subtotal + normalized.vat_amount - normalized.discount
    )
    if normalized.total == 0 and expected_total > 0:
        normalized.total = expected_total
    elif (
        normalized.total > 0
        and expected_total > 0
        and abs(normalized.total - expected_total) > MONEY_TOLERANCE
    ):
        issues.append("Total không khớp subtotal + VAT - discount")

    score = 0.0
    if normalized.merchant:
        score += 0.10
    if normalized.date:
        score += 0.10
    if normalized.items:
        score += 0.30
    if normalized.total > 0:
        score += 0.20
    if normalized.subtotal > 0:
        score += 0.10
    if not issues:
        score += 0.20

    return normalized, issues, min(round(score, 2), 1.0)


def field_confidence(
    data: ReceiptData,
    issues: list[str],
) -> dict[str, float]:
    """Return conservative confidence per field for review UX decisions."""
    category, category_confidence = classify_category(data.merchant, data.items)
    total_has_issue = any(issue.startswith("Total ") for issue in issues)
    result: dict[str, float] = {}
    if data.merchant:
        result["merchant"] = 0.82
    if data.total > 0:
        result["total"] = 0.55 if total_has_issue else 0.94
    if data.date:
        result["date"] = 0.85
    if data.address:
        result["address"] = 0.70
    if data.items:
        result["items"] = 0.76 if not issues else 0.62
    if category and data.suggested_category == category:
        result["category"] = category_confidence
    return result
