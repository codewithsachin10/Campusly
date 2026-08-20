import { queryOptions } from "@tanstack/react-query";
import { supabase } from "../supabase";
import type { AppSettings, College, Department, Faculty, Student, TimetableSlot, Assignment, Exam } from "../types";

/**
 * Data layer integrated with Supabase.
 */

export const api = {
  dashboard: {
    stats: async () => {
      const [
        { count: students },
        { count: faculty },
        { count: departments },
      ] = await Promise.all([
        supabase.from("students").select("*", { count: "exact", head: true }),
        supabase.from("faculties").select("*", { count: "exact", head: true }),
        supabase.from("sections").select("*", { count: "exact", head: true }),
      ]);

      const { count: subjects } = await supabase.from("subjects").select("*", { count: "exact", head: true });
      const { count: assignments } = await supabase.from("assignments").select("*", { count: "exact", head: true });
      const { count: events } = await supabase.from("events").select("*", { count: "exact", head: true });
      const { count: notifications } = await supabase.from("notifications").select("*", { count: "exact", head: true });
      const { count: upcomingExams } = await supabase.from("exams").select("*", { count: "exact", head: true });

      return {
        students: students || 0,
        faculty: faculty || 0,
        departments: departments || 0,
        subjects: subjects || 0,
        assignments: assignments || 0,
        events: events || 0,
        notifications: notifications || 0,
        upcomingExams: upcomingExams || 0,
      };
    },
    studentsPerDepartment: async () => {
      // In Postgres, we would do a join or group by, but for simplicity we fetch both and map them
      const { data: students } = await supabase.from("students").select("departmentId");
      const { data: departments } = await supabase.from("departments").select("id, name");

      return (departments || []).map((d) => ({
        department: d.name,
        students: (students || []).filter((s) => s.departmentId === d.id).length,
      }));
    },
    attendance: async () => {
      const { count } = await supabase
        .from("attendance")
        .select("*", { count: "exact", head: true });
      return count ? [{ label: "Total Records", value: count }] : [];
    },
    activities: async () => {
      const { data, error } = await supabase
        .from("event_registrations")
        .select("*, events(title), students(name)")
        .limit(5);
      if (error || !data) return [];
      return data.map((r: any) => ({
        id: r.id,
        actor: r.students?.name || "A student",
        action: "registered for",
        target: r.events?.title || "an event",
        at: r.created_at ? new Date(r.created_at).toLocaleDateString() : "Recently"
      }));
    },
    notifications: async () => {
      const { data, error } = await supabase
        .from("notifications")
        .select("*")
        .order("created_at", { ascending: false });
      if (error || !data) return [];

      return data.map((n) => ({
        id: n.id,
        title: n.title || "Announcement",
        description: n.body || "",
        priority: n.priority || "normal",
        target: n.target || "Everyone",
        at: n.created_at ? new Date(n.created_at).toLocaleDateString() : "Recently",
      }));
    },
    todaysClasses: async () => {
      const today = new Date().toLocaleDateString("en-US", { weekday: "long" });
      const { data } = await supabase.from("schedule").select("*").eq("day", today).limit(5);
      return data || [];
    },
    events: async () => {
      const { data, error } = await supabase
        .from("events")
        .select("*")
        .order("date", { ascending: true });
      if (error || !data) return [];
      return data.map((e) => ({
        id: e.id,
        title: e.title || "Event",
        date: e.date || "TBD",
        venue: e.venue || "TBD",
      }));
    },
    wipeDatabase: async () => {
      // Wiping Supabase requires deleting from tables. Be careful with foreign keys.
      const tables = ["faculties", "sections", "events", "notifications", "schedule"];
      for (const t of tables) {
        // Warning: This will delete everything if RLS allows it!
        await supabase.from(t).delete().neq("id", "00000000-0000-0000-0000-000000000000");
      }
      return true;
    },
  },

  students: {
    list: async () => {
      const { data, error } = await supabase.from("students").select("*");
      if (error || !data) return [];
      return data as Student[];
    },
    create: async (payload: Omit<Student, "id">) => {
      const { data, error } = await supabase.from("students").insert([payload]).select().single();
      if (error) throw error;
      return data as Student;
    },
    update: async (id: string, payload: Partial<Student>) => {
      const { data, error } = await supabase
        .from("students")
        .update(payload)
        .eq("id", id)
        .select()
        .single();
      if (error) throw error;
      return data as Student;
    },
    remove: async (id: string) => {
      const { error } = await supabase.from("students").delete().eq("id", id);
      if (error) throw error;
      return id;
    },
  },

  faculty: {
    list: async () => {
      const { data, error } = await supabase.from("faculties").select("*");
      if (error || !data) return [];
      return data as Faculty[];
    },
    create: async (payload: Omit<Faculty, "id">) => {
      const { data, error } = await supabase.from("faculties").insert([payload]).select().single();
      if (error) throw error;
      return data as Faculty;
    },
    update: async (id: string, payload: Partial<Faculty>) => {
      const { data, error } = await supabase
        .from("faculties")
        .update(payload)
        .eq("id", id)
        .select()
        .single();
      if (error) throw error;
      return data as Faculty;
    },
    remove: async (id: string) => {
      const { error } = await supabase.from("faculties").delete().eq("id", id);
      if (error) throw error;
      return id;
    },
  },

  departments: {
    list: async () => {
      const { data, error } = await supabase.from("departments").select("*");
      if (error || !data) return [];
      return data as Department[];
    },
    create: async (payload: Omit<Department, "id">) => {
      const { data, error } = await supabase.from("departments").insert([payload]).select().single();
      if (error) throw error;
      return data as Department;
    },
    update: async (id: string, payload: Partial<Department>) => {
      const { data, error } = await supabase
        .from("departments")
        .update(payload)
        .eq("id", id)
        .select()
        .single();
      if (error) throw error;
      return data as Department;
    },
    remove: async (id: string) => {
      const { error } = await supabase.from("departments").delete().eq("id", id);
      if (error) throw error;
      return id;
    },
  },

  timetable: {
    list: async (sectionKey: string) => {
      const { data, error } = await supabase
        .from("schedule")
        .select("*")
        .eq("sectionKey", sectionKey);

      if (error || !data || data.length === 0) return [];

      return data.map((d) => ({
        id: d.id,
        sectionKey: d.sectionKey,
        day: d.day,
        period: d.period,
        subject: d.subject,
        faculty: d.faculty,
        room: d.room,
        type: d.type,
      })) as TimetableSlot[];
    },
    sections: async () => {
      // Retrieve unique sections from the students table as a fallback since sections table might not exist
      const { data, error } = await supabase.from("sections").select("id, name").limit(1);
      if (!error && data) {
         // Sections table exists
         const { data: allSections } = await supabase.from("sections").select("id, name");
         return (allSections || []).map((d) => ({ key: d.name, label: d.name }));
      }
      
      // Fallback: extract unique combinations of department and section from students
      const { data: studentsData } = await supabase.from("students").select("section");
      if (!studentsData) return [];
      const unique = Array.from(new Set(studentsData.map(s => s.section).filter(Boolean)));
      return unique.map(s => ({ key: s as string, label: s as string }));
    },
    periods: async () => {
      const { data, error } = await supabase
        .from("periods")
        .select("*")
        .order("index", { ascending: true });
      if (error || !data || data.length === 0) {
        // Fallback inserted to DB if table is empty
        const defaultPeriods = [
          { index: 1, label: "09:00 – 10:00" },
          { index: 2, label: "10:15 – 11:15" },
          { index: 3, label: "11:30 – 12:30" },
          { index: 4, label: "13:30 – 14:30" },
          { index: 5, label: "14:45 – 15:45" },
          { index: 6, label: "16:00 – 17:00" },
        ];
        await supabase.from("periods").insert(defaultPeriods);
        return defaultPeriods;
      }
      return data;
    },
    save: async (slots: TimetableSlot[], sectionKey: string) => {
      // First, delete existing slots for this section
      await supabase.from("schedule").delete().eq("sectionKey", sectionKey);

      if (slots.length === 0) return [];

      // Remove 'id' if it's a new temporary id before insert
      const toInsert = slots.map(({ id, ...rest }) => ({
        ...rest,
        sectionKey,
      }));

      const { data, error } = await supabase.from("schedule").insert(toInsert).select();
      if (error) throw error;
      return data as TimetableSlot[];
    },
  },

  college: {
    get: async () => {
      const { data, error } = await supabase.from("colleges").select("*").limit(1).maybeSingle();
      if (error || !data) {
        const defaultCollege = {
          id: "main",
          name: "My College",
          shortName: "MC",
          email: "contact@college.edu",
          phone: "-",
          website: "-",
          address: "-",
          affiliation: "-",
          established: "-",
        };
        await supabase.from("colleges").upsert([defaultCollege]);
        return defaultCollege as College;
      }
      return data as College;
    },
    update: async (payload: Partial<College>) => {
      // Upsert pattern
      const { data, error } = await supabase
        .from("colleges")
        .upsert([{ id: "main", ...payload }])
        .select()
        .single();
      if (error) throw error;
      return data as College;
    },
  },

  customTimetables: {
    list: async () => {
      const { data, error } = await supabase.from("custom_timetables").select("*").order("created_at", { ascending: false });
      if (error || !data) return [];
      return data as any[];
    },
    get: async (id: string) => {
      const { data, error } = await supabase.from("custom_timetables").select("*").eq("id", id).single();
      if (error) throw error;
      return data;
    },
    create: async (payload: any) => {
      const { data, error } = await supabase.from("custom_timetables").insert([payload]).select().single();
      if (error) throw error;
      return data;
    },
    update: async (id: string, payload: any) => {
      const { data, error } = await supabase.from("custom_timetables").update(payload).eq("id", id).select().single();
      if (error) throw error;
      return data;
    },
    remove: async (id: string) => {
      const { error } = await supabase.from("custom_timetables").delete().eq("id", id);
      if (error) throw error;
      return id;
    },
    getPeriods: async (timetableId: string) => {
      const { data, error } = await supabase.from("custom_timetable_periods").select("*").eq("timetable_id", timetableId);
      if (error || !data) return [];
      return data as any[];
    },
    getMembers: async (timetableId: string) => {
      const { data: members, error } = await supabase.from("student_timetable_members").select("*").eq("timetable_id", timetableId);
      if (error || !members || members.length === 0) return [];
      
      const studentIds = members.map((m: any) => m.student_id);
      const { data: students, error: studentError } = await supabase.from("students").select("*").in("id", studentIds);
      
      if (studentError || !students) return [];
      return students;
    },
    savePeriods: async (timetableId: string, periods: any[]) => {
      await supabase.from("custom_timetable_periods").delete().eq("timetable_id", timetableId);
      if (periods.length === 0) return [];
      const toInsert = periods.map(({ id, ...rest }) => ({
        ...rest,
        timetable_id: timetableId,
      }));
      const { data, error } = await supabase.from("custom_timetable_periods").insert(toInsert).select();
      if (error) throw new Error(error.message);
      return data;
    },
    getMappedSubjects: async (timetableId: string) => {
      const { data, error } = await supabase.from("custom_timetable_subjects").select("*").eq("timetable_id", timetableId);
      if (error || !data) return [];
      return data;
    },
    addMappedSubject: async (payload: { timetable_id: string; subject: string; faculty: string }) => {
      const { data, error } = await supabase.from("custom_timetable_subjects").insert([payload]).select().single();
      if (error) throw new Error(error.message);
      return data;
    },
    removeMappedSubject: async (id: string) => {
      const { error } = await supabase.from("custom_timetable_subjects").delete().eq("id", id);
      if (error) throw new Error(error.message);
    },
  },

  // --- ASSIGNMENTS ---
  assignments: {
    list: async () => {
      const { data, error } = await supabase.from("assignments").select("*").order("created_at", { ascending: false });
      if (error) throw new Error(error.message);
      return data;
    },
    create: async (assignment: any) => {
      const { data, error } = await supabase.from("assignments").insert([assignment]).select().single();
      if (error) throw new Error(error.message);
      return data;
    },
    update: async (id: string, assignment: any) => {
      const { data, error } = await supabase.from("assignments").update(assignment).eq("id", id).select().single();
      if (error) throw new Error(error.message);
      return data;
    },
    remove: async (id: string) => {
      const { error } = await supabase.from("assignments").delete().eq("id", id);
      if (error) throw new Error(error.message);
    },
  },

  // --- EXAMS ---
  exams: {
    list: async () => {
      const { data, error } = await supabase.from("exams").select("*").order("created_at", { ascending: false });
      if (error) throw new Error(error.message);
      return data;
    },
    create: async (exam: any) => {
      const { data, error } = await supabase.from("exams").insert([exam]).select().single();
      if (error) throw new Error(error.message);
      return data;
    },
    update: async (id: string, exam: any) => {
      const { data, error } = await supabase.from("exams").update(exam).eq("id", id).select().single();
      if (error) throw new Error(error.message);
      return data;
    },
    remove: async (id: string) => {
      const { error } = await supabase.from("exams").delete().eq("id", id);
      if (error) throw new Error(error.message);
    },
  },
  // --- CURRICULUM ---
  curriculum: {
    listRegulations: async () => {
      const { data, error } = await supabase.from("academic_regulations").select("*, departments(name)").order("created_at", { ascending: false });
      if (error) throw new Error(error.message);
      return data;
    },
    getRegulationDetails: async (id: string) => {
      const { data: regulation, error: regError } = await supabase
        .from("academic_regulations")
        .select("*, departments(name)")
        .eq("id", id)
        .single();
      if (regError) throw new Error(regError.message);

      const { data: semesters, error: semError } = await supabase
        .from("academic_semesters")
        .select("*, curriculum_subjects(*)")
        .eq("regulation_id", id)
        .order("semester_number", { ascending: true });
      
      if (semError) throw new Error(semError.message);

      // Sort subjects inside semesters by code or just leave as is
      return {
        ...regulation,
        semesters: semesters || [],
      };
    },
    getRegulation: async (id: string) => {
      const { data, error } = await supabase.from("academic_regulations").select("*, departments(name)").eq("id", id).single();
      if (error) throw new Error(error.message);
      return data;
    },
    createRegulation: async (regulation: any) => {
      const { data, error } = await supabase.from("academic_regulations").insert([regulation]).select().single();
      if (error) throw new Error(error.message);
      return data;
    },
    updateRegulation: async (id: string, regulation: any) => {
      const { data, error } = await supabase.from("academic_regulations").update(regulation).eq("id", id).select().single();
      if (error) throw new Error(error.message);
      return data;
    },
    deleteRegulation: async (id: string) => {
      const { error } = await supabase.from("academic_regulations").delete().eq("id", id);
      if (error) throw new Error(error.message);
    },
    listSemesters: async (regulationId: string) => {
      const { data, error } = await supabase.from("academic_semesters").select("*").eq("regulation_id", regulationId).order("semester_number", { ascending: true });
      if (error) throw new Error(error.message);
      return data;
    },
    listSubjects: async (semesterId: string) => {
      const { data, error } = await supabase.from("curriculum_subjects").select("*").eq("semester_id", semesterId);
      if (error) throw new Error(error.message);
      return data;
    },
    createSemester: async (semester: any) => {
      const { data, error } = await supabase.from("academic_semesters").insert([semester]).select().single();
      if (error) throw new Error(error.message);
      return data;
    },
    createSubject: async (subject: any) => {
      const { data, error } = await supabase.from("curriculum_subjects").insert([subject]).select().single();
      if (error) throw new Error(error.message);
      return data;
    },
  },

  settings: {
    get: async () => {
      const { data, error } = await supabase.from("settings").select("*").limit(1).maybeSingle();
      if (error || !data) {
        const defaultSettings = {
          id: "main",
          academicYear: "2025-26",
          weekStart: "Monday",
          periodsPerDay: 6,
          emailNotifications: false,
          pushNotifications: false,
          weeklyDigest: false,
          twoFactor: false,
        };
        await supabase.from("settings").upsert([defaultSettings]);
        return defaultSettings as AppSettings;
      }
      return data as AppSettings;
    },
    update: async (payload: Partial<AppSettings>) => {
      const { data, error } = await supabase
        .from("settings")
        .upsert([{ id: "main", ...payload }])
        .select()
        .single();
      if (error) throw error;
      return data as AppSettings;
    },
    changePassword: async (currentPassword: string, newPassword: string) => {
      if (currentPassword === newPassword) {
        throw new Error("The new password must be different from the current one.");
      }
      return { ok: true as const };
    },
  },

  sessions: {
    list: async () => {
      const { data, error } = await supabase.from("academic_sessions").select("*").order("start_date", { ascending: false });
      if (error || !data) return [];
      return data as AcademicSession[];
    },
    create: async (payload: Omit<AcademicSession, "id" | "created_at">) => {
      // if setting to active, deactivate others
      if (payload.is_active) {
        await supabase.from("academic_sessions").update({ is_active: false }).neq("id", "00000000-0000-0000-0000-000000000000");
      }
      const { data, error } = await supabase.from("academic_sessions").insert([payload]).select().single();
      if (error) throw error;
      return data as AcademicSession;
    },
    update: async (id: string, payload: Partial<AcademicSession>) => {
      if (payload.is_active) {
        await supabase.from("academic_sessions").update({ is_active: false }).neq("id", id);
      }
      const { data, error } = await supabase
        .from("academic_sessions")
        .update(payload)
        .eq("id", id)
        .select()
        .single();
      if (error) throw error;
      return data as AcademicSession;
    },
    delete: async (id: string) => {
      const { error } = await supabase.from("academic_sessions").delete().eq("id", id);
      if (error) throw error;
      return id;
    },
    listBatches: async (sessionId: string) => {
      const { data, error } = await supabase.from("academic_batches").select("*").eq("session_id", sessionId).order("admission_year", { ascending: false });
      if (error || !data) return [];
      return data as AcademicBatch[];
    },
    saveBatches: async (sessionId: string, batches: Omit<AcademicBatch, "id" | "created_at">[]) => {
      // Upsert batches for a session
      const { data, error } = await supabase.from("academic_batches").upsert(
        batches.map(b => ({ ...b, session_id: sessionId })),
        { onConflict: "session_id,admission_year" }
      ).select();
      if (error) throw error;
      return data as AcademicBatch[];
    },
    deleteBatch: async (id: string) => {
      const { error } = await supabase.from("academic_batches").delete().eq("id", id);
      if (error) throw error;
      return id;
    },
  },

  marketing: {
    trackDownload: async (userAgent: string) => {
      const { error } = await supabase.from("app_downloads").insert([{ user_agent: userAgent }]);
      if (error) console.error("Failed to track download:", error);
    },
    getDownloadCount: async () => {
      const { data, error } = await supabase.rpc("get_total_app_downloads");
      if (error) {
        console.error("Failed to get total downloads:", error);
        return 0;
      }
      return data as number;
    },
  },

  testimonials: {
    listAdmin: async () => {
      const { data, error } = await supabase.from("testimonials").select("*").order("created_at", { ascending: false });
      if (error) throw error;
      return data;
    },
    listPublic: async () => {
      const { data, error } = await supabase.from("testimonials").select("*").eq("is_published", true).order("created_at", { ascending: false });
      if (error) throw error;
      return data;
    },
    create: async (payload: { author_name: string; author_role: string; content: string; rating: number; is_published: boolean }) => {
      const { data, error } = await supabase.from("testimonials").insert([payload]).select().single();
      if (error) throw error;
      return data;
    },
    update: async (id: string, payload: Partial<{ author_name: string; author_role: string; content: string; rating: number; is_published: boolean }>) => {
      const { data, error } = await supabase.from("testimonials").update(payload).eq("id", id).select().single();
      if (error) throw error;
      return data;
    },
    delete: async (id: string) => {
      const { error } = await supabase.from("testimonials").delete().eq("id", id);
      if (error) throw error;
      return id;
    }
  },
};

