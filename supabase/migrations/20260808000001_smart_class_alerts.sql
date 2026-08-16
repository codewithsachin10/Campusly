-- Smart Class Alerts Migration

-- 1. User Devices (For Push Tokens)
CREATE TABLE IF NOT EXISTS public.user_devices (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    device_id TEXT NOT NULL,
    push_token TEXT,
    platform TEXT,
    app_version TEXT,
    is_active BOOLEAN DEFAULT true,
    last_seen_at TIMESTAMPTZ DEFAULT NOW(),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(user_id, device_id)
);

-- 2. Timetable Change Events (Audit Log)
CREATE TABLE IF NOT EXISTS public.timetable_change_events (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    timetable_id UUID NOT NULL, -- references custom_timetables or schedule
    timetable_entry_id TEXT NOT NULL, -- period ID or schedule ID
    change_type TEXT NOT NULL, -- 'VENUE_CHANGED', 'TIME_CHANGED', 'CANCELLED', 'FACULTY_CHANGED', 'GENERAL'
    old_data JSONB,
    new_data JSONB,
    affected_student_count INTEGER DEFAULT 0,
    created_by UUID REFERENCES auth.users(id),
    scheduled_class_time TIMESTAMPTZ,
    notification_status TEXT DEFAULT 'PENDING',
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 3. Notification Events (Inbox)
CREATE TABLE IF NOT EXISTS public.notification_events (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    change_event_id UUID REFERENCES public.timetable_change_events(id) ON DELETE CASCADE,
    type TEXT NOT NULL,
    title TEXT NOT NULL,
    body TEXT NOT NULL,
    data JSONB,
    priority TEXT DEFAULT 'HIGH',
    is_read BOOLEAN DEFAULT false,
    read_at TIMESTAMPTZ,
    sent_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 4. Notification Preferences
CREATE TABLE IF NOT EXISTS public.notification_preferences (
    user_id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    venue_changes BOOLEAN DEFAULT true,
    time_changes BOOLEAN DEFAULT true,
    cancellations BOOLEAN DEFAULT true,
    faculty_changes BOOLEAN DEFAULT true,
    general_updates BOOLEAN DEFAULT true,
    sound BOOLEAN DEFAULT true,
    vibration BOOLEAN DEFAULT true,
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Enable RLS
ALTER TABLE public.user_devices ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.timetable_change_events ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.notification_events ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.notification_preferences ENABLE ROW LEVEL SECURITY;

-- RLS Policies for user_devices
DROP POLICY IF EXISTS "Users can manage their own devices" ON public.user_devices;
CREATE POLICY "Users can manage their own devices" ON public.user_devices
    FOR ALL USING (auth.uid() = user_id);

-- RLS Policies for notification_events
DROP POLICY IF EXISTS "Users can view and update their own notifications" ON public.notification_events;
CREATE POLICY "Users can view and update their own notifications" ON public.notification_events
    FOR SELECT USING (auth.uid() = user_id);
DROP POLICY IF EXISTS "Users can update their own notifications" ON public.notification_events;
CREATE POLICY "Users can update their own notifications" ON public.notification_events
    FOR UPDATE USING (auth.uid() = user_id);

-- RLS Policies for notification_preferences
DROP POLICY IF EXISTS "Users can manage their own preferences" ON public.notification_preferences;
CREATE POLICY "Users can manage their own preferences" ON public.notification_preferences
    FOR ALL USING (auth.uid() = user_id);

-- RLS Policies for timetable_change_events
DROP POLICY IF EXISTS "Anyone can view change events" ON public.timetable_change_events;
CREATE POLICY "Anyone can view change events" ON public.timetable_change_events
    FOR SELECT USING (true);
