create table if not exists public.journal_collections (
    id uuid primary key default gen_random_uuid(),
    user_id uuid not null references auth.users(id) on delete cascade,
    name text not null,
    start_date date,
    end_date date,
    created_at timestamptz not null default timezone('utc', now()),
    updated_at timestamptz not null default timezone('utc', now()),
    constraint journal_collections_name_not_blank check (btrim(name) <> ''),
    constraint journal_collections_date_order check (
        start_date is null or end_date is null or start_date <= end_date
    )
);

create index if not exists journal_collections_user_created_idx
    on public.journal_collections (user_id, created_at desc);

create table if not exists public.journal_collection_transactions (
    collection_id uuid not null
        references public.journal_collections(id) on delete cascade,
    transaction_id uuid not null
        references public.transactions(id) on delete cascade,
    user_id uuid not null references auth.users(id) on delete cascade,
    created_at timestamptz not null default timezone('utc', now()),
    primary key (collection_id, transaction_id)
);

create index if not exists journal_collection_transactions_user_idx
    on public.journal_collection_transactions (user_id, collection_id);

drop trigger if exists set_journal_collections_updated_at
    on public.journal_collections;
create trigger set_journal_collections_updated_at
before update on public.journal_collections
for each row execute function public.set_updated_at();

alter table public.journal_collections enable row level security;
alter table public.journal_collection_transactions enable row level security;

drop policy if exists "journal_collections_select_own"
    on public.journal_collections;
create policy "journal_collections_select_own"
on public.journal_collections for select to authenticated
using (user_id = auth.uid());

drop policy if exists "journal_collections_insert_own"
    on public.journal_collections;
create policy "journal_collections_insert_own"
on public.journal_collections for insert to authenticated
with check (user_id = auth.uid());

drop policy if exists "journal_collections_update_own"
    on public.journal_collections;
create policy "journal_collections_update_own"
on public.journal_collections for update to authenticated
using (user_id = auth.uid())
with check (user_id = auth.uid());

drop policy if exists "journal_collections_delete_own"
    on public.journal_collections;
create policy "journal_collections_delete_own"
on public.journal_collections for delete to authenticated
using (user_id = auth.uid());

drop policy if exists "journal_collection_transactions_select_own"
    on public.journal_collection_transactions;
create policy "journal_collection_transactions_select_own"
on public.journal_collection_transactions for select to authenticated
using (user_id = auth.uid());

drop policy if exists "journal_collection_transactions_insert_own"
    on public.journal_collection_transactions;
create policy "journal_collection_transactions_insert_own"
on public.journal_collection_transactions for insert to authenticated
with check (
    user_id = auth.uid()
    and exists (
        select 1
        from public.journal_collections c
        where c.id = collection_id
          and c.user_id = auth.uid()
    )
    and exists (
        select 1
        from public.transactions t
        where t.id = transaction_id
          and t.user_id = auth.uid()
    )
);

drop policy if exists "journal_collection_transactions_delete_own"
    on public.journal_collection_transactions;
create policy "journal_collection_transactions_delete_own"
on public.journal_collection_transactions for delete to authenticated
using (user_id = auth.uid());
