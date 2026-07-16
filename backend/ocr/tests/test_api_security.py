"""Security boundary tests for public OCR HTTP endpoints."""

import asyncio

from fastapi.testclient import TestClient

import main
from security import SlidingWindowRateLimiter, require_user


client = TestClient(main.app)


def teardown_function() -> None:
    main.app.dependency_overrides.clear()


def test_extract_requires_a_bearer_session() -> None:
    response = client.post(
        "/extract",
        files={"file": ("receipt.jpg", b"jpeg", "image/jpeg")},
    )

    assert response.status_code == 401
    assert response.json()["detail"] == "Bearer session is required"


def test_authenticated_request_reaches_endpoint_validation() -> None:
    main.app.dependency_overrides[require_user] = lambda: "user-1"

    response = client.post(
        "/extract",
        files={"file": ("receipt.txt", b"not an image", "text/plain")},
    )

    assert response.status_code == 415


def test_raw_debug_output_is_fail_closed() -> None:
    main.app.dependency_overrides[require_user] = lambda: "user-2"

    response = client.post(
        "/extract?debug=true",
        files={"file": ("receipt.jpg", b"jpeg", "image/jpeg")},
    )

    assert response.status_code == 403
    assert response.json()["detail"] == "Raw OCR debug output is disabled"


def test_rate_limiter_is_isolated_per_user() -> None:
    limiter = SlidingWindowRateLimiter(max_requests=1, window_seconds=60)

    async def consume_for_each_user() -> None:
        await limiter.consume("user-1")
        await limiter.consume("user-2")

    asyncio.run(consume_for_each_user())


def test_rate_limiter_rejects_repeated_requests() -> None:
    limiter = SlidingWindowRateLimiter(max_requests=1, window_seconds=60)

    async def consume_twice() -> None:
        await limiter.consume("user-1")
        try:
            await limiter.consume("user-1")
        except Exception as exc:
            assert getattr(exc, "status_code", None) == 429
        else:
            raise AssertionError("Expected the repeated request to be rate limited")

    asyncio.run(consume_twice())
