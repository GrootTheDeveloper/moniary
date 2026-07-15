-- Group finance controls: explicit base currency, safe public media policy,
-- recurring auto-posting and an administrator-only audit trail.

alter table public.groups
    add column if not exists base_currency text;
update public.groups
set base_currency = 'VND'
where base_currency is null or btrim(base_currency) = '';
alter table public.groups
    alter column base_currency set default 'VND',
    alter column base_currency set not null;
alter table public.groups
    drop constraint if exists groups_base_currency_check;
alter table public.groups
    add constraint groups_base_currency_check
    check (base_currency ~ '^[A-Z]{3}$');
alter table public.group_transactions
    add column if not exists currency_code text;
alter table public.group_transactions
    add column if not exists exchange_rate_to_base numeric(18,8);
alter table public.group_transactions
    add column if not exists base_total_amount bigint;
alter table public.group_transactions
    add column if not exists original_total_amount bigint;
update public.group_transactions
set currency_code = coalesce(nullif(currency_code, ''), 'VND'),
    exchange_rate_to_base = coalesce(exchange_rate_to_base, 1),
    base_total_amount = coalesce(base_total_amount, total_amount),
    original_total_amount = coalesce(original_total_amount, total_amount);
alter table public.group_transactions
    alter column currency_code set default 'VND',
    alter column currency_code set not null,
    alter column exchange_rate_to_base set default 1,
    alter column exchange_rate_to_base set not null,
    alter column base_total_amount set not null,
    alter column original_total_amount set not null;
alter table public.group_transactions
    drop constraint if exists group_transactions_currency_code_check;
alter table public.group_transactions
    add constraint group_transactions_currency_code_check
    check (currency_code ~ '^[A-Z]{3}$');
alter table public.group_transactions
    drop constraint if exists group_transactions_exchange_rate_check;
alter table public.group_transactions
    add constraint group_transactions_exchange_rate_check
    check (exchange_rate_to_base > 0);
alter table public.group_transactions
    drop constraint if exists group_transactions_base_amount_check;
alter table public.group_transactions
    add constraint group_transactions_base_amount_check
    check (base_total_amount > 0);
alter table public.group_transactions
    drop constraint if exists group_transactions_original_amount_check;
alter table public.group_transactions
    add constraint group_transactions_original_amount_check
    check (original_total_amount > 0);
create or replace function public.set_group_transaction_currency_defaults()
returns trigger language plpgsql set search_path = public
as $$
begin
    new.currency_code := coalesce(nullif(new.currency_code, ''), 'VND');
    new.exchange_rate_to_base := coalesce(new.exchange_rate_to_base, 1);
    new.base_total_amount := coalesce(new.base_total_amount, new.total_amount);
    new.original_total_amount := coalesce(new.original_total_amount, new.total_amount);
    return new;
end;
$$;
drop trigger if exists set_group_transaction_currency_defaults
    on public.group_transactions;
create trigger set_group_transaction_currency_defaults
before insert or update on public.group_transactions
for each row execute function public.set_group_transaction_currency_defaults();
create or replace function public.update_group_currency(
    p_group_id uuid,
    p_base_currency text
)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
    v_currency text := upper(btrim(coalesce(p_base_currency, '')));
begin
    if not public.has_group_role(
        p_group_id,
        array['owner', 'admin']::public.group_role[],
        auth.uid()
    ) then
        raise exception 'group admin required' using errcode = '42501';
    end if;
    if v_currency !~ '^[A-Z]{3}$' then
        raise exception 'invalid base currency';
    end if;
    if exists (
        select 1
        from public.group_transactions
        where group_id = p_group_id and split_status = 'posted'
    ) and exists (
        select 1 from public.groups
        where id = p_group_id and base_currency <> v_currency
    ) then
        raise exception 'base currency cannot change after posted transactions';
    end if;
    update public.groups
    set base_currency = v_currency
    where id = p_group_id;
end;
$$;
revoke all on function public.update_group_currency(uuid, text) from public;
grant execute on function public.update_group_currency(uuid, text) to authenticated;
alter table public.group_recurring_transactions
    add column if not exists auto_post boolean not null default false;
alter table public.group_recurring_transactions
    add column if not exists last_posted_at timestamptz;
