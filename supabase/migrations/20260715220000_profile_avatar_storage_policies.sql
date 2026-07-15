-- Profile avatars live in the existing private transaction-images bucket.
-- Authenticated users may read avatars because they are shown in friend and
-- group discovery. Only the owner of the second path segment may mutate them.
drop policy if exists "storage_select_profile_avatars" on storage.objects;
create policy "storage_select_profile_avatars"
on storage.objects for select to authenticated
using (
    bucket_id = 'transaction-images'
    and (storage.foldername(name))[1] = 'avatars'
);

drop policy if exists "storage_insert_own_profile_avatar" on storage.objects;
create policy "storage_insert_own_profile_avatar"
on storage.objects for insert to authenticated
with check (
    bucket_id = 'transaction-images'
    and (storage.foldername(name))[1] = 'avatars'
    and (storage.foldername(name))[2] = auth.uid()::text
);

drop policy if exists "storage_update_own_profile_avatar" on storage.objects;
create policy "storage_update_own_profile_avatar"
on storage.objects for update to authenticated
using (
    bucket_id = 'transaction-images'
    and (storage.foldername(name))[1] = 'avatars'
    and (storage.foldername(name))[2] = auth.uid()::text
)
with check (
    bucket_id = 'transaction-images'
    and (storage.foldername(name))[1] = 'avatars'
    and (storage.foldername(name))[2] = auth.uid()::text
);

drop policy if exists "storage_delete_own_profile_avatar" on storage.objects;
create policy "storage_delete_own_profile_avatar"
on storage.objects for delete to authenticated
using (
    bucket_id = 'transaction-images'
    and (storage.foldername(name))[1] = 'avatars'
    and (storage.foldername(name))[2] = auth.uid()::text
);
