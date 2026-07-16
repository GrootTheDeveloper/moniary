-- Personal transaction attachment semantics and atomic CSV imports.

alter table public.transactions
    alter column image_upload_status set default 'none';

alter table public.transactions
    drop constraint if exists transactions_image_path_pairing;

update public.transactions
set image_upload_status = 'none'
where image_path is null
  and image_upload_status = 'pending';

alter table public.transactions
    add constraint transactions_image_path_pairing check (
        (image_path is null and image_upload_status in ('none', 'pending', 'failed'))
        or (image_path is not null and image_upload_status = 'uploaded')
    );

alter table public.group_transactions
    alter column image_upload_status set default 'none';

alter table public.group_transactions
    drop constraint if exists group_transactions_image_path_pairing;

-- This is a metadata-only backfill. Temporarily bypass the immutable-history
-- guard so settled transactions can adopt the explicit no-image state.
alter table public.group_transactions
    disable trigger prevent_locked_group_transaction_mutation;

update public.group_transactions
set image_upload_status = 'none'
where image_path is null
  and image_upload_status = 'pending';

alter table public.group_transactions
    enable trigger prevent_locked_group_transaction_mutation;

alter table public.group_transactions
    add constraint group_transactions_image_path_pairing check (
        (image_path is null and image_upload_status in ('none', 'pending', 'uploading', 'failed'))
        or (image_path is not null and image_upload_status = 'uploaded')
    );

create table if not exists public.personal_transaction_import_batches (
    user_id uuid not null references auth.users(id) on delete cascade,
    batch_key text not null,
    wallet_id uuid not null references public.wallets(id) on delete restrict,
    imported_count integer not null default 0,
    created_at timestamptz not null default timezone('utc', now()),
    completed_at timestamptz,
    primary key (user_id, batch_key),
    constraint personal_transaction_import_batch_key_valid check (
        batch_key ~ '^[a-f0-9]{48}$'
    ),
    constraint personal_transaction_import_count_valid check (
        imported_count between 0 and 1000
    )
);

alter table public.personal_transaction_import_batches enable row level security;

drop policy if exists "personal_transaction_import_batches_select_own"
    on public.personal_transaction_import_batches;
create policy "personal_transaction_import_batches_select_own"
on public.personal_transaction_import_batches
for select to authenticated
using (user_id = auth.uid());

create or replace function public.import_personal_transactions(
    p_wallet_id uuid,
    p_batch_key text,
    p_rows jsonb
)
returns integer
language plpgsql
security definer
set search_path = public
as $$
declare
    v_user_id uuid := auth.uid();
    v_existing_count integer;
    v_row jsonb;
    v_amount numeric(14, 2);
    v_type public.transaction_type;
    v_category_id uuid;
    v_transaction_date timestamptz;
    v_note text;
    v_count integer := 0;
begin
    if v_user_id is null then
        raise exception 'Not authenticated' using errcode = '42501';
    end if;
    if p_batch_key is null or p_batch_key !~ '^[a-f0-9]{48}$' then
        raise exception 'Invalid import batch key' using errcode = '22023';
    end if;
    if p_rows is null
       or jsonb_typeof(p_rows) <> 'array'
       or jsonb_array_length(p_rows) < 1
       or jsonb_array_length(p_rows) > 1000 then
        raise exception 'Import must contain between 1 and 1000 rows'
            using errcode = '22023';
    end if;
    if not exists (
        select 1 from public.wallets
        where id = p_wallet_id
          and user_id = v_user_id
          and is_active
    ) then
        raise exception 'Wallet is unavailable' using errcode = '22023';
    end if;

    insert into public.personal_transaction_import_batches (
        user_id,
        batch_key,
        wallet_id
    ) values (
        v_user_id,
        p_batch_key,
        p_wallet_id
    )
    on conflict (user_id, batch_key) do nothing;

    if not found then
        select imported_count
        into v_existing_count
        from public.personal_transaction_import_batches
        where user_id = v_user_id
          and batch_key = p_batch_key
          and wallet_id = p_wallet_id
          and completed_at is not null;

        if v_existing_count is null then
            raise exception 'Import batch key conflicts with another wallet'
                using errcode = '22023';
        end if;
        return v_existing_count;
    end if;

    for v_row in select value from jsonb_array_elements(p_rows)
    loop
        if jsonb_typeof(v_row) <> 'object' then
            raise exception 'Invalid import row' using errcode = '22023';
        end if;

        begin
            v_amount := (v_row ->> 'amount')::numeric(14, 2);
            v_category_id := (v_row ->> 'category_id')::uuid;
            v_transaction_date := (v_row ->> 'transaction_date')::timestamptz;
        exception when others then
            raise exception 'Invalid import row value' using errcode = '22023';
        end;

        if v_amount <= 0 then
            raise exception 'Import amount must be positive' using errcode = '22023';
        end if;
        if v_row ->> 'type' not in ('income', 'expense') then
            raise exception 'Invalid import transaction type' using errcode = '22023';
        end if;
        v_type := (v_row ->> 'type')::public.transaction_type;

        if not exists (
            select 1 from public.categories
            where id = v_category_id
              and user_id = v_user_id
              and type = v_type
              and is_active
        ) then
            raise exception 'Category is unavailable or has the wrong type'
                using errcode = '22023';
        end if;

        v_note := nullif(btrim(coalesce(v_row ->> 'note', '')), '');
        insert into public.transactions (
            user_id,
            wallet_id,
            category_id,
            amount,
            type,
            note,
            transaction_date,
            source,
            image_upload_status
        ) values (
            v_user_id,
            p_wallet_id,
            v_category_id,
            v_amount,
            v_type,
            left(v_note, 2000),
            v_transaction_date,
            'import',
            'none'
        );
        v_count := v_count + 1;
    end loop;

    update public.personal_transaction_import_batches
    set imported_count = v_count,
        completed_at = timezone('utc', now())
    where user_id = v_user_id
      and batch_key = p_batch_key;

    return v_count;
end;
$$;

revoke all on function public.import_personal_transactions(uuid, text, jsonb)
    from public;
grant execute on function public.import_personal_transactions(uuid, text, jsonb)
    to authenticated;
