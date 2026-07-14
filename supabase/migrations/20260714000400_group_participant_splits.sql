create or replace function public.populate_group_transaction_v2(
    p_transaction_id uuid,
    p_total_amount bigint,
    p_split_mode public.group_split_mode,
    p_payment_mode public.group_payment_mode,
    p_payer_amounts jsonb,
    p_participant_ids jsonb,
    p_share_amounts jsonb
)
returns public.group_split_status
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
    v_group_id uuid;
    v_participant_count integer;
    v_base_share bigint;
    v_remainder bigint;
    v_payer_count integer;
    v_paid_total bigint;
    v_all_positive boolean;
    v_share_total bigint;
begin
    select group_id into v_group_id
    from public.group_transactions
    where id = p_transaction_id;

    create temporary table if not exists group_work_participants (
        user_id uuid primary key
    ) on commit delete rows;
    truncate table pg_temp.group_work_participants;

    if jsonb_array_length(coalesce(p_participant_ids, '[]'::jsonb)) = 0 then
        insert into pg_temp.group_work_participants (user_id)
        select user_id from public.group_members
        where group_id = v_group_id and status = 'active';
    else
        insert into pg_temp.group_work_participants (user_id)
        select value::uuid from jsonb_array_elements_text(p_participant_ids);
    end if;

    select count(*) into v_participant_count
    from pg_temp.group_work_participants;
    if p_total_amount <= 0 then
        raise exception 'GROUP_TOTAL_AMOUNT_INVALID';
    end if;
    if v_participant_count = 0 then
        raise exception 'GROUP_NO_PARTICIPANTS';
    end if;
    if exists (
        select 1 from pg_temp.group_work_participants selected
        where not exists (
            select 1 from public.group_members gm
            where gm.group_id = v_group_id
              and gm.user_id = selected.user_id
              and gm.status = 'active'
        )
    ) then
        raise exception 'GROUP_PARTICIPANT_NOT_ACTIVE';
    end if;

    if p_payment_mode <> 'everyone_paid' then
        select count(*), coalesce(sum(value::bigint), 0),
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
        v_base_share := p_total_amount / v_participant_count;
        v_remainder := p_total_amount % v_participant_count;
        insert into public.group_transaction_shares (
            group_transaction_id, user_id, share_amount,
            input_status, submitted_at
        )
        select p_transaction_id, ordered.user_id,
               v_base_share + case when ordered.position <= v_remainder then 1 else 0 end,
               'submitted', timezone('utc', now())
        from (
            select selected.user_id,
                   row_number() over (order by gm.joined_at, selected.user_id) position
            from pg_temp.group_work_participants selected
            join public.group_members gm
              on gm.group_id = v_group_id and gm.user_id = selected.user_id
        ) ordered;
    elsif p_split_mode = 'exact' then
        if exists (
            select 1 from pg_temp.group_work_participants selected
            where not (coalesce(p_share_amounts, '{}'::jsonb) ? selected.user_id::text)
        ) or exists (
            select 1 from jsonb_object_keys(coalesce(p_share_amounts, '{}'::jsonb)) key
            where not exists (
                select 1 from pg_temp.group_work_participants selected
                where selected.user_id = key::uuid
            )
        ) then
            raise exception 'GROUP_SHARE_TOTAL_MISMATCH';
        end if;
        select coalesce(sum(value::bigint), 0)
        into v_share_total
        from jsonb_each_text(coalesce(p_share_amounts, '{}'::jsonb));
        if v_share_total <> p_total_amount or exists (
            select 1 from jsonb_each_text(coalesce(p_share_amounts, '{}'::jsonb))
            where value::bigint < 0
        ) then
            raise exception 'GROUP_SHARE_TOTAL_MISMATCH';
        end if;
        insert into public.group_transaction_shares (
            group_transaction_id, user_id, share_amount,
            input_status, submitted_at
        )
        select p_transaction_id, selected.user_id,
               (p_share_amounts ->> selected.user_id::text)::bigint,
               'submitted', timezone('utc', now())
        from pg_temp.group_work_participants selected;
    else
        insert into public.group_transaction_shares (
            group_transaction_id, user_id, share_amount, input_status
        )
        select p_transaction_id, user_id, 0, 'pending'
        from pg_temp.group_work_participants;
    end if;

    if p_payment_mode = 'everyone_paid' and p_split_mode <> 'unequal' then
        insert into public.group_transaction_payers (
            group_transaction_id, user_id, paid_amount
        )
        select group_transaction_id, user_id, share_amount
        from public.group_transaction_shares
        where group_transaction_id = p_transaction_id;
    elsif p_payment_mode <> 'everyone_paid' then
        insert into public.group_transaction_payers (
            group_transaction_id, user_id, paid_amount
        )
        select p_transaction_id, key::uuid, value::bigint
        from jsonb_each_text(p_payer_amounts);
    end if;

    if p_split_mode = 'unequal' then
        insert into public.group_notifications (
            group_id, user_id, group_transaction_id, type
        )
        select v_group_id, user_id, p_transaction_id,
               'member_amount_input_required'
        from pg_temp.group_work_participants;
        return 'pending_member_amount_input';
    end if;

    insert into public.group_notifications (
        group_id, user_id, group_transaction_id, type
    )
    select v_group_id, user_id, p_transaction_id,
           'group_transaction_posted'
    from public.group_members
    where group_id = v_group_id and status = 'active';
    return 'posted';
