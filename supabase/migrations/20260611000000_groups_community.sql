alter table public.profiles
    add column if not exists username text;

create unique index if not exists profiles_username_key
    on public.profiles (lower(username))
    where username is not null;

update public.profiles
set username = 'user_' || right(replace(id::text, '-', ''), 24)
where username is null;

do $$
begin
    alter table public.profiles
        add constraint profiles_username_format check (
            username ~ '^[a-z0-9_]{3,30}$'
        );
exception
    when duplicate_object then null;
end
$$;

create or replace function public.ensure_profile_username()
returns trigger
language plpgsql
set search_path = public
as $$
begin
    if new.username is null or btrim(new.username) = '' then
        new.username :=
            'user_' || right(replace(new.id::text, '-', ''), 24);
    else
        new.username := lower(btrim(new.username));
    end if;
    return new;
end;
$$;

drop trigger if exists ensure_profiles_username on public.profiles;
create trigger ensure_profiles_username
before insert or update of username on public.profiles
for each row execute function public.ensure_profile_username();

do $$
begin
    create type public.group_role as enum ('owner', 'admin', 'member');
exception
    when duplicate_object then null;
end
$$;

do $$
begin
    create type public.group_member_status
        as enum ('invited', 'active', 'declined', 'left', 'removed');
exception
    when duplicate_object then null;
end
$$;

do $$
begin
    create type public.group_status as enum ('active', 'archived');
exception
    when duplicate_object then null;
end
$$;

do $$
begin
    create type public.group_split_mode as enum ('equal', 'unequal');
exception
    when duplicate_object then null;
end
$$;

do $$
begin
    create type public.group_payment_mode
        as enum ('everyone_paid', 'single_payer', 'multiple_payers');
exception
    when duplicate_object then null;
end
$$;

do $$
begin
    create type public.group_split_status
        as enum (
            'draft',
            'pending_member_amount_input',
            'amount_mismatch',
            'posted',
            'cancelled'
        );
exception
    when duplicate_object then null;
end
$$;

do $$
begin
    create type public.group_share_input_status as enum ('pending', 'submitted');
exception
    when duplicate_object then null;
end
$$;

do $$
begin
    create type public.group_settlement_status
        as enum ('pending', 'payer_marked_paid', 'completed', 'disputed');
exception
    when duplicate_object then null;
end
$$;

create table if not exists public.groups (
    id uuid primary key default gen_random_uuid(),
    name text not null,
    avatar_path text,
    description text,
    type text,
    created_by uuid not null,
    status public.group_status not null default 'active',
    created_at timestamptz not null default timezone('utc', now()),
    updated_at timestamptz not null default timezone('utc', now()),
    constraint groups_created_by_profiles_fkey
        foreign key (created_by) references public.profiles(id) on delete restrict,
    constraint groups_name_not_blank check (btrim(name) <> '')
);

create table if not exists public.group_members (
    id uuid primary key default gen_random_uuid(),
    group_id uuid not null references public.groups(id) on delete cascade,
    user_id uuid not null,
    role public.group_role not null default 'member',
    status public.group_member_status not null default 'invited',
    joined_at timestamptz not null default timezone('utc', now()),
    left_at timestamptz,
    created_at timestamptz not null default timezone('utc', now()),
    updated_at timestamptz not null default timezone('utc', now()),
    constraint group_members_user_id_profiles_fkey
        foreign key (user_id) references public.profiles(id) on delete restrict,
    constraint group_members_group_user_key unique (group_id, user_id),
    constraint group_members_left_at_check check (
        (status = 'left' and left_at is not null)
        or (status <> 'left')
    )
);

create table if not exists public.group_transactions (
    id uuid primary key default gen_random_uuid(),
    group_id uuid not null references public.groups(id) on delete cascade,
    created_by uuid not null,
    total_amount bigint not null,
    category_id uuid references public.categories(id) on delete set null,
    category_name_snapshot text,
    caption text,
    note text,
    image_path text,
    image_upload_status public.image_upload_status not null default 'pending',
    split_mode public.group_split_mode not null,
    payment_mode public.group_payment_mode not null,
    split_status public.group_split_status not null default 'draft',
    transaction_date timestamptz not null default timezone('utc', now()),
    created_at timestamptz not null default timezone('utc', now()),
    updated_at timestamptz not null default timezone('utc', now()),
    constraint group_transactions_created_by_profiles_fkey
        foreign key (created_by) references public.profiles(id) on delete restrict,
    constraint group_transactions_amount_positive check (total_amount > 0),
    constraint group_transactions_image_path_pairing check (
        (image_path is null and image_upload_status in ('pending', 'uploading', 'failed'))
        or (image_path is not null and image_upload_status = 'uploaded')
    )
);

create table if not exists public.group_transaction_payers (
    id uuid primary key default gen_random_uuid(),
    group_transaction_id uuid not null
        references public.group_transactions(id) on delete cascade,
    user_id uuid not null,
    paid_amount bigint not null,
    created_at timestamptz not null default timezone('utc', now()),
    updated_at timestamptz not null default timezone('utc', now()),
    constraint group_transaction_payers_user_id_profiles_fkey
        foreign key (user_id) references public.profiles(id) on delete restrict,
    constraint group_transaction_payers_transaction_user_key
        unique (group_transaction_id, user_id),
    constraint group_transaction_payers_amount_non_negative
        check (paid_amount >= 0)
);

