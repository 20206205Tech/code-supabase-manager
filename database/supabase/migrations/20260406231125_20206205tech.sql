-- Xóa function custom_access_token_hook
-- (Hành động này sẽ tự động dọn dẹp các quyền đã được GRANT/REVOKE trước đó)
DROP FUNCTION IF EXISTS public.custom_access_token_hook(jsonb);