end;
$$;

create or replace function public.create_group_transaction(
    p_group_id uuid, p_total_amount bigint, p_category_id uuid,
    p_category_name text, p_caption text, p_note text,
    p_split_mode text, p_payment_mode text, p_payer_amounts jsonb,
    p_participant_ids jsonb, p_share_amounts jsonb
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
        group_id, created_by, total_amount, category_id,
        category_name_snapshot, caption, note, split_mode,
        payment_mode, split_status
    ) values (
        p_group_id, auth.uid(), p_total_amount, p_category_id,
        nullif(btrim(coalesce(p_category_name, '')), ''),
        nullif(btrim(coalesce(p_caption, '')), ''),
        nullif(btrim(coalesce(p_note, '')), ''),
        p_split_mode::public.group_split_mode,
        p_payment_mode::public.group_payment_mode, 'draft'
    ) returning id into v_transaction_id;
    v_split_status := public.populate_group_transaction_v2(
        v_transaction_id, p_total_amount,
        p_split_mode::public.group_split_mode,
        p_payment_mode::public.group_payment_mode,
        p_payer_amounts, p_participant_ids, p_share_amounts
    );
    update public.group_transactions set split_status = v_split_status
    where id = v_transaction_id;
    if v_split_status = 'posted' then
        perform public.refresh_group_settlements(p_group_id);
    end if;
    return v_transaction_id;
end;
$$;

create or replace function public.update_group_transaction(
    p_transaction_id uuid, p_total_amount bigint, p_category_id uuid,
    p_category_name text, p_caption text, p_note text,
    p_split_mode text, p_payment_mode text, p_payer_amounts jsonb,
    p_participant_ids jsonb, p_share_amounts jsonb
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
    select group_id, created_by into v_group_id, v_created_by
    from public.group_transactions
    where id = p_transaction_id for update;
    if v_group_id is null then raise exception 'NOT_FOUND'; end if;
    if v_created_by <> auth.uid() then raise exception 'GROUP_CREATOR_ONLY'; end if;
    delete from public.group_transaction_payers
    where group_transaction_id = p_transaction_id;
    delete from public.group_transaction_shares
    where group_transaction_id = p_transaction_id;
    update public.group_transactions set
        total_amount = p_total_amount,
        category_id = p_category_id,
        category_name_snapshot = nullif(btrim(coalesce(p_category_name, '')), ''),
        caption = nullif(btrim(coalesce(p_caption, '')), ''),
        note = nullif(btrim(coalesce(p_note, '')), ''),
        split_mode = p_split_mode::public.group_split_mode,
        payment_mode = p_payment_mode::public.group_payment_mode,
        split_status = 'draft'
    where id = p_transaction_id;
    v_split_status := public.populate_group_transaction_v2(
        p_transaction_id, p_total_amount,
        p_split_mode::public.group_split_mode,
        p_payment_mode::public.group_payment_mode,
        p_payer_amounts, p_participant_ids, p_share_amounts
    );
    update public.group_transactions set split_status = v_split_status
    where id = p_transaction_id;
    perform public.refresh_group_settlements(v_group_id);
end;
$$;

revoke all on function public.populate_group_transaction_v2(
    uuid, bigint, public.group_split_mode, public.group_payment_mode,
    jsonb, jsonb, jsonb
) from public;
grant execute on function public.create_group_transaction(
    uuid, bigint, uuid, text, text, text, text, text,
    jsonb, jsonb, jsonb
) to authenticated;
grant execute on function public.update_group_transaction(
    uuid, bigint, uuid, text, text, text, text, text,
    jsonb, jsonb, jsonb
) to authenticated;
