"""OCR engine adapters for server-side receipt recognition."""

from __future__ import annotations

from dataclasses import dataclass, replace
import importlib.util
import os
import re
import time
from pathlib import Path
from typing import Any, Protocol

from PIL import Image

try:
    import pytesseract
    from pytesseract import Output, TesseractNotFoundError
except ImportError:  # Allows rule unit tests before OCR deps are installed.
    pytesseract = None
    Output = None

    class TesseractNotFoundError(RuntimeError):
        pass


OCR_LANG = os.getenv("OCR_LANG", "vie+eng")
OCR_PSM = int(os.getenv("OCR_PSM", "6"))
OCR_ENGINE = os.getenv("OCR_ENGINE", "auto").strip().casefold()
PADDLEOCR_LANG = os.getenv("PADDLEOCR_LANG", "vi")
PADDLEOCR_USE_ANGLE_CLS = (
    os.getenv("PADDLEOCR_USE_ANGLE_CLS", "true").strip().casefold()
    not in {"0", "false", "no", "off"}
)
TESSERACT_CMD = os.getenv("TESSERACT_CMD")


@dataclass(frozen=True)
class OCRLine:
    text: str
    confidence: float | None = None
    bbox: list[list[float]] | None = None

    def to_dict(self) -> dict[str, object]:
        return {
            "text": self.text,
            "confidence": self.confidence,
            "bbox": self.bbox,
        }


@dataclass(frozen=True)
class OCRResult:
    text: str
    lines: list[OCRLine]
    engine: str
    elapsed_seconds: float


class OCREngine(Protocol):
    name: str

    def recognize(
        self,
        image_path: str,
        fallback_image_path: str | None = None,
    ) -> OCRResult:
        ...

    def health_info(self) -> dict[str, object]:
        ...


def _quality_score(text: str) -> int:
    normalized = text.casefold()
    non_empty_lines = [line for line in text.splitlines() if line.strip()]
    useful_characters = sum(
        character.isalnum() or character in ".,:$%₫"
        for character in text
    )
    item_lines = len(
        re.findall(r"(?im)^\s*\d+(?:[.,]\d+)?\s*[x×]\s+\S+", text)
    )
    score = useful_characters + len(non_empty_lines) * 5 + item_lines * 20
    if "total" in normalized or "tổng" in normalized:
        score += 30
    if "receipt" in normalized or "hóa đơn" in normalized:
        score += 30
    return score


def _image_paths(
    image_path: str,
    fallback_image_path: str | None,
) -> list[str]:
    paths = [image_path]
    if fallback_image_path and Path(fallback_image_path) != Path(image_path):
        paths.append(fallback_image_path)
    return paths


def _text_lines(text: str) -> list[OCRLine]:
    return [
        OCRLine(text=line.strip())
        for line in text.splitlines()
        if line.strip()
    ]


def _not_found_error() -> RuntimeError:
    return RuntimeError(
        "Tesseract was not found. Install tesseract-ocr with the "
        "`vie` and `eng` language packs, or set TESSERACT_CMD."
    )


