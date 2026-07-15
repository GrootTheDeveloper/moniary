create extension if not exists pgcrypto;

create or replace function public._seed_uuid(p_text text)
returns uuid
language sql
immutable
as $$
  select (
    substr(md5(p_text), 1, 8) || '-' ||
    substr(md5(p_text), 9, 4) || '-' ||
    substr(md5(p_text), 13, 4) || '-' ||
    substr(md5(p_text), 17, 4) || '-' ||
    substr(md5(p_text), 21, 12)
  )::uuid;
$$;

do $$
declare
  v_password text := '12345678';
  u record;
  v_user_id uuid;
begin
  create temp table if not exists seed_users (
    email text primary key,
    full_name text not null,
    username text not null,
    occupation text not null,
    initial_balance numeric(14,2) not null
  );

  truncate seed_users;
  insert into seed_users (email, full_name, username, occupation, initial_balance)
  values
    ('a@gmail.com', 'Nguyen Minh An', 'an_nguyen', 'office_worker', 24500000),
    ('b@gmail.com', 'Tran Gia Binh', 'binh_tran', 'freelancer', 18200000),
    ('c@gmail.com', 'Le Mai Chi', 'chi_le', 'student', 6350000);

  for u in select * from seed_users loop
    select id into v_user_id
    from auth.users
    where lower(email) = lower(u.email)
    limit 1;

    if v_user_id is null then
      v_user_id := public._seed_uuid('auth:' || u.email);

      insert into auth.users (
        instance_id,
        id,
        aud,
        role,
        email,
        encrypted_password,
        email_confirmed_at,
        confirmation_sent_at,
        confirmation_token,
        recovery_token,
        email_change_token_new,
        email_change,
        raw_app_meta_data,
        raw_user_meta_data,
        is_super_admin,
        created_at,
        updated_at,
        phone,
        phone_confirmed_at,
        is_sso_user
      )
      values (
        '00000000-0000-0000-0000-000000000000',
        v_user_id,
        'authenticated',
        'authenticated',
        u.email,
        crypt(v_password, gen_salt('bf')),
        now(),
        now(),
        '',
        '',
        '',
        '',
        jsonb_build_object('provider', 'email', 'providers', jsonb_build_array('email')),
        jsonb_build_object('full_name', u.full_name, 'name', u.full_name),
        false,
        now() - interval '90 days',
        now(),
        null,
        null,
        false
      );
    else
      update auth.users
      set encrypted_password = crypt(v_password, gen_salt('bf')),
          email_confirmed_at = coalesce(email_confirmed_at, now()),
          raw_app_meta_data = jsonb_build_object('provider', 'email', 'providers', jsonb_build_array('email')),
          raw_user_meta_data = jsonb_build_object('full_name', u.full_name, 'name', u.full_name),
          updated_at = now()
      where id = v_user_id;
    end if;

    insert into auth.identities (
      id,
      provider_id,
      user_id,
      identity_data,
      provider,
      last_sign_in_at,
      created_at,
      updated_at
    )
    values (
      public._seed_uuid('identity:' || u.email),
      v_user_id::text,
      v_user_id,
      jsonb_build_object(
        'sub', v_user_id::text,
        'email', u.email,
        'email_verified', true,
        'phone_verified', false
      ),
      'email',
      now(),
      now() - interval '90 days',
      now()
    )
    on conflict (provider, provider_id) do update
    set identity_data = excluded.identity_data,
        updated_at = now();
  end loop;
end $$;

create temp table seed_user_map as
select
  s.email,
  s.full_name,
  s.username,
  s.occupation,
  s.initial_balance,
  u.id as user_id
from seed_users s
join auth.users u on lower(u.email) = lower(s.email);

delete from public.groups
where id in (
  public._seed_uuid('group:dalat-july-2026'),
  public._seed_uuid('group:roommates-2026')
);