create table if not exists public.group_transaction_shares (
    id uuid primary key default gen_random_uuid(),
    group_transaction_id uuid not null
        references public.group_transactions(id) on delete cascade,
    user_id uuid not null,
    share_amount bigint not null default 0,
    input_status public.group_share_input_status not null default 'pending',
    submitted_at timestamptz,
    created_at timestamptz not null default timezone('utc', now()),
    updated_at timestamptz not null default timezone('utc', now()),
    constraint group_transaction_shares_user_id_profiles_fkey
        foreign key (user_id) references public.profiles(id) on delete restrict,
    constraint group_transaction_shares_transaction_user_key
        unique (group_transaction_id, user_id),
    constraint group_transaction_shares_amount_non_negative
        check (share_amount >= 0),
    constraint group_transaction_shares_submission_check check (
        (input_status = 'pending' and submitted_at is null)
        or (input_status = 'submitted' and submitted_at is not null)
    )
);

create table if not exists public.group_settlement_suggestions (
    id uuid primary key default gen_random_uuid(),
    group_id uuid not null references public.groups(id) on delete cascade,
    from_user_id uuid not null,
    to_user_id uuid not null,
    amount bigint not null,
    status public.group_settlement_status not null default 'pending',
    payer_marked_paid_at timestamptz,
    receiver_confirmed_at timestamptz,
    created_at timestamptz not null default timezone('utc', now()),
    updated_at timestamptz not null default timezone('utc', now()),
    constraint group_settlements_from_user_profiles_fkey
        foreign key (from_user_id) references public.profiles(id) on delete restrict,
    constraint group_settlements_to_user_profiles_fkey
        foreign key (to_user_id) references public.profiles(id) on delete restrict,
    constraint group_settlements_amount_positive check (amount > 0),
    constraint group_settlements_different_users
        check (from_user_id <> to_user_id),
    constraint group_settlements_status_dates check (
        (status = 'pending'
            and payer_marked_paid_at is null
            and receiver_confirmed_at is null)
        or (status = 'payer_marked_paid'
            and payer_marked_paid_at is not null
            and receiver_confirmed_at is null)
        or (status = 'completed'
            and payer_marked_paid_at is not null
            and receiver_confirmed_at is not null)
        or status = 'disputed'
    )
);

create table if not exists public.group_transaction_comments (
    id uuid primary key default gen_random_uuid(),
    group_transaction_id uuid not null
        references public.group_transactions(id) on delete cascade,
    user_id uuid not null,
    content text not null,
    created_at timestamptz not null default timezone('utc', now()),
    updated_at timestamptz not null default timezone('utc', now()),
    constraint group_transaction_comments_user_id_profiles_fkey
        foreign key (user_id) references public.profiles(id) on delete restrict,
    constraint group_transaction_comments_content_not_blank
        check (btrim(content) <> '')
);

create table if not exists public.group_invites (
    id uuid primary key default gen_random_uuid(),
    group_id uuid not null references public.groups(id) on delete cascade,
    invited_user_id uuid,
    invited_by uuid not null,
    token text not null default gen_random_uuid()::text,
    status text not null default 'pending',
    expires_at timestamptz not null default timezone('utc', now()) + interval '7 days',
    created_at timestamptz not null default timezone('utc', now()),
    updated_at timestamptz not null default timezone('utc', now()),
    constraint group_invites_invited_user_profiles_fkey
        foreign key (invited_user_id) references public.profiles(id) on delete cascade,
    constraint group_invites_invited_by_profiles_fkey
        foreign key (invited_by) references public.profiles(id) on delete cascade,
    constraint group_invites_token_key unique (token),
    constraint group_invites_status_check
        check (status in ('pending', 'accepted', 'declined', 'expired'))
);

create unique index if not exists group_invites_pending_user_key
    on public.group_invites (group_id, invited_user_id)
    where invited_user_id is not null and status = 'pending';

create table if not exists public.group_notifications (
    id uuid primary key default gen_random_uuid(),
    group_id uuid not null references public.groups(id) on delete cascade,
    user_id uuid not null,
    group_transaction_id uuid
        references public.group_transactions(id) on delete cascade,
    type text not null,
    is_read boolean not null default false,
    created_at timestamptz not null default timezone('utc', now()),
    constraint group_notifications_user_id_profiles_fkey
        foreign key (user_id) references public.profiles(id) on delete cascade
);

create table if not exists public.group_activities (
    id uuid primary key default gen_random_uuid(),
    group_id uuid not null references public.groups(id) on delete cascade,
    actor_user_id uuid not null,
    type text not null,
    metadata jsonb not null default '{}'::jsonb,
    created_at timestamptz not null default timezone('utc', now()),
    constraint group_activities_actor_profiles_fkey
        foreign key (actor_user_id) references public.profiles(id) on delete restrict
);

create index if not exists group_members_user_status_idx
    on public.group_members (user_id, status, joined_at);
create index if not exists group_transactions_group_date_idx
    on public.group_transactions (group_id, transaction_date desc);
create index if not exists group_transaction_payers_transaction_idx
    on public.group_transaction_payers (group_transaction_id, user_id);
create index if not exists group_transaction_shares_transaction_idx
    on public.group_transaction_shares (group_transaction_id, user_id);
create index if not exists group_settlements_group_status_idx
    on public.group_settlement_suggestions (group_id, status, created_at);
create index if not exists group_comments_transaction_date_idx
    on public.group_transaction_comments (group_transaction_id, created_at);
create index if not exists group_notifications_user_read_idx
    on public.group_notifications (user_id, is_read, created_at desc);

drop trigger if exists set_groups_updated_at on public.groups;
create trigger set_groups_updated_at
before update on public.groups
for each row execute function public.set_updated_at();

drop trigger if exists set_group_members_updated_at on public.group_members;
create trigger set_group_members_updated_at
before update on public.group_members
for each row execute function public.set_updated_at();

drop trigger if exists set_group_transactions_updated_at on public.group_transactions;
create trigger set_group_transactions_updated_at
before update on public.group_transactions
for each row execute function public.set_updated_at();

drop trigger if exists set_group_transaction_payers_updated_at
    on public.group_transaction_payers;
