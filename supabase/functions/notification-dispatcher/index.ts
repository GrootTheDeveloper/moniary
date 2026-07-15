import {
  createClient,
  type SupabaseClient,
} from "https://esm.sh/@supabase/supabase-js@2";

import { classifyFcmFailure, constantTimeEqual } from "./logic.ts";

type ServiceAccount = {
  project_id: string;
  client_email: string;
  private_key: string;
};

type OutboxRow = {
  id: string;
  user_id: string;
  category: string;
  type: string;
  group_id: string | null;
  metadata: Record<string, unknown>;
};

type DeviceRow = {
  id: string;
  device_token: string;
  locale: string;
};

type DispatchOutcome = {
  outcome: "sent" | "skipped" | "retry" | "failed";
  reason: string | null;
};

type EdgeSupabaseClient = SupabaseClient<
  any,
  "public",
  "public",
  any,
  any
>;

const dispatchHeader = "x-notification-dispatch-secret";
const batchSize = 50;

Deno.serve(async (request) => {
  try {
    return await handleRequest(request);
  } catch (error) {
    console.error("Notification dispatcher failed", safeErrorCode(error));
    return json({ error: "Notification dispatch failed" }, 500);
  }
});

async function handleRequest(request: Request) {
  if (request.method !== "POST") {
    return json({ error: "Method not allowed" }, 405);
  }

  const supabaseUrl = Deno.env.get("SUPABASE_URL")?.trim();
  const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")?.trim();
  const dispatchSecret = Deno.env.get("NOTIFICATION_DISPATCH_SECRET")?.trim();
  const serviceAccountResult = parseServiceAccount(
    Deno.env.get("FCM_SERVICE_ACCOUNT_JSON"),
  );
  if (
    !supabaseUrl ||
    !serviceRoleKey ||
    !dispatchSecret ||
    dispatchSecret.length < 32 ||
    serviceAccountResult == null
  ) {
    return json({ error: "Server is not configured" }, 500);
  }
  if (!constantTimeEqual(request.headers.get(dispatchHeader), dispatchSecret)) {
    return json({ error: "Unauthorized" }, 401);
  }

  const client = createClient(supabaseUrl, serviceRoleKey, {
    auth: { autoRefreshToken: false, persistSession: false },
  });
  const lockToken = crypto.randomUUID();
  const { data, error } = await client.rpc("claim_notification_outbox", {
    p_limit: batchSize,
    p_lock_token: lockToken,
  });
  if (error) {
    console.error("Failed to claim notification outbox", error.code);
    return json({ error: "Outbox is unavailable" }, 500);
  }

  const rows = (data ?? []) as OutboxRow[];
  if (rows.length === 0) {
    return json({ processed: 0, sent: 0, skipped: 0, retried: 0, failed: 0 });
  }

  let accessToken: string;
  try {
    accessToken = await createGoogleAccessToken(serviceAccountResult);
  } catch (error) {
    console.error("FCM authentication failed", safeErrorCode(error));
    await Promise.allSettled(
      rows.map((row) =>
        finishOutbox(client, row.id, lockToken, "retry", "FCM_AUTH_FAILED")
      ),
    );
    return json({ error: "Push provider is unavailable" }, 502);
  }

  const counts = { sent: 0, skipped: 0, retried: 0, failed: 0 };
  for (const row of rows) {
    let result: DispatchOutcome;
    try {
      result = await dispatchRow(
        client,
        serviceAccountResult.project_id,
        accessToken,
        row,
      );
    } catch (error) {
      console.error("Notification row failed", row.id, safeErrorCode(error));
      result = { outcome: "retry", reason: safeErrorCode(error) };
    }

    try {
      await finishOutbox(
        client,
        row.id,
        lockToken,
        result.outcome,
        result.reason,
      );
      if (result.outcome === "retry") counts.retried++;
      else counts[result.outcome]++;
    } catch (error) {
      console.error(
        "Failed to finish notification row",
        row.id,
        safeErrorCode(error),
      );
      counts.failed++;
    }
  }

  return json({ processed: rows.length, ...counts });
}