delete from public.friend_requests
where from_user_id in (select user_id from seed_user_map)
   or to_user_id in (select user_id from seed_user_map);

delete from public.friendships
where user_id in (select user_id from seed_user_map)
   or friend_user_id in (select user_id from seed_user_map);

delete from public.journal_collections
where user_id in (select user_id from seed_user_map);

delete from public.recurring_transactions
where user_id in (select user_id from seed_user_map);

delete from public.category_budget_limits
where user_id in (select user_id from seed_user_map);

delete from public.transactions
where user_id in (select user_id from seed_user_map);

delete from public.wallets
where user_id in (select user_id from seed_user_map);

delete from public.categories
where user_id in (select user_id from seed_user_map);

delete from public.notification_settings
where user_id in (select user_id from seed_user_map);

insert into public.profiles (
  id,
  full_name,
  email,
  avatar_url,
  login_provider,
  timezone,
  username,
  occupation,
  preferred_currency,
  survey_completed_at,
  created_at,
  updated_at
)
select
  user_id,
  full_name,
  email,
  null,
  'email',
  'Asia/Ho_Chi_Minh',
  username,
  occupation,
  'VND',
  now() - interval '85 days',
  now() - interval '90 days',
  now()
from seed_user_map
on conflict (id) do update
set full_name = excluded.full_name,
    email = excluded.email,
    login_provider = excluded.login_provider,
    timezone = excluded.timezone,
    username = excluded.username,
    occupation = excluded.occupation,
    preferred_currency = excluded.preferred_currency,
    survey_completed_at = excluded.survey_completed_at,
    updated_at = now();

insert into public.notification_settings (
  user_id,
  daily_reminder_enabled,
  daily_reminder_time,
  weekly_summary_enabled,
  monthly_summary_enabled,
  created_at,
  updated_at
)
select
  user_id,
  true,
  case email
    when 'a@gmail.com' then '21:00'::time
    when 'b@gmail.com' then '20:30'::time
    else '22:00'::time
  end,
  true,
  true,
  now() - interval '80 days',
  now()
from seed_user_map;

create temp table seed_wallet_specs (
  email text,
  key text,
  name text,
  type public.wallet_type,
  icon text,
  color text,
  balance numeric(14,2),
  is_default boolean
) ;

insert into seed_wallet_specs values
  ('a@gmail.com', 'cash', 'Tien mat', 'cash', 'wallet', '#2E7D32', 1800000, true),
  ('a@gmail.com', 'bank', 'Vietcombank payroll', 'bank', 'account_balance', '#1565C0', 24500000, false),
  ('a@gmail.com', 'momo', 'MoMo ca nhan', 'ewallet', 'account_balance_wallet', '#C2185B', 1250000, false),
  ('b@gmail.com', 'cash', 'Tien mat', 'cash', 'wallet', '#388E3C', 950000, true),
  ('b@gmail.com', 'bank', 'Techcombank freelance', 'bank', 'account_balance', '#D32F2F', 18200000, false),
  ('b@gmail.com', 'momo', 'Vi dien tu', 'ewallet', 'account_balance_wallet', '#7B1FA2', 2100000, false),
  ('c@gmail.com', 'cash', 'Tien mat', 'cash', 'wallet', '#43A047', 620000, true),
  ('c@gmail.com', 'bank', 'MB Bank sinh vien', 'bank', 'account_balance', '#1976D2', 6350000, false),
  ('c@gmail.com', 'momo', 'MoMo an vat', 'ewallet', 'account_balance_wallet', '#AD1457', 340000, false);

insert into public.wallets (
  id,
  user_id,
  name,
  type,
  icon,
  color,
  initial_balance,
  is_default,
  is_active,
  created_at,
  updated_at
)
select
  public._seed_uuid('wallet:' || w.email || ':' || w.key),
  u.user_id,
  w.name,
  w.type,
  w.icon,
  w.color,
  w.balance,
  w.is_default,
  true,
  now() - interval '89 days',
  now()