create trigger set_group_transaction_payers_updated_at
before update on public.group_transaction_payers
for each row execute function public.set_updated_at();

drop trigger if exists set_group_transaction_shares_updated_at
    on public.group_transaction_shares;
create trigger set_group_transaction_shares_updated_at
before update on public.group_transaction_shares
for each row execute function public.set_updated_at();

drop trigger if exists set_group_settlements_updated_at
    on public.group_settlement_suggestions;
create trigger set_group_settlements_updated_at
before update on public.group_settlement_suggestions
for each row execute function public.set_updated_at();

drop trigger if exists set_group_comments_updated_at
    on public.group_transaction_comments;
create trigger set_group_comments_updated_at
before update on public.group_transaction_comments
for each row execute function public.set_updated_at();

drop trigger if exists set_group_invites_updated_at on public.group_invites;
create trigger set_group_invites_updated_at
before update on public.group_invites
for each row execute function public.set_updated_at();

create or replace function public.is_group_member(
    p_group_id uuid,
    p_user_id uuid default auth.uid()
)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
    select exists (
        select 1
        from public.group_members gm
        where gm.group_id = p_group_id
          and gm.user_id = p_user_id
          and gm.status = 'active'
    );
$$;

create or replace function public.has_group_role(
    p_group_id uuid,
    p_roles public.group_role[],
    p_user_id uuid default auth.uid()
)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
    select exists (
        select 1
        from public.group_members gm
        where gm.group_id = p_group_id
          and gm.user_id = p_user_id
          and gm.status = 'active'
          and gm.role = any(p_roles)
    );
$$;

revoke all on function public.is_group_member(uuid, uuid) from public;
revoke all on function public.has_group_role(uuid, public.group_role[], uuid)
    from public;
grant execute on function public.is_group_member(uuid, uuid) to authenticated;
grant execute on function public.has_group_role(
    uuid,
    public.group_role[],
    uuid
) to authenticated;

alter table public.groups enable row level security;
alter table public.group_members enable row level security;
alter table public.group_transactions enable row level security;
alter table public.group_transaction_payers enable row level security;
alter table public.group_transaction_shares enable row level security;
alter table public.group_settlement_suggestions enable row level security;
alter table public.group_transaction_comments enable row level security;
alter table public.group_invites enable row level security;
alter table public.group_notifications enable row level security;
alter table public.group_activities enable row level security;

drop policy if exists "groups_select_member" on public.groups;
create policy "groups_select_member"
on public.groups for select to authenticated
using (public.is_group_member(id));

drop policy if exists "groups_insert_creator" on public.groups;
create policy "groups_insert_creator"
on public.groups for insert to authenticated
with check (created_by = auth.uid());

drop policy if exists "groups_update_admin" on public.groups;
create policy "groups_update_admin"
on public.groups for update to authenticated
using (public.has_group_role(id, array['owner', 'admin']::public.group_role[]))
with check (
    public.has_group_role(id, array['owner', 'admin']::public.group_role[])
);

drop policy if exists "group_members_select_member" on public.group_members;
create policy "group_members_select_member"
on public.group_members for select to authenticated
using (public.is_group_member(group_id));

drop policy if exists "group_members_insert_admin" on public.group_members;
create policy "group_members_insert_admin"
on public.group_members for insert to authenticated
with check (
    public.has_group_role(
        group_id,
        array['owner', 'admin']::public.group_role[]
    )
);

drop policy if exists "group_members_update_admin" on public.group_members;
create policy "group_members_update_admin"
on public.group_members for update to authenticated
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

drop policy if exists "group_transactions_select_member"
    on public.group_transactions;
create policy "group_transactions_select_member"
on public.group_transactions for select to authenticated
using (public.is_group_member(group_id));

drop policy if exists "group_transactions_insert_active"
    on public.group_transactions;
create policy "group_transactions_insert_active"
on public.group_transactions for insert to authenticated
with check (
    created_by = auth.uid()
    and public.is_group_member(group_id)
);

drop policy if exists "group_transactions_update_creator"
    on public.group_transactions;
create policy "group_transactions_update_creator"
on public.group_transactions for update to authenticated
using (created_by = auth.uid() and public.is_group_member(group_id))
with check (created_by = auth.uid() and public.is_group_member(group_id));

drop policy if exists "group_transactions_delete_creator"
    on public.group_transactions;
create policy "group_transactions_delete_creator"
on public.group_transactions for delete to authenticated
using (created_by = auth.uid() and public.is_group_member(group_id));

drop policy if exists "group_payers_select_member"
    on public.group_transaction_payers;
create policy "group_payers_select_member"
on public.group_transaction_payers for select to authenticated
using (
    exists (
        select 1
        from public.group_transactions gt
        where gt.id = group_transaction_id
          and public.is_group_member(gt.group_id)
    )
);

drop policy if exists "group_shares_select_member"
    on public.group_transaction_shares;
create policy "group_shares_select_member"
on public.group_transaction_shares for select to authenticated
using (
    exists (
        select 1
        from public.group_transactions gt
        where gt.id = group_transaction_id
          and public.is_group_member(gt.group_id)
    )
);

drop policy if exists "group_settlements_select_member"
    on public.group_settlement_suggestions;
create policy "group_settlements_select_member"
on public.group_settlement_suggestions for select to authenticated
using (public.is_group_member(group_id));

drop policy if exists "group_comments_select_member"
    on public.group_transaction_comments;
create policy "group_comments_select_member"
on public.group_transaction_comments for select to authenticated
using (
    exists (
        select 1
        from public.group_transactions gt
        where gt.id = group_transaction_id
          and public.is_group_member(gt.group_id)
    )
);

drop policy if exists "group_comments_insert_active"
    on public.group_transaction_comments;
