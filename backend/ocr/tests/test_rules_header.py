from src.rules.header import extract_header


def test_extract_vietnamese_header():
    result = extract_header(
        [
            "Cửa hàng Minh Anh",
            "Số 1 Đường Nguyễn Huệ, Quận 1",
            "Ngày 10/06/2026 09:15",
        ]
    )

    assert result == {
        "merchant": "Cửa hàng Minh Anh",
        "address": "Số 1 Đường Nguyễn Huệ, Quận 1",
        "date": "2026-06-10",
        "time": "09:15",
    }


def test_extract_iso_date_and_pm_time():
    result = extract_header(
        [
            "Coffee Shop",
            "2026-06-10 09:05 PM",
        ]
    )

    assert result["date"] == "2026-06-10"
    assert result["time"] == "21:05"


def test_invalid_date_is_ignored():
    result = extract_header(["Shop", "Date: 32/14/2026"])

    assert result["date"] is None

