-- Enable Row Level Security on exam_schedules and exam_papers
ALTER TABLE public.exam_schedules ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.exam_papers ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if any to prevent conflicts
DROP POLICY IF EXISTS "Allow read access to exam_schedules" ON public.exam_schedules;
DROP POLICY IF EXISTS "Allow write access to exam_schedules" ON public.exam_schedules;
DROP POLICY IF EXISTS "Allow read access to exam_papers" ON public.exam_papers;
DROP POLICY IF EXISTS "Allow write access to exam_papers" ON public.exam_papers;

-- Read Access: Allow students and users to view exam schedules and papers
CREATE POLICY "Allow read access to exam_schedules"
  ON public.exam_schedules FOR SELECT
  USING (true);

CREATE POLICY "Allow read access to exam_papers"
  ON public.exam_papers FOR SELECT
  USING (true);

-- Write Access: Allow authenticated users / admins to manage schedules and papers
CREATE POLICY "Allow write access to exam_schedules"
  ON public.exam_schedules FOR ALL
  TO authenticated
  USING (true)
  WITH CHECK (true);

CREATE POLICY "Allow write access to exam_papers"
  ON public.exam_papers FOR ALL
  TO authenticated
  USING (true)
  WITH CHECK (true);
