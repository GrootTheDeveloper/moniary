do $$
begin
    create type public.friend_request_status
        as enum ('pending', 'accepted', 'declined', 'cancelled');
exception
    when duplicate_object then null;
end
$$;

create table if not exists public.friend_requests (
    id uuid primary key default gen_random_uuid(),
    from_user_id uuid not null,
    to_user_id uuid not null,
    status public.friend_request_status not null default 'pending',
    created_at timestamptz not null default timezone('utc', now()),
    updated_at timestamptz not null default timezone('utc', now()),
    responded_at timestamptz,
    constraint friend_requests_from_user_profiles_fkey
        foreign key (from_user_id) references public.profiles(id)
        on delete cascade,
    constraint friend_requests_to_user_profiles_fkey
        foreign key (to_user_id) references public.profiles(id)
        on delete cascade,
    constraint friend_requests_no_self check (from_user_id <> to_user_id)
);

create unique index if not exists friend_requests_pending_pair_key
    on public.friend_requests (
        least(from_user_id, to_user_id),
        greatest(from_user_id, to_user_id)
    )
    where status = 'pending';

create index if not exists friend_requests_to_status_idx
    on public.friend_requests (to_user_id, status, created_at desc);

create index if not exists friend_requests_from_status_idx
    on public.friend_requests (from_user_id, status, created_at desc);

create table if not exists public.friendships (
    id uuid primary key default gen_random_uuid(),
    user_id uuid not null,
    friend_user_id uuid not null,
    created_at timestamptz not null default timezone('utc', now()),
    constraint friendships_user_profiles_fkey
        foreign key (user_id) references public.profiles(id)
        on delete cascade,
    constraint friendships_friend_user_profiles_fkey
        foreign key (friend_user_id) references public.profiles(id)
        on delete cascade,
    constraint friendships_no_self check (user_id <> friend_user_id),
    constraint friendships_user_friend_key unique (user_id, friend_user_id)
);

create index if not exists friendships_user_created_idx
    on public.friendships (user_id, created_at desc);

drop trigger if exists set_friend_requests_updated_at
    on public.friend_requests;
create trigger set_friend_requests_updated_at
before update on public.friend_requests
for each row execute function public.set_updated_at();

alter table public.friend_requests enable row level security;
alter table public.friendships enable row level security;

drop policy if exists "friend_requests_select_participant"
    on public.friend_requests;
create policy "friend_requests_select_participant"
on public.friend_requests for select to authenticated
using (from_user_id = auth.uid() or to_user_id = auth.uid());

drop policy if exists "friendships_select_own" on public.friendships;
create policy "friendships_select_own"
on public.friendships for select to authenticated
using (user_id = auth.uid());

create or replace function public.are_friends(
    p_user_id uuid,
    p_friend_user_id uuid
)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
    select exists (
        select 1
        from public.friendships
        where user_id = p_user_id
          and friend_user_id = p_friend_user_id
    );
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
      and (
          (p_direction = 'outgoing' and fr.from_user_id = auth.uid())
          or (p_direction <> 'outgoing' and fr.to_user_id = auth.uid())
      )
    order by fr.created_at desc;
$$;

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
        select lower(btrim(coalesce(p_query, ''))) as query
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
      and n.query <> ''
      and p.id <> auth.uid()
      and lower(coalesce(p.username, '')) like n.query || '%'
    order by lower(coalesce(p.username, p.full_name, p.id::text))
    limit 20;
$$;

create or replace function public.send_friend_request(p_username text)
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
    where lower(username) = lower(btrim(coalesce(p_username, '')))
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

