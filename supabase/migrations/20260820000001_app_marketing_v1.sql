-- Create App Downloads Table
CREATE TABLE public.app_downloads (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL,
    user_agent TEXT,
    ip_address TEXT
);

-- Create Testimonials Table
CREATE TABLE public.testimonials (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    author_name TEXT NOT NULL,
    author_role TEXT NOT NULL,
    content TEXT NOT NULL,
    rating INTEGER NOT NULL DEFAULT 5 CHECK (rating >= 1 AND rating <= 5),
    is_published BOOLEAN NOT NULL DEFAULT false,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL
);

-- Enable RLS
ALTER TABLE public.app_downloads ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.testimonials ENABLE ROW LEVEL SECURITY;

-- App Downloads Policies
-- Allow anyone to insert a download record (anonymous)
CREATE POLICY "Allow anonymous inserts for app_downloads"
    ON public.app_downloads FOR INSERT
    TO public, anon
    WITH CHECK (true);

-- Allow admins to read download records
CREATE POLICY "Allow authenticated read for app_downloads"
    ON public.app_downloads FOR SELECT
    TO authenticated
    USING (true);

-- Allow anyone to read the count (we will create a secure view or RPC for the count to avoid exposing individual IP addresses)
CREATE OR REPLACE FUNCTION get_total_app_downloads()
RETURNS INTEGER
LANGUAGE sql
SECURITY DEFINER
AS $$
    SELECT count(*)::integer FROM public.app_downloads;
$$;

-- Testimonials Policies
-- Allow anyone to read published testimonials
CREATE POLICY "Allow public read for published testimonials"
    ON public.testimonials FOR SELECT
    TO public, anon
    USING (is_published = true);

-- Allow authenticated admins full access to testimonials
CREATE POLICY "Allow authenticated full access for testimonials"
    ON public.testimonials FOR ALL
    TO authenticated
    USING (true)
    WITH CHECK (true);
