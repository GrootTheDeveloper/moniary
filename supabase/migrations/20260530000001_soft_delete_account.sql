-- Migration for Soft Delete & Grace Period Deletion

-- 1. Thêm cột `deleted_at` vào bảng profiles
alter table public.profiles add column if not exists deleted_at timestamptz;

-- 2. Đảm bảo pg_cron được cài đặt (đã có ở file migration trước, nhưng thêm vào cho an toàn)
create extension if not exists pg_cron;

-- 3. Tạo một cron job để tự động xóa hoàn toàn các user đã hết hạn 30 ngày.
-- Chúng ta gọi edge function `garbage-collect` mỗi đêm vào lúc 02:00 AM.
select cron.schedule(
    'invoke_garbage_collect',
    '0 2 * * *',
    $$
    select net.http_post(
        url:='https://iegjdbcmngtpjoldbixs.supabase.co/functions/v1/garbage-collect',
        headers:=jsonb_build_object(
            'Content-Type', 'application/json',
            'Authorization', 'Bearer sb_publishable_92rDMp51wgUdNtyAH792QA_MR82rukr' -- Will be using anon key, but we should use service role or just let the function use service role internally via SUPABASE_SERVICE_ROLE_KEY
        )
    );
    $$
);
