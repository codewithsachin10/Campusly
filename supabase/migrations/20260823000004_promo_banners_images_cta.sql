-- Add image and CTA columns
ALTER TABLE public.promo_banners 
ADD COLUMN IF NOT EXISTS image_url TEXT,
ADD COLUMN IF NOT EXISTS cta_text TEXT;

-- Insert storage bucket for promo_banners
INSERT INTO storage.buckets (id, name, public) 
VALUES ('promo_banners', 'promo_banners', true) 
ON CONFLICT (id) DO NOTHING;

-- Set up RLS policies for storage
-- Drop existing ones if they exist just in case
DROP POLICY IF EXISTS "promo_banners_public_read" ON storage.objects;
DROP POLICY IF EXISTS "promo_banners_admin_insert" ON storage.objects;
DROP POLICY IF EXISTS "promo_banners_admin_update" ON storage.objects;
DROP POLICY IF EXISTS "promo_banners_admin_delete" ON storage.objects;

-- Allow public access to read images
CREATE POLICY "promo_banners_public_read" 
ON storage.objects FOR SELECT 
USING (bucket_id = 'promo_banners');

-- Allow authenticated users (admins) to insert images
CREATE POLICY "promo_banners_admin_insert" 
ON storage.objects FOR INSERT 
TO authenticated
WITH CHECK (bucket_id = 'promo_banners');

-- Allow authenticated users (admins) to update images
CREATE POLICY "promo_banners_admin_update" 
ON storage.objects FOR UPDATE 
TO authenticated
USING (bucket_id = 'promo_banners');

-- Allow authenticated users (admins) to delete images
CREATE POLICY "promo_banners_admin_delete" 
ON storage.objects FOR DELETE 
TO authenticated
USING (bucket_id = 'promo_banners');
