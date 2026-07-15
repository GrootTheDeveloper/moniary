-- Make notification dispatch concurrency-safe and bounded. The Edge Function
-- claims rows with a lease, records successful delivery per device, and moves
-- permanently failed/max-retry rows out of the active queue.

create extension if not exists pg_cron;
create extension if not exists pg_net;

alter table public.notification_outbox
    add column if not exists locked_at timestamptz,
    add column if not exists lock_token uuid,
    add column if not exists failed_at timestamptz;

alter table public.notification_outbox
    drop constraint if exists notification_outbox_terminal_state_check;
alter table public.notification_outbox
    add constraint notification_outbox_terminal_state_check check (
        not (sent_at is not null and failed_at is not null)
    );

create index if not exists notification_outbox_dispatch_idx
on public.notification_outbox (next_attempt_at, created_at)
where sent_at is null and failed_at is null;

create table if not exists public.notification_delivery_receipts (
    outbox_id uuid not null
        references public.notification_outbox(id) on delete cascade,
    device_id uuid not null
        references public.notification_devices(id) on delete cascade,
    delivered_at timestamptz not null default timezone('utc', now()),
    primary key (outbox_id, device_id)
);

alter table public.notification_delivery_receipts enable row level security;
revoke all on table public.notification_delivery_receipts
from public, anon, authenticated;
grant select, insert, update, delete
on table public.notification_delivery_receipts to service_role;

create or replace function public.cleanup_expired_notifications()
returns integer
language plpgsql
security definer
set search_path = ''
as $$
declare
    v_deleted integer;
begin
    delete from public.app_notifications
    where expires_at <= timezone('utc', now())
       or created_at < timezone('utc', now()) - interval '30 days';
    get diagnostics v_deleted = row_count;

    delete from public.group_notifications
    where created_at < timezone('utc', now()) - interval '30 days';

    delete from public.notification_outbox
    where (sent_at is not null or failed_at is not null)
      and created_at < timezone('utc', now()) - interval '30 days';

    return v_deleted;
end;
$$;

revoke all on function public.cleanup_expired_notifications()
from public, anon, authenticated;