alter table public.group_public_profiles
    add column if not exists show_description boolean;
alter table public.group_public_profiles
    add column if not exists show_group_type boolean;
alter table public.group_public_profiles
    add column if not exists show_avatar boolean;
update public.group_public_profiles
set show_description = coalesce(show_description, false),
    show_group_type = coalesce(show_group_type, false),
    show_avatar = coalesce(show_avatar, false);
alter table public.group_public_profiles
    alter column show_description set default false,
    alter column show_description set not null,
    alter column show_group_type set default false,
    alter column show_group_type set not null,
    alter column show_avatar set default false,
    alter column show_avatar set not null;
create or replace function public.create_group_recurring_transaction(
    p_group_id uuid,
    p_title text,
    p_amount bigint,
    p_frequency text,
    p_next_run_at timestamptz,
    p_notify_days_before integer,
    p_auto_post boolean
)
returns uuid
language plpgsql security definer set search_path = public
as $$
declare v_id uuid;
begin
    if auth.uid() is null or not public.is_group_member(p_group_id, auth.uid()) then
        raise exception 'group membership required' using errcode = '42501';
    end if;
    insert into public.group_recurring_transactions (
        group_id, created_by, title, amount, frequency, next_run_at,
        notify_days_before, auto_post
    ) values (
        p_group_id, auth.uid(), btrim(p_title), p_amount, p_frequency,
        p_next_run_at, p_notify_days_before, coalesce(p_auto_post, false)
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
    p_is_active boolean,
    p_auto_post boolean
)
returns void
language plpgsql security definer set search_path = public
as $$
begin
    update public.group_recurring_transactions rt
    set title = btrim(p_title), amount = p_amount, frequency = p_frequency,
        next_run_at = p_next_run_at, notify_days_before = p_notify_days_before,
        is_active = p_is_active, auto_post = coalesce(p_auto_post, false)
    where rt.id = p_id
      and (rt.created_by = auth.uid() or public.has_group_role(
          rt.group_id, array['owner', 'admin']::public.group_role[], auth.uid()
      ));
    if not found then
        raise exception 'recurring transaction not found or not allowed'
            using errcode = '42501';
    end if;
end;
$$;
revoke all on function public.create_group_recurring_transaction(
    uuid, text, bigint, text, timestamptz, integer, boolean
) from public;
grant execute on function public.create_group_recurring_transaction(
    uuid, text, bigint, text, timestamptz, integer, boolean
) to authenticated;
revoke all on function public.update_group_recurring_transaction(
    uuid, text, bigint, text, timestamptz, integer, boolean, boolean
) from public;
grant execute on function public.update_group_recurring_transaction(
    uuid, text, bigint, text, timestamptz, integer, boolean, boolean
) to authenticated;
create table if not exists public.group_recurring_postings (
    id uuid primary key default gen_random_uuid(),
    recurring_transaction_id uuid not null
        references public.group_recurring_transactions(id) on delete cascade,
    scheduled_for timestamptz not null,
    group_transaction_id uuid references public.group_transactions(id) on delete set null,
    created_at timestamptz not null default timezone('utc', now()),
    unique (recurring_transaction_id, scheduled_for)
);
alter table public.group_recurring_postings enable row level security;
drop policy if exists "group_recurring_postings_select_member"
    on public.group_recurring_postings;
create policy "group_recurring_postings_select_member"
on public.group_recurring_postings for select to authenticated
using (
    exists (
        select 1 from public.group_recurring_transactions rt
        where rt.id = recurring_transaction_id
          and public.is_group_member(rt.group_id)
    )
);
create or replace function public.post_due_group_recurring_transactions(
    p_limit integer default 25
)
returns integer
language plpgsql
security definer
set search_path = public
as $$
declare
    v_item public.group_recurring_transactions%rowtype;
    v_scheduled timestamptz;
    v_transaction_id uuid;
    v_count integer := 0;
    v_actor uuid;
