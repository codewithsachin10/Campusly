import { useSuspenseQuery } from "@tanstack/react-query";
import { createFileRoute } from "@tanstack/react-router";
import {
  BookOpen,
  Building2,
  CalendarCheck,
  FileStack,
  GraduationCap,
  Megaphone,
  PartyPopper,
  Users,
} from "lucide-react";
import { motion } from "motion/react";
import { Bar, BarChart, CartesianGrid, Line, LineChart, XAxis, YAxis } from "recharts";
import { PageHeader } from "@/components/page-header";
import { StatCard } from "@/components/stat-card";
import { Badge } from "@/components/ui/badge";
import { ChartContainer, ChartTooltip, ChartTooltipContent } from "@/components/ui/chart";
import { dashboardQueries } from "@/lib/services";

export const Route = createFileRoute("/_app/dashboard")({
  head: () => ({
    meta: [
      { title: "Dashboard — Campusly Admin" },
      {
        name: "description",
        content: "Live college analytics: enrolment, attendance, classes and campus activity.",
      },
      { property: "og:title", content: "Dashboard — Campusly Admin" },
      {
        property: "og:description",
        content: "Live college analytics: enrolment, attendance, classes and campus activity.",
      },
    ],
  }),
  loader: ({ context }) => {
    context.queryClient.ensureQueryData(dashboardQueries.stats());
    context.queryClient.ensureQueryData(dashboardQueries.perDepartment());
  },
  component: DashboardPage,
});

