-- A real, server-side privacy request channel. Requests are immutable to the
-- submitting user; only trusted service-role/admin processes may change their
-- processing status or response metadata.

create table if not exists public.privacy_requests (
    id uuid primary key default gen_random_uuid(),
    user_id uuid not null references auth.users(id) on delete cascade,
    request_type text not null,
    message text not null,
    status text not null default 'submitted',
    admin_note text,
    submitted_at timestamptz not null default timezone('utc', now()),
    updated_at timestamptz not null default timezone('utc', now()),
    resolved_at timestamptz,
    constraint privacy_requests_type_valid check (
        request_type in (
            'data_access',
            'data_export_help',
            'data_correction',
            'data_deletion',
            'privacy_complaint'
        )
    ),
    constraint privacy_requests_message_valid check (
        length(btrim(message)) between 1 and 4000
    ),
    constraint privacy_requests_status_valid check (
        status in ('submitted', 'in_review', 'resolved', 'rejected')
    ),
    constraint privacy_requests_resolution_consistent check (
        (status in ('resolved', 'rejected') and resolved_at is not null)
        or (status in ('submitted', 'in_review') and resolved_at is null)
    )
);

create index if not exists privacy_requests_user_submitted_idx
    on public.privacy_requests (user_id, submitted_at desc);
create index if not exists privacy_requests_admin_queue_idx
    on public.privacy_requests (status, submitted_at asc)
    where status in ('submitted', 'in_review');

drop trigger if exists set_privacy_requests_updated_at
    on public.privacy_requests;
create trigger set_privacy_requests_updated_at
before update on public.privacy_requests
for each row execute function public.set_updated_at();

alter table public.privacy_requests enable row level security;

drop policy if exists "privacy_requests_select_own"
    on public.privacy_requests;
create policy "privacy_requests_select_own"
on public.privacy_requests
for select to authenticated
using (user_id = auth.uid());

drop policy if exists "privacy_requests_insert_own"
    on public.privacy_requests;

create or replace function public.submit_privacy_request(
    p_request_type text,
    p_message text
)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
    v_user_id uuid := auth.uid();
    v_request_id uuid;
    v_message text := btrim(coalesce(p_message, ''));
begin
    if v_user_id is null then
        raise exception 'AUTH_REQUIRED' using errcode = '42501';
    end if;
    if p_request_type not in (
        'data_access',
        'data_export_help',
        'data_correction',
        'data_deletion',
        'privacy_complaint'
    ) then
        raise exception 'PRIVACY_REQUEST_TYPE_INVALID' using errcode = '22023';
    end if;
    if length(v_message) not between 1 and 4000 then
        raise exception 'PRIVACY_REQUEST_MESSAGE_INVALID' using errcode = '22023';
    end if;

    perform pg_advisory_xact_lock(
        hashtextextended('privacy:' || v_user_id::text, 0)
    );
    if (
        select count(*)
        from public.privacy_requests
        where user_id = v_user_id
          and submitted_at >= timezone('utc', now()) - interval '24 hours'
    ) >= 5 then
        raise exception 'PRIVACY_REQUEST_RATE_LIMITED' using errcode = 'P0001';
    end if;

    insert into public.privacy_requests (user_id, request_type, message)
    values (v_user_id, p_request_type, v_message)
    returning id into v_request_id;
    return v_request_id;
end;
$$;

revoke all on function public.submit_privacy_request(text, text) from public;
grant execute on function public.submit_privacy_request(text, text)
    to authenticated;

-- No authenticated INSERT/UPDATE/DELETE policy: submissions pass through the
-- bounded RPC, users cannot mark their own request resolved, and users cannot
-- erase the audit trail. The service role remains responsible for processing.
