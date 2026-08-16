-- Migration: Admin Management System & RBAC

-- 1. Enums
DO $$ BEGIN
    CREATE TYPE admin_status AS ENUM ('Active', 'Pending', 'Suspended', 'Disabled');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

-- 2. Core Tables
CREATE TABLE IF NOT EXISTS public.roles (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL UNIQUE,
    description TEXT,
    is_system_role BOOLEAN DEFAULT false,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.admin_profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    full_name TEXT NOT NULL,
    email TEXT NOT NULL UNIQUE,
    phone TEXT,
    employee_id TEXT UNIQUE,
    department_id UUID, -- intentionally omitting FK for now to prevent issues if departments table is missing
    designation TEXT,
    status admin_status DEFAULT 'Pending',
    role_id UUID REFERENCES public.roles(id) ON DELETE RESTRICT,
    mfa_enabled BOOLEAN DEFAULT false,
    last_active_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.permissions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    module TEXT NOT NULL,
    action TEXT NOT NULL,
    description TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(module, action)
);

CREATE TABLE IF NOT EXISTS public.role_permissions (
    role_id UUID REFERENCES public.roles(id) ON DELETE CASCADE,
    permission_id UUID REFERENCES public.permissions(id) ON DELETE CASCADE,
    PRIMARY KEY (role_id, permission_id)
);

CREATE TABLE IF NOT EXISTS public.admin_scopes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    admin_id UUID REFERENCES public.admin_profiles(id) ON DELETE CASCADE,
    scope_type TEXT NOT NULL,
    scope_id UUID,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 3. Audit Logs
CREATE TABLE IF NOT EXISTS public.admin_audit_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    actor_id UUID REFERENCES public.admin_profiles(id) ON DELETE SET NULL,
    action TEXT NOT NULL,
    resource_type TEXT NOT NULL,
    resource_id UUID,
    old_value JSONB,
    new_value JSONB,
    ip_address TEXT,
    user_agent TEXT,
    metadata JSONB,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Protect audit logs (Immutable)
CREATE OR REPLACE FUNCTION prevent_audit_log_modification()
RETURNS TRIGGER AS $$
BEGIN
    RAISE EXCEPTION 'Audit logs are immutable and cannot be updated or deleted.';
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_prevent_audit_log_update ON public.admin_audit_logs;
CREATE TRIGGER trg_prevent_audit_log_update
BEFORE UPDATE ON public.admin_audit_logs
FOR EACH ROW EXECUTE FUNCTION prevent_audit_log_modification();

DROP TRIGGER IF EXISTS trg_prevent_audit_log_delete ON public.admin_audit_logs;
CREATE TRIGGER trg_prevent_audit_log_delete
BEFORE DELETE ON public.admin_audit_logs
FOR EACH ROW EXECUTE FUNCTION prevent_audit_log_modification();


-- 4. RLS & Security Definer Functions
ALTER TABLE public.admin_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.roles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.permissions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.role_permissions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.admin_scopes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.admin_audit_logs ENABLE ROW LEVEL SECURITY;

-- Helper function to check permission
CREATE OR REPLACE FUNCTION public.has_permission(p_admin_id UUID, p_action TEXT)
RETURNS BOOLEAN AS $$
DECLARE
    v_has_permission BOOLEAN;
BEGIN
    SELECT EXISTS (
        SELECT 1 
        FROM public.admin_profiles ap
        JOIN public.role_permissions rp ON ap.role_id = rp.role_id
        JOIN public.permissions p ON rp.permission_id = p.id
        WHERE ap.id = p_admin_id AND p.action = p_action AND ap.status = 'Active'
    ) INTO v_has_permission;
    
    RETURN v_has_permission;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 5. Seed Data (Permissions & Roles)
INSERT INTO public.permissions (module, action, description) VALUES
('People', 'manage_admins', 'Create, edit, suspend, and remove administrators'),
('People', 'view_students', 'View student profiles'),
('People', 'edit_students', 'Modify student data'),
('Academic', 'view_curriculum', 'View curriculum and subjects'),
('Academic', 'edit_curriculum', 'Modify curriculum, subjects, semesters'),
('Timetable', 'view_timetable', 'View timetables'),
('Timetable', 'edit_timetable', 'Create and edit timetables'),
('Support', 'view_tickets', 'View support tickets'),
('Support', 'respond_tickets', 'Assign and respond to support tickets'),
('System', 'manage_settings', 'Modify global system settings')
ON CONFLICT (module, action) DO NOTHING;

INSERT INTO public.roles (name, description, is_system_role) VALUES
('Super Admin', 'Full access to all modules and system settings.', true),
('Academic Admin', 'Manages curriculum, subjects, and timetables.', true),
('Department Admin', 'Manages department-specific academic data.', true),
('Support Admin', 'Manages student support tickets and reports.', true)
ON CONFLICT (name) DO NOTHING;

-- Map all permissions to Super Admin
INSERT INTO public.role_permissions (role_id, permission_id)
SELECT r.id, p.id
FROM public.roles r, public.permissions p
WHERE r.name = 'Super Admin'
ON CONFLICT DO NOTHING;

-- Map specific permissions to Academic Admin
INSERT INTO public.role_permissions (role_id, permission_id)
SELECT r.id, p.id
FROM public.roles r
JOIN public.permissions p ON p.action IN ('view_students', 'view_curriculum', 'edit_curriculum', 'view_timetable', 'edit_timetable')
WHERE r.name = 'Academic Admin'
ON CONFLICT DO NOTHING;

-- Map specific permissions to Department Admin
INSERT INTO public.role_permissions (role_id, permission_id)
SELECT r.id, p.id
FROM public.roles r
JOIN public.permissions p ON p.action IN ('view_students', 'view_curriculum', 'view_timetable', 'edit_timetable')
WHERE r.name = 'Department Admin'
ON CONFLICT DO NOTHING;

-- Map specific permissions to Support Admin
INSERT INTO public.role_permissions (role_id, permission_id)
SELECT r.id, p.id
FROM public.roles r
JOIN public.permissions p ON p.action IN ('view_tickets', 'respond_tickets', 'view_students')
WHERE r.name = 'Support Admin'
ON CONFLICT DO NOTHING;