class TesseractEngine:
    """Tesseract OCR adapter with plain text and line-layout output."""

    name = "tesseract"

    def _configure(self) -> None:
        if pytesseract is None:
            raise RuntimeError(
                "pytesseract is not installed. Run "
                "`pip install -r requirements.txt`."
            )
        if TESSERACT_CMD:
            pytesseract.pytesseract.tesseract_cmd = TESSERACT_CMD

    def _config(self, psm: int) -> str:
        return f"--oem 3 --psm {psm} -l {OCR_LANG}"

    def _ocr_text(self, image_path: str, psm: int) -> str:
        with Image.open(Path(image_path)) as image:
            return pytesseract.image_to_string(
                image,
                config=self._config(psm),
            )

    def _line_layout(self, image_path: str) -> list[OCRLine]:
        if Output is None:
            return []
        try:
            with Image.open(Path(image_path)) as image:
                data = pytesseract.image_to_data(
                    image,
                    config=self._config(OCR_PSM),
                    output_type=Output.DICT,
                )
        except TesseractNotFoundError as exc:
            raise _not_found_error() from exc

        grouped: dict[tuple[int, int, int], list[dict[str, object]]] = {}
        for index, text in enumerate(data["text"]):
            normalized = str(text).strip()
            if not normalized:
                continue
            try:
                confidence = float(data["conf"][index])
            except (TypeError, ValueError):
                confidence = -1.0
            if confidence < 30:
                continue

            key = (
                int(data["block_num"][index]),
                int(data["par_num"][index]),
                int(data["line_num"][index]),
            )
            grouped.setdefault(key, []).append(
                {
                    "text": normalized,
                    "confidence": confidence,
                    "left": int(data["left"][index]),
                    "top": int(data["top"][index]),
                    "right": int(data["left"][index])
                    + int(data["width"][index]),
                    "bottom": int(data["top"][index])
                    + int(data["height"][index]),
                }
            )

        lines: list[OCRLine] = []
        for words in grouped.values():
            left = min(int(word["left"]) for word in words)
            top = min(int(word["top"]) for word in words)
            right = max(int(word["right"]) for word in words)
            bottom = max(int(word["bottom"]) for word in words)
            lines.append(
                OCRLine(
                    text=" ".join(str(word["text"]) for word in words),
                    confidence=round(
                        sum(float(word["confidence"]) for word in words)
                        / len(words),
                        2,
                    ),
                    bbox=[
                        [float(left), float(top)],
                        [float(right), float(top)],
                        [float(right), float(bottom)],
                        [float(left), float(bottom)],
                    ],
                )
            )
        return lines

    def recognize(
        self,
        image_path: str,
        fallback_image_path: str | None = None,
    ) -> OCRResult:
        self._configure()
        started_at = time.perf_counter()
        candidates: list[tuple[str, str]] = []

        try:
            for path in _image_paths(image_path, fallback_image_path):
                raw_text = self._ocr_text(path, OCR_PSM)
                if len(raw_text.strip()) < 20 and OCR_PSM != 4:
                    raw_text = self._ocr_text(path, 4)
                candidates.append((raw_text, path))
        except TesseractNotFoundError as exc:
            raise _not_found_error() from exc

        text, selected_path = max(
            candidates,
            key=lambda candidate: _quality_score(candidate[0]),
            default=("", image_path),
        )
        lines = self._line_layout(selected_path) or _text_lines(text)
        elapsed = time.perf_counter() - started_at
        print(f"OCR completed in {elapsed:.2f}s using {self.name}")
        return OCRResult(
            text=text,
            lines=lines,
            engine=self.name,
            elapsed_seconds=elapsed,
        )

    def word_layout(self, image_path: str) -> list[dict[str, object]]:
        self._configure()
        if Output is None:
            return []
        try:
            with Image.open(Path(image_path)) as image:
                data = pytesseract.image_to_data(
                    image,
                    config=self._config(OCR_PSM),
                    output_type=Output.DICT,
                )
        except TesseractNotFoundError as exc:
            raise _not_found_error() from exc

        words: list[dict[str, object]] = []
        for index, text in enumerate(data["text"]):
            try:
                confidence = float(data["conf"][index])
            except (TypeError, ValueError):
                confidence = -1.0
            normalized = str(text).strip()
            if normalized and confidence >= 30:
                words.append(
                    {
                        "text": normalized,
                        "conf": confidence,
                        "left": int(data["left"][index]),
                        "top": int(data["top"][index]),
                        "width": int(data["width"][index]),
                        "height": int(data["height"][index]),
                        "line_num": int(data["line_num"][index]),
                        "block_num": int(data["block_num"][index]),
                    }
                )
        return words

    def health_info(self) -> dict[str, object]:
        self._configure()
        try:
            version = str(pytesseract.get_tesseract_version())
            languages = sorted(pytesseract.get_languages(config=""))
        except TesseractNotFoundError as exc:
            raise _not_found_error() from exc

        required_languages = {"eng", "vie"}
        return {
            "status": "ok"
            if required_languages.issubset(set(languages))
            else "degraded",
            "ocr_engine": self.name,
            "tesseract_version": version,
            "languages": languages,
            "layout": "line_bbox",
        }


