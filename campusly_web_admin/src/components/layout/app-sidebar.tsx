import { Link, useRouterState } from "@tanstack/react-router";
import { useAuth } from "@/lib/auth";
import {
  BookOpen,
  Building2,
  CalendarDays,
  CalendarRange,
  ClipboardList,
  Clock,
  FileStack,
  GraduationCap,
  HeartHandshake,
  HelpCircle,
  Layers,
  LayoutDashboard,
  Library,
  Megaphone,
  PartyPopper,
  Settings,
  ShieldCheck,
  SquareStack,
  Table2,
  UserCog,
  Users,
  Smartphone,
} from "lucide-react";
import {
  Sidebar,
  SidebarContent,
  SidebarGroup,
  SidebarGroupContent,
  SidebarGroupLabel,
  SidebarHeader,
  SidebarMenu,
  SidebarMenuButton,
  SidebarMenuItem,
  useSidebar,
} from "@/components/ui/sidebar";

const groups = [
  {
    label: "Overview",
    items: [{ title: "Dashboard", url: "/dashboard", icon: LayoutDashboard }],
  },
  {
    label: "People",
    items: [
      { title: "Students", url: "/students", icon: Users, permission: "view_students" },
      { title: "Faculty", url: "/faculty", icon: GraduationCap, permission: "view_students" },
      { title: "Admins", url: "/admins", icon: ShieldCheck, permission: "manage_admins" },
    ],
  },
  {
    label: "Academics",
    items: [
      { title: "Departments", url: "/departments", icon: Building2, permission: "view_curriculum" },
      { title: "Curriculum", url: "/curriculum", icon: BookOpen, permission: "view_curriculum" },
      { title: "Courses", url: "/courses", icon: BookOpen, permission: "view_curriculum" },
      { title: "Academic Sessions", url: "/sessions", icon: CalendarRange, permission: "view_curriculum" },
      { title: "Academic Years", url: "/academic-years", icon: CalendarRange, permission: "view_curriculum" },
      { title: "Semesters", url: "/semesters", icon: Layers, permission: "view_curriculum" },
      { title: "Sections", url: "/sections", icon: SquareStack, permission: "view_curriculum" },
      { title: "Subjects", url: "/subjects", icon: Library, permission: "view_curriculum" },
      { title: "Classrooms", url: "/classrooms", icon: Table2, permission: "view_curriculum" },
    ],
  },
  {
    label: "Operations",
    items: [
      { title: "Forms", url: "/forms", icon: FileStack, permission: "view_curriculum" },
      { title: "Timetable", url: "/timetable", icon: Clock, permission: "view_timetable" },
      { title: "Attendance", url: "/attendance", icon: ClipboardList, permission: "view_students" },
      { title: "Assignments", url: "/assignments", icon: FileStack, permission: "view_timetable" },
      { title: "Resources", url: "/resources", icon: Library, permission: "view_curriculum" },
      { title: "Exam Schedule", url: "/exam-schedule", icon: ShieldCheck, permission: "view_timetable" },
      { title: "Holiday Calendar", url: "/holidays", icon: CalendarDays, permission: "view_timetable" },
    ],
  },
  {
    label: "App Updates",
    items: [
      { title: "Overview", url: "/updates", icon: LayoutDashboard, permission: "manage_settings" },
      { title: "Releases", url: "/updates/releases", icon: Smartphone, permission: "manage_settings" },
      { title: "Create Release", url: "/updates/create", icon: FileStack, permission: "manage_settings" },
      { title: "Testimonials", url: "/testimonials", icon: HeartHandshake, permission: "manage_settings" },
    ],
  },
  {
    label: "Campus Life",
    items: [
      { title: "Events", url: "/events", icon: PartyPopper, permission: "manage_settings" },
      { title: "Clubs", url: "/clubs", icon: Users, permission: "manage_settings" },
      { title: "Notifications", url: "/notifications", icon: Megaphone, permission: "manage_settings" },
    ],
  },
  {
    label: "Account",
    items: [
      { title: "Profile", url: "/profile", icon: UserCog },
      { title: "Settings", url: "/settings", icon: Settings, permission: "manage_settings" },
      { title: "Support Center", url: "/support", icon: HelpCircle, permission: "view_tickets" },
    ],
  },
];

export function AppSidebar() {
  const { state } = useSidebar();
  const collapsed = state === "collapsed";
  const pathname = useRouterState({ select: (r) => r.location.pathname });
  const { can, admin } = useAuth();
  
  const isSuperAdmin = (admin?.roles as any)?.name === 'Super Admin';

  return (
    <Sidebar collapsible="icon" className="border-r">
      <SidebarHeader className="px-3 py-4">
        <Link to="/dashboard" className="flex items-center gap-2.5">
          <span className="flex size-9 shrink-0 items-center justify-center rounded-xl bg-primary text-primary-foreground">
            <GraduationCap className="size-5" />
          </span>
          {!collapsed && (
            <span className="flex flex-col leading-tight">
              <span className="text-[15px] font-semibold tracking-tight">Campusly</span>
              <span className="text-xs text-muted-foreground">Admin Console</span>
            </span>
          )}
        </Link>
      </SidebarHeader>

      <SidebarContent className="gap-0 px-2 pb-6">
        {groups.map((group) => {
          const visibleItems = group.items.filter((item) => {
            if (!item.permission) return true;
            if (isSuperAdmin) return true;
            return can(item.permission as any);
          });

          if (visibleItems.length === 0) return null;

          return (
            <SidebarGroup key={group.label} className="py-1.5">
              {!collapsed && (
                <SidebarGroupLabel className="px-2 text-[11px] font-medium uppercase tracking-wider text-muted-foreground/70">
                  {group.label}
                </SidebarGroupLabel>
              )}
              <SidebarGroupContent>
                <SidebarMenu>
                  {visibleItems.map((item) => (
                  <SidebarMenuItem key={item.url}>
                    <SidebarMenuButton
                      asChild
                      isActive={pathname === item.url}
                      tooltip={item.title}
                      className="h-9 rounded-lg"
                    >
                      <Link to={item.url}>
                        <item.icon className="size-4" />
                        <span>{item.title}</span>
                      </Link>
                    </SidebarMenuButton>
                  </SidebarMenuItem>
                  ))}
                </SidebarMenu>
              </SidebarGroupContent>
            </SidebarGroup>
          );
        })}
      </SidebarContent>
    </Sidebar>
  );
}
