-- Once a group has started or completed a settlement, posted transactions are
-- treated as financial history. They must be adjusted with a new transaction
-- instead of being edited or deleted in place.

alter table public.group_settlement_suggestions
    add column if not exists dispute_reason text,
    add column if not exists disputed_by_user_id uuid
        references public.profiles(id) on delete set null,
    add column if not exists disputed_at timestamptz;

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
    v_reason text := btrim(coalesce(p_reason, ''));
begin
    if v_reason = '' then
        raise exception 'GROUP_DISPUTE_REASON_REQUIRED';
    end if;
    if length(v_reason) > 300 then
        raise exception 'GROUP_DISPUTE_REASON_TOO_LONG';
    end if;

    select * into v_settlement
    from public.group_settlement_suggestions
    where id = p_settlement_id
    for update;

    if v_settlement.id is null then
        raise exception 'NOT_FOUND';
    end if;
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
    set status = 'disputed',
        dispute_reason = v_reason,
        disputed_by_user_id = auth.uid(),
        disputed_at = timezone('utc', now()),
        updated_at = timezone('utc', now())
    where id = p_settlement_id;

    insert into public.group_activities (
        group_id, actor_user_id, type, metadata
    ) values (
        v_settlement.group_id,
        auth.uid(),
        'settlement_disputed',
        jsonb_build_object(
            'settlement_id', p_settlement_id,
            'reason', v_reason
        )
    );
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
        dispute_reason = null,
        disputed_by_user_id = null,
        disputed_at = null,
        updated_at = timezone('utc', now())
    where id = p_settlement_id
      and status = 'disputed';

    if not found then
        raise exception 'GROUP_SETTLEMENT_FORBIDDEN';
    end if;

    perform public.refresh_group_settlements(v_group_id);

    insert into public.group_activities (
        group_id, actor_user_id, type, metadata
    ) values (
        v_group_id,
        auth.uid(),
        'settlement_dispute_reset',
        jsonb_build_object('settlement_id', p_settlement_id)
    );
end;
$$;

create or replace function public.prevent_locked_group_transaction_mutation()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
    if OLD.split_status = 'posted'
       and exists (
           select 1
           from public.group_settlement_suggestions gs
           where gs.group_id = OLD.group_id
             and gs.status in ('payer_marked_paid', 'completed', 'disputed')
       ) then
        raise exception 'GROUP_TRANSACTION_SETTLEMENT_LOCKED';
    end if;

    if TG_OP = 'DELETE' then
        return OLD;
    end if;
    return NEW;
end;
$$;

drop trigger if exists prevent_locked_group_transaction_mutation
on public.group_transactions;
create trigger prevent_locked_group_transaction_mutation
before update or delete on public.group_transactions
for each row execute function public.prevent_locked_group_transaction_mutation();

-- Keep the final privileges explicit in this migration. The functions are
-- security-definer entry points and must never be callable by anon/public.
revoke all on function public.dispute_group_settlement(uuid, text) from public;
revoke all on function public.reset_disputed_settlement(uuid) from public;
grant execute on function public.dispute_group_settlement(uuid, text)
    to authenticated;
grant execute on function public.reset_disputed_settlement(uuid)
    to authenticated;
