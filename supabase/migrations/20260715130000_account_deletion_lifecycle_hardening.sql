-- Complete the 30-day account-deletion lifecycle without embedding project
-- credentials in migration source. Shared group ledger rows keep a scrubbed
-- profile tombstone so historical balances remain referentially valid.

create extension if not exists pg_cron;
create extension if not exists pg_net;

-- A hard-deleted auth user must not cascade through shared group ledgers. An
-- active profile is still created from auth.users by the existing auth trigger;
-- only a scrubbed profile with deleted_at set may outlive its auth user.
do $$
declare
    v_constraint record;
begin
    for v_constraint in
        select conname
        from pg_constraint
        where conrelid = 'public.profiles'::regclass
          and contype = 'f'
          and confrelid = 'auth.users'::regclass
    loop
        execute format(
            'alter table public.profiles drop constraint %I',
            v_constraint.conname
        );
    end loop;
end
$$;

create or replace function public.enforce_active_profile_auth_user()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
    if new.deleted_at is null
       and not exists (select 1 from auth.users where id = new.id) then
        raise exception 'ACTIVE_PROFILE_REQUIRES_AUTH_USER';
    end if;
    return new;
end;
$$;

drop trigger if exists enforce_active_profile_auth_user on public.profiles;
create constraint trigger enforce_active_profile_auth_user
after insert or update of id, deleted_at on public.profiles
deferrable initially deferred
for each row execute function public.enforce_active_profile_auth_user();

create or replace function public.guard_profile_deleted_at_transition()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
    if old.deleted_at is not distinct from new.deleted_at then
        return new;
    end if;
    if auth.role() = 'service_role' then
        return new;
    end if;
    if old.deleted_at is not null
       and new.deleted_at is null
       and current_setting('app.account_restore_allowed', true) = 'true' then
        return new;
    end if;
    raise exception 'ACCOUNT_DELETION_STATE_CHANGE_FORBIDDEN';
end;
$$;

drop trigger if exists guard_profile_deleted_at_transition
on public.profiles;
create trigger guard_profile_deleted_at_transition
before update of deleted_at on public.profiles
for each row execute function public.guard_profile_deleted_at_transition();

create or replace function public.restore_deleted_account()
returns timestamptz
language plpgsql
security definer
set search_path = ''
as $$
declare
    v_user_id uuid := auth.uid();
    v_deleted_at timestamptz;
begin
    if v_user_id is null then
        raise exception 'AUTH_REQUIRED';
    end if;

    select deleted_at
    into v_deleted_at
    from public.profiles
    where id = v_user_id
    for update;

    if not found then
        raise exception 'PROFILE_NOT_FOUND';
    end if;
    if v_deleted_at is null then
        return null;
    end if;
    if v_deleted_at <= now() - interval '30 days' then
        raise exception 'ACCOUNT_RESTORE_EXPIRED';
    end if;

    perform set_config('app.account_restore_allowed', 'true', true);
    update public.profiles
    set deleted_at = null
    where id = v_user_id;

    return v_deleted_at;
end;
$$;

revoke all on function public.restore_deleted_account() from public;
grant execute on function public.restore_deleted_account() to authenticated;

