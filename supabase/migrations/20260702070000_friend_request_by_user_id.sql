create or replace function public.send_friend_request_by_user_id(
    p_target_user_id uuid
)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
    v_target_user_id uuid;
    v_request_id uuid;
begin
    if auth.uid() is null then
        raise exception 'AUTH_REQUIRED';
    end if;

    select id
    into v_target_user_id
    from public.profiles
    where id = p_target_user_id
      and coalesce(deleted_at is null, true)
    limit 1;

    if v_target_user_id is null then
        raise exception 'FRIEND_USER_NOT_FOUND';
    end if;

    if v_target_user_id = auth.uid() then
        raise exception 'FRIEND_CANNOT_ADD_SELF';
    end if;

    if public.are_friends(auth.uid(), v_target_user_id) then
        raise exception 'FRIEND_ALREADY_EXISTS';
    end if;

    if exists (
        select 1
        from public.friend_requests
        where status = 'pending'
          and (
              (from_user_id = auth.uid() and to_user_id = v_target_user_id)
              or (from_user_id = v_target_user_id and to_user_id = auth.uid())
          )
    ) then
        raise exception 'FRIEND_REQUEST_ALREADY_PENDING';
    end if;

    insert into public.friend_requests (from_user_id, to_user_id)
    values (auth.uid(), v_target_user_id)
    returning id into v_request_id;

    return v_request_id;
end;
$$;

create or replace function public.list_friend_profiles()
returns table (
    user_id uuid,
    full_name text,
    username text,
    avatar_url text,
    friends_since timestamptz
)
language sql
stable
security definer
set search_path = public
as $$
    select
        p.id as user_id,
        p.full_name,
        p.username,
        p.avatar_url,
        f.created_at as friends_since
    from public.friendships f
    join public.profiles p on p.id = f.friend_user_id
    where f.user_id = auth.uid()
      and coalesce(p.deleted_at is null, true)
    order by lower(coalesce(p.full_name, p.username, p.id::text));
$$;

create or replace function public.list_friend_requests(
    p_direction text default 'incoming'
)
returns table (
    request_id uuid,
    from_user_id uuid,
    to_user_id uuid,
    other_user_id uuid,
    full_name text,
    username text,
    avatar_url text,
    status text,
    created_at timestamptz
)
language sql
stable
security definer
set search_path = public
as $$
    select
        fr.id as request_id,
        fr.from_user_id,
        fr.to_user_id,
        case
            when p_direction = 'outgoing' then fr.to_user_id
            else fr.from_user_id
        end as other_user_id,
        p.full_name,
        p.username,
        p.avatar_url,
        fr.status::text,
        fr.created_at
    from public.friend_requests fr
    join public.profiles p
      on p.id = case
          when p_direction = 'outgoing' then fr.to_user_id
          else fr.from_user_id
      end
    where fr.status = 'pending'
      and coalesce(p.deleted_at is null, true)
      and (
          (p_direction = 'outgoing' and fr.from_user_id = auth.uid())
          or (p_direction <> 'outgoing' and fr.to_user_id = auth.uid())
      )
    order by fr.created_at desc;
$$;

revoke all on function public.send_friend_request_by_user_id(uuid) from public;
revoke all on function public.list_friend_profiles() from public;
revoke all on function public.list_friend_requests(text) from public;

grant execute on function public.send_friend_request_by_user_id(uuid)
    to authenticated;
grant execute on function public.list_friend_profiles() to authenticated;
grant execute on function public.list_friend_requests(text) to authenticated;
