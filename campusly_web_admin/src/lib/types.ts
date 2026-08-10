// Domain model for Campusly Admin.
// These types mirror the intended Supabase SQL tables so the
// data layer can be swapped without touching any UI code.

export type Status = "active" | "inactive";

export type Role = "super_admin" | "admin" | "faculty" | "readonly_admin";

export type Permission = "view" | "create" | "edit" | "delete" | "export" | "import";

/** collection: admins */
export interface Admin {
  uid: string;
  name: string;
  email: string;
  photo?: string;
  role: Role;
  collegeId: string;
  permissions: Permission[];
  createdAt: string;
}

/** collection: students */
export interface Student {
  id: string;
  studentId: string;
  rollNumber: string;
  name: string;
  email: string;
  phone: string;
  departmentId: string;
  courseId: string;
  assignmentId?: string;
  examId?: string;
  academicYear: string;
  semester: number;
  section: string;
  photo?: string;
  address: string;
  guardian: string;
  status: Status;
}

/** collection: faculty */
export interface Faculty {
  id: string;
  facultyId: string;
  name: string;
  email: string;
  departmentId: string;
  designation: string;
  phone: string;
  photo?: string;
  subjects: string[];
  status: Status;
}

/** collection: departments */
export interface Department {
  id: string;
  name: string;
  code: string;
  description: string;
  headOfDepartment: string;
}

export interface DashboardStats {
  students: number;
  faculty: number;
  departments: number;
  subjects: number;
  assignments: number;
  events: number;
  notifications: number;
  upcomingExams: number;
}

export interface Activity {
  id: string;
  actor: string;
  action: string;
  target: string;
  at: string;
}

export interface ClassSlot {
  id: string;
  time: string;
  subject: string;
  faculty: string;
  room: string;
  section: string;
}

export interface NotificationItem {
  id: string;
  title: string;
  description: string;
  priority: "low" | "normal" | "high";
  target: string;
  at: string;
}

export type Weekday = "Monday" | "Tuesday" | "Wednesday" | "Thursday" | "Friday" | "Saturday";

/** collection: timetables/{sectionKey}/slots */
export interface TimetableSlot {
  id: string;
  sectionKey: string;
  day: Weekday;
  period: number;
  subject: string;
  faculty: string;
  room: string;
  type: "lecture" | "lab" | "tutorial";
}

export interface PeriodDefinition {
  index: number;
  label: string;
}

/** collection: colleges */
export interface College {
  id: string;
  name: string;
  shortName: string;
  email: string;
  phone: string;
  website: string;
  address: string;
  affiliation: string;
  established: string;
}

/** document: settings/{collegeId} */
export interface AppSettings {
  academicYear: string;
  weekStart: Weekday;
  periodsPerDay: number;
  emailNotifications: boolean;
  pushNotifications: boolean;
  weeklyDigest: boolean;
  twoFactor: boolean;
}

export interface CustomTimetable {
  id: string;
  name: string;
  description?: string;
  department?: string;
  academic_year?: string;
  semester?: string;
  section?: string;
  join_code: string;
  status: "draft" | "published" | "archived";
  created_at: string;
  updated_at: string;
}

export interface CustomTimetablePeriod {
  id: string;
  timetable_id: string;
  day: Weekday;
  start_time: string;
  end_time: string;
  subject: string;
  faculty: string;
  room: string;
  color_label?: string;
  notes?: string;
}

export interface Assignment {
  id: string;
  name: string;
  description: string;
  subjectId: string;
  headOfAssignment: string;
}

export interface Exam {
  id: string;
  name: string;
  subjectId: string;
  headOfExam: string;
  type: string;
}

export interface AcademicRegulation {
  id: string;
  department_id: string;
  name: string;
  regulation_year: number;
  batch: string;
  effective_academic_year: string;
  status: "draft" | "active" | "archived";
  created_at: string;
  updated_at: string;
}

export interface AcademicSemester {
  id: string;
  regulation_id: string;
  semester_number: number;
  created_at: string;
}

export interface CurriculumSubject {
  id: string;
  semester_id: string;
  subject_code: string;
  name: string;
  credits: number;
  course_type?: string;
  l_t_p?: string;
  theory_lab?: string;
  category?: string;
  created_at: string;
  updated_at: string;
}

export interface AcademicSession {
  id: string;
  name: string;
  is_active: boolean;
  start_date: string;
  end_date: string;
  created_at: string;
}

export interface AcademicBatch {
  id: string;
  session_id: string;
  admission_year: number;
  current_year: number;
  current_semester: number;
  promotion_date: string;
  created_at: string;
}
