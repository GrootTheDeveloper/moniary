from src.models import ReceiptData, ReceiptItem
from src.validator import field_confidence, validate


def test_autofill_total():
    data, issues, _ = validate(
        ReceiptData(subtotal=100_000, vat_amount=10_000)
    )

    assert data.total == 110_000
    assert issues == []


def test_autofill_vat_amount():
    data, _, _ = validate(
        ReceiptData(subtotal=100_000, vat_rate=10)
    )

    assert data.vat_amount == 10_000


def test_autofill_vat_amount_preserves_decimals():
    data, _, _ = validate(
        ReceiptData(subtotal=99.95, vat_rate=7.5)
    )

    assert data.vat_amount == 7.5
    assert data.total == 107.45


def test_autofill_vat_rate():
    data, _, _ = validate(
        ReceiptData(subtotal=100_000, vat_amount=10_000)
    )

    assert data.vat_rate == 10


def test_autofill_subtotal_from_items():
    data, _, _ = validate(
        ReceiptData(
            items=[
                ReceiptItem(
                    name="Cà phê",
                    qty=2,
                    unit_price=25_000,
                    amount=50_000,
                )
            ]
        )
    )

    assert data.subtotal == 50_000
    assert data.total == 50_000


def test_validation_detects_total_mismatch():
    _, issues, _ = validate(
        ReceiptData(subtotal=100_000, vat_amount=10_000, total=150_000)
    )

    assert "Total không khớp subtotal + VAT - discount" in issues


def test_confidence_full_data():
    _, _, confidence = validate(
        ReceiptData(
            merchant="Cửa hàng",
            date="2026-06-10",
            items=[
                ReceiptItem(
                    name="Cà phê",
                    unit_price=100_000,
                    amount=100_000,
                )
            ],
            subtotal=100_000,
            total=100_000,
        )
    )

    assert confidence >= 0.7


def test_confidence_minimal_data():
    _, _, confidence = validate(ReceiptData(total=100_000))

    assert confidence < 0.5


def test_field_confidence_marks_total_mismatch_for_review():
    data, issues, _ = validate(ReceiptData(subtotal=100_000, total=150_000))
    confidence = field_confidence(data, issues)
    assert confidence["total"] < 0.75
