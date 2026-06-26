create table if not exists public.account_deletion_feedback (
  id uuid primary key default gen_random_uuid(),
  reason_code text not null check (
    reason_code in (
      'difficult_to_use',
      'missing_features',
      'technical_issues',
      'privacy_concerns',
      'no_longer_needed',
      'other'
    )
  ),
  details text check (details is null or char_length(details) <= 500),
  app_version text not null,
  platform text not null,
  locale text not null,
  created_at timestamptz not null default now()
);

alter table public.account_deletion_feedback enable row level security;

comment on table public.account_deletion_feedback is
  'Identity-free product feedback captured when an authenticated user requests account deletion.';
