-- Campusly Forms Platform - Phase 1 Migration
-- Expands ENUMS and adds relational tables for collaboration, audit, and themes.

-- 1. EXPAND QUESTION TYPES
DO $$ BEGIN
    ALTER TYPE form_question_type ADD VALUE IF NOT EXISTS 'linear_scale';
    ALTER TYPE form_question_type ADD VALUE IF NOT EXISTS 'student_name';
    ALTER TYPE form_question_type ADD VALUE IF NOT EXISTS 'roll_number';
    ALTER TYPE form_question_type ADD VALUE IF NOT EXISTS 'college_email';
    ALTER TYPE form_question_type ADD VALUE IF NOT EXISTS 'department';
    ALTER TYPE form_question_type ADD VALUE IF NOT EXISTS 'year';
    ALTER TYPE form_question_type ADD VALUE IF NOT EXISTS 'semester';
    ALTER TYPE form_question_type ADD VALUE IF NOT EXISTS 'subject';
    ALTER TYPE form_question_type ADD VALUE IF NOT EXISTS 'faculty';
    ALTER TYPE form_question_type ADD VALUE IF NOT EXISTS 'attendance_input';
    ALTER TYPE form_question_type ADD VALUE IF NOT EXISTS 'video';
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

-- 2. FORM THEMES
CREATE TABLE IF NOT EXISTS form_themes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    form_id UUID REFERENCES forms(id) ON DELETE CASCADE UNIQUE,
    primary_color TEXT DEFAULT '#0f172a',
    background_color TEXT DEFAULT '#f8fafc',
    font_family TEXT DEFAULT 'Inter',
    corner_radius TEXT DEFAULT 'rounded-lg',
    cover_image_url TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 3. FORM COLLABORATORS
CREATE TABLE IF NOT EXISTS form_collaborators (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    form_id UUID REFERENCES forms(id) ON DELETE CASCADE,
    admin_id UUID REFERENCES admin_profiles(id) ON DELETE CASCADE,
    role TEXT DEFAULT 'editor', -- owner, editor, viewer
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(form_id, admin_id)
);

-- 4. FORM NOTIFICATIONS
CREATE TABLE IF NOT EXISTS form_notifications (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    form_id UUID REFERENCES forms(id) ON DELETE CASCADE,
    notify_on_response BOOLEAN DEFAULT false,
    email_recipients JSONB DEFAULT '[]'::jsonb,
    campusly_notification BOOLEAN DEFAULT false,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 5. FORM TEMPLATES
CREATE TABLE IF NOT EXISTS form_templates (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    title TEXT NOT NULL,
    description TEXT,
    category TEXT,
    schema_snapshot JSONB NOT NULL,
    created_by UUID REFERENCES admin_profiles(id),
    is_global BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 6. FORM AUDIT LOGS
CREATE TABLE IF NOT EXISTS form_audit_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    form_id UUID REFERENCES forms(id) ON DELETE CASCADE,
    actor_id UUID REFERENCES admin_profiles(id),
    action TEXT NOT NULL,
    details JSONB DEFAULT '{}'::jsonb,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- RLS POLICIES
ALTER TABLE form_themes ENABLE ROW LEVEL SECURITY;
ALTER TABLE form_collaborators ENABLE ROW LEVEL SECURITY;
ALTER TABLE form_notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE form_templates ENABLE ROW LEVEL SECURITY;
ALTER TABLE form_audit_logs ENABLE ROW LEVEL SECURITY;

DO $$ BEGIN
  DROP POLICY IF EXISTS "Admins full access to form_themes" ON form_themes;
  DROP POLICY IF EXISTS "Admins full access to form_collaborators" ON form_collaborators;
  DROP POLICY IF EXISTS "Admins full access to form_notifications" ON form_notifications;
  DROP POLICY IF EXISTS "Admins full access to form_templates" ON form_templates;
  DROP POLICY IF EXISTS "Admins full access to form_audit_logs" ON form_audit_logs;
EXCEPTION
  WHEN undefined_object THEN null;
END $$;

CREATE POLICY "Admins full access to form_themes" ON form_themes FOR ALL USING (EXISTS (SELECT 1 FROM admin_profiles WHERE id = auth.uid()));
CREATE POLICY "Admins full access to form_collaborators" ON form_collaborators FOR ALL USING (EXISTS (SELECT 1 FROM admin_profiles WHERE id = auth.uid()));
CREATE POLICY "Admins full access to form_notifications" ON form_notifications FOR ALL USING (EXISTS (SELECT 1 FROM admin_profiles WHERE id = auth.uid()));
CREATE POLICY "Admins full access to form_templates" ON form_templates FOR ALL USING (EXISTS (SELECT 1 FROM admin_profiles WHERE id = auth.uid()));
CREATE POLICY "Admins full access to form_audit_logs" ON form_audit_logs FOR ALL USING (EXISTS (SELECT 1 FROM admin_profiles WHERE id = auth.uid()));
