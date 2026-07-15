-- Deliver scheduled reports once per user/period, in the user's timezone, via
-- a private scheduler endpoint. Aggregation happens in Postgres so API row
-- limits cannot silently truncate financial totals.

create extension if not exists pg_cron;
create extension if not exists pg_net;

create table if not exists public.scheduled_report_deliveries (
    id uuid primary key default gen_random_uuid(),
    user_id uuid not null references public.profiles(id) on delete cascade,
    report_type text not null,
    period_start timestamptz not null,
    period_end timestamptz not null,
    attempt_count integer not null default 0,
    next_attempt_at timestamptz not null default timezone('utc', now()),
    locked_at timestamptz,
    lock_token uuid,
    sent_at timestamptz,
    failed_at timestamptz,
    provider_message_id text,
    last_error text,
    created_at timestamptz not null default timezone('utc', now()),
    constraint scheduled_report_type_check
        check (report_type in ('daily', 'weekly', 'monthly', 'yearly')),
    constraint scheduled_report_period_check check (period_start < period_end),
    constraint scheduled_report_attempt_check check (attempt_count >= 0),
    constraint scheduled_report_terminal_check check (
        not (sent_at is not null and failed_at is not null)
    ),
    unique (user_id, report_type, period_start, period_end)
);

create index if not exists scheduled_report_delivery_queue_idx
on public.scheduled_report_deliveries (next_attempt_at, created_at)
where sent_at is null and failed_at is null;

alter table public.scheduled_report_deliveries enable row level security;
revoke all on table public.scheduled_report_deliveries
from public, anon, authenticated;
grant select, insert, update, delete
on table public.scheduled_report_deliveries to service_role;

