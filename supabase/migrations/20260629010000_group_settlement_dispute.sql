create or replace function public.dispute_settlement(
    p_settlement_id uuid
)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
    update public.group_settlement_suggestions
    set status = 'disputed',
        updated_at = timezone('utc', now())
    where id = p_settlement_id
      and to_user_id = auth.uid()
      and status = 'payer_marked_paid';

    if not found then
        raise exception 'GROUP_SETTLEMENT_FORBIDDEN';
    end if;
end;
$$;

create or replace function public.reset_disputed_settlement(
    p_settlement_id uuid
)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
    v_group_id uuid;
    v_role public.group_role;
begin
    select gs.group_id
    into v_group_id
    from public.group_settlement_suggestions gs
    where gs.id = p_settlement_id;

    select gm.role
    into v_role
    from public.group_members gm
    where gm.group_id = v_group_id
      and gm.user_id = auth.uid()
      and gm.status = 'active';

    if v_role not in ('owner'::public.group_role, 'admin'::public.group_role) then
        raise exception 'GROUP_ADMIN_REQUIRED';
    end if;

    update public.group_settlement_suggestions
    set status = 'pending',
        updated_at = timezone('utc', now())
    where id = p_settlement_id
      and status = 'disputed';

    if not found then
        raise exception 'GROUP_SETTLEMENT_FORBIDDEN';
    end if;
end;
$$;

revoke all on function public.dispute_settlement(uuid) from public;
revoke all on function public.reset_disputed_settlement(uuid) from public;

grant execute on function public.dispute_settlement(uuid) to authenticated;
grant execute on function public.reset_disputed_settlement(uuid)
to authenticated;