from seed_wallet_specs w
join seed_user_map u using (email);

create temp table seed_category_specs (
  email text,
  key text,
  name text,
  type public.transaction_type,
  icon text,
  color text
) ;

insert into seed_category_specs values
  ('a@gmail.com', 'salary', 'Luong', 'income', 'payments', '#43A047'),
  ('a@gmail.com', 'bonus', 'Thuong', 'income', 'savings', '#00897B'),
  ('a@gmail.com', 'food', 'An uong', 'expense', 'restaurant', '#F4511E'),
  ('a@gmail.com', 'coffee', 'Ca phe', 'expense', 'coffee', '#6D4C41'),
  ('a@gmail.com', 'transport', 'Di chuyen', 'expense', 'directions_bus', '#1E88E5'),
  ('a@gmail.com', 'family', 'Gia dinh', 'expense', 'family_restroom', '#D81B60'),
  ('a@gmail.com', 'bill', 'Hoa don', 'expense', 'receipt_long', '#FB8C00'),
  ('a@gmail.com', 'health', 'Suc khoe', 'expense', 'health_and_safety', '#00897B'),
  ('b@gmail.com', 'project', 'Thu nhap du an', 'income', 'work_outline', '#43A047'),
  ('b@gmail.com', 'bonus', 'Thuong', 'income', 'savings', '#00897B'),
  ('b@gmail.com', 'food', 'An uong', 'expense', 'restaurant', '#F4511E'),
  ('b@gmail.com', 'coffee', 'Ca phe', 'expense', 'coffee', '#6D4C41'),
  ('b@gmail.com', 'tool', 'Cong cu lam viec', 'expense', 'laptop_mac', '#3949AB'),
  ('b@gmail.com', 'internet', 'Internet', 'expense', 'wifi', '#039BE5'),
  ('b@gmail.com', 'cowork', 'Khong gian lam viec', 'expense', 'desk', '#8D6E63'),
  ('b@gmail.com', 'transport', 'Di chuyen', 'expense', 'directions_bus', '#1E88E5'),
  ('b@gmail.com', 'bill', 'Hoa don', 'expense', 'receipt_long', '#FB8C00'),
  ('c@gmail.com', 'allowance', 'Tro cap gia dinh', 'income', 'payments', '#43A047'),
  ('c@gmail.com', 'parttime', 'Lam them', 'income', 'work_outline', '#00897B'),
  ('c@gmail.com', 'food', 'An uong', 'expense', 'restaurant', '#F4511E'),
  ('c@gmail.com', 'tuition', 'Hoc phi', 'expense', 'school', '#5E35B1'),
  ('c@gmail.com', 'book', 'Sach vo', 'expense', 'menu_book', '#6D4C41'),
  ('c@gmail.com', 'rent', 'Nha tro', 'expense', 'home', '#00897B'),
  ('c@gmail.com', 'transport', 'Di chuyen', 'expense', 'directions_bus', '#1E88E5'),
  ('c@gmail.com', 'shopping', 'Mua sam', 'expense', 'shopping_bag', '#8E24AA');

insert into public.categories (
  id,
  user_id,
  name,
  type,
  icon,
  color,
  is_default,
  is_active,
  created_at,
  updated_at
)
select
  public._seed_uuid('category:' || c.email || ':' || c.key),
  u.user_id,
  c.name,
  c.type,
  c.icon,
  c.color,
  true,
  true,
  now() - interval '88 days',
  now()
from seed_category_specs c
join seed_user_map u using (email);

create temp table seed_tx_specs (
  email text,
  key text,
  wallet_key text,
  category_key text,
  amount numeric(14,2),
  type public.transaction_type,
  note text,
  merchant text,
  day_offset int,
  source public.transaction_source,
  important boolean
) ;

