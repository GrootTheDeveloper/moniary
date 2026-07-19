-- Multi-currency support, phase 1: each wallet gets a fixed currency (set at
-- creation, immutable afterward so historical transactions never silently
-- change meaning), plus a daily historical exchange_rates table populated by
-- a cron-scheduled Edge Function. Conversion between currencies happens at
-- read time in the client using the rate for the transaction's own date.

alter table public.wallets
  add column if not exists currency text not null default 'VND'
    check (currency ~ '^[A-Z]{3}$');

-- Backfill existing wallets to their owner's current preferred currency, so
-- pre-existing amounts keep being interpreted the way the user already sees
-- them displayed today.
update public.wallets w
set currency = coalesce(nullif(upper(btrim(p.preferred_currency)), ''), 'VND')
from public.profiles p
where p.id = w.user_id;

drop function if exists public.create_personal_wallet(text, text, numeric, boolean);
create or replace function public.create_personal_wallet(
    p_name text,
    p_type text,
    p_initial_balance numeric,
    p_currency text default 'VND',
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
    v_currency text := upper(btrim(coalesce(p_currency, 'VND')));
begin
    if v_user_id is null then
        raise exception 'Not authenticated' using errcode = '42501';
    end if;
    if length(btrim(coalesce(p_name, ''))) not between 1 and 100
       or p_type not in ('cash', 'bank', 'ewallet', 'credit', 'other')
       or p_initial_balance is null
       or p_initial_balance not between -999999999999.99 and 999999999999.99
       or v_currency !~ '^[A-Z]{3}$' then
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
        currency,
        is_default
    ) values (
        v_user_id,
        btrim(p_name),
        p_type::public.wallet_type,
        p_initial_balance,
        v_currency,
        v_make_default
    )
    returning id into v_wallet_id;
    return v_wallet_id;
end;
$$;

revoke all on function public.create_personal_wallet(text, text, numeric, text, boolean)
    from public;
grant execute on function public.create_personal_wallet(text, text, numeric, text, boolean)
    to authenticated;

-- update_personal_wallet intentionally does not take a currency parameter:
-- a wallet's currency is fixed at creation. Transactions do not carry their
-- own currency, they inherit the wallet's — allowing currency to change
-- later would silently reinterpret every historical transaction in that
-- wallet under a different currency.
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

-- Daily historical exchange rates, pivoted through USD (rate_to_usd = USD
-- value of 1 unit of currency_code). Populated only by the
-- fetch-exchange-rates Edge Function using the service-role key, which
-- bypasses RLS entirely — authenticated users may read every row (rates are
-- not user-scoped data) but never write.
create table if not exists public.exchange_rates (
    id uuid primary key default gen_random_uuid(),
    rate_date date not null,
    currency_code text not null check (currency_code ~ '^[A-Z]{3}$'),
    rate_to_usd numeric(18, 10) not null check (rate_to_usd > 0),
    created_at timestamptz not null default timezone('utc', now()),
    unique (rate_date, currency_code)
);

create index if not exists exchange_rates_currency_date_idx
    on public.exchange_rates (currency_code, rate_date desc);

alter table public.exchange_rates enable row level security;

drop policy if exists "exchange_rates_select_all" on public.exchange_rates;
create policy "exchange_rates_select_all"
    on public.exchange_rates
    for select
    to authenticated
    using (true);

-- Invokes the fetch-exchange-rates Edge Function via pg_net, authenticated
-- with a shared secret read from Supabase Vault (same `project_url` entry
-- already used by scheduled-reports/garbage-collect). Before enabling the
-- cron job, create a `fetch_exchange_rates_secret` Vault entry and set the
-- same value as the Edge Function's FETCH_EXCHANGE_RATES_SECRET.
create or replace function public.invoke_fetch_exchange_rates()
returns bigint
language plpgsql
security definer
set search_path = ''
as $$
declare
    v_project_url text;
    v_secret text;
    v_request_id bigint;
begin
    select decrypted_secret into v_project_url
    from vault.decrypted_secrets
    where name = 'project_url'
    order by created_at desc
    limit 1;

    select decrypted_secret into v_secret
    from vault.decrypted_secrets
    where name = 'fetch_exchange_rates_secret'
    order by created_at desc
    limit 1;

    if nullif(btrim(v_project_url), '') is null
       or char_length(coalesce(v_secret, '')) < 32 then
        raise exception 'FETCH_EXCHANGE_RATES_VAULT_NOT_CONFIGURED';
    end if;

    select net.http_post(
        url := rtrim(v_project_url, '/') || '/functions/v1/fetch-exchange-rates',
        headers := jsonb_build_object(
            'Content-Type', 'application/json',
            'x-fetch-exchange-rates-secret', v_secret
        ),
        body := '{}'::jsonb,
        timeout_milliseconds := 30000
    ) into v_request_id;

    return v_request_id;
end;
$$;

revoke all on function public.invoke_fetch_exchange_rates()
from public, anon, authenticated;
grant execute on function public.invoke_fetch_exchange_rates()
to service_role;

do $$
declare
    v_job_id bigint;
begin
    for v_job_id in
        select jobid from cron.job
        where jobname = 'invoke_fetch_exchange_rates'
    loop
        perform cron.unschedule(v_job_id);
    end loop;
end;
$$;

select cron.schedule(
    'invoke_fetch_exchange_rates',
    '0 1 * * *',
    'select public.invoke_fetch_exchange_rates();'
);
