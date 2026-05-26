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
    return json({ error: 'Server is not configured for account deletion' }, 500);
  }

  const authHeader = req.headers.get('Authorization');
  if (!authHeader) {
    return json({ error: 'Missing Authorization header' }, 401);
  }

  const userClient = createClient(supabaseUrl, anonKey, {
    global: { headers: { Authorization: authHeader } },
  });
  const adminClient = createClient(supabaseUrl, serviceRoleKey);

  const { data: userData, error: userError } = await userClient.auth.getUser();
  if (userError || !userData.user) {
    return json({ error: 'Invalid user session' }, 401);
  }

  const userId = userData.user.id;
  try {
    await removeTransactionImages(adminClient, userId);
  } catch (error) {
    return json({ error: readableError(error) }, 500);
  }

  const { error: deleteUserError } = await adminClient.auth.admin.deleteUser(userId);
  if (deleteUserError) {
    return json({ error: deleteUserError.message }, 500);
  }

  return json({ deleted: true });
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

function readableError(error: unknown) {
  if (error instanceof Error) {
    return error.message;
  }
  return 'Could not delete account data';
}