create policy "group_comments_insert_active"
on public.group_transaction_comments for insert to authenticated
with check (
    user_id = auth.uid()
    and exists (
        select 1
        from public.group_transactions gt
        where gt.id = group_transaction_id
          and public.is_group_member(gt.group_id)
    )
);

drop policy if exists "group_comments_update_own"
    on public.group_transaction_comments;
create policy "group_comments_update_own"
on public.group_transaction_comments for update to authenticated
using (user_id = auth.uid())
with check (user_id = auth.uid());

drop policy if exists "group_comments_delete_own"
    on public.group_transaction_comments;
create policy "group_comments_delete_own"
on public.group_transaction_comments for delete to authenticated
using (user_id = auth.uid());

drop policy if exists "group_invites_select_related" on public.group_invites;
create policy "group_invites_select_related"
on public.group_invites for select to authenticated
using (
    invited_user_id = auth.uid()
    or public.has_group_role(
        group_id,
        array['owner', 'admin']::public.group_role[]
    )
);

drop policy if exists "group_notifications_select_own"
    on public.group_notifications;
create policy "group_notifications_select_own"
on public.group_notifications for select to authenticated
using (user_id = auth.uid());

drop policy if exists "group_notifications_update_own"
    on public.group_notifications;
create policy "group_notifications_update_own"
on public.group_notifications for update to authenticated
using (user_id = auth.uid())
with check (user_id = auth.uid());

drop policy if exists "group_activities_select_member"
    on public.group_activities;
create policy "group_activities_select_member"
on public.group_activities for select to authenticated
using (public.is_group_member(group_id));

drop policy if exists "profiles_select_shared_group_members"
    on public.profiles;
create policy "profiles_select_shared_group_members"
on public.profiles for select to authenticated
using (
    id = auth.uid()
    or exists (
        select 1
        from public.group_members target_member
        join public.group_members current_member
          on current_member.group_id = target_member.group_id
        where target_member.user_id = profiles.id
          and current_member.user_id = auth.uid()
          and current_member.status = 'active'
    )
);

create or replace view public.group_balance_summary
with (security_invoker = true)
as
with member_keys as (
    select gm.group_id, gm.user_id
    from public.group_members gm
    where gm.status in ('active', 'left')
),
share_totals as (
    select
        gt.group_id,
        gts.user_id,
        sum(gts.share_amount)::bigint as total_share_amount
    from public.group_transactions gt
    join public.group_transaction_shares gts
      on gts.group_transaction_id = gt.id
    where gt.split_status = 'posted'
    group by gt.group_id, gts.user_id
),
paid_totals as (
    select
        gt.group_id,
        gtp.user_id,
        sum(gtp.paid_amount)::bigint as total_paid_amount
    from public.group_transactions gt
    join public.group_transaction_payers gtp
      on gtp.group_transaction_id = gt.id
    where gt.split_status = 'posted'
    group by gt.group_id, gtp.user_id
),
settlement_adjustments as (
    select
        group_id,
        user_id,
        sum(amount)::bigint as adjustment
    from (
        select
            gss.group_id,
            gss.from_user_id as user_id,
            -gss.amount as amount
        from public.group_settlement_suggestions gss
        where gss.status = 'completed'
        union all
        select
            gss.group_id,
            gss.to_user_id as user_id,
            gss.amount
        from public.group_settlement_suggestions gss
        where gss.status = 'completed'
    ) completed_ledger
    group by group_id, user_id
)
select
    mk.group_id,
    mk.user_id,
    coalesce(st.total_share_amount, 0)::bigint as total_share_amount,
    coalesce(pt.total_paid_amount, 0)::bigint as total_paid_amount,
    (
        coalesce(st.total_share_amount, 0)
        - coalesce(pt.total_paid_amount, 0)
        + coalesce(sa.adjustment, 0)
    )::bigint as balance
from member_keys mk
left join share_totals st
  on st.group_id = mk.group_id and st.user_id = mk.user_id
left join paid_totals pt
  on pt.group_id = mk.group_id and pt.user_id = mk.user_id
left join settlement_adjustments sa
  on sa.group_id = mk.group_id and sa.user_id = mk.user_id;

grant select on public.group_balance_summary to authenticated;

create or replace function public.refresh_group_settlements(p_group_id uuid)
returns void
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
    v_debtor_id uuid;
    v_creditor_id uuid;
    v_debt bigint;
    v_credit bigint;
    v_amount bigint;
begin
    if not public.is_group_member(p_group_id) then
        raise exception 'GROUP_MEMBER_REQUIRED';
    end if;

    delete from public.group_settlement_suggestions
    where group_id = p_group_id
      and status = 'pending';

    create temporary table if not exists group_work_balances (
        user_id uuid primary key,
        balance bigint not null
    ) on commit delete rows;

    truncate table pg_temp.group_work_balances;

    insert into pg_temp.group_work_balances (user_id, balance)
    select user_id, balance
    from public.group_balance_summary
    where group_id = p_group_id;

    with reserved as (
        select
            user_id,
            sum(amount)::bigint as amount
        from (
            select from_user_id as user_id, -amount as amount
            from public.group_settlement_suggestions
            where group_id = p_group_id
              and status = 'payer_marked_paid'
            union all
            select to_user_id as user_id, amount
            from public.group_settlement_suggestions
            where group_id = p_group_id
              and status = 'payer_marked_paid'
        ) reserved_ledger
        group by user_id
    )
    update pg_temp.group_work_balances work
    set balance = work.balance + reserved.amount
    from reserved
    where reserved.user_id = work.user_id;

    loop
        select user_id, balance
        into v_debtor_id, v_debt
        from pg_temp.group_work_balances
        where balance > 0
        order by balance desc, user_id
        limit 1;

        select user_id, balance
        into v_creditor_id, v_credit
        from pg_temp.group_work_balances
        where balance < 0
        order by balance asc, user_id
        limit 1;

        exit when v_debtor_id is null or v_creditor_id is null;

        v_amount := least(v_debt, abs(v_credit));

        insert into public.group_settlement_suggestions (
            group_id,
            from_user_id,
            to_user_id,
            amount
        )
        values (p_group_id, v_debtor_id, v_creditor_id, v_amount);

        update pg_temp.group_work_balances
        set balance = balance - v_amount
        where user_id = v_debtor_id;

        update pg_temp.group_work_balances
        set balance = balance + v_amount
        where user_id = v_creditor_id;

        v_debtor_id := null;
        v_creditor_id := null;
    end loop;
