import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { createFileRoute, Link, useNavigate } from "@tanstack/react-router";
import { Plus, Trash2, FileText, Upload, Eye } from "lucide-react";
import { toast } from "sonner";
import { DataTable, type Column } from "@/components/data-table";
import { PageHeader } from "@/components/page-header";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { api } from "@/lib/services";
import type { AcademicRegulation } from "@/lib/types";

export const Route = createFileRoute("/_app/curriculum/")({
  head: () => ({
    meta: [
      { title: "Academic Curriculum — Campusly Admin" },
      { name: "description", content: "Manage academic regulations and curriculums." },
    ],
  }),
  component: CurriculumPage,
});

function CurriculumPage() {
  const qc = useQueryClient();
  const navigate = useNavigate();
  
  const regulations = useQuery({
    queryKey: ["regulations"],
    queryFn: () => api.curriculum.listRegulations(),
  });

  const invalidate = () => qc.invalidateQueries({ queryKey: ["regulations"] });

  const deleteMutation = useMutation({
    mutationFn: (id: string) => api.curriculum.deleteRegulation(id),
    onSuccess: () => {
      invalidate();
      toast.success("Regulation deleted");
    },
    onError: () => toast.error("Could not delete regulation"),
  });

  const columns: Column<AcademicRegulation & { departments: { name: string } }>[] = [
    {
      key: "name",
      header: "Regulation Name",
      cell: (row) => (
        <div>
          <p className="font-medium text-foreground">{row.name}</p>
          <p className="text-xs text-muted-foreground">{row.departments?.name}</p>
        </div>
      ),
    },
    {
      key: "year",
      header: "Regulation Year",
      cell: (row) => <span>{row.regulation_year}</span>,
    },
    {
      key: "batch",
      header: "Batch",
      cell: (row) => <Badge variant="outline">{row.batch}</Badge>,
    },
    {
      key: "status",
      header: "Status",
      cell: (row) => {
        if (row.status === "active") return <Badge variant="default" className="bg-emerald-500">Active</Badge>;
        if (row.status === "archived") return <Badge variant="secondary">Archived</Badge>;
        return <Badge variant="outline" className="bg-amber-500 text-amber-600 border-amber-500">Draft</Badge>;
      },
    },
    {
      key: "actions",
      header: "Actions",
      cell: (row) => (
        <div className="flex items-center justify-end gap-2">
          <Button
            variant="ghost"
            size="sm"
            asChild
            className="hover:bg-primary/10 hover:text-primary"
          >
            <Link to={`/curriculum/${row.id}`}>
              <Eye className="size-4" />
            </Link>
          </Button>
          <Button
            variant="ghost"
            size="sm"
            onClick={() => {
              if (window.confirm("Are you sure you want to delete this regulation and all its subjects?")) {
                deleteMutation.mutate(row.id);
              }
            }}
            className="hover:bg-destructive/10 hover:text-destructive"
          >
            <Trash2 className="size-4" />
          </Button>
        </div>
      ),
    },
  ];

  return (
    <div className="space-y-6">
      <PageHeader 
        title="Academic Curriculum" 
        description="Manage official academic regulations and subjects."
        actions={
          <div className="flex items-center gap-2">
            <Button asChild variant="outline">
              <Link to="/curriculum/batch-import">
                <Upload className="size-4 mr-2" /> Batch Import
              </Link>
            </Button>
            <Button asChild>
              <Link to="/curriculum/import">
                <FileText className="size-4 mr-2" /> Single Import
              </Link>
            </Button>
          </div>
        }
      />

      <DataTable 
        data={regulations.data ?? []} 
        columns={columns as any} 
        rowKey={(row) => row.id} 
        loading={regulations.isLoading} 
      />
    </div>
  );
}
