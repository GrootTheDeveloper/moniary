create or replace function public.initialize_user()
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
    v_user_id uuid := auth.uid();
    v_email text;
    v_full_name text;
    v_avatar_url text;
    v_provider text := 'anonymous';
    v_default_wallet_id uuid;
begin
    if v_user_id is null then
        raise exception 'Not authenticated';
    end if;

    select
        u.email,
        coalesce(
            u.raw_user_meta_data ->> 'full_name',
            u.raw_user_meta_data ->> 'name',
            'Guest'
        ),
        u.raw_user_meta_data ->> 'avatar_url',
        coalesce(u.raw_app_meta_data ->> 'provider', 'anonymous')
    into v_email, v_full_name, v_avatar_url, v_provider
    from auth.users u
    where u.id = v_user_id;

    insert into public.profiles (id, full_name, email, avatar_url, login_provider)
    values (v_user_id, v_full_name, v_email, v_avatar_url, v_provider)
    on conflict (id) do update
    set full_name = excluded.full_name,
        email = excluded.email,
        avatar_url = excluded.avatar_url,
        login_provider = excluded.login_provider;

    insert into public.notification_settings (user_id)
    values (v_user_id)
    on conflict (user_id) do nothing;

    select id into v_default_wallet_id
    from public.wallets
    where user_id = v_user_id
      and is_default = true
    order by created_at asc
    limit 1;

    if v_default_wallet_id is null then
        select id into v_default_wallet_id
        from public.wallets
        where user_id = v_user_id
        order by created_at asc
        limit 1;

        if v_default_wallet_id is null then
            insert into public.wallets
                (user_id, name, type, icon, color, initial_balance, is_default)
            values
                (v_user_id, 'Tiền mặt', 'cash', 'wallet', '#4CAF50', 0, true)
            on conflict (user_id, lower(name)) do update
            set is_default = true,
                is_active = true
            returning id into v_default_wallet_id;
        else
            update public.wallets
            set is_default = true,
                is_active = true
            where id = v_default_wallet_id
            returning id into v_default_wallet_id;
        end if;
    end if;

    insert into public.categories
        (user_id, name, type, icon, color, is_default)
    values
        (v_user_id, 'Ăn uống', 'expense', 'restaurant', '#FF7043', true),
        (v_user_id, 'Di chuyển', 'expense', 'directions_bus', '#42A5F5', true),
        (v_user_id, 'Mua sắm', 'expense', 'shopping_bag', '#AB47BC', true),
        (v_user_id, 'Hóa đơn', 'expense', 'receipt_long', '#FFA726', true),
        (v_user_id, 'Lương', 'income', 'payments', '#66BB6A', true),
        (v_user_id, 'Thưởng', 'income', 'savings', '#26A69A', true),
        (v_user_id, 'Khác', 'income', 'more_horiz', '#78909C', true)
    on conflict (user_id, type, lower(name)) do nothing;

    return jsonb_build_object(
        'userId', v_user_id,
        'defaultWalletId', v_default_wallet_id,
        'initialized', true
    );
end;
$$;

revoke all on function public.initialize_user() from public;
grant execute on function public.initialize_user() to authenticated;

create or replace function public.ensure_occupation_categories(
    p_occupation text
)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
    v_user_id uuid := auth.uid();