async function dispatchRow(
  client: EdgeSupabaseClient,
  projectId: string,
  accessToken: string,
  row: OutboxRow,
): Promise<DispatchOutcome> {
  const allowed = await pushAllowed(client, row);
  if (!allowed) return { outcome: "skipped", reason: "PUSH_MUTED" };

  const { data: deviceData, error: deviceError } = await client
    .from("notification_devices")
    .select("id, device_token, locale")
    .eq("user_id", row.user_id)
    .eq("is_active", true);
  if (deviceError) throw new Error("DEVICE_LOOKUP_FAILED");

  const devices = (deviceData ?? []) as DeviceRow[];
  if (devices.length === 0) {
    return { outcome: "skipped", reason: "NO_ACTIVE_DEVICE" };
  }

  const { data: receiptData, error: receiptError } = await client
    .from("notification_delivery_receipts")
    .select("device_id")
    .eq("outbox_id", row.id);
  if (receiptError) throw new Error("DELIVERY_RECEIPT_LOOKUP_FAILED");
  const deliveredDeviceIds = new Set(
    (receiptData ?? []).map((receipt) => receipt.device_id as string),
  );
  const pendingDevices = devices.filter(
    (device) => !deliveredDeviceIds.has(device.id),
  );
  if (pendingDevices.length === 0) {
    return { outcome: "sent", reason: null };
  }

  let transientFailure: string | null = null;
  let permanentFailure: string | null = null;
  let delivered = 0;
  let invalid = 0;

  for (const device of pendingDevices) {
    const copy = notificationCopy(row.category, device.locale);
    const response = await sendFcmMessage(
      projectId,
      accessToken,
      device.device_token,
      row,
      copy,
    );
    if (response.ok) {
      const { error: receiptInsertError } = await client
        .from("notification_delivery_receipts")
        .upsert(
          { outbox_id: row.id, device_id: device.id },
          { onConflict: "outbox_id,device_id", ignoreDuplicates: true },
        );
      if (receiptInsertError) throw new Error("DELIVERY_RECEIPT_WRITE_FAILED");
      delivered++;
      continue;
    }

    if (response.failure.kind === "invalid_token") {
      const { error: deactivateError } = await client
        .from("notification_devices")
        .update({
          is_active: false,
          updated_at: new Date().toISOString(),
        })
        .eq("id", device.id);
      if (deactivateError) throw new Error("DEVICE_DEACTIVATION_FAILED");
      invalid++;
    } else if (response.failure.kind === "retryable") {
      transientFailure ??= response.failure.code;
    } else {
      permanentFailure ??= response.failure.code;
    }
  }

  if (permanentFailure != null) {
    return { outcome: "failed", reason: `FCM_${permanentFailure}` };
  }
  if (transientFailure != null) {
    return { outcome: "retry", reason: `FCM_${transientFailure}` };
  }
  if (delivered > 0) return { outcome: "sent", reason: null };
  if (invalid === pendingDevices.length) {
    return { outcome: "skipped", reason: "ALL_TOKENS_INVALID" };
  }
  return { outcome: "retry", reason: "NO_TERMINAL_DELIVERY_STATE" };
}

async function pushAllowed(client: EdgeSupabaseClient, row: OutboxRow) {
  const { data, error } = await client.rpc("notification_push_allowed", {
    p_user_id: row.user_id,
    p_category: row.category,
    p_group_id: row.group_id,
    p_type: row.type,
  });
  if (error) throw new Error("PUSH_POLICY_LOOKUP_FAILED");
  return data === true;
}

async function finishOutbox(
  client: EdgeSupabaseClient,
  outboxId: string,
  lockToken: string,
  outcome: DispatchOutcome["outcome"],
  reason: string | null,
) {
  const { data, error } = await client.rpc("finish_notification_outbox", {
    p_outbox_id: outboxId,
    p_lock_token: lockToken,
    p_outcome: outcome,
    p_error: reason,
  });
  if (error || data !== true) throw new Error("OUTBOX_FINISH_FAILED");
}

function notificationCopy(category: string, locale: string) {
  const vietnamese = locale?.toLowerCase().startsWith("vi");
  const labels = vietnamese
    ? {
      personal: "Cá nhân",
      group: "Group",
      community: "Cộng đồng",
      system: "Hệ thống",
    }
    : {
      personal: "Personal",
      group: "Group",
      community: "Community",
      system: "System",
    };
  const categoryLabel = labels[category as keyof typeof labels] ??
    labels.system;
  const body = vietnamese
    ? category === "group"
      ? "Bạn có cập nhật mới trong group."
      : category === "community"
      ? "Bạn có cập nhật mới trong cộng đồng."
      : category === "personal"
      ? "Bạn có thông báo cá nhân mới."
      : "Bạn có cập nhật mới từ Moniary."
    : category === "group"
    ? "You have a new group update."
    : category === "community"
    ? "You have a new community update."
    : category === "personal"
    ? "You have a new personal notification."
    : "You have a new Moniary update.";
  return { title: `Moniary · ${categoryLabel}`, body };
}