create or replace function public.claim_due_scheduled_reports(
    p_limit integer,
    p_lock_token uuid
)
returns table (
    id uuid,
    user_id uuid,
    email text,
    full_name text,
    preferred_currency text,
    report_type text,
    period_start timestamptz,
    period_end timestamptz
)
language plpgsql
security definer
set search_path = ''
as $$
begin
    if auth.role() <> 'service_role' then
        raise exception 'SERVICE_ROLE_REQUIRED';
    end if;
    if p_lock_token is null then
        raise exception 'LOCK_TOKEN_REQUIRED';
    end if;

    -- Resolve the most recent scheduled occurrence in the user's timezone.
    -- This also covers reminder times near midnight and short scheduler
    -- outages; the unique period key makes later ticks harmless.
    with base as (
        select
            settings.user_id,
            profile.timezone,
            timezone(profile.timezone, now()) as local_now,
            settings.daily_reminder_enabled,
            settings.daily_reminder_time,
            settings.weekly_summary_enabled,
            settings.monthly_summary_enabled,
            settings.yearly_summary_enabled
        from public.notification_settings settings
        join public.profiles profile on profile.id = settings.user_id
        join auth.users account on account.id = settings.user_id
        join pg_catalog.pg_timezone_names zone on zone.name = profile.timezone
        where profile.deleted_at is null
          and nullif(btrim(account.email), '') is not null
          and account.email_confirmed_at is not null
          and account.is_anonymous is false
          and (account.banned_until is null or account.banned_until <= now())
    ), schedules as (
        select
            base.user_id,
            base.timezone,
            report.report_type,
            case
                when base.local_now >= report.nominal_scheduled_local
                    then report.nominal_scheduled_local
                else report.nominal_scheduled_local - report.rewind_interval
            end as scheduled_local
        from base
        cross join lateral (
            values
                (
                    'daily'::text,
                    base.daily_reminder_enabled,
                    base.local_now::date
                        + coalesce(base.daily_reminder_time, time '07:00'),
                    interval '1 day'
                ),
                (
                    'weekly'::text,
                    base.weekly_summary_enabled,
                    (
                        base.local_now::date
                        - (extract(isodow from base.local_now)::integer - 1)
                    ) + coalesce(base.daily_reminder_time, time '07:00'),
                    interval '7 days'
                ),
                (
                    'monthly'::text,
                    base.monthly_summary_enabled,
                    date_trunc('month', base.local_now)::date
                        + coalesce(base.daily_reminder_time, time '07:00'),
                    interval '1 month'
                ),
                (
                    'yearly'::text,
                    base.yearly_summary_enabled,
                    date_trunc('year', base.local_now)::date
                        + coalesce(base.daily_reminder_time, time '07:00'),
                    interval '1 year'
                )
        ) as report(
            report_type,
            enabled,
            nominal_scheduled_local,
            rewind_interval
        )
        where report.enabled
    ), due as (
        select
            schedules.user_id,
            schedules.report_type,
            (
                case schedules.report_type
                    when 'daily' then schedules.scheduled_local::date - interval '1 day'
                    when 'weekly' then schedules.scheduled_local::date - interval '7 days'
                    when 'monthly' then schedules.scheduled_local::date - interval '1 month'
                    else schedules.scheduled_local::date - interval '1 year'
                end
            ) at time zone schedules.timezone as period_start,
            schedules.scheduled_local::date::timestamp
                at time zone schedules.timezone as period_end
        from schedules
    )
    insert into public.scheduled_report_deliveries (
        user_id, report_type, period_start, period_end
    )
    select due.user_id, due.report_type, due.period_start, due.period_end
    from due
    on conflict (user_id, report_type, period_start, period_end) do nothing;

    update public.scheduled_report_deliveries abandoned
    set failed_at = timezone('utc', now()),
        last_error = 'MAX_ATTEMPTS:WORKER_LEASE_EXPIRED',
        locked_at = null,
        lock_token = null
    where abandoned.sent_at is null
      and abandoned.failed_at is null
      and abandoned.attempt_count >= 5
      and (
          abandoned.locked_at is null
          or abandoned.locked_at < timezone('utc', now()) - interval '10 minutes'
      );

    return query
    with candidates as materialized (
        select delivery.id
        from public.scheduled_report_deliveries delivery
        join public.profiles profile on profile.id = delivery.user_id
        join auth.users account on account.id = delivery.user_id
        join public.notification_settings settings
          on settings.user_id = delivery.user_id
        where delivery.sent_at is null
          and delivery.failed_at is null
          and delivery.next_attempt_at <= timezone('utc', now())
          and delivery.attempt_count < 5
          and profile.deleted_at is null
          and nullif(btrim(account.email), '') is not null
          and account.email_confirmed_at is not null
          and account.is_anonymous is false
          and (account.banned_until is null or account.banned_until <= now())
          and case delivery.report_type
              when 'daily' then settings.daily_reminder_enabled
              when 'weekly' then settings.weekly_summary_enabled
              when 'monthly' then settings.monthly_summary_enabled
              when 'yearly' then settings.yearly_summary_enabled
              else false
          end
          and (
              delivery.locked_at is null
              or delivery.locked_at
                  < timezone('utc', now()) - interval '10 minutes'
          )
        order by delivery.created_at
        for update of delivery skip locked
        limit greatest(1, least(coalesce(p_limit, 100), 200))
    ), claimed as (
        update public.scheduled_report_deliveries delivery
        set locked_at = timezone('utc', now()),
            lock_token = p_lock_token,
            attempt_count = delivery.attempt_count + 1
        from candidates
        where delivery.id = candidates.id
        returning delivery.*
    )
    select
        claimed.id,
        claimed.user_id,
        account.email,
        profile.full_name,
        coalesce(profile.preferred_currency, 'VND'),
        claimed.report_type,
        claimed.period_start,
        claimed.period_end
    from claimed
    join public.profiles profile on profile.id = claimed.user_id
    join auth.users account on account.id = claimed.user_id;
end;
$$;

revoke all on function public.claim_due_scheduled_reports(integer, uuid)
from public, anon, authenticated;
grant execute on function public.claim_due_scheduled_reports(integer, uuid)
to service_role;