create or replace function public.accept_friend_request(p_request_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
    v_from_user_id uuid;
    v_to_user_id uuid;
begin
    if auth.uid() is null then
        raise exception 'AUTH_REQUIRED';
    end if;

    select from_user_id, to_user_id
    into v_from_user_id, v_to_user_id
    from public.friend_requests
    where id = p_request_id
      and status = 'pending'
      and to_user_id = auth.uid()
    for update;

    if v_from_user_id is null then
        raise exception 'FRIEND_REQUEST_NOT_FOUND';
    end if;

    update public.friend_requests
    set status = 'accepted',
        responded_at = timezone('utc', now())
    where id = p_request_id;

    insert into public.friendships (user_id, friend_user_id)
    values (v_from_user_id, v_to_user_id)
    on conflict (user_id, friend_user_id) do nothing;

    insert into public.friendships (user_id, friend_user_id)
    values (v_to_user_id, v_from_user_id)
    on conflict (user_id, friend_user_id) do nothing;
end;
$$;

create or replace function public.decline_friend_request(p_request_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
    if auth.uid() is null then
        raise exception 'AUTH_REQUIRED';
    end if;

    update public.friend_requests
    set status = 'declined',
        responded_at = timezone('utc', now())
    where id = p_request_id
      and status = 'pending'
      and to_user_id = auth.uid();

    if not found then
        raise exception 'FRIEND_REQUEST_NOT_FOUND';
    end if;
end;
$$;

create or replace function public.cancel_friend_request(p_request_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
    if auth.uid() is null then
        raise exception 'AUTH_REQUIRED';
    end if;

    update public.friend_requests
    set status = 'cancelled',
        responded_at = timezone('utc', now())
    where id = p_request_id
      and status = 'pending'
      and from_user_id = auth.uid();

    if not found then
        raise exception 'FRIEND_REQUEST_NOT_FOUND';
    end if;
end;
$$;

create or replace function public.remove_friend(p_friend_user_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
    if auth.uid() is null then
        raise exception 'AUTH_REQUIRED';
    end if;

    delete from public.friendships
    where (user_id = auth.uid() and friend_user_id = p_friend_user_id)
       or (user_id = p_friend_user_id and friend_user_id = auth.uid());

    if not found then
        raise exception 'FRIEND_NOT_FOUND';
    end if;
end;
$$;

create or replace function public.invite_group_member_by_user_id(
    p_group_id uuid,
    p_user_id uuid
)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
    if not public.has_group_role(
        p_group_id,
        array['owner', 'admin']::public.group_role[]
    ) then
        raise exception 'GROUP_ADMIN_REQUIRED';
    end if;

    if p_user_id is null or not exists (
        select 1 from public.profiles where id = p_user_id
    ) then
        raise exception 'GROUP_USER_NOT_FOUND';
    end if;

    if not public.are_friends(auth.uid(), p_user_id) then
        raise exception 'FRIEND_NOT_FOUND';
    end if;

    if exists (
        select 1
        from public.group_members
        where group_id = p_group_id
          and user_id = p_user_id
          and status in ('active', 'invited')
    ) then
        raise exception 'GROUP_MEMBER_ALREADY_INVITED';
    end if;

    insert into public.group_members (
        group_id,
        user_id,
        role,
        status
    )
    values (p_group_id, p_user_id, 'member', 'invited')
    on conflict (group_id, user_id) do update
    set status = 'invited',
        role = 'member',
        left_at = null;

    insert into public.group_invites (
        group_id,
        invited_user_id,
        invited_by
    )
    values (p_group_id, p_user_id, auth.uid())
    on conflict (group_id, invited_user_id)
        where invited_user_id is not null and status = 'pending'
    do nothing;

    insert into public.group_notifications (group_id, user_id, type)
    values (p_group_id, p_user_id, 'group_invite');
end;
$$;

revoke all on function public.are_friends(uuid, uuid) from public;
revoke all on function public.list_friend_profiles() from public;
revoke all on function public.list_friend_requests(text) from public;
revoke all on function public.search_friend_profiles(text) from public;
revoke all on function public.send_friend_request(text) from public;
revoke all on function public.accept_friend_request(uuid) from public;
revoke all on function public.decline_friend_request(uuid) from public;
revoke all on function public.cancel_friend_request(uuid) from public;
revoke all on function public.remove_friend(uuid) from public;
revoke all on function public.invite_group_member_by_user_id(uuid, uuid)
    from public;

grant select on public.friend_requests to authenticated;
grant select on public.friendships to authenticated;

grant execute on function public.list_friend_profiles() to authenticated;
grant execute on function public.list_friend_requests(text) to authenticated;
grant execute on function public.search_friend_profiles(text) to authenticated;
grant execute on function public.send_friend_request(text) to authenticated;
grant execute on function public.accept_friend_request(uuid) to authenticated;
grant execute on function public.decline_friend_request(uuid) to authenticated;
grant execute on function public.cancel_friend_request(uuid) to authenticated;
grant execute on function public.remove_friend(uuid) to authenticated;
grant execute on function public.invite_group_member_by_user_id(uuid, uuid)
    to authenticated;
