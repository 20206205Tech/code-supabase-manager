-- 1. Tạo function xử lý Custom JWT Hook
CREATE OR REPLACE FUNCTION public.custom_access_token_hook(event jsonb)
RETURNS jsonb
LANGUAGE plpgsql
STABLE
SECURITY DEFINER -- Thêm dòng này cực kỳ quan trọng để vượt qua RLS
SET search_path = public -- Bảo mật search_path khi dùng Security Definer
AS $$
DECLARE
  claims jsonb;
  profile_data record;
BEGIN
  -- Lấy danh sách claims hiện tại từ event
  claims := event->'claims';

  -- Truy vấn bảng profiles
  SELECT full_name, avatar_url INTO profile_data
  FROM public.profiles
  WHERE id = (claims->>'sub')::uuid;

  -- Nếu có dữ liệu, nhúng vào claims
  IF FOUND THEN
    claims := claims || jsonb_build_object(
      'full_name', profile_data.full_name,
      'avatar_url', profile_data.avatar_url
    );
    event := jsonb_set(event, '{claims}', claims);
  END IF;

  RETURN event;
END;
$$;

-- 2. Phân quyền bảo mật cho function
-- Thu hồi quyền thực thi từ các role thông thường để tránh rò rỉ dữ liệu
REVOKE EXECUTE ON FUNCTION public.custom_access_token_hook(jsonb) FROM authenticated, anon, public;

-- Chỉ cấp quyền cho supabase_auth_admin (role hệ thống của Supabase chuyên xử lý Auth)
GRANT USAGE ON SCHEMA public TO supabase_auth_admin;
GRANT EXECUTE ON FUNCTION public.custom_access_token_hook(jsonb) TO supabase_auth_admin;