begin
    v_actor := auth.uid();
    for v_item in
        select rt.*
        from public.group_recurring_transactions rt
        where rt.is_active
          and rt.auto_post
          and rt.next_run_at <= timezone('utc', now())
          and (v_actor is null or public.is_group_member(rt.group_id, v_actor))
        order by rt.next_run_at
        limit greatest(1, least(coalesce(p_limit, 25), 100))
        for update skip locked
    loop
        v_scheduled := v_item.next_run_at;
        if exists (
            select 1 from public.group_recurring_postings
            where recurring_transaction_id = v_item.id
              and scheduled_for = v_scheduled
        ) then
            update public.group_recurring_transactions
            set next_run_at = case when frequency = 'weekly'
                then next_run_at + interval '7 days'
                else next_run_at + interval '1 month' end
            where id = v_item.id;
            continue;
        end if;

        insert into public.group_transactions (
            group_id, created_by, total_amount, base_total_amount, original_total_amount,
            currency_code, exchange_rate_to_base, caption,
            split_mode, payment_mode, split_status, transaction_date
        )
        select
            v_item.group_id,
            coalesce(v_actor, g.created_by),
            v_item.amount,
            v_item.amount,
            v_item.amount,
            g.base_currency,
            1,
            v_item.title,
            'equal',
            'everyone_paid',
            'draft',
            v_scheduled
        from public.groups g
        where g.id = v_item.group_id
        returning id into v_transaction_id;

        perform public.populate_group_transaction(
            v_transaction_id,
            v_item.amount,
            'equal'::public.group_split_mode,
            'everyone_paid'::public.group_payment_mode,
            '{}'::jsonb
        );
        update public.group_transactions
        set split_status = 'posted'
        where id = v_transaction_id;
        insert into public.group_recurring_postings (
            recurring_transaction_id, scheduled_for, group_transaction_id
        ) values (v_item.id, v_scheduled, v_transaction_id);
        update public.group_recurring_transactions
        set last_posted_at = timezone('utc', now()),
            next_run_at = case when frequency = 'weekly'
                then next_run_at + interval '7 days'
                else next_run_at + interval '1 month' end
        where id = v_item.id;
        perform public.refresh_group_settlements(v_item.group_id);
        v_count := v_count + 1;
    end loop;
    return v_count;
end;
$$;
revoke all on function public.post_due_group_recurring_transactions(integer) from public;
grant execute on function public.post_due_group_recurring_transactions(integer)
    to authenticated;
create table if not exists public.group_audit_logs (
    id uuid primary key default gen_random_uuid(),
    group_id uuid not null references public.groups(id) on delete cascade,
    actor_user_id uuid references public.profiles(id) on delete set null,
    action text not null,
    target_user_id uuid references public.profiles(id) on delete set null,
    target_transaction_id uuid references public.group_transactions(id) on delete set null,
    metadata jsonb not null default '{}'::jsonb,
    created_at timestamptz not null default timezone('utc', now())
);
create index if not exists group_audit_logs_group_created_idx
    on public.group_audit_logs (group_id, created_at desc);
alter table public.group_audit_logs enable row level security;
drop policy if exists "group_audit_logs_select_admin"
    on public.group_audit_logs;
create policy "group_audit_logs_select_admin"
on public.group_audit_logs for select to authenticated
using (
    public.has_group_role(
        group_id,
        array['owner', 'admin']::public.group_role[],
        auth.uid()
    )
);
create or replace function public.log_group_audit_event()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
    v_group_id uuid;
    v_actor uuid := auth.uid();
begin
    v_group_id := coalesce((to_jsonb(new)->>'group_id')::uuid,
                           (to_jsonb(old)->>'group_id')::uuid,
                           (to_jsonb(new)->>'id')::uuid,
                           (to_jsonb(old)->>'id')::uuid);
    if v_group_id is not null then
        insert into public.group_audit_logs (
            group_id, actor_user_id, action, target_user_id,
            target_transaction_id, metadata
        ) values (
            v_group_id,
            v_actor,
            lower(TG_TABLE_NAME || '.' || TG_OP),
            case when TG_TABLE_NAME = 'group_members' then
                nullif(coalesce(to_jsonb(new)->>'user_id', to_jsonb(old)->>'user_id'), '')::uuid
            end,
            case when TG_TABLE_NAME = 'group_transactions' then
                nullif(coalesce(to_jsonb(new)->>'id', to_jsonb(old)->>'id'), '')::uuid
            end,
            jsonb_build_object('table', TG_TABLE_NAME, 'operation', TG_OP)
        );
    end if;
    if TG_OP = 'DELETE' then
        return old;
    end if;
    return new;
