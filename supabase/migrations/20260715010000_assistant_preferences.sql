-- Restored from the remote migration history.

create table if not exists public.assistant_preferences (
    user_id uuid primary key references auth.users(id) on delete cascade,
    intro_seen boolean not null default false,
    enabled boolean not null default false,
    transactions boolean not null default true,
    wallets boolean not null default true,
    budgets boolean not null default false,
    consented_at timestamptz,
    created_at timestamptz not null default timezone('utc', now()),
    updated_at timestamptz not null default timezone('utc', now())
);

drop trigger if exists set_assistant_preferences_updated_at
    on public.assistant_preferences;
create trigger set_assistant_preferences_updated_at
before update on public.assistant_preferences
for each row execute function public.set_updated_at();

alter table public.assistant_preferences enable row level security;

drop policy if exists "assistant_preferences_select_own"
    on public.assistant_preferences;
create policy "assistant_preferences_select_own"
on public.assistant_preferences for select to authenticated
using (user_id = auth.uid());

drop policy if exists "assistant_preferences_insert_own"
    on public.assistant_preferences;
create policy "assistant_preferences_insert_own"
on public.assistant_preferences for insert to authenticated
with check (user_id = auth.uid());

drop policy if exists "assistant_preferences_update_own"
    on public.assistant_preferences;
create policy "assistant_preferences_update_own"
on public.assistant_preferences for update to authenticated
using (user_id = auth.uid())
with check (user_id = auth.uid());

drop policy if exists "assistant_preferences_delete_own"
    on public.assistant_preferences;
create policy "assistant_preferences_delete_own"
on public.assistant_preferences for delete to authenticated
using (user_id = auth.uid());

create table if not exists public.assistant_rate_limits (
    user_id uuid not null references auth.users(id) on delete cascade,
    bucket_start timestamptz not null,
    request_count integer not null default 0,
    updated_at timestamptz not null default timezone('utc', now()),
    primary key (user_id, bucket_start),
    constraint assistant_rate_limits_request_count_nonnegative
        check (request_count >= 0)
);

create index if not exists assistant_rate_limits_updated_idx
    on public.assistant_rate_limits (updated_at);

alter table public.assistant_rate_limits enable row level security;

create or replace function public.consume_assistant_rate_limit(
    p_user_id uuid,
    p_bucket_start timestamptz,
    p_limit integer
)
returns boolean
language plpgsql
security definer
set search_path = public
as $$
declare
    v_count integer;
begin
    if p_user_id is null or p_bucket_start is null or p_limit < 1 then
        return false;
    end if;

    insert into public.assistant_rate_limits
        (user_id, bucket_start, request_count, updated_at)
    values
        (p_user_id, p_bucket_start, 1, timezone('utc', now()))
    on conflict (user_id, bucket_start) do update
    set request_count = public.assistant_rate_limits.request_count + 1,
        updated_at = timezone('utc', now())
    returning request_count into v_count;

    return v_count <= p_limit;
end;
$$;

revoke all on function public.consume_assistant_rate_limit(
    uuid, timestamptz, integer
) from public;
grant execute on function public.consume_assistant_rate_limit(
    uuid, timestamptz, integer
) to service_role;
