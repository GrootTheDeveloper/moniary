-- Remove abandoned anonymous Auth users so they do not accumulate forever.
-- Accounts upgraded to email or OAuth are preserved because is_anonymous is false.

create extension if not exists pg_cron;

create or replace function public.cleanup_stale_anonymous_users(
    p_inactive_for interval default interval '30 days'
)
returns bigint
language plpgsql
security definer
set search_path = ''
as $$
declare
    v_deleted_count bigint;
begin
    if p_inactive_for < interval '7 days' then
        raise exception 'Anonymous account retention must be at least 7 days';
    end if;

    delete from auth.users as auth_user
    where auth_user.is_anonymous is true
      and coalesce(auth_user.last_sign_in_at, auth_user.created_at)
          < now() - p_inactive_for
      and not exists (
          select 1
          from auth.sessions as auth_session
          where auth_session.user_id = auth_user.id
            and coalesce(auth_session.updated_at, auth_session.created_at)
                >= now() - p_inactive_for
      );

    get diagnostics v_deleted_count = row_count;
    return v_deleted_count;
end;
$$;

revoke all on function public.cleanup_stale_anonymous_users(interval)
from public, anon, authenticated;

do $$
declare
    v_job_id bigint;
begin
    select jobid
    into v_job_id
    from cron.job
    where jobname = 'cleanup_stale_anonymous_users';

    if v_job_id is not null then
        perform cron.unschedule(v_job_id);
    end if;
end;
$$;

select cron.schedule(
    'cleanup_stale_anonymous_users',
    '15 3 * * *',
    $job$select public.cleanup_stale_anonymous_users(interval '30 days');$job$
);