create or replace function public.scheduled_report_summary(
    p_user_id uuid,
    p_report_type text,
    p_period_start timestamptz,
    p_period_end timestamptz
)
returns jsonb
language sql
stable
security definer
set search_path = ''
as $$
    with eligibility as (
        select true as eligible
        from public.profiles profile
        join auth.users account on account.id = profile.id
        join public.notification_settings settings on settings.user_id = profile.id
        where profile.id = p_user_id
          and p_report_type in ('daily', 'weekly', 'monthly', 'yearly')
          and profile.deleted_at is null
          and nullif(btrim(account.email), '') is not null
          and account.email_confirmed_at is not null
          and account.is_anonymous is false
          and (account.banned_until is null or account.banned_until <= now())
          and case p_report_type
              when 'daily' then settings.daily_reminder_enabled
              when 'weekly' then settings.weekly_summary_enabled
              when 'monthly' then settings.monthly_summary_enabled
              when 'yearly' then settings.yearly_summary_enabled
              else false
          end
    ), period_transactions as (
        select transaction.amount, transaction.type, category.name
        from public.transactions transaction
        left join public.categories category on category.id = transaction.category_id
        cross join eligibility
        where transaction.user_id = p_user_id
          and transaction.transaction_date >= p_period_start
          and transaction.transaction_date < p_period_end
    ), totals as (
        select
            count(*) as transaction_count,
            coalesce(sum(amount) filter (where type = 'income'), 0) as total_income,
            coalesce(sum(amount) filter (where type = 'expense'), 0) as total_expense
        from period_transactions
    ), top_categories as (
        select coalesce(name, 'Khác') as name, sum(amount) as amount
        from period_transactions
        where type = 'expense'
        group by coalesce(name, 'Khác')
        order by amount desc, name
        limit 3
    )
    select jsonb_build_object(
        'eligible', exists (select 1 from eligibility),
        'has_transactions', totals.transaction_count > 0,
        'total_income', totals.total_income,
        'total_expense', totals.total_expense,
        'top_categories', coalesce(
            (
                select jsonb_agg(
                    jsonb_build_object('name', name, 'amount', amount)
                    order by amount desc, name
                )
                from top_categories
            ),
            '[]'::jsonb
        )
    )
    from totals;
$$;

revoke all on function public.scheduled_report_summary(
    uuid, text, timestamptz, timestamptz
)
from public, anon, authenticated;
grant execute on function public.scheduled_report_summary(
    uuid, text, timestamptz, timestamptz
)
to service_role;

create or replace function public.finish_scheduled_report_delivery(
    p_delivery_id uuid,
    p_lock_token uuid,
    p_outcome text,
    p_error text default null,
    p_provider_message_id text default null
)
returns boolean
language plpgsql
security definer
set search_path = ''
as $$
declare
    v_attempt_count integer;
    v_error text := nullif(left(btrim(coalesce(p_error, '')), 256), '');
    v_retry_seconds integer;
begin
    if auth.role() <> 'service_role' then
        raise exception 'SERVICE_ROLE_REQUIRED';
    end if;
    if p_outcome is null
       or p_outcome not in ('sent', 'skipped', 'retry', 'failed') then
        raise exception 'INVALID_REPORT_OUTCOME';
    end if;

    select attempt_count into v_attempt_count
    from public.scheduled_report_deliveries
    where id = p_delivery_id
      and lock_token = p_lock_token
      and sent_at is null
      and failed_at is null
    for update;

    if not found then
        return false;
    end if;

    if p_outcome in ('sent', 'skipped') then
        update public.scheduled_report_deliveries
        set sent_at = timezone('utc', now()),
            provider_message_id = nullif(
                left(btrim(coalesce(p_provider_message_id, '')), 128),
                ''
            ),
            last_error = v_error,
            locked_at = null,
            lock_token = null
        where id = p_delivery_id;
    elsif p_outcome = 'failed' or v_attempt_count >= 5 then
        update public.scheduled_report_deliveries
        set failed_at = timezone('utc', now()),
            last_error = case
                when p_outcome = 'failed' then v_error
                else concat('MAX_ATTEMPTS:', coalesce(v_error, 'UNKNOWN'))
            end,
            locked_at = null,
            lock_token = null
        where id = p_delivery_id;
    else
        v_retry_seconds := least(
            3600,
            (60 * power(2, greatest(v_attempt_count - 1, 0)))::integer
        );
        update public.scheduled_report_deliveries
        set next_attempt_at = timezone('utc', now())
                + make_interval(secs => v_retry_seconds),
            last_error = v_error,
            locked_at = null,
            lock_token = null
        where id = p_delivery_id;
    end if;

    return true;
end;
$$;

revoke all on function public.finish_scheduled_report_delivery(
    uuid, uuid, text, text, text
) from public, anon, authenticated;
grant execute on function public.finish_scheduled_report_delivery(
    uuid, uuid, text, text, text
) to service_role;

create or replace function public.cancel_reports_on_notification_opt_out()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
    update public.scheduled_report_deliveries delivery
    set failed_at = timezone('utc', now()),
        last_error = 'REPORT_DISABLED',
        locked_at = null,
        lock_token = null
    where delivery.user_id = new.user_id
      and delivery.sent_at is null
      and delivery.failed_at is null
      and not case delivery.report_type
          when 'daily' then new.daily_reminder_enabled
          when 'weekly' then new.weekly_summary_enabled
          when 'monthly' then new.monthly_summary_enabled
          when 'yearly' then new.yearly_summary_enabled
          else false
      end;
    return new;
