-- Community participation primitives: lightweight polls and shared savings goals.

create table if not exists public.group_polls (
    id uuid primary key default gen_random_uuid(),
    group_id uuid not null references public.groups(id) on delete cascade,
    created_by uuid not null references public.profiles(id) on delete restrict,
    title text not null,
    is_closed boolean not null default false,
    created_at timestamptz not null default timezone('utc', now()),
    constraint group_polls_title_check check (btrim(title) <> '')
);
create table if not exists public.group_poll_options (
    id uuid primary key default gen_random_uuid(),
    poll_id uuid not null references public.group_polls(id) on delete cascade,
    label text not null,
    vote_count integer not null default 0,
    constraint group_poll_options_label_check check (btrim(label) <> '')
);
create table if not exists public.group_poll_votes (
    poll_id uuid not null references public.group_polls(id) on delete cascade,
    option_id uuid not null references public.group_poll_options(id) on delete cascade,
    user_id uuid not null references public.profiles(id) on delete cascade,
    created_at timestamptz not null default timezone('utc', now()),
    primary key (poll_id, user_id)
);
alter table public.group_polls enable row level security;
alter table public.group_poll_options enable row level security;
alter table public.group_poll_votes enable row level security;
create policy "group_polls_select_member" on public.group_polls for select to authenticated
using (public.is_group_member(group_id));
create policy "group_poll_options_select_member" on public.group_poll_options for select to authenticated
using (exists (select 1 from public.group_polls p where p.id = poll_id and public.is_group_member(p.group_id)));
create policy "group_poll_votes_select_member" on public.group_poll_votes for select to authenticated
using (exists (select 1 from public.group_polls p where p.id = poll_id and public.is_group_member(p.group_id)));

create or replace function public.create_group_poll(
    p_group_id uuid, p_title text, p_options jsonb
)
returns uuid language plpgsql security definer set search_path = public
as $$
declare v_poll uuid; v_option text;
begin
    if auth.uid() is null or not public.is_group_member(p_group_id, auth.uid()) then
        raise exception 'GROUP_MEMBER_REQUIRED';
    end if;
    if jsonb_array_length(coalesce(p_options, '[]'::jsonb)) < 2
       or jsonb_array_length(coalesce(p_options, '[]'::jsonb)) > 6 then
        raise exception 'POLL_OPTIONS_INVALID';
    end if;
    insert into public.group_polls(group_id, created_by, title)
    values (p_group_id, auth.uid(), btrim(p_title)) returning id into v_poll;
    for v_option in select value from jsonb_array_elements_text(p_options) loop
        insert into public.group_poll_options(poll_id, label) values (v_poll, btrim(v_option));
    end loop;
    return v_poll;
end;
$$;
create or replace function public.vote_group_poll(p_poll_id uuid, p_option_id uuid)
returns void language plpgsql security definer set search_path = public
as $$
declare v_group uuid; v_old uuid;
begin
    select group_id into v_group from public.group_polls
    where id = p_poll_id and not is_closed;
    if v_group is null or not public.is_group_member(v_group) then
        raise exception 'POLL_NOT_AVAILABLE';
    end if;
    if not exists (select 1 from public.group_poll_options where id = p_option_id and poll_id = p_poll_id) then
        raise exception 'POLL_OPTION_INVALID';
    end if;
    select option_id into v_old from public.group_poll_votes
    where poll_id = p_poll_id and user_id = auth.uid();
    if v_old = p_option_id then return; end if;
    if v_old is not null then
        update public.group_poll_options set vote_count = greatest(vote_count - 1, 0) where id = v_old;
        delete from public.group_poll_votes where poll_id = p_poll_id and user_id = auth.uid();
    end if;
    insert into public.group_poll_votes(poll_id, option_id, user_id)
    values (p_poll_id, p_option_id, auth.uid());
    update public.group_poll_options set vote_count = vote_count + 1 where id = p_option_id;
end;
$$;
create or replace function public.close_group_poll(p_poll_id uuid)
returns void language plpgsql security definer set search_path = public
as $$
begin
    update public.group_polls p set is_closed = true
    where p.id = p_poll_id and (
        p.created_by = auth.uid() or public.has_group_role(
            p.group_id, array['owner', 'admin']::public.group_role[], auth.uid()
        )
    );
    if not found then raise exception 'POLL_CLOSE_NOT_ALLOWED' using errcode = '42501'; end if;
end;
$$;
revoke all on function public.create_group_poll(uuid, text, jsonb) from public;
grant execute on function public.create_group_poll(uuid, text, jsonb) to authenticated;
revoke all on function public.vote_group_poll(uuid, uuid) from public;
grant execute on function public.vote_group_poll(uuid, uuid) to authenticated;
revoke all on function public.close_group_poll(uuid) from public;
grant execute on function public.close_group_poll(uuid) to authenticated;

create table if not exists public.group_savings_challenges (
    id uuid primary key default gen_random_uuid(),
    group_id uuid not null references public.groups(id) on delete cascade,
    created_by uuid not null references public.profiles(id) on delete restrict,
    title text not null,
    target_amount bigint not null,
    start_date date not null,
    end_date date not null,
    is_active boolean not null default true,
    created_at timestamptz not null default timezone('utc', now()),
    constraint group_savings_challenge_amount_check check (target_amount > 0),
    constraint group_savings_challenge_dates_check check (end_date >= start_date)
);
create table if not exists public.group_savings_contributions (
    id uuid primary key default gen_random_uuid(),
    challenge_id uuid not null references public.group_savings_challenges(id) on delete cascade,
    user_id uuid not null references public.profiles(id) on delete restrict,
    amount bigint not null,
    note text,
    created_at timestamptz not null default timezone('utc', now()),
    constraint group_savings_contribution_amount_check check (amount > 0)
);
alter table public.group_savings_challenges enable row level security;
alter table public.group_savings_contributions enable row level security;
create policy "group_savings_challenges_select_member" on public.group_savings_challenges
for select to authenticated using (public.is_group_member(group_id));
create policy "group_savings_contributions_select_member" on public.group_savings_contributions
for select to authenticated using (exists (select 1 from public.group_savings_challenges c
    where c.id = challenge_id and public.is_group_member(c.group_id)));
create policy "group_savings_contributions_insert_member" on public.group_savings_contributions
for insert to authenticated with check (user_id = auth.uid() and exists (
    select 1 from public.group_savings_challenges c
    where c.id = challenge_id and c.is_active and public.is_group_member(c.group_id)
));

create or replace function public.create_group_savings_challenge(
    p_group_id uuid, p_title text, p_target_amount bigint,
    p_start_date date, p_end_date date
)
returns uuid language plpgsql security definer set search_path = public
as $$
declare v_id uuid;
begin
    if not public.has_group_role(p_group_id, array['owner', 'admin']::public.group_role[], auth.uid()) then
        raise exception 'GROUP_ADMIN_REQUIRED' using errcode = '42501';
    end if;
    insert into public.group_savings_challenges(
        group_id, created_by, title, target_amount, start_date, end_date
    ) values (p_group_id, auth.uid(), btrim(p_title), p_target_amount, p_start_date, p_end_date)
    returning id into v_id;
    return v_id;
end;
$$;
revoke all on function public.create_group_savings_challenge(uuid, text, bigint, date, date) from public;
grant execute on function public.create_group_savings_challenge(uuid, text, bigint, date, date) to authenticated;
