import { Link, useRouterState } from "@tanstack/react-router";
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
      { title: "Students", url: "/students", icon: Users },
      { title: "Faculty", url: "/faculty", icon: GraduationCap },
      { title: "Admins", url: "/admins", icon: ShieldCheck },
    ],
  },
  {
    label: "Academics",
    items: [
      { title: "Departments", url: "/departments", icon: Building2 },
      { title: "Curriculum", url: "/curriculum", icon: BookOpen },
      { title: "Courses", url: "/courses", icon: BookOpen },
      { title: "Academic Sessions", url: "/sessions", icon: CalendarRange },
      { title: "Academic Years", url: "/academic-years", icon: CalendarRange },
      { title: "Semesters", url: "/semesters", icon: Layers },
      { title: "Sections", url: "/sections", icon: SquareStack },
      { title: "Subjects", url: "/subjects", icon: Library },
      { title: "Classrooms", url: "/classrooms", icon: Table2 },
    ],
  },
  {
    label: "Operations",
    items: [
      { title: "Timetable", url: "/timetable", icon: Clock },
      { title: "Attendance", url: "/attendance", icon: ClipboardList },
      { title: "Assignments", url: "/assignments", icon: FileStack },
      { title: "Resources", url: "/resources", icon: Library },
      { title: "Exam Schedule", url: "/exam-schedule", icon: ShieldCheck },
      { title: "Holiday Calendar", url: "/holidays", icon: CalendarDays },
    ],
  },
  {
    label: "App Updates",
    items: [
      { title: "Overview", url: "/updates", icon: LayoutDashboard },
      { title: "Releases", url: "/updates/releases", icon: Smartphone },
      { title: "Create Release", url: "/updates/create", icon: FileStack },
    ],
  },
  {
    label: "Campus Life",
    items: [
      { title: "Events", url: "/events", icon: PartyPopper },
      { title: "Clubs", url: "/clubs", icon: Users },
      { title: "Notifications", url: "/notifications", icon: Megaphone },
    ],
  },
  {
    label: "Account",
    items: [
      { title: "Profile", url: "/profile", icon: UserCog },
      { title: "Settings", url: "/settings", icon: Settings },
      { title: "Support Center", url: "/support", icon: HelpCircle },
    ],
  },
];

export function AppSidebar() {
  const { state } = useSidebar();
  const collapsed = state === "collapsed";
  const pathname = useRouterState({ select: (r) => r.location.pathname });

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
        {groups.map((group) => (
          <SidebarGroup key={group.label} className="py-1.5">
            {!collapsed && (
              <SidebarGroupLabel className="px-2 text-[11px] font-medium uppercase tracking-wider text-muted-foreground/70">
                {group.label}
              </SidebarGroupLabel>
            )}
            <SidebarGroupContent>
              <SidebarMenu>
                {group.items.map((item) => (
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
        ))}
      </SidebarContent>
    </Sidebar>
  );
}
