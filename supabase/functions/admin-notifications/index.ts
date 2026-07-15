import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

type Category = 'personal' | 'group' | 'community' | 'system';
type Audience = 'all' | 'active_device_users' | 'user_ids' | 'username_or_email';

type AdminNotificationPayload = {
  title?: string;
  body?: string;
  titleVi?: string;
  bodyVi?: string;
  titleEn?: string;
  bodyEn?: string;
  category?: Category;
  type?: string;
  audience?: Audience;
  userIds?: string[];
  query?: string;
  actionUrl?: string;
  data?: Record<string, unknown>;
  dedupKey?: string;
  dryRun?: boolean;
  dispatchNow?: boolean;
  createdBy?: string;
};

type Recipient = { id: string };

const SUPABASE_URL = Deno.env.get('SUPABASE_URL');
const SERVICE_ROLE_KEY = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY');
const ADMIN_SECRET = Deno.env.get('ADMIN_NOTIFICATION_SECRET');
const DISPATCH_SECRET = Deno.env.get('NOTIFICATION_DISPATCH_SECRET');

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers':
    'authorization, x-client-info, apikey, content-type, x-admin-notification-secret',
  'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
};

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response(null, { status: 204, headers: corsHeaders });
  }

  if (!ADMIN_SECRET) {
    return json({ error: 'ADMIN_NOTIFICATION_SECRET is not configured' }, 500);
  }
  if (req.headers.get('x-admin-notification-secret') !== ADMIN_SECRET) {
    return json({ error: 'Unauthorized' }, 401);
  }
  if (!SUPABASE_URL || !SERVICE_ROLE_KEY) {
    return json({ error: 'Supabase is not configured' }, 500);
  }

  const supabase = createClient(SUPABASE_URL, SERVICE_ROLE_KEY);

  if (req.method === 'GET') {
    return summary(supabase);
  }
  if (req.method !== 'POST') {
    return json({ error: 'Method not allowed' }, 405);
  }

  let payload: AdminNotificationPayload;
  try {
    payload = await req.json();
  } catch {
    return json({ error: 'Invalid JSON body' }, 400);
  }

  const validationError = validatePayload(payload);
  if (validationError) return json({ error: validationError }, 400);

  const audience = payload.audience ?? 'active_device_users';
  const recipientsResult = await resolveRecipients(supabase, audience, payload);
  if (recipientsResult.error) return json({ error: recipientsResult.error }, 400);

  const recipients = recipientsResult.recipients;
  if (payload.dryRun) {
    return json({
      dryRun: true,
      audience,
      targetCount: recipients.length,
    });
  }

  if (recipients.length === 0) {
    return json({ error: 'No matching recipients' }, 400);
  }

  const category = payload.category ?? 'system';
  const type = normalizeType(payload.type);
  const metadata = notificationMetadata(payload);

  const { data: campaign, error: campaignError } = await supabase
    .from('admin_notification_campaigns')
    .insert({
      title: payload.title!.trim(),
      body: payload.body!.trim(),
      category,
      type,
      audience,
      target_count: recipients.length,
      queued_count: 0,
      metadata: {
        action_url: normalizedText(payload.actionUrl),
        data: sanitizeData(payload.data),
        title_vi: normalizedText(payload.titleVi),
        body_vi: normalizedText(payload.bodyVi),
        title_en: normalizedText(payload.titleEn),
        body_en: normalizedText(payload.bodyEn),
      },
      created_by: normalizedText(payload.createdBy),
    })
    .select('id')
    .single();

  if (campaignError) return json({ error: campaignError.message }, 500);

  const rows = recipients.map((recipient) => ({
    user_id: recipient.id,
    category,
    type,
    metadata: {
      ...metadata,
      admin_campaign_id: campaign.id,
      dedup_key: payload.dedupKey?.trim()
        ? `${payload.dedupKey.trim()}:${recipient.id}`
        : `admin:${campaign.id}:${recipient.id}`,
    },
  }));

  let queuedCount = 0;
  let failedCount = 0;
  for (const chunk of chunks(rows, 500)) {
    const { data, error } = await supabase
      .from('app_notifications')
      .insert(chunk)
      .select('id');
    if (error) {
      failedCount += chunk.length;
      continue;
    }
    queuedCount += data?.length ?? 0;
  }

  let dispatchResult: unknown = null;
  if (payload.dispatchNow && queuedCount > 0) {
    dispatchResult = await dispatchPendingNotifications(queuedCount);
  }

  const patch: Record<string, unknown> = {
    queued_count: queuedCount,
    failed_count: failedCount,
  };
  if (dispatchResult) {
    patch.dispatched_at = new Date().toISOString();
    patch.dispatch_result = dispatchResult;
  }
  await supabase
    .from('admin_notification_campaigns')
    .update(patch)
    .eq('id', campaign.id);

  return json({
    campaignId: campaign.id,
    targetCount: recipients.length,
    queuedCount,
    failedCount,
    dispatchResult,
  });
});

