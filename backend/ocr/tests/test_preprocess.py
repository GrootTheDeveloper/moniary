from pathlib import Path

import cv2
import numpy as np
import pytest

from src.preprocess import preprocess


def _write_image(path: Path, width: int, height: int) -> None:
    image = np.full((height, width, 3), 255, dtype=np.uint8)
    cv2.putText(
        image,
        "TOTAL 100.000",
        (20, min(100, height - 20)),
        cv2.FONT_HERSHEY_SIMPLEX,
        1,
        (0, 0, 0),
        2,
    )
    assert cv2.imwrite(str(path), image)


def test_preprocess_keeps_small_image_dimensions(tmp_path):
    source = tmp_path / "receipt.jpg"
    _write_image(source, 640, 480)

    output_path = preprocess(str(source))
    try:
        output = cv2.imread(output_path)
        assert output.shape[:2] == (480, 640)
    finally:
        Path(output_path).unlink(missing_ok=True)


def test_preprocess_resizes_long_side_to_2000(tmp_path):
    source = tmp_path / "large.jpg"
    _write_image(source, 3000, 1500)

    output_path = preprocess(str(source))
    try:
        output = cv2.imread(output_path)
        assert output.shape[:2] == (1000, 2000)
    finally:
        Path(output_path).unlink(missing_ok=True)


def test_preprocess_invalid_path_raises():
    with pytest.raises(ValueError, match="Cannot read image"):
        preprocess("/tmp/receipt-does-not-exist.jpg")

