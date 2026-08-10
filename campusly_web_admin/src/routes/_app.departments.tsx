import { zodResolver } from "@hookform/resolvers/zod";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { createFileRoute } from "@tanstack/react-router";
import { MoreHorizontal, Pencil, Plus, Trash2 } from "lucide-react";
import { useState } from "react";
import { useForm } from "react-hook-form";
import { toast } from "sonner";
import { z } from "zod";
import { ConfirmDialog } from "@/components/confirm-dialog";
import { DataTable, type Column } from "@/components/data-table";
import { Form, TextField } from "@/components/form-fields";
import { PageHeader } from "@/components/page-header";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogTitle,
} from "@/components/ui/dialog";
import {
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuItem,
  DropdownMenuTrigger,
} from "@/components/ui/dropdown-menu";
import { api, departmentQueries, studentQueries } from "@/lib/services";
import type { Department } from "@/lib/types";

export const Route = createFileRoute("/_app/departments")({
  head: () => ({
    meta: [
      { title: "Departments — Campusly Admin" },
      {
        name: "description",
        content: "Create and manage academic departments, codes and heads of department.",
      },
      { property: "og:title", content: "Departments — Campusly Admin" },
      {
        property: "og:description",
        content: "Create and manage academic departments, codes and heads of department.",
      },
    ],
  }),
  component: DepartmentsPage,
});

const departmentSchema = z.object({
  name: z.string().trim().min(2, "Department name is required.").max(80),
  code: z.string().trim().min(2, "Code is required.").max(10),
  description: z.string().trim().max(200).optional().default(""),
  headOfDepartment: z.string().trim().max(80).optional().default(""),
});

type DepartmentForm = z.input<typeof departmentSchema>;

const emptyDepartment: DepartmentForm = {
  name: "",
  code: "",
  description: "",
  headOfDepartment: "",
};