insert into seed_tx_specs values
  ('a@gmail.com','a01','bank','salary',28500000,'income','Luong thang 7','Cong ty A',-13,'manual',true),
  ('a@gmail.com','a02','momo','coffee',55000,'expense','Ca phe sang voi team','Phuc Long',-12,'manual',false),
  ('a@gmail.com','a03','cash','food',92000,'expense','Com trua van phong','Com tam Ba Ghien',-12,'ocr',false),
  ('a@gmail.com','a04','bank','bill',1450000,'expense','Tien dien va internet','EVN/HCMC Telecom',-10,'manual',true),
  ('a@gmail.com','a05','momo','transport',78000,'expense','Grab di gap khach hang','Grab',-9,'manual',false),
  ('a@gmail.com','a06','bank','family',3200000,'expense','Gui me tien sinh hoat','Chuyen khoan gia dinh',-8,'manual',true),
  ('a@gmail.com','a07','cash','health',420000,'expense','Mua thuoc cam','Pharmacity',-7,'ocr',false),
  ('a@gmail.com','a08','bank','bonus',3500000,'income','Thuong KPI quy','Cong ty A',-5,'manual',true),
  ('a@gmail.com','a09','momo','food',168000,'expense','Dat do an toi','ShopeeFood',-4,'manual',false),
  ('a@gmail.com','a10','cash','coffee',45000,'expense','Bac xiu chieu','Highlands',-3,'manual',false),
  ('a@gmail.com','a11','bank','transport',650000,'expense','Nap the metro/bus thang','Public transport',-2,'manual',false),
  ('a@gmail.com','a12','cash','food',73000,'expense','Bun bo sang','Quan Hue',-1,'manual',false),
  ('a@gmail.com','a13','bank','salary',28500000,'income','Luong thang 6','Cong ty A',-43,'manual',true),
  ('a@gmail.com','a14','bank','bill',1320000,'expense','Tien nha mang thang 6','HCMC Telecom',-39,'manual',true),
  ('b@gmail.com','b01','bank','project',18000000,'income','Thanh toan landing page','Khach hang Minh Khoa',-14,'manual',true),
  ('b@gmail.com','b02','momo','internet',320000,'expense','Internet nha','FPT Telecom',-13,'manual',true),
  ('b@gmail.com','b03','cash','food',85000,'expense','Pho bo sau buoi meeting','Pho Thin',-12,'manual',false),
  ('b@gmail.com','b04','bank','tool',2490000,'expense','Gia han Figma annual','Figma',-11,'manual',true),
  ('b@gmail.com','b05','momo','transport',112000,'expense','Grab di quay video','Grab',-10,'manual',false),
  ('b@gmail.com','b06','bank','cowork',1800000,'expense','Goi coworking 10 ngay','Toong',-8,'manual',true),
  ('b@gmail.com','b07','cash','coffee',68000,'expense','Ca phe lam viec','The Coffee House',-6,'manual',false),
  ('b@gmail.com','b08','bank','bonus',2500000,'income','Thuong giao som milestone','Khach hang An Phu',-5,'manual',true),
  ('b@gmail.com','b09','cash','food',145000,'expense','An toi voi ban','Pizza 4Ps',-4,'ocr',false),
  ('b@gmail.com','b10','bank','bill',720000,'expense','Dien nuoc phong','Chu nha',-3,'manual',true),
  ('b@gmail.com','b11','momo','food',59000,'expense','Tra sua','Koi The',-2,'manual',false),
  ('b@gmail.com','b12','bank','project',12500000,'income','Tam ung app mobile','Startup Nha Xanh',-45,'manual',true),
  ('c@gmail.com','c01','bank','allowance',5000000,'income','Tien sinh hoat tu gia dinh','Me chuyen khoan',-15,'manual',true),
  ('c@gmail.com','c02','cash','food',35000,'expense','Banh mi sang','Banh mi 37',-14,'manual',false),
  ('c@gmail.com','c03','bank','tuition',4200000,'expense','Hoc phi hoc ky he','Dai hoc',-13,'manual',true),
  ('c@gmail.com','c04','momo','transport',22000,'expense','Xe buyt di hoc','Bus HCMC',-12,'manual',false),
  ('c@gmail.com','c05','cash','book',185000,'expense','Giao trinh kinh te vi mo','Nha sach Fahasa',-10,'ocr',true),
  ('c@gmail.com','c06','bank','rent',1800000,'expense','Tien nha tro thang 7','Chu tro',-9,'manual',true),
  ('c@gmail.com','c07','momo','food',49000,'expense','Com ga truong','Canteen',-7,'manual',false),
  ('c@gmail.com','c08','bank','parttime',1600000,'income','Luong part-time quan cafe','Cafe S',-6,'manual',true),
  ('c@gmail.com','c09','cash','shopping',260000,'expense','Ao so mi di thuc tap','Uniqlo',-5,'manual',false),
  ('c@gmail.com','c10','momo','food',42000,'expense','Tra sua sau gio hoc','Tocotoco',-3,'manual',false),
  ('c@gmail.com','c11','cash','transport',38000,'expense','Xe cong nghe ve nha','Be',-2,'manual',false),
  ('c@gmail.com','c12','bank','allowance',5000000,'income','Tien sinh hoat thang 6','Me chuyen khoan',-46,'manual',true);

