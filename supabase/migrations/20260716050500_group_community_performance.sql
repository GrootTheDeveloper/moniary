-- Bound Group/Community reads so latency grows with the requested page rather
-- than with all historical data. RPCs are versioned to allow backend-first
-- deployment before the mobile client starts using them.

create index if not exists groups_updated_id_idx
    on public.groups(updated_at desc, id desc)
    where status = 'active';
create index if not exists group_members_group_status_joined_idx
    on public.group_members(group_id, status, joined_at);
create index if not exists group_transactions_group_status_date_idx
    on public.group_transactions(group_id, split_status, transaction_date desc);
create index if not exists group_polls_group_created_idx
    on public.group_polls(group_id, created_at desc, id desc);
create index if not exists group_savings_challenges_group_created_idx
    on public.group_savings_challenges(group_id, created_at desc, id desc);
create index if not exists group_savings_contributions_challenge_idx
    on public.group_savings_contributions(challenge_id);
create index if not exists group_community_media_post_created_idx
    on public.group_community_media(post_id, created_at, id);

alter table public.group_community_media
    add column if not exists upload_status public.image_upload_status
    not null default 'pending';

update public.group_community_media
set upload_status = case
    when storage_path is null then 'failed'::public.image_upload_status
    else 'uploaded'::public.image_upload_status
end
where upload_status = 'pending';

create or replace function public.list_my_group_summaries_v1(
    p_limit integer default 20,
    p_before_updated_at timestamptz default null,
    p_before_id uuid default null
)
returns table (
    id uuid,
    name text,
    avatar_path text,
    description text,
    type text,
    base_currency text,
    created_by uuid,
    status public.group_status,
    created_at timestamptz,
    updated_at timestamptz,
    member_count bigint,
    member_avatar_paths jsonb,
    transaction_count bigint,
    total_spent bigint,
    current_user_balance bigint,
    has_unresolved_settlements boolean
)
language sql
stable
security definer
set search_path = public, pg_temp
as $$
    with page as (
        select g.*
        from public.groups g
        join public.group_members me
          on me.group_id = g.id
         and me.user_id = auth.uid()
         and me.status = 'active'
        where g.status = 'active'
          and (
              p_before_updated_at is null
              or g.updated_at < p_before_updated_at
              or (
                  g.updated_at = p_before_updated_at
                  and p_before_id is not null
                  and g.id < p_before_id
              )
          )
        order by g.updated_at desc, g.id desc
        limit least(greatest(coalesce(p_limit, 20), 1), 51)
    )
    select
        g.id,
        g.name,
        g.avatar_path,
        g.description,
        g.type,
        g.base_currency,
        g.created_by,
        g.status,
        g.created_at,
        g.updated_at,
        coalesce(member_summary.member_count, 0),
        coalesce(member_summary.avatar_paths, '[]'::jsonb),
        coalesce(transaction_summary.transaction_count, 0),
        coalesce(transaction_summary.total_spent, 0),
        coalesce(balance_summary.balance, 0),
        coalesce(settlement_summary.has_unresolved, false)
    from page g
    left join lateral (
        select
            (
                select count(*)::bigint
                from public.group_members count_member
                where count_member.group_id = g.id
                  and count_member.status = 'active'
            ) as member_count,
            coalesce(
                (
                    select jsonb_agg(member.avatar_url order by member.joined_at)
                    from (
                        select gm.joined_at, p.avatar_url
                        from public.group_members gm
                        join public.profiles p on p.id = gm.user_id
                        where gm.group_id = g.id
                          and gm.status = 'active'
                          and p.avatar_url is not null
                        order by gm.joined_at
                        limit 5
                    ) member
                ),
                '[]'::jsonb
            ) as avatar_paths
    ) member_summary on true
    left join lateral (
        select
            count(*)::bigint as transaction_count,
            coalesce(sum(gt.total_amount), 0)::bigint as total_spent
        from public.group_transactions gt
        where gt.group_id = g.id and gt.split_status = 'posted'
    ) transaction_summary on true
    left join lateral (
        select sum(gbs.balance)::bigint as balance
        from public.group_balance_summary gbs
        where gbs.group_id = g.id and gbs.user_id = auth.uid()
    ) balance_summary on true
    left join lateral (
        select exists (
            select 1
            from public.group_settlement_suggestions gss
            where gss.group_id = g.id
              and gss.status in ('pending', 'payer_marked_paid', 'disputed')
        ) as has_unresolved
    ) settlement_summary on true
    order by g.updated_at desc, g.id desc;
