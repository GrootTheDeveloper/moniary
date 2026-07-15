-- Device delivery must stop in the same transaction that places an account
-- into the deletion grace period. Client sign-out remains a second layer for
-- the current phone, while this trigger covers every registered device.

create or replace function public.deactivate_devices_on_account_deletion()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
    if old.deleted_at is null and new.deleted_at is not null then
        update public.notification_devices
        set is_active = false,
            updated_at = timezone('utc', now())
        where user_id = new.id
          and is_active = true;
    end if;

    return new;
end;
$$;

revoke all on function public.deactivate_devices_on_account_deletion()
from public, anon, authenticated;

drop trigger if exists deactivate_devices_on_account_deletion
on public.profiles;
create trigger deactivate_devices_on_account_deletion
after update of deleted_at on public.profiles
for each row execute function public.deactivate_devices_on_account_deletion();