end;
$$;

create or replace function public.populate_group_transaction(
    p_transaction_id uuid,
    p_total_amount bigint,
    p_split_mode public.group_split_mode,
    p_payment_mode public.group_payment_mode,
    p_payer_amounts jsonb
)
returns public.group_split_status
language plpgsql
security definer
set search_path = public
as $$
declare
    v_group_id uuid;
    v_member_count integer;
    v_base_share bigint;
    v_remainder bigint;
    v_payer_count integer;
    v_paid_total bigint;
    v_all_positive boolean;
begin
    select group_id
    into v_group_id
    from public.group_transactions
    where id = p_transaction_id;

    select count(*)
    into v_member_count
    from public.group_members
    where group_id = v_group_id
      and status = 'active';

    if p_total_amount <= 0 then
        raise exception 'GROUP_TOTAL_AMOUNT_INVALID';
    end if;
    if v_member_count = 0 then
        raise exception 'GROUP_NO_ACTIVE_MEMBERS';
    end if;

    if p_payment_mode <> 'everyone_paid' then
        select
            count(*),
            coalesce(sum(value::bigint), 0),
            coalesce(bool_and(value::bigint > 0), false)
        into v_payer_count, v_paid_total, v_all_positive
        from jsonb_each_text(coalesce(p_payer_amounts, '{}'::jsonb));

        if p_payment_mode = 'single_payer' and v_payer_count <> 1 then
            raise exception 'GROUP_PAYER_REQUIRED';
        end if;
        if p_payment_mode = 'multiple_payers' and v_payer_count < 2 then
            raise exception 'GROUP_MULTIPLE_PAYERS_REQUIRED';
        end if;
        if not v_all_positive then
            raise exception 'GROUP_PAYER_AMOUNT_INVALID';
        end if;
        if v_paid_total <> p_total_amount then
            raise exception 'GROUP_PAID_TOTAL_MISMATCH';
        end if;
        if exists (
            select 1
            from jsonb_object_keys(coalesce(p_payer_amounts, '{}'::jsonb)) key
            where not public.is_group_member(v_group_id, key::uuid)
        ) then
            raise exception 'GROUP_PAYER_NOT_ACTIVE';
        end if;
    end if;

    if p_split_mode = 'equal' then
        v_base_share := p_total_amount / v_member_count;
        v_remainder := p_total_amount % v_member_count;

        insert into public.group_transaction_shares (
            group_transaction_id,
            user_id,
            share_amount,
            input_status,
            submitted_at
        )
        select
            p_transaction_id,
            ordered.user_id,
            v_base_share
                + case when ordered.position <= v_remainder then 1 else 0 end,
            'submitted',
            timezone('utc', now())
        from (
            select
                gm.user_id,
                row_number() over (order by gm.joined_at, gm.user_id) as position
            from public.group_members gm
            where gm.group_id = v_group_id
              and gm.status = 'active'
        ) ordered;

        if p_payment_mode = 'everyone_paid' then
            insert into public.group_transaction_payers (
                group_transaction_id,
                user_id,
                paid_amount
            )
            select
                group_transaction_id,
                user_id,
                share_amount
            from public.group_transaction_shares
            where group_transaction_id = p_transaction_id;
        else
            insert into public.group_transaction_payers (
                group_transaction_id,
                user_id,
                paid_amount
            )
            select
                p_transaction_id,
                key::uuid,
                value::bigint
            from jsonb_each_text(p_payer_amounts);
        end if;
        return 'posted';
    end if;

    insert into public.group_transaction_shares (
        group_transaction_id,
        user_id,
        share_amount,
        input_status
    )
    select p_transaction_id, gm.user_id, 0, 'pending'
    from public.group_members gm
    where gm.group_id = v_group_id
      and gm.status = 'active';

    if p_payment_mode <> 'everyone_paid' then
        insert into public.group_transaction_payers (
            group_transaction_id,
            user_id,
            paid_amount
        )
        select
            p_transaction_id,
            key::uuid,
            value::bigint
        from jsonb_each_text(p_payer_amounts);
    end if;

    insert into public.group_notifications (
        group_id,
        user_id,
        group_transaction_id,
        type
    )
    select
        v_group_id,
        gm.user_id,
        p_transaction_id,
        'member_amount_input_required'
    from public.group_members gm
    where gm.group_id = v_group_id
      and gm.status = 'active';

    return 'pending_member_amount_input';
end;
$$;

create or replace function public.create_expense_group(
    p_name text,
    p_description text default null,
    p_type text default null
)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
    v_user_id uuid := auth.uid();
    v_group_id uuid;
begin
    if v_user_id is null then
        raise exception 'AUTH_REQUIRED';
    end if;
    if btrim(coalesce(p_name, '')) = '' then
        raise exception 'GROUP_NAME_REQUIRED';
    end if;

    insert into public.groups (name, description, type, created_by)
    values (
        btrim(p_name),
        nullif(btrim(coalesce(p_description, '')), ''),
        nullif(btrim(coalesce(p_type, '')), ''),
        v_user_id
    )
    returning id into v_group_id;

    insert into public.group_members (
        group_id,
        user_id,
        role,
        status
    )
    values (v_group_id, v_user_id, 'owner', 'active');

    return v_group_id;
