import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

// Constants
const RESEND_API_KEY = Deno.env.get("RESEND_API_KEY");
const SUPABASE_URL = Deno.env.get("SUPABASE_URL");
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

serve(async (req) => {
  // Handle CORS
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    // 1. Initialize Supabase Client
    if (!SUPABASE_URL || !SUPABASE_SERVICE_ROLE_KEY) {
      throw new Error("Missing Supabase environment variables");
    }
    const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY);

    // 2. Determine which reports to send based on the current date
    const today = new Date();
    // In JS, getDay() returns 0 for Sunday, 1 for Monday. Let's assume Monday is start of week.
    const isFirstDayOfMonth = today.getDate() === 1;
    const isFirstDayOfYear = today.getMonth() === 0 && today.getDate() === 1;
    // You could also check for weekly (e.g. today.getDay() === 1 for Monday)
    // For simplicity, we assume this cron runs daily at 00:00 UTC.

    // 3. Fetch notification settings
    const { data: settings, error: settingsError } = await supabase
      .from("notification_settings")
      .select("user_id, daily_reminder_enabled, weekly_summary_enabled, monthly_summary_enabled, yearly_summary_enabled");

    if (settingsError) throw settingsError;

    if (!settings || settings.length === 0) {
      return new Response(JSON.stringify({ message: "No settings found" }), {
        headers: { ...corsHeaders, "Content-Type": "application/json" },
        status: 200,
      });
    }

    // 4. Group users by report type
    // In a real production app, you might query each group separately and process in batches.
    const usersToProcess = [];

    for (const s of settings) {
      // Logic: if daily_reminder is enabled, we send daily report.
      // If weekly and today is Monday, send weekly.
      // If monthly and today is 1st, send monthly.
      // If yearly and today is Jan 1st, send yearly.
      
      let reportType = null;
      if (s.yearly_summary_enabled && isFirstDayOfYear) reportType = "yearly";
      else if (s.monthly_summary_enabled && isFirstDayOfMonth) reportType = "monthly";
      else if (s.weekly_summary_enabled && today.getDay() === 1) reportType = "weekly"; // Monday
      else if (s.daily_reminder_enabled) reportType = "daily";

      if (reportType) {
        usersToProcess.push({ userId: s.user_id, reportType });
      }
    }

    if (usersToProcess.length === 0) {
      return new Response(JSON.stringify({ message: "No reports to send today" }), {
        headers: { ...corsHeaders, "Content-Type": "application/json" },
        status: 200,
      });
    }

    // 5. Fetch profiles and process reports
    const emailsSent = [];

    for (const { userId, reportType } of usersToProcess) {
      // Get profile
      const { data: profile } = await supabase
        .from("profiles")
        .select("email, full_name, login_provider")
        .eq("id", userId)
        .single();

      if (!profile || !profile.email || profile.login_provider === 'anonymous') {
        continue; // Skip anonymous users or users without email
      }

      // Calculate date range based on reportType
      const startDate = new Date(today);
      if (reportType === "daily") startDate.setDate(startDate.getDate() - 1);
      else if (reportType === "weekly") startDate.setDate(startDate.getDate() - 7);
      else if (reportType === "monthly") startDate.setMonth(startDate.getMonth() - 1);
      else if (reportType === "yearly") startDate.setFullYear(startDate.getFullYear() - 1);

      // Fetch transactions for the user within the date range
      const { data: transactions } = await supabase
        .from("transactions")
        .select("amount, type, category_id, categories(name)")
        .eq("user_id", userId)
        .gte("transaction_date", startDate.toISOString())
        .lt("transaction_date", today.toISOString());

      if (!transactions || transactions.length === 0) {
        continue; // Skip if no transactions
      }

      // Calculate summaries
      let totalIncome = 0;
      let totalExpense = 0;
      const categoryTotals: Record<string, number> = {};

      for (const t of transactions) {
        const amount = Number(t.amount);
        if (t.type === "income") {
          totalIncome += amount;
        } else if (t.type === "expense") {
          totalExpense += amount;
          const catName = t.categories?.name || "Khác";
          categoryTotals[catName] = (categoryTotals[catName] || 0) + amount;
        }
      }

      const netBalance = totalIncome - totalExpense;

      // Top categories
      const topCategories = Object.entries(categoryTotals)
        .sort((a, b) => b[1] - a[1])
        .slice(0, 3);

      let topCategoriesHtml = "";
      for (const [name, amount] of topCategories) {
        const percentage = totalExpense > 0 ? ((amount / totalExpense) * 100).toFixed(1) : 0;
        topCategoriesHtml += `<li><b>${name}:</b> ${amount.toLocaleString("vi-VN")} VNĐ (${percentage}%)</li>`;
      }

      // Render HTML
      const periodLabel = reportType === "daily" ? "Hôm qua" :
                          reportType === "weekly" ? "Tuần trước" :
                          reportType === "monthly" ? "Tháng trước" : "Năm trước";

      const htmlContent = `
        <div style="font-family: sans-serif; max-width: 600px; margin: 0 auto; color: #333;">
          <h2 style="color: #4CAF50;">📊 Báo cáo tài chính Moniary - ${periodLabel}</h2>
          <p>Chào <b>${profile.full_name || 'bạn'}</b>,</p>
          <p>Dưới đây là tóm tắt tình hình tài chính của bạn trong ${periodLabel.toLowerCase()}:</p>
          
          <div style="background-color: #f9f9f9; padding: 15px; border-radius: 8px; margin: 20px 0;">
            <h3 style="margin-top: 0;">Tổng quan</h3>
            <p>🟢 <b>Tổng Thu:</b> +${totalIncome.toLocaleString("vi-VN")} VNĐ</p>
            <p>🔴 <b>Tổng Chi:</b> -${totalExpense.toLocaleString("vi-VN")} VNĐ</p>
            <p>💰 <b>Số Dư (Tiết kiệm):</b> ${(netBalance > 0 ? "+" : "")}${netBalance.toLocaleString("vi-VN")} VNĐ</p>
          </div>

          ${topCategories.length > 0 ? `
          <div style="margin: 20px 0;">
            <h3>Top Danh Mục Chi Tiêu</h3>
            <ul>
              ${topCategoriesHtml}
            </ul>
          </div>
          ` : ""}

          <p style="color: #777; font-size: 12px; margin-top: 30px;">
            Đây là email tự động từ ứng dụng Moniary. Bạn có thể thay đổi cài đặt nhận email trong mục Cài đặt của ứng dụng.
          </p>
        </div>
      `;

      // 6. Send Email via Resend
      if (RESEND_API_KEY) {
        const resRequest = await fetch("https://api.resend.com/emails", {
          method: "POST",
          headers: {
            "Content-Type": "application/json",
            "Authorization": `Bearer ${RESEND_API_KEY}`,
          },
          body: JSON.stringify({
            from: "Moniary App <onboarding@resend.dev>", // Using Resend testing domain
            to: [profile.email],
            subject: `Báo cáo tài chính Moniary - ${periodLabel}`,
            html: htmlContent,
          }),
        });

        if (resRequest.ok) {
          emailsSent.push(profile.email);
        } else {
          const resError = await resRequest.text();
          console.error(`Failed to send email to ${profile.email}: ${resError}`);
        }
      } else {
        console.warn("RESEND_API_KEY is not set. Skipping actual email send.");
      }
    }

    return new Response(JSON.stringify({ 
      message: "Reports processed successfully",
      emailsSent: emailsSent.length 
    }), {
      headers: { ...corsHeaders, "Content-Type": "application/json" },
      status: 200,
    });

  } catch (error) {
    return new Response(JSON.stringify({ error: error.message }), {
      headers: { ...corsHeaders, "Content-Type": "application/json" },
      status: 500,
    });
  }
});
