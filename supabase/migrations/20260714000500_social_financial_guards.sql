create or replace function public.enforce_friend_request_rate_limit()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
    if (
        select count(*)
        from public.friend_requests
        where from_user_id = new.from_user_id
          and created_at >= timezone('utc', now()) - interval '1 hour'
    ) >= 30 then
        raise exception 'FRIEND_RATE_LIMITED';
    end if;
    return new;
end;
$$;

drop trigger if exists enforce_friend_request_rate_limit
on public.friend_requests;
create trigger enforce_friend_request_rate_limit
before insert on public.friend_requests
for each row execute function public.enforce_friend_request_rate_limit();

create or replace function public.dispute_group_settlement(
    p_settlement_id uuid,
    p_reason text
)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
    v_settlement public.group_settlement_suggestions%rowtype;
begin
    if btrim(coalesce(p_reason, '')) = '' then
        raise exception 'GROUP_DISPUTE_REASON_REQUIRED';
    end if;
    select * into v_settlement
    from public.group_settlement_suggestions
    where id = p_settlement_id
    for update;
    if v_settlement.id is null then raise exception 'NOT_FOUND'; end if;
    if auth.uid() not in (
        v_settlement.from_user_id,
        v_settlement.to_user_id
    ) then
        raise exception 'GROUP_SETTLEMENT_FORBIDDEN';
    end if;
    if v_settlement.status in ('completed', 'disputed') then
        raise exception 'GROUP_SETTLEMENT_FORBIDDEN';
    end if;
    update public.group_settlement_suggestions
    set status = 'disputed', updated_at = timezone('utc', now())
    where id = p_settlement_id;
    insert into public.group_activities (
        group_id, actor_user_id, type, metadata
    ) values (
        v_settlement.group_id,
        auth.uid(),
        'settlement_disputed',
        jsonb_build_object(
            'settlement_id', p_settlement_id,
            'reason', btrim(p_reason)
        )
    );
end;
$$;

create or replace function public.remove_group_member(
    p_group_id uuid,
    p_user_id uuid
)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
    v_actor_role public.group_role;
    v_target_member public.group_members%rowtype;
    v_balance bigint;
    v_unresolved boolean;
begin
    if p_user_id = auth.uid() then
        raise exception 'GROUP_MEMBER_REMOVE_FORBIDDEN';
    end if;
    select role into v_actor_role
    from public.group_members
    where group_id = p_group_id
      and user_id = auth.uid()
      and status = 'active'
    for update;
    select * into v_target_member
    from public.group_members
    where group_id = p_group_id
      and user_id = p_user_id
      and status in ('active', 'invited')
    for update;
    if v_actor_role is null or v_target_member.id is null then
        raise exception 'NOT_FOUND';
    end if;
    if v_target_member.role = 'owner'
      or v_actor_role not in ('owner', 'admin')
      or (v_actor_role = 'admin' and v_target_member.role <> 'member') then
        raise exception 'GROUP_MEMBER_REMOVE_FORBIDDEN';
    end if;
    select coalesce(balance, 0) into v_balance
    from public.group_balance_summary
    where group_id = p_group_id and user_id = p_user_id;
    select exists (
        select 1
        from public.group_settlement_suggestions
        where group_id = p_group_id
          and status in ('pending', 'payer_marked_paid', 'disputed')
          and (from_user_id = p_user_id or to_user_id = p_user_id)
    ) into v_unresolved;
    if coalesce(v_balance, 0) <> 0 or v_unresolved then
        raise exception 'GROUP_MEMBER_REMOVE_UNRESOLVED';
    end if;
    update public.group_members
    set status = 'removed', left_at = timezone('utc', now())
    where id = v_target_member.id;
    update public.group_invites
    set status = 'expired'
    where group_id = p_group_id
      and invited_user_id = p_user_id
      and status = 'pending';
    insert into public.group_activities (
        group_id, actor_user_id, type, metadata
    ) values (
        p_group_id,
        auth.uid(),
        'member_removed',
        jsonb_build_object('removed_user_id', p_user_id)
    );
end;
$$;

revoke all on function public.dispute_group_settlement(uuid, text)
from public;
revoke all on function public.remove_group_member(uuid, uuid)
from public;
grant execute on function public.dispute_group_settlement(uuid, text)
to authenticated;
grant execute on function public.remove_group_member(uuid, uuid)
to authenticated;
