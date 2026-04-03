-- 1. Tạo bucket 'avatars' (thiết lập public = true để ai cũng có thể xem ảnh)
insert into storage.buckets (id, name, public)
values ('avatars', 'avatars', true)
on conflict (id) do nothing;

-- 2. Cho phép mọi người (public) xem các file trong bucket 'avatars'
create policy "Avatar images are publicly accessible."
  on storage.objects for select
  using ( bucket_id = 'avatars' );

-- 3. Cho phép người dùng đã đăng nhập (authenticated) tải ảnh lên
create policy "Users can upload their own avatar."
  on storage.objects for insert
  with check ( bucket_id = 'avatars' and auth.uid() = owner );

-- 4. Cho phép người dùng tự cập nhật ảnh của chính mình
create policy "Users can update their own avatar."
  on storage.objects for update
  using ( bucket_id = 'avatars' and auth.uid() = owner );

-- 5. Cho phép người dùng tự xóa ảnh của chính mình
create policy "Users can delete their own avatar."
  on storage.objects for delete
  using ( bucket_id = 'avatars' and auth.uid() = owner );