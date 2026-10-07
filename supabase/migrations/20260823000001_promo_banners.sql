CREATE TABLE IF NOT EXISTS public.promo_banners (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  category text NOT NULL,
  title text NOT NULL,
  icon_name text NOT NULL,
  gradient_start text NOT NULL,
  gradient_end text NOT NULL,
  target_link text,
  is_active boolean DEFAULT true,
  display_order integer DEFAULT 0,
  created_at timestamptz DEFAULT now()
);

-- RLS policies
ALTER TABLE public.promo_banners ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Allow public read access on promo_banners"
  ON public.promo_banners FOR SELECT
  USING (true);

-- Allow service role or authenticated admins full access
CREATE POLICY "Allow full access for authenticated users on promo_banners"
  ON public.promo_banners FOR ALL
  USING (auth.role() = 'authenticated');