def _paddle_available() -> bool:
    return importlib.util.find_spec("paddleocr") is not None


def _paddle_error() -> RuntimeError:
    return RuntimeError(
        "PaddleOCR is not installed. Install it with "
        "`pip install -r requirements-paddle.txt`, or set "
        "`OCR_ENGINE=tesseract`."
    )


def _to_plain_data(value: Any) -> Any:
    if hasattr(value, "tolist"):
        return value.tolist()
    if isinstance(value, tuple):
        return [_to_plain_data(item) for item in value]
    if isinstance(value, list):
        return [_to_plain_data(item) for item in value]
    return value


def _coerce_bbox(value: Any) -> list[list[float]] | None:
    value = _to_plain_data(value)
    if not isinstance(value, list):
        return None

    if len(value) == 4 and all(isinstance(item, (int, float)) for item in value):
        left, top, right, bottom = [float(item) for item in value]
        return [[left, top], [right, top], [right, bottom], [left, bottom]]

    points: list[list[float]] = []
    for point in value:
        if (
            isinstance(point, list)
            and len(point) >= 2
            and isinstance(point[0], (int, float))
            and isinstance(point[1], (int, float))
        ):
            points.append([float(point[0]), float(point[1])])

    return points or None


def _paddle_entry(node: Any) -> OCRLine | None:
    node = _to_plain_data(node)
    if not (
        isinstance(node, list)
        and len(node) >= 2
        and isinstance(node[1], list)
        and node[1]
        and isinstance(node[1][0], str)
    ):
        return None

    text = node[1][0].strip()
    if not text:
        return None
    confidence = None
    if len(node[1]) > 1 and isinstance(node[1][1], (int, float)):
        confidence = round(float(node[1][1]), 4)
    return OCRLine(
        text=text,
        confidence=confidence,
        bbox=_coerce_bbox(node[0]),
    )


def _paddle_dict_lines(node: dict[str, Any]) -> list[OCRLine]:
    texts = node.get("rec_texts") or node.get("texts")
    if not isinstance(texts, list):
        return []

    scores = node.get("rec_scores") or node.get("scores") or []
    boxes = (
        node.get("rec_polys")
        or node.get("dt_polys")
        or node.get("rec_boxes")
        or node.get("boxes")
        or []
    )
    lines: list[OCRLine] = []
    for index, text in enumerate(texts):
        normalized = str(text).strip()
        if not normalized:
            continue
        score = scores[index] if index < len(scores) else None
        bbox = boxes[index] if index < len(boxes) else None
        lines.append(
            OCRLine(
                text=normalized,
                confidence=round(float(score), 4)
                if isinstance(score, (int, float))
                else None,
                bbox=_coerce_bbox(bbox),
            )
        )
    return lines


def _paddle_lines(node: Any) -> list[OCRLine]:
    entry = _paddle_entry(node)
    if entry:
        return [entry]

    if isinstance(node, dict):
        lines = _paddle_dict_lines(node)
        if lines:
            return lines
        output: list[OCRLine] = []
        for value in node.values():
            output.extend(_paddle_lines(value))
        return output

    for attr_name in ("json", "res"):
        attr = getattr(node, attr_name, None)
        if attr is None:
            continue
        value = attr() if callable(attr) else attr
        lines = _paddle_lines(value)
        if lines:
            return lines

    if isinstance(node, (list, tuple)):
        output = []
        for item in node:
            output.extend(_paddle_lines(item))
        return output

    return []