end;
$$;

revoke all on function public.cancel_reports_on_notification_opt_out()
from public, anon, authenticated;
drop trigger if exists cancel_reports_on_notification_opt_out
on public.notification_settings;
create trigger cancel_reports_on_notification_opt_out
after insert or update of
    daily_reminder_enabled,
    weekly_summary_enabled,
    monthly_summary_enabled,
    yearly_summary_enabled
on public.notification_settings
for each row execute function public.cancel_reports_on_notification_opt_out();

create or replace function public.cancel_reports_on_account_deletion()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
    if old.deleted_at is null and new.deleted_at is not null then
        update public.scheduled_report_deliveries
        set failed_at = timezone('utc', now()),
            last_error = 'ACCOUNT_DELETION_PENDING',
            locked_at = null,
            lock_token = null
        where user_id = new.id
          and sent_at is null
          and failed_at is null;
    end if;
    return new;
end;
$$;

revoke all on function public.cancel_reports_on_account_deletion()
from public, anon, authenticated;
drop trigger if exists cancel_reports_on_account_deletion on public.profiles;
create trigger cancel_reports_on_account_deletion
after update of deleted_at on public.profiles
for each row execute function public.cancel_reports_on_account_deletion();

create or replace function public.cleanup_scheduled_report_deliveries()
returns integer
language plpgsql
security definer
set search_path = ''
as $$
declare
    v_deleted integer;
begin
    delete from public.scheduled_report_deliveries
    where (sent_at is not null or failed_at is not null)
      and created_at < timezone('utc', now()) - interval '90 days';
    get diagnostics v_deleted = row_count;
    return v_deleted;
end;
$$;

revoke all on function public.cleanup_scheduled_report_deliveries()
from public, anon, authenticated;

create or replace function public.invoke_scheduled_reports()
returns bigint
language plpgsql
security definer
set search_path = ''
as $$
declare
    v_project_url text;
    v_scheduler_secret text;
    v_request_id bigint;
begin
    select decrypted_secret into v_project_url
    from vault.decrypted_secrets
    where name = 'project_url'
    order by created_at desc
    limit 1;

    select decrypted_secret into v_scheduler_secret
    from vault.decrypted_secrets
    where name = 'scheduled_reports_secret'
    order by created_at desc
    limit 1;

    if nullif(btrim(v_project_url), '') is null
       or char_length(coalesce(v_scheduler_secret, '')) < 32 then
        raise exception 'SCHEDULED_REPORTS_VAULT_NOT_CONFIGURED';
    end if;

    select net.http_post(
        url := rtrim(v_project_url, '/') || '/functions/v1/scheduled-reports',
        headers := jsonb_build_object(
            'Content-Type', 'application/json',
            'x-scheduled-reports-secret', v_scheduler_secret
        ),
        body := '{}'::jsonb,
        timeout_milliseconds := 30000
    ) into v_request_id;

    return v_request_id;
end;
$$;

revoke all on function public.invoke_scheduled_reports()
from public, anon, authenticated;
grant execute on function public.invoke_scheduled_reports()
to service_role;

create or replace function public.schedule_report_jobs()
returns table (report_job_id bigint, cleanup_job_id bigint)
language plpgsql
security definer
set search_path = ''
as $$
declare
    v_job_id bigint;
begin
    perform public.invoke_scheduled_reports();

    for v_job_id in
        select jobid from cron.job
        where jobname in (
            'invoke-scheduled-reports',
            'invoke_scheduled_reports',
            'cleanup_scheduled_report_deliveries'
        )
    loop
        perform cron.unschedule(v_job_id);
    end loop;

    select cron.schedule(
        'invoke_scheduled_reports',
        '*/15 * * * *',
        'select public.invoke_scheduled_reports();'
    ) into report_job_id;

    select cron.schedule(
        'cleanup_scheduled_report_deliveries',
        '30 3 * * *',
        'select public.cleanup_scheduled_report_deliveries();'
    ) into cleanup_job_id;

    return next;
end;
$$;

revoke all on function public.schedule_report_jobs()
from public, anon, authenticated;
grant execute on function public.schedule_report_jobs()
to service_role;
