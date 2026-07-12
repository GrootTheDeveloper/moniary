create or replace function public.create_group_invite_link(p_group_id uuid)
returns text
language plpgsql
security definer
set search_path = public
as $$
declare
    v_token text;
begin
    if not public.has_group_role(
        p_group_id,
        array['owner', 'admin']::public.group_role[]
    ) then
        raise exception 'GROUP_ADMIN_REQUIRED';
    end if;

    update public.group_invites
    set status = 'expired'
    where group_id = p_group_id
      and invited_user_id is null
      and status = 'pending'
      and expires_at <= timezone('utc', now());

    update public.group_invites
    set status = 'revoked'
    where group_id = p_group_id
      and invited_user_id is null
      and status = 'pending';

    insert into public.group_invites (group_id, invited_by)
    values (p_group_id, auth.uid())
    returning token into v_token;

    return 'https://go.vuivethoima.id.vn/groups/invite/' || v_token;
end;
$$;

revoke all on function public.create_group_invite_link(uuid) from public;
grant execute on function public.create_group_invite_link(uuid) to authenticated;
