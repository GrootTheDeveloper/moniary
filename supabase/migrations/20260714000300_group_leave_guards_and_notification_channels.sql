-- Finance-first group lifecycle guards and separate Group/Community channels.

alter table public.group_notifications
    add column if not exists category text not null default 'group';

alter table public.group_notifications
    drop constraint if exists group_notifications_category_check;
alter table public.group_notifications
    add constraint group_notifications_category_check
    check (category in ('group', 'community'));

alter table public.group_notification_preferences
    add column if not exists community_comments boolean not null default true;
alter table public.group_notification_preferences
    add column if not exists community_reactions boolean not null default true;

update public.group_notifications
set category = 'community'
where type ilike '%comment%'
   or type ilike '%mention%'
   or type ilike '%reaction%'
   or type ilike '%reply%';

create or replace function public.set_group_notification_category()
returns trigger
language plpgsql
as $$
begin
    new.category := case
        when new.type ilike '%comment%'
          or new.type ilike '%mention%'
          or new.type ilike '%reaction%'
          or new.type ilike '%reply%'
        then 'community'
        else coalesce(new.category, 'group')
    end;
    return new;
end;
$$;

drop trigger if exists set_group_notification_category
    on public.group_notifications;
create trigger set_group_notification_category
before insert on public.group_notifications
for each row execute function public.set_group_notification_category();

create or replace function public.notify_group_community_activity()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
    v_transaction_id uuid;
    v_recipient_id uuid;
begin
    if new.type not in ('transaction_reacted', 'comment_added') then
        return new;
    end if;

    v_transaction_id := nullif(new.metadata ->> 'transactionId', '')::uuid;
    if v_transaction_id is null then
        return new;
    end if;

    select created_by
    into v_recipient_id
    from public.group_transactions
    where id = v_transaction_id;

    if v_recipient_id is not null and v_recipient_id <> new.actor_user_id then
        insert into public.group_notifications (
            group_id, user_id, group_transaction_id, type
        ) values (
            new.group_id,
            v_recipient_id,
            v_transaction_id,
            new.type
        );
    end if;
    return new;
end;
$$;

drop trigger if exists notify_group_community_activity
    on public.group_activities;
create trigger notify_group_community_activity
after insert on public.group_activities
for each row execute function public.notify_group_community_activity();

