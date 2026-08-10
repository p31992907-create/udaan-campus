-- Supabase Row Level Security (RLS) policy templates for Udaan Campus
-- Replace {table} and fields as needed. Assumes `auth.uid()` returns the caller UID

-- Enable RLS for a table
-- ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;

-- Example: users table - allow super_manager full access via custom claim `role` in JWT
-- Supabase uses JWT claims; ensure Access Token contains `role` claim (set via server-side)

-- Policy: allow super_manager full access
-- CREATE POLICY super_manager_full_access ON public.users
--   FOR ALL
--   USING (auth.role = 'super_manager')
--   WITH CHECK (auth.role = 'super_manager');

-- Policy: allow users to read/update their own record (but not role)
-- CREATE POLICY user_self_read_update ON public.users
--   FOR SELECT, UPDATE
--   USING (auth.uid() = id)
--   WITH CHECK (auth.uid() = id AND (role IS NULL OR role = old.role));

-- Policy: prevent clients from changing `role` column
-- CREATE POLICY prevent_role_changes ON public.users
--   FOR UPDATE
--   USING (true)
--   WITH CHECK (COALESCE(role, '') = COALESCE(old.role, '') OR auth.role = 'super_manager');

-- Audit logs: only allow insertions from backend with a service role
-- CREATE POLICY audit_insert_by_backend ON public.audit_logs
--   FOR INSERT
--   USING (auth.role = 'service' OR auth.role = 'super_manager')

-- More granular policies: classes, sections, attendance, homework, tests, marks
-- Follow same pattern: allow `super_manager` via auth.role claim; allow manager/teacher based on assignments

-- NOTE: Supabase JWT must include `role` and any other claims like `school_id` to enforce scoped access.
