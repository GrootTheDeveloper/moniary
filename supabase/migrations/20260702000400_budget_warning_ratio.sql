alter table if exists public.category_budget_limits
  add column if not exists warning_ratio numeric not null default 0.9
  check (warning_ratio >= 0.5 and warning_ratio <= 1);
