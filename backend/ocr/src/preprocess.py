"""Image preprocessing for Tesseract receipt OCR."""

import math
import os
import uuid
import warnings
from pathlib import Path

import cv2
import numpy as np


MAX_IMAGE_PX = int(os.getenv("MAX_IMAGE_PX", "2000"))
MIN_IMAGE_PX = 300


def deskew(image: np.ndarray) -> np.ndarray:
    """Rotate an image using the median angle of near-horizontal lines."""
    gray = (
        cv2.cvtColor(image, cv2.COLOR_BGR2GRAY)
        if image.ndim == 3
        else image.copy()
    )
    edges = cv2.Canny(gray, 50, 150, apertureSize=3)
    min_line_length = max(50, min(image.shape[:2]) // 4)
    lines = cv2.HoughLinesP(
        edges,
        1,
        np.pi / 180,
        threshold=80,
        minLineLength=min_line_length,
        maxLineGap=20,
    )
    if lines is None:
        return image

    angles: list[float] = []
    # OpenCV returns either (N, 1, 4) or (N, 4) depending on the build.
    for x1, y1, x2, y2 in np.asarray(lines).reshape(-1, 4):
        angle = math.degrees(math.atan2(y2 - y1, x2 - x1))
        if -45 <= angle <= 45:
            angles.append(angle)

    if not angles:
        return image

    angle = float(np.median(angles))
    if abs(angle) <= 0.5:
        return image

    height, width = image.shape[:2]
    matrix = cv2.getRotationMatrix2D((width / 2, height / 2), angle, 1.0)
    return cv2.warpAffine(
        image,
        matrix,
        (width, height),
        flags=cv2.INTER_CUBIC,
        borderMode=cv2.BORDER_REPLICATE,
    )


def preprocess(image_path: str) -> str:
    """Prepare a receipt image and return a temporary JPEG path."""
    try:
        image = cv2.imread(image_path)
    except Exception as exc:
        raise ValueError(f"Cannot read image: {image_path}") from exc
    if image is None:
        raise ValueError(f"Cannot read image: {image_path}")

    height, width = image.shape[:2]
    if min(height, width) < MIN_IMAGE_PX:
        warnings.warn(
            "Receipt image has a side shorter than 300px; OCR accuracy may be low.",
            stacklevel=2,
        )

    longest_side = max(height, width)
    if longest_side > MAX_IMAGE_PX:
        scale = MAX_IMAGE_PX / longest_side
        image = cv2.resize(
            image,
            (max(1, round(width * scale)), max(1, round(height * scale))),
            interpolation=cv2.INTER_AREA,
        )

    image = deskew(image)
    gray = cv2.cvtColor(image, cv2.COLOR_BGR2GRAY)
    denoised = cv2.fastNlMeansDenoising(gray, h=10)
    binary = cv2.adaptiveThreshold(
        denoised,
        255,
        cv2.ADAPTIVE_THRESH_GAUSSIAN_C,
        cv2.THRESH_BINARY,
        11,
        2,
    )
    sharpen_kernel = np.array(
        [[0, -1, 0], [-1, 5, -1], [0, -1, 0]],
        dtype=np.float32,
    )
    sharpened = cv2.filter2D(binary, -1, sharpen_kernel)

    output_path = Path("/tmp") / f"receipt_{uuid.uuid4().hex[:8]}.jpg"
    written = cv2.imwrite(
        str(output_path),
        sharpened,
        [int(cv2.IMWRITE_JPEG_QUALITY), 95],
    )
    if not written:
        raise ValueError(f"Cannot write preprocessed image: {output_path}")
    return str(output_path)
