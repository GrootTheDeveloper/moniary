from src.rules.totals import extract_totals


def test_extract_total_vietnamese():
    result = extract_totals(["Tổng thanh toán: 150.000đ"])

    assert result["total"] == 150_000.0
    assert result["currency"] == "VND"


def test_extract_vat_with_rate():
    result = extract_totals(["Thuế GTGT (10%): 13.636"])

    assert result["vat_rate"] == 10.0
    assert result["vat_amount"] == 13_636.0


def test_extract_discount():
    result = extract_totals(["Giảm giá: 10.000"])

    assert result["discount"] == 10_000.0


def test_extract_total_english():
    result = extract_totals(["Grand Total: 250,000"])

    assert result["total"] == 250_000.0


def test_extract_subtotal_and_total():
    result = extract_totals(
        [
            "Subtotal: 100.000",
            "VAT 10%: 10.000",
            "Grand Total: 110.000",
        ]
    )

    assert result["subtotal"] == 100_000.0
    assert result["total"] == 110_000.0


def test_extract_usd_and_cash():
    result = extract_totals(
        [
            "TOTAL AMOUNT $ 117.00",
            "CASH $ 200.00",
            "CHANGE $ 83.00",
        ]
    )

    assert result["total"] == 117.0
    assert result["currency"] == "USD"
    assert result["payment_method"] == "cash"

