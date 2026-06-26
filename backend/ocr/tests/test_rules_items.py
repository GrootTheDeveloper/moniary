from src.rules.items import extract_items


def test_parse_single_line_item():
    items = extract_items(
        [
            "Cửa hàng",
            "Cà phê  2  25.000  50.000",
            "Tổng thanh toán 50.000",
        ]
    )

    assert items == [
        {
            "name": "Cà phê",
            "qty": 2.0,
            "unit_price": 25_000.0,
            "amount": 50_000.0,
        }
    ]


def test_parse_multiline_item():
    items = extract_items(
        [
            "Bánh mì",
            "1 x 35.000  35.000",
            "Tổng 35.000",
        ]
    )

    assert items[0]["name"] == "Bánh mì"
    assert items[0]["amount"] == 35_000.0


def test_parse_name_amount_only():
    items = extract_items(
        [
            "Nước suối         10.000",
            "Total 10.000",
        ]
    )

    assert items[0] == {
        "name": "Nước suối",
        "qty": 1.0,
        "unit_price": 10_000.0,
        "amount": 10_000.0,
    }


def test_parse_quantity_name_unit_price():
    items = extract_items(
        [
            "RECEIPT",
            "2x Lorem ipsum $ 15.00",
            "TOTAL AMOUNT $ 30.00",
        ]
    )

    assert items[0] == {
        "name": "Lorem ipsum",
        "qty": 2.0,
        "unit_price": 7.5,
        "amount": 15.0,
    }


def test_skip_separator_lines():
    assert extract_items(["---", "Total 0"]) == []


def test_skip_total_lines():
    assert extract_items(["Tổng cộng 100.000"]) == []
