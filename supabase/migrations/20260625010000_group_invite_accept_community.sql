-- Group invite acceptance and community feed helpers.
-- These RPCs keep invite validation server-side while the Flutter UI remains
-- behind the Repository/DataSource boundary.

create or replace function public.get_group_invite_preview(p_token text)
returns table (
    group_id uuid,
    group_name text,
    group_avatar_path text,
    group_description text,
    group_type text,
    invited_by uuid,
    inviter_full_name text,
    invite_status text,
    member_count integer,
    expires_at timestamptz
)
language plpgsql
stable
security definer
set search_path = public
as $$
declare
    v_invite public.group_invites%rowtype;
    v_group public.groups%rowtype;
    v_existing_status public.group_member_status;
begin
    if auth.uid() is null then
        raise exception 'AUTH_REQUIRED';
    end if;

    select *
    into v_invite
    from public.group_invites
    where token = btrim(p_token)
    limit 1;

    if v_invite.id is null then
        return query select
            null::uuid,
            null::text,
            null::text,
            null::text,
            null::text,
            null::uuid,
            null::text,
            'invalid'::text,
            0::integer,
            null::timestamptz;
        return;
    end if;

    if v_invite.invited_user_id is not null
       and v_invite.invited_user_id <> auth.uid() then
        return query select
            null::uuid,
            null::text,
            null::text,
            null::text,
            null::text,
            null::uuid,
            null::text,
            'invalid'::text,
            0::integer,
            null::timestamptz;
        return;
    end if;

    select *
    into v_group
    from public.groups
    where id = v_invite.group_id;

    select status
    into v_existing_status
    from public.group_members
    where group_id = v_invite.group_id
      and user_id = auth.uid()
    limit 1;

    return query
    select
        v_group.id,
        v_group.name,
        v_group.avatar_path,
        v_group.description,
        v_group.type,
        v_invite.invited_by,
        inviter.full_name,
        case
            when v_group.id is null then 'invalid'
            when v_group.status <> 'active'::public.group_status then 'group_archived'
            when v_existing_status = 'active'::public.group_member_status then 'already_member'
            when v_invite.status = 'pending'
                 and v_invite.expires_at <= timezone('utc', now()) then 'expired'
            else v_invite.status
        end,
        (
            select count(*)::integer
            from public.group_members gm
            where gm.group_id = v_invite.group_id
              and gm.status = 'active'::public.group_member_status
        ),
        v_invite.expires_at
    from public.profiles inviter
    where inviter.id = v_invite.invited_by;
end;
$$;

create or replace function public.accept_group_invite(p_token text)
returns table (
    group_id uuid,
    result_status text
)
language plpgsql
security definer
set search_path = public
as $$
declare
    v_invite public.group_invites%rowtype;
    v_group_status public.group_status;
    v_existing_member public.group_members%rowtype;
    v_now timestamptz := timezone('utc', now());
begin
    if auth.uid() is null then
        raise exception 'AUTH_REQUIRED';
    end if;

    select *
    into v_invite
    from public.group_invites
    where token = btrim(p_token)
    for update;

    if v_invite.id is null then
        raise exception 'GROUP_INVITE_INVALID';
    end if;

    if v_invite.invited_user_id is not null
       and v_invite.invited_user_id <> auth.uid() then
        raise exception 'GROUP_INVITE_FORBIDDEN';
    end if;

    select status
    into v_group_status
    from public.groups
    where id = v_invite.group_id;

    if v_group_status is null then
        raise exception 'GROUP_INVITE_INVALID';
    end if;

    if v_group_status <> 'active'::public.group_status then
        raise exception 'GROUP_INVITE_ARCHIVED';
    end if;

    select *
    into v_existing_member
    from public.group_members
    where group_id = v_invite.group_id
      and user_id = auth.uid()
    for update;

    if v_existing_member.status = 'active'::public.group_member_status then
        return query select v_invite.group_id, 'already_member'::text;
        return;
    end if;

    if v_invite.status <> 'pending' then
        raise exception 'GROUP_INVITE_NOT_PENDING';
    end if;

    if v_invite.expires_at <= v_now then
        update public.group_invites
        set status = 'expired',
            updated_at = v_now
        where id = v_invite.id;
        raise exception 'GROUP_INVITE_EXPIRED';
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
        v_now,
        null
    )
    on conflict (group_id, user_id) do update
    set role = case
            when public.group_members.role = 'owner'::public.group_role
                then public.group_members.role
            else 'member'::public.group_role
        end,
        status = 'active'::public.group_member_status,
        joined_at = coalesce(public.group_members.joined_at, v_now),
        left_at = null;

    update public.group_invites
    set invited_user_id = coalesce(invited_user_id, auth.uid()),
        status = 'accepted',
        updated_at = v_now
    where id = v_invite.id;

    insert into public.group_activities (
        group_id,
        actor_user_id,
        type,
        metadata
    )
    values (
        v_invite.group_id,
        auth.uid(),
        'member_joined',
        jsonb_build_object('source', 'invite_link')
    );

    insert into public.group_notifications (group_id, user_id, type)
    select v_invite.group_id, gm.user_id, 'member_joined'
    from public.group_members gm
    where gm.group_id = v_invite.group_id
      and gm.status = 'active'::public.group_member_status
      and gm.user_id <> auth.uid();

    return query select v_invite.group_id, 'accepted'::text;
