-- Idempotent personal recurring materialization, atomic rule mutations, and
-- source-controlled scheduling for both personal and group auto-post rules.

create table if not exists public.personal_recurring_postings (
    recurring_transaction_id uuid not null
        references public.recurring_transactions(id) on delete cascade,
    scheduled_for date not null,
    transaction_id uuid not null
        references public.transactions(id) on delete cascade,
    created_at timestamptz not null default timezone('utc', now()),
    primary key (recurring_transaction_id, scheduled_for),
    unique (transaction_id)
);

alter table public.personal_recurring_postings enable row level security;

drop policy if exists "personal_recurring_postings_select_own"
    on public.personal_recurring_postings;
create policy "personal_recurring_postings_select_own"
on public.personal_recurring_postings
for select to authenticated
using (
    exists (
        select 1
        from public.recurring_transactions rt
        where rt.id = recurring_transaction_id
          and rt.user_id = auth.uid()
    )
);

-- Preserve idempotency for transactions materialized by older app versions.
insert into public.personal_recurring_postings (
    recurring_transaction_id,
    scheduled_for,
    transaction_id
)
select distinct on (
    t.recurring_transaction_id,
    (t.transaction_date at time zone coalesce(tz.name, 'UTC'))::date
)
    t.recurring_transaction_id,
    (t.transaction_date at time zone coalesce(tz.name, 'UTC'))::date,
    t.id
from public.transactions t
join public.profiles p on p.id = t.user_id
left join pg_catalog.pg_timezone_names tz on tz.name = p.timezone
where t.recurring_transaction_id is not null
order by
    t.recurring_transaction_id,
    (t.transaction_date at time zone coalesce(tz.name, 'UTC'))::date,
    t.created_at asc
on conflict do nothing;

create or replace function public.advance_personal_recurring_date(
    p_date date,
    p_frequency text,
    p_interval integer
)
returns date
language sql
immutable
set search_path = ''
as $$
    select case p_frequency
        when 'daily' then p_date + greatest(p_interval, 1)
        when 'weekly' then p_date + (7 * greatest(p_interval, 1))
        when 'monthly' then (
            p_date + make_interval(months => greatest(p_interval, 1))
        )::date
        when 'yearly' then (
            p_date + make_interval(years => greatest(p_interval, 1))
        )::date
        else p_date + 1
    end;
$$;

create or replace function public.post_due_personal_recurring_transactions(
    p_limit integer default 100,
    p_through date default null
)
returns integer
language plpgsql
security definer
set search_path = public
as $$
declare
    v_actor uuid := auth.uid();
    v_item public.recurring_transactions%rowtype;
    v_next date;
    v_last date;
    v_today date;
    v_timezone text;
    v_transaction_id uuid;
    v_inserted boolean;
    v_count integer := 0;
    v_limit integer := greatest(1, least(coalesce(p_limit, 100), 500));
begin
    for v_item in
        select rt.*
        from public.recurring_transactions rt
        where rt.is_active
          and rt.auto_post
          and (v_actor is null or rt.user_id = v_actor)
        order by rt.next_run_date, rt.id
        for update skip locked
    loop
        exit when v_count >= v_limit;
        select
            coalesce(tz.name, 'UTC'),
            (timezone(coalesce(tz.name, 'UTC'), now()))::date
        into v_timezone, v_today
        from public.profiles p
        left join pg_catalog.pg_timezone_names tz on tz.name = p.timezone
        where p.id = v_item.user_id;
        v_timezone := coalesce(v_timezone, 'UTC');
        v_today := coalesce(v_today, current_date);
        -- Authenticated callers may retry through today, never force future
        -- occurrences. Cron callers pass null and use each profile timezone.
        if v_actor is not null and p_through is not null then
            v_today := least(v_today, p_through);
        end if;

        v_next := v_item.next_run_date;
        v_last := v_item.last_run_date;
        while v_next <= v_today
          and (v_item.end_date is null or v_next <= v_item.end_date)
          and v_count < v_limit
        loop
            v_inserted := false;
            insert into public.transactions (
                user_id,
                wallet_id,
                category_id,
                amount,
                type,
                note,
                transaction_date,
                source,
                image_upload_status,
                recurring_transaction_id
            ) values (
                v_item.user_id,
                v_item.wallet_id,
                v_item.category_id,
                v_item.amount,
                v_item.type,
                v_item.note,
                v_next::timestamp at time zone v_timezone,
                'recurring',
                'none',
                v_item.id
            )
            returning id into v_transaction_id;

            begin
                insert into public.personal_recurring_postings (
                    recurring_transaction_id,
                    scheduled_for,
                    transaction_id
                ) values (
                    v_item.id,
                    v_next,
                    v_transaction_id
                );
                v_inserted := true;
            exception when unique_violation then
                delete from public.transactions where id = v_transaction_id;
            end;

            if v_inserted then
                v_count := v_count + 1;
            end if;
            v_last := v_next;
            v_next := public.advance_personal_recurring_date(
                v_next,
                v_item.frequency,
                v_item.interval
            );
        end loop;

        update public.recurring_transactions
        set next_run_date = v_next,
            last_run_date = v_last,
            is_active = (
                v_item.end_date is null or v_next <= v_item.end_date
            )
        where id = v_item.id;
    end loop;

    return v_count;
end;
$$;

revoke all on function public.post_due_personal_recurring_transactions(integer, date)
    from public;
