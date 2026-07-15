-- Admin-created notification campaigns for custom push/inbox sends.
-- This table is written only from the admin Edge Function through the
-- service-role client. Mobile clients must not read or mutate it.

create table if not exists public.admin_notification_campaigns (
    id uuid primary key default gen_random_uuid(),
    title text not null,
    body text not null,
    category text not null default 'system',
    type text not null default 'admin_broadcast',
    audience text not null,
    target_count integer not null default 0,
    queued_count integer not null default 0,
    failed_count integer not null default 0,
    dispatched_at timestamptz,
    dispatch_result jsonb,
    metadata jsonb not null default '{}'::jsonb,
    created_by text,
    created_at timestamptz not null default timezone('utc', now()),
    constraint admin_notification_campaigns_category_check
        check (category in ('personal', 'group', 'community', 'system')),
    constraint admin_notification_campaigns_counts_check
        check (target_count >= 0 and queued_count >= 0 and failed_count >= 0),
    constraint admin_notification_campaigns_title_not_blank
        check (btrim(title) <> ''),
    constraint admin_notification_campaigns_body_not_blank
        check (btrim(body) <> ''),
    constraint admin_notification_campaigns_audience_not_blank
        check (btrim(audience) <> '')
);

create index if not exists admin_notification_campaigns_created_idx
    on public.admin_notification_campaigns (created_at desc);

alter table public.admin_notification_campaigns enable row level security;

revoke all on table public.admin_notification_campaigns from public;
revoke all on table public.admin_notification_campaigns from anon;
revoke all on table public.admin_notification_campaigns from authenticated;