$$;

revoke all on function public.list_my_group_summaries_v1(integer, timestamptz, uuid)
    from public;
grant execute on function public.list_my_group_summaries_v1(integer, timestamptz, uuid)
    to authenticated;

create or replace function public.list_group_community_feed_v1(
    p_group_id uuid,
    p_limit integer default 20,
    p_before_created_at timestamptz default null,
    p_before_type text default null,
    p_before_id uuid default null
)
returns table (
    item_type text,
    item_id uuid,
    group_id uuid,
    created_at timestamptz,
    payload jsonb
)
language plpgsql
stable
security definer
set search_path = public, pg_temp
as $$
begin
    if auth.uid() is null or not public.is_group_member(p_group_id, auth.uid()) then
        raise exception 'GROUP_MEMBER_REQUIRED' using errcode = '42501';
    end if;

    return query
    with candidates as (
        select 'post'::text as kind, p.id, p.group_id, p.created_at
        from public.group_community_posts p
        where p.group_id = p_group_id and p.deleted_at is null
        union all
        select 'poll'::text, p.id, p.group_id, p.created_at
        from public.group_polls p
        where p.group_id = p_group_id
        union all
        select 'challenge'::text, c.id, c.group_id, c.created_at
        from public.group_savings_challenges c
        where c.group_id = p_group_id
    ), page as (
        select candidate.*
        from candidates candidate
        where p_before_created_at is null
           or candidate.created_at < p_before_created_at
           or (
               candidate.created_at = p_before_created_at
               and p_before_type is not null
               and candidate.kind < p_before_type
           )
           or (
               candidate.created_at = p_before_created_at
               and candidate.kind = p_before_type
               and p_before_id is not null
               and candidate.id < p_before_id
           )
        order by candidate.created_at desc, candidate.kind desc, candidate.id desc
        limit least(greatest(coalesce(p_limit, 20), 1), 51)
    )
    select
        page.kind,
        page.id,
        page.group_id,
        page.created_at,
        case page.kind
            when 'post' then (
                select jsonb_build_object(
                    'id', post.id,
                    'group_id', post.group_id,
                    'author_user_id', post.author_user_id,
                    'post_type', post.post_type,
                    'content', post.content,
                    'linked_transaction_id', post.linked_transaction_id,
                    'linked_poll_id', post.linked_poll_id,
                    'linked_challenge_id', post.linked_challenge_id,
                    'created_at', post.created_at,
                    'author', jsonb_build_object(
                        'full_name', author.full_name,
                        'avatar_url', author.avatar_url
                    ),
                    'media', coalesce((
                        select jsonb_agg(to_jsonb(media_row) order by media_row.created_at)
                        from (
                            select media.id, media.group_id, media.post_id,
                                   media.created_by, media.media_kind,
                                   media.storage_path, media.caption, media.created_at
                            from public.group_community_media media
                            where media.post_id = post.id
                              and media.storage_path is not null
                              and media.upload_status = 'uploaded'
                            order by media.created_at
                            limit 4
                        ) media_row
                    ), '[]'::jsonb),
                    'reactions', coalesce((
                        select jsonb_agg(jsonb_build_object(
                            'emoji', reaction.emoji,
                            'reaction_count', reaction.reaction_count,
                            'reacted_by_current_user', reaction.reacted_by_current_user
                        ) order by reaction.emoji)
                        from (
                            select r.emoji,
                                   count(*)::bigint as reaction_count,
                                   bool_or(r.user_id = auth.uid()) as reacted_by_current_user
                            from public.group_community_post_reactions r
                            where r.post_id = post.id
                            group by r.emoji
                        ) reaction
                    ), '[]'::jsonb),
                    'comment_count', (
                        select count(*)::bigint
                        from public.group_community_post_comments comment
                        where comment.post_id = post.id
                    ),
                    'comments', '[]'::jsonb
                )
                from public.group_community_posts post
                join public.profiles author on author.id = post.author_user_id
                where post.id = page.id
            )
            when 'poll' then (
                select jsonb_build_object(
                    'id', poll.id,
                    'group_id', poll.group_id,
                    'title', poll.title,
                    'is_closed', poll.is_closed,
                    'created_at', poll.created_at,
                    'selected_option_id', (
                        select vote.option_id
                        from public.group_poll_votes vote
                        where vote.poll_id = poll.id and vote.user_id = auth.uid()
                    ),
                    'options', coalesce((
                        select jsonb_agg(jsonb_build_object(
                            'id', option.id,
                            'label', option.label,
                            'vote_count', option.vote_count
                        ) order by option.id)
                        from public.group_poll_options option
                        where option.poll_id = poll.id
                    ), '[]'::jsonb)
                )
                from public.group_polls poll
                where poll.id = page.id
            )
            else (
                select jsonb_build_object(
                    'id', challenge.id,
                    'group_id', challenge.group_id,
                    'title', challenge.title,
                    'target_amount', challenge.target_amount,
                    'start_date', challenge.start_date,
                    'end_date', challenge.end_date,
                    'is_active', challenge.is_active,
                    'created_at', challenge.created_at,
                    'total_contributed', coalesce((
                        select sum(contribution.amount)::bigint
                        from public.group_savings_contributions contribution
                        where contribution.challenge_id = challenge.id
                    ), 0)
                )
                from public.group_savings_challenges challenge
                where challenge.id = page.id
            )
        end
    from page
    order by page.created_at desc, page.kind desc, page.id desc;
