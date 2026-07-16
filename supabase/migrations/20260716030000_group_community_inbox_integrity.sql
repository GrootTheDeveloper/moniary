-- Keep Community member-generated, make the unified inbox group-aware, and
-- guard savings contributions against over-funding.

alter table public.group_notifications
    add column if not exists metadata jsonb not null default '{}'::jsonb;

create index if not exists group_notifications_user_group_unread_idx
    on public.group_notifications(user_id, group_id, is_read, created_at desc);

drop policy if exists "group_community_post_comments_update_author_or_admin"
    on public.group_community_post_comments;
create policy "group_community_post_comments_update_author_or_admin"
on public.group_community_post_comments for update to authenticated
using (
    user_id = auth.uid()
    or exists (
        select 1
        from public.group_community_posts p
        where p.id = post_id
          and public.has_group_role(
              p.group_id,
              array['owner', 'admin']::public.group_role[]
          )
    )
)
with check (
    user_id = auth.uid()
    or exists (
        select 1
        from public.group_community_posts p
        where p.id = post_id
          and public.has_group_role(
              p.group_id,
              array['owner', 'admin']::public.group_role[]
          )
    )
);

drop policy if exists "group_community_post_comments_delete_author_or_admin"
    on public.group_community_post_comments;
create policy "group_community_post_comments_delete_author_or_admin"
on public.group_community_post_comments for delete to authenticated
using (
    user_id = auth.uid()
    or exists (
        select 1
        from public.group_community_posts p
        where p.id = post_id
          and public.has_group_role(
              p.group_id,
              array['owner', 'admin']::public.group_role[]
          )
    )
);

create or replace function public.set_group_notification_category()
returns trigger
language plpgsql
as $$
begin
    new.category := case
        when new.type ilike '%comment%'
          or new.type ilike '%mention%'
          or new.type ilike '%react%'
          or new.type ilike '%reply%'
          or new.type ilike 'community_%'
          or new.type ilike 'challenge_%'
          or new.type ilike 'poll_%'
        then 'community'
        else coalesce(new.category, 'group')
    end;
    return new;
end;
$$;

create or replace function public.notify_group_community_post_activity()
returns trigger
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
    v_post_id uuid;
    v_recipient_id uuid;
    v_actor_name text;
    v_notification_type text;
begin
    if new.type not in (
        'community_post_commented',
        'community_post_reacted'
    ) then
        return new;
    end if;

    v_post_id := nullif(new.metadata ->> 'post_id', '')::uuid;
    if v_post_id is null then return new; end if;

    select p.author_user_id
    into v_recipient_id
    from public.group_community_posts p
    where p.id = v_post_id
      and p.deleted_at is null;

    if v_recipient_id is null or v_recipient_id = new.actor_user_id then
        return new;
    end if;

    v_notification_type := new.type;
    if not public.group_notification_enabled(
        new.group_id,
        v_recipient_id,
        v_notification_type
    ) then
        return new;
    end if;

    select coalesce(nullif(btrim(p.full_name), ''), p.username, 'Member')
    into v_actor_name
    from public.profiles p
    where p.id = new.actor_user_id;

    if exists (
        select 1
        from public.group_notifications gn
        where gn.user_id = v_recipient_id
          and gn.group_id = new.group_id
          and gn.type = v_notification_type
          and gn.metadata ->> 'post_id' = v_post_id::text
          and gn.metadata ->> 'actor_user_id' = new.actor_user_id::text
          and gn.created_at >= timezone('utc', now()) - interval '5 minutes'
    ) then
        return new;
    end if;

    insert into public.group_notifications(
        group_id,
        user_id,
        type,
        metadata
    ) values (
        new.group_id,
        v_recipient_id,
        v_notification_type,
        jsonb_build_object(
            'post_id', v_post_id,
            'actor_user_id', new.actor_user_id,
            'actor_name', coalesce(v_actor_name, 'Member')
        )
    );
    return new;
end;
$$;

drop trigger if exists notify_group_community_post_activity
    on public.group_activities;
create trigger notify_group_community_post_activity
after insert on public.group_activities
for each row execute function public.notify_group_community_post_activity();

-- Contributions must go through the locked RPC below so concurrent clients
-- cannot overfill a challenge by inserting directly through PostgREST.
drop policy if exists "group_savings_contributions_insert_member"
    on public.group_savings_contributions;

create or replace function public.add_group_savings_contribution(
    p_challenge_id uuid,
    p_amount bigint,
    p_note text default null
)
returns void
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
    v_challenge public.group_savings_challenges%rowtype;
    v_total bigint;
    v_remaining bigint;
    v_actor_name text;