function validatePayload(payload: AdminNotificationPayload) {
  if (!normalizedText(payload.title)) return 'Title is required';
  if (!normalizedText(payload.body)) return 'Body is required';
  if ((payload.title?.trim().length ?? 0) > 120) {
    return 'Title must be 120 characters or less';
  }
  if ((payload.body?.trim().length ?? 0) > 500) {
    return 'Body must be 500 characters or less';
  }
  if (payload.category && !['personal', 'group', 'community', 'system'].includes(payload.category)) {
    return 'Invalid category';
  }
  if (payload.audience && !['all', 'active_device_users', 'user_ids', 'username_or_email'].includes(payload.audience)) {
    return 'Invalid audience';
  }
  if ((payload.type?.trim().length ?? 0) > 64) return 'Type is too long';
  if ((payload.dedupKey?.trim().length ?? 0) > 96) return 'Dedup key is too long';
  return null;
}

async function resolveRecipients(
  supabase: ReturnType<typeof createClient>,
  audience: Audience,
  payload: AdminNotificationPayload,
): Promise<{ recipients: Recipient[]; error?: string }> {
  if (audience === 'user_ids') {
    const ids = [...new Set((payload.userIds ?? []).map((id) => id.trim()).filter(Boolean))];
    if (ids.length === 0) return { recipients: [], error: 'At least one user id is required' };
    const { data, error } = await supabase.from('profiles').select('id').in('id', ids).limit(5000);
    if (error) return { recipients: [], error: error.message };
    return { recipients: (data ?? []) as Recipient[] };
  }

  if (audience === 'username_or_email') {
    const query = payload.query?.trim().toLowerCase();
    if (!query) return { recipients: [], error: 'Username or email query is required' };
    const [usernameResult, emailResult] = await Promise.all([
      supabase.from('profiles').select('id').eq('username', query).limit(50),
      supabase.from('profiles').select('id').eq('email', query).limit(50),
    ]);
    if (usernameResult.error) {
      return { recipients: [], error: usernameResult.error.message };
    }
    if (emailResult.error) return { recipients: [], error: emailResult.error.message };

    const ids = [
      ...new Set([
        ...(usernameResult.data ?? []).map((row) => row.id as string),
        ...(emailResult.data ?? []).map((row) => row.id as string),
      ]),
    ];
    return { recipients: ids.map((id) => ({ id })) };
  }

  if (audience === 'active_device_users') {
    const { data, error } = await supabase
      .from('notification_devices')
      .select('user_id')
      .eq('is_active', true)
      .limit(5000);
    if (error) return { recipients: [], error: error.message };
    const ids = [...new Set((data ?? []).map((row) => row.user_id as string).filter(Boolean))];
    return { recipients: ids.map((id) => ({ id })) };
  }

  const { data, error } = await supabase.from('profiles').select('id').limit(5000);
  if (error) return { recipients: [], error: error.message };
  return { recipients: (data ?? []) as Recipient[] };
}