create or replace function public.claim_notification_outbox(
    p_limit integer,
    p_lock_token uuid
)
returns table (
    id uuid,
    user_id uuid,
    category text,
    type text,
    group_id uuid,
    metadata jsonb
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

    -- A worker can terminate after its fifth claim but before finishing the
    -- row. Once that lease expires, move it to dead-letter instead of leaving
    -- an unclaimable row in the active queue forever.
    update public.notification_outbox abandoned
    set failed_at = timezone('utc', now()),
        last_error = 'MAX_ATTEMPTS:WORKER_LEASE_EXPIRED',
        locked_at = null,
        lock_token = null
    where abandoned.sent_at is null
      and abandoned.failed_at is null
      and abandoned.attempt_count >= 5
      and (
          abandoned.locked_at is null
          or abandoned.locked_at < timezone('utc', now()) - interval '5 minutes'
      );

    return query
    with candidates as materialized (
        select candidate.id
        from public.notification_outbox candidate
        where candidate.sent_at is null
          and candidate.failed_at is null
          and candidate.next_attempt_at <= timezone('utc', now())
          and (
              candidate.locked_at is null
              or candidate.locked_at < timezone('utc', now()) - interval '5 minutes'
          )
          and candidate.attempt_count < 5
        order by candidate.created_at
        for update skip locked
        limit greatest(1, least(coalesce(p_limit, 50), 100))
    ), claimed as (
        update public.notification_outbox outbox
        set locked_at = timezone('utc', now()),
            lock_token = p_lock_token,
            attempt_count = outbox.attempt_count + 1
        from candidates
        where outbox.id = candidates.id
        returning
            outbox.id,
            outbox.user_id,
            outbox.category,
            outbox.type,
            outbox.group_id,
            outbox.metadata
    )
    select * from claimed;
end;
$$;

revoke all on function public.claim_notification_outbox(integer, uuid)
from public, anon, authenticated;
grant execute on function public.claim_notification_outbox(integer, uuid)
to service_role;

create or replace function public.finish_notification_outbox(
    p_outbox_id uuid,
    p_lock_token uuid,
    p_outcome text,
    p_error text default null
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
        raise exception 'INVALID_DISPATCH_OUTCOME';
    end if;

    select attempt_count
    into v_attempt_count
    from public.notification_outbox
    where id = p_outbox_id
      and lock_token = p_lock_token
      and sent_at is null
      and failed_at is null
    for update;

    if not found then
        return false;
    end if;

    if p_outcome in ('sent', 'skipped') then
        update public.notification_outbox
        set sent_at = timezone('utc', now()),
            last_error = v_error,
            locked_at = null,
            lock_token = null
        where id = p_outbox_id;
    elsif p_outcome = 'failed' or v_attempt_count >= 5 then
        update public.notification_outbox
        set failed_at = timezone('utc', now()),
            last_error = case
                when p_outcome = 'failed' then v_error
                else concat('MAX_ATTEMPTS:', coalesce(v_error, 'UNKNOWN'))
            end,
            locked_at = null,
            lock_token = null
        where id = p_outbox_id;
    else
        v_retry_seconds := least(
            3600,
            (30 * power(2, greatest(v_attempt_count - 1, 0)))::integer
        );
        update public.notification_outbox
        set next_attempt_at = timezone('utc', now())
                + make_interval(secs => v_retry_seconds),
            last_error = v_error,
            locked_at = null,
            lock_token = null
        where id = p_outbox_id;
    end if;

    return true;
end;
$$;

revoke all on function public.finish_notification_outbox(uuid, uuid, text, text)
from public, anon, authenticated;
grant execute on function public.finish_notification_outbox(uuid, uuid, text, text)
to service_role;

create or replace function public.invoke_notification_dispatcher()
returns bigint
language plpgsql
security definer
set search_path = ''
as $$
declare
    v_project_url text;
    v_dispatch_secret text;
    v_request_id bigint;
begin
    select decrypted_secret into v_project_url
    from vault.decrypted_secrets
    where name = 'project_url'
    order by created_at desc
    limit 1;

    select decrypted_secret into v_dispatch_secret
    from vault.decrypted_secrets
    where name = 'notification_dispatch_secret'
    order by created_at desc
    limit 1;

    if nullif(btrim(v_project_url), '') is null
       or char_length(coalesce(v_dispatch_secret, '')) < 32 then
        raise exception 'NOTIFICATION_DISPATCH_VAULT_NOT_CONFIGURED';
    end if;

    select net.http_post(
        url := rtrim(v_project_url, '/')
            || '/functions/v1/notification-dispatcher',
        headers := jsonb_build_object(
            'Content-Type', 'application/json',
            'x-notification-dispatch-secret', v_dispatch_secret
        ),
        body := '{}'::jsonb,
        timeout_milliseconds := 20000
    ) into v_request_id;

    return v_request_id;
end;
$$;

revoke all on function public.invoke_notification_dispatcher()
from public, anon, authenticated;
grant execute on function public.invoke_notification_dispatcher()
to service_role;

create or replace function public.schedule_notification_jobs()
returns table (dispatch_job_id bigint, cleanup_job_id bigint)
language plpgsql
security definer
set search_path = ''
as $$
declare
    v_job_id bigint;
begin
    -- Validate Vault before creating jobs that would otherwise fail forever.
    perform public.invoke_notification_dispatcher();

    for v_job_id in
        select jobid from cron.job
        where jobname in (
            'dispatch_notification_outbox',
            'cleanup_expired_notifications'
        )
    loop
        perform cron.unschedule(v_job_id);
    end loop;

    select cron.schedule(
        'dispatch_notification_outbox',
        '* * * * *',
        'select public.invoke_notification_dispatcher();'
    ) into dispatch_job_id;

    select cron.schedule(
        'cleanup_expired_notifications',
        '15 3 * * *',
        'select public.cleanup_expired_notifications();'
    ) into cleanup_job_id;

    return next;
end;
$$;

revoke all on function public.schedule_notification_jobs()
from public, anon, authenticated;
grant execute on function public.schedule_notification_jobs()
to service_role;
