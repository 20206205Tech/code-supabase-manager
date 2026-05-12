-- 1. Tạo bucket cho ảnh nhân vật (Persona)
-- Thiết lập public: true để có thể truy cập ảnh qua URL công khai
insert into storage.buckets (id, name, public)
values ('persona_audios', 'persona_audios', true)
on conflict (id) do nothing;

-- 2. Policy: Cho phép mọi người xem ảnh (Kể cả khách không đăng nhập)
-- Chúng ta dùng 'drop policy if exists' để tránh lỗi khi deploy lại migration
drop policy if exists "Persona avatars are public" on storage.objects;

create policy "Persona avatars are public"
  on storage.objects for select
  using ( bucket_id = 'persona_audios' );

-- 3. Policy: Chỉ Admin mới có quyền toàn diện (Thêm/Sửa/Xóa)
-- Tận dụng metadata 'role' = 'admin' mà bạn đã thiết lập từ trigger đầu tiên
drop policy if exists "Admins can manage persona avatars" on storage.objects;

create policy "Admins can manage persona avatars"
  on storage.objects for all
  to authenticated
  using (
    bucket_id = 'persona_audios' 
    AND (auth.jwt() -> 'app_metadata' ->> 'role') = 'admin'
  )
  with check (
    bucket_id = 'persona_audios' 
    AND (auth.jwt() -> 'app_metadata' ->> 'role') = 'admin'
  );