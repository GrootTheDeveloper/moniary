-- Cursor pagination and source-aware read state for the unified inbox.
-- The original RPCs remain available for older clients.

alter table public.notification_delivery_preferences
    alter column push_enabled set default false;

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

    -- Push is explicit opt-in. Inbox persistence is unaffected.
    if not found or not v_pref.push_enabled then return false; end if;
    if p_category = 'personal' and not v_pref.personal_enabled then return false; end if;
    if p_category = 'group' and not v_pref.group_enabled then return false; end if;
    if p_category = 'community' and not v_pref.community_enabled then return false; end if;
    if p_category = 'system' and not v_pref.system_enabled then return false; end if;

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

create or replace function public.list_all_notifications_v2(
    p_category text default null,
    p_before timestamptz default null,
    p_limit integer default 30
)
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
    with normalized as (
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
            end,
            gn.group_id,
            g.name,
            gn.group_transaction_id,
            null::uuid,
            '{}'::jsonb,
            gn.is_read,
            gn.created_at,
            'group'::text
        from public.group_notifications gn
        join public.groups g on g.id = gn.group_id
        where gn.user_id = auth.uid()
          and gn.created_at >= timezone('utc', now()) - interval '30 days'
          and (p_category is null or gn.category = p_category)
    )
    select *
    from normalized n
    where p_before is null or n.created_at < p_before
    order by n.created_at desc, n.id desc
    limit least(greatest(coalesce(p_limit, 30), 1), 100);
$$;

create or replace function public.notification_unread_summary()
returns table (
    total bigint,
    personal bigint,
    group_count bigint,
    community bigint,
    system_count bigint
)
language sql
stable
security definer
set search_path = public
as $$
    with unread as (
        select an.category
        from public.app_notifications an
        where an.user_id = auth.uid()
          and not an.is_read
          and an.created_at >= timezone('utc', now()) - interval '30 days'
          and an.expires_at > timezone('utc', now())

        union all

        select gn.category
        from public.group_notifications gn
        where gn.user_id = auth.uid()
          and not gn.is_read
          and gn.created_at >= timezone('utc', now()) - interval '30 days'
    )
    select
        count(*) as total,
        count(*) filter (where category = 'personal') as personal,
        count(*) filter (where category = 'group') as group_count,
        count(*) filter (where category = 'community') as community,
        count(*) filter (where category = 'system') as system_count
    from unread;
$$;

create or replace function public.mark_notification_read_v2(
    p_notification_id uuid,
    p_source text
)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
    if p_source = 'app' then
        update public.app_notifications
        set is_read = true,
            read_at = timezone('utc', now())
        where id = p_notification_id
          and user_id = auth.uid()
          and not is_read;
    elsif p_source = 'group' then
        update public.group_notifications
        set is_read = true
        where id = p_notification_id
          and user_id = auth.uid()
          and not is_read;
    else
        raise exception 'NOTIFICATION_SOURCE_INVALID';
    end if;
end;
$$;

create or replace function public.set_notification_read_state(
    p_notification_id uuid,
    p_source text,
    p_is_read boolean
)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
    if p_source = 'app' then
        update public.app_notifications
        set is_read = p_is_read,
            read_at = case
                when p_is_read then timezone('utc', now())
                else null
            end
        where id = p_notification_id
          and user_id = auth.uid();
    elsif p_source = 'group' then
        update public.group_notifications
        set is_read = p_is_read
        where id = p_notification_id
          and user_id = auth.uid();
    else
        raise exception 'NOTIFICATION_SOURCE_INVALID';
    end if;
end;
$$;

revoke all on function public.list_all_notifications_v2(text, timestamptz, integer) from public;
revoke all on function public.notification_unread_summary() from public;
revoke all on function public.mark_notification_read_v2(uuid, text) from public;
revoke all on function public.set_notification_read_state(uuid, text, boolean) from public;

grant execute on function public.list_all_notifications_v2(text, timestamptz, integer) to authenticated;
grant execute on function public.notification_unread_summary() to authenticated;
grant execute on function public.mark_notification_read_v2(uuid, text) to authenticated;
grant execute on function public.set_notification_read_state(uuid, text, boolean) to authenticated;
