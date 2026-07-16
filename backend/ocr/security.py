"""Authentication and abuse controls for the OCR API."""

import asyncio
import math
import os
import time
from collections import defaultdict, deque
from typing import Annotated

import httpx
from fastapi import Depends, Header, HTTPException


def positive_int_env(name: str, default: int) -> int:
    try:
        value = int(os.getenv(name, str(default)))
    except ValueError as exc:
        raise RuntimeError(f"{name} must be an integer") from exc
    if value <= 0:
        raise RuntimeError(f"{name} must be greater than zero")
    return value


def positive_float_env(name: str, default: float) -> float:
    try:
        value = float(os.getenv(name, str(default)))
    except ValueError as exc:
        raise RuntimeError(f"{name} must be a number") from exc
    if not math.isfinite(value) or value <= 0:
        raise RuntimeError(f"{name} must be a finite number greater than zero")
    return value


class SupabaseAuthVerifier:
    """Resolve a bearer token through Supabase Auth instead of trusting JWT data."""

    def __init__(
        self,
        *,
        supabase_url: str | None = None,
        supabase_anon_key: str | None = None,
        timeout_seconds: float = 5.0,
    ) -> None:
        self._supabase_url = (
            supabase_url if supabase_url is not None else os.getenv("SUPABASE_URL", "")
        ).rstrip("/")
        self._supabase_anon_key = (
            supabase_anon_key
            if supabase_anon_key is not None
            else os.getenv("SUPABASE_ANON_KEY", "")
        )
        self._timeout_seconds = timeout_seconds

    async def verify(self, access_token: str) -> str:
        if not self._supabase_url or not self._supabase_anon_key:
            raise HTTPException(
                status_code=503,
                detail="OCR authentication is not configured",
            )

        try:
            async with httpx.AsyncClient(timeout=self._timeout_seconds) as client:
                response = await client.get(
                    f"{self._supabase_url}/auth/v1/user",
                    headers={
                        "apikey": self._supabase_anon_key,
                        "authorization": f"Bearer {access_token}",
                    },
                )
        except httpx.HTTPError as exc:
            raise HTTPException(
                status_code=503,
                detail="OCR authentication service is unavailable",
            ) from exc

        if response.status_code in {401, 403}:
            raise HTTPException(status_code=401, detail="Invalid or expired session")
        if response.status_code != 200:
            raise HTTPException(
                status_code=503,
                detail="OCR authentication service is unavailable",
            )

        try:
            user_id = response.json().get("id")
        except ValueError as exc:
            raise HTTPException(
                status_code=503,
                detail="OCR authentication returned an invalid response",
            ) from exc
        if not isinstance(user_id, str) or not user_id:
            raise HTTPException(status_code=401, detail="Invalid or expired session")
        return user_id


class SlidingWindowRateLimiter:
    """Process-local per-user limiter; the gateway remains the cross-replica layer."""

    def __init__(self, max_requests: int, window_seconds: int = 60) -> None:
        if max_requests <= 0 or window_seconds <= 0:
            raise ValueError("Rate-limit values must be greater than zero")
        self._max_requests = max_requests
        self._window_seconds = window_seconds
        self._requests: dict[str, deque[float]] = defaultdict(deque)
        self._lock = asyncio.Lock()
        self._consume_count = 0

    async def consume(self, user_id: str) -> None:
        now = time.monotonic()
        cutoff = now - self._window_seconds
        async with self._lock:
            self._consume_count += 1
            if self._consume_count % 100 == 0:
                stale_users = [
                    key
                    for key, values in self._requests.items()
                    if not values or values[-1] <= cutoff
                ]
                for key in stale_users:
                    del self._requests[key]
            timestamps = self._requests[user_id]
            while timestamps and timestamps[0] <= cutoff:
                timestamps.popleft()
            if len(timestamps) >= self._max_requests:
                retry_after = max(1, int(timestamps[0] + self._window_seconds - now) + 1)
                raise HTTPException(
                    status_code=429,
                    detail="OCR rate limit exceeded",
                    headers={"Retry-After": str(retry_after)},
                )
            timestamps.append(now)


auth_verifier = SupabaseAuthVerifier()
rate_limiter = SlidingWindowRateLimiter(
    positive_int_env("OCR_REQUESTS_PER_MINUTE", 10),
)


async def require_user(authorization: str | None = Header(default=None)) -> str:
    if authorization is None or not authorization.startswith("Bearer "):
        raise HTTPException(status_code=401, detail="Bearer session is required")
    access_token = authorization.removeprefix("Bearer ").strip()
    if not access_token:
        raise HTTPException(status_code=401, detail="Bearer session is required")
    return await auth_verifier.verify(access_token)


async def authorize_ocr_request(
    user_id: Annotated[str, Depends(require_user)],
) -> str:
    await rate_limiter.consume(user_id)
    return user_id
