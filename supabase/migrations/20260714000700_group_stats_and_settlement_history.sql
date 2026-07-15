-- Read-only finance summaries for the group management experience.

create or replace function public.get_group_monthly_stats(
    p_group_id uuid,
    p_month date default current_date
)
returns jsonb
language plpgsql
stable
security definer
set search_path = public
as $$
declare
    v_start date := date_trunc('month', coalesce(p_month, current_date)::timestamp)::date;
    v_end date := (date_trunc('month', coalesce(p_month, current_date)::timestamp)
        + interval '1 month')::date;
    v_total bigint;
    v_count integer;
    v_top_category text;
    v_top_amount bigint;
begin
    if not public.is_group_member(p_group_id) then
        raise exception 'GROUP_MEMBER_REQUIRED';
    end if;

    select coalesce(sum(gt.total_amount), 0), count(*)::integer
    into v_total, v_count
    from public.group_transactions gt
    where gt.group_id = p_group_id
      and gt.split_status = 'posted'
      and gt.transaction_date >= v_start
      and gt.transaction_date < v_end;

    select coalesce(gt.category_name_snapshot, 'Uncategorized'),
           sum(gt.total_amount)
    into v_top_category, v_top_amount
    from public.group_transactions gt
    where gt.group_id = p_group_id
      and gt.split_status = 'posted'
      and gt.transaction_date >= v_start
      and gt.transaction_date < v_end
    group by coalesce(gt.category_name_snapshot, 'Uncategorized')
    order by sum(gt.total_amount) desc
    limit 1;

    return jsonb_build_object(
        'group_id', p_group_id,
        'month', v_start,
        'total_spent', v_total,
        'transaction_count', v_count,
        'top_category_name', v_top_category,
        'top_category_amount', coalesce(v_top_amount, 0),
        'category_breakdown', coalesce((
            select jsonb_agg(
                jsonb_build_object(
                    'category_name', category_name,
                    'total_amount', total_amount,
                    'transaction_count', transaction_count
                ) order by total_amount desc
            )
            from (
                select coalesce(gt.category_name_snapshot, 'Uncategorized')
                    as category_name,
                    sum(gt.total_amount)::bigint as total_amount,
                    count(*)::integer as transaction_count
                from public.group_transactions gt
                where gt.group_id = p_group_id
                  and gt.split_status = 'posted'
                  and gt.transaction_date >= v_start
                  and gt.transaction_date < v_end
                group by coalesce(gt.category_name_snapshot, 'Uncategorized')
            ) category_rows
        ), '[]'::jsonb),
        'member_breakdown', coalesce((
            select jsonb_agg(
                jsonb_build_object(
                    'user_id', member_rows.user_id,
                    'display_name', member_rows.display_name,
                    'share_amount', member_rows.share_amount,
                    'paid_amount', member_rows.paid_amount,
                    'balance', member_rows.share_amount - member_rows.paid_amount,
                    'transaction_count', member_rows.transaction_count
                ) order by member_rows.share_amount desc
            )
            from (
                select
                    gm.user_id,
                    coalesce(nullif(btrim(p.full_name), ''), p.username)
                        as display_name,
                    coalesce((
                        select sum(gts.share_amount)::bigint
                        from public.group_transaction_shares gts
                        join public.group_transactions gt
                          on gt.id = gts.group_transaction_id
                        where gts.user_id = gm.user_id
                          and gt.group_id = p_group_id
                          and gt.split_status = 'posted'
                          and gt.transaction_date >= v_start
                          and gt.transaction_date < v_end
                    ), 0) as share_amount,
                    coalesce((
                        select sum(gtp.paid_amount)::bigint
                        from public.group_transaction_payers gtp
                        join public.group_transactions gt
                          on gt.id = gtp.group_transaction_id
                        where gtp.user_id = gm.user_id
                          and gt.group_id = p_group_id
                          and gt.split_status = 'posted'
                          and gt.transaction_date >= v_start
                          and gt.transaction_date < v_end
                    ), 0) as paid_amount,
                    coalesce((
                        select count(distinct gt.id)::integer
                        from public.group_transaction_shares gts
                        join public.group_transactions gt
                          on gt.id = gts.group_transaction_id
                        where gts.user_id = gm.user_id
                          and gt.group_id = p_group_id
                          and gt.split_status = 'posted'
                          and gt.transaction_date >= v_start
                          and gt.transaction_date < v_end
                    ), 0) as transaction_count
                from public.group_members gm
                join public.profiles p on p.id = gm.user_id
                where gm.group_id = p_group_id
                  and gm.status = 'active'
            ) member_rows
        ), '[]'::jsonb)
    );
end;
$$;

create or replace function public.list_group_settlement_history(p_group_id uuid)
returns table (
    id uuid,
    from_name text,
    to_name text,
    amount bigint,
    status text,
    updated_at timestamptz
)
language sql
stable
security definer
set search_path = public
as $$
    select
        gs.id,
        coalesce(nullif(btrim(from_profile.full_name), ''), from_profile.username),
        coalesce(nullif(btrim(to_profile.full_name), ''), to_profile.username),
        gs.amount,
        gs.status::text,
        gs.updated_at
    from public.group_settlement_suggestions gs
    join public.profiles from_profile on from_profile.id = gs.from_user_id
    join public.profiles to_profile on to_profile.id = gs.to_user_id
    where gs.group_id = p_group_id
      and public.is_group_member(p_group_id)
      and gs.status <> 'pending'
    order by gs.updated_at desc;
$$;

revoke all on function public.get_group_monthly_stats(uuid, date) from public;
revoke all on function public.list_group_settlement_history(uuid) from public;
grant execute on function public.get_group_monthly_stats(uuid, date)
    to authenticated;
grant execute on function public.list_group_settlement_history(uuid)
    to authenticated;
