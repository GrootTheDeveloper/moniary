const encoder = new TextEncoder();

export function constantTimeEqual(received: string | null, expected: string) {
  if (received == null) return false;
  const receivedBytes = encoder.encode(received);
  const expectedBytes = encoder.encode(expected);
  if (receivedBytes.length !== expectedBytes.length) return false;

  let difference = 0;
  for (let index = 0; index < expectedBytes.length; index++) {
    difference |= receivedBytes[index] ^ expectedBytes[index];
  }
  return difference === 0;
}

// The catalog of currencies the app's picker offers (lib/shared/utils/currency_formatter.dart).
// Kept in sync manually — add a code here whenever it's added to that catalog.
export const SUPPORTED_CURRENCIES = [
  "VND",
  "USD",
  "EUR",
  "GBP",
  "JPY",
  "CNY",
  "KRW",
  "THB",
  "SGD",
  "AUD",
  "INR",
  "IDR",
  "MYR",
  "PHP",
];

export interface ExchangeRateApiResponse {
  result?: string;
  base_code?: string;
  rates?: Record<string, number>;
}

export interface ExchangeRateRow {
  rate_date: string;
  currency_code: string;
  rate_to_usd: number;
}

// The API returns rates as "units of currency per 1 USD" (base_code: "USD").
// We store the inverse — USD value of 1 unit of the currency — so converting
// between any two stored currencies is a single multiply/divide through USD.
export function normalizeRates(
  response: ExchangeRateApiResponse,
  rateDate: string,
  supportedCodes: string[] = SUPPORTED_CURRENCIES,
): ExchangeRateRow[] {
  if (response.result !== "success" || response.base_code !== "USD") {
    throw new Error("EXCHANGE_RATE_API_INVALID_RESPONSE");
  }
  const rates = response.rates ?? {};
  const rows: ExchangeRateRow[] = [];
  for (const code of supportedCodes) {
    const unitsPerUsd = rates[code];
    if (typeof unitsPerUsd !== "number" || !(unitsPerUsd > 0)) continue;
    rows.push({
      rate_date: rateDate,
      currency_code: code,
      rate_to_usd: 1 / unitsPerUsd,
    });
  }
  return rows;
}
