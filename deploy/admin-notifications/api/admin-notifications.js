module.exports = async function handler(request, response) {
  if (request.method === 'OPTIONS') {
    response.status(204).end();
    return;
  }

  if (!['GET', 'POST'].includes(request.method)) {
    response.status(405).json({ error: 'Method not allowed' });
    return;
  }

  const functionUrl = notificationFunctionUrl();
  const adminSecret = process.env.ADMIN_NOTIFICATION_SECRET;
  if (!functionUrl || !adminSecret) {
    response.status(500).json({
      error:
        'Vercel is missing ADMIN_NOTIFICATION_SECRET and Supabase function URL configuration',
    });
    return;
  }

  try {
    const upstream = await fetch(functionUrl, {
      method: request.method,
      headers: {
        'Content-Type': 'application/json',
        'x-admin-notification-secret': adminSecret,
      },
      body: request.method === 'GET' ? undefined : JSON.stringify(request.body ?? {}),
    });

    const text = await upstream.text();
    response.status(upstream.status);
    response.setHeader(
      'Content-Type',
      upstream.headers.get('content-type') || 'application/json',
    );
    response.send(text);
  } catch (error) {
    response.status(502).json({
      error: error instanceof Error ? error.message : String(error),
    });
  }
};

function notificationFunctionUrl() {
  const explicit =
    process.env.ADMIN_NOTIFICATION_FUNCTION_URL ||
    process.env.SUPABASE_ADMIN_NOTIFICATION_URL;
  if (explicit) return explicit;

  const supabaseUrl = process.env.SUPABASE_URL;
  if (!supabaseUrl) return null;
  return `${supabaseUrl.replace(/\/+$/, '')}/functions/v1/admin-notifications`;
}
