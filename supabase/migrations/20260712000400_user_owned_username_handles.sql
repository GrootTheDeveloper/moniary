create or replace function public.ensure_profile_username()
returns trigger
language plpgsql
set search_path = public
as $$
begin
    if new.username is null or btrim(new.username) = '' then
        new.username := null;
    else
        new.username := lower(btrim(new.username));
    end if;
    return new;
end;
$$;

drop trigger if exists ensure_profiles_username on public.profiles;
create trigger ensure_profiles_username
before insert or update of username on public.profiles
for each row execute function public.ensure_profile_username();

update public.profiles
set username = null
where username ~ '^user_[0-9a-f]{24}$';

create or replace function public.search_friend_profiles(p_query text)
returns table (
    user_id uuid,
    full_name text,
    username text,
    avatar_url text,
    relation_status text
)
language sql
stable
security definer
set search_path = public
as $$
    with normalized as (
        select case
            when lower(btrim(coalesce(p_query, ''))) like '@%' then
                substring(lower(btrim(coalesce(p_query, ''))) from 2)
            else lower(btrim(coalesce(p_query, '')))
        end as username_query
    )
    select
        p.id as user_id,
        p.full_name,
        p.username,
        p.avatar_url,
        case
            when exists (
                select 1
                from public.friendships f
                where f.user_id = auth.uid()
                  and f.friend_user_id = p.id
            ) then 'friends'
            when exists (
                select 1
                from public.friend_requests fr
                where fr.from_user_id = auth.uid()
                  and fr.to_user_id = p.id
                  and fr.status = 'pending'
            ) then 'outgoing_pending'
            when exists (
                select 1
                from public.friend_requests fr
                where fr.from_user_id = p.id
                  and fr.to_user_id = auth.uid()
                  and fr.status = 'pending'
            ) then 'incoming_pending'
            else 'none'
        end as relation_status
    from public.profiles p, normalized n
    where auth.uid() is not null
      and n.username_query <> ''
      and p.id <> auth.uid()
      and p.username is not null
      and coalesce(p.deleted_at is null, true)
      and lower(p.username) like n.username_query || '%'
    order by
        case when lower(p.username) = n.username_query then 0 else 1 end,
        lower(p.username)
    limit 20;
$$;

revoke all on function public.search_friend_profiles(text) from public;
grant execute on function public.search_friend_profiles(text) to authenticated;
