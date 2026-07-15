-- Unified notification inbox, 30-day retention, and push-device registration.
-- Existing group_notifications remain the source for Group/Community history
-- during the compatibility phase; list_all_notifications normalizes both
-- stores for the Flutter notification center.

create table if not exists public.app_notifications (
    id uuid primary key default gen_random_uuid(),
    user_id uuid not null references public.profiles(id) on delete cascade,
    category text not null,
    type text not null,
    actor_user_id uuid references public.profiles(id) on delete set null,
    group_id uuid references public.groups(id) on delete cascade,
    group_transaction_id uuid references public.group_transactions(id) on delete cascade,
    friend_request_id uuid references public.friend_requests(id) on delete cascade,
    metadata jsonb not null default '{}'::jsonb,
    is_read boolean not null default false,
    read_at timestamptz,
    created_at timestamptz not null default timezone('utc', now()),
    expires_at timestamptz not null default timezone('utc', now()) + interval '30 days',
    constraint app_notifications_category_check
        check (category in ('personal', 'group', 'community', 'system')),
    constraint app_notifications_read_at_check
        check ((is_read and read_at is not null) or (not is_read))
);

create index if not exists app_notifications_user_created_idx
    on public.app_notifications (user_id, created_at desc);
create index if not exists app_notifications_user_unread_idx
    on public.app_notifications (user_id, is_read, created_at desc);
create unique index if not exists app_notifications_dedup_key_idx
    on public.app_notifications (user_id, (metadata ->> 'dedup_key'))
    where metadata ? 'dedup_key';

alter table public.app_notifications enable row level security;

drop policy if exists "app_notifications_select_own" on public.app_notifications;
create policy "app_notifications_select_own"
on public.app_notifications for select to authenticated
using (user_id = auth.uid());

drop policy if exists "app_notifications_update_own" on public.app_notifications;
create policy "app_notifications_update_own"
on public.app_notifications for update to authenticated
using (user_id = auth.uid())
with check (user_id = auth.uid());

create table if not exists public.notification_devices (
    id uuid primary key default gen_random_uuid(),
    user_id uuid not null references public.profiles(id) on delete cascade,
    device_token text not null,
    platform text not null,
    locale text not null default 'vi_VN',
    timezone text not null default 'Asia/Ho_Chi_Minh',
    is_active boolean not null default true,
    last_seen_at timestamptz not null default timezone('utc', now()),
    created_at timestamptz not null default timezone('utc', now()),
    updated_at timestamptz not null default timezone('utc', now()),
    constraint notification_devices_platform_check
        check (platform in ('android', 'ios'))
);

create unique index if not exists notification_devices_token_idx
    on public.notification_devices (device_token);
create index if not exists notification_devices_user_active_idx
    on public.notification_devices (user_id, is_active);

alter table public.notification_devices enable row level security;

drop policy if exists "notification_devices_select_own" on public.notification_devices;
create policy "notification_devices_select_own"
on public.notification_devices for select to authenticated
using (user_id = auth.uid());

create table if not exists public.notification_delivery_preferences (
    user_id uuid primary key references public.profiles(id) on delete cascade,
    push_enabled boolean not null default true,
    personal_enabled boolean not null default true,
    group_enabled boolean not null default true,
    community_enabled boolean not null default true,
    system_enabled boolean not null default true,
    updated_at timestamptz not null default timezone('utc', now())
);

alter table public.notification_delivery_preferences enable row level security;

drop policy if exists "notification_delivery_preferences_select_own"
    on public.notification_delivery_preferences;
create policy "notification_delivery_preferences_select_own"
on public.notification_delivery_preferences for select to authenticated
using (user_id = auth.uid());

drop policy if exists "notification_delivery_preferences_upsert_own"
    on public.notification_delivery_preferences;
create policy "notification_delivery_preferences_upsert_own"
on public.notification_delivery_preferences for all to authenticated
using (user_id = auth.uid())
with check (user_id = auth.uid());

create table if not exists public.notification_outbox (
    id uuid primary key default gen_random_uuid(),
    source text not null,
    notification_id uuid not null,
    user_id uuid not null references public.profiles(id) on delete cascade,
    category text not null,
    type text not null,
    group_id uuid,
    metadata jsonb not null default '{}'::jsonb,
    attempt_count integer not null default 0,
    next_attempt_at timestamptz not null default timezone('utc', now()),
    sent_at timestamptz,
    last_error text,
    created_at timestamptz not null default timezone('utc', now()),
    constraint notification_outbox_source_check check (source in ('app', 'group'))
);

create unique index if not exists notification_outbox_source_notification_idx
    on public.notification_outbox (source, notification_id);
create index if not exists notification_outbox_pending_idx
    on public.notification_outbox (next_attempt_at, created_at)
    where sent_at is null;
alter table public.notification_outbox enable row level security;

