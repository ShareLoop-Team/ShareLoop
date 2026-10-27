-- Item photo storage.
--
-- Private bucket: listings are only browsable after sign-in, so photos are
-- too. The app fetches short-lived signed URLs (which need SELECT on the
-- object) instead of using permanent public links. Objects are stored as
-- `<firebase uid>/<random>.<ext>`; only the owner of that folder can write
-- to it, and items.image_paths may only point into the donor's own folder
-- (see private.check_item_image_paths).

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('item-images', 'item-images', false, 5242880, array['image/jpeg', 'image/png', 'image/webp'])
on conflict (id) do update
  set public = excluded.public,
      file_size_limit = excluded.file_size_limit,
      allowed_mime_types = excluded.allowed_mime_types;

create policy "Signed-in users view item images" on storage.objects
  for select to anon, authenticated
  using (
    bucket_id = 'item-images'
    and (select public.requesting_user_id()) is not null
  );

create policy "Users upload item images to their own folder" on storage.objects
  for insert to anon, authenticated
  with check (
    bucket_id = 'item-images'
    and (storage.foldername(name))[1] = (select public.requesting_user_id())
    and (select private.is_active_user())
  );

create policy "Users replace item images in their own folder" on storage.objects
  for update to anon, authenticated
  using (
    bucket_id = 'item-images'
    and (storage.foldername(name))[1] = (select public.requesting_user_id())
  )
  with check (
    bucket_id = 'item-images'
    and (storage.foldername(name))[1] = (select public.requesting_user_id())
    and (select private.is_active_user())
  );

create policy "Owners and admins delete item images" on storage.objects
  for delete to anon, authenticated
  using (
    bucket_id = 'item-images'
    and ((storage.foldername(name))[1] = (select public.requesting_user_id())
      or (select private.is_admin()))
  );