end;
$$;

create or replace function public.create_group_invite_link(p_group_id uuid)
returns text
language plpgsql
security definer
set search_path = public
as $$
declare
    v_token text;
begin
    if not public.has_group_role(
        p_group_id,
        array['owner', 'admin']::public.group_role[]
    ) then
        raise exception 'GROUP_ADMIN_REQUIRED';
    end if;

    insert into public.group_invites (group_id, invited_by)
    values (p_group_id, auth.uid())
    returning token into v_token;

    return 'moniary://groups/invite/' || v_token;
end;
$$;

create or replace function public.invite_group_member_by_username(
    p_group_id uuid,
    p_username text
)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
    v_invited_user_id uuid;
begin
    if not public.has_group_role(
        p_group_id,
        array['owner', 'admin']::public.group_role[]
    ) then
        raise exception 'GROUP_ADMIN_REQUIRED';
    end if;

    select id
    into v_invited_user_id
    from public.profiles
    where lower(username) = lower(btrim(p_username))
    limit 1;

    if v_invited_user_id is null then
        raise exception 'GROUP_USER_NOT_FOUND';
    end if;

    if exists (
        select 1
        from public.group_members
        where group_id = p_group_id
          and user_id = v_invited_user_id
          and status in ('active', 'invited')
    ) then
        raise exception 'GROUP_MEMBER_ALREADY_INVITED';
    end if;

    insert into public.group_members (
        group_id,
        user_id,
        role,
        status
    )
    values (p_group_id, v_invited_user_id, 'member', 'invited')
    on conflict (group_id, user_id) do update
    set status = 'invited',
        role = 'member',
        left_at = null;

    insert into public.group_invites (
        group_id,
        invited_user_id,
        invited_by
    )
    values (p_group_id, v_invited_user_id, auth.uid())
    on conflict (group_id, invited_user_id)
        where invited_user_id is not null and status = 'pending'
    do nothing;

    insert into public.group_notifications (group_id, user_id, type)
    values (p_group_id, v_invited_user_id, 'group_invite');
end;
$$;

create or replace function public.create_group_transaction(
    p_group_id uuid,
    p_total_amount bigint,
    p_category_id uuid,
    p_category_name text,
    p_caption text,
    p_note text,
    p_split_mode text,
    p_payment_mode text,
    p_payer_amounts jsonb default '{}'::jsonb
)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
    v_transaction_id uuid;
    v_split_status public.group_split_status;
begin
    if not public.is_group_member(p_group_id) then
        raise exception 'GROUP_MEMBER_REQUIRED';
    end if;

    insert into public.group_transactions (
        group_id,
        created_by,
        total_amount,
        category_id,
        category_name_snapshot,
        caption,
        note,
        split_mode,
        payment_mode,
        split_status
    )
    values (
        p_group_id,
        auth.uid(),
        p_total_amount,
        p_category_id,
        nullif(btrim(coalesce(p_category_name, '')), ''),
        nullif(btrim(coalesce(p_caption, '')), ''),
        nullif(btrim(coalesce(p_note, '')), ''),
        p_split_mode::public.group_split_mode,
        p_payment_mode::public.group_payment_mode,
        'draft'
    )
    returning id into v_transaction_id;

    v_split_status := public.populate_group_transaction(
        v_transaction_id,
        p_total_amount,
        p_split_mode::public.group_split_mode,
        p_payment_mode::public.group_payment_mode,
        coalesce(p_payer_amounts, '{}'::jsonb)
    );

    update public.group_transactions
    set split_status = v_split_status
    where id = v_transaction_id;

    if v_split_status = 'posted' then
        perform public.refresh_group_settlements(p_group_id);
    end if;

    return v_transaction_id;
end;
$$;

create or replace function public.update_group_transaction(
    p_transaction_id uuid,
    p_total_amount bigint,
    p_category_id uuid,
    p_category_name text,
    p_caption text,
    p_note text,
    p_split_mode text,
    p_payment_mode text,
    p_payer_amounts jsonb default '{}'::jsonb
)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
    v_group_id uuid;
    v_created_by uuid;
    v_split_status public.group_split_status;
begin
    select group_id, created_by
    into v_group_id, v_created_by
    from public.group_transactions
    where id = p_transaction_id
    for update;

    if v_group_id is null then
        raise exception 'NOT_FOUND';
    end if;
    if v_created_by <> auth.uid() then
        raise exception 'GROUP_CREATOR_ONLY';
    end if;

    delete from public.group_transaction_payers
    where group_transaction_id = p_transaction_id;
    delete from public.group_transaction_shares
    where group_transaction_id = p_transaction_id;

    update public.group_transactions
    set total_amount = p_total_amount,
        category_id = p_category_id,
        category_name_snapshot =
            nullif(btrim(coalesce(p_category_name, '')), ''),
        caption = nullif(btrim(coalesce(p_caption, '')), ''),
        note = nullif(btrim(coalesce(p_note, '')), ''),
        split_mode = p_split_mode::public.group_split_mode,
        payment_mode = p_payment_mode::public.group_payment_mode,
        split_status = 'draft'
    where id = p_transaction_id;

    v_split_status := public.populate_group_transaction(
        p_transaction_id,
        p_total_amount,
        p_split_mode::public.group_split_mode,
        p_payment_mode::public.group_payment_mode,
        coalesce(p_payer_amounts, '{}'::jsonb)
    );

    update public.group_transactions
    set split_status = v_split_status
    where id = p_transaction_id;

    perform public.refresh_group_settlements(v_group_id);
end;
$$;

create or replace function public.delete_group_transaction(
    p_transaction_id uuid
)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
    v_group_id uuid;
    v_created_by uuid;
