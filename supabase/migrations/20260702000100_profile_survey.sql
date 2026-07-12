alter table public.profiles
    add column if not exists occupation text,
    add column if not exists preferred_currency text not null default 'VND',
    add column if not exists survey_completed_at timestamptz;

update public.profiles
set survey_completed_at = coalesce(survey_completed_at, created_at)
where survey_completed_at is null;

alter table public.profiles
    drop constraint if exists profiles_occupation_allowed;
alter table public.profiles
    add constraint profiles_occupation_allowed check (
        occupation is null
        or occupation in (
            'student',
            'office_worker',
            'freelancer',
            'business_owner',
            'other'
        )
    );

alter table public.profiles
    drop constraint if exists profiles_preferred_currency_allowed;
alter table public.profiles
    add constraint profiles_preferred_currency_allowed check (
        preferred_currency in ('VND', 'USD', 'VGO')
    );
