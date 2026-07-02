do $$
begin
    create type public.friend_invite_link_status
        as enum ('active', 'used', 'revoked');
exception
    when duplicate_object then null;
end
$$;

create table if not exists public.friend_invite_links (
    id uuid primary key default gen_random_uuid(),
    creator_user_id uuid not null references public.profiles(id) on delete cascade,
    token_hash text not null unique,
    status public.friend_invite_link_status not null default 'active',
    expires_at timestamptz not null default timezone('utc', now()) + interval '30 days',
    used_by_user_id uuid references public.profiles(id) on delete set null,
    used_at timestamptz,
    revoked_at timestamptz,
    created_at timestamptz not null default timezone('utc', now()),
    updated_at timestamptz not null default timezone('utc', now()),
    constraint friend_invite_links_no_self_use
        check (used_by_user_id is null or used_by_user_id <> creator_user_id)
);

create index if not exists friend_invite_links_creator_created_idx
    on public.friend_invite_links (creator_user_id, created_at desc);

create index if not exists friend_invite_links_used_by_idx
    on public.friend_invite_links (used_by_user_id, used_at desc)
    where used_by_user_id is not null;

drop trigger if exists set_friend_invite_links_updated_at
    on public.friend_invite_links;
create trigger set_friend_invite_links_updated_at
before update on public.friend_invite_links
for each row execute function public.set_updated_at();

alter table public.friend_invite_links enable row level security;

drop policy if exists "friend_invite_links_select_related"
    on public.friend_invite_links;
create policy "friend_invite_links_select_related"
on public.friend_invite_links for select to authenticated
using (creator_user_id = auth.uid() or used_by_user_id = auth.uid());

create or replace function public.hash_friend_invite_token(p_token text)
returns text
language sql
immutable
security definer
set search_path = public
as $$
    select encode(extensions.digest(coalesce(p_token, ''), 'sha256'), 'hex');
$$;

create or replace function public.create_friend_invite_link()
returns table (
    token text,
    expires_at timestamptz
)
language plpgsql
security definer
set search_path = public
as $$
declare
    v_token text;
    v_expires_at timestamptz;
begin
    if auth.uid() is null then
        raise exception 'AUTH_REQUIRED';
    end if;

    update public.friend_invite_links
    set status = 'revoked',
        revoked_at = timezone('utc', now())
    where creator_user_id = auth.uid()
      and status = 'active'
      and used_at is null;

    v_token := encode(extensions.gen_random_bytes(32), 'hex');

    insert into public.friend_invite_links (
        creator_user_id,
        token_hash
    )
    values (
        auth.uid(),
        public.hash_friend_invite_token(v_token)
    )
    returning friend_invite_links.expires_at
    into v_expires_at;

    token := v_token;
    expires_at := v_expires_at;
    return next;
end;
$$;

create or replace function public.get_friend_invite_preview(p_token text)
returns table (
    inviter_user_id uuid,
    full_name text,
    username text,
    avatar_url text,
    invite_status text,
    relation_status text,
    expires_at timestamptz
)
language plpgsql
stable
security definer
set search_path = public
as $$
declare
    v_invite public.friend_invite_links%rowtype;
