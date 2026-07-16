-- Complete the friend profile contract used by the Friends UI.
-- Positive current_user_balance means the friend owes the current user.
drop function if exists public.list_friend_profiles();

create function public.list_friend_profiles()
returns table (
    user_id uuid,
    full_name text,
    username text,
    avatar_url text,
    friends_since timestamptz,
    shared_group_count bigint,
    current_user_balance bigint
)
language sql
stable
security definer
set search_path = public, pg_temp
as $$
    with shared_groups as (
        select
            f.friend_user_id,
            current_member.group_id
        from public.friendships f
        join public.group_members current_member
          on current_member.user_id = f.user_id
         and current_member.status = 'active'
        join public.group_members friend_member
          on friend_member.group_id = current_member.group_id
         and friend_member.user_id = f.friend_user_id
         and friend_member.status = 'active'
        join public.groups g
          on g.id = current_member.group_id
         and g.status = 'active'
        where f.user_id = auth.uid()
        group by f.friend_user_id, current_member.group_id
    ),
    group_counts as (
        select
            friend_user_id,
            count(*)::bigint as shared_group_count
        from shared_groups
        group by friend_user_id
    ),
    pair_balances as (
        select
            sg.friend_user_id,
            coalesce(
                sum(
                    case
                        when settlement.from_user_id = sg.friend_user_id
                         and settlement.to_user_id = auth.uid()
                            then settlement.amount
                        when settlement.from_user_id = auth.uid()
                         and settlement.to_user_id = sg.friend_user_id
                            then -settlement.amount
                        else 0
                    end
                ),
                0
            )::bigint as current_user_balance
        from shared_groups sg
        left join public.group_settlement_suggestions settlement
          on settlement.group_id = sg.group_id
         and settlement.status <> 'completed'
         and (
             (settlement.from_user_id = sg.friend_user_id
              and settlement.to_user_id = auth.uid())
             or
             (settlement.from_user_id = auth.uid()
              and settlement.to_user_id = sg.friend_user_id)
         )
        group by sg.friend_user_id
    )
    select
        p.id as user_id,
        p.full_name,
        p.username,
        p.avatar_url,
        f.created_at as friends_since,
        coalesce(gc.shared_group_count, 0)::bigint,
        coalesce(pb.current_user_balance, 0)::bigint
    from public.friendships f
    join public.profiles p
      on p.id = f.friend_user_id
    left join group_counts gc
      on gc.friend_user_id = f.friend_user_id
    left join pair_balances pb
      on pb.friend_user_id = f.friend_user_id
    where f.user_id = auth.uid()
      and coalesce(p.deleted_at is null, true)
    order by lower(coalesce(p.full_name, p.username, p.id::text));
$$;

revoke all on function public.list_friend_profiles() from public;
grant execute on function public.list_friend_profiles() to authenticated;