function DepartmentsPage() {
  const qc = useQueryClient();
  const departments = useQuery(departmentQueries.list());
  const students = useQuery(studentQueries.list());

  const [formOpen, setFormOpen] = useState(false);
  const [editing, setEditing] = useState<Department | null>(null);
  const [deleting, setDeleting] = useState<Department | null>(null);

  const form = useForm<DepartmentForm>({
    resolver: zodResolver(departmentSchema),
    defaultValues: emptyDepartment,
  });

  const invalidate = () => qc.invalidateQueries({ queryKey: ["departments"] });

  const saveMutation = useMutation({
    mutationFn: async (values: DepartmentForm) => {
      const parsed = departmentSchema.parse(values);
      return editing ? api.departments.update(editing.id, parsed) : api.departments.create(parsed);
    },
    onSuccess: () => {
      invalidate();
      toast.success(editing ? "Department updated" : "Department created");
      setFormOpen(false);
      setEditing(null);
    },
    onError: () => toast.error("Could not save this department."),
  });

  const deleteMutation = useMutation({
    mutationFn: (id: string) => api.departments.remove(id),
    onSuccess: () => {
      invalidate();
      toast.success("Department deleted");
      setDeleting(null);
    },
    onError: () => toast.error("Could not delete this department."),
  });

  const strength = (id: string) =>
    (students.data ?? []).filter((s) => s.departmentId === id).length;

  const openCreate = () => {
    setEditing(null);
    form.reset(emptyDepartment);
    setFormOpen(true);
  };

  const openEdit = (d: Department) => {
    setEditing(d);
    form.reset({ ...d });
    setFormOpen(true);
  };

  const columns: Column<Department>[] = [
    {
      key: "name",
      header: "Department",
      cell: (d) => (
        <div className="min-w-0">
          <p className="truncate text-sm font-medium">{d.name}</p>
          <p className="truncate text-xs text-muted-foreground">{d.description || "—"}</p>
        </div>
      ),
    },
    {
      key: "code",
      header: "Code",
      cell: (d) => (
        <Badge variant="secondary" className="rounded-md font-mono text-xs">
          {d.code}
        </Badge>
      ),
    },
    {
      key: "hod",
      header: "Head of Department",
      cell: (d) => <span className="text-sm">{d.headOfDepartment || "—"}</span>,
    },
    {
      key: "students",
      header: "Students",
      cell: (d) => <span className="text-sm tabular-nums">{strength(d.id)}</span>,
    },
    {
      key: "actions",
      header: "",
      className: "w-12 text-right",
      cell: (d) => (
        <DropdownMenu>
          <DropdownMenuTrigger asChild>
            <Button variant="ghost" size="icon" className="size-8 rounded-lg">
              <MoreHorizontal className="size-4" />
            </Button>
          </DropdownMenuTrigger>
          <DropdownMenuContent align="end">
            <DropdownMenuItem onClick={() => openEdit(d)}>
              <Pencil className="mr-2 size-4" />
              Edit
            </DropdownMenuItem>
            <DropdownMenuItem
              className="text-destructive focus:text-destructive"
              onClick={() => setDeleting(d)}
            >
              <Trash2 className="mr-2 size-4" />
              Delete
            </DropdownMenuItem>
          </DropdownMenuContent>
        </DropdownMenu>
      ),
    },
  ];

  return (
    <>
      <PageHeader
        title="Departments"
        description="The academic backbone every other module is organised around."
        crumbs={[{ label: "Departments" }]}
        actions={
          <Button className="rounded-lg" onClick={openCreate}>
            <Plus className="size-4" />
            Add department
          </Button>
        }
      />

      <DataTable
        data={departments.data}
        columns={columns}
        rowKey={(d) => d.id}
        loading={departments.isLoading}
        error={departments.error}
        onRetry={() => departments.refetch()}
        searchPlaceholder="Search departments"
        searchValue={(d) => `${d.name} ${d.code} ${d.headOfDepartment}`}
        emptyTitle="No departments yet"
        emptyDescription="Create your first department to start adding courses and subjects."
        emptyAction={
          <Button className="rounded-lg" onClick={openCreate}>
            <Plus className="size-4" />
            Add department
          </Button>
        }
      />

      <Dialog open={formOpen} onOpenChange={setFormOpen}>
        <DialogContent className="rounded-2xl sm:max-w-lg">
          <DialogHeader>
            <DialogTitle>{editing ? "Edit department" : "Add department"}</DialogTitle>
            <DialogDescription>
              Departments drive sections, subjects and timetables.
            </DialogDescription>
          </DialogHeader>
          <Form {...form}>
            <form
              id="department-form"
              onSubmit={form.handleSubmit((v) => saveMutation.mutate(v))}
              className="grid gap-4"
            >
              <TextField
                control={form.control}
                name="name"
                label="Department name"
                placeholder="Computer Science & Engineering"
              />
              <TextField
                control={form.control}
                name="code"
                label="Department code"
                placeholder="CSE"
              />
              <TextField
                control={form.control}
                name="headOfDepartment"
                label="Head of department"
                placeholder="Dr. Meera Iyer"
              />
              <TextField
                control={form.control}
                name="description"
                label="Description"
                placeholder="Short summary of the department"
                textarea
              />
            </form>
          </Form>
          <DialogFooter>
            <Button variant="outline" className="rounded-lg" onClick={() => setFormOpen(false)}>
              Cancel
            </Button>
            <Button
              type="submit"
              form="department-form"
              className="rounded-lg"
              disabled={saveMutation.isPending}
            >
              {editing ? "Save changes" : "Add department"}
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>

      <ConfirmDialog
        open={Boolean(deleting)}
        onOpenChange={(o) => !o && setDeleting(null)}
        title="Delete this department?"
        description={
          <>
            Deleting <strong>{deleting?.name}</strong> affects every linked section, subject and
            timetable entry.
          </>
        }
        confirmLabel="Delete department"
        destructive
        onConfirm={() => deleting && deleteMutation.mutate(deleting.id)}
      />
    </>
  );
}
