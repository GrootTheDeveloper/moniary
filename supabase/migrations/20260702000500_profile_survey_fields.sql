alter table if exists public.profiles
    add column if not exists occupation text,
    add column if not exists preferred_currency text not null default 'VND';

do $$
begin
    if not exists (
        select 1
        from pg_constraint
        where conname = 'profiles_preferred_currency_not_blank'
    ) then
        alter table public.profiles
            add constraint profiles_preferred_currency_not_blank
            check (btrim(preferred_currency) <> '');
    end if;
end $$;
