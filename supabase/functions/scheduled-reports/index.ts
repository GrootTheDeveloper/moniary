import {
  createClient,
  type SupabaseClient,
} from "https://esm.sh/@supabase/supabase-js@2";

import {
  classifyResendFailure,
  constantTimeEqual,
  escapeHtml,
  isValidSender,
  runWithConcurrency,
} from "./logic.ts";

type EdgeSupabaseClient = SupabaseClient<any, "public", "public", any, any>;

type ReportTask = {
  id: string;
  user_id: string;
  email: string;
  full_name: string | null;
  preferred_currency: string;
  report_type: "daily" | "weekly" | "monthly" | "yearly";
  period_start: string;
  period_end: string;
};

type CategorySummary = {
  name: string;
  amount: number;
};

type ReportSummary = {
  eligible: boolean;
  has_transactions: boolean;
  total_income: number;
  total_expense: number;
  top_categories: CategorySummary[];
};

type DeliveryOutcome = "sent" | "skipped" | "retry" | "failed";

const schedulerHeader = "x-scheduled-reports-secret";

Deno.serve(async (request) => {
  try {
    return await handleRequest(request);
  } catch (error) {
    console.error("Scheduled reports failed", safeErrorCode(error));
    return json({ error: "Scheduled reports failed" }, 500);
  }
});

async function handleRequest(request: Request) {
  if (request.method !== "POST") {
    return json({ error: "Method not allowed" }, 405);
  }

  const supabaseUrl = Deno.env.get("SUPABASE_URL")?.trim();
  const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")?.trim();
  const resendApiKey = Deno.env.get("RESEND_API_KEY")?.trim();
  const fromEmail = Deno.env.get("REPORT_EMAIL_FROM")?.trim();
  const schedulerSecret = Deno.env.get("SCHEDULED_REPORTS_SECRET")?.trim();
  if (
    !supabaseUrl ||
    !serviceRoleKey ||
    !resendApiKey?.startsWith("re_") ||
    !fromEmail ||
    !isValidSender(fromEmail) ||
    !schedulerSecret ||
    schedulerSecret.length < 32
  ) {
    return json({ error: "Server is not configured" }, 500);
  }
  if (
    !constantTimeEqual(request.headers.get(schedulerHeader), schedulerSecret)
  ) {
    return json({ error: "Unauthorized" }, 401);
  }

  const client = createClient(supabaseUrl, serviceRoleKey, {
    auth: { autoRefreshToken: false, persistSession: false },
  });
  const lockToken = crypto.randomUUID();
  const { data, error } = await client.rpc("claim_due_scheduled_reports", {
    // Five workers and a 20-second provider timeout keep the external-I/O
    // portion of a tick bounded to roughly 80 seconds.
    p_limit: 20,
    p_lock_token: lockToken,
  });
  if (error) {
    console.error("Failed to claim scheduled reports", error.code);
    return json({ error: "Report queue is unavailable" }, 500);
  }

  const tasks = (data ?? []) as ReportTask[];
  const counts = { sent: 0, skipped: 0, retried: 0, failed: 0 };
  await runWithConcurrency(tasks, 5, async (task) => {
    let outcome: DeliveryOutcome = "retry";
    let reason: string | null = null;
    let providerMessageId: string | null = null;
    try {
      const summary = await loadSummary(client, task);
      if (!summary.eligible) {
        outcome = "skipped";
        reason = "ACCOUNT_OR_REPORT_INELIGIBLE";
      } else if (!summary.has_transactions) {
        outcome = "skipped";
        reason = "NO_TRANSACTIONS";
      } else {
        const email = renderEmail(task, summary);
        const response = await sendEmail(
          resendApiKey,
          fromEmail,
          task,
          email,
        );
        outcome = response.outcome;
        reason = response.reason;
        providerMessageId = response.providerMessageId;
      }
    } catch (error) {
      reason = safeErrorCode(error);
      console.error("Scheduled report row failed", task.id, reason);
    }

    try {
      await finishDelivery(
        client,
        task.id,
        lockToken,
        outcome,
        reason,
        providerMessageId,
      );
      if (outcome === "retry") counts.retried++;
      else counts[outcome]++;
    } catch (error) {
      console.error(
        "Failed to finish report delivery",
        task.id,
        safeErrorCode(error),
      );
      counts.failed++;
    }
  });

  return json({ processed: tasks.length, ...counts });
}