insert into public.transactions (
  id,
  user_id,
  wallet_id,
  category_id,
  amount,
  type,
  note,
  image_path,
  image_upload_status,
  merchant_name,
  transaction_date,
  source,
  is_important,
  created_at,
  updated_at
)
select
  public._seed_uuid('tx:' || t.email || ':' || t.key),
  u.user_id,
  public._seed_uuid('wallet:' || t.email || ':' || t.wallet_key),
  public._seed_uuid('category:' || t.email || ':' || t.category_key),
  t.amount,
  t.type,
  t.note,
  null,
  'pending',
  t.merchant,
  date_trunc('day', now()) + (t.day_offset || ' days')::interval + interval '12 hours',
  t.source,
  t.important,
  date_trunc('day', now()) + (t.day_offset || ' days')::interval + interval '13 hours',
  now()
from seed_tx_specs t
join seed_user_map u using (email);

insert into public.category_budget_limits (id, user_id, category_id, month_start, limit_amount, created_at, updated_at)
select
  public._seed_uuid('budget:' || email || ':' || category_key),
  user_id,
  public._seed_uuid('category:' || email || ':' || category_key),
  date_trunc('month', now())::date,
  limit_amount,
  now() - interval '20 days',
  now()
from (
  values
    ('a@gmail.com','food',4500000), ('a@gmail.com','coffee',1200000), ('a@gmail.com','family',4000000), ('a@gmail.com','bill',2500000),
    ('b@gmail.com','food',3800000), ('b@gmail.com','tool',3500000), ('b@gmail.com','cowork',2500000), ('b@gmail.com','internet',600000),
    ('c@gmail.com','food',1800000), ('c@gmail.com','book',700000), ('c@gmail.com','rent',2000000), ('c@gmail.com','transport',500000)
) as b(email, category_key, limit_amount)
join seed_user_map using (email);

insert into public.recurring_transactions (
  id, user_id, wallet_id, category_id, amount, type, note, frequency, interval,
  start_date, next_run_date, end_date, auto_post, is_active, last_run_date, created_at, updated_at
)
select
  public._seed_uuid('recurring:' || email || ':' || key),
  user_id,
  public._seed_uuid('wallet:' || email || ':' || wallet_key),
  public._seed_uuid('category:' || email || ':' || category_key),
  amount,
  type::public.transaction_type,
  note,
  'monthly',
  1,
  (date_trunc('month', now()) - interval '2 months')::date + start_day,
  (date_trunc('month', now()) + interval '1 month')::date + start_day,
  null,
  auto_post,
  true,
  (date_trunc('month', now())::date + start_day),
  now() - interval '60 days',
  now()