create or replace function public.enqueue_app_notification()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
    insert into public.notification_outbox (
        source, notification_id, user_id, category, type, group_id, metadata
    ) values (
        'app', new.id, new.user_id, new.category, new.type, new.group_id,
        new.metadata
    ) on conflict (source, notification_id) do nothing;
    return new;
end;
$$;

drop trigger if exists enqueue_app_notification on public.app_notifications;
create trigger enqueue_app_notification
after insert on public.app_notifications
for each row execute function public.enqueue_app_notification();

create or replace function public.enqueue_group_notification()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
    insert into public.notification_outbox (
        source, notification_id, user_id, category, type, group_id, metadata
    ) values (
        'group', new.id, new.user_id, new.category, new.type, new.group_id,
        jsonb_build_object('group_transaction_id', new.group_transaction_id)
    ) on conflict (source, notification_id) do nothing;
    return new;
end;
$$;

drop trigger if exists enqueue_group_notification on public.group_notifications;
create trigger enqueue_group_notification
after insert on public.group_notifications
for each row execute function public.enqueue_group_notification();

create or replace function public.notification_push_allowed(
    p_user_id uuid,
    p_category text,
    p_group_id uuid default null,
    p_type text default null
)
returns boolean
language plpgsql
stable
security definer
set search_path = public
as $$
declare
    v_pref public.notification_delivery_preferences%rowtype;
begin
    select * into v_pref
    from public.notification_delivery_preferences
    where user_id = p_user_id;

    if found and not v_pref.push_enabled then return false; end if;
    if found and p_category = 'personal' and not v_pref.personal_enabled then return false; end if;
    if found and p_category = 'group' and not v_pref.group_enabled then return false; end if;
    if found and p_category = 'community' and not v_pref.community_enabled then return false; end if;
    if found and p_category = 'system' and not v_pref.system_enabled then return false; end if;

    if p_group_id is not null and p_category in ('group', 'community') then
        return public.group_notification_enabled(
            p_group_id,
            p_user_id,
            coalesce(p_type, '')
        );
    end if;
    return true;
end;
$$;

-- Mute preferences control push delivery, not inbox persistence. The legacy
-- Group trigger used to return NULL for muted events, which would erase them
-- from history. Keep the trigger for compatibility but always retain events.
create or replace function public.filter_group_notification_by_preference()
returns trigger
language plpgsql
as $$
begin
    return new;
end;
$$;

create or replace function public.create_app_notification(
    p_user_id uuid,
    p_category text,
    p_type text,
    p_actor_user_id uuid default null,
    p_group_id uuid default null,
    p_group_transaction_id uuid default null,
    p_friend_request_id uuid default null,
    p_metadata jsonb default '{}'::jsonb
)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
    v_id uuid;
begin
    if p_user_id is null or p_category not in ('personal', 'group', 'community', 'system') then
        raise exception 'NOTIFICATION_INVALID_PAYLOAD';
    end if;

    insert into public.app_notifications (
        user_id,
        category,
        type,
        actor_user_id,
        group_id,
        group_transaction_id,
        friend_request_id,
        metadata
    ) values (
        p_user_id,
        p_category,
        p_type,
        p_actor_user_id,
        p_group_id,
        p_group_transaction_id,
        p_friend_request_id,
        coalesce(p_metadata, '{}'::jsonb)
    )
    on conflict do nothing
    returning id into v_id;

    return v_id;
end;
$$;

create or replace function public.notify_friend_request_event()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
    if tg_op = 'INSERT' then
        perform public.create_app_notification(
            new.to_user_id,
            'personal',
            'friend_request',
            new.from_user_id,
            null,
            null,
            new.id,
            jsonb_build_object('dedup_key', 'friend_request:' || new.id::text)
        );
    elsif tg_op = 'UPDATE'
       and old.status = 'pending'
       and new.status = 'accepted' then
        perform public.create_app_notification(
            new.from_user_id,
            'personal',
            'friend_request_accepted',
            new.to_user_id,
            null,
            null,
            new.id,
            jsonb_build_object('dedup_key', 'friend_request_accepted:' || new.id::text)
        );
    end if;
    return new;
end;
$$;

drop trigger if exists notify_friend_request_event on public.friend_requests;
create trigger notify_friend_request_event
after insert or update of status on public.friend_requests
for each row execute function public.notify_friend_request_event();