async function loadSummary(
  client: EdgeSupabaseClient,
  task: ReportTask,
): Promise<ReportSummary> {
  const { data, error } = await client.rpc("scheduled_report_summary", {
    p_user_id: task.user_id,
    p_report_type: task.report_type,
    p_period_start: task.period_start,
    p_period_end: task.period_end,
  });
  if (error || data == null || typeof data !== "object") {
    throw new Error("REPORT_SUMMARY_FAILED");
  }
  const value = data as Record<string, unknown>;
  const categories = Array.isArray(value.top_categories)
    ? value.top_categories
      .filter((item): item is Record<string, unknown> =>
        item != null && typeof item === "object"
      )
      .map((item) => ({
        name: typeof item.name === "string" ? item.name : "Khác",
        amount: numeric(item.amount),
      }))
    : [];
  return {
    eligible: value.eligible === true,
    has_transactions: value.has_transactions === true,
    total_income: numeric(value.total_income),
    total_expense: numeric(value.total_expense),
    top_categories: categories,
  };
}

function renderEmail(task: ReportTask, summary: ReportSummary) {
  const periodLabel = {
    daily: "Hôm qua",
    weekly: "Tuần trước",
    monthly: "Tháng trước",
    yearly: "Năm trước",
  }[task.report_type];
  const currency = /^[A-Z]{3}$/.test(task.preferred_currency)
    ? task.preferred_currency
    : "VND";
  const money = (value: number) => {
    try {
      return new Intl.NumberFormat("vi-VN", {
        style: "currency",
        currency,
      }).format(value);
    } catch {
      return `${value.toLocaleString("vi-VN")} ${currency}`;
    }
  };
  const topCategories = summary.top_categories
    .map((category) => {
      const percentage = summary.total_expense > 0
        ? (category.amount / summary.total_expense) * 100
        : 0;
      return `<li><b>${escapeHtml(category.name)}:</b> ${
        money(category.amount)
      } (${percentage.toFixed(1)}%)</li>`;
    })
    .join("");
  const displayName = escapeHtml(task.full_name?.trim() || "bạn");
  const netBalance = summary.total_income - summary.total_expense;

  return {
    subject: `Báo cáo tài chính Moniary - ${periodLabel}`,
    html: `
      <div style="font-family:sans-serif;max-width:600px;margin:0 auto;color:#333">
        <h2 style="color:#4CAF50">Báo cáo tài chính Moniary - ${periodLabel}</h2>
        <p>Chào <b>${displayName}</b>,</p>
        <p>Đây là tóm tắt tài chính của bạn trong ${periodLabel.toLowerCase()}.</p>
        <div style="background:#f9f9f9;padding:15px;border-radius:8px;margin:20px 0">
          <h3 style="margin-top:0">Tổng quan</h3>
          <p><b>Tổng thu:</b> ${money(summary.total_income)}</p>
          <p><b>Tổng chi:</b> ${money(summary.total_expense)}</p>
          <p><b>Số dư:</b> ${money(netBalance)}</p>
        </div>
        ${
      topCategories
        ? `<h3>Top danh mục chi tiêu</h3><ul>${topCategories}</ul>`
        : ""
    }
        <p style="color:#777;font-size:12px;margin-top:30px">
          Đây là email tự động từ Moniary. Bạn có thể tắt báo cáo trong phần Cài đặt thông báo.
        </p>
      </div>
    `,
  };
}

async function sendEmail(
  apiKey: string,
  fromEmail: string,
  task: ReportTask,
  email: { subject: string; html: string },
) {
  const response = await fetch("https://api.resend.com/emails", {
    method: "POST",
    headers: {
      Authorization: `Bearer ${apiKey}`,
      "Content-Type": "application/json",
      "Idempotency-Key": `moniary-report/${task.id}`,
    },
    body: JSON.stringify({
      from: fromEmail,
      to: [task.email],
      subject: email.subject,
      html: email.html,
    }),
    signal: AbortSignal.timeout(20_000),
  });
  const payload = await response.json().catch(() => null) as
    | { id?: unknown; name?: unknown }
    | null;
  if (response.ok && typeof payload?.id === "string") {
    return {
      outcome: "sent" as const,
      reason: null,
      providerMessageId: payload.id,
    };
  }

  const outcome = classifyResendFailure(response.status, payload?.name);
  const reasonName = typeof payload?.name === "string"
    ? payload.name.toUpperCase().replace(/[^A-Z0-9_]/g, "_")
    : `HTTP_${response.status}`;
  return {
    outcome,
    reason: `RESEND_${reasonName}`,
    providerMessageId: null,
  };
}

async function finishDelivery(
  client: EdgeSupabaseClient,
  deliveryId: string,
  lockToken: string,
  outcome: DeliveryOutcome,
  reason: string | null,
  providerMessageId: string | null,
) {
  const { data, error } = await client.rpc("finish_scheduled_report_delivery", {
    p_delivery_id: deliveryId,
    p_lock_token: lockToken,
    p_outcome: outcome,
    p_error: reason,
    p_provider_message_id: providerMessageId,
  });
  if (error || data !== true) throw new Error("REPORT_FINISH_FAILED");
}

function numeric(value: unknown) {
  const parsed = typeof value === "number" ? value : Number(value);
  return Number.isFinite(parsed) ? parsed : 0;
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