from (
  values
    ('a@gmail.com','salary','bank','salary',28500000,'income','Luong hang thang',0,true),
    ('a@gmail.com','internet','bank','bill',450000,'expense','Internet FPT',9,false),
    ('b@gmail.com','cowork','bank','cowork',1800000,'expense','Coworking hang thang',4,false),
    ('b@gmail.com','internet','bank','internet',320000,'expense','Internet FPT',12,false),
    ('c@gmail.com','allowance','bank','allowance',5000000,'income','Tro cap gia dinh',0,true),
    ('c@gmail.com','rent','bank','rent',1800000,'expense','Tien nha tro',8,false)
) as r(email, key, wallet_key, category_key, amount, type, note, start_day, auto_post)
join seed_user_map using (email);

insert into public.journal_collections (id, user_id, name, start_date, end_date, created_at, updated_at)
select
  public._seed_uuid('journal:' || email || ':' || key),
  user_id,
  name,
  (now()::date + start_offset),
  (now()::date + end_offset),
  now() - interval '18 days',
  now()
from (
  values
    ('a@gmail.com','workweek','Tuan lam viec thang 7',-14,-7),
    ('b@gmail.com','freelance','Chi phi du an freelance',-15,-3),
    ('c@gmail.com','semester','Hoc ky he',-16,-2)
) as j(email, key, name, start_offset, end_offset)
join seed_user_map using (email);

insert into public.journal_collection_transactions (collection_id, transaction_id, user_id, created_at)
select
  public._seed_uuid('journal:' || t.email || ':' ||
    case t.email when 'a@gmail.com' then 'workweek' when 'b@gmail.com' then 'freelance' else 'semester' end),
  public._seed_uuid('tx:' || t.email || ':' || t.key),
  u.user_id,
  now() - interval '2 days'
from seed_tx_specs t
join seed_user_map u using (email)
where t.day_offset between -15 and -2
  and (
    (t.email = 'a@gmail.com' and t.key in ('a01','a02','a03','a04','a05','a06','a07'))
    or (t.email = 'b@gmail.com' and t.key in ('b01','b02','b04','b05','b06','b08','b10'))
    or (t.email = 'c@gmail.com' and t.key in ('c01','c03','c04','c05','c06','c08','c09'))
  );

insert into public.friendships (id, user_id, friend_user_id, created_at)
select public._seed_uuid('friendship:' || a.email || ':' || b.email), a.user_id, b.user_id, now() - interval '50 days'
from seed_user_map a
join seed_user_map b on a.email <> b.email;

insert into public.friend_requests (id, from_user_id, to_user_id, status, created_at, updated_at, responded_at)
select
  public._seed_uuid('friend_request:a-b'),
  (select user_id from seed_user_map where email='a@gmail.com'),
  (select user_id from seed_user_map where email='b@gmail.com'),
  'accepted',
  now() - interval '51 days',
  now() - interval '50 days',
  now() - interval '50 days';

insert into public.groups (id, name, avatar_path, description, type, created_by, status, created_at, updated_at)
values (
  public._seed_uuid('group:dalat-july-2026'),
  'Da Lat cuoi tuan',
  null,
  'Chuyen di Da Lat 3 ngay 2 dem, chia tien an uong va di chuyen.',
  'trip',
  (select user_id from seed_user_map where email='a@gmail.com'),
  'active',
  now() - interval '25 days',
  now()
);

insert into public.group_members (id, group_id, user_id, role, status, joined_at, created_at, updated_at)
select
  public._seed_uuid('group_member:dalat:' || email),
  public._seed_uuid('group:dalat-july-2026'),
  user_id,
  case email when 'a@gmail.com' then 'owner'::public.group_role when 'b@gmail.com' then 'admin'::public.group_role else 'member'::public.group_role end,
  'active',
  now() - interval '24 days',
  now() - interval '24 days',
  now()
from seed_user_map;

