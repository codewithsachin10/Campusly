-- Migration to align app_releases with Campusly Smart Updates v3 and create release_notes table

-- 1. Drop old constraints safely and add new columns to app_releases
DO $$ 
DECLARE 
    constraint_name text;
BEGIN
    -- Drop update_type check constraint
    SELECT conname INTO constraint_name 
    FROM pg_constraint 
    WHERE conrelid = 'app_releases'::regclass AND contype = 'c' 
    AND pg_get_constraintdef(oid) LIKE '%update_type%';
    
    IF constraint_name IS NOT NULL THEN
        EXECUTE 'ALTER TABLE app_releases DROP CONSTRAINT ' || constraint_name;
    END IF;

    -- Drop status check constraint
    SELECT conname INTO constraint_name 
    FROM pg_constraint 
    WHERE conrelid = 'app_releases'::regclass AND contype = 'c' 
    AND pg_get_constraintdef(oid) LIKE '%status%';
    
    IF constraint_name IS NOT NULL THEN
        EXECUTE 'ALTER TABLE app_releases DROP CONSTRAINT ' || constraint_name;
    END IF;
END $$;

ALTER TABLE app_releases 
ADD COLUMN IF NOT EXISTS priority TEXT CHECK (priority IN ('NORMAL', 'RECOMMENDED', 'IMPORTANT', 'CRITICAL')) DEFAULT 'NORMAL',
ADD COLUMN IF NOT EXISTS channel TEXT CHECK (channel IN ('STABLE', 'BETA', 'INTERNAL')) DEFAULT 'STABLE',
ADD COLUMN IF NOT EXISTS description TEXT,
ADD COLUMN IF NOT EXISTS minimum_supported_version TEXT DEFAULT '1.0.0',
ADD COLUMN IF NOT EXISTS published_at TIMESTAMP WITH TIME ZONE;

-- We keep update_type around if existing logic depends on it, but we prefer 'priority' going forward
-- Rename 'release_title' to 'title' if 'title' doesn't exist
DO $$ 
BEGIN
  IF NOT EXISTS(SELECT *
    FROM information_schema.columns
    WHERE table_name='app_releases' and column_name='title')
  THEN
      ALTER TABLE app_releases RENAME COLUMN release_title TO title;
  END IF;
END $$;

-- Update status constraint to include TESTING
ALTER TABLE app_releases ADD CONSTRAINT app_releases_status_check3 CHECK (status IN ('DRAFT', 'TESTING', 'PUBLISHED', 'PAUSED', 'ROLLED_BACK', 'ARCHIVED'));

-- 2. Create release_notes table
CREATE TABLE IF NOT EXISTS release_notes (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    release_id UUID REFERENCES app_releases(id) ON DELETE CASCADE NOT NULL,
    category TEXT CHECK (category IN ('NEW', 'IMPROVED', 'FIXED', 'SECURITY', 'PERFORMANCE', 'DESIGN')) NOT NULL,
    title TEXT,
    description TEXT NOT NULL,
    sort_order INTEGER DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- 3. Row Level Security for release_notes
ALTER TABLE release_notes ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Anyone can view notes for published releases" ON release_notes;
CREATE POLICY "Anyone can view notes for published releases" 
ON release_notes FOR SELECT 
USING (
    EXISTS (
        SELECT 1 FROM app_releases 
        WHERE app_releases.id = release_notes.release_id 
        AND (app_releases.status = 'PUBLISHED' OR app_releases.is_published = true)
    )
);

-- Note: Admins manage releases through the web dashboard, which bypasses RLS using service role 
-- or has its own admin policies on the backend.
