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
        select
            lower(btrim(coalesce(p_query, ''))) as raw_query,
            case
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
      and n.raw_query <> ''
      and p.id <> auth.uid()
      and coalesce(p.deleted_at is null, true)
      and (
          lower(coalesce(p.username, '')) like n.username_query || '%'
          or (
              position('@' in n.raw_query) > 1
              and lower(coalesce(p.email, '')) = n.raw_query
          )
      )
    order by lower(coalesce(p.username, p.full_name, p.id::text))
    limit 20;
$$;

revoke all on function public.search_friend_profiles(text) from public;
grant execute on function public.search_friend_profiles(text) to authenticated;
