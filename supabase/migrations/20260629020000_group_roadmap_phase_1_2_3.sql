-- Roadmap Phase 1-3: notification preferences, reactions, mentions,
-- group statistics support, budgets, recurring transactions and public profile.

create table if not exists public.group_notification_preferences (
    group_id uuid not null references public.groups(id) on delete cascade,
    user_id uuid not null references public.profiles(id) on delete cascade,
    mute_all boolean not null default false,
    transaction_notifications boolean not null default true,
    debt_notifications boolean not null default true,
    invite_notifications boolean not null default true,
    mention_notifications boolean not null default true,
    quiet_hours_start smallint,
    quiet_hours_end smallint,
    created_at timestamptz not null default timezone('utc', now()),
    updated_at timestamptz not null default timezone('utc', now()),
    primary key (group_id, user_id),
    constraint group_notification_quiet_start_check
        check (quiet_hours_start is null or quiet_hours_start between 0 and 23),
    constraint group_notification_quiet_end_check
        check (quiet_hours_end is null or quiet_hours_end between 0 and 23),
    constraint group_notification_quiet_pair_check
        check (
            (quiet_hours_start is null and quiet_hours_end is null)
            or (quiet_hours_start is not null and quiet_hours_end is not null)
        )
);

create table if not exists public.group_transaction_reactions (
    id uuid primary key default gen_random_uuid(),
    group_transaction_id uuid not null
        references public.group_transactions(id) on delete cascade,
    user_id uuid not null references public.profiles(id) on delete cascade,
    emoji text not null,
    created_at timestamptz not null default timezone('utc', now()),
    constraint group_transaction_reactions_emoji_check
        check (char_length(emoji) between 1 and 16),
    constraint group_transaction_reactions_unique
        unique (group_transaction_id, user_id, emoji)
);

create table if not exists public.group_comment_mentions (
    id uuid primary key default gen_random_uuid(),
    comment_id uuid not null
        references public.group_transaction_comments(id) on delete cascade,
    mentioned_user_id uuid not null
        references public.profiles(id) on delete cascade,
    created_at timestamptz not null default timezone('utc', now()),
    constraint group_comment_mentions_unique
        unique (comment_id, mentioned_user_id)
);

create table if not exists public.group_budgets (
    group_id uuid primary key references public.groups(id) on delete cascade,
    monthly_limit bigint not null default 0,
    warning_threshold_percent integer not null default 80,
    created_at timestamptz not null default timezone('utc', now()),
    updated_at timestamptz not null default timezone('utc', now()),
    constraint group_budgets_monthly_limit_check check (monthly_limit >= 0),
    constraint group_budgets_warning_threshold_check
        check (warning_threshold_percent between 1 and 100)
);

create table if not exists public.group_recurring_transactions (
    id uuid primary key default gen_random_uuid(),
    group_id uuid not null references public.groups(id) on delete cascade,
    created_by uuid not null references public.profiles(id) on delete restrict,
    title text not null,
    amount bigint not null,
    frequency text not null default 'monthly',
    next_run_at timestamptz not null,
    notify_days_before integer not null default 1,
    is_active boolean not null default true,
    last_notified_at timestamptz,
    created_at timestamptz not null default timezone('utc', now()),
    updated_at timestamptz not null default timezone('utc', now()),
    constraint group_recurring_title_check check (btrim(title) <> ''),
    constraint group_recurring_amount_check check (amount > 0),
    constraint group_recurring_frequency_check
        check (frequency in ('weekly', 'monthly')),
    constraint group_recurring_notify_days_check
        check (notify_days_before between 0 and 30)
);

create table if not exists public.group_public_profiles (
    group_id uuid primary key references public.groups(id) on delete cascade,
    slug text unique,
    is_enabled boolean not null default false,
    show_stats boolean not null default false,
    created_at timestamptz not null default timezone('utc', now()),
    updated_at timestamptz not null default timezone('utc', now()),
    constraint group_public_profiles_slug_check
        check (slug is null or slug ~ '^[a-z0-9-]{3,80}$')
);

create index if not exists group_reactions_transaction_idx
    on public.group_transaction_reactions (group_transaction_id, emoji);
create index if not exists group_recurring_due_idx
    on public.group_recurring_transactions (is_active, next_run_at);
create index if not exists group_comment_mentions_user_idx
    on public.group_comment_mentions (mentioned_user_id, created_at desc);

drop trigger if exists set_group_notification_preferences_updated_at
    on public.group_notification_preferences;
create trigger set_group_notification_preferences_updated_at
before update on public.group_notification_preferences
for each row execute function public.set_updated_at();