export const marketingQueries = {
  downloads: () => queryOptions({ queryKey: ["marketing", "downloads"], queryFn: api.marketing.getDownloadCount }),
};

export const testimonialsQueries = {
  adminList: () => queryOptions({ queryKey: ["testimonials", "admin"], queryFn: api.testimonials.listAdmin }),
  publicList: () => queryOptions({ queryKey: ["testimonials", "public"], queryFn: api.testimonials.listPublic }),
};

export const sessionQueries = {
  list: () => queryOptions({ queryKey: ["sessions"], queryFn: api.sessions.list }),
  batches: (sessionId: string) => queryOptions({ queryKey: ["sessions", sessionId, "batches"], queryFn: () => api.sessions.listBatches(sessionId) }),
};

/* ------------------------------ query options ----------------------------- */

export const dashboardQueries = {
  stats: () => queryOptions({ queryKey: ["dashboard", "stats"], queryFn: api.dashboard.stats }),
  perDepartment: () =>
    queryOptions({
      queryKey: ["dashboard", "perDepartment"],
      queryFn: api.dashboard.studentsPerDepartment,
    }),
  attendance: () =>
    queryOptions({ queryKey: ["dashboard", "attendance"], queryFn: api.dashboard.attendance }),
  activities: () =>
    queryOptions({ queryKey: ["dashboard", "activities"], queryFn: api.dashboard.activities }),
  notifications: () =>
    queryOptions({
      queryKey: ["dashboard", "notifications"],
      queryFn: api.dashboard.notifications,
    }),
  classes: () =>
    queryOptions({ queryKey: ["dashboard", "classes"], queryFn: api.dashboard.todaysClasses }),
  events: () => queryOptions({ queryKey: ["dashboard", "events"], queryFn: api.dashboard.events }),
};