end;
$$;

create or replace function public.decline_group_invite(p_token text)
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

    select *
    into v_invite
    from public.group_invites
    where token = btrim(p_token)
    for update;

    if v_invite.id is null then
        raise exception 'GROUP_INVITE_INVALID';
    end if;

    if v_invite.invited_user_id is not null
       and v_invite.invited_user_id <> auth.uid() then
        raise exception 'GROUP_INVITE_FORBIDDEN';
    end if;

    update public.group_invites
    set invited_user_id = coalesce(invited_user_id, auth.uid()),
        status = 'declined',
        updated_at = timezone('utc', now())
    where id = v_invite.id
      and status = 'pending';
end;
$$;

create or replace function public.list_group_notifications()
returns table (
    id uuid,
    group_id uuid,
    group_name text,
    group_transaction_id uuid,
    type text,
    is_read boolean,
    created_at timestamptz
)
language sql
stable
security definer
set search_path = public
as $$
    select
        gn.id,
        gn.group_id,
        g.name as group_name,
        gn.group_transaction_id,
        gn.type,
        gn.is_read,
        gn.created_at
    from public.group_notifications gn
    join public.groups g on g.id = gn.group_id
    where gn.user_id = auth.uid()
    order by gn.created_at desc
    limit 100;
$$;

create or replace function public.mark_group_notification_read(
    p_notification_id uuid
)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
    if auth.uid() is null then
        raise exception 'AUTH_REQUIRED';
    end if;

    update public.group_notifications
    set is_read = true
    where id = p_notification_id
      and user_id = auth.uid();
end;
$$;

create or replace function public.list_group_activities(p_group_id uuid)
returns table (
    id uuid,
    group_id uuid,
    actor_user_id uuid,
    actor_name text,
    type text,
    metadata jsonb,
    created_at timestamptz
)
language plpgsql
stable
security definer
set search_path = public
as $$
begin
    if not public.is_group_member(p_group_id) then
        raise exception 'GROUP_MEMBER_REQUIRED';
    end if;

    return query
    select
        ga.id,
        ga.group_id,
        ga.actor_user_id,
        p.full_name,
        ga.type,
        ga.metadata,
        ga.created_at
    from public.group_activities ga
    left join public.profiles p on p.id = ga.actor_user_id
    where ga.group_id = p_group_id
    order by ga.created_at desc
    limit 50;
end;
$$;

revoke all on function public.get_group_invite_preview(text) from public;
revoke all on function public.accept_group_invite(text) from public;
revoke all on function public.decline_group_invite(text) from public;
revoke all on function public.list_group_notifications() from public;
revoke all on function public.mark_group_notification_read(uuid) from public;
revoke all on function public.list_group_activities(uuid) from public;

grant execute on function public.get_group_invite_preview(text)
    to authenticated;
grant execute on function public.accept_group_invite(text) to authenticated;
grant execute on function public.decline_group_invite(text) to authenticated;
grant execute on function public.list_group_notifications() to authenticated;
grant execute on function public.mark_group_notification_read(uuid)
    to authenticated;
grant execute on function public.list_group_activities(uuid) to authenticated;
