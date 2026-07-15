-- Link auto-posted transactions back to the recurring rule that created them,
-- so a rule edit can update or delete its previously generated transactions.
-- Deleting a rule keeps its transactions (history) and just nulls the link.
alter table public.transactions
    add column if not exists recurring_transaction_id uuid
    references public.recurring_transactions(id) on delete set null;

create index if not exists transactions_recurring_id_idx
    on public.transactions (recurring_transaction_id);