begin
    select group_id, created_by
    into v_group_id, v_created_by
    from public.group_transactions
    where id = p_transaction_id;

    if v_group_id is null then
        raise exception 'NOT_FOUND';
    end if;
    if v_created_by <> auth.uid() then
        raise exception 'GROUP_CREATOR_ONLY';
    end if;

    delete from public.group_transactions
    where id = p_transaction_id;

    perform public.refresh_group_settlements(v_group_id);
end;
$$;

create or replace function public.submit_group_member_amount(
    p_transaction_id uuid,
    p_share_amount bigint
)
returns public.group_split_status
language plpgsql
security definer
set search_path = public
as $$
declare
    v_group_id uuid;
    v_total_amount bigint;
    v_payment_mode public.group_payment_mode;
    v_pending_count integer;
    v_share_total bigint;
begin
    if p_share_amount < 0 then
        raise exception 'GROUP_SHARE_AMOUNT_INVALID';
    end if;

    select group_id, total_amount, payment_mode
    into v_group_id, v_total_amount, v_payment_mode
    from public.group_transactions
    where id = p_transaction_id
      and split_mode = 'unequal'
      and split_status in (
          'pending_member_amount_input',
          'amount_mismatch'
      )
    for update;

    if v_group_id is null then
        raise exception 'NOT_FOUND';
    end if;
    if not public.is_group_member(v_group_id) then
        raise exception 'GROUP_MEMBER_REQUIRED';
    end if;

    update public.group_transaction_shares
    set share_amount = p_share_amount,
        input_status = 'submitted',
        submitted_at = timezone('utc', now())
    where group_transaction_id = p_transaction_id
      and user_id = auth.uid();

    if not found then
        raise exception 'GROUP_SHARE_NOT_FOUND';
    end if;

    select
        count(*) filter (where input_status = 'pending'),
        sum(share_amount)::bigint
    into v_pending_count, v_share_total
    from public.group_transaction_shares
    where group_transaction_id = p_transaction_id;

    if v_pending_count > 0 then
        update public.group_transactions
        set split_status = 'pending_member_amount_input'
        where id = p_transaction_id;
        return 'pending_member_amount_input';
    end if;

    if v_share_total <> v_total_amount then
        update public.group_transactions
        set split_status = 'amount_mismatch'
        where id = p_transaction_id;

        delete from public.group_settlement_suggestions
        where group_id = v_group_id
          and status = 'pending';

        insert into public.group_notifications (
            group_id,
            user_id,
            group_transaction_id,
            type
        )
        select
            v_group_id,
            gm.user_id,
            p_transaction_id,
            'member_amount_mismatch'
        from public.group_members gm
        where gm.group_id = v_group_id
          and gm.status = 'active';

        return 'amount_mismatch';
    end if;

    if v_payment_mode = 'everyone_paid' then
        delete from public.group_transaction_payers
        where group_transaction_id = p_transaction_id;

        insert into public.group_transaction_payers (
            group_transaction_id,
            user_id,
            paid_amount
        )
        select
            group_transaction_id,
            user_id,
            share_amount
        from public.group_transaction_shares
        where group_transaction_id = p_transaction_id;
    end if;

    update public.group_transactions
    set split_status = 'posted'
    where id = p_transaction_id;

    perform public.refresh_group_settlements(v_group_id);

    insert into public.group_notifications (
        group_id,
        user_id,
        group_transaction_id,
        type
    )
    select
        v_group_id,
        gm.user_id,
        p_transaction_id,
        'group_transaction_posted'
    from public.group_members gm
    where gm.group_id = v_group_id
      and gm.status = 'active';

    return 'posted';
end;
$$;

create or replace function public.mark_group_settlement_paid(
    p_settlement_id uuid
)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
    update public.group_settlement_suggestions
    set status = 'payer_marked_paid',
        payer_marked_paid_at = timezone('utc', now())
    where id = p_settlement_id
      and from_user_id = auth.uid()
      and status = 'pending';

    if not found then
        raise exception 'GROUP_SETTLEMENT_FORBIDDEN';
    end if;
end;
$$;

create or replace function public.confirm_group_settlement_received(
    p_settlement_id uuid
)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
    v_group_id uuid;
begin
    update public.group_settlement_suggestions
    set status = 'completed',
        receiver_confirmed_at = timezone('utc', now())
    where id = p_settlement_id
      and to_user_id = auth.uid()
      and status = 'payer_marked_paid'
    returning group_id into v_group_id;

    if v_group_id is null then
        raise exception 'GROUP_SETTLEMENT_FORBIDDEN';
    end if;

    perform public.refresh_group_settlements(v_group_id);
end;
$$;

create or replace function public.leave_expense_group(p_group_id uuid)
returns text
language plpgsql
security definer
set search_path = public
as $$
declare
    v_role public.group_role;
    v_balance bigint;
    v_unresolved boolean;
    v_other_owner_count integer;
begin
    select role
    into v_role
    from public.group_members
    where group_id = p_group_id
      and user_id = auth.uid()
      and status = 'active'
    for update;

    if v_role is null then
        raise exception 'GROUP_MEMBER_REQUIRED';
    end if;

    select coalesce(balance, 0)
    into v_balance
    from public.group_balance_summary
    where group_id = p_group_id
      and user_id = auth.uid();

    select exists (
        select 1
        from public.group_settlement_suggestions
        where group_id = p_group_id
          and status in ('pending', 'payer_marked_paid')
          and (
              from_user_id = auth.uid()
              or to_user_id = auth.uid()
          )
    )
    into v_unresolved;

    if coalesce(v_balance, 0) <> 0 or v_unresolved then
        insert into public.group_activities (
            group_id,
            actor_user_id,
            type
        )
        values (p_group_id, auth.uid(), 'leave_blocked_unresolved');

        insert into public.group_notifications (group_id, user_id, type)
        select p_group_id, gm.user_id, 'member_leave_blocked_warning'
        from public.group_members gm
        where gm.group_id = p_group_id
          and gm.status = 'active'
          and gm.user_id <> auth.uid();

        return 'unresolved';
    end if;

    if v_role = 'owner' then
        select count(*)
        into v_other_owner_count
        from public.group_members
        where group_id = p_group_id
          and user_id <> auth.uid()
          and status = 'active'
          and role = 'owner';

        if v_other_owner_count = 0 then
            return 'owner_transfer_required';
        end if;
    end if;

    update public.group_members
    set status = 'left',
        left_at = timezone('utc', now())
    where group_id = p_group_id
      and user_id = auth.uid();

    insert into public.group_activities (
        group_id,
        actor_user_id,
        type
    )
    values (p_group_id, auth.uid(), 'member_left');

    return 'left';