begin
    if v_user_id is null then
        raise exception 'Not authenticated';
    end if;

    insert into public.categories
        (user_id, name, type, icon, color, is_default, is_active)
    values
        (v_user_id, 'Ăn uống', 'expense', 'restaurant', '#FF7043', true, true),
        (v_user_id, 'Di chuyển', 'expense', 'directions_bus', '#42A5F5', true, true),
        (v_user_id, 'Mua sắm', 'expense', 'shopping_bag', '#AB47BC', true, true),
        (v_user_id, 'Hóa đơn', 'expense', 'receipt_long', '#FFA726', true, true),
        (v_user_id, 'Lương', 'income', 'payments', '#66BB6A', true, true),
        (v_user_id, 'Thưởng', 'income', 'savings', '#26A69A', true, true),
        (v_user_id, 'Khác', 'income', 'more_horiz', '#78909C', true, true)
    on conflict (user_id, type, lower(name)) do update
    set icon = excluded.icon,
        color = excluded.color,
        is_default = true,
        is_active = true;

    insert into public.categories
        (user_id, name, type, icon, color, is_default, is_active)
    select
        v_user_id,
        template.name,
        template.type::public.transaction_type,
        template.icon,
        template.color,
        true,
        true
    from (
        values
            ('student', 'Học phí', 'expense', 'school', '#5C6BC0'),
            ('student', 'Sách vở', 'expense', 'menu_book', '#8D6E63'),
            ('student', 'Nhà trọ', 'expense', 'home', '#26A69A'),
            ('student', 'Sinh hoạt phí', 'expense', 'local_laundry_service', '#7E57C2'),
            ('office_worker', 'Cà phê', 'expense', 'coffee', '#8D6E63'),
            ('office_worker', 'Gia đình', 'expense', 'family_restroom', '#EC407A'),
            ('office_worker', 'Sức khỏe', 'expense', 'health_and_safety', '#26A69A'),
            ('freelancer', 'Công cụ làm việc', 'expense', 'laptop_mac', '#5C6BC0'),
            ('freelancer', 'Internet', 'expense', 'wifi', '#29B6F6'),
            ('freelancer', 'Không gian làm việc', 'expense', 'desk', '#8D6E63'),
            ('freelancer', 'Thu nhập dự án', 'income', 'work_outline', '#43A047'),
            ('business_owner', 'Nhập hàng', 'expense', 'inventory_2', '#7E57C2'),
            ('business_owner', 'Mặt bằng', 'expense', 'storefront', '#26A69A'),
            ('business_owner', 'Marketing', 'expense', 'campaign', '#EC407A'),
            ('business_owner', 'Vận chuyển', 'expense', 'local_shipping', '#42A5F5'),
            ('business_owner', 'Tiếp khách', 'expense', 'groups', '#FF7043'),
            ('business_owner', 'Doanh thu', 'income', 'point_of_sale', '#43A047')
    ) as template(occupation, name, type, icon, color)
    where template.occupation = p_occupation
    on conflict (user_id, type, lower(name)) do update
    set icon = excluded.icon,
        color = excluded.color,
        is_default = true,
        is_active = true;
end;
$$;

revoke all on function public.ensure_occupation_categories(text) from public;
grant execute on function public.ensure_occupation_categories(text) to authenticated;

create or replace function public.complete_profile_survey(
    p_occupation text,
    p_preferred_currency text,
    p_wallet_name text,
    p_initial_balance numeric
)
returns public.profiles
language plpgsql
security definer
set search_path = public
as $$
declare
    v_user_id uuid := auth.uid();
    v_wallet_id uuid;
    v_profile public.profiles;
begin
    if v_user_id is null then
        raise exception 'Not authenticated';
    end if;

    if btrim(p_wallet_name) = '' then
        raise exception 'Wallet name must not be blank';
    end if;

    perform public.initialize_user();

    select id into v_wallet_id
    from public.wallets
    where user_id = v_user_id
      and lower(name) = lower(p_wallet_name)
    order by created_at asc
    limit 1;

    if v_wallet_id is null then
        select id into v_wallet_id
        from public.wallets
        where user_id = v_user_id
          and is_default = true
        order by created_at asc
        limit 1;
    end if;

    if v_wallet_id is null then
        insert into public.wallets
            (user_id, name, type, icon, color, initial_balance, is_default, is_active)
        values
            (v_user_id, p_wallet_name, 'cash', 'wallet', '#4CAF50', p_initial_balance, true, true)
        returning id into v_wallet_id;
    else
        update public.wallets
        set is_default = false
        where user_id = v_user_id
          and id <> v_wallet_id
          and is_default = true;

        update public.wallets
        set name = p_wallet_name,
            initial_balance = p_initial_balance,
            is_default = true,
            is_active = true
        where id = v_wallet_id
          and user_id = v_user_id;
    end if;

    perform public.ensure_occupation_categories(p_occupation);

    update public.profiles
    set occupation = p_occupation,
        preferred_currency = p_preferred_currency,
        survey_completed_at = timezone('utc', now()),
        updated_at = timezone('utc', now())
    where id = v_user_id
    returning * into v_profile;

    return v_profile;
end;
$$;

revoke all on function public.complete_profile_survey(text, text, text, numeric) from public;
grant execute on function public.complete_profile_survey(text, text, text, numeric) to authenticated;
