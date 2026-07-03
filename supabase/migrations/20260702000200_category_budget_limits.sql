create table if not exists public.category_budget_limits (
    id uuid primary key default gen_random_uuid(),
    user_id uuid not null references auth.users(id) on delete cascade,
    category_id uuid not null references public.categories(id) on delete cascade,
    month_start date not null,
    limit_amount numeric(14,2) not null,
    created_at timestamptz not null default timezone('utc', now()),
    updated_at timestamptz not null default timezone('utc', now()),
    constraint category_budget_limits_positive check (limit_amount > 0),
    constraint category_budget_limits_month_start check (
        month_start = date_trunc('month', month_start)::date
    ),
    constraint category_budget_limits_unique
        unique (user_id, category_id, month_start)
);

create index if not exists category_budget_limits_user_month_idx
    on public.category_budget_limits (user_id, month_start);

drop trigger if exists set_category_budget_limits_updated_at
    on public.category_budget_limits;
create trigger set_category_budget_limits_updated_at
before update on public.category_budget_limits
for each row execute function public.set_updated_at();

alter table public.category_budget_limits enable row level security;

drop policy if exists "category_budget_limits_select_own"
    on public.category_budget_limits;
create policy "category_budget_limits_select_own"
on public.category_budget_limits for select to authenticated
using (user_id = auth.uid());

drop policy if exists "category_budget_limits_insert_own"
    on public.category_budget_limits;
create policy "category_budget_limits_insert_own"
on public.category_budget_limits for insert to authenticated
with check (
    user_id = auth.uid()
    and exists (
        select 1
        from public.categories c
        where c.id = category_id
          and c.user_id = auth.uid()
          and c.type = 'expense'
    )
);

drop policy if exists "category_budget_limits_update_own"
    on public.category_budget_limits;
create policy "category_budget_limits_update_own"
on public.category_budget_limits for update to authenticated
using (user_id = auth.uid())
with check (
    user_id = auth.uid()
    and exists (
        select 1
        from public.categories c
        where c.id = category_id
          and c.user_id = auth.uid()
          and c.type = 'expense'
    )
);

drop policy if exists "category_budget_limits_delete_own"
    on public.category_budget_limits;
create policy "category_budget_limits_delete_own"
on public.category_budget_limits for delete to authenticated
using (user_id = auth.uid());
