from src.classifier import classify_category
from src.models import ReceiptItem


def test_food_category_from_merchant():
    category, confidence = classify_category("Highlands Coffee", [])
    assert category == "food"
    assert confidence >= 0.7


def test_transport_category_from_items():
    category, confidence = classify_category(
        None,
        [ReceiptItem(name="Phi giu xe", amount=10_000)],
    )
    assert category == "transport"
    assert confidence > 0.5


def test_unknown_receipt_has_no_category():
    assert classify_category("ABC XYZ", []) == (None, 0.0)


def test_short_keywords_do_not_match_inside_other_words():
    assert classify_category("Smart Workshop Company", []) == (None, 0.0)