end;
$$;

revoke all on function public.refresh_group_settlements(uuid) from public;
revoke all on function public.populate_group_transaction(
    uuid,
    bigint,
    public.group_split_mode,
    public.group_payment_mode,
    jsonb
) from public;
revoke all on function public.create_expense_group(text, text, text)
    from public;
revoke all on function public.create_group_invite_link(uuid) from public;
revoke all on function public.invite_group_member_by_username(uuid, text)
    from public;
revoke all on function public.create_group_transaction(
    uuid,
    bigint,
    uuid,
    text,
    text,
    text,
    text,
    text,
    jsonb
) from public;
revoke all on function public.update_group_transaction(
    uuid,
    bigint,
    uuid,
    text,
    text,
    text,
    text,
    text,
    jsonb
) from public;
revoke all on function public.delete_group_transaction(uuid) from public;
revoke all on function public.submit_group_member_amount(uuid, bigint)
    from public;
revoke all on function public.mark_group_settlement_paid(uuid) from public;
revoke all on function public.confirm_group_settlement_received(uuid)
    from public;
revoke all on function public.leave_expense_group(uuid) from public;

grant execute on function public.create_expense_group(text, text, text)
    to authenticated;
grant execute on function public.create_group_invite_link(uuid)
    to authenticated;
grant execute on function public.invite_group_member_by_username(uuid, text)
    to authenticated;
grant execute on function public.create_group_transaction(
    uuid,
    bigint,
    uuid,
    text,
    text,
    text,
    text,
    text,
    jsonb
) to authenticated;
grant execute on function public.update_group_transaction(
    uuid,
    bigint,
    uuid,
    text,
    text,
    text,
    text,
    text,
    jsonb
) to authenticated;
grant execute on function public.delete_group_transaction(uuid)
    to authenticated;
grant execute on function public.submit_group_member_amount(uuid, bigint)
    to authenticated;
grant execute on function public.mark_group_settlement_paid(uuid)
    to authenticated;
grant execute on function public.confirm_group_settlement_received(uuid)
    to authenticated;
grant execute on function public.leave_expense_group(uuid) to authenticated;

drop policy if exists "storage_select_group_images" on storage.objects;
create policy "storage_select_group_images"
on storage.objects for select to authenticated
using (
    bucket_id = 'transaction-images'
    and (storage.foldername(name))[1] in ('groups', 'group-transactions')
    and public.is_group_member(
        ((storage.foldername(name))[2])::uuid
    )
);

drop policy if exists "storage_insert_group_avatar" on storage.objects;
create policy "storage_insert_group_avatar"
on storage.objects for insert to authenticated
with check (
    bucket_id = 'transaction-images'
    and (storage.foldername(name))[1] = 'groups'
    and public.has_group_role(
        ((storage.foldername(name))[2])::uuid,
        array['owner', 'admin']::public.group_role[]
    )
);

drop policy if exists "storage_update_group_avatar" on storage.objects;
create policy "storage_update_group_avatar"
on storage.objects for update to authenticated
using (
    bucket_id = 'transaction-images'
    and (storage.foldername(name))[1] = 'groups'
    and public.has_group_role(
        ((storage.foldername(name))[2])::uuid,
        array['owner', 'admin']::public.group_role[]
    )
)
with check (
    bucket_id = 'transaction-images'
    and (storage.foldername(name))[1] = 'groups'
    and public.has_group_role(
        ((storage.foldername(name))[2])::uuid,
        array['owner', 'admin']::public.group_role[]
    )
);

drop policy if exists "storage_insert_group_transaction_image"
    on storage.objects;
create policy "storage_insert_group_transaction_image"
on storage.objects for insert to authenticated
with check (
    bucket_id = 'transaction-images'
    and (storage.foldername(name))[1] = 'group-transactions'
    and exists (
        select 1
        from public.group_transactions gt
        where gt.id = ((storage.foldername(name))[3])::uuid
          and gt.group_id = ((storage.foldername(name))[2])::uuid
          and gt.created_by = auth.uid()
    )
);

drop policy if exists "storage_update_group_transaction_image"
    on storage.objects;
create policy "storage_update_group_transaction_image"
on storage.objects for update to authenticated
using (
    bucket_id = 'transaction-images'
    and (storage.foldername(name))[1] = 'group-transactions'
    and exists (
        select 1
        from public.group_transactions gt
        where gt.id = ((storage.foldername(name))[3])::uuid
          and gt.group_id = ((storage.foldername(name))[2])::uuid
          and gt.created_by = auth.uid()
    )
)
with check (
    bucket_id = 'transaction-images'
    and (storage.foldername(name))[1] = 'group-transactions'
    and exists (
        select 1
        from public.group_transactions gt
        where gt.id = ((storage.foldername(name))[3])::uuid
          and gt.group_id = ((storage.foldername(name))[2])::uuid
          and gt.created_by = auth.uid()
    )
);