drop trigger if exists set_group_budgets_updated_at on public.group_budgets;
create trigger set_group_budgets_updated_at
before update on public.group_budgets
for each row execute function public.set_updated_at();

drop trigger if exists set_group_recurring_transactions_updated_at
    on public.group_recurring_transactions;
create trigger set_group_recurring_transactions_updated_at
before update on public.group_recurring_transactions
for each row execute function public.set_updated_at();

drop trigger if exists set_group_public_profiles_updated_at
    on public.group_public_profiles;
create trigger set_group_public_profiles_updated_at
before update on public.group_public_profiles
for each row execute function public.set_updated_at();

alter table public.group_notification_preferences enable row level security;
alter table public.group_transaction_reactions enable row level security;
alter table public.group_comment_mentions enable row level security;
alter table public.group_budgets enable row level security;
alter table public.group_recurring_transactions enable row level security;
alter table public.group_public_profiles enable row level security;

drop policy if exists "group_notification_preferences_select_own"
    on public.group_notification_preferences;
create policy "group_notification_preferences_select_own"
on public.group_notification_preferences for select to authenticated
using (user_id = auth.uid() and public.is_group_member(group_id));

drop policy if exists "group_notification_preferences_upsert_own"
    on public.group_notification_preferences;
create policy "group_notification_preferences_upsert_own"
on public.group_notification_preferences for all to authenticated
using (user_id = auth.uid() and public.is_group_member(group_id))
with check (user_id = auth.uid() and public.is_group_member(group_id));

drop policy if exists "group_reactions_select_member"
    on public.group_transaction_reactions;
create policy "group_reactions_select_member"
on public.group_transaction_reactions for select to authenticated
using (
    exists (
        select 1
        from public.group_transactions gt
        where gt.id = group_transaction_id
          and public.is_group_member(gt.group_id)
    )
);

drop policy if exists "group_reactions_insert_member"
    on public.group_transaction_reactions;
create policy "group_reactions_insert_member"
on public.group_transaction_reactions for insert to authenticated
with check (
    user_id = auth.uid()
    and exists (
        select 1
        from public.group_transactions gt
        where gt.id = group_transaction_id
          and public.is_group_member(gt.group_id)
    )
);

drop policy if exists "group_reactions_delete_own"
    on public.group_transaction_reactions;
create policy "group_reactions_delete_own"
on public.group_transaction_reactions for delete to authenticated
using (user_id = auth.uid());

drop policy if exists "group_comment_mentions_select_member"
    on public.group_comment_mentions;
create policy "group_comment_mentions_select_member"
on public.group_comment_mentions for select to authenticated
using (
    exists (
        select 1
        from public.group_transaction_comments gtc
        join public.group_transactions gt
          on gt.id = gtc.group_transaction_id
        where gtc.id = comment_id
          and public.is_group_member(gt.group_id)
    )
);

drop policy if exists "group_budgets_select_member" on public.group_budgets;
create policy "group_budgets_select_member"
on public.group_budgets for select to authenticated
using (public.is_group_member(group_id));

drop policy if exists "group_budgets_insert_admin" on public.group_budgets;
create policy "group_budgets_insert_admin"
on public.group_budgets for insert to authenticated
with check (
    public.has_group_role(
        group_id,
        array['owner', 'admin']::public.group_role[]
    )
);

drop policy if exists "group_budgets_update_admin" on public.group_budgets;
create policy "group_budgets_update_admin"
on public.group_budgets for update to authenticated
using (
    public.has_group_role(
        group_id,
        array['owner', 'admin']::public.group_role[]
    )
)
with check (
    public.has_group_role(
        group_id,
        array['owner', 'admin']::public.group_role[]
    )
);

drop policy if exists "group_recurring_select_member"
    on public.group_recurring_transactions;
create policy "group_recurring_select_member"
on public.group_recurring_transactions for select to authenticated
using (public.is_group_member(group_id));

drop policy if exists "group_recurring_insert_member"
    on public.group_recurring_transactions;
create policy "group_recurring_insert_member"
on public.group_recurring_transactions for insert to authenticated
with check (created_by = auth.uid() and public.is_group_member(group_id));

drop policy if exists "group_recurring_update_owner_or_admin"
    on public.group_recurring_transactions;
create policy "group_recurring_update_owner_or_admin"
on public.group_recurring_transactions for update to authenticated
using (
    created_by = auth.uid()
    or public.has_group_role(
        group_id,
        array['owner', 'admin']::public.group_role[]
    )
)
with check (
    created_by = auth.uid()
    or public.has_group_role(
        group_id,
        array['owner', 'admin']::public.group_role[]
    )
);

