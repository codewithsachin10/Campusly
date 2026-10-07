ALTER TABLE public.promo_banners
ADD COLUMN IF NOT EXISTS target_departments uuid[],
ADD COLUMN IF NOT EXISTS target_batches text[],
ADD COLUMN IF NOT EXISTS start_date timestamptz,
ADD COLUMN IF NOT EXISTS end_date timestamptz,
ADD COLUMN IF NOT EXISTS clicks integer DEFAULT 0;

CREATE OR REPLACE FUNCTION increment_banner_clicks(banner_id uuid)
RETURNS void AS $$
BEGIN
  UPDATE public.promo_banners
  SET clicks = clicks + 1
  WHERE id = banner_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
