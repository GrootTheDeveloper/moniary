import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers':
    'authorization, x-client-info, apikey, content-type',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
};

const financialKinds = new Set([
  'monthlyTotal',
  'weeklyComparison',
  'dailyAverage',
  'topCategory',
  'recurringExpenses',
  'savingSuggestion',
]);

type AssistantHistoryItem = {
  role: 'user' | 'assistant';
  text: string;
};

type AssistantPayload = {
  question?: unknown;
  kind?: unknown;
  locale?: unknown;
  currencyCode?: unknown;
  profileName?: unknown;
  snapshot?: unknown;
  history?: unknown;
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
  const geminiApiKey = Deno.env.get('GEMINI_API_KEY');
  const geminiModel = Deno.env.get('GEMINI_MODEL') ?? 'gemini-2.5-flash';
  const blockedGeminiKeyDigests = parseSha256DigestList(
    Deno.env.get('GEMINI_BLOCKED_KEY_SHA256'),
  );

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
  const { data: userData, error: userError } =
    await userClient.auth.getUser();
  if (userError || !userData.user) {
    return json({ error: 'Invalid user session' }, 401);
  }
  if (!geminiApiKey) {
    return json({ error: 'Server is not configured' }, 500);
  }
  if (await isBlockedSecret(geminiApiKey, blockedGeminiKeyDigests)) {
    return json({ error: 'Server is not configured' }, 500);
  }

  let payload: AssistantPayload;
  try {
    payload = await req.json();
  } catch {
    return json({ error: 'Invalid JSON payload' }, 400);
  }

  const question = normalizeText(payload.question, 500);
  const kind = normalizeText(payload.kind, 64);
  const locale = normalizeText(payload.locale, 16) || 'vi';
  const currencyCode = normalizeText(payload.currencyCode, 8) || 'VND';
  const profileName = normalizeNullableText(payload.profileName, 120);
  const snapshot = sanitizeSnapshot(payload.snapshot);
  const history = sanitizeHistory(payload.history);

  if (!question || !kind) {
    return json({ error: 'Missing question context' }, 400);
  }

  const adminClient = createClient(supabaseUrl, serviceRoleKey);
  const userId = userData.user.id;
  const { data: access, error: accessError } = await adminClient
    .from('assistant_preferences')
    .select('enabled, transactions, wallets, budgets')
    .eq('user_id', userId)
    .maybeSingle();

  if (accessError) {
    return json({ error: 'Unable to verify assistant access' }, 500);
  }
  if (!access?.enabled) {
    return json({ error: 'Assistant access is disabled' }, 403);
  }
  if (financialKinds.has(kind) && !access.transactions) {
    return json({ error: 'Transaction access is disabled' }, 403);
  }
  if (snapshot?.walletsIncluded === true && !access.wallets) {
    return json({ error: 'Wallet access is disabled' }, 403);
  }
  if (snapshot?.budgetsIncluded === true && !access.budgets) {
    return json({ error: 'Budget access is disabled' }, 403);
  }

  const bucketStart = new Date(Math.floor(Date.now() / 60000) * 60000)
    .toISOString();
  const { data: allowed, error: limitError } = await adminClient.rpc(
    'consume_assistant_rate_limit',
    {
      p_user_id: userId,
      p_bucket_start: bucketStart,
      p_limit: 20,
    },
  );
  if (limitError) {
    return json({ error: 'Unable to verify assistant quota' }, 500);
  }
  if (allowed !== true) {
    return json({ error: 'Assistant rate limit exceeded' }, 429);
  }

  const answer = await generateGeminiAnswer({
    apiKey: geminiApiKey,
    model: geminiModel,
    question,
    kind,
    locale,
    currencyCode,
    profileName,
    snapshot,
    history,
  });

  return json({ answer });
});

async function generateGeminiAnswer(args: {
  apiKey: string;
  model: string;
  question: string;
  kind: string;
  locale: string;
  currencyCode: string;
  profileName: string | null;
  snapshot: Record<string, unknown> | null;
  history: AssistantHistoryItem[];
}) {
  const uri = new URL(
    `https://generativelanguage.googleapis.com/v1beta/models/${args.model}:generateContent`,
  );
  uri.searchParams.set('key', args.apiKey);

  for (let attempt = 0; attempt < 2; attempt++) {
    const response = await fetch(uri, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(buildGeminiRequest(args)),
    });
    if (!response.ok) {
      return null;
    }

    const body = await response.json();
    const candidate = Array.isArray(body.candidates)
      ? body.candidates[0]
      : null;
    if (candidate?.finishReason !== 'STOP') {
      continue;
    }

    const parts = Array.isArray(candidate.content?.parts)
      ? candidate.content.parts
      : [];
    const text = parts
      .map((part: Record<string, unknown>) => part.text)
      .filter((part: unknown): part is string => typeof part === 'string')
      .join('\n')
      .trim();
    const answer = parseJsonAnswer(text);
    if (answer) return answer;
  }
  return null;
}

