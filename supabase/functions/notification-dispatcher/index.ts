import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

type ServiceAccount = {
  project_id: string;
  client_email: string;
  private_key: string;
};

type OutboxRow = {
  id: string;
  notification_id: string;
  user_id: string;
  category: string;
  type: string;
  group_id: string | null;
  metadata: Record<string, unknown>;
  attempt_count: number;
};

const SUPABASE_URL = Deno.env.get('SUPABASE_URL');
const SERVICE_ROLE_KEY = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY');
const DISPATCH_SECRET = Deno.env.get('NOTIFICATION_DISPATCH_SECRET');

Deno.serve(async (req) => {
  if (req.method !== 'POST') {
    return json({ error: 'Method not allowed' }, 405);
  }

  if (DISPATCH_SECRET && req.headers.get('x-notification-dispatch-secret') !== DISPATCH_SECRET) {
    return json({ error: 'Unauthorized' }, 401);
  }

  if (!SUPABASE_URL || !SERVICE_ROLE_KEY) {
    return json({ error: 'Supabase is not configured' }, 500);
  }

  const serviceAccountJson = Deno.env.get('FCM_SERVICE_ACCOUNT_JSON');
  if (!serviceAccountJson) {
    return json({ error: 'FCM is not configured' }, 500);
  }

  let serviceAccount: ServiceAccount;
  try {
    serviceAccount = JSON.parse(serviceAccountJson) as ServiceAccount;
  } catch {
    return json({ error: 'FCM service account is invalid' }, 500);
  }

  const supabase = createClient(SUPABASE_URL, SERVICE_ROLE_KEY);
  const { data: rows, error } = await supabase
    .from('notification_outbox')
    .select(
      'id, notification_id, user_id, category, type, group_id, metadata, attempt_count',
    )
    .is('sent_at', null)
    .lte('next_attempt_at', new Date().toISOString())
    .order('created_at', { ascending: true })
    .limit(50);

  if (error) return json({ error: error.message }, 500);

  const accessToken = await createGoogleAccessToken(serviceAccount);
  let sent = 0;
  let skipped = 0;
  let failed = 0;

  for (const row of (rows ?? []) as OutboxRow[]) {
    let allowed: boolean;
    try {
      allowed = await pushAllowed(supabase, row);
    } catch (error) {
      await retryLater(supabase, row, 'PUSH_POLICY_CHECK_FAILED');
      failed++;
      console.error('Push policy check failed', row.id, error);
      continue;
    }
    if (!allowed) {
      if (
        !(await markDoneWithRetry(
          supabase,
          row,
          'PUSH_MUTED',
          'OUTBOX_UPDATE_FAILED',
        ))
      ) {
        failed++;
        continue;
      }
      skipped++;
      continue;
    }

    const { data: devices, error: devicesError } = await supabase
      .from('notification_devices')
      .select('id, device_token, locale')
      .eq('user_id', row.user_id)
      .eq('is_active', true);

    if (devicesError) {
      await retryLater(supabase, row, 'DEVICE_LOOKUP_FAILED');
      failed++;
      console.error('Notification device lookup failed', row.id, devicesError);
      continue;
    }

    if (!devices || devices.length === 0) {
      if (
        !(await markDoneWithRetry(
          supabase,
          row,
          'NO_ACTIVE_DEVICE',
          'OUTBOX_UPDATE_FAILED',
        ))
      ) {
        failed++;
        continue;
      }
      skipped++;
      continue;
    }

    let rowFailed = false;
    for (const device of devices) {
      const copy = notificationCopy(row.category, row.type, device.locale);
      const response = await sendFcmMessage(
        serviceAccount.project_id,
        accessToken,
        device.device_token,
        row,
        copy,
      );
      if (!response.ok) {
        rowFailed = true;
        if (response.invalidToken) {
          await supabase
            .from('notification_devices')
            .update({ is_active: false })
            .eq('id', device.id);
        }
      }
    }

    if (rowFailed) {
      await retryLater(supabase, row, 'FCM_SEND_FAILED');
      failed++;
    } else {
      if (
        !(await markDoneWithRetry(
          supabase,
          row,
          null,
          'OUTBOX_UPDATE_FAILED',
        ))
      ) {
        failed++;
        continue;
      }
      sent++;
    }
  }

  return json({ processed: (rows ?? []).length, sent, skipped, failed });
});

async function pushAllowed(client: ReturnType<typeof createClient>, row: OutboxRow) {
  const { data, error } = await client.rpc('notification_push_allowed', {
    p_user_id: row.user_id,
    p_category: row.category,
    p_group_id: row.group_id,
    p_type: row.type,
  });
  if (error) throw error;
  return data === true;
}