begin
    if auth.uid() is null then
        raise exception 'AUTH_REQUIRED';
    end if;

    select *
    into v_invite
    from public.friend_invite_links
    where token_hash = public.hash_friend_invite_token(btrim(coalesce(p_token, '')))
    limit 1;

    if v_invite.id is null then
        invite_status := 'invalid';
        relation_status := 'none';
        return next;
        return;
    end if;

    select
        p.id,
        p.full_name,
        p.username,
        p.avatar_url
    into
        inviter_user_id,
        full_name,
        username,
        avatar_url
    from public.profiles p
    where p.id = v_invite.creator_user_id;

    expires_at := v_invite.expires_at;

    if v_invite.status = 'revoked' then
        invite_status := 'revoked';
    elsif v_invite.status = 'used' then
        invite_status := 'used';
    elsif v_invite.expires_at <= timezone('utc', now()) then
        invite_status := 'expired';
    elsif v_invite.creator_user_id = auth.uid() then
        invite_status := 'self';
    elsif public.are_friends(auth.uid(), v_invite.creator_user_id) then
        invite_status := 'already_friends';
    else
        invite_status := 'active';
    end if;

    relation_status := case
        when v_invite.creator_user_id = auth.uid() then 'self'
        when public.are_friends(auth.uid(), v_invite.creator_user_id) then 'friends'
        when exists (
            select 1
            from public.friend_requests fr
            where fr.status = 'pending'
              and fr.from_user_id = auth.uid()
              and fr.to_user_id = v_invite.creator_user_id
        ) then 'outgoing_pending'
        when exists (
            select 1
            from public.friend_requests fr
            where fr.status = 'pending'
              and fr.from_user_id = v_invite.creator_user_id
              and fr.to_user_id = auth.uid()
        ) then 'incoming_pending'
        else 'none'
    end;

    return next;
end;
$$;

create or replace function public.accept_friend_invite(p_token text)
returns table (
    inviter_user_id uuid,
    status text
)
language plpgsql
security definer
set search_path = public
as $$
declare
    v_invite public.friend_invite_links%rowtype;
begin
    if auth.uid() is null then
        raise exception 'AUTH_REQUIRED';
    end if;

    select *
    into v_invite
    from public.friend_invite_links
    where token_hash = public.hash_friend_invite_token(btrim(coalesce(p_token, '')))
    for update;

    if v_invite.id is null then
        raise exception 'FRIEND_INVITE_INVALID';
    end if;

    inviter_user_id := v_invite.creator_user_id;

    if v_invite.creator_user_id = auth.uid() then
        raise exception 'FRIEND_INVITE_SELF';
    end if;

    if public.are_friends(auth.uid(), v_invite.creator_user_id) then
        status := 'already_friends';
        return next;
        return;
    end if;

    if v_invite.status = 'revoked' then
        raise exception 'FRIEND_INVITE_REVOKED';
    end if;

    if v_invite.status = 'used' then
        raise exception 'FRIEND_INVITE_USED';
    end if;

    if v_invite.expires_at <= timezone('utc', now()) then
        raise exception 'FRIEND_INVITE_EXPIRED';
    end if;

    update public.friend_requests fr
    set status = 'accepted',
        responded_at = timezone('utc', now())
    where fr.status = 'pending'
      and (
          (fr.from_user_id = auth.uid() and fr.to_user_id = v_invite.creator_user_id)
          or (fr.from_user_id = v_invite.creator_user_id and fr.to_user_id = auth.uid())
      );

    insert into public.friendships (user_id, friend_user_id)
    values (auth.uid(), v_invite.creator_user_id)
    on conflict (user_id, friend_user_id) do nothing;

    insert into public.friendships (user_id, friend_user_id)
    values (v_invite.creator_user_id, auth.uid())
    on conflict (user_id, friend_user_id) do nothing;

    update public.friend_invite_links
    set status = 'used',
        used_by_user_id = auth.uid(),
        used_at = timezone('utc', now())
    where id = v_invite.id;

    status := 'accepted';
    return next;
end;
$$;

create or replace function public.revoke_friend_invite_link(p_token text)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
    if auth.uid() is null then
        raise exception 'AUTH_REQUIRED';
    end if;

    update public.friend_invite_links
    set status = 'revoked',
        revoked_at = timezone('utc', now())
    where token_hash = public.hash_friend_invite_token(btrim(coalesce(p_token, '')))
      and creator_user_id = auth.uid()
      and status = 'active';

    if not found then
        raise exception 'FRIEND_INVITE_NOT_FOUND';
    end if;
end;
$$;

grant execute on function public.create_friend_invite_link()
    to authenticated;
grant execute on function public.get_friend_invite_preview(text)
    to authenticated;
grant execute on function public.accept_friend_invite(text)
    to authenticated;
grant execute on function public.revoke_friend_invite_link(text)
    to authenticated;
