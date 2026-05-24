create extension if not exists pgcrypto;

create type public.wallet_type as enum ('cash', 'bank', 'ewallet', 'credit', 'other');
create type public.transaction_type as enum ('income', 'expense');
create type public.image_upload_status as enum ('pending', 'uploading', 'uploaded', 'failed');
create type public.transaction_source as enum ('manual', 'ocr', 'import');

create table if not exists public.profiles (
    id uuid primary key references auth.users(id) on delete cascade,
    full_name text,
    email text,
    avatar_url text,
    login_provider text not null default 'anonymous',
    timezone text not null default 'Asia/Ho_Chi_Minh',
    created_at timestamptz not null default timezone('utc', now()),
    updated_at timestamptz not null default timezone('utc', now()),
    constraint profiles_timezone_not_blank check (btrim(timezone) <> '')
);

create table if not exists public.wallets (
    id uuid primary key default gen_random_uuid(),
    user_id uuid not null references auth.users(id) on delete cascade,
    name text not null,
    type public.wallet_type not null,
    icon text,
    color text,
    initial_balance numeric(14,2) not null default 0,
    is_default boolean not null default false,
    is_active boolean not null default true,
    created_at timestamptz not null default timezone('utc', now()),
    updated_at timestamptz not null default timezone('utc', now()),
    constraint wallets_name_not_blank check (btrim(name) <> ''),
    constraint wallets_initial_balance_range
        check (initial_balance between -999999999999.99 and 999999999999.99)
);

create unique index if not exists wallets_one_default_per_user_idx
    on public.wallets (user_id)
    where is_default;

create unique index if not exists wallets_user_name_key
    on public.wallets (user_id, lower(name));

create index if not exists wallets_user_created_idx
    on public.wallets (user_id, created_at desc);

create table if not exists public.categories (
    id uuid primary key default gen_random_uuid(),
    user_id uuid not null references auth.users(id) on delete cascade,
    name text not null,
    type public.transaction_type not null,
    icon text,
    color text,
    is_default boolean not null default false,
    is_active boolean not null default true,
    created_at timestamptz not null default timezone('utc', now()),
    updated_at timestamptz not null default timezone('utc', now()),
    constraint categories_name_not_blank check (btrim(name) <> '')
);

create unique index if not exists categories_user_type_name_key
    on public.categories (user_id, type, lower(name));

create index if not exists categories_user_type_active_idx
    on public.categories (user_id, type, is_active, created_at desc);

create table if not exists public.transactions (
    id uuid primary key default gen_random_uuid(),
    user_id uuid not null references auth.users(id) on delete cascade,
    wallet_id uuid not null references public.wallets(id) on delete restrict,
    category_id uuid not null references public.categories(id) on delete restrict,
    amount numeric(14,2) not null,
    type public.transaction_type not null,
    note text,
    image_path text,
    image_upload_status public.image_upload_status not null default 'pending',
    merchant_name text,
    transaction_date timestamptz not null,
    source public.transaction_source not null default 'manual',
    is_important boolean not null default false,
    created_at timestamptz not null default timezone('utc', now()),
    updated_at timestamptz not null default timezone('utc', now()),
    constraint transactions_amount_positive check (amount > 0),
    constraint transactions_image_path_pairing check (
        (image_path is null and image_upload_status in ('pending', 'failed'))
        or (image_path is not null and image_upload_status = 'uploaded')
    )
);

create index if not exists transactions_user_date_idx
    on public.transactions (user_id, transaction_date desc, created_at desc);
create index if not exists transactions_user_wallet_date_idx
    on public.transactions (user_id, wallet_id, transaction_date desc);
create index if not exists transactions_user_category_date_idx
    on public.transactions (user_id, category_id, transaction_date desc);
create index if not exists transactions_user_upload_status_idx
    on public.transactions (user_id, image_upload_status, updated_at desc);

create table if not exists public.notification_settings (
    user_id uuid primary key references auth.users(id) on delete cascade,
    daily_reminder_enabled boolean not null default false,
    daily_reminder_time time,
    weekly_summary_enabled boolean not null default false,
    monthly_summary_enabled boolean not null default false,
    created_at timestamptz not null default timezone('utc', now()),
    updated_at timestamptz not null default timezone('utc', now()),
    constraint notification_daily_time_required check (
        (daily_reminder_enabled = false)
        or (daily_reminder_enabled = true and daily_reminder_time is not null)
    )
);

create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
    new.updated_at = timezone('utc', now());
    return new;
end;
$$;

