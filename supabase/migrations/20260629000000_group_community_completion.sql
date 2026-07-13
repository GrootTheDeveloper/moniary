drop function if exists public.list_group_notifications();

create function public.list_group_notifications()
returns table (
    id uuid,
    group_id uuid,
    group_name text,
    group_transaction_id uuid,
    invite_token text,
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
        gi.token as invite_token,
        case gn.type
            when 'member_amount_input_required' then 'member_amount_required'
            when 'group_transaction_posted' then 'transaction_posted'
            else gn.type
        end as type,
        gn.is_read,
        gn.created_at
    from public.group_notifications gn
    join public.groups g on g.id = gn.group_id
    left join lateral (
        select token
        from public.group_invites
        where public.group_invites.group_id = gn.group_id
          and public.group_invites.invited_user_id = gn.user_id
        order by public.group_invites.created_at desc
        limit 1
    ) gi on gn.type = 'group_invite'
    where gn.user_id = auth.uid()
    order by gn.created_at desc
    limit 100;
$$;

create or replace function public.transfer_group_ownership(
    p_group_id uuid,
    p_new_owner_user_id uuid
)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
    v_current_role public.group_role;
    v_new_owner_member_id uuid;
begin
    if auth.uid() is null then
        raise exception 'AUTH_REQUIRED';
    end if;

    if p_new_owner_user_id is null
       or p_new_owner_user_id = auth.uid() then
        raise exception 'GROUP_OWNER_TRANSFER_TARGET_REQUIRED';
    end if;

    select role
    into v_current_role
    from public.group_members
    where group_id = p_group_id
      and user_id = auth.uid()
      and status = 'active'
    for update;

    if v_current_role is null then
        raise exception 'GROUP_MEMBER_REQUIRED';
    end if;

    if v_current_role <> 'owner'::public.group_role then
        raise exception 'GROUP_OWNER_REQUIRED';
    end if;

    select id
    into v_new_owner_member_id
    from public.group_members
    where group_id = p_group_id
      and user_id = p_new_owner_user_id
      and status = 'active'
    for update;

    if v_new_owner_member_id is null then
        raise exception 'GROUP_MEMBER_REQUIRED';
    end if;

    update public.group_members
    set role = 'owner'::public.group_role
    where id = v_new_owner_member_id;

    update public.group_members
    set role = 'member'::public.group_role
    where group_id = p_group_id
      and user_id = auth.uid()
      and status = 'active';

    insert into public.group_activities (
        group_id,
        actor_user_id,
        type,
        metadata
    )
    values (
        p_group_id,
        auth.uid(),
        'owner_transferred',
        jsonb_build_object('new_owner_user_id', p_new_owner_user_id)
    );

    insert into public.group_notifications (group_id, user_id, type)
    select p_group_id, gm.user_id, 'owner_transferred'
    from public.group_members gm
    where gm.group_id = p_group_id
      and gm.status = 'active'
      and gm.user_id <> auth.uid();
end;
$$;

revoke all on function public.list_group_notifications() from public;
revoke all on function public.transfer_group_ownership(uuid, uuid) from public;

grant execute on function public.list_group_notifications() to authenticated;
grant execute on function public.transfer_group_ownership(uuid, uuid)
to authenticated;