grant execute on function public.post_due_personal_recurring_transactions(integer, date)
    to authenticated;

create or replace function public.update_personal_recurring_transaction(
    p_id uuid,
    p_amount numeric,
    p_type text,
    p_wallet_id uuid,
    p_category_id uuid,
    p_frequency text,
    p_interval integer,
    p_start_date date,
    p_next_run_date date,
    p_is_active boolean,
    p_end_date date default null,
    p_note text default null,
    p_auto_post boolean default false,
    p_apply_mode text default 'future_only'
)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
    v_user_id uuid := auth.uid();
    v_type public.transaction_type;
begin
    if v_user_id is null then
        raise exception 'Not authenticated' using errcode = '42501';
    end if;
    if p_amount <= 0
       or p_type not in ('income', 'expense')
       or p_frequency not in ('daily', 'weekly', 'monthly', 'yearly')
       or p_interval < 1
       or p_end_date is not null and p_end_date < p_start_date
       or p_apply_mode not in ('future_only', 'update_existing', 'delete_and_regenerate') then
        raise exception 'Invalid recurring transaction values' using errcode = '22023';
    end if;
    v_type := p_type::public.transaction_type;

    perform 1
    from public.recurring_transactions
    where id = p_id and user_id = v_user_id
    for update;
    if not found then
        raise exception 'Recurring transaction not found' using errcode = 'P0002';
    end if;
    if not exists (
        select 1 from public.wallets
        where id = p_wallet_id and user_id = v_user_id and is_active
    ) or not exists (
        select 1 from public.categories
        where id = p_category_id
          and user_id = v_user_id
          and type = v_type
          and is_active
    ) then
        raise exception 'Wallet or category is unavailable' using errcode = '22023';
    end if;

    if p_apply_mode = 'delete_and_regenerate' and exists (
        select 1 from public.transactions
        where user_id = v_user_id
          and recurring_transaction_id = p_id
          and image_path is not null
    ) then
        raise exception 'Remove images from generated transactions before regenerating'
            using errcode = '22023';
    end if;

    update public.recurring_transactions
    set wallet_id = p_wallet_id,
        category_id = p_category_id,
        amount = p_amount,
        type = v_type,
        note = nullif(btrim(coalesce(p_note, '')), ''),
        frequency = p_frequency,
        interval = p_interval,
        start_date = p_start_date,
        next_run_date = case
            when p_apply_mode = 'delete_and_regenerate' then p_start_date
            else p_next_run_date
        end,
        last_run_date = case
            when p_apply_mode = 'delete_and_regenerate' then null
            else last_run_date
        end,
        end_date = p_end_date,
        auto_post = p_auto_post,
        is_active = p_is_active
    where id = p_id and user_id = v_user_id;

    if p_apply_mode = 'update_existing' then
        update public.transactions
        set wallet_id = p_wallet_id,
            category_id = p_category_id,
            amount = p_amount,
            type = v_type,
            note = nullif(btrim(coalesce(p_note, '')), '')
        where user_id = v_user_id
          and recurring_transaction_id = p_id;
    elsif p_apply_mode = 'delete_and_regenerate' then
        delete from public.transactions
        where user_id = v_user_id
          and recurring_transaction_id = p_id;
    end if;
end;
$$;

revoke all on function public.update_personal_recurring_transaction(
    uuid, numeric, text, uuid, uuid, text, integer, date, date, boolean,
    date, text, boolean, text
) from public;
grant execute on function public.update_personal_recurring_transaction(
    uuid, numeric, text, uuid, uuid, text, integer, date, date, boolean,
    date, text, boolean, text
) to authenticated;

create or replace function public.delete_personal_recurring_transaction(
    p_id uuid,
    p_delete_generated boolean default false
)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
    v_user_id uuid := auth.uid();
begin
    if v_user_id is null then
        raise exception 'Not authenticated' using errcode = '42501';
    end if;
    perform 1
    from public.recurring_transactions
    where id = p_id and user_id = v_user_id
    for update;
    if not found then
        raise exception 'Recurring transaction not found' using errcode = 'P0002';
    end if;
    if p_delete_generated and exists (
        select 1 from public.transactions
        where user_id = v_user_id
          and recurring_transaction_id = p_id
          and image_path is not null
    ) then
        raise exception 'Remove images from generated transactions before deleting them'
            using errcode = '22023';
    end if;
    if p_delete_generated then
        delete from public.transactions
        where user_id = v_user_id
          and recurring_transaction_id = p_id;
    end if;
    delete from public.recurring_transactions
    where id = p_id and user_id = v_user_id;
end;
$$;

revoke all on function public.delete_personal_recurring_transaction(uuid, boolean)
    from public;
grant execute on function public.delete_personal_recurring_transaction(uuid, boolean)
    to authenticated;

create extension if not exists pg_cron;

do $$
declare
    v_job_id bigint;
begin
    for v_job_id in
        select jobid from cron.job
        where jobname in (
            'post_due_personal_recurring_transactions',
            'post_due_group_recurring_transactions'
        )
    loop
        perform cron.unschedule(v_job_id);
    end loop;
end;
$$;

select cron.schedule(
    'post_due_personal_recurring_transactions',
    '*/5 * * * *',
    'select public.post_due_personal_recurring_transactions(500, null);'
);

select cron.schedule(
    'post_due_group_recurring_transactions',
    '*/5 * * * *',
    'select public.post_due_group_recurring_transactions(100);'
);