create or replace function public.prepare_account_for_hard_delete(
    p_user_id uuid
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
    v_group_id uuid;
    v_replacement_user_id uuid;
begin
    if auth.role() <> 'service_role' then
        raise exception 'SERVICE_ROLE_REQUIRED';
    end if;

    perform 1
    from public.profiles
    where id = p_user_id
      and deleted_at <= now() - interval '30 days'
    for update;

    if not found then
        raise exception 'ACCOUNT_NOT_READY_FOR_HARD_DELETE';
    end if;

    -- Transfer groups to another active member. Sole-member groups contain no
    -- data belonging to another account and can be removed completely.
    for v_group_id in
        select distinct g.id
        from public.groups g
        left join public.group_members owner_member
          on owner_member.group_id = g.id
         and owner_member.user_id = p_user_id
         and owner_member.role = 'owner'
        where g.created_by = p_user_id
           or owner_member.user_id is not null
    loop
        select member.user_id
        into v_replacement_user_id
        from public.group_members member
        where member.group_id = v_group_id
          and member.user_id <> p_user_id
          and member.status = 'active'
        order by
            case member.role when 'admin' then 0 else 1 end,
            member.joined_at,
            member.user_id
        limit 1;

        if v_replacement_user_id is null then
            delete from public.groups where id = v_group_id;
        else
            update public.group_members
            set role = 'member',
                status = 'left',
                left_at = coalesce(left_at, timezone('utc', now()))
            where group_id = v_group_id
              and user_id = p_user_id;

            update public.group_members
            set role = 'owner',
                status = 'active',
                left_at = null
            where group_id = v_group_id
              and user_id = v_replacement_user_id;

            update public.groups
            set created_by = v_replacement_user_id
            where id = v_group_id;
        end if;
    end loop;

    update public.group_members
    set role = 'member',
        status = 'left',
        left_at = coalesce(left_at, timezone('utc', now()))
    where user_id = p_user_id
      and status <> 'left';

    update public.group_recurring_transactions
    set is_active = false
    where created_by = p_user_id;

    delete from public.friend_requests
    where from_user_id = p_user_id or to_user_id = p_user_id;
    delete from public.friendships
    where user_id = p_user_id or friend_user_id = p_user_id;
    delete from public.friend_invite_links
    where creator_user_id = p_user_id or used_by_user_id = p_user_id;
    delete from public.group_invites
    where invited_user_id = p_user_id or invited_by = p_user_id;
    delete from public.group_notification_preferences where user_id = p_user_id;
    delete from public.group_transaction_reactions where user_id = p_user_id;
    delete from public.group_comment_mentions where mentioned_user_id = p_user_id;
    delete from public.group_notifications where user_id = p_user_id;
    delete from public.notification_outbox where user_id = p_user_id;
    delete from public.notification_delivery_preferences where user_id = p_user_id;
    delete from public.notification_devices where user_id = p_user_id;
    delete from public.app_notifications where user_id = p_user_id;

    update public.profiles
    set full_name = 'Deleted account',
        email = null,
        avatar_url = null,
        login_provider = 'deleted',
        timezone = 'UTC',
        username = null,
        occupation = null,
        preferred_currency = 'VND',
        survey_completed_at = null,
        payment_qr_path = null,
        updated_at = timezone('utc', now())
    where id = p_user_id;
end;
$$;

revoke all on function public.prepare_account_for_hard_delete(uuid)
from public, anon, authenticated;
grant execute on function public.prepare_account_for_hard_delete(uuid)
to service_role;

alter table public.account_deletion_feedback
    drop constraint if exists account_deletion_feedback_context_length;
alter table public.account_deletion_feedback
    add constraint account_deletion_feedback_context_length check (
        char_length(app_version) between 1 and 64
        and char_length(platform) between 1 and 32
        and char_length(locale) between 1 and 32
    );

-- Values are read from Supabase Vault at execution time. Before enabling the
-- job, create `project_url` and `garbage_collect_secret` Vault entries and set
-- the same secret as the Edge Function's GARBAGE_COLLECT_SECRET.
create or replace function public.invoke_garbage_collect()
returns bigint
language plpgsql
security definer
set search_path = ''
as $$
declare
    v_project_url text;
    v_cron_secret text;
    v_request_id bigint;
begin
    select decrypted_secret
    into v_project_url
    from vault.decrypted_secrets
    where name = 'project_url'
    limit 1;

    select decrypted_secret
    into v_cron_secret
    from vault.decrypted_secrets
    where name = 'garbage_collect_secret'
    limit 1;

    if nullif(btrim(v_project_url), '') is null
       or nullif(btrim(v_cron_secret), '') is null then
        raise exception 'ACCOUNT_CLEANUP_VAULT_SECRETS_MISSING';
    end if;

    select net.http_post(
        url := rtrim(v_project_url, '/') || '/functions/v1/garbage-collect',
        headers := jsonb_build_object(
            'Content-Type', 'application/json',
            'x-cron-secret', v_cron_secret
        ),
        body := '{}'::jsonb,
        timeout_milliseconds := 5000
    )
    into v_request_id;

    return v_request_id;
end;
$$;

revoke all on function public.invoke_garbage_collect()
from public, anon, authenticated;

select cron.unschedule(jobid)
from cron.job
where jobname in ('invoke_garbage_collect', 'garbage_collect_expired_accounts');

select cron.schedule(
    'garbage_collect_expired_accounts',
    '0 2 * * *',
    'select public.invoke_garbage_collect();'
);
