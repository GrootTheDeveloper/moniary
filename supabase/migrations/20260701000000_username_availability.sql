create or replace function public.is_username_available(p_username text)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
    with normalized as (
        select lower(btrim(coalesce(p_username, ''))) as username
    )
    select
        normalized.username ~ '^[a-z0-9_]{3,30}$'
        and not exists (
            select 1
            from public.profiles p
            where lower(p.username) = normalized.username
              and p.id <> auth.uid()
        )
    from normalized;
$$;

revoke all on function public.is_username_available(text) from public;
grant execute on function public.is_username_available(text) to authenticated;
