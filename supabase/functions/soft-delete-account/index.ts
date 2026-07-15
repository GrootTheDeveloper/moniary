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
    auth: { autoRefreshToken: false, persistSession: false },
  });

  const { data: userData, error: userError } = await userClient.auth.getUser();
  if (userError || !userData.user) {
    return json({ error: 'Invalid user session' }, 401);
  }

  const userId = userData.user.id;
  const adminClient = createClient(supabaseUrl, serviceRoleKey, {
    auth: { autoRefreshToken: false, persistSession: false },
  });

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
  const validPlatforms = new Set([
    'android',
    'fuchsia',
    'iOS',
    'linux',
    'macOS',
    'windows',
  ]);
  if (
    !appVersion || appVersion.length > 64 ||
    !validPlatforms.has(platform) ||
    !locale || locale.length > 32
  ) {
    return json({ error: 'Missing feedback context' }, 400);
  }

  const { data: existingProfile, error: profileError } = await adminClient
    .from('profiles')
    .select('deleted_at')
    .eq('id', userId)
    .maybeSingle();

  if (profileError) {
    return json({ error: profileError.message }, 500);
  }
  if (!existingProfile) {
    return json({ error: 'Profile not found' }, 404);
  }

  const existingDeletedAt = typeof existingProfile.deleted_at === 'string'
    ? existingProfile.deleted_at
    : null;
  if (existingDeletedAt) {
    return json({
      success: true,
      deleted_at: existingDeletedAt,
      feedbackRecorded: false,
      alreadyPending: true,
    });
  }

  const requestedDeletedAt = new Date().toISOString();
  const { data: updatedProfile, error: updateError } = await adminClient
    .from('profiles')
    .update({ deleted_at: requestedDeletedAt })
    .eq('id', userId)
    .is('deleted_at', null)
    .select('deleted_at')
    .maybeSingle();

  if (updateError) {
    return json({ error: updateError.message }, 500);
  }

  // A concurrent request may have transitioned the same account first. Read
  // back the canonical timestamp so the 30-day deadline is never extended.
  let deletedAt = updatedProfile?.deleted_at as string | undefined;
  if (!deletedAt) {
    const { data: concurrentProfile, error: concurrentError } = await adminClient
      .from('profiles')
      .select('deleted_at')
      .eq('id', userId)
      .maybeSingle();
    if (concurrentError || typeof concurrentProfile?.deleted_at !== 'string') {
      return json({ error: concurrentError?.message ?? 'Deletion request failed' }, 500);
    }
    deletedAt = concurrentProfile.deleted_at;
  }

  let feedbackRecorded = false;
  if (updatedProfile) {
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
    } else {
      feedbackRecorded = true;
    }
  }

  const accessToken = authHeader.replace(/^Bearer\s+/i, '').trim();
  if (accessToken) {
    const { error: signOutError } = await adminClient.auth.admin.signOut(
      accessToken,
      'global',
    );
    if (signOutError) {
      console.error('Failed to revoke account sessions', signOutError);
    }
  }

  return json({
    success: true,
    deleted_at: deletedAt,
    feedbackRecorded,
    alreadyPending: !updatedProfile,
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
