-- Community content: member-only posts, private album media, reactions and comments.

create table if not exists public.group_community_posts (
    id uuid primary key default gen_random_uuid(),
    group_id uuid not null references public.groups(id) on delete cascade,
    author_user_id uuid not null references public.profiles(id) on delete restrict,
    post_type text not null default 'text',
    content text,
    linked_transaction_id uuid references public.group_transactions(id) on delete set null,
    linked_poll_id uuid references public.group_polls(id) on delete set null,
    linked_challenge_id uuid references public.group_savings_challenges(id) on delete set null,
    created_at timestamptz not null default timezone('utc', now()),
    updated_at timestamptz not null default timezone('utc', now()),
    deleted_at timestamptz,
    constraint group_community_posts_type_check
        check (post_type in ('text', 'photo', 'activity', 'poll', 'challenge')),
    constraint group_community_posts_content_check
        check (content is null or btrim(content) <> '')
);

create table if not exists public.group_community_media (
    id uuid primary key default gen_random_uuid(),
    group_id uuid not null references public.groups(id) on delete cascade,
    post_id uuid not null references public.group_community_posts(id) on delete cascade,
    created_by uuid not null references public.profiles(id) on delete restrict,
    media_kind text not null default 'memory',
    storage_path text,
    caption text,
    created_at timestamptz not null default timezone('utc', now()),
    constraint group_community_media_kind_check
        check (media_kind in ('memory', 'receipt')),
    constraint group_community_media_caption_check
        check (caption is null or btrim(caption) <> ''),
    constraint group_community_media_storage_path_check
        check (storage_path is null or btrim(storage_path) <> '')
);

create table if not exists public.group_community_post_reactions (
    post_id uuid not null references public.group_community_posts(id) on delete cascade,
    user_id uuid not null references public.profiles(id) on delete cascade,
    emoji text not null,
    created_at timestamptz not null default timezone('utc', now()),
    primary key (post_id, user_id, emoji),
    constraint group_community_post_reaction_emoji_check
        check (emoji in ('❤️', '👍', '🎉', '😂', '👏', '🔥'))
);

create table if not exists public.group_community_post_comments (
    id uuid primary key default gen_random_uuid(),
    post_id uuid not null references public.group_community_posts(id) on delete cascade,
    user_id uuid not null references public.profiles(id) on delete restrict,
    content text not null,
    created_at timestamptz not null default timezone('utc', now()),
    updated_at timestamptz not null default timezone('utc', now()),
    constraint group_community_post_comments_content_check
        check (btrim(content) <> '')
);

create index if not exists group_community_posts_group_created_idx
    on public.group_community_posts(group_id, created_at desc)
    where deleted_at is null;
create index if not exists group_community_media_group_created_idx
    on public.group_community_media(group_id, created_at desc);
create index if not exists group_community_post_comments_post_created_idx
    on public.group_community_post_comments(post_id, created_at);

alter table public.group_community_posts enable row level security;
alter table public.group_community_media enable row level security;
alter table public.group_community_post_reactions enable row level security;
alter table public.group_community_post_comments enable row level security;

drop policy if exists "group_community_posts_select_member"
    on public.group_community_posts;
create policy "group_community_posts_select_member"
on public.group_community_posts for select to authenticated
using (public.is_group_member(group_id) and deleted_at is null);

drop policy if exists "group_community_posts_insert_member"
    on public.group_community_posts;
create policy "group_community_posts_insert_member"
on public.group_community_posts for insert to authenticated
with check (author_user_id = auth.uid() and public.is_group_member(group_id));

drop policy if exists "group_community_posts_update_author_or_admin"
    on public.group_community_posts;
create policy "group_community_posts_update_author_or_admin"
on public.group_community_posts for update to authenticated
using (
    author_user_id = auth.uid()
    or public.has_group_role(
        group_id,
        array['owner', 'admin']::public.group_role[]
    )
)
with check (
    author_user_id = auth.uid()
    or public.has_group_role(
        group_id,
        array['owner', 'admin']::public.group_role[]
    )
);

drop policy if exists "group_community_media_select_member"
    on public.group_community_media;
create policy "group_community_media_select_member"
on public.group_community_media for select to authenticated
using (public.is_group_member(group_id));

drop policy if exists "group_community_media_insert_member"
    on public.group_community_media;
create policy "group_community_media_insert_member"
on public.group_community_media for insert to authenticated
with check (
    created_by = auth.uid()
    and public.is_group_member(group_id)
    and exists (
        select 1
        from public.group_community_posts p
        where p.id = post_id
          and p.group_id = group_community_media.group_id
          and p.deleted_at is null
    )
);

drop policy if exists "group_community_media_update_author_or_admin"
    on public.group_community_media;
create policy "group_community_media_update_author_or_admin"
on public.group_community_media for update to authenticated
using (
    created_by = auth.uid()
    or public.has_group_role(
        group_id,
        array['owner', 'admin']::public.group_role[]
    )
);

drop policy if exists "group_community_media_delete_author_or_admin"
    on public.group_community_media;
create policy "group_community_media_delete_author_or_admin"
on public.group_community_media for delete to authenticated
using (
    created_by = auth.uid()
    or public.has_group_role(
        group_id,
        array['owner', 'admin']::public.group_role[]
    )
);

drop policy if exists "group_community_post_reactions_select_member"
    on public.group_community_post_reactions;