async function sendFcmMessage(
  projectId: string,
  accessToken: string,
  token: string,
  row: OutboxRow,
  copy: { title: string; body: string },
) {
  const metadata = row.metadata ?? {};
  const data: Record<string, string> = {
    notification_id: row.id,
    category: row.category,
    type: row.type,
    channel_name: copy.title,
    channel_description: copy.body,
  };
  if (row.group_id) data.group_id = row.group_id;
  if (typeof metadata.group_transaction_id === "string") {
    data.group_transaction_id = metadata.group_transaction_id;
  }
  if (typeof metadata.friend_request_id === "string") {
    data.friend_request_id = metadata.friend_request_id;
  }

  const response = await fetch(
    `https://fcm.googleapis.com/v1/projects/${
      encodeURIComponent(projectId)
    }/messages:send`,
    {
      method: "POST",
      headers: {
        Authorization: `Bearer ${accessToken}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        message: {
          token,
          notification: copy,
          data,
          android: {
            notification: { channel_id: `moniary_${row.category}` },
          },
          apns: {
            payload: { aps: { "thread-id": `moniary_${row.category}` } },
          },
        },
      }),
      signal: AbortSignal.timeout(15_000),
    },
  );
  if (response.ok) return { ok: true as const };

  const payload = await response.json().catch(() => null);
  return {
    ok: false as const,
    failure: classifyFcmFailure(response.status, payload),
  };
}

function parseServiceAccount(value: string | undefined): ServiceAccount | null {
  if (!value) return null;
  try {
    const parsed = JSON.parse(value) as Partial<ServiceAccount>;
    if (
      typeof parsed.project_id !== "string" ||
      parsed.project_id.trim().length < 4 ||
      typeof parsed.client_email !== "string" ||
      !parsed.client_email.includes("@") ||
      typeof parsed.private_key !== "string" ||
      !parsed.private_key.includes("-----BEGIN PRIVATE KEY-----")
    ) {
      return null;
    }
    return {
      project_id: parsed.project_id.trim(),
      client_email: parsed.client_email.trim(),
      private_key: parsed.private_key,
    };
  } catch {
    return null;
  }
}

async function createGoogleAccessToken(account: ServiceAccount) {
  const now = Math.floor(Date.now() / 1000);
  const header = base64Url(JSON.stringify({ alg: "RS256", typ: "JWT" }));
  const claim = base64Url(
    JSON.stringify({
      iss: account.client_email,
      scope: "https://www.googleapis.com/auth/firebase.messaging",
      aud: "https://oauth2.googleapis.com/token",
      iat: now,
      exp: now + 3600,
    }),
  );
  const unsigned = `${header}.${claim}`;
  const key = await crypto.subtle.importKey(
    "pkcs8",
    pemToBytes(account.private_key),
    { name: "RSASSA-PKCS1-v1_5", hash: "SHA-256" },
    false,
    ["sign"],
  );
  const signature = await crypto.subtle.sign(
    "RSASSA-PKCS1-v1_5",
    key,
    new TextEncoder().encode(unsigned),
  );
  const assertion = `${unsigned}.${base64Url(signature)}`;
  const response = await fetch("https://oauth2.googleapis.com/token", {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body: new URLSearchParams({
      grant_type: "urn:ietf:params:oauth:grant-type:jwt-bearer",
      assertion,
    }),
    signal: AbortSignal.timeout(15_000),
  });
  if (!response.ok) throw new Error(`GOOGLE_TOKEN_HTTP_${response.status}`);
  const body = await response.json() as { access_token?: unknown };
  if (typeof body.access_token !== "string" || body.access_token.length === 0) {
    throw new Error("GOOGLE_TOKEN_MISSING");
  }
  return body.access_token;
}

function pemToBytes(pem: string) {
  const encoded = pem.replace(/-----BEGIN PRIVATE KEY-----/g, "")
    .replace(/-----END PRIVATE KEY-----/g, "")
    .replace(/\s/g, "");
  const binary = atob(encoded);
  return Uint8Array.from(binary, (character) => character.charCodeAt(0));
}

function base64Url(value: string | ArrayBuffer) {
  const bytes = typeof value === "string"
    ? new TextEncoder().encode(value)
    : new Uint8Array(value);
  let binary = "";
  for (const byte of bytes) binary += String.fromCharCode(byte);
  return btoa(binary).replace(/\+/g, "-").replace(/\//g, "_").replace(
    /=+$/,
    "",
  );
}

function safeErrorCode(error: unknown) {
  if (!(error instanceof Error)) return "UNKNOWN_ERROR";
  return error.message.replace(/[^A-Z0-9_:-]/gi, "_").slice(0, 160);
}

function json(body: unknown, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { "Content-Type": "application/json" },
  });
}