class PaddleOCREngine:
    """PaddleOCR adapter for the server-side OCR option."""

    name = "paddleocr"

    def __init__(self) -> None:
        self.lang = PADDLEOCR_LANG
        self.use_angle_cls = PADDLEOCR_USE_ANGLE_CLS
        self._ocr: Any | None = None

    def _load(self) -> Any:
        if not _paddle_available():
            raise _paddle_error()
        if self._ocr is None:
            from paddleocr import PaddleOCR

            try:
                self._ocr = PaddleOCR(
                    use_angle_cls=self.use_angle_cls,
                    lang=self.lang,
                )
            except TypeError:
                self._ocr = PaddleOCR(lang=self.lang)
        return self._ocr

    def _run_once(self, image_path: str) -> OCRResult:
        engine = self._load()
        if hasattr(engine, "ocr"):
            raw_result = engine.ocr(image_path, cls=self.use_angle_cls)
        elif hasattr(engine, "predict"):
            raw_result = engine.predict(image_path)
        else:
            raise RuntimeError("Unsupported PaddleOCR runtime interface.")

        lines = _paddle_lines(raw_result)
        text = "\n".join(line.text for line in lines if line.text)
        return OCRResult(
            text=text,
            lines=lines,
            engine=self.name,
            elapsed_seconds=0.0,
        )

    def recognize(
        self,
        image_path: str,
        fallback_image_path: str | None = None,
    ) -> OCRResult:
        started_at = time.perf_counter()
        candidates = [
            self._run_once(path)
            for path in _image_paths(image_path, fallback_image_path)
        ]
        selected = max(
            candidates,
            key=lambda candidate: _quality_score(candidate.text),
            default=OCRResult("", [], self.name, 0.0),
        )
        elapsed = time.perf_counter() - started_at
        print(f"OCR completed in {elapsed:.2f}s using {self.name}")
        return replace(selected, elapsed_seconds=elapsed)

    def health_info(self) -> dict[str, object]:
        if not _paddle_available():
            raise _paddle_error()
        return {
            "status": "ok",
            "ocr_engine": self.name,
            "paddleocr_lang": self.lang,
            "use_angle_cls": self.use_angle_cls,
            "layout": "line_bbox",
        }


_ENGINE_CACHE: dict[str, OCREngine] = {}


def _resolved_engine_name() -> str:
    if OCR_ENGINE in {"", "auto"}:
        return "paddleocr" if _paddle_available() else "tesseract"
    if OCR_ENGINE in {"paddle", "paddleocr"}:
        return "paddleocr"
    if OCR_ENGINE == "tesseract":
        return "tesseract"
    raise RuntimeError(
        "Unsupported OCR_ENGINE. Use auto, paddleocr, or tesseract."
    )


def get_ocr_engine() -> OCREngine:
    engine_name = _resolved_engine_name()
    if engine_name not in _ENGINE_CACHE:
        if engine_name == "paddleocr":
            _ENGINE_CACHE[engine_name] = PaddleOCREngine()
        else:
            _ENGINE_CACHE[engine_name] = TesseractEngine()
    return _ENGINE_CACHE[engine_name]


def recognize_image(
    image_path: str,
    fallback_image_path: str | None = None,
) -> OCRResult:
    return get_ocr_engine().recognize(image_path, fallback_image_path)


def run_ocr(image_path: str, fallback_image_path: str | None = None) -> str:
    """Compatibility wrapper returning only raw OCR text."""
    return recognize_image(image_path, fallback_image_path).text


def run_ocr_with_layout(image_path: str) -> list[dict[str, object]]:
    """Return layout data from the selected OCR engine."""
    engine = get_ocr_engine()
    if isinstance(engine, TesseractEngine):
        return engine.word_layout(image_path)
    return [
        line.to_dict()
        for line in engine.recognize(image_path).lines
    ]


def tesseract_info() -> tuple[str | None, list[str]]:
    """Return the installed Tesseract version and language list."""
    info = TesseractEngine().health_info()
    return (
        str(info.get("tesseract_version")),
        list(info.get("languages", [])),
    )


def ocr_health() -> dict[str, object]:
    """Return health metadata for the configured OCR engine."""
    requested_engine = OCR_ENGINE or "auto"
    try:
        info = get_ocr_engine().health_info()
    except RuntimeError as exc:
        try:
            engine_name = _resolved_engine_name()
        except RuntimeError:
            engine_name = None
        return {
            "status": "unavailable",
            "requested_ocr_engine": requested_engine,
            "ocr_engine": engine_name,
            "error": str(exc),
        }
    return {
        "requested_ocr_engine": requested_engine,
        **info,
    }
