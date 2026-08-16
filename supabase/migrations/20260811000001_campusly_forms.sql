-- Campusly Forms Platform Migration
-- Extends the schema to support dynamic forms, versions, audiences, and responses.

-- ENUMS
DO $$ BEGIN
    CREATE TYPE form_status AS ENUM ('draft', 'scheduled', 'published', 'closed', 'archived');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
    CREATE TYPE form_question_type AS ENUM (
      'short_text', 'long_text', 'email', 'phone', 'url',
      'number',
      'single_choice', 'multiple_choice', 'dropdown', 'yes_no',
      'star_rating', 'number_rating', 'emoji_rating',
      'date', 'time', 'date_time',
      'image_upload', 'file_upload', 'pdf_upload',
      'heading', 'description', 'divider', 'section'
    );
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

-- FORMS
CREATE TABLE IF NOT EXISTS forms (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    title TEXT NOT NULL,
    description TEXT,
    category TEXT DEFAULT 'General',
    icon TEXT,
    cover_image_url TEXT,
    status form_status DEFAULT 'draft',
    settings JSONB DEFAULT '{}'::jsonb, -- stores availability rules, limits, etc.
    created_by UUID REFERENCES admin_profiles(id),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    published_at TIMESTAMPTZ,
    archived_at TIMESTAMPTZ
);

-- FORM VERSIONS (to preserve historical response integrity)
CREATE TABLE IF NOT EXISTS form_versions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    form_id UUID REFERENCES forms(id) ON DELETE CASCADE,
    version_number INTEGER NOT NULL DEFAULT 1,
    status form_status DEFAULT 'draft',
    created_by UUID REFERENCES admin_profiles(id),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    published_at TIMESTAMPTZ
);

-- SECTIONS
CREATE TABLE IF NOT EXISTS form_sections (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    form_version_id UUID REFERENCES form_versions(id) ON DELETE CASCADE,
    title TEXT,
    description TEXT,
    display_order INTEGER NOT NULL DEFAULT 0
);

-- QUESTIONS
CREATE TABLE IF NOT EXISTS form_questions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    form_version_id UUID REFERENCES form_versions(id) ON DELETE CASCADE,
    section_id UUID REFERENCES form_sections(id) ON DELETE CASCADE,
    type form_question_type NOT NULL,
    title TEXT NOT NULL,
    description TEXT,
    placeholder TEXT,
    required BOOLEAN DEFAULT false,
    display_order INTEGER NOT NULL DEFAULT 0,
    settings JSONB DEFAULT '{}'::jsonb,
    validation_rules JSONB DEFAULT '{}'::jsonb,
    logic_rules JSONB DEFAULT '[]'::jsonb,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- OPTIONS (for multiple choice, dropdowns, etc.)
CREATE TABLE IF NOT EXISTS form_options (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    question_id UUID REFERENCES form_questions(id) ON DELETE CASCADE,
    label TEXT NOT NULL,
    value TEXT NOT NULL,
    display_order INTEGER NOT NULL DEFAULT 0
);

-- AUDIENCES (who can see the form)
CREATE TABLE IF NOT EXISTS form_audiences (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    form_id UUID REFERENCES forms(id) ON DELETE CASCADE,
    department TEXT, -- NULL means all
    year INTEGER,
    semester INTEGER,
    section TEXT,
    batch TEXT,
    timetable_group TEXT,
    student_id UUID -- removed foreign key constraint to students because we don't know the exact table definition yet, keeping it generic UUID
);

-- PUBLIC LINKS (for smart deep linking)
CREATE TABLE IF NOT EXISTS form_public_links (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    form_id UUID REFERENCES forms(id) ON DELETE CASCADE,
    form_version_id UUID REFERENCES form_versions(id) ON DELETE CASCADE,
    public_token TEXT UNIQUE NOT NULL,
    active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    expires_at TIMESTAMPTZ
);