create or replace function public.list_all_notifications(p_category text default null)
returns table (
    id uuid,
    category text,
    type text,
    group_id uuid,
    group_name text,
    group_transaction_id uuid,
    friend_request_id uuid,
    metadata jsonb,
    is_read boolean,
    created_at timestamptz,
    source text
)
language sql
stable
security definer
set search_path = public
as $$
    select
        an.id,
        an.category,
        an.type,
        an.group_id,
        g.name as group_name,
        an.group_transaction_id,
        an.friend_request_id,
        an.metadata,
        an.is_read,
        an.created_at,
        'app'::text as source
    from public.app_notifications an
    left join public.groups g on g.id = an.group_id
    where an.user_id = auth.uid()
      and an.created_at >= timezone('utc', now()) - interval '30 days'
      and an.expires_at > timezone('utc', now())
      and (p_category is null or an.category = p_category)

    union all

    select
        gn.id,
        gn.category,
        case gn.type
            when 'member_amount_input_required' then 'member_amount_required'
            when 'group_transaction_posted' then 'transaction_posted'
            else gn.type
        end as type,
        gn.group_id,
        g.name as group_name,
        gn.group_transaction_id,
        null::uuid as friend_request_id,
        '{}'::jsonb as metadata,
        gn.is_read,
        gn.created_at,
        'group'::text as source
    from public.group_notifications gn
    join public.groups g on g.id = gn.group_id
    where gn.user_id = auth.uid()
      and gn.created_at >= timezone('utc', now()) - interval '30 days'
      and (p_category is null or gn.category = p_category)
    order by created_at desc
    limit 100;
$$;

create or replace function public.mark_notification_read(p_notification_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
    update public.app_notifications
    set is_read = true,
        read_at = timezone('utc', now())
    where id = p_notification_id
      and user_id = auth.uid()
      and not is_read;

    update public.group_notifications
    set is_read = true
    where id = p_notification_id
      and user_id = auth.uid()
      and not is_read;
end;
$$;

create or replace function public.mark_all_notifications_read()
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
    update public.app_notifications
    set is_read = true,
        read_at = timezone('utc', now())
    where user_id = auth.uid()
      and not is_read
      and expires_at > timezone('utc', now());

    update public.group_notifications
    set is_read = true
    where user_id = auth.uid()
      and not is_read
      and created_at >= timezone('utc', now()) - interval '30 days';
end;
$$;

create or replace function public.register_notification_device(
    p_token text,
    p_platform text,
    p_locale text default 'vi_VN',
    p_timezone text default 'Asia/Ho_Chi_Minh'
)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
    v_id uuid;
begin
    if auth.uid() is null then raise exception 'AUTH_REQUIRED'; end if;
    if nullif(btrim(coalesce(p_token, '')), '') is null then
        raise exception 'NOTIFICATION_DEVICE_TOKEN_REQUIRED';
    end if;
    if p_platform not in ('android', 'ios') then
        raise exception 'NOTIFICATION_PLATFORM_INVALID';
    end if;

    insert into public.notification_devices (
        user_id, device_token, platform, locale, timezone,
        is_active, last_seen_at, updated_at
    ) values (
        auth.uid(), btrim(p_token), p_platform,
        coalesce(nullif(btrim(p_locale), ''), 'vi_VN'),
        coalesce(nullif(btrim(p_timezone), ''), 'Asia/Ho_Chi_Minh'),
        true, timezone('utc', now()), timezone('utc', now())
    )
    on conflict (device_token) do update set
        user_id = excluded.user_id,
        platform = excluded.platform,
        locale = excluded.locale,
        timezone = excluded.timezone,
        is_active = true,
        last_seen_at = timezone('utc', now()),
        updated_at = timezone('utc', now())
    returning id into v_id;

    return v_id;
end;
$$;

create or replace function public.unregister_notification_device(p_token text)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
    update public.notification_devices
    set is_active = false,
        updated_at = timezone('utc', now())
    where user_id = auth.uid()
      and device_token = btrim(coalesce(p_token, ''));
end;
$$;

create or replace function public.cleanup_expired_notifications()
returns integer
language plpgsql
security definer
set search_path = public
as $$
declare
    v_deleted integer;
begin
    delete from public.app_notifications
    where expires_at <= timezone('utc', now())
       or created_at < timezone('utc', now()) - interval '30 days';
    get diagnostics v_deleted = row_count;

    delete from public.group_notifications
    where created_at < timezone('utc', now()) - interval '30 days';

    delete from public.notification_outbox
    where sent_at is not null
      and created_at < timezone('utc', now()) - interval '30 days';

    return v_deleted;
end;
$$;

revoke all on function public.create_app_notification(uuid, text, text, uuid, uuid, uuid, uuid, jsonb) from public;
revoke all on function public.notify_friend_request_event() from public;
revoke all on function public.enqueue_app_notification() from public;
revoke all on function public.enqueue_group_notification() from public;
revoke all on function public.notification_push_allowed(uuid, text, uuid, text) from public;
revoke all on function public.list_all_notifications(text) from public;
revoke all on function public.mark_notification_read(uuid) from public;
revoke all on function public.mark_all_notifications_read() from public;
revoke all on function public.register_notification_device(text, text, text, text) from public;
revoke all on function public.unregister_notification_device(text) from public;
revoke all on function public.cleanup_expired_notifications() from public;

grant execute on function public.list_all_notifications(text) to authenticated;
grant execute on function public.mark_notification_read(uuid) to authenticated;
grant execute on function public.mark_all_notifications_read() to authenticated;
grant execute on function public.register_notification_device(text, text, text, text) to authenticated;
grant execute on function public.unregister_notification_device(text) to authenticated;