end;
$$;
drop trigger if exists group_audit_groups on public.groups;
create trigger group_audit_groups after insert or update or delete on public.groups
for each row execute function public.log_group_audit_event();
drop trigger if exists group_audit_members on public.group_members;
create trigger group_audit_members after insert or update or delete on public.group_members
for each row execute function public.log_group_audit_event();
drop trigger if exists group_audit_transactions on public.group_transactions;
create trigger group_audit_transactions after insert or update or delete on public.group_transactions
for each row execute function public.log_group_audit_event();
create or replace function public.list_group_audit_logs(
    p_group_id uuid,
    p_limit integer default 50,
    p_offset integer default 0
)
returns setof public.group_audit_logs
language sql
stable
security invoker
set search_path = public
as $$
    select * from public.group_audit_logs
    where group_id = p_group_id
    order by created_at desc
    limit greatest(1, least(coalesce(p_limit, 50), 100))
    offset greatest(coalesce(p_offset, 0), 0);
$$;
revoke all on function public.list_group_audit_logs(uuid, integer, integer) from public;
grant execute on function public.list_group_audit_logs(uuid, integer, integer)
    to authenticated;
drop function if exists public.get_public_group_profile(text);
create function public.get_public_group_profile(p_slug text)
returns table (
    group_id uuid, slug text, group_name text, avatar_path text,
    description text, group_type text, show_stats boolean,
    member_count bigint, transaction_count bigint, total_spent bigint
)
language sql stable security definer set search_path = public
as $$
    select gp.group_id, gp.slug, g.name,
        case when gp.show_avatar and g.avatar_path like 'public-group-avatars/%'
             then g.avatar_path else null end,
        case when gp.show_description then g.description else null end,
        case when gp.show_group_type then g.type else null end,
        gp.show_stats,
        case when gp.show_stats then (select count(*) from public.group_members gm
            where gm.group_id = g.id and gm.status = 'active') else null end,
        case when gp.show_stats then (select count(*) from public.group_transactions gt
            where gt.group_id = g.id and gt.split_status = 'posted') else null end,
        case when gp.show_stats then (select coalesce(sum(gt.base_total_amount), 0)
            from public.group_transactions gt
            where gt.group_id = g.id and gt.split_status = 'posted') else null end
    from public.group_public_profiles gp
    join public.groups g on g.id = gp.group_id
    where gp.slug = lower(trim(p_slug)) and gp.is_enabled and g.status = 'active';
$$;
revoke all on function public.get_public_group_profile(text) from public;
grant execute on function public.get_public_group_profile(text) to anon, authenticated;
-- Currency-aware overloads keep the original RPCs backward compatible while
-- making every new foreign-currency transaction ledger in the group base unit.
create or replace function public.create_group_transaction(
    p_group_id uuid, p_total_amount bigint, p_category_id uuid,
    p_category_name text, p_caption text, p_note text,
    p_split_mode text, p_payment_mode text, p_payer_amounts jsonb,
    p_participant_ids jsonb, p_share_amounts jsonb,
    p_currency_code text, p_exchange_rate_to_base numeric
)
returns uuid
language plpgsql security definer set search_path = public
as $$
declare
    v_id uuid;
    v_base bigint;
    v_rate numeric := coalesce(p_exchange_rate_to_base, 1);
    v_currency text := upper(btrim(coalesce(p_currency_code, '')));
    v_status public.group_split_status;