function buildGeminiRequest(args: {
  question: string;
  kind: string;
  locale: string;
  currencyCode: string;
  profileName: string | null;
  snapshot: Record<string, unknown> | null;
  history: AssistantHistoryItem[];
}) {
  const isVietnamese = args.locale.toLowerCase().startsWith('vi');
  const language = isVietnamese ? 'Vietnamese' : 'English';
  const isFinancial = financialKinds.has(args.kind);
  const compactFacts = JSON.stringify({
    kind: args.kind,
    currencyCode: args.currencyCode,
    profileName: args.profileName,
    snapshot: args.snapshot,
  });

  const systemInstruction = [
    'You are the financial assistant inside Moniary.',
    `Reply in ${language}.`,
    'Return only valid JSON with one string field named "answer".',
    'Keep the answer natural, concise, and at most 4 sentences.',
    'Only answer questions about Moniary, personal finance, or the provided profile context.',
    'Do not invent wallets, budgets, transactions, names, or financial facts.',
    isFinancial
      ? 'For financial questions, do not include exact amounts, percentages, counts, or dates; the app renders verified facts separately. Provide interpretation or next-step wording only.'
      : 'For non-financial assistant questions, use only the profile context provided.',
  ].join('\n');

  const contents = [
    ...args.history.map((item) => ({
      role: item.role === 'assistant' ? 'model' : 'user',
      parts: [{ text: item.text }],
    })),
    {
      role: 'user',
      parts: [
        {
          text: [
            `Current question: ${args.question}`,
            `Internal kind: ${args.kind}`,
            `Verified context JSON: ${compactFacts}`,
          ].join('\n'),
        },
      ],
    },
  ];

  return {
    systemInstruction: { parts: [{ text: systemInstruction }] },
    contents,
    generationConfig: {
      temperature: 0.25,
      topP: 0.9,
      maxOutputTokens: 512,
      responseMimeType: 'application/json',
      thinkingConfig: { thinkingBudget: 0 },
    },
  };
}

function normalizeText(value: unknown, maxLength: number) {
  if (typeof value !== 'string') return '';
  return value.replace(/\s+/g, ' ').trim().slice(0, maxLength);
}

function normalizeNullableText(value: unknown, maxLength: number) {
  const text = normalizeText(value, maxLength);
  return text ? text : null;
}

function parseSha256DigestList(value: string | undefined): string[] {
  if (!value) return [];
  return value
    .split(',')
    .map((item) => item.trim().toLowerCase())
    .filter((item) => /^[a-f0-9]{64}$/.test(item));
}

async function isBlockedSecret(value: string, blockedDigests: string[]) {
  if (blockedDigests.length === 0) return false;
  const digest = await sha256Hex(value);
  return blockedDigests.includes(digest);
}

async function sha256Hex(value: string) {
  const buffer = await crypto.subtle.digest(
    'SHA-256',
    new TextEncoder().encode(value),
  );
  return [...new Uint8Array(buffer)]
    .map((byte) => byte.toString(16).padStart(2, '0'))
    .join('');
}

function sanitizeHistory(value: unknown): AssistantHistoryItem[] {
  if (!Array.isArray(value)) return [];
  return value
    .slice(-8)
    .map((item) => {
      if (!item || typeof item !== 'object') return null;
      const row = item as Record<string, unknown>;
      const role = row.role === 'assistant' ? 'assistant' : 'user';
      const text = normalizeText(row.text, 500);
      return text ? { role, text } : null;
    })
    .filter((item): item is AssistantHistoryItem => item !== null);
}

function sanitizeSnapshot(value: unknown) {
  if (!value || typeof value !== 'object' || Array.isArray(value)) {
    return null;
  }
  const input = value as Record<string, unknown>;
  const output: Record<string, unknown> = {};
  for (const [key, raw] of Object.entries(input)) {
    if (typeof raw === 'number' && Number.isFinite(raw)) {
      output[key] = raw;
    } else if (typeof raw === 'boolean') {
      output[key] = raw;
    } else if (typeof raw === 'string') {
      output[key] = raw.replace(/\s+/g, ' ').trim().slice(0, 120);
    } else if (raw === null) {
      output[key] = null;
    }
  }
  return output;
}

function parseJsonAnswer(text: string) {
  if (!text) return null;
  try {
    const parsed = JSON.parse(text) as Record<string, unknown>;
    if (typeof parsed.answer !== 'string') return null;
    const answer = parsed.answer.replace(/\s+/g, ' ').trim();
    return answer ? answer.slice(0, 900) : null;
  } catch {
    return null;
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
