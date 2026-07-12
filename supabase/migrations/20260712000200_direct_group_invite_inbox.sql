-- Direct invitations are private to their recipient. These RPCs bridge the
-- active-member RLS boundary until the recipient accepts the invitation.

create or replace function public.get_my_group_invites()
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
begin
    if auth.uid() is null then
        raise exception 'AUTH_REQUIRED';
    end if;

    with expired_invites as (
        update public.group_invites
        set status = 'expired'
        where invited_user_id = auth.uid()
          and status = 'pending'
          and expires_at <= timezone('utc', now())
        returning group_id
    )
    update public.group_members as gm
    set status = 'declined'
    where gm.user_id = auth.uid()
      and gm.status = 'invited'
      and gm.group_id in (select group_id from expired_invites);

    with revoked_invites as (
        update public.group_invites as gi
        set status = 'revoked'
        from public.groups as g
        where gi.group_id = g.id
          and gi.invited_user_id = auth.uid()
          and gi.status = 'pending'
          and g.status <> 'active'
        returning gi.group_id
    )
    update public.group_members as gm
    set status = 'declined'
    where gm.user_id = auth.uid()
      and gm.status = 'invited'
      and gm.group_id in (select group_id from revoked_invites);

    update public.group_invites as gi
    set status = 'accepted'
    from public.group_members as gm
    where gi.group_id = gm.group_id
      and gi.invited_user_id = auth.uid()
      and gi.status = 'pending'
      and gm.user_id = auth.uid()
      and gm.status = 'active';

    return coalesce((
        select jsonb_agg(
            jsonb_build_object(
                'id', gi.id,
                'group_id', g.id,
                'group_name', g.name,
                'group_avatar_path', g.avatar_path,
                'inviter_name', coalesce(nullif(btrim(p.full_name), ''), p.username),
                'status', gi.status,
                'created_at', gi.created_at,
                'expires_at', gi.expires_at
            )
            order by gi.created_at desc
        )
        from public.group_invites as gi
        join public.groups as g on g.id = gi.group_id
        join public.profiles as p on p.id = gi.invited_by
        where gi.invited_user_id = auth.uid()
    ), '[]'::jsonb);
end;
$$;

create or replace function public.accept_direct_group_invite(p_invite_id uuid)
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
    where id = p_invite_id
      and invited_user_id = auth.uid()
    for update;

    if not found then
        raise exception 'GROUP_DIRECT_INVITE_INVALID';
    end if;

    if v_invite.status = 'pending' and v_invite.expires_at <= timezone('utc', now()) then
        update public.group_invites
        set status = 'expired'
        where id = v_invite.id;
        update public.group_members
        set status = 'declined'
        where group_id = v_invite.group_id
          and user_id = auth.uid()
          and status = 'invited';
        raise exception 'GROUP_DIRECT_INVITE_EXPIRED';
    end if;

    select g.status into v_group_status
    from public.groups as g
    where g.id = v_invite.group_id;
    if not found or v_group_status <> 'active' then
        update public.group_invites
        set status = 'revoked'
        where id = v_invite.id
          and status = 'pending';
        update public.group_members
        set status = 'declined'
        where group_id = v_invite.group_id
          and user_id = auth.uid()
          and status = 'invited';
        raise exception 'GROUP_DIRECT_INVITE_REVOKED';
    end if;

    if exists (
        select 1
        from public.group_members
        where group_id = v_invite.group_id
          and user_id = auth.uid()
          and status = 'active'
    ) then
        update public.group_invites
        set status = 'accepted'
        where id = v_invite.id
          and status = 'pending';
        return jsonb_build_object(
            'status', 'already_member',
            'group_id', v_invite.group_id
        );
    end if;

    if v_invite.status = 'declined' then
        raise exception 'GROUP_DIRECT_INVITE_DECLINED';
    end if;
    if v_invite.status = 'expired' then
        raise exception 'GROUP_DIRECT_INVITE_EXPIRED';
    end if;
    if v_invite.status = 'revoked' then
        raise exception 'GROUP_DIRECT_INVITE_REVOKED';
    end if;
    if v_invite.status <> 'pending' then
        raise exception 'GROUP_DIRECT_INVITE_INVALID';
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

    update public.group_invites
    set status = 'accepted'
    where id = v_invite.id;

    update public.group_notifications
    set is_read = true
    where group_id = v_invite.group_id
      and user_id = auth.uid()
      and type = 'group_invite';

    insert into public.group_activities (group_id, actor_user_id, type, metadata)
    values (
        v_invite.group_id,
        auth.uid(),
        'member_invitation_accepted',
        jsonb_build_object('invite_id', v_invite.id)
    );

    return jsonb_build_object('status', 'accepted', 'group_id', v_invite.group_id);
end;
$$;

create or replace function public.decline_direct_group_invite(p_invite_id uuid)
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
    where id = p_invite_id
      and invited_user_id = auth.uid()
    for update;

    if not found then
        raise exception 'GROUP_DIRECT_INVITE_INVALID';
    end if;

    if v_invite.status = 'pending' and v_invite.expires_at <= timezone('utc', now()) then
        update public.group_invites
        set status = 'expired'
        where id = v_invite.id;
        update public.group_members
        set status = 'declined'
        where group_id = v_invite.group_id
          and user_id = auth.uid()
          and status = 'invited';
        raise exception 'GROUP_DIRECT_INVITE_EXPIRED';
    end if;

    if v_invite.status in ('declined', 'accepted') then
        return;
    end if;
    if v_invite.status = 'expired' then
        raise exception 'GROUP_DIRECT_INVITE_EXPIRED';
    end if;
    if v_invite.status = 'revoked' then
        raise exception 'GROUP_DIRECT_INVITE_REVOKED';
    end if;
    if v_invite.status <> 'pending' then
        raise exception 'GROUP_DIRECT_INVITE_INVALID';
    end if;

    update public.group_invites
    set status = 'declined'
    where id = v_invite.id;

    update public.group_members
    set status = 'declined'
    where group_id = v_invite.group_id
      and user_id = auth.uid()
      and status = 'invited';

    update public.group_notifications
    set is_read = true
    where group_id = v_invite.group_id
      and user_id = auth.uid()
      and type = 'group_invite';

    insert into public.group_activities (group_id, actor_user_id, type, metadata)
    values (
        v_invite.group_id,
        auth.uid(),
        'member_invitation_declined',
        jsonb_build_object('invite_id', v_invite.id)
    );
end;
$$;

revoke all on function public.get_my_group_invites() from public;
revoke all on function public.accept_direct_group_invite(uuid) from public;
revoke all on function public.decline_direct_group_invite(uuid) from public;

grant execute on function public.get_my_group_invites() to authenticated;
grant execute on function public.accept_direct_group_invite(uuid) to authenticated;
grant execute on function public.decline_direct_group_invite(uuid) to authenticated;
