-- Collaboration polish: member payment QR and guarded group lifecycle actions.

alter table public.profiles
    add column if not exists payment_qr_path text;

create or replace function public.update_expense_group(
    p_group_id uuid,
    p_name text,
    p_description text default null,
    p_type text default null
)
returns void
language plpgsql
security definer
set search_path = public, pg_temp
as $$
begin
    if not public.has_group_role(
        p_group_id,
        array['owner', 'admin']::public.group_role[]
    ) then
        raise exception 'GROUP_ADMIN_REQUIRED';
    end if;

    if nullif(btrim(coalesce(p_name, '')), '') is null then
        raise exception 'GROUP_NAME_REQUIRED';
    end if;

    update public.groups
    set name = btrim(p_name),
        description = nullif(btrim(coalesce(p_description, '')), ''),
        type = nullif(btrim(coalesce(p_type, '')), '')
    where id = p_group_id;
end;
$$;

create or replace function public.set_expense_group_archived(
    p_group_id uuid,
    p_archived boolean
)
returns void
language plpgsql
security definer
set search_path = public, pg_temp
as $$
begin
    if not public.has_group_role(
        p_group_id,
        array['owner', 'admin']::public.group_role[]
    ) then
        raise exception 'GROUP_ADMIN_REQUIRED';
    end if;

    if p_archived and (
        exists (
            select 1
            from public.group_transactions
            where group_id = p_group_id
              and split_status not in ('posted', 'cancelled')
        )
        or exists (
            select 1
            from public.group_settlement_suggestions
            where group_id = p_group_id
              and status <> 'completed'
        )
        or exists (
            select 1
            from public.group_balance_summary
            where group_id = p_group_id
              and balance <> 0
        )
    ) then
        raise exception 'GROUP_ARCHIVE_UNRESOLVED';
    end if;

    update public.groups
    set status = case when p_archived then 'archived' else 'active' end
    where id = p_group_id;
end;
$$;

revoke all on function public.update_expense_group(uuid, text, text, text)
    from public;
revoke all on function public.set_expense_group_archived(uuid, boolean)
    from public;
grant execute on function public.update_expense_group(uuid, text, text, text)
    to authenticated;
grant execute on function public.set_expense_group_archived(uuid, boolean)
    to authenticated;

-- QR files stay in the existing private bucket. The second path segment is a
-- user id, compared as text to avoid unsafe casts on arbitrary object names.
drop policy if exists "storage_select_payment_qr" on storage.objects;
create policy "storage_select_payment_qr"
on storage.objects for select to authenticated
using (
    bucket_id = 'transaction-images'
    and (storage.foldername(name))[1] = 'payment-qr'
    and (
        (storage.foldername(name))[2] = auth.uid()::text
        or exists (
            select 1
            from public.group_members viewer
            join public.group_members owner_member
              on owner_member.group_id = viewer.group_id
            where viewer.user_id = auth.uid()
              and viewer.status = 'active'
              and owner_member.user_id::text = (storage.foldername(name))[2]
              and owner_member.status = 'active'
        )
    )
);

drop policy if exists "storage_insert_own_payment_qr" on storage.objects;
create policy "storage_insert_own_payment_qr"
on storage.objects for insert to authenticated
with check (
    bucket_id = 'transaction-images'
    and (storage.foldername(name))[1] = 'payment-qr'
    and (storage.foldername(name))[2] = auth.uid()::text
);

drop policy if exists "storage_update_own_payment_qr" on storage.objects;
create policy "storage_update_own_payment_qr"
on storage.objects for update to authenticated
using (
    bucket_id = 'transaction-images'
    and (storage.foldername(name))[1] = 'payment-qr'
    and (storage.foldername(name))[2] = auth.uid()::text
)
with check (
    bucket_id = 'transaction-images'
    and (storage.foldername(name))[1] = 'payment-qr'
    and (storage.foldername(name))[2] = auth.uid()::text
);

drop policy if exists "storage_delete_own_payment_qr" on storage.objects;
create policy "storage_delete_own_payment_qr"
on storage.objects for delete to authenticated
using (
    bucket_id = 'transaction-images'
    and (storage.foldername(name))[1] = 'payment-qr'
    and (storage.foldername(name))[2] = auth.uid()::text
);
