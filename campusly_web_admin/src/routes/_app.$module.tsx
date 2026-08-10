import { createFileRoute } from "@tanstack/react-router";
import { Construction } from "lucide-react";
import { PageHeader } from "@/components/page-header";
import { Button } from "@/components/ui/button";
import { Link } from "@tanstack/react-router";

export const Route = createFileRoute("/_app/$module")({
  head: () => ({
    meta: [
      { title: "Module — Campusly Admin" },
      { name: "description", content: "This Campusly Admin module is being rolled out next." },
      { property: "og:title", content: "Module — Campusly Admin" },
      {
        property: "og:description",
        content: "This Campusly Admin module is being rolled out next.",
      },
    ],
  }),
  component: ModulePlaceholder,
});

const titles: Record<string, string> = {
  courses: "Courses",
  "academic-years": "Academic Years",
  semesters: "Semesters",
  sections: "Sections",
  subjects: "Subjects",
  classrooms: "Classrooms",
  timetable: "Timetable",
  attendance: "Attendance",
  assignments: "Assignments",
  resources: "Resources",
  events: "Events",
  clubs: "Clubs",
  notifications: "Notifications",
  "exam-schedule": "Exam Schedule",
  holidays: "Holiday Calendar",
  profile: "Profile",
  settings: "Settings",
};

function ModulePlaceholder() {
  const { module } = Route.useParams();
  const title = titles[module] ?? "Module";

  return (
    <>
      <PageHeader
        title={title}
        description={`${title} is part of the full Campusly Admin rollout.`}
        crumbs={[{ label: title }]}
      />
      <div className="surface flex flex-col items-center gap-3 px-6 py-20 text-center">
        <div className="flex size-11 items-center justify-center rounded-xl bg-muted">
          <Construction className="size-5 text-muted-foreground" />
        </div>
        <div className="space-y-1">
          <p className="font-medium">{title} module coming next</p>
          <p className="max-w-sm text-sm text-muted-foreground">
            The shared table, form, dialog and data-layer components are already in place — this
            module plugs straight into them.
          </p>
        </div>
        <Button asChild variant="outline" className="mt-2 rounded-lg">
          <Link to="/dashboard">Back to dashboard</Link>
        </Button>
      </div>
    </>
  );
}