insert into public.group_budgets (group_id, monthly_limit, warning_threshold_percent, created_at, updated_at)
values (public._seed_uuid('group:dalat-july-2026'), 12000000, 80, now() - interval '24 days', now());

insert into public.group_public_profiles (group_id, slug, is_enabled, show_stats, created_at, updated_at)
values (public._seed_uuid('group:dalat-july-2026'), 'da-lat-cuoi-tuan-2026', true, true, now() - interval '24 days', now());

insert into public.group_notification_preferences (
  group_id, user_id, mute_all, transaction_notifications, debt_notifications,
  invite_notifications, mention_notifications, quiet_hours_start, quiet_hours_end, created_at, updated_at
)
select
  public._seed_uuid('group:dalat-july-2026'),
  user_id,
  false,
  true,
  true,
  true,
  true,
  22,
  7,
  now() - interval '24 days',
  now()
from seed_user_map;

insert into public.group_transactions (
  id, group_id, created_by, total_amount, category_id, category_name_snapshot,
  caption, note, image_path, image_upload_status, split_mode, payment_mode,
  split_status, transaction_date, created_at, updated_at
)
values
  (
    public._seed_uuid('group_tx:dalat:homestay'),
    public._seed_uuid('group:dalat-july-2026'),
    (select user_id from seed_user_map where email='a@gmail.com'),
    3600000,
    public._seed_uuid('category:a@gmail.com:bill'),
    'Hoa don',
    'Dat coc homestay',
    'A thanh toan truoc tien phong 2 dem.',
    null,
    'pending',
    'equal',
    'single_payer',
    'posted',
    now() - interval '18 days',
    now() - interval '18 days',
    now()
  ),
  (
    public._seed_uuid('group_tx:dalat:dinner'),
    public._seed_uuid('group:dalat-july-2026'),
    (select user_id from seed_user_map where email='b@gmail.com'),
    1260000,
    public._seed_uuid('category:b@gmail.com:food'),
    'An uong',
    'Lau ga la e',
    'Bua toi ngay dau, B tra bang the.',
    null,
    'pending',
    'equal',
    'single_payer',
    'posted',
    now() - interval '16 days',
    now() - interval '16 days',
    now()
  );

insert into public.group_transaction_payers (id, group_transaction_id, user_id, paid_amount, created_at, updated_at)
values
  (public._seed_uuid('payer:homestay:a'), public._seed_uuid('group_tx:dalat:homestay'), (select user_id from seed_user_map where email='a@gmail.com'), 3600000, now() - interval '18 days', now()),
  (public._seed_uuid('payer:dinner:b'), public._seed_uuid('group_tx:dalat:dinner'), (select user_id from seed_user_map where email='b@gmail.com'), 1260000, now() - interval '16 days', now());

insert into public.group_transaction_shares (id, group_transaction_id, user_id, share_amount, input_status, submitted_at, created_at, updated_at)
select
  public._seed_uuid('share:homestay:' || email),
  public._seed_uuid('group_tx:dalat:homestay'),
  user_id,
  1200000,
  'submitted'::public.group_share_input_status,
  now() - interval '18 days',
  now() - interval '18 days',
  now()
from seed_user_map
union all
select
  public._seed_uuid('share:dinner:' || email),
  public._seed_uuid('group_tx:dalat:dinner'),
  user_id,
  420000,
  'submitted'::public.group_share_input_status,
  now() - interval '16 days',
  now() - interval '16 days',
  now()
from seed_user_map;

insert into public.group_settlement_suggestions (
  id, group_id, from_user_id, to_user_id, amount, status,
  payer_marked_paid_at, receiver_confirmed_at, created_at, updated_at
)
values
  (public._seed_uuid('settlement:chi-to-an'), public._seed_uuid('group:dalat-july-2026'),
    (select user_id from seed_user_map where email='c@gmail.com'),
    (select user_id from seed_user_map where email='a@gmail.com'),
    1620000, 'pending', null, null, now() - interval '15 days', now()),
  (public._seed_uuid('settlement:binh-to-an'), public._seed_uuid('group:dalat-july-2026'),
    (select user_id from seed_user_map where email='b@gmail.com'),
    (select user_id from seed_user_map where email='a@gmail.com'),
    780000, 'payer_marked_paid', now() - interval '13 days', null, now() - interval '15 days', now());