export const studentQueries = {
  list: () => queryOptions({ queryKey: ["students"], queryFn: api.students.list }),
};

export const facultyQueries = {
  list: () => queryOptions({ queryKey: ["faculty"], queryFn: api.faculty.list }),
};

export const departmentQueries = {
  list: () => queryOptions({ queryKey: ["departments"], queryFn: api.departments.list }),
};

export const timetableQueries = {
  list: (sectionKey: string) =>
    queryOptions({
      queryKey: ["timetable", sectionKey],
      queryFn: () => api.timetable.list(sectionKey),
    }),
  sections: () =>
    queryOptions({ queryKey: ["timetable-sections"], queryFn: api.timetable.sections }),
  periods: () => queryOptions({ queryKey: ["timetable-periods"], queryFn: api.timetable.periods }),
};

export const collegeQueries = {
  get: () => queryOptions({ queryKey: ["college"], queryFn: api.college.get }),
};

export const settingsQueries = {
  get: () => queryOptions({ queryKey: ["settings"], queryFn: api.settings.get }),
};

export const customTimetableQueries = {
  list: () => queryOptions({ queryKey: ["customTimetables"], queryFn: api.customTimetables.list }),
  detail: (id: string) => queryOptions({ queryKey: ["customTimetable", id], queryFn: () => api.customTimetables.get(id) }),
  periods: (id: string) => queryOptions({ queryKey: ["customTimetablePeriods", id], queryFn: () => api.customTimetables.getPeriods(id) }),
  members: (id: string) => queryOptions({ queryKey: ["customTimetableMembers", id], queryFn: () => api.customTimetables.getMembers(id) }),
  mappedSubjects: (id: string) => queryOptions({ queryKey: ["customTimetableSubjects", id], queryFn: () => api.customTimetables.getMappedSubjects(id) }),
};

export const assignmentQueries = {
  list: () => queryOptions({ queryKey: ["assignments"], queryFn: api.assignments.list }),
};

export const examQueries = {
  list: () => queryOptions({ queryKey: ["exams"], queryFn: api.exams.list }),
};

export const curriculumQueries = {
  listRegulations: () => queryOptions({ queryKey: ["regulations"], queryFn: api.curriculum.listRegulations }),
  regulationDetails: (id: string) => queryOptions({ queryKey: ["regulation", id], queryFn: () => api.curriculum.getRegulationDetails(id) }),
};