begin
    if not public.is_group_member(p_group_id) then
        raise exception 'GROUP_MEMBER_REQUIRED';
    end if;
    if v_currency !~ '^[A-Z]{3}$' or v_rate <= 0 then
        raise exception 'CURRENCY_RATE_INVALID';
    end if;
    v_base := round(p_total_amount * v_rate)::bigint;
    if v_base <= 0 then raise exception 'GROUP_AMOUNT_INVALID'; end if;
    insert into public.group_transactions (
        group_id, created_by, total_amount, base_total_amount, original_total_amount,
        currency_code, exchange_rate_to_base, category_id,
        category_name_snapshot, caption, note, split_mode,
        payment_mode, split_status
    ) values (
        p_group_id, auth.uid(), v_base, v_base, p_total_amount, v_currency, v_rate,
        p_category_id, nullif(btrim(coalesce(p_category_name, '')), ''),
        nullif(btrim(coalesce(p_caption, '')), ''),
        nullif(btrim(coalesce(p_note, '')), ''),
        p_split_mode::public.group_split_mode,
        p_payment_mode::public.group_payment_mode, 'draft'
    ) returning id into v_id;
    v_status := public.populate_group_transaction_v2(
        v_id, v_base, p_split_mode::public.group_split_mode,
        p_payment_mode::public.group_payment_mode,
        coalesce(p_payer_amounts, '{}'::jsonb),
        coalesce(p_participant_ids, '[]'::jsonb),
        coalesce(p_share_amounts, '{}'::jsonb)
    );
    update public.group_transactions set split_status = v_status where id = v_id;
    if v_status = 'posted' then perform public.refresh_group_settlements(p_group_id); end if;
    return v_id;
end;
$$;
create or replace function public.update_group_transaction(
    p_transaction_id uuid, p_total_amount bigint, p_category_id uuid,
    p_category_name text, p_caption text, p_note text,
    p_split_mode text, p_payment_mode text, p_payer_amounts jsonb,
    p_participant_ids jsonb, p_share_amounts jsonb,
    p_currency_code text, p_exchange_rate_to_base numeric
)
returns void
language plpgsql security definer set search_path = public
as $$
declare
    v_group_id uuid;
    v_base bigint;
    v_rate numeric := coalesce(p_exchange_rate_to_base, 1);
    v_currency text := upper(btrim(coalesce(p_currency_code, '')));
    v_status public.group_split_status;
begin
    select group_id into v_group_id from public.group_transactions
    where id = p_transaction_id and created_by = auth.uid() for update;
    if v_group_id is null then raise exception 'GROUP_CREATOR_ONLY'; end if;
    if v_currency !~ '^[A-Z]{3}$' or v_rate <= 0 then
        raise exception 'CURRENCY_RATE_INVALID';
    end if;
    v_base := round(p_total_amount * v_rate)::bigint;
    delete from public.group_transaction_payers where group_transaction_id = p_transaction_id;
    delete from public.group_transaction_shares where group_transaction_id = p_transaction_id;
    update public.group_transactions set
        total_amount = v_base, base_total_amount = v_base,
        original_total_amount = p_total_amount,
        currency_code = v_currency, exchange_rate_to_base = v_rate,
        category_id = p_category_id,
        category_name_snapshot = nullif(btrim(coalesce(p_category_name, '')), ''),
        caption = nullif(btrim(coalesce(p_caption, '')), ''),
        note = nullif(btrim(coalesce(p_note, '')), ''),
        split_mode = p_split_mode::public.group_split_mode,
        payment_mode = p_payment_mode::public.group_payment_mode,
        split_status = 'draft'
    where id = p_transaction_id;
    v_status := public.populate_group_transaction_v2(
        p_transaction_id, v_base, p_split_mode::public.group_split_mode,
        p_payment_mode::public.group_payment_mode,
        coalesce(p_payer_amounts, '{}'::jsonb),
        coalesce(p_participant_ids, '[]'::jsonb),
        coalesce(p_share_amounts, '{}'::jsonb)
    );
    update public.group_transactions set split_status = v_status where id = p_transaction_id;
    perform public.refresh_group_settlements(v_group_id);
end;
$$;
revoke all on function public.create_group_transaction(
    uuid, bigint, uuid, text, text, text, text, text, jsonb, jsonb, jsonb, text, numeric
) from public;
grant execute on function public.create_group_transaction(
    uuid, bigint, uuid, text, text, text, text, text, jsonb, jsonb, jsonb, text, numeric
) to authenticated;
revoke all on function public.update_group_transaction(
    uuid, bigint, uuid, text, text, text, text, text, jsonb, jsonb, jsonb, text, numeric
) from public;
grant execute on function public.update_group_transaction(
    uuid, bigint, uuid, text, text, text, text, text, jsonb, jsonb, jsonb, text, numeric
) to authenticated;
