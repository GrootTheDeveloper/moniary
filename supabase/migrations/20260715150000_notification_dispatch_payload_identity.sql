-- The dispatcher must expose the source notification ID to clients, not the
-- internal outbox row ID. Recreate the claim RPC because PostgreSQL cannot
-- change a function's TABLE return type with create or replace.

drop function if exists public.claim_notification_outbox(integer, uuid);

create function public.claim_notification_outbox(
    p_limit integer,
    p_lock_token uuid
)
returns table (
    id uuid,
    notification_id uuid,
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
            outbox.notification_id,
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
