import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

import { constantTimeEqual, normalizeRates, SUPPORTED_CURRENCIES } from "./logic.ts";

const secretHeader = "x-fetch-exchange-rates-secret";
const rateApiUrl = "https://open.er-api.com/v6/latest/USD";

Deno.serve(async (request) => {
  try {
    return await handleRequest(request);
  } catch (error) {
    console.error("fetch-exchange-rates failed", error);
    return json({ error: "fetch-exchange-rates failed" }, 500);
  }
});

async function handleRequest(request: Request) {
  if (request.method !== "POST") {
    return json({ error: "Method not allowed" }, 405);
  }

  const supabaseUrl = Deno.env.get("SUPABASE_URL")?.trim();
  const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")?.trim();
  const sharedSecret = Deno.env.get("FETCH_EXCHANGE_RATES_SECRET")?.trim();
  if (!supabaseUrl || !serviceRoleKey || !sharedSecret) {
    return json({ error: "fetch-exchange-rates misconfigured" }, 500);
  }
  if (!constantTimeEqual(request.headers.get(secretHeader), sharedSecret)) {
    return json({ error: "Unauthorized" }, 401);
  }

  const apiResponse = await fetch(rateApiUrl);
  if (!apiResponse.ok) {
    return json({ error: `rate API returned ${apiResponse.status}` }, 502);
  }
  const rateDate = new Date().toISOString().slice(0, 10);
  const rows = normalizeRates(await apiResponse.json(), rateDate, SUPPORTED_CURRENCIES);

  const client = createClient(supabaseUrl, serviceRoleKey, {
    auth: { autoRefreshToken: false, persistSession: false },
  });
  const { error } = await client
    .from("exchange_rates")
    .upsert(rows, { onConflict: "rate_date,currency_code" });
  if (error) {
    return json({ error: error.message }, 500);
  }

  return json({ ok: true, rate_date: rateDate, count: rows.length });
}

function json(body: unknown, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { "Content-Type": "application/json" },
  });
}