drop trigger if exists set_profiles_updated_at on public.profiles;
create trigger set_profiles_updated_at
before update on public.profiles
for each row execute function public.set_updated_at();

drop trigger if exists set_wallets_updated_at on public.wallets;
create trigger set_wallets_updated_at
before update on public.wallets
for each row execute function public.set_updated_at();

drop trigger if exists set_categories_updated_at on public.categories;
create trigger set_categories_updated_at
before update on public.categories
for each row execute function public.set_updated_at();

drop trigger if exists set_transactions_updated_at on public.transactions;
create trigger set_transactions_updated_at
before update on public.transactions
for each row execute function public.set_updated_at();

drop trigger if exists set_notification_settings_updated_at on public.notification_settings;
create trigger set_notification_settings_updated_at
before update on public.notification_settings
for each row execute function public.set_updated_at();

alter table public.profiles enable row level security;
alter table public.wallets enable row level security;
alter table public.categories enable row level security;
alter table public.transactions enable row level security;
alter table public.notification_settings enable row level security;

drop policy if exists "profiles_select_own" on public.profiles;
create policy "profiles_select_own"
on public.profiles for select to authenticated
using (id = auth.uid());

drop policy if exists "profiles_insert_own" on public.profiles;
create policy "profiles_insert_own"
on public.profiles for insert to authenticated
with check (id = auth.uid());

drop policy if exists "profiles_update_own" on public.profiles;
create policy "profiles_update_own"
on public.profiles for update to authenticated
using (id = auth.uid())
with check (id = auth.uid());

drop policy if exists "wallets_select_own" on public.wallets;
create policy "wallets_select_own"
on public.wallets for select to authenticated
using (user_id = auth.uid());

drop policy if exists "wallets_insert_own" on public.wallets;
create policy "wallets_insert_own"
on public.wallets for insert to authenticated
with check (user_id = auth.uid());

drop policy if exists "wallets_update_own" on public.wallets;
create policy "wallets_update_own"
on public.wallets for update to authenticated
using (user_id = auth.uid())
with check (user_id = auth.uid());

drop policy if exists "wallets_delete_own" on public.wallets;
create policy "wallets_delete_own"
on public.wallets for delete to authenticated
using (user_id = auth.uid());

drop policy if exists "categories_select_own" on public.categories;
create policy "categories_select_own"
on public.categories for select to authenticated
using (user_id = auth.uid());

drop policy if exists "categories_insert_own" on public.categories;
create policy "categories_insert_own"
on public.categories for insert to authenticated
with check (user_id = auth.uid());

drop policy if exists "categories_update_own" on public.categories;
create policy "categories_update_own"
on public.categories for update to authenticated
using (user_id = auth.uid())
with check (user_id = auth.uid());

drop policy if exists "categories_delete_own" on public.categories;
create policy "categories_delete_own"
on public.categories for delete to authenticated
using (user_id = auth.uid());

drop policy if exists "transactions_select_own" on public.transactions;
create policy "transactions_select_own"
on public.transactions for select to authenticated
using (user_id = auth.uid());

drop policy if exists "transactions_insert_own" on public.transactions;
create policy "transactions_insert_own"
on public.transactions for insert to authenticated
with check (
    user_id = auth.uid()
    and exists (
        select 1
        from public.wallets w
        where w.id = wallet_id
          and w.user_id = auth.uid()
    )
    and exists (
        select 1
        from public.categories c
        where c.id = category_id
          and c.user_id = auth.uid()
          and c.type = transactions.type
    )
);

drop policy if exists "transactions_update_own" on public.transactions;
create policy "transactions_update_own"
on public.transactions for update to authenticated
using (user_id = auth.uid())
with check (
    user_id = auth.uid()
    and exists (
        select 1
        from public.wallets w
        where w.id = wallet_id
          and w.user_id = auth.uid()
    )
    and exists (
        select 1
        from public.categories c
        where c.id = category_id
          and c.user_id = auth.uid()
          and c.type = transactions.type
    )
);

drop policy if exists "transactions_delete_own" on public.transactions;
create policy "transactions_delete_own"
on public.transactions for delete to authenticated
using (user_id = auth.uid());

drop policy if exists "notification_settings_select_own" on public.notification_settings;
create policy "notification_settings_select_own"
on public.notification_settings for select to authenticated
using (user_id = auth.uid());

drop policy if exists "notification_settings_insert_own" on public.notification_settings;
create policy "notification_settings_insert_own"
on public.notification_settings for insert to authenticated
with check (user_id = auth.uid());

