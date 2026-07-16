from src.extractor import extract_receipt_with_metadata
from src.ocr import OCRLine, OCRResult


def test_extractor_preserves_ocr_engine_and_line_layout(monkeypatch, tmp_path):
    source = tmp_path / "receipt.jpg"
    processed = tmp_path / "processed.jpg"
    source.write_bytes(b"fake image")

    def fake_preprocess(image_path: str) -> str:
        assert image_path == str(source)
        return str(processed)

    def fake_recognize(
        image_path: str,
        fallback_image_path: str | None = None,
    ) -> OCRResult:
        assert image_path == str(processed)
        assert fallback_image_path == str(source)
        return OCRResult(
            text="Cua hang\nTong thanh toan: 150.000 VND",
            lines=[
                OCRLine(
                    text="Tong thanh toan: 150.000 VND",
                    confidence=0.98,
                    bbox=[
                        [10.0, 20.0],
                        [300.0, 20.0],
                        [300.0, 50.0],
                        [10.0, 50.0],
                    ],
                )
            ],
            engine="fake",
            elapsed_seconds=0.01,
        )

    monkeypatch.setattr("src.extractor.preprocess", fake_preprocess)
    monkeypatch.setattr("src.extractor.recognize_image", fake_recognize)
    monkeypatch.setattr("src.extractor.enhance_receipt", lambda *_: None)

    result = extract_receipt_with_metadata(str(source))

    assert result.ocr_engine == "fake"
    assert result.ocr_lines[0].confidence == 0.98
    assert result.ocr_lines[0].bbox == [
        [10.0, 20.0],
        [300.0, 20.0],
        [300.0, 50.0],
        [10.0, 50.0],
    ]
    assert result.data.total == 150_000.0
