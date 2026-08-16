-- Temporarily drop the FK constraint on admin_profiles so we can test the UI by inserting random UUIDs.
ALTER TABLE public.admin_profiles DROP CONSTRAINT IF EXISTS admin_profiles_id_fkey;
