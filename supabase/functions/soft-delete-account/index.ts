import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
};

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  if (req.method !== 'POST') {
    return json({ error: 'Method not allowed' }, 405);
  }

  const supabaseUrl = Deno.env.get('SUPABASE_URL');
  const anonKey = Deno.env.get('SUPABASE_ANON_KEY');
  const serviceRoleKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY');

  if (!supabaseUrl || !anonKey || !serviceRoleKey) {
    return json({ error: 'Server is not configured' }, 500);
  }

  const authHeader = req.headers.get('Authorization');
  if (!authHeader) {
    return json({ error: 'Missing Authorization header' }, 401);
  }

  const userClient = createClient(supabaseUrl, anonKey, {
    global: { headers: { Authorization: authHeader } },
  });
  
  const { data: userData, error: userError } = await userClient.auth.getUser();
  if (userError || !userData.user) {
    return json({ error: 'Invalid user session' }, 401);
  }

  const userId = userData.user.id;
  const adminClient = createClient(supabaseUrl, serviceRoleKey);

  let payload: Record<string, unknown>;
  try {
    payload = await req.json();
  } catch {
    return json({ error: 'Invalid JSON payload' }, 400);
  }

  const validReasons = new Set([
    'difficult_to_use',
    'missing_features',
    'technical_issues',
    'privacy_concerns',
    'no_longer_needed',
    'other',
  ]);
  const reasonCode = typeof payload.reasonCode === 'string'
    ? payload.reasonCode.trim()
    : '';
  const details = typeof payload.details === 'string'
    ? payload.details.trim()
    : null;
  const appVersion = typeof payload.appVersion === 'string'
    ? payload.appVersion.trim()
    : '';
  const platform = typeof payload.platform === 'string'
    ? payload.platform.trim()
    : '';
  const locale = typeof payload.locale === 'string'
    ? payload.locale.trim()
    : '';

  if (!validReasons.has(reasonCode)) {
    return json({ error: 'Invalid deletion reason' }, 400);
  }
  if (details && details.length > 500) {
    return json({ error: 'Deletion details are too long' }, 400);
  }
  if (!appVersion || !platform || !locale) {
    return json({ error: 'Missing feedback context' }, 400);
  }

  const deletedAt = new Date().toISOString();

  const { error: updateError } = await adminClient
    .from('profiles')
    .update({ deleted_at: deletedAt })
    .eq('id', userId);

  if (updateError) {
    return json({ error: updateError.message }, 500);
  }

  const { error: feedbackError } = await adminClient
    .from('account_deletion_feedback')
    .insert({
      reason_code: reasonCode,
      details: details || null,
      app_version: appVersion,
      platform,
      locale,
    });

  if (feedbackError) {
    console.error('Failed to store account deletion feedback', feedbackError);
  }

  return json({
    success: true,
    deleted_at: deletedAt,
    feedbackRecorded: !feedbackError,
  });
});

function json(body: Record<string, unknown>, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: {
      ...corsHeaders,
      'Content-Type': 'application/json',
    },
  });
}
