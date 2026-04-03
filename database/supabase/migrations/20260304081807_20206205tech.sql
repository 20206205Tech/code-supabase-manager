-- 1. Tạo bảng whitelist (Dùng IF NOT EXISTS để không lỗi nếu bảng đã có)
create table if not exists public.admin_whitelist (
  email text primary key
);

-- Bật RLS. Mặc định nếu không có policy nào, không ai (trừ service_role) đọc được bảng này.
-- Điều này TỐT cho bảo mật.
alter table public.admin_whitelist enable row level security;

-- 2. Thêm email (Dùng ON CONFLICT để tránh lỗi duplicate key nếu chạy lại)
insert into public.admin_whitelist (email) 
values 
  ('vuvannghia.work@gmail.com')
on conflict (email) do nothing;

-- 3. Tạo hàm xử lý
create or replace function public.handle_new_user_role()
returns trigger 
language plpgsql 
security definer -- Chạy với quyền của người tạo hàm (bỏ qua RLS của bảng whitelist)
set search_path = public -- QUAN TRỌNG: Cố định search_path để bảo mật
as $$
declare
  is_admin boolean;
begin
  -- So sánh email dạng chữ thường để chính xác tuyệt đối
  select exists(
    select 1 
    from public.admin_whitelist 
    where lower(email) = lower(new.email)
  ) into is_admin;

  if is_admin then
    new.raw_app_meta_data = 
      jsonb_set(coalesce(new.raw_app_meta_data, '{}'::jsonb), '{role}', '"admin"');
    
  else
    new.raw_app_meta_data = 
      jsonb_set(coalesce(new.raw_app_meta_data, '{}'::jsonb), '{role}', '"user"');
  end if;
  
  return new;
end;
$$;

-- 4. Gán Trigger
-- Xóa trigger cũ nếu tồn tại để tránh lỗi duplicate trigger
drop trigger if exists on_auth_user_created_add_role on auth.users;

create trigger on_auth_user_created_add_role
  before insert on auth.users
  for each row execute procedure public.handle_new_user_role();