-- Account deletion starts as a reversible 30-day soft delete.
-- Scheduling and permanent deletion are configured by a later hardening
-- migration so no project URL or credential is embedded in source control.
alter table public.profiles add column if not exists deleted_at timestamptz;
