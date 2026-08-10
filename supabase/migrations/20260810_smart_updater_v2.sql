-- Migration to upgrade app_releases to the new Smart Updater v2 Specification
-- Do not delete existing tables per safety requirements; alter instead.

-- 1. Add new columns
ALTER TABLE app_releases
ADD COLUMN IF NOT EXISTS platform TEXT DEFAULT 'android',
ADD COLUMN IF NOT EXISTS release_title TEXT,
ADD COLUMN IF NOT EXISTS short_description TEXT,
ADD COLUMN IF NOT EXISTS update_type TEXT CHECK (update_type IN ('OPTIONAL', 'RECOMMENDED', 'MANDATORY')) DEFAULT 'RECOMMENDED',
ADD COLUMN IF NOT EXISTS minimum_supported_version TEXT,
ADD COLUMN IF NOT EXISTS apk_size BIGINT,
ADD COLUMN IF NOT EXISTS package_name TEXT DEFAULT 'com.sachindigisolutions.campusly',
ADD COLUMN IF NOT EXISTS rollout_percentage INTEGER DEFAULT 100 CHECK (rollout_percentage >= 0 AND rollout_percentage <= 100),
ADD COLUMN IF NOT EXISTS is_published BOOLEAN DEFAULT false,
ADD COLUMN IF NOT EXISTS updated_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()),
ADD COLUMN IF NOT EXISTS updated_by UUID REFERENCES auth.users(id);

-- 2. Rename existing columns to match the new specification
ALTER TABLE app_releases RENAME COLUMN version_code TO build_number;
ALTER TABLE app_releases RENAME COLUMN version_name TO version;
ALTER TABLE app_releases RENAME COLUMN download_url TO apk_url;
ALTER TABLE app_releases RENAME COLUMN apk_hash TO apk_sha256;
ALTER TABLE app_releases RENAME COLUMN min_supported_version_code TO minimum_supported_build;

-- 3. Drop old status constraint and create new one (requires dropping default, altering type)
ALTER TABLE app_releases ALTER COLUMN status DROP DEFAULT;
-- Let's just bypass dropping the exact name of the old constraint by adding a new check constraint on the updated ENUM values.
-- (PostgreSQL doesn't strictly complain if the old constraint is there UNLESS it conflicts, but the old one only allowed PUBLISHED, DRAFT, ROLLED_BACK. We are adding new ones. So we must drop the old constraint.)
DO $$ 
DECLARE 
    constraint_name text;
BEGIN
    SELECT conname INTO constraint_name 
    FROM pg_constraint 
    WHERE conrelid = 'app_releases'::regclass AND contype = 'c' 
    AND pg_get_constraintdef(oid) LIKE '%status%';
    
    IF constraint_name IS NOT NULL THEN
        EXECUTE 'ALTER TABLE app_releases DROP CONSTRAINT ' || constraint_name;
    END IF;
END $$;

ALTER TABLE app_releases ADD CONSTRAINT app_releases_status_check2 CHECK (status IN ('DRAFT', 'READY', 'PUBLISHED', 'PAUSED', 'ROLLED_BACK', 'ARCHIVED'));
ALTER TABLE app_releases ALTER COLUMN status SET DEFAULT 'DRAFT';

-- 4. Update existing policies for app_releases
DROP POLICY IF EXISTS "Anyone can view published releases" ON app_releases;
CREATE POLICY "Anyone can view published releases" 
ON app_releases FOR SELECT 
USING (status = 'PUBLISHED' OR is_published = true);

-- 5. Create app_update_analytics if it doesn't exist
CREATE TABLE IF NOT EXISTS app_update_analytics (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    from_version_code INTEGER,
    to_version_code INTEGER,
    status TEXT NOT NULL CHECK (status IN ('STARTED', 'DOWNLOADED', 'INSTALLED', 'FAILED', 'INTEGRITY_FAILED')),
    error_message TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

ALTER TABLE app_update_analytics ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can insert their analytics" ON app_update_analytics;
CREATE POLICY "Users can insert their analytics" 
ON app_update_analytics FOR INSERT 
WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Admins can view all analytics" ON app_update_analytics;
CREATE POLICY "Admins can view all analytics" 
ON app_update_analytics FOR SELECT 
USING (true);

-- 6. Trigger for updated_at
CREATE OR REPLACE FUNCTION set_app_releases_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = timezone('utc'::text, now());
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_app_releases_updated_at ON app_releases;
CREATE TRIGGER trg_app_releases_updated_at
BEFORE UPDATE ON app_releases
FOR EACH ROW
EXECUTE FUNCTION set_app_releases_updated_at();
