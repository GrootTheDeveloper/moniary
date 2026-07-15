-- A departed/removed member must not remain in the shared profile read scope.
drop policy if exists "profiles_select_shared_group_members" on public.profiles;
create policy "profiles_select_shared_group_members"
on public.profiles for select to authenticated
using (
    id = auth.uid()
    or exists (
        select 1
        from public.group_members target_member
        join public.group_members current_member
          on current_member.group_id = target_member.group_id
        where target_member.user_id = profiles.id
          and target_member.status = 'active'
          and current_member.user_id = auth.uid()
          and current_member.status = 'active'
    )
);
