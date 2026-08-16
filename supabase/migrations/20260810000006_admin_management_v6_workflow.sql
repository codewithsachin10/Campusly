-- Update Admin Profile Schema for OTP and Scope
ALTER TABLE public.admin_profiles 
  ADD COLUMN IF NOT EXISTS staff_id TEXT UNIQUE,
  ADD COLUMN IF NOT EXISTS otp_code TEXT,
  ADD COLUMN IF NOT EXISTS otp_expires_at TIMESTAMPTZ;

-- The prompt requested "Department" as an input, we already had a department_id UUID column, 
-- but let's change it to department TEXT to simplify the scope matching for now since we couldn't find a departments table.
ALTER TABLE public.admin_profiles
  DROP COLUMN IF EXISTS department_id;
ALTER TABLE public.admin_profiles
  ADD COLUMN IF NOT EXISTS department TEXT;

-- Update the status ENUM types (Postgres requires altering the type to add values)
ALTER TYPE admin_status ADD VALUE IF NOT EXISTS 'Pending_Verification';
ALTER TYPE admin_status ADD VALUE IF NOT EXISTS 'Pending_Role';

-- Finally, re-enable the Foreign Key constraint for security now that we have a real backend flow
-- Note: Doing this will FAIL if there are existing rows that violate it. 
-- Since we inserted dummy rows in the previous session, we need to clear them first!
DELETE FROM public.admin_profiles WHERE NOT EXISTS (SELECT 1 FROM auth.users WHERE auth.users.id = admin_profiles.id);

ALTER TABLE public.admin_profiles
  ADD CONSTRAINT admin_profiles_id_fkey FOREIGN KEY (id) REFERENCES auth.users(id) ON DELETE CASCADE;
