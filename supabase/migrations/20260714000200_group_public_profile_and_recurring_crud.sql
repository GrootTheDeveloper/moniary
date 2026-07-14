-- Safe public group profiles and authorization-checked recurring transaction CRUD.

create or replace function public.get_public_group_profile(p_slug text)
returns table (
    group_id uuid,
    slug text,
    group_name text,
    avatar_path text,
    description text,
    group_type text,
    show_stats boolean,
    member_count bigint,
    transaction_count bigint,
    total_spent bigint
)
language sql
stable
security definer
set search_path = public
as $$
    select
        gp.group_id,
        gp.slug,
        g.name,
        g.avatar_path,
        g.description,
        g.type,
        gp.show_stats,
        case when gp.show_stats then (
            select count(*)
            from public.group_members gm
            where gm.group_id = g.id and gm.status = 'active'
        ) else null end,
        case when gp.show_stats then (
            select count(*)
            from public.group_transactions gt
            where gt.group_id = g.id and gt.split_status = 'posted'
        ) else null end,
        case when gp.show_stats then (
            select coalesce(sum(gt.total_amount), 0)
            from public.group_transactions gt
            where gt.group_id = g.id and gt.split_status = 'posted'
        ) else null end
    from public.group_public_profiles gp
    join public.groups g on g.id = gp.group_id
    where gp.slug = lower(trim(p_slug))
      and gp.is_enabled = true
      and g.status = 'active';
$$;

revoke all on function public.get_public_group_profile(text) from public;
grant execute on function public.get_public_group_profile(text) to anon, authenticated;

create or replace function public.create_group_recurring_transaction(
    p_group_id uuid,
    p_title text,
    p_amount bigint,
    p_frequency text,
    p_next_run_at timestamptz,
    p_notify_days_before integer default 1
)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
    v_id uuid;
begin
    if auth.uid() is null or not public.is_group_member(p_group_id, auth.uid()) then
        raise exception 'group membership required' using errcode = '42501';
    end if;
    if btrim(coalesce(p_title, '')) = '' or p_amount <= 0
       or p_frequency not in ('weekly', 'monthly')
       or p_notify_days_before not between 0 and 30 then
        raise exception 'invalid recurring transaction';
    end if;

    insert into public.group_recurring_transactions (
        group_id, created_by, title, amount, frequency,
        next_run_at, notify_days_before
    ) values (
        p_group_id, auth.uid(), btrim(p_title), p_amount, p_frequency,
        p_next_run_at, p_notify_days_before
    ) returning id into v_id;
    return v_id;
end;
$$;

create or replace function public.update_group_recurring_transaction(
    p_id uuid,
    p_title text,
    p_amount bigint,
    p_frequency text,
    p_next_run_at timestamptz,
    p_notify_days_before integer,
    p_is_active boolean
)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
    if auth.uid() is null then
        raise exception 'authentication required' using errcode = '42501';
    end if;
    if btrim(coalesce(p_title, '')) = '' or p_amount <= 0
       or p_frequency not in ('weekly', 'monthly')
       or p_notify_days_before not between 0 and 30 then
        raise exception 'invalid recurring transaction';
    end if;
    update public.group_recurring_transactions rt
    set title = btrim(p_title), amount = p_amount, frequency = p_frequency,
        next_run_at = p_next_run_at, notify_days_before = p_notify_days_before,
        is_active = p_is_active
    where rt.id = p_id
      and (
          rt.created_by = auth.uid()
          or public.has_group_role(
              rt.group_id,
              array['owner', 'admin']::public.group_role[], auth.uid()
          )
      );
    if not found then
        raise exception 'recurring transaction not found or not allowed'
            using errcode = '42501';
    end if;
end;
$$;

create or replace function public.delete_group_recurring_transaction(p_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
    if auth.uid() is null then
        raise exception 'authentication required' using errcode = '42501';
    end if;
    delete from public.group_recurring_transactions rt
    where rt.id = p_id
      and (
          rt.created_by = auth.uid()
          or public.has_group_role(
              rt.group_id,
              array['owner', 'admin']::public.group_role[], auth.uid()
          )
      );
    if not found then
        raise exception 'recurring transaction not found or not allowed'
            using errcode = '42501';
    end if;
end;
$$;

revoke all on function public.create_group_recurring_transaction(
    uuid, text, bigint, text, timestamptz, integer
) from public;
revoke all on function public.update_group_recurring_transaction(
    uuid, text, bigint, text, timestamptz, integer, boolean
) from public;
revoke all on function public.delete_group_recurring_transaction(uuid) from public;
grant execute on function public.create_group_recurring_transaction(
    uuid, text, bigint, text, timestamptz, integer
) to authenticated;
grant execute on function public.update_group_recurring_transaction(
    uuid, text, bigint, text, timestamptz, integer, boolean
) to authenticated;
grant execute on function public.delete_group_recurring_transaction(uuid)
    to authenticated;
