-- Shared group invite links are reusable until they expire or an admin revokes
-- them. Direct invitations continue to use the same table with a non-null
-- invited_user_id.

alter table public.group_invites
    drop constraint if exists group_invites_status_check;

alter table public.group_invites
    add constraint group_invites_status_check
    check (status in ('pending', 'accepted', 'declined', 'expired', 'revoked'));

create or replace function public.create_group_invite_link(p_group_id uuid)
returns text
language plpgsql
security definer
set search_path = public
as $$
declare
    v_token text;
begin
    if not public.has_group_role(
        p_group_id,
        array['owner', 'admin']::public.group_role[]
    ) then
        raise exception 'GROUP_ADMIN_REQUIRED';
    end if;

    update public.group_invites
    set status = 'expired'
    where group_id = p_group_id
      and invited_user_id is null
      and status = 'pending'
      and expires_at <= timezone('utc', now());

    -- Regenerating a link revokes the previously active shared link. This keeps
    -- a single, user-manageable active link for each group.
    update public.group_invites
    set status = 'revoked'
    where group_id = p_group_id
      and invited_user_id is null
      and status = 'pending';

    insert into public.group_invites (group_id, invited_by)
    values (p_group_id, auth.uid())
    returning token into v_token;

    return 'moniary://groups/invite/' || v_token;
end;
$$;

create or replace function public.get_group_invite_preview(p_token text)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
    v_invite public.group_invites%rowtype;
    v_group public.groups%rowtype;
    v_inviter_name text;
begin
    if auth.uid() is null then
        raise exception 'AUTH_REQUIRED';
    end if;

    select * into v_invite
    from public.group_invites
    where token = btrim(p_token)
      and invited_user_id is null;

    if not found then
        return jsonb_build_object('status', 'invalid');
    end if;

    if v_invite.status = 'pending' and v_invite.expires_at <= timezone('utc', now()) then
        update public.group_invites
        set status = 'expired'
        where id = v_invite.id;
        v_invite.status := 'expired';
    end if;

    select * into v_group
    from public.groups
    where id = v_invite.group_id;

    if not found or v_group.status <> 'active' then
        return jsonb_build_object('status', 'invalid');
    end if;

    select coalesce(nullif(btrim(full_name), ''), username)
    into v_inviter_name
    from public.profiles
    where id = v_invite.invited_by;

    if exists (
        select 1
        from public.group_members
        where group_id = v_invite.group_id
          and user_id = auth.uid()
          and status = 'active'
    ) then
        return jsonb_build_object(
            'status', 'already_member',
            'group_id', v_group.id,
            'group_name', v_group.name,
            'group_avatar_path', v_group.avatar_path,
            'inviter_name', v_inviter_name,
            'expires_at', v_invite.expires_at
        );
    end if;

    if v_invite.status = 'revoked' then
        return jsonb_build_object('status', 'revoked');
    end if;
    if v_invite.status = 'expired' then
        return jsonb_build_object('status', 'expired');
    end if;
    if v_invite.status = 'accepted' then
        return jsonb_build_object('status', 'used');
    end if;
    if v_invite.status <> 'pending' then
        return jsonb_build_object('status', 'invalid');
    end if;

    return jsonb_build_object(
        'status', 'active',
        'group_id', v_group.id,
        'group_name', v_group.name,
        'group_avatar_path', v_group.avatar_path,
        'inviter_name', v_inviter_name,
        'expires_at', v_invite.expires_at
    );
end;
$$;

create or replace function public.accept_group_invite_link(p_token text)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
    v_invite public.group_invites%rowtype;
    v_group_status public.group_status;
begin
    if auth.uid() is null then
        raise exception 'AUTH_REQUIRED';
    end if;

    select * into v_invite
    from public.group_invites
    where token = btrim(p_token)
      and invited_user_id is null
    for update;

    if not found then
        raise exception 'GROUP_INVITE_INVALID';
    end if;

    if v_invite.status = 'pending' and v_invite.expires_at <= timezone('utc', now()) then
        update public.group_invites
        set status = 'expired'
        where id = v_invite.id;
        v_invite.status := 'expired';
    end if;

    if v_invite.status = 'revoked' then
        raise exception 'GROUP_INVITE_REVOKED';
    end if;
    if v_invite.status = 'expired' then
        raise exception 'GROUP_INVITE_EXPIRED';
    end if;
    if v_invite.status = 'accepted' then
        raise exception 'GROUP_INVITE_USED';
    end if;
    if v_invite.status <> 'pending' then
        raise exception 'GROUP_INVITE_INVALID';
    end if;

    select g.status into v_group_status
    from public.groups as g
    where g.id = v_invite.group_id;
    if not found or v_group_status <> 'active' then
        raise exception 'GROUP_INVITE_INVALID';
    end if;

    if exists (
        select 1
        from public.group_members
        where group_id = v_invite.group_id
          and user_id = auth.uid()
          and status = 'active'
    ) then
        return jsonb_build_object(
            'status', 'already_member',
            'group_id', v_invite.group_id
        );
    end if;

    insert into public.group_members (
        group_id,
        user_id,
        role,
        status,
        joined_at,
        left_at
    )
    values (
        v_invite.group_id,
        auth.uid(),
        'member',
        'active',
        timezone('utc', now()),
        null
    )
    on conflict (group_id, user_id) do update
    set role = 'member',
        status = 'active',
        joined_at = excluded.joined_at,
        left_at = null;

    insert into public.group_activities (group_id, actor_user_id, type, metadata)
    values (
        v_invite.group_id,
        auth.uid(),
        'member_joined_by_link',
        jsonb_build_object('invite_id', v_invite.id)
    );

    -- Do not mark the shared link accepted: it is reusable by many people for
    -- its full seven-day lifetime.
    return jsonb_build_object(
        'status', 'accepted',
        'group_id', v_invite.group_id
    );
end;
$$;

create or replace function public.revoke_group_invite_link(p_token text)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
    v_invite public.group_invites%rowtype;
begin
    if auth.uid() is null then
        raise exception 'AUTH_REQUIRED';
    end if;

    select * into v_invite
    from public.group_invites
    where token = btrim(p_token)
      and invited_user_id is null
    for update;

    if not found then
        raise exception 'GROUP_INVITE_INVALID';
    end if;

    if not public.has_group_role(
        v_invite.group_id,
        array['owner', 'admin']::public.group_role[]
    ) then
        raise exception 'GROUP_ADMIN_REQUIRED';
    end if;

    if v_invite.status = 'pending' and v_invite.expires_at <= timezone('utc', now()) then
        update public.group_invites
        set status = 'expired'
        where id = v_invite.id;
        return;
    end if;

    if v_invite.status = 'pending' then
        update public.group_invites
        set status = 'revoked'
        where id = v_invite.id;
    end if;
end;
$$;
