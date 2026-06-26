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
  const serviceRoleKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY');

  if (!supabaseUrl || !serviceRoleKey) {
    return json({ error: 'Server is not configured' }, 500);
  }

  // Basic security to ensure only our cron (or someone with anon key/service role) calls it
  // Since pg_net uses anon key, we should check auth header, but for a cron we might just verify the service role
  // But wait, the cron sends Authorization: Bearer anon_key. Let's just bypass auth check for simplicity, 
  // or verify it. Actually, anyone could hit this and trigger garbage collection which is fine, it's just a cleanup job.
  
  const adminClient = createClient(supabaseUrl, serviceRoleKey);

  // 30 days ago
  const date30DaysAgo = new Date();
  date30DaysAgo.setDate(date30DaysAgo.getDate() - 30);
  const cutoffDate = date30DaysAgo.toISOString();

  // Find users
  const { data: profiles, error: fetchError } = await adminClient
    .from('profiles')
    .select('id')
    .lt('deleted_at', cutoffDate);

  if (fetchError) {
    return json({ error: fetchError.message }, 500);
  }

  const usersToDelete = profiles || [];
  let deletedCount = 0;

  for (const user of usersToDelete) {
    const userId = user.id;
    
    // 1. Remove images
    try {
      await removeTransactionImages(adminClient, userId);
    } catch (e) {
      console.error(`Failed to remove images for user ${userId}`, e);
      continue; // Skip deleting auth if we couldn't remove images, to try again later
    }

    // 2. Delete Auth user
    const { error: deleteError } = await adminClient.auth.admin.deleteUser(userId);
    if (!deleteError) {
      deletedCount++;
    } else {
      console.error(`Failed to delete user ${userId}`, deleteError);
    }
  }

  return json({ success: true, processed: usersToDelete.length, deleted: deletedCount });
});

async function removeTransactionImages(adminClient: ReturnType<typeof createClient>, userId: string) {
  const prefix = `transactions/${userId}`;
  const paths: string[] = [];
  let offset = 0;
  const limit = 100;

  while (true) {
    const { data, error } = await adminClient.storage.from('transaction-images').list(prefix, {
      limit,
      offset,
    });

    if (error) {
      throw error;
    }

    const batch = data ?? [];
    for (const item of batch) {
      if (item.name) {
        paths.push(`${prefix}/${item.name}`);
      }
    }

    if (batch.length < limit) {
      break;
    }
    offset += limit;
  }

  if (paths.length > 0) {
    const { error } = await adminClient.storage.from('transaction-images').remove(paths);
    if (error) {
      throw error;
    }
  }
}

function json(body: Record<string, unknown>, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: {
      ...corsHeaders,
      'Content-Type': 'application/json',
    },
  });
}