async function summary(supabase: ReturnType<typeof createClient>) {
  const [campaigns, users, devices, pending] = await Promise.all([
    supabase
      .from('admin_notification_campaigns')
      .select('id,title,body,category,type,audience,target_count,queued_count,failed_count,dispatched_at,dispatch_result,created_by,created_at')
      .order('created_at', { ascending: false })
      .limit(20),
    supabase.from('profiles').select('id', { count: 'exact', head: true }),
    supabase
      .from('notification_devices')
      .select('id', { count: 'exact', head: true })
      .eq('is_active', true),
    supabase
      .from('notification_outbox')
      .select('id', { count: 'exact', head: true })
      .is('sent_at', null),
  ]);

  if (campaigns.error) return json({ error: campaigns.error.message }, 500);
  return json({
    campaigns: campaigns.data ?? [],
    stats: {
      users: users.count ?? 0,
      activeDevices: devices.count ?? 0,
      pendingOutbox: pending.count ?? 0,
    },
  });
}

function notificationMetadata(payload: AdminNotificationPayload) {
  return {
    title: payload.title!.trim(),
    body: payload.body!.trim(),
    title_vi: normalizedText(payload.titleVi),
    body_vi: normalizedText(payload.bodyVi),
    title_en: normalizedText(payload.titleEn),
    body_en: normalizedText(payload.bodyEn),
    action_url: normalizedText(payload.actionUrl),
    data: sanitizeData(payload.data),
  };
}

function sanitizeData(data: Record<string, unknown> | undefined) {
  if (!data || typeof data !== 'object' || Array.isArray(data)) return {};
  const sanitized: Record<string, string> = {};
  for (const [key, value] of Object.entries(data)) {
    if (!/^[a-zA-Z0-9_:-]{1,40}$/.test(key)) continue;
    if (['string', 'number', 'boolean'].includes(typeof value)) {
      sanitized[key] = String(value).slice(0, 500);
    }
  }
  return sanitized;
}

async function dispatchPendingNotifications(expectedCount: number) {
  const batches: Array<{ ok: boolean; status: number; body: unknown }> = [];
  const totals = { processed: 0, sent: 0, skipped: 0, failed: 0 };
  const maxBatches = Math.min(20, Math.max(1, Math.ceil(expectedCount / 50) + 2));

  try {
    const headers: Record<string, string> = { 'Content-Type': 'application/json' };
    if (DISPATCH_SECRET) headers['x-notification-dispatch-secret'] = DISPATCH_SECRET;

    for (let index = 0; index < maxBatches; index++) {
      const response = await fetch(`${SUPABASE_URL}/functions/v1/notification-dispatcher`, {
        method: 'POST',
        headers,
        body: '{}',
      });
      const text = await response.text();
      let body: unknown = text;
      try {
        body = JSON.parse(text);
      } catch {
        // Keep the raw response text.
      }

      batches.push({ ok: response.ok, status: response.status, body });
      if (!response.ok || !isDispatchBody(body)) break;

      totals.processed += body.processed;
      totals.sent += body.sent;
      totals.skipped += body.skipped;
      totals.failed += body.failed;

      if (body.processed < 50 || totals.processed >= expectedCount) break;
    }

    return { ok: batches.every((batch) => batch.ok), totals, batches };
  } catch (error) {
    return { ok: false, error: error instanceof Error ? error.message : String(error) };
  }
}

function isDispatchBody(
  value: unknown,
): value is { processed: number; sent: number; skipped: number; failed: number } {
  if (!value || typeof value !== 'object') return false;
  const body = value as Record<string, unknown>;
  return ['processed', 'sent', 'skipped', 'failed'].every((key) =>
    typeof body[key] === 'number'
  );
}

function normalizeType(value: string | undefined) {
  const normalized = value?.trim().toLowerCase().replace(/[^a-z0-9_:-]/g, '_');
  return normalized || 'admin_broadcast';
}

function normalizedText(value: string | undefined) {
  const normalized = value?.trim();
  return normalized ? normalized : null;
}

function chunks<T>(values: T[], size: number) {
  const output: T[][] = [];
  for (let index = 0; index < values.length; index += size) {
    output.push(values.slice(index, index + size));
  }
  return output;
}

function json(body: unknown, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: {
      ...corsHeaders,
      'Content-Type': 'application/json',
    },
  });
}