function DashboardPage() {
  const { data: stats } = useSuspenseQuery(dashboardQueries.stats());
  const { data: perDept } = useSuspenseQuery(dashboardQueries.perDepartment());
  const { data: attendance } = useSuspenseQuery(dashboardQueries.attendance());
  const { data: activities } = useSuspenseQuery(dashboardQueries.activities());
  const { data: notifications } = useSuspenseQuery(dashboardQueries.notifications());
  const { data: classes } = useSuspenseQuery(dashboardQueries.classes());
  const { data: events } = useSuspenseQuery(dashboardQueries.events());

  const cards = [
    { label: "Total Students", value: stats.students, icon: Users },
    { label: "Total Faculty", value: stats.faculty, icon: GraduationCap },
    { label: "Departments", value: stats.departments, icon: Building2 },
    { label: "Subjects", value: stats.subjects, icon: BookOpen },
    { label: "Assignments", value: stats.assignments, icon: FileStack },
    { label: "Events", value: stats.events, icon: PartyPopper },
    { label: "Notifications", value: stats.notifications, icon: Megaphone },
    { label: "Upcoming Exams", value: stats.upcomingExams, icon: CalendarCheck },
  ];

  return (
    <>
      <PageHeader
        title="Dashboard"
        description="A live view of everything happening across your campus today."
        crumbs={[{ label: "Dashboard" }]}
      />

      <div className="grid gap-4 sm:grid-cols-2 xl:grid-cols-4">
        {cards.map((c, i) => (
          <StatCard key={c.label} index={i} label={c.label} value={c.value} icon={c.icon} />
        ))}
      </div>

      <div className="grid gap-4 lg:grid-cols-2">
        <Panel title="Students per Department" subtitle="Current enrolment split">
          <ChartContainer
            className="h-[280px] w-full"
            config={{ students: { label: "Students", color: "var(--chart-1)" } }}
          >
            <BarChart data={perDept} margin={{ left: -18, right: 8, top: 8 }}>
              <CartesianGrid vertical={false} strokeDasharray="4 4" stroke="var(--border)" />
              <XAxis dataKey="department" tickLine={false} axisLine={false} fontSize={12} />
              <YAxis tickLine={false} axisLine={false} fontSize={12} />
              <ChartTooltip content={<ChartTooltipContent />} />
              <Bar
                dataKey="students"
                fill="var(--color-students)"
                radius={[8, 8, 4, 4]}
                maxBarSize={44}
              />
            </BarChart>
          </ChartContainer>
        </Panel>

        <Panel title="Attendance Overview" subtitle="Average present vs absent, last 6 months">
          <ChartContainer
            className="h-[280px] w-full"
            config={{
              present: { label: "Present %", color: "var(--chart-3)" },
              absent: { label: "Absent %", color: "var(--chart-4)" },
            }}
          >
            <LineChart data={attendance} margin={{ left: -18, right: 8, top: 8 }}>
              <CartesianGrid vertical={false} strokeDasharray="4 4" stroke="var(--border)" />
              <XAxis dataKey="month" tickLine={false} axisLine={false} fontSize={12} />
              <YAxis tickLine={false} axisLine={false} fontSize={12} />
              <ChartTooltip content={<ChartTooltipContent />} />
              <Line dataKey="present" stroke="var(--color-present)" strokeWidth={2.5} dot={false} />
              <Line dataKey="absent" stroke="var(--color-absent)" strokeWidth={2.5} dot={false} />
            </LineChart>
          </ChartContainer>
        </Panel>
      </div>

      <div className="grid gap-4 lg:grid-cols-3">
        <Panel title="Recent Activity" subtitle="Across all modules">
          <ul className="space-y-4">
            {activities.map((a) => (
              <li key={a.id} className="flex gap-3">
                <span className="mt-1.5 size-1.5 shrink-0 rounded-full bg-primary" />
                <div className="space-y-0.5">
                  <p className="text-sm leading-snug">
                    <span className="font-medium">{a.actor}</span> {a.action}{" "}
                    <span className="font-medium">{a.target}</span>
                  </p>
                  <p className="text-xs text-muted-foreground">{a.at}</p>
                </div>
              </li>
            ))}
          </ul>
        </Panel>

        <Panel title="Today's Classes" subtitle="Live timetable feed">
          <ul className="space-y-3">
            {classes.map((c) => (
              <li key={c.id} className="rounded-xl border border-border/70 p-3">
                <div className="flex items-center justify-between gap-2">
                  <p className="text-sm font-medium">{c.subject}</p>
                  <span className="text-xs text-muted-foreground tabular-nums">{c.time}</span>
                </div>
                <p className="mt-1 text-xs text-muted-foreground">
                  {c.faculty} • {c.room} • {c.section}
                </p>
              </li>
            ))}
          </ul>
        </Panel>

        <div className="space-y-4">
          <Panel title="Latest Notifications">
            <ul className="space-y-3">
              {notifications.slice(0, 3).map((n) => (
                <li key={n.id} className="space-y-1">
                  <div className="flex items-center gap-2">
                    <p className="text-sm font-medium">{n.title}</p>
                    {n.priority === "high" && (
                      <Badge
                        variant="secondary"
                        className="h-5 rounded-md px-1.5 text-[10px] uppercase"
                      >
                        High
                      </Badge>
                    )}
                  </div>
                  <p className="text-xs text-muted-foreground">
                    {n.target} • {n.at}
                  </p>
                </li>
              ))}
            </ul>
          </Panel>

          <Panel title="Upcoming Events">
            <ul className="space-y-3">
              {events.map((e) => (
                <li key={e.id} className="flex items-center gap-3">
                  <span className="flex size-10 shrink-0 flex-col items-center justify-center rounded-xl bg-muted text-[11px] font-medium leading-none">
                    {e.date.split(" ")[0]}
                    <span className="mt-0.5 text-sm font-semibold">{e.date.split(" ")[1]}</span>
                  </span>
                  <div>
                    <p className="text-sm font-medium">{e.title}</p>
                    <p className="text-xs text-muted-foreground">{e.venue}</p>
                  </div>
                </li>
              ))}
            </ul>
          </Panel>
        </div>
      </div>
    </>
  );
}

function Panel({
  title,
  subtitle,
  children,
}: {
  title: string;
  subtitle?: string;
  children: React.ReactNode;
}) {
  return (
    <motion.section
      initial={{ opacity: 0, y: 10 }}
      animate={{ opacity: 1, y: 0 }}
      transition={{ duration: 0.4, ease: [0.22, 1, 0.36, 1] }}
      className="surface p-5 sm:p-6"
    >
      <header className="mb-5 space-y-0.5">
        <h2 className="text-base font-semibold tracking-tight">{title}</h2>
        {subtitle && <p className="text-xs text-muted-foreground">{subtitle}</p>}
      </header>
      {children}
    </motion.section>
  );
}