insert into public.group_transaction_comments (id, group_transaction_id, user_id, content, created_at, updated_at)
values
  (public._seed_uuid('comment:homestay:chi'), public._seed_uuid('group_tx:dalat:homestay'),
    (select user_id from seed_user_map where email='c@gmail.com'), 'Phong sach, gan cho dem nen gia nay hop ly.', now() - interval '17 days', now()),
  (public._seed_uuid('comment:dinner:an'), public._seed_uuid('group_tx:dalat:dinner'),
    (select user_id from seed_user_map where email='a@gmail.com'), 'Mon lau ngon, lan sau quay lai quan nay.', now() - interval '15 days', now());

insert into public.group_transaction_reactions (id, group_transaction_id, user_id, emoji, created_at)
values
  (public._seed_uuid('reaction:homestay:b'), public._seed_uuid('group_tx:dalat:homestay'), (select user_id from seed_user_map where email='b@gmail.com'), 'ok', now() - interval '17 days'),
  (public._seed_uuid('reaction:dinner:c'), public._seed_uuid('group_tx:dalat:dinner'), (select user_id from seed_user_map where email='c@gmail.com'), 'yum', now() - interval '15 days');

insert into public.group_comment_mentions (id, comment_id, mentioned_user_id, created_at)
values (
  public._seed_uuid('mention:homestay:an'),
  public._seed_uuid('comment:homestay:chi'),
  (select user_id from seed_user_map where email='a@gmail.com'),
  now() - interval '17 days'
);

insert into public.group_recurring_transactions (
  id, group_id, created_by, title, amount, frequency, next_run_at,
  notify_days_before, is_active, last_notified_at, created_at, updated_at
)
values (
  public._seed_uuid('group_recurring:dalat:photo-storage'),
  public._seed_uuid('group:dalat-july-2026'),
  (select user_id from seed_user_map where email='a@gmail.com'),
  'Backup anh chung',
  99000,
  'monthly',
  date_trunc('month', now()) + interval '1 month 5 days',
  2,
  true,
  null,
  now() - interval '12 days',
  now()
);

insert into public.group_notifications (id, group_id, user_id, group_transaction_id, type, is_read, created_at)
select
  public._seed_uuid('notification:homestay:' || email),
  public._seed_uuid('group:dalat-july-2026'),
  user_id,
  public._seed_uuid('group_tx:dalat:homestay'),
  'transaction_created',
  email = 'a@gmail.com',
  now() - interval '18 days'
from seed_user_map;

insert into public.group_activities (id, group_id, actor_user_id, type, metadata, created_at)
values
  (public._seed_uuid('activity:group-created'), public._seed_uuid('group:dalat-july-2026'),
    (select user_id from seed_user_map where email='a@gmail.com'), 'group_created',
    jsonb_build_object('name', 'Da Lat cuoi tuan'), now() - interval '25 days'),
  (public._seed_uuid('activity:homestay'), public._seed_uuid('group:dalat-july-2026'),
    (select user_id from seed_user_map where email='a@gmail.com'), 'transaction_created',
    jsonb_build_object('caption', 'Dat coc homestay', 'amount', 3600000), now() - interval '18 days'),
  (public._seed_uuid('activity:dinner'), public._seed_uuid('group:dalat-july-2026'),
    (select user_id from seed_user_map where email='b@gmail.com'), 'transaction_created',
    jsonb_build_object('caption', 'Lau ga la e', 'amount', 1260000), now() - interval '16 days');

drop function if exists public._seed_uuid(text);