drop policy if exists "group_public_profiles_select_member"
    on public.group_public_profiles;
create policy "group_public_profiles_select_member"
on public.group_public_profiles for select to authenticated
using (public.is_group_member(group_id));

drop policy if exists "group_public_profiles_insert_admin"
    on public.group_public_profiles;
create policy "group_public_profiles_insert_admin"
on public.group_public_profiles for insert to authenticated
with check (
    public.has_group_role(
        group_id,
        array['owner', 'admin']::public.group_role[]
    )
);

drop policy if exists "group_public_profiles_update_admin"
    on public.group_public_profiles;
create policy "group_public_profiles_update_admin"
on public.group_public_profiles for update to authenticated
using (
    public.has_group_role(
        group_id,
        array['owner', 'admin']::public.group_role[]
    )
)
with check (
    public.has_group_role(
        group_id,
        array['owner', 'admin']::public.group_role[]
    )
);

create or replace function public.group_notification_enabled(
    p_group_id uuid,
    p_user_id uuid,
    p_type text
)
returns boolean
language plpgsql
stable
security definer
set search_path = public
as $$
declare
    v_pref public.group_notification_preferences%rowtype;
    v_hour integer := extract(hour from timezone('utc', now()));
    v_quiet boolean := false;
begin
    select *
    into v_pref
    from public.group_notification_preferences
    where group_id = p_group_id
      and user_id = p_user_id;

    if not found then
        return true;
    end if;
    if v_pref.mute_all then
        return false;
    end if;
    if v_pref.quiet_hours_start is not null
       and v_pref.quiet_hours_end is not null then
        if v_pref.quiet_hours_start <= v_pref.quiet_hours_end then
            v_quiet :=
                v_hour >= v_pref.quiet_hours_start
                and v_hour < v_pref.quiet_hours_end;
        else
            v_quiet :=
                v_hour >= v_pref.quiet_hours_start
                or v_hour < v_pref.quiet_hours_end;
        end if;
        if v_quiet then
            return false;
        end if;
    end if;
    if p_type ilike '%invite%' then
        return v_pref.invite_notifications;
    end if;
    if p_type ilike '%mention%' then
        return v_pref.mention_notifications;
    end if;
    if p_type ilike '%settlement%' or p_type ilike '%debt%' then
        return v_pref.debt_notifications;
    end if;
    if p_type ilike '%transaction%' or p_type ilike '%amount%' then
        return v_pref.transaction_notifications;
    end if;
    return true;
end;
$$;

create or replace function public.filter_group_notification_by_preference()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
    if not public.group_notification_enabled(
        new.group_id,
        new.user_id,
        new.type
    ) then
        return null;
    end if;
    return new;
end;
$$;

drop trigger if exists filter_group_notifications_by_preference
    on public.group_notifications;
create trigger filter_group_notifications_by_preference
before insert on public.group_notifications
for each row execute function public.filter_group_notification_by_preference();

create or replace function public.list_group_transaction_reactions(
    p_transaction_id uuid
)
returns table (
    emoji text,
    reaction_count bigint,
    reacted_by_current_user boolean
)
language plpgsql
security definer
set search_path = public
as $$
declare
    v_group_id uuid;
begin
    select group_id
    into v_group_id
    from public.group_transactions
    where id = p_transaction_id;

    if v_group_id is null then
        raise exception 'NOT_FOUND';
    end if;
    if not public.is_group_member(v_group_id) then
        raise exception 'GROUP_MEMBER_REQUIRED';
    end if;

    return query
    select
        gtr.emoji,
        count(*)::bigint as reaction_count,
        bool_or(gtr.user_id = auth.uid()) as reacted_by_current_user
    from public.group_transaction_reactions gtr
    where gtr.group_transaction_id = p_transaction_id
    group by gtr.emoji
    order by count(*) desc, gtr.emoji;
end;
$$;

create or replace function public.toggle_group_transaction_reaction(
    p_transaction_id uuid,
    p_emoji text
)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
    v_group_id uuid;
    v_emoji text := btrim(coalesce(p_emoji, ''));
