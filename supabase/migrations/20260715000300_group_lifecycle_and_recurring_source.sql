-- Reconcile the two historical migrations that independently used version
-- 20260714000600 on separate branches. Every statement is idempotent so this
-- safely repairs either production history and also runs once on a fresh DB.

alter type public.transaction_source add value if not exists 'recurring';

-- Keep operational Group notifications complete when financial state changes.

create or replace function public.notify_group_settlement_change()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
    v_type text;
begin
    if old.status = new.status then
        return new;
    end if;

    v_type := case new.status
        when 'payer_marked_paid' then 'settlement_marked_paid'
        when 'completed' then 'settlement_completed'
        when 'disputed' then 'settlement_disputed'
        else null
    end;

    if v_type is null then
        return new;
    end if;

    insert into public.group_notifications (group_id, user_id, type)
    select new.group_id, member.user_id, v_type
    from public.group_members member
    where member.group_id = new.group_id
      and member.status = 'active'
      and member.user_id in (new.from_user_id, new.to_user_id)
      and member.user_id <> coalesce(auth.uid(), '00000000-0000-0000-0000-000000000000'::uuid);

    return new;
end;
$$;

drop trigger if exists notify_group_settlement_change
    on public.group_settlement_suggestions;
create trigger notify_group_settlement_change
after update on public.group_settlement_suggestions
for each row execute function public.notify_group_settlement_change();

create or replace function public.notify_group_member_removed()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
    if old.status <> 'removed' and new.status = 'removed' then
        insert into public.group_notifications (group_id, user_id, type)
        select new.group_id, member.user_id, 'member_removed'
        from public.group_members member
        where member.group_id = new.group_id
          and member.status = 'active'
          and member.user_id <> coalesce(auth.uid(), '00000000-0000-0000-0000-000000000000'::uuid);
    end if;
    return new;
end;
$$;

drop trigger if exists notify_group_member_removed on public.group_members;
create trigger notify_group_member_removed
after update on public.group_members
for each row execute function public.notify_group_member_removed();

-- Recurring records are reminder schedules, not automatic expenses yet. Move
-- the next reminder forward so a past date cannot remain permanently overdue.
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
        insert into public.group_notifications (group_id, user_id, type)
        select v_item.group_id, member.user_id, 'recurring_due'
        from public.group_members member
        where member.group_id = v_item.group_id
          and member.status = 'active';

        while v_item.next_run_at <= timezone('utc', now()) loop
            v_item.next_run_at := v_item.next_run_at + case v_item.frequency
                when 'weekly' then interval '7 days'
                else interval '1 month'
            end;
        end loop;

        update public.group_recurring_transactions
        set last_notified_at = timezone('utc', now()),
            next_run_at = v_item.next_run_at
        where id = v_item.id;

        v_count := v_count + 1;
    end loop;

    return v_count;
end;
$$;

revoke all on function public.notify_group_settlement_change() from public;
revoke all on function public.notify_group_member_removed() from public;
grant execute on function public.notify_group_settlement_change() to authenticated;
grant execute on function public.notify_group_member_removed() to authenticated;