-- RESPONSES
CREATE TABLE IF NOT EXISTS form_responses (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    form_id UUID REFERENCES forms(id) ON DELETE CASCADE,
    form_version_id UUID REFERENCES form_versions(id) ON DELETE CASCADE,
    user_id UUID, -- UUID of student
    status TEXT DEFAULT 'started', -- started, submitted, abandoned
    is_test BOOLEAN DEFAULT false,
    metadata JSONB DEFAULT '{}'::jsonb,
    submitted_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ANSWERS
CREATE TABLE IF NOT EXISTS form_response_answers (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    response_id UUID REFERENCES form_responses(id) ON DELETE CASCADE,
    question_id UUID REFERENCES form_questions(id) ON DELETE CASCADE,
    answer_text TEXT,
    answer_number NUMERIC,
    answer_boolean BOOLEAN,
    answer_json JSONB,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- FILE RESPONSES
CREATE TABLE IF NOT EXISTS form_response_files (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    response_id UUID REFERENCES form_responses(id) ON DELETE CASCADE,
    question_id UUID REFERENCES form_questions(id) ON DELETE CASCADE,
    storage_path TEXT NOT NULL,
    file_name TEXT NOT NULL,
    mime_type TEXT,
    file_size INTEGER,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ROW LEVEL SECURITY (RLS)
ALTER TABLE forms ENABLE ROW LEVEL SECURITY;
ALTER TABLE form_versions ENABLE ROW LEVEL SECURITY;
ALTER TABLE form_sections ENABLE ROW LEVEL SECURITY;
ALTER TABLE form_questions ENABLE ROW LEVEL SECURITY;
ALTER TABLE form_options ENABLE ROW LEVEL SECURITY;
ALTER TABLE form_audiences ENABLE ROW LEVEL SECURITY;
ALTER TABLE form_public_links ENABLE ROW LEVEL SECURITY;
ALTER TABLE form_responses ENABLE ROW LEVEL SECURITY;
ALTER TABLE form_response_answers ENABLE ROW LEVEL SECURITY;
ALTER TABLE form_response_files ENABLE ROW LEVEL SECURITY;

-- DROP EXISTING POLICIES (for idempotent script execution)
DO $$ BEGIN
  DROP POLICY IF EXISTS "Admins full access to forms" ON forms;
  DROP POLICY IF EXISTS "Admins full access to form_versions" ON form_versions;
  DROP POLICY IF EXISTS "Admins full access to form_sections" ON form_sections;
  DROP POLICY IF EXISTS "Admins full access to form_questions" ON form_questions;
  DROP POLICY IF EXISTS "Admins full access to form_options" ON form_options;
  DROP POLICY IF EXISTS "Admins full access to form_audiences" ON form_audiences;
  DROP POLICY IF EXISTS "Admins full access to form_public_links" ON form_public_links;
  DROP POLICY IF EXISTS "Admins full access to form_responses" ON form_responses;
  DROP POLICY IF EXISTS "Admins full access to form_response_answers" ON form_response_answers;
  DROP POLICY IF EXISTS "Admins full access to form_response_files" ON form_response_files;
  
  DROP POLICY IF EXISTS "Students can read published forms" ON forms;
  DROP POLICY IF EXISTS "Students can read published form_versions" ON form_versions;
  DROP POLICY IF EXISTS "Students can read sections of published versions" ON form_sections;
  DROP POLICY IF EXISTS "Students can read questions of published versions" ON form_questions;
  DROP POLICY IF EXISTS "Students can read options of published versions" ON form_options;
  DROP POLICY IF EXISTS "Students can read public links" ON form_public_links;
  
  DROP POLICY IF EXISTS "Students can insert their own responses" ON form_responses;
  DROP POLICY IF EXISTS "Students can select their own responses" ON form_responses;
  DROP POLICY IF EXISTS "Students can update their own unsubmitted responses" ON form_responses;
  
  DROP POLICY IF EXISTS "Students can insert their own answers" ON form_response_answers;
  DROP POLICY IF EXISTS "Students can select their own answers" ON form_response_answers;
  
  DROP POLICY IF EXISTS "Students can insert their own file records" ON form_response_files;
  DROP POLICY IF EXISTS "Students can select their own file records" ON form_response_files;
EXCEPTION
  WHEN undefined_object THEN null;
END $$;

-- Admins get full access to all forms tables
CREATE POLICY "Admins full access to forms" ON forms FOR ALL USING (
  EXISTS (SELECT 1 FROM admin_profiles WHERE id = auth.uid())
);
CREATE POLICY "Admins full access to form_versions" ON form_versions FOR ALL USING (
  EXISTS (SELECT 1 FROM admin_profiles WHERE id = auth.uid())
);
CREATE POLICY "Admins full access to form_sections" ON form_sections FOR ALL USING (
  EXISTS (SELECT 1 FROM admin_profiles WHERE id = auth.uid())
);
CREATE POLICY "Admins full access to form_questions" ON form_questions FOR ALL USING (
  EXISTS (SELECT 1 FROM admin_profiles WHERE id = auth.uid())
);
CREATE POLICY "Admins full access to form_options" ON form_options FOR ALL USING (
  EXISTS (SELECT 1 FROM admin_profiles WHERE id = auth.uid())
);
CREATE POLICY "Admins full access to form_audiences" ON form_audiences FOR ALL USING (
  EXISTS (SELECT 1 FROM admin_profiles WHERE id = auth.uid())
);
CREATE POLICY "Admins full access to form_public_links" ON form_public_links FOR ALL USING (
  EXISTS (SELECT 1 FROM admin_profiles WHERE id = auth.uid())
);
CREATE POLICY "Admins full access to form_responses" ON form_responses FOR ALL USING (
  EXISTS (SELECT 1 FROM admin_profiles WHERE id = auth.uid())
);
CREATE POLICY "Admins full access to form_response_answers" ON form_response_answers FOR ALL USING (
  EXISTS (SELECT 1 FROM admin_profiles WHERE id = auth.uid())
);
CREATE POLICY "Admins full access to form_response_files" ON form_response_files FOR ALL USING (
  EXISTS (SELECT 1 FROM admin_profiles WHERE id = auth.uid())
);

-- Public/Student read access to published forms and related elements
CREATE POLICY "Students can read published forms" ON forms FOR SELECT USING (
  status = 'published'
);
CREATE POLICY "Students can read published form_versions" ON form_versions FOR SELECT USING (
  status = 'published'
);
CREATE POLICY "Students can read sections of published versions" ON form_sections FOR SELECT USING (
  EXISTS (SELECT 1 FROM form_versions WHERE id = form_sections.form_version_id AND status = 'published')
);
CREATE POLICY "Students can read questions of published versions" ON form_questions FOR SELECT USING (
  EXISTS (SELECT 1 FROM form_versions WHERE id = form_questions.form_version_id AND status = 'published')
);
CREATE POLICY "Students can read options of published versions" ON form_options FOR SELECT USING (
  EXISTS (
    SELECT 1 FROM form_questions fq 
    JOIN form_versions fv ON fv.id = fq.form_version_id 
    WHERE fq.id = form_options.question_id AND fv.status = 'published'
  )
);
CREATE POLICY "Students can read public links" ON form_public_links FOR SELECT USING (
  active = true
);

-- Students can insert and select their OWN responses
CREATE POLICY "Students can insert their own responses" ON form_responses FOR INSERT WITH CHECK (
  auth.uid() = user_id OR user_id IS NULL
);
CREATE POLICY "Students can select their own responses" ON form_responses FOR SELECT USING (
  auth.uid() = user_id OR user_id IS NULL
);
CREATE POLICY "Students can update their own unsubmitted responses" ON form_responses FOR UPDATE USING (
  (auth.uid() = user_id OR user_id IS NULL) AND status != 'submitted'
);

CREATE POLICY "Students can insert their own answers" ON form_response_answers FOR INSERT WITH CHECK (
  EXISTS (SELECT 1 FROM form_responses fr WHERE fr.id = form_response_answers.response_id AND (fr.user_id = auth.uid() OR fr.user_id IS NULL))
);
CREATE POLICY "Students can select their own answers" ON form_response_answers FOR SELECT USING (
  EXISTS (SELECT 1 FROM form_responses fr WHERE fr.id = form_response_answers.response_id AND (fr.user_id = auth.uid() OR fr.user_id IS NULL))
);

CREATE POLICY "Students can insert their own file records" ON form_response_files FOR INSERT WITH CHECK (
  EXISTS (SELECT 1 FROM form_responses fr WHERE fr.id = form_response_files.response_id AND (fr.user_id = auth.uid() OR fr.user_id IS NULL))
);
CREATE POLICY "Students can select their own file records" ON form_response_files FOR SELECT USING (
  EXISTS (SELECT 1 FROM form_responses fr WHERE fr.id = form_response_files.response_id AND (fr.user_id = auth.uid() OR fr.user_id IS NULL))
);