create policy "group_community_post_reactions_select_member"
on public.group_community_post_reactions for select to authenticated
using (exists (
    select 1 from public.group_community_posts p
    where p.id = post_id and public.is_group_member(p.group_id)
));

drop policy if exists "group_community_post_comments_select_member"
    on public.group_community_post_comments;
create policy "group_community_post_comments_select_member"
on public.group_community_post_comments for select to authenticated
using (exists (
    select 1 from public.group_community_posts p
    where p.id = post_id and public.is_group_member(p.group_id)
));

drop policy if exists "group_community_post_comments_insert_member"
    on public.group_community_post_comments;
create policy "group_community_post_comments_insert_member"
on public.group_community_post_comments for insert to authenticated
with check (
    user_id = auth.uid()
    and exists (
        select 1 from public.group_community_posts p
        where p.id = post_id and public.is_group_member(p.group_id)
    )
);

create or replace function public.toggle_group_community_post_reaction(
    p_post_id uuid,
    p_emoji text
)
returns void
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare v_group_id uuid;
begin
    select group_id into v_group_id
    from public.group_community_posts
    where id = p_post_id and deleted_at is null;
    if v_group_id is null or not public.is_group_member(v_group_id) then
        raise exception 'GROUP_MEMBER_REQUIRED';
    end if;
    if exists (
        select 1 from public.group_community_post_reactions
        where post_id = p_post_id and user_id = auth.uid() and emoji = p_emoji
    ) then
        delete from public.group_community_post_reactions
        where post_id = p_post_id and user_id = auth.uid() and emoji = p_emoji;
    else
        insert into public.group_community_post_reactions(post_id, user_id, emoji)
        values (p_post_id, auth.uid(), p_emoji);
    end if;
end;
$$;

revoke all on function public.toggle_group_community_post_reaction(uuid, text)
    from public;
grant execute on function public.toggle_group_community_post_reaction(uuid, text)
    to authenticated;

create or replace function public.log_group_community_activity()
returns trigger
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
    v_payload jsonb := to_jsonb(new);
    v_post_id uuid;
    v_group_id uuid;
    v_actor_id uuid;
begin
    v_post_id := case
        when tg_argv[0] = 'community_post_created'
            then nullif(v_payload ->> 'id', '')::uuid
        else nullif(v_payload ->> 'post_id', '')::uuid
    end;
    select p.group_id into v_group_id
    from public.group_community_posts p
    where p.id = v_post_id;
    v_actor_id := coalesce(
        nullif(v_payload ->> 'author_user_id', '')::uuid,
        nullif(v_payload ->> 'user_id', '')::uuid
    );
    insert into public.group_activities(group_id, actor_user_id, type, metadata)
    values (
        v_group_id,
        v_actor_id,
        tg_argv[0],
        jsonb_build_object(
            'post_id', v_post_id,
            'emoji', case
                when tg_argv[0] = 'community_post_reacted'
                    then v_payload ->> 'emoji'
                else null
            end
        )
    );
    return new;
end;
$$;

drop trigger if exists group_community_post_activity on public.group_community_posts;
create trigger group_community_post_activity
after insert on public.group_community_posts
for each row execute function public.log_group_community_activity('community_post_created');

drop trigger if exists group_community_comment_activity
    on public.group_community_post_comments;
create trigger group_community_comment_activity
after insert on public.group_community_post_comments
for each row execute function public.log_group_community_activity('community_post_commented');

drop trigger if exists group_community_reaction_activity
    on public.group_community_post_reactions;
create trigger group_community_reaction_activity
after insert on public.group_community_post_reactions
for each row execute function public.log_group_community_activity('community_post_reacted');

drop policy if exists "storage_select_group_community_media" on storage.objects;
create policy "storage_select_group_community_media"
on storage.objects for select to authenticated
using (
    bucket_id = 'transaction-images'
    and (storage.foldername(name))[1] = 'group-community'
    and exists (
        select 1 from public.group_community_media m
        where m.id::text = (storage.foldername(name))[3]
          and m.group_id::text = (storage.foldername(name))[2]
          and public.is_group_member(m.group_id)
    )
);

drop policy if exists "storage_insert_group_community_media" on storage.objects;
create policy "storage_insert_group_community_media"
on storage.objects for insert to authenticated
with check (
    bucket_id = 'transaction-images'
    and (storage.foldername(name))[1] = 'group-community'
    and exists (
        select 1 from public.group_community_media m
        where m.id::text = (storage.foldername(name))[3]
          and m.group_id::text = (storage.foldername(name))[2]
          and m.created_by = auth.uid()
    )
);

drop policy if exists "storage_update_group_community_media" on storage.objects;
create policy "storage_update_group_community_media"
on storage.objects for update to authenticated
using (
    bucket_id = 'transaction-images'
    and (storage.foldername(name))[1] = 'group-community'
    and exists (
        select 1 from public.group_community_media m
        where m.id::text = (storage.foldername(name))[3]
          and m.group_id::text = (storage.foldername(name))[2]
          and (
              m.created_by = auth.uid()
              or public.has_group_role(
                  m.group_id,
                  array['owner', 'admin']::public.group_role[]
              )
          )
    )
)
with check (
    bucket_id = 'transaction-images'
    and (storage.foldername(name))[1] = 'group-community'
);