drop function if exists public.list_group_notifications();
create function public.list_group_notifications(p_category text default null)
returns table (
    id uuid,
    group_id uuid,
    group_name text,
    group_transaction_id uuid,
    invite_token text,
    category text,
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
        gn.category,
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
      and (p_category is null or gn.category = p_category)
    order by gn.created_at desc
    limit 100;
$$;

revoke all on function public.list_group_notifications(text) from public;
grant execute on function public.list_group_notifications(text) to authenticated;

create or replace function public.group_notification_enabled(
    p_group_id uuid,
    p_user_id uuid,
    p_type text
)
returns boolean
language plpgsql
stable
security definer
set search_path = public
as $$
declare
    v_pref public.group_notification_preferences%rowtype;
    v_hour integer := extract(hour from timezone('utc', now()));
    v_quiet boolean := false;
begin
    select * into v_pref
    from public.group_notification_preferences
    where group_id = p_group_id and user_id = p_user_id;

    if not found then return true; end if;
    if v_pref.mute_all then return false; end if;
    if v_pref.quiet_hours_start is not null
       and v_pref.quiet_hours_end is not null then
        if v_pref.quiet_hours_start <= v_pref.quiet_hours_end then
            v_quiet := v_hour >= v_pref.quiet_hours_start
                and v_hour < v_pref.quiet_hours_end;
        else
            v_quiet := v_hour >= v_pref.quiet_hours_start
                or v_hour < v_pref.quiet_hours_end;
        end if;
        if v_quiet then return false; end if;
    end if;
    if p_type ilike '%reaction%' then return v_pref.community_reactions; end if;
    if p_type ilike '%comment%' or p_type ilike '%reply%' then
        return v_pref.community_comments;
    end if;
    if p_type ilike '%invite%' then return v_pref.invite_notifications; end if;
    if p_type ilike '%mention%' then return v_pref.mention_notifications; end if;
    if p_type ilike '%settlement%' or p_type ilike '%debt%' then
        return v_pref.debt_notifications;
    end if;
    if p_type ilike '%transaction%' or p_type ilike '%amount%' then
        return v_pref.transaction_notifications;
    end if;
    return true;
end;
$$;

-- Admins may manage roles, but direct table writes cannot mark a member as
-- left/removed. Lifecycle status changes must go through audited RPCs.
drop policy if exists "group_members_update_admin" on public.group_members;
create policy "group_members_update_admin"
on public.group_members for update to authenticated
using (
    public.has_group_role(
        group_id,
        array['owner', 'admin']::public.group_role[]
    )
)
with check (
    status = 'active'
    and public.has_group_role(
        group_id,
        array['owner', 'admin']::public.group_role[]
    )
);

create or replace function public.leave_expense_group(p_group_id uuid)
returns text
language plpgsql
security definer
set search_path = public
as $$
declare
    v_role public.group_role;
    v_balance bigint;
    v_unresolved boolean;
    v_disputed boolean;
    v_pending_transaction_count integer;
    v_other_owner_count integer;
begin
    select role
    into v_role
    from public.group_members
    where group_id = p_group_id
      and user_id = auth.uid()
      and status = 'active'
    for update;

    if v_role is null then
        raise exception 'GROUP_MEMBER_REQUIRED';
    end if;

    select coalesce(balance, 0)
    into v_balance
    from public.group_balance_summary
    where group_id = p_group_id
      and user_id = auth.uid();

    select exists (
        select 1
        from public.group_settlement_suggestions
        where group_id = p_group_id
          and status in ('pending', 'payer_marked_paid')
          and (from_user_id = auth.uid() or to_user_id = auth.uid())
    )
    into v_unresolved;

    select exists (
        select 1
        from public.group_settlement_suggestions
        where group_id = p_group_id
          and status = 'disputed'
          and (from_user_id = auth.uid() or to_user_id = auth.uid())
    )
    into v_disputed;

    select count(distinct gt.id)::integer
    into v_pending_transaction_count
    from public.group_transactions gt
    left join public.group_transaction_shares gts
      on gts.group_transaction_id = gt.id
    where gt.group_id = p_group_id
      and gt.split_status in (
          'draft', 'pending_member_amount_input', 'amount_mismatch'
      )
      and (gt.created_by = auth.uid() or gts.user_id = auth.uid());

    if coalesce(v_pending_transaction_count, 0) > 0 then
        insert into public.group_activities (
            group_id, actor_user_id, type, metadata
        ) values (
            p_group_id,
            auth.uid(),
            'leave_blocked_unresolved',
            jsonb_build_object(
                'reason', 'incomplete_transaction',
                'pending_transaction_count', v_pending_transaction_count
            )
        );
    elsif v_disputed then
        insert into public.group_activities (
            group_id, actor_user_id, type, metadata
        ) values (
            p_group_id,
            auth.uid(),
            'leave_blocked_unresolved',
            jsonb_build_object('reason', 'disputed_settlement')
        );
    elsif coalesce(v_balance, 0) <> 0 or v_unresolved then
        insert into public.group_activities (
            group_id, actor_user_id, type, metadata
        ) values (
            p_group_id,
            auth.uid(),
            'leave_blocked_unresolved',
            jsonb_build_object(
                'reason', 'unresolved_balance',
                'balance', coalesce(v_balance, 0)
            )
        );
    end if;

    if coalesce(v_pending_transaction_count, 0) > 0
       or v_disputed
       or coalesce(v_balance, 0) <> 0
       or v_unresolved then
        insert into public.group_notifications (group_id, user_id, type)
        select p_group_id, gm.user_id, 'member_leave_blocked_warning'
        from public.group_members gm
        where gm.group_id = p_group_id
          and gm.status = 'active'
          and gm.user_id <> auth.uid();

        if coalesce(v_pending_transaction_count, 0) > 0 then
            return 'unresolved_transaction';
        end if;
        if v_disputed then
            return 'disputed_settlement';
        end if;
        return 'unresolved';
    end if;

    if v_role = 'owner' then
        select count(*)
        into v_other_owner_count
        from public.group_members
        where group_id = p_group_id
          and user_id <> auth.uid()
          and status = 'active'
          and role = 'owner';

        if v_other_owner_count = 0 then
            return 'owner_transfer_required';
        end if;
    end if;

    update public.group_members
    set status = 'left', left_at = timezone('utc', now())
    where group_id = p_group_id
      and user_id = auth.uid();

    insert into public.group_activities (
        group_id, actor_user_id, type
    ) values (p_group_id, auth.uid(), 'member_left');

    insert into public.group_notifications (group_id, user_id, type)
    select p_group_id, gm.user_id, 'member_left'
    from public.group_members gm
    where gm.group_id = p_group_id
      and gm.status = 'active'
      and gm.user_id <> auth.uid();

    return 'left';
end;
$$;

revoke all on function public.leave_expense_group(uuid) from public;
grant execute on function public.leave_expense_group(uuid) to authenticated;
