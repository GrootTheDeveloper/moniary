-- Keep disputed settlements visible and reserved while the group reviews them.
-- Reopening a dispute clears the payment timestamps before returning to pending.

create or replace function public.refresh_group_settlements(p_group_id uuid)
returns void
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
    v_debtor_id uuid;
    v_creditor_id uuid;
    v_debt bigint;
    v_credit bigint;
    v_amount bigint;
begin
    if not public.is_group_member(p_group_id) then
        raise exception 'GROUP_MEMBER_REQUIRED';
    end if;

    delete from public.group_settlement_suggestions
    where group_id = p_group_id
      and status = 'pending';

    create temporary table if not exists group_work_balances (
        user_id uuid primary key,
        balance bigint not null
    ) on commit delete rows;

    truncate table pg_temp.group_work_balances;

    insert into pg_temp.group_work_balances (user_id, balance)
    select user_id, balance
    from public.group_balance_summary
    where group_id = p_group_id;

    with reserved as (
        select
            user_id,
            sum(amount)::bigint as amount
        from (
            select from_user_id as user_id, -amount as amount
            from public.group_settlement_suggestions
            where group_id = p_group_id
              and status in ('payer_marked_paid', 'disputed')
            union all
            select to_user_id as user_id, amount
            from public.group_settlement_suggestions
            where group_id = p_group_id
              and status in ('payer_marked_paid', 'disputed')
        ) reserved_ledger
        group by user_id
    )
    update pg_temp.group_work_balances work
    set balance = work.balance + reserved.amount
    from reserved
    where reserved.user_id = work.user_id;

    loop
        select user_id, balance
        into v_debtor_id, v_debt
        from pg_temp.group_work_balances
        where balance > 0
        order by balance desc, user_id
        limit 1;

        select user_id, balance
        into v_creditor_id, v_credit
        from pg_temp.group_work_balances
        where balance < 0
        order by balance asc, user_id
        limit 1;

        exit when v_debtor_id is null or v_creditor_id is null;

        v_amount := least(v_debt, abs(v_credit));

        insert into public.group_settlement_suggestions (
            group_id,
            from_user_id,
            to_user_id,
            amount
        )
        values (p_group_id, v_debtor_id, v_creditor_id, v_amount);

        update pg_temp.group_work_balances
        set balance = balance - v_amount
        where user_id = v_debtor_id;

        update pg_temp.group_work_balances
        set balance = balance + v_amount
        where user_id = v_creditor_id;

        v_debtor_id := null;
        v_creditor_id := null;
    end loop;
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

    if v_group_id is null then
        raise exception 'NOT_FOUND';
    end if;

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
        payer_marked_paid_at = null,
        receiver_confirmed_at = null,
        updated_at = timezone('utc', now())
    where id = p_settlement_id
      and status = 'disputed';

    if not found then
        raise exception 'GROUP_SETTLEMENT_FORBIDDEN';
    end if;

    perform public.refresh_group_settlements(v_group_id);
end;
$$;

revoke all on function public.reset_disputed_settlement(uuid) from public;
grant execute on function public.reset_disputed_settlement(uuid) to authenticated;
