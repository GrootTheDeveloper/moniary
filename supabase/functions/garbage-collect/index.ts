import {
  createClient,
  type SupabaseClient,
} from "https://esm.sh/@supabase/supabase-js@2";

type EdgeSupabaseClient = SupabaseClient<any, "public", "public", any, any>;

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "content-type, x-cron-secret",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

const cleanupPrefixes = (userId: string) => [
  `transactions/${userId}`,
  `avatars/${userId}`,
  `payment-qr/${userId}`,
];

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }
  if (req.method !== "POST") {
    return json({ error: "Method not allowed" }, 405);
  }

  const expectedSecret = Deno.env.get("GARBAGE_COLLECT_SECRET");
  if (!expectedSecret) {
    return json({ error: "Server cleanup secret is not configured" }, 500);
  }
  const receivedSecret = req.headers.get("x-cron-secret") ?? "";
  if (!(await secureEquals(receivedSecret, expectedSecret))) {
    return json({ error: "Unauthorized" }, 401);
  }

  const supabaseUrl = Deno.env.get("SUPABASE_URL");
  const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
  if (!supabaseUrl || !serviceRoleKey) {
    return json({ error: "Server is not configured" }, 500);
  }

  const adminClient = createClient(supabaseUrl, serviceRoleKey, {
    auth: { autoRefreshToken: false, persistSession: false },
  });
  const cutoff = new Date(Date.now() - 30 * 24 * 60 * 60 * 1000)
    .toISOString();

  // Keep each invocation bounded so the Edge Function cannot time out while
  // processing a large backlog. The nightly job continues with the next batch.
  const { data: profiles, error: fetchError } = await adminClient
    .from("profiles")
    .select("id")
    .not("deleted_at", "is", null)
    .lte("deleted_at", cutoff)
    .order("deleted_at", { ascending: true })
    .limit(100);

  if (fetchError) {
    return json({ error: fetchError.message }, 500);
  }

  let deletedCount = 0;
  const failures: Array<{ userId: string; error: string }> = [];

  for (const profile of profiles ?? []) {
    const userId = profile.id as string;
    try {
      const { error: prepareError } = await adminClient.rpc(
        "prepare_account_for_hard_delete",
        { p_user_id: userId },
      );
      if (prepareError) throw prepareError;

      for (const prefix of cleanupPrefixes(userId)) {
        await removeStoragePrefix(adminClient, prefix);
      }

      const { error: deleteError } = await adminClient.auth.admin.deleteUser(
        userId,
        false,
      );
      if (deleteError) throw deleteError;

      deletedCount++;
    } catch (error) {
      const message = readableError(error);
      failures.push({ userId, error: message });
      console.error(`Account cleanup failed for ${userId}: ${message}`);
    }
  }

  return json({
    success: failures.length === 0,
    processed: profiles?.length ?? 0,
    deleted: deletedCount,
    failed: failures.length,
  }, failures.length === 0 ? 200 : 207);
});

async function removeStoragePrefix(
  adminClient: EdgeSupabaseClient,
  prefix: string,
) {
  while (true) {
    const { data, error } = await adminClient.storage
      .from("transaction-images")
      .list(prefix, { limit: 100, offset: 0 });
    if (error) throw error;

    const paths = (data ?? [])
      .filter((item) => item.name && item.id)
      .map((item) => `${prefix}/${item.name}`);
    if (paths.length === 0) return;

    const { error: removeError } = await adminClient.storage
      .from("transaction-images")
      .remove(paths);
    if (removeError) throw removeError;
  }
}

async function secureEquals(left: string, right: string) {
  const encoder = new TextEncoder();
  const [leftHash, rightHash] = await Promise.all([
    crypto.subtle.digest("SHA-256", encoder.encode(left)),
    crypto.subtle.digest("SHA-256", encoder.encode(right)),
  ]);
  const leftBytes = new Uint8Array(leftHash);
  const rightBytes = new Uint8Array(rightHash);
  let difference = left.length ^ right.length;
  for (let index = 0; index < leftBytes.length; index++) {
    difference |= leftBytes[index] ^ rightBytes[index];
  }
  return difference === 0;
}

function json(body: Record<string, unknown>, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: {
      ...corsHeaders,
      "Content-Type": "application/json",
    },
  });
}

function readableError(error: unknown) {
  if (error instanceof Error) return error.message;
  if (
    typeof error === "object" &&
    error !== null &&
    "message" in error &&
    typeof error.message === "string"
  ) {
    return error.message;
  }
  return "Could not delete account data";
}
