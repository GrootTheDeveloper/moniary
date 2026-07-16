"""Gemini semantic enrichment tests without external network calls."""

import hashlib
import json

import httpx

from src.llm import GeminiReceiptEnhancer
from src.models import ReceiptData


def test_gemini_enriches_semantic_fields_and_keeps_stable_sources():
    def handler(request: httpx.Request) -> httpx.Response:
        assert request.headers["x-goog-api-key"] == "test-key"
        body = json.loads(request.content)
        assert body["generationConfig"]["responseMimeType"] == "application/json"
        assert "responseJsonSchema" in body["generationConfig"]
        return httpx.Response(
            200,
            json={
                "candidates": [
                    {
                        "finishReason": "STOP",
                        "content": {
                            "parts": [
                                {
                                    "text": """{
                                      "merchant": "Highlands Coffee",
                                      "address": "1 Nguyen Hue, Quan 1",
                                      "date": "2026-07-16",
                                      "time": "09:30",
                                      "items": [{
                                        "name": "Ca phe sua",
                                        "qty": 1,
                                        "unit_price": 35000,
                                        "amount": 35000
                                      }],
                                      "subtotal": 35000,
                                      "discount": 0,
                                      "vat_rate": 0,
                                      "vat_amount": 0,
                                      "total": 35000,
                                      "currency": "VND",
                                      "payment_method": "card",
                                      "suggested_category": "coffee",
                                      "field_confidence": {
                                        "merchant": 0.93,
                                        "total": 0.97,
                                        "category": 0.88
                                      }
                                    }"""
                                }
                            ]
                        },
                    }
                ]
            },
        )

    client = httpx.Client(transport=httpx.MockTransport(handler))
    enhancer = GeminiReceiptEnhancer(api_key="test-key", client=client)

    result = enhancer.enhance(
        "RECEIPT\nHighlands Coffee\nTOTAL 35.000 VND",
        ReceiptData(merchant="RECEIPT", total=35000),
    )

    assert result is not None
    assert result.data.merchant == "Highlands Coffee"
    assert result.data.total == 35_000
    assert result.data.suggested_category == "coffee"
    assert result.data.items[0].amount == 35_000
    assert result.field_sources["merchant"] == "llm"
    assert result.field_sources["category"] == "llm"
    assert result.field_confidence["merchant"] == 0.93
    client.close()


def test_gemini_failure_falls_back_without_raising():
    client = httpx.Client(
        transport=httpx.MockTransport(
            lambda _: httpx.Response(429, json={"error": "quota"})
        )
    )
    enhancer = GeminiReceiptEnhancer(api_key="test-key", client=client)

    result = enhancer.enhance("TOTAL 35.000 VND", ReceiptData(total=35_000))

    assert result is None
    client.close()


def test_blocked_gemini_key_is_not_used(monkeypatch):
    api_key = "exposed-key"
    monkeypatch.setenv(
        "GEMINI_BLOCKED_KEY_SHA256",
        hashlib.sha256(api_key.encode()).hexdigest(),
    )
    client = httpx.Client(
        transport=httpx.MockTransport(
            lambda _: (_ for _ in ()).throw(
                AssertionError("Blocked key must not make a request")
            )
        )
    )
    enhancer = GeminiReceiptEnhancer(api_key=api_key, client=client)

    assert enhancer.enhance("TOTAL 35.000 VND", ReceiptData(total=35_000)) is None
    client.close()
