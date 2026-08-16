-- Campusly Smart In-App Updater Schema

-- 1. Create app_releases table
CREATE TABLE IF NOT EXISTS app_releases (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    version_code INTEGER NOT NULL,
    version_name TEXT NOT NULL,
    release_notes TEXT,
    download_url TEXT NOT NULL,
    apk_hash TEXT NOT NULL, -- SHA-256
    is_mandatory BOOLEAN DEFAULT false,
    min_supported_version_code INTEGER NOT NULL,
    status TEXT NOT NULL CHECK (status IN ('PUBLISHED', 'DRAFT', 'ROLLED_BACK')) DEFAULT 'DRAFT',
    published_at TIMESTAMP WITH TIME ZONE,
    created_by UUID REFERENCES auth.users(id),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- Enable RLS
ALTER TABLE app_releases ENABLE ROW LEVEL SECURITY;

-- Everyone can view PUBLISHED releases
DROP POLICY IF EXISTS "Anyone can view published releases" ON app_releases;
CREATE POLICY "Anyone can view published releases" 
ON app_releases FOR SELECT 
USING (status = 'PUBLISHED');

-- Admins can manage all releases
DROP POLICY IF EXISTS "Admins can manage releases" ON app_releases;
CREATE POLICY "Admins can manage releases" 
ON app_releases FOR ALL 
USING (true); -- Currently trusting all authenticated web admins. For production, check a user 'role' here.

-- 2. Create app_update_analytics table
CREATE TABLE IF NOT EXISTS app_update_analytics (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    from_version_code INTEGER,
    to_version_code INTEGER,
    status TEXT NOT NULL CHECK (status IN ('STARTED', 'DOWNLOADED', 'INSTALLED', 'FAILED')),
    error_message TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- Enable RLS
ALTER TABLE app_update_analytics ENABLE ROW LEVEL SECURITY;

-- Users can insert their own analytics
DROP POLICY IF EXISTS "Users can insert their analytics" ON app_update_analytics;
CREATE POLICY "Users can insert their analytics" 
ON app_update_analytics FOR INSERT 
WITH CHECK (auth.uid() = user_id);

-- Admins can view all analytics
DROP POLICY IF EXISTS "Admins can view all analytics" ON app_update_analytics;
CREATE POLICY "Admins can view all analytics" 
ON app_update_analytics FOR SELECT 
USING (true);

-- 3. Storage Bucket for APKs
INSERT INTO storage.buckets (id, name, public) 
VALUES ('releases', 'releases', true)
ON CONFLICT (id) DO NOTHING;

-- Storage RLS: Anyone can read releases
DROP POLICY IF EXISTS "Anyone can read releases" ON storage.objects;
CREATE POLICY "Anyone can read releases" 
ON storage.objects FOR SELECT 
USING (bucket_id = 'releases');

-- Storage RLS: Admins can upload/delete
DROP POLICY IF EXISTS "Admins can upload releases" ON storage.objects;
CREATE POLICY "Admins can upload releases" 
ON storage.objects FOR INSERT 
WITH CHECK (bucket_id = 'releases' AND auth.role() = 'authenticated');

DROP POLICY IF EXISTS "Admins can delete releases" ON storage.objects;
CREATE POLICY "Admins can delete releases" 
ON storage.objects FOR DELETE 
USING (bucket_id = 'releases' AND auth.role() = 'authenticated');

DROP POLICY IF EXISTS "Admins can update releases" ON storage.objects;
CREATE POLICY "Admins can update releases" 
ON storage.objects FOR UPDATE 
USING (bucket_id = 'releases' AND auth.role() = 'authenticated');
