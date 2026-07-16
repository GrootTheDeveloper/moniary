-- Keep Group Home bounded: return its header aggregates without downloading
-- the complete transaction history.
create or replace function public.get_group_summary_v1(p_group_id uuid)
returns table (
    id uuid,
    name text,
    avatar_path text,
    description text,
    type text,
    base_currency text,
    created_by uuid,
    status public.group_status,
    created_at timestamptz,
    updated_at timestamptz,
    member_count bigint,
    transaction_count bigint,
    total_spent bigint,
    current_user_balance bigint,
    has_unresolved_settlements boolean
)
language plpgsql
stable
security definer
set search_path = public, pg_temp
as $$
begin
    if auth.uid() is null
       or not public.is_group_member(p_group_id, auth.uid()) then
        raise exception 'GROUP_MEMBER_REQUIRED' using errcode = '42501';
    end if;

    return query
    select
        g.id,
        g.name,
        g.avatar_path,
        g.description,
        g.type,
        g.base_currency,
        g.created_by,
        g.status,
        g.created_at,
        g.updated_at,
        (
            select count(*)::bigint
            from public.group_members gm
            where gm.group_id = g.id and gm.status = 'active'
        ),
        (
            select count(*)::bigint
            from public.group_transactions gt
            where gt.group_id = g.id and gt.split_status = 'posted'
        ),
        (
            select coalesce(sum(gt.total_amount), 0)::bigint
            from public.group_transactions gt
            where gt.group_id = g.id and gt.split_status = 'posted'
        ),
        (
            select coalesce(sum(gbs.balance), 0)::bigint
            from public.group_balance_summary gbs
            where gbs.group_id = g.id and gbs.user_id = auth.uid()
        ),
        exists (
            select 1
            from public.group_settlement_suggestions gss
            where gss.group_id = g.id
              and gss.status in ('pending', 'payer_marked_paid', 'disputed')
        )
    from public.groups g
    where g.id = p_group_id and g.status = 'active';
end;
$$;

revoke all on function public.get_group_summary_v1(uuid) from public;
grant execute on function public.get_group_summary_v1(uuid) to authenticated;