end;
$$;

revoke all on function public.list_group_community_feed_v1(
    uuid, integer, timestamptz, text, uuid
) from public;
grant execute on function public.list_group_community_feed_v1(
    uuid, integer, timestamptz, text, uuid
) to authenticated;

create or replace function public.list_group_community_comments_v1(
    p_post_id uuid,
    p_limit integer default 30,
    p_before_created_at timestamptz default null,
    p_before_id uuid default null
)
returns table (
    id uuid,
    post_id uuid,
    user_id uuid,
    content text,
    created_at timestamptz,
    profile jsonb
)
language plpgsql
stable
security definer
set search_path = public, pg_temp
as $$
declare
    v_group_id uuid;
begin
    select post.group_id into v_group_id
    from public.group_community_posts post
    where post.id = p_post_id and post.deleted_at is null;

    if v_group_id is null
       or auth.uid() is null
       or not public.is_group_member(v_group_id, auth.uid()) then
        raise exception 'GROUP_MEMBER_REQUIRED' using errcode = '42501';
    end if;

    return query
    select comment.id,
           comment.post_id,
           comment.user_id,
           comment.content,
           comment.created_at,
           jsonb_build_object(
               'full_name', author.full_name,
               'avatar_url', author.avatar_url
           ) as profile
    from public.group_community_post_comments comment
    join public.profiles author on author.id = comment.user_id
    where comment.post_id = p_post_id
      and (
          p_before_created_at is null
          or comment.created_at < p_before_created_at
          or (
              comment.created_at = p_before_created_at
              and p_before_id is not null
              and comment.id < p_before_id
          )
      )
    order by comment.created_at desc, comment.id desc
    limit least(greatest(coalesce(p_limit, 30), 1), 51);
end;
$$;

revoke all on function public.list_group_community_comments_v1(
    uuid, integer, timestamptz, uuid
) from public;
grant execute on function public.list_group_community_comments_v1(
    uuid, integer, timestamptz, uuid
) to authenticated;
