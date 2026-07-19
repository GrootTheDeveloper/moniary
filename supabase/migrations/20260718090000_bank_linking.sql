-- Bank linking (aggregator-agnostic): a catalog of supported institutions,
-- per-user connections, and staged transactions pending user confirmation
-- before they are copied into public.transactions. No aggregator is wired up
-- yet; bank_sync_transactions rows are only ever written server-side once a
-- provider is integrated, so regular users may read and update (confirm or
-- dismiss) their own rows but never insert or delete them directly.

create table if not exists public.bank_institutions (
  id uuid primary key default gen_random_uuid(),
  slug text not null unique,
  name text not null,
  logo_url text,
  is_supported boolean not null default true,
  created_at timestamptz not null default timezone('utc', now())
);

alter table public.bank_institutions enable row level security;

drop policy if exists "bank_institutions_select_all" on public.bank_institutions;
create policy "bank_institutions_select_all"
  on public.bank_institutions
  for select
  to authenticated
  using (true);

insert into public.bank_institutions (slug, name, is_supported)
values
  ('vietcombank', 'Vietcombank', true),
  ('techcombank', 'Techcombank', true),
  ('mbbank', 'MB Bank', true),
  ('acb', 'ACB', true),
  ('bidv', 'BIDV', true)
on conflict (slug) do nothing;

create table if not exists public.bank_connections (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  institution_id uuid not null references public.bank_institutions(id),
  institution_name text not null,
  institution_logo_url text,
  masked_account_number text,
  status text not null default 'pending'
    check (status in ('pending', 'connected', 'error', 'revoked')),
  provider text not null default 'unconfigured',
  last_synced_at timestamptz,
  last_error text,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now())
);

create index if not exists bank_connections_user_id_idx
  on public.bank_connections (user_id, created_at desc);

drop trigger if exists set_bank_connections_updated_at on public.bank_connections;
create trigger set_bank_connections_updated_at
  before update on public.bank_connections
  for each row execute function public.set_updated_at();

alter table public.bank_connections enable row level security;

drop policy if exists "bank_connections_select_own" on public.bank_connections;
create policy "bank_connections_select_own"
  on public.bank_connections
  for select
  to authenticated
  using (user_id = auth.uid());

drop policy if exists "bank_connections_insert_own" on public.bank_connections;
create policy "bank_connections_insert_own"
  on public.bank_connections
  for insert
  to authenticated
  with check (user_id = auth.uid());

drop policy if exists "bank_connections_update_own" on public.bank_connections;
create policy "bank_connections_update_own"
  on public.bank_connections
  for update
  to authenticated
  using (user_id = auth.uid())
  with check (user_id = auth.uid());

drop policy if exists "bank_connections_delete_own" on public.bank_connections;
create policy "bank_connections_delete_own"
  on public.bank_connections
  for delete
  to authenticated
  using (user_id = auth.uid());

create table if not exists public.bank_sync_transactions (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  bank_connection_id uuid not null
    references public.bank_connections(id) on delete cascade,
  external_transaction_id text not null,
  amount numeric not null check (amount > 0),
  type text not null check (type in ('income', 'expense')),
  transaction_date timestamptz not null,
  merchant_name text,
  raw_description text,
  status text not null default 'pending'
    check (status in ('pending', 'confirmed', 'dismissed')),
  confirmed_transaction_id uuid references public.transactions(id) on delete set null,
  created_at timestamptz not null default timezone('utc', now()),
  unique (bank_connection_id, external_transaction_id)
);

create index if not exists bank_sync_transactions_user_status_idx
  on public.bank_sync_transactions (user_id, status, transaction_date desc);

alter table public.bank_sync_transactions enable row level security;

drop policy if exists "bank_sync_transactions_select_own" on public.bank_sync_transactions;
create policy "bank_sync_transactions_select_own"
  on public.bank_sync_transactions
  for select
  to authenticated
  using (user_id = auth.uid());

drop policy if exists "bank_sync_transactions_update_own" on public.bank_sync_transactions;
create policy "bank_sync_transactions_update_own"
  on public.bank_sync_transactions
  for update
  to authenticated
  using (user_id = auth.uid())
  with check (user_id = auth.uid());
