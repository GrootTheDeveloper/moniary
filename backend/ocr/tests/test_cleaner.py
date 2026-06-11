import pytest

from src.cleaner import clean_text, normalize_money, remove_diacritics


def test_normalize_vnd_dot_separator():
    assert normalize_money("1.500.000") == 1_500_000.0


def test_normalize_comma_separator():
    assert normalize_money("25,000") == 25_000.0


def test_normalize_suffix_k():
    assert normalize_money("150K") == 150_000.0


def test_normalize_suffix_m():
    assert normalize_money("1.5M") == 1_500_000.0


def test_normalize_strips_currency():
    assert normalize_money("50.000đ") == 50_000.0
    assert normalize_money("$ 35.00") == 35.0


def test_normalize_mixed_separators():
    assert normalize_money("1.500.000,50") == 1_500_000.5


def test_normalize_invalid_raises():
    with pytest.raises(ValueError):
        normalize_money("không có giá")


def test_clean_preserves_vietnamese():
    assert "Cà phê sữa đá" in clean_text("Cà phê sữa đá")


def test_clean_preserves_currency_symbols():
    assert clean_text("$ 50.000₫") == "$ 50.000₫"


def test_clean_removes_garbage():
    assert clean_text("|||@@# Cà phê") == "Cà phê"


def test_remove_diacritics_handles_vietnamese_d():
    assert remove_diacritics("Đường Nguyễn Huệ") == "Duong Nguyen Hue"

