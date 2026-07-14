"""Pydantic models returned by the receipt OCR API."""

from pydantic import BaseModel, Field


class OCRTextLine(BaseModel):
    text: str
    confidence: float | None = None
    bbox: list[list[float]] | None = None


class ReceiptItem(BaseModel):
    name: str
    qty: float = 1.0
    unit_price: float = 0.0
    amount: float = 0.0


class ReceiptData(BaseModel):
    merchant: str | None = None
    address: str | None = None
    date: str | None = None
    time: str | None = None
    items: list[ReceiptItem] = Field(default_factory=list)
    subtotal: float = 0.0
    discount: float = 0.0
    vat_rate: float = 0.0
    vat_amount: float = 0.0
    total: float = 0.0
    currency: str = "VND"
    payment_method: str | None = None
    suggested_category: str | None = None


class ReceiptResponse(BaseModel):
    success: bool
    data: ReceiptData | None = None
    raw_text: str | None = None
    ocr_engine: str | None = None
    ocr_lines: list[OCRTextLine] | None = None
    validation_issues: list[str] = Field(default_factory=list)
    confidence: float = 0.0
    field_confidence: dict[str, float] = Field(default_factory=dict)
    processing_ms: int = 0
    error: str | None = None