begin
    if auth.uid() is null then raise exception 'AUTH_REQUIRED'; end if;
    if coalesce(p_amount, 0) <= 0 then
        raise exception 'CHALLENGE_CONTRIBUTION_INVALID';
    end if;

    select * into v_challenge
    from public.group_savings_challenges
    where id = p_challenge_id
    for update;

    if not found
       or not public.is_group_member(v_challenge.group_id, auth.uid()) then
        raise exception 'CHALLENGE_NOT_AVAILABLE';
    end if;
    if not v_challenge.is_active
       or current_date < v_challenge.start_date
       or current_date > v_challenge.end_date then
        raise exception 'CHALLENGE_NOT_ACTIVE';
    end if;

    select coalesce(sum(amount), 0)
    into v_total
    from public.group_savings_contributions
    where challenge_id = p_challenge_id;
    v_remaining := greatest(v_challenge.target_amount - v_total, 0);
    if p_amount > v_remaining then
        raise exception 'CHALLENGE_CONTRIBUTION_EXCEEDS_REMAINING';
    end if;

    insert into public.group_savings_contributions(
        challenge_id,
        user_id,
        amount,
        note
    ) values (
        p_challenge_id,
        auth.uid(),
        p_amount,
        nullif(btrim(coalesce(p_note, '')), '')
    );

    if p_amount = v_remaining then
        update public.group_savings_challenges
        set is_active = false
        where id = p_challenge_id;
    end if;

    insert into public.group_activities(
        group_id,
        actor_user_id,
        type,
        metadata
    ) values (
        v_challenge.group_id,
        auth.uid(),
        'challenge_contribution',
        jsonb_build_object(
            'challenge_id', p_challenge_id,
            'amount', p_amount
        )
    );

    if v_challenge.created_by <> auth.uid()
       and public.group_notification_enabled(
           v_challenge.group_id,
           v_challenge.created_by,
           'challenge_contribution'
       ) then
        select coalesce(nullif(btrim(p.full_name), ''), p.username, 'Member')
        into v_actor_name
        from public.profiles p
        where p.id = auth.uid();

        insert into public.group_notifications(
            group_id,
            user_id,
            type,
            metadata
        ) values (
            v_challenge.group_id,
            v_challenge.created_by,
            'challenge_contribution',
            jsonb_build_object(
                'challenge_id', p_challenge_id,
                'actor_user_id', auth.uid(),
                'actor_name', coalesce(v_actor_name, 'Member'),
                'amount', p_amount
            )
        );
    end if;
end;
$$;

revoke all on function public.add_group_savings_contribution(uuid, bigint, text)
    from public;
grant execute on function public.add_group_savings_contribution(uuid, bigint, text)
    to authenticated;

create or replace function public.update_group_member_role(
    p_group_id uuid,
    p_user_id uuid,
    p_role public.group_role
)
returns void
language plpgsql
security definer
set search_path = public, pg_temp
as $$
begin
    if not public.has_group_role(
        p_group_id,
        array['owner']::public.group_role[],
        auth.uid()
    ) then
        raise exception 'GROUP_OWNER_REQUIRED';
    end if;
    if p_user_id = auth.uid()
       or p_role not in ('admin'::public.group_role, 'member'::public.group_role)
    then
        raise exception 'GROUP_MEMBER_ROLE_FORBIDDEN';
    end if;

    update public.group_members
    set role = p_role
    where group_id = p_group_id
      and user_id = p_user_id
      and status = 'active'
      and role <> 'owner'::public.group_role;
    if not found then
        raise exception 'GROUP_MEMBER_ROLE_FORBIDDEN';
    end if;

    insert into public.group_activities(
        group_id,
        actor_user_id,
        type,
        metadata
    ) values (
        p_group_id,
        auth.uid(),
        'member_role_updated',
        jsonb_build_object('user_id', p_user_id, 'role', p_role)
    );

    insert into public.group_notifications(
        group_id,
        user_id,
        type,
        metadata
    ) values (
        p_group_id,
        p_user_id,
        'member_role_updated',
        jsonb_build_object('role', p_role)
    );
end;
$$;

revoke all on function public.update_group_member_role(
    uuid,
    uuid,
    public.group_role
) from public;
grant execute on function public.update_group_member_role(
    uuid,
    uuid,
    public.group_role
) to authenticated;

drop function if exists public.list_all_notifications_v2(
    text,
    timestamptz,
    integer
);
create function public.list_all_notifications_v2(
    p_category text default null,
    p_before timestamptz default null,
    p_limit integer default 30,
    p_group_id uuid default null
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
          and (p_group_id is null or an.group_id = p_group_id)

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
            gn.metadata,
            gn.is_read,
            gn.created_at,
            'group'::text
        from public.group_notifications gn
        join public.groups g on g.id = gn.group_id
        where gn.user_id = auth.uid()
          and gn.created_at >= timezone('utc', now()) - interval '30 days'
          and (p_category is null or gn.category = p_category)
          and (p_group_id is null or gn.group_id = p_group_id)
    )
    select *
    from normalized n
    where p_before is null or n.created_at < p_before
    order by n.created_at desc, n.id desc
    limit least(greatest(coalesce(p_limit, 30), 1), 100);
$$;

revoke all on function public.list_all_notifications_v2(
    text,
    timestamptz,
    integer,
    uuid
) from public;
grant execute on function public.list_all_notifications_v2(
    text,
    timestamptz,
    integer,
    uuid
) to authenticated;

drop function if exists public.notification_unread_summary();
create function public.notification_unread_summary(p_group_id uuid default null)
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
          and (p_group_id is null or an.group_id = p_group_id)

        union all

        select gn.category
        from public.group_notifications gn
        where gn.user_id = auth.uid()
          and not gn.is_read
          and gn.created_at >= timezone('utc', now()) - interval '30 days'
          and (p_group_id is null or gn.group_id = p_group_id)
    )
    select
        count(*) as total,
        count(*) filter (where category = 'personal') as personal,
        count(*) filter (where category = 'group') as group_count,
        count(*) filter (where category = 'community') as community,
        count(*) filter (where category = 'system') as system_count
    from unread;
$$;

revoke all on function public.notification_unread_summary(uuid) from public;
grant execute on function public.notification_unread_summary(uuid)
    to authenticated;

create or replace function public.mark_all_notifications_read_scoped(
    p_group_id uuid default null
)
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
      and (p_group_id is null or group_id = p_group_id);

    update public.group_notifications
    set is_read = true
    where user_id = auth.uid()
      and not is_read
      and (p_group_id is null or group_id = p_group_id);
end;
$$;

revoke all on function public.mark_all_notifications_read_scoped(uuid)
    from public;
grant execute on function public.mark_all_notifications_read_scoped(uuid)
    to authenticated;
