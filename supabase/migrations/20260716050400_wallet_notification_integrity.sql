-- Atomic wallet-default mutations and stable notification pagination.

create or replace function public.create_personal_wallet(
    p_name text,
    p_type text,
    p_initial_balance numeric,
    p_is_default boolean default false
)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
    v_user_id uuid := auth.uid();
    v_wallet_id uuid;
    v_make_default boolean;
begin
    if v_user_id is null then
        raise exception 'Not authenticated' using errcode = '42501';
    end if;
    if length(btrim(coalesce(p_name, ''))) not between 1 and 100
       or p_type not in ('cash', 'bank', 'ewallet', 'credit', 'other')
       or p_initial_balance is null
       or p_initial_balance not between -999999999999.99 and 999999999999.99 then
        raise exception 'Invalid wallet values' using errcode = '22023';
    end if;

    perform pg_advisory_xact_lock(hashtextextended(v_user_id::text, 0));
    v_make_default := coalesce(p_is_default, false) or not exists (
        select 1 from public.wallets
        where user_id = v_user_id and is_active and is_default
    );
    if v_make_default then
        update public.wallets
        set is_default = false
        where user_id = v_user_id and is_default;
    end if;

    insert into public.wallets (
        user_id,
        name,
        type,
        initial_balance,
        is_default
    ) values (
        v_user_id,
        btrim(p_name),
        p_type::public.wallet_type,
        p_initial_balance,
        v_make_default
    )
    returning id into v_wallet_id;
    return v_wallet_id;
end;
$$;

revoke all on function public.create_personal_wallet(text, text, numeric, boolean)
    from public;
grant execute on function public.create_personal_wallet(text, text, numeric, boolean)
    to authenticated;

create or replace function public.update_personal_wallet(
    p_wallet_id uuid,
    p_name text,
    p_type text,
    p_initial_balance numeric,
    p_is_default boolean,
    p_is_active boolean
)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
    v_user_id uuid := auth.uid();
    v_was_default boolean;
    v_replacement_id uuid;
begin
    if v_user_id is null then
        raise exception 'Not authenticated' using errcode = '42501';
    end if;
    if length(btrim(coalesce(p_name, ''))) not between 1 and 100
       or p_type not in ('cash', 'bank', 'ewallet', 'credit', 'other')
       or p_initial_balance is null
       or p_is_default is null
       or p_is_active is null
       or p_initial_balance not between -999999999999.99 and 999999999999.99
       or p_is_default and not p_is_active then
        raise exception 'Invalid wallet values' using errcode = '22023';
    end if;

    perform pg_advisory_xact_lock(hashtextextended(v_user_id::text, 0));
    select is_default into v_was_default
    from public.wallets
    where id = p_wallet_id and user_id = v_user_id
    for update;
    if v_was_default is null then
        raise exception 'Wallet not found' using errcode = 'P0002';
    end if;

    if p_is_default then
        update public.wallets
        set is_default = false
        where user_id = v_user_id
          and id <> p_wallet_id
          and is_default;
    elsif v_was_default then
        select id into v_replacement_id
        from public.wallets
        where user_id = v_user_id
          and id <> p_wallet_id
          and is_active
        order by created_at, id
        limit 1
        for update;
        if v_replacement_id is null then
            raise exception 'At least one active default wallet is required'
                using errcode = '22023';
        end if;
    end if;

    update public.wallets
    set name = btrim(p_name),
        type = p_type::public.wallet_type,
        initial_balance = p_initial_balance,
        is_default = p_is_default,
        is_active = p_is_active
    where id = p_wallet_id and user_id = v_user_id;

    if v_replacement_id is not null then
        update public.wallets set is_default = true
        where id = v_replacement_id and user_id = v_user_id;
    end if;
end;
$$;

revoke all on function public.update_personal_wallet(
    uuid, text, text, numeric, boolean, boolean
) from public;
grant execute on function public.update_personal_wallet(
    uuid, text, text, numeric, boolean, boolean
) to authenticated;

create or replace function public.list_all_notifications_v3(
    p_category text default null,
    p_before_created_at timestamptz default null,
    p_before_source text default null,
    p_before_id uuid default null,
    p_limit integer default 30,
    p_group_id uuid default null
)
returns table (
    id uuid,
    category text,
    type text,
    group_id uuid,
    group_name text,
    group_transaction_id uuid,
    friend_request_id uuid,
    metadata jsonb,
    is_read boolean,
    created_at timestamptz,
    source text
)
language sql
stable
security definer
set search_path = public
as $$
    with normalized as (
        select
            an.id,
            an.category,
            an.type,
            an.group_id,
            g.name as group_name,
            an.group_transaction_id,
            an.friend_request_id,
            an.metadata,
            an.is_read,
            an.created_at,
            'app'::text as source
        from public.app_notifications an
        left join public.groups g on g.id = an.group_id
        where an.user_id = auth.uid()
          and an.created_at >= timezone('utc', now()) - interval '30 days'
          and an.expires_at > timezone('utc', now())
          and (p_category is null or an.category = p_category)
          and (p_group_id is null or an.group_id = p_group_id)

        union all

        select
            gn.id,
            gn.category,
            case gn.type
                when 'member_amount_input_required' then 'member_amount_required'
                when 'group_transaction_posted' then 'transaction_posted'
                else gn.type
            end,
            gn.group_id,
            g.name,
            gn.group_transaction_id,
            null::uuid,
            gn.metadata,
            gn.is_read,
            gn.created_at,
            'group'::text
        from public.group_notifications gn
        join public.groups g on g.id = gn.group_id
        where gn.user_id = auth.uid()
          and gn.created_at >= timezone('utc', now()) - interval '30 days'
          and (p_category is null or gn.category = p_category)
          and (p_group_id is null or gn.group_id = p_group_id)
    )
    select *
    from normalized n
    where p_before_created_at is null
       or n.created_at < p_before_created_at
       or (
            n.created_at = p_before_created_at
            and n.source < p_before_source
       )
       or (
            n.created_at = p_before_created_at
            and n.source = p_before_source
            and n.id < p_before_id
       )
    order by n.created_at desc, n.source desc, n.id desc
    limit least(greatest(coalesce(p_limit, 30), 1), 100);
$$;

revoke all on function public.list_all_notifications_v3(
    text, timestamptz, text, uuid, integer, uuid
) from public;
grant execute on function public.list_all_notifications_v3(
    text, timestamptz, text, uuid, integer, uuid
) to authenticated;
