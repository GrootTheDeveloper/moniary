from src.cleaner import clean_text
from src.models import ReceiptData
from src.rules.header import extract_header
from src.rules.items import extract_items
from src.rules.totals import extract_totals
from src.validator import validate


SAMPLE_TEXT = """
RECEIPT
1x Lorem ipsum       $ 35.00
2x Lorem ipsum       $ 15.00
1x Lorem ipsum       $ 30.00
1x Lorem ipsum       $ 10.00
2x Lorem ipsum       $ 10.00
1x Lorem ipsum       $ 7.00
1x Lorem ipsum       $ 10.00
TOTAL AMOUNT         $ 117.00
CASH                 $ 200.00
CHANGE               $ 83.00
THANK YOU
"""


def test_sample_receipt_text_extracts_total_117():
    lines = [
        line
        for line in clean_text(SAMPLE_TEXT).splitlines()
        if line.strip()
    ]
    header = extract_header(lines)
    items = extract_items(lines)
    totals = extract_totals(lines)
    data, issues, confidence = validate(
        ReceiptData(
            merchant=header["merchant"],
            address=header["address"],
            date=header["date"],
            time=header["time"],
            items=items,
            **totals,
        )
    )

    assert len(data.items) == 7
    assert data.subtotal == 117.0
    assert data.total == 117.0
    assert data.currency == "USD"
    assert data.payment_method == "cash"
    assert issues == []
    assert confidence >= 0.8