function notificationCopy(category: string, type: string, locale: string) {
  const vietnamese = locale?.toLowerCase().startsWith('vi');
  const labels = vietnamese
    ? { personal: 'Cá nhân', group: 'Group', community: 'Cộng đồng', system: 'Hệ thống' }
    : { personal: 'Personal', group: 'Group', community: 'Community', system: 'System' };
  const categoryLabel = labels[category as keyof typeof labels] ?? labels.system;
  const body = vietnamese
    ? category === 'group'
      ? 'Bạn có cập nhật mới trong group.'
      : category === 'community'
        ? 'Bạn có cập nhật mới trong cộng đồng.'
        : category === 'personal'
          ? 'Bạn có thông báo cá nhân mới.'
          : 'Bạn có cập nhật mới từ Moniary.'
    : category === 'group'
      ? 'You have a new group update.'
      : category === 'community'
        ? 'You have a new community update.'
        : category === 'personal'
          ? 'You have a new personal notification.'
          : 'You have a new Moniary update.';
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
    notification_id: row.notification_id,
    category: row.category,
    type: row.type,
    channel_name: copy.title,
    channel_description: copy.body,
  };
  if (row.group_id) data.group_id = row.group_id;
  if (typeof metadata.group_transaction_id === 'string') {
    data.group_transaction_id = metadata.group_transaction_id;
  }
  if (typeof metadata.friend_request_id === 'string') {
    data.friend_request_id = metadata.friend_request_id;
  }

  const response = await fetch(
    `https://fcm.googleapis.com/v1/projects/${projectId}/messages:send`,
    {
      method: 'POST',
      headers: {
        Authorization: `Bearer ${accessToken}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        message: {
          token,
          notification: copy,
          data,
          android: {
            notification: {
              channel_id: `moniary_${row.category}`,
            },
          },
          apns: {
            payload: {
              aps: { 'thread-id': `moniary_${row.category}` },
            },
          },
        },
      }),
    },
  );
  if (response.ok) return { ok: true, invalidToken: false };
  const message = await response.text();
  const normalizedMessage = message.toLowerCase();
  return {
    ok: false,
    invalidToken:
      normalizedMessage.includes('unregistered') ||
      normalizedMessage.includes('registration-token-not-registered'),
    message,
  };
}

async function markDone(
  client: ReturnType<typeof createClient>,
  id: string,
  reason: string | null,
) {
  const { error } = await client
    .from('notification_outbox')
    .update({ sent_at: new Date().toISOString(), last_error: reason })
    .eq('id', id)
    .is('sent_at', null);
  if (error) throw error;
}

async function markDoneWithRetry(
  client: ReturnType<typeof createClient>,
  row: OutboxRow,
  reason: string | null,
  retryReason: string,
) {
  try {
    await markDone(client, row.id, reason);
    return true;
  } catch (error) {
    console.error('Notification outbox update failed', row.id, error);
    try {
      await retryLater(client, row, retryReason);
    } catch (retryError) {
      console.error('Notification outbox retry update failed', row.id, retryError);
    }
    return false;
  }
}

async function retryLater(
  client: ReturnType<typeof createClient>,
  row: OutboxRow,
  reason: string,
) {
  const { error } = await client
    .from('notification_outbox')
    .update({
      attempt_count: row.attempt_count + 1,
      next_attempt_at: new Date(Date.now() + 5 * 60 * 1000).toISOString(),
      last_error: reason,
    })
    .eq('id', row.id)
    .eq('attempt_count', row.attempt_count)
    .is('sent_at', null);
  if (error) throw error;
}

async function createGoogleAccessToken(account: ServiceAccount) {
  const now = Math.floor(Date.now() / 1000);
  const header = base64Url(JSON.stringify({ alg: 'RS256', typ: 'JWT' }));
  const claim = base64Url(
    JSON.stringify({
      iss: account.client_email,
      scope: 'https://www.googleapis.com/auth/firebase.messaging',
      aud: 'https://oauth2.googleapis.com/token',
      iat: now,
      exp: now + 3600,
    }),
  );
  const unsigned = `${header}.${claim}`;
  const key = await crypto.subtle.importKey(
    'pkcs8',
    pemToBytes(account.private_key),
    { name: 'RSASSA-PKCS1-v1_5', hash: 'SHA-256' },
    false,
    ['sign'],
  );
  const signature = await crypto.subtle.sign(
    'RSASSA-PKCS1-v1_5',
    key,
    new TextEncoder().encode(unsigned),
  );
  const assertion = `${unsigned}.${base64Url(signature)}`;
  const response = await fetch('https://oauth2.googleapis.com/token', {
    method: 'POST',
    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
    body: new URLSearchParams({
      grant_type: 'urn:ietf:params:oauth:grant-type:jwt-bearer',
      assertion,
    }),
  });
  if (!response.ok) throw new Error(`Google token request failed: ${await response.text()}`);
  const body = await response.json();
  return body.access_token as string;
}

function pemToBytes(pem: string) {
  const encoded = pem.replace(/-----BEGIN PRIVATE KEY-----/g, '')
    .replace(/-----END PRIVATE KEY-----/g, '')
    .replace(/\s/g, '');
  const binary = atob(encoded);
  return Uint8Array.from(binary, (char) => char.charCodeAt(0));
}

function base64Url(value: string | ArrayBuffer) {
  const bytes = typeof value === 'string'
    ? new TextEncoder().encode(value)
    : new Uint8Array(value);
  let binary = '';
  for (const byte of bytes) binary += String.fromCharCode(byte);
  return btoa(binary).replace(/\+/g, '-').replace(/\//g, '_').replace(/=+$/, '');
}

function json(body: unknown, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { 'Content-Type': 'application/json' },
  });
}
