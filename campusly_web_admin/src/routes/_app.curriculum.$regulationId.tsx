import { useSuspenseQuery } from "@tanstack/react-query";
import { createFileRoute, Link } from "@tanstack/react-router";
import { BookOpen, ChevronLeft, Layers } from "lucide-react";
import { PageHeader } from "@/components/page-header";
import { Button } from "@/components/ui/button";
import { Badge } from "@/components/ui/badge";
import { DataTable, type Column } from "@/components/data-table";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { curriculumQueries } from "@/lib/services";
import type { CurriculumSubject } from "@/lib/types";

export const Route = createFileRoute("/_app/curriculum/$regulationId")({
  head: () => ({
    meta: [
      { title: "Curriculum Details — Campusly Admin" },
    ],
  }),
  loader: ({ context, params }) => {
    context.queryClient.ensureQueryData(curriculumQueries.regulationDetails(params.regulationId));
  },
  component: CurriculumDetailsPage,
});

function getCategoryColor(category: string) {
  switch (category?.toUpperCase()) {
    case "PC": return "bg-blue-500/10 text-blue-600 border-blue-200 dark:bg-blue-500/20 dark:text-blue-400 dark:border-blue-500/30";
    case "PE": return "bg-indigo-500/10 text-indigo-600 border-indigo-200 dark:bg-indigo-500/20 dark:text-indigo-400 dark:border-indigo-500/30";
    case "BS": return "bg-purple-500/10 text-purple-600 border-purple-200 dark:bg-purple-500/20 dark:text-purple-400 dark:border-purple-500/30";
    case "ES": return "bg-orange-500/10 text-orange-600 border-orange-200 dark:bg-orange-500/20 dark:text-orange-400 dark:border-orange-500/30";
    case "HS": return "bg-emerald-500/10 text-emerald-600 border-emerald-200 dark:bg-emerald-500/20 dark:text-emerald-400 dark:border-emerald-500/30";
    case "OE": return "bg-cyan-500/10 text-cyan-600 border-cyan-200 dark:bg-cyan-500/20 dark:text-cyan-400 dark:border-cyan-500/30";
    case "MC": return "bg-rose-500/10 text-rose-600 border-rose-200 dark:bg-rose-500/20 dark:text-rose-400 dark:border-rose-500/30";
    case "EEC": return "bg-amber-500/10 text-amber-600 border-amber-200 dark:bg-amber-500/20 dark:text-amber-400 dark:border-amber-500/30";
    default: return "bg-gray-500/10 text-gray-600 border-gray-200 dark:bg-gray-500/20 dark:text-gray-400 dark:border-gray-500/30";
  }
}

function CurriculumDetailsPage() {
  const { regulationId } = Route.useParams();
  const { data: regulation } = useSuspenseQuery(curriculumQueries.regulationDetails(regulationId));

  const columns: Column<CurriculumSubject>[] = [
    {
      key: "subject_code",
      header: "Code",
      cell: (row) => <span className="font-semibold text-foreground/80">{row.subject_code}</span>,
    },
    {
      key: "name",
      header: "Subject Name",
      cell: (row) => <span className="font-medium">{row.name}</span>,
    },
    {
      key: "credits",
      header: "Credits",
      cell: (row) => (
        <span className="inline-flex items-center justify-center w-6 h-6 rounded-full bg-primary/10 text-primary text-xs font-semibold">
          {row.credits}
        </span>
      ),
    },
    {
      key: "course_type",
      header: "Type",
      cell: (row) => (
        <span className="text-muted-foreground text-sm flex items-center gap-1.5">
          {row.course_type?.toLowerCase().includes("lab") ? <Layers className="size-3" /> : <BookOpen className="size-3" />}
          {row.course_type}
        </span>
      ),
    },
    {
      key: "category",
      header: "Category",
      cell: (row) => (
        <Badge variant="outline" className={getCategoryColor(row.category)}>
          {row.category || "N/A"}
        </Badge>
      ),
    },
    {
      key: "l_t_p",
      header: "L-T-P",
      cell: (row) => <span className="text-sm font-medium tracking-wider">{row.l_t_p}</span>,
    },
  ];

  return (
    <div className="space-y-8 pb-12">
      <PageHeader
        title={regulation.name}
        description={`Regulation ${regulation.regulation_year} • Batch ${regulation.batch} • ${regulation.departments?.name || ""}`}
        crumbs={[
          { label: "Academics" },
          { label: "Curriculum", to: "/curriculum" },
          { label: "Details" },
        ]}
        actions={
          <Button variant="outline" asChild className="hover:bg-primary/5">
            <Link to="/curriculum">
              <ChevronLeft className="size-4 mr-2" /> Back to Regulations
            </Link>
          </Button>
        }
      />

      <div className="grid gap-6">
        {regulation.semesters.map((semester: any) => {
          const totalCredits = semester.curriculum_subjects?.reduce((sum: number, s: any) => sum + Number(s.credits || 0), 0) || 0;
          
          return (
            <Card key={semester.id} className="overflow-hidden border-muted/60 shadow-sm transition-all hover:shadow-md">
              <CardHeader className="bg-muted/30 border-b px-6 py-4 flex flex-row items-center justify-between">
                <CardTitle className="text-xl font-bold flex items-center gap-2">
                  <span className="bg-primary/10 text-primary w-8 h-8 rounded-lg flex items-center justify-center text-sm">
                    {semester.semester_number}
                  </span>
                  Semester {semester.semester_number}
                </CardTitle>
                <div className="flex items-center gap-3">
                  <Badge variant="secondary" className="px-3 py-1 text-sm font-medium">
                    {totalCredits} Total Credits
                  </Badge>
                  <Badge variant="outline" className="px-3 py-1 bg-background text-sm font-medium">
                    {semester.curriculum_subjects?.length || 0} Subjects
                  </Badge>
                </div>
              </CardHeader>
              <CardContent className="p-0">
                <DataTable
                  data={semester.curriculum_subjects || []}
                  columns={columns}
                  rowKey={(row) => row.id}
                />
              </CardContent>
            </Card>
          );
        })}
        
        {regulation.semesters.length === 0 && (
          <div className="text-center py-16 text-muted-foreground border-2 border-dashed rounded-xl bg-muted/10">
            <BookOpen className="size-12 mx-auto mb-4 text-muted-foreground/50" />
            <p className="text-lg font-medium">No semesters found</p>
            <p className="text-sm">This curriculum doesn't have any subjects yet.</p>
          </div>
        )}
      </div>
    </div>
  );
}
