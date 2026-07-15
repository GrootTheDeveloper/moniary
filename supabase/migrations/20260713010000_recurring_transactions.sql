-- Recurring transactions & subscriptions.
-- Restored from the remote migration history so local and remote versions
-- remain deterministic for future Supabase CLI pushes.

create table if not exists public.recurring_transactions (
    id uuid primary key default gen_random_uuid(),
    user_id uuid not null references auth.users(id) on delete cascade,
    wallet_id uuid not null references public.wallets(id) on delete cascade,
    category_id uuid not null references public.categories(id) on delete cascade,
    amount numeric(14, 2) not null,
    type public.transaction_type not null,
    note text,
    frequency text not null,
    interval integer not null default 1,
    start_date date not null,
    next_run_date date not null,
    end_date date,
    auto_post boolean not null default false,
    is_active boolean not null default true,
    last_run_date date,
    created_at timestamptz not null default timezone('utc', now()),
    updated_at timestamptz not null default timezone('utc', now()),
    constraint recurring_transactions_amount_positive check (amount > 0),
    constraint recurring_transactions_frequency_valid
        check (frequency in ('daily', 'weekly', 'monthly', 'yearly')),
    constraint recurring_transactions_interval_positive check (interval >= 1),
    constraint recurring_transactions_end_after_start
        check (end_date is null or end_date >= start_date)
);

create index if not exists recurring_transactions_user_next_run_idx
    on public.recurring_transactions (user_id, is_active, next_run_date);

drop trigger if exists set_recurring_transactions_updated_at
    on public.recurring_transactions;
create trigger set_recurring_transactions_updated_at
before update on public.recurring_transactions
for each row execute function public.set_updated_at();

alter table public.recurring_transactions enable row level security;

drop policy if exists "recurring_transactions_select_own"
    on public.recurring_transactions;
create policy "recurring_transactions_select_own"
on public.recurring_transactions for select to authenticated
using (user_id = auth.uid());

drop policy if exists "recurring_transactions_insert_own"
    on public.recurring_transactions;
create policy "recurring_transactions_insert_own"
on public.recurring_transactions for insert to authenticated
with check (
    user_id = auth.uid()
    and exists (
        select 1 from public.wallets w
        where w.id = wallet_id and w.user_id = auth.uid()
    )
    and exists (
        select 1 from public.categories c
        where c.id = category_id
          and c.user_id = auth.uid()
          and c.type = recurring_transactions.type
    )
);

drop policy if exists "recurring_transactions_update_own"
    on public.recurring_transactions;
create policy "recurring_transactions_update_own"
on public.recurring_transactions for update to authenticated
using (user_id = auth.uid())
with check (
    user_id = auth.uid()
    and exists (
        select 1 from public.wallets w
        where w.id = wallet_id and w.user_id = auth.uid()
    )
    and exists (
        select 1 from public.categories c
        where c.id = category_id
          and c.user_id = auth.uid()
          and c.type = recurring_transactions.type
    )
);

drop policy if exists "recurring_transactions_delete_own"
    on public.recurring_transactions;
create policy "recurring_transactions_delete_own"
on public.recurring_transactions for delete to authenticated
using (user_id = auth.uid());