begin
    select group_id
    into v_group_id
    from public.group_transactions
    where id = p_transaction_id;

    if v_group_id is null then
        raise exception 'NOT_FOUND';
    end if;
    if not public.is_group_member(v_group_id) then
        raise exception 'GROUP_MEMBER_REQUIRED';
    end if;
    if v_emoji = '' then
        raise exception 'GROUP_REACTION_REQUIRED';
    end if;

    delete from public.group_transaction_reactions
    where group_transaction_id = p_transaction_id
      and user_id = auth.uid()
      and emoji = v_emoji;

    if found then
        return;
    end if;

    insert into public.group_transaction_reactions (
        group_transaction_id,
        user_id,
        emoji
    )
    values (p_transaction_id, auth.uid(), v_emoji);

    insert into public.group_activities (
        group_id,
        actor_user_id,
        type,
        metadata
    )
    values (
        v_group_id,
        auth.uid(),
        'transaction_reacted',
        jsonb_build_object('transactionId', p_transaction_id, 'emoji', v_emoji)
    );
end;
$$;

create or replace function public.add_group_transaction_comment(
    p_transaction_id uuid,
    p_content text
)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
    v_group_id uuid;
    v_comment_id uuid;
    v_content text := btrim(coalesce(p_content, ''));
    v_username text;
    v_mentioned_user_id uuid;
begin
    select group_id
    into v_group_id
    from public.group_transactions
    where id = p_transaction_id;

    if v_group_id is null then
        raise exception 'NOT_FOUND';
    end if;
    if not public.is_group_member(v_group_id) then
        raise exception 'GROUP_MEMBER_REQUIRED';
    end if;
    if v_content = '' then
        raise exception 'GROUP_COMMENT_REQUIRED';
    end if;

    insert into public.group_transaction_comments (
        group_transaction_id,
        user_id,
        content
    )
    values (p_transaction_id, auth.uid(), v_content)
    returning id into v_comment_id;

    insert into public.group_activities (
        group_id,
        actor_user_id,
        type,
        metadata
    )
    values (
        v_group_id,
        auth.uid(),
        'comment_added',
        jsonb_build_object('transactionId', p_transaction_id)
    );

    for v_username in
        select distinct lower(mention.match[1])
        from regexp_matches(
            v_content,
            '@([A-Za-z0-9_]{3,30})',
            'g'
        ) as mention(match)
    loop
        select gm.user_id
        into v_mentioned_user_id
        from public.group_members gm
        join public.profiles p on p.id = gm.user_id
        where gm.group_id = v_group_id
          and gm.status = 'active'
          and lower(p.username) = v_username
        limit 1;

        if v_mentioned_user_id is not null
           and v_mentioned_user_id <> auth.uid() then
            insert into public.group_comment_mentions (
                comment_id,
                mentioned_user_id
            )
            values (v_comment_id, v_mentioned_user_id)
            on conflict do nothing;

            insert into public.group_notifications (
                group_id,
                user_id,
                group_transaction_id,
                type
            )
            values (
                v_group_id,
                v_mentioned_user_id,
                p_transaction_id,
                'comment_mention'
            );
        end if;

        v_mentioned_user_id := null;
    end loop;

    return v_comment_id;
end;
$$;

create or replace function public.notify_due_group_recurring_transactions()
returns integer
language plpgsql
security definer
set search_path = public
as $$
declare
    v_count integer := 0;
    v_item public.group_recurring_transactions%rowtype;
begin
    for v_item in
        select *
        from public.group_recurring_transactions
        where is_active = true
          and next_run_at - make_interval(days => notify_days_before)
              <= timezone('utc', now())
          and (
              last_notified_at is null
              or last_notified_at < next_run_at - interval '1 day'
          )
    loop
        insert into public.group_notifications (
            group_id,
            user_id,
            type
        )
        select
            v_item.group_id,
            gm.user_id,
            'recurring_due'
        from public.group_members gm
        where gm.group_id = v_item.group_id
          and gm.status = 'active';

        update public.group_recurring_transactions
        set last_notified_at = timezone('utc', now())
        where id = v_item.id;

        v_count := v_count + 1;
    end loop;

    return v_count;
end;
$$;

revoke all on function public.group_notification_enabled(uuid, uuid, text)
    from public;
revoke all on function public.list_group_transaction_reactions(uuid)
    from public;
revoke all on function public.toggle_group_transaction_reaction(uuid, text)
    from public;
revoke all on function public.add_group_transaction_comment(uuid, text)
    from public;
revoke all on function public.notify_due_group_recurring_transactions()
    from public;

grant execute on function public.group_notification_enabled(uuid, uuid, text)
    to authenticated;
grant execute on function public.list_group_transaction_reactions(uuid)
    to authenticated;
grant execute on function public.toggle_group_transaction_reaction(uuid, text)
    to authenticated;
grant execute on function public.add_group_transaction_comment(uuid, text)
    to authenticated;
grant execute on function public.notify_due_group_recurring_transactions()
    to authenticated;
