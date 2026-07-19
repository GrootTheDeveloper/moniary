import { constantTimeEqual, normalizeRates } from "./logic.ts";

Deno.test("shared secret requires an exact value", () => {
  if (!constantTimeEqual("a".repeat(64), "a".repeat(64))) {
    throw new Error("matching secrets were rejected");
  }
  if (constantTimeEqual("a".repeat(64), "b".repeat(64))) {
    throw new Error("different secrets were accepted");
  }
});

Deno.test("normalizeRates inverts units-per-USD into USD value per unit", () => {
  const rows = normalizeRates(
    { result: "success", base_code: "USD", rates: { USD: 1, VND: 25000, EUR: 0.92 } },
    "2026-07-19",
    ["USD", "VND", "EUR"],
  );
  const byCode = Object.fromEntries(rows.map((row) => [row.currency_code, row]));
  if (byCode.USD.rate_to_usd !== 1) {
    throw new Error("USD should always be 1:1 with itself");
  }
  if (Math.abs(byCode.VND.rate_to_usd - 1 / 25000) > 1e-12) {
    throw new Error("VND rate was not correctly inverted");
  }
  if (Math.abs(byCode.EUR.rate_to_usd - 1 / 0.92) > 1e-12) {
    throw new Error("EUR rate was not correctly inverted");
  }
  for (const row of rows) {
    if (row.rate_date !== "2026-07-19") {
      throw new Error("rate_date was not stamped on every row");
    }
  }
});

Deno.test("normalizeRates skips codes missing or invalid in the response", () => {
  const rows = normalizeRates(
    { result: "success", base_code: "USD", rates: { USD: 1, VND: 0, EUR: -1 } },
    "2026-07-19",
    ["USD", "VND", "EUR", "GBP"],
  );
  const codes = rows.map((row) => row.currency_code);
  if (!codes.includes("USD") || codes.includes("VND") || codes.includes("EUR") || codes.includes("GBP")) {
    throw new Error("non-positive or missing rates should be skipped");
  }
});

Deno.test("normalizeRates rejects a non-success or wrong-base response", () => {
  let threw = false;
  try {
    normalizeRates({ result: "error", base_code: "USD", rates: {} }, "2026-07-19");
  } catch {
    threw = true;
  }
  if (!threw) {
    throw new Error("non-success result should throw");
  }

  threw = false;
  try {
    normalizeRates({ result: "success", base_code: "EUR", rates: {} }, "2026-07-19");
  } catch {
    threw = true;
  }
  if (!threw) {
    throw new Error("unexpected base_code should throw");
  }
});