drop policy if exists "notification_settings_update_own" on public.notification_settings;
create policy "notification_settings_update_own"
on public.notification_settings for update to authenticated
using (user_id = auth.uid())
with check (user_id = auth.uid());

insert into storage.buckets (id, name, public)
values ('transaction-images', 'transaction-images', false)
on conflict (id) do nothing;

drop policy if exists "storage_select_own_transaction_images" on storage.objects;
create policy "storage_select_own_transaction_images"
on storage.objects for select to authenticated
using (
    bucket_id = 'transaction-images'
    and (storage.foldername(name))[1] = 'transactions'
    and auth.uid()::text = (storage.foldername(name))[2]
);

drop policy if exists "storage_insert_own_transaction_images" on storage.objects;
create policy "storage_insert_own_transaction_images"
on storage.objects for insert to authenticated
with check (
    bucket_id = 'transaction-images'
    and (storage.foldername(name))[1] = 'transactions'
    and auth.uid()::text = (storage.foldername(name))[2]
);

drop policy if exists "storage_update_own_transaction_images" on storage.objects;
create policy "storage_update_own_transaction_images"
on storage.objects for update to authenticated
using (
    bucket_id = 'transaction-images'
    and (storage.foldername(name))[1] = 'transactions'
    and auth.uid()::text = (storage.foldername(name))[2]
)
with check (
    bucket_id = 'transaction-images'
    and (storage.foldername(name))[1] = 'transactions'
    and auth.uid()::text = (storage.foldername(name))[2]
);

drop policy if exists "storage_delete_own_transaction_images" on storage.objects;
create policy "storage_delete_own_transaction_images"
on storage.objects for delete to authenticated
using (
    bucket_id = 'transaction-images'
    and (storage.foldername(name))[1] = 'transactions'
    and auth.uid()::text = (storage.foldername(name))[2]
);

create or replace function public.initialize_user()
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
    v_user_id uuid := auth.uid();
    v_email text;
    v_full_name text;
    v_avatar_url text;
    v_provider text := 'anonymous';
    v_default_wallet_id uuid;
begin
    if v_user_id is null then
        raise exception 'Not authenticated';
    end if;

    select
        u.email,
        coalesce(
            u.raw_user_meta_data ->> 'full_name',
            u.raw_user_meta_data ->> 'name',
            'Guest'
        ),
        u.raw_user_meta_data ->> 'avatar_url',
        coalesce(u.raw_app_meta_data ->> 'provider', 'anonymous')
    into v_email, v_full_name, v_avatar_url, v_provider
    from auth.users u
    where u.id = v_user_id;

    insert into public.profiles (id, full_name, email, avatar_url, login_provider)
    values (v_user_id, v_full_name, v_email, v_avatar_url, v_provider)
    on conflict (id) do update
    set full_name = excluded.full_name,
        email = excluded.email,
        avatar_url = excluded.avatar_url,
        login_provider = excluded.login_provider;

    insert into public.notification_settings (user_id)
    values (v_user_id)
    on conflict (user_id) do nothing;

    insert into public.wallets
        (user_id, name, type, icon, color, initial_balance, is_default)
    select v_user_id, 'Tiền mặt', 'cash', 'wallet', '#4CAF50', 0, true
    where not exists (
        select 1
        from public.wallets w
        where w.user_id = v_user_id
          and lower(w.name) = lower('Tiền mặt')
    );

    select id into v_default_wallet_id
    from public.wallets
    where user_id = v_user_id
      and is_default = true
    order by created_at asc
    limit 1;

    insert into public.categories
        (user_id, name, type, icon, color, is_default)
    values
        (v_user_id, 'Ăn uống', 'expense', 'restaurant', '#FF7043', true),
        (v_user_id, 'Di chuyển', 'expense', 'directions_bus', '#42A5F5', true),
        (v_user_id, 'Mua sắm', 'expense', 'shopping_bag', '#AB47BC', true),
        (v_user_id, 'Hóa đơn', 'expense', 'receipt_long', '#FFA726', true),
        (v_user_id, 'Lương', 'income', 'payments', '#66BB6A', true),
        (v_user_id, 'Thưởng', 'income', 'savings', '#26A69A', true),
        (v_user_id, 'Khác', 'income', 'more_horiz', '#78909C', true)
    on conflict (user_id, type, lower(name)) do nothing;

    return jsonb_build_object(
        'userId', v_user_id,
        'defaultWalletId', v_default_wallet_id,
        'initialized', true
    );
end;
$$;

revoke all on function public.initialize_user() from public;
grant execute on function public.initialize_user() to authenticated;
