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
import { api, assignmentQueries, studentQueries } from "@/lib/services";
import type { Assignment } from "@/lib/types";

export const Route = createFileRoute("/_app/assignments")({
  head: () => ({
    meta: [
      { title: "Assignments — Campusly Admin" },
      {
        name: "description",
        content: "Create and manage academic assignments, subjectIds and heads of assignment.",
      },
      { property: "og:title", content: "Assignments — Campusly Admin" },
      {
        property: "og:description",
        content: "Create and manage academic assignments, subjectIds and heads of assignment.",
      },
    ],
  }),
  component: AssignmentsPage,
});

const assignmentSchema = z.object({
  name: z.string().trim().min(2, "Assignment name is required.").max(80),
  subjectId: z.string().trim().min(2, "Code is required.").max(10),
  description: z.string().trim().max(200).optional().default(""),
  headOfAssignment: z.string().trim().max(80).optional().default(""),
});

type AssignmentForm = z.input<typeof assignmentSchema>;

const emptyAssignment: AssignmentForm = {
  name: "",
  subjectId: "",
  description: "",
  headOfAssignment: "",
};

function AssignmentsPage() {
  const qc = useQueryClient();
  const assignments = useQuery(assignmentQueries.list());
  const students = useQuery(studentQueries.list());

  const [formOpen, setFormOpen] = useState(false);
  const [editing, setEditing] = useState<Assignment | null>(null);
  const [deleting, setDeleting] = useState<Assignment | null>(null);

  const form = useForm<AssignmentForm>({
    resolver: zodResolver(assignmentSchema),
    defaultValues: emptyAssignment,
  });

  const invalidate = () => qc.invalidateQueries({ queryKey: ["assignments"] });

  const saveMutation = useMutation({
    mutationFn: async (values: AssignmentForm) => {
      const parsed = assignmentSchema.parse(values);
      return editing ? api.assignments.update(editing.id, parsed) : api.assignments.create(parsed);
    },
    onSuccess: () => {
      invalidate();
      toast.success(editing ? "Assignment updated" : "Assignment created");
      setFormOpen(false);
      setEditing(null);
    },
    onError: () => toast.error("Could not save this assignment."),
  });

  const deleteMutation = useMutation({
    mutationFn: (id: string) => api.assignments.remove(id),
    onSuccess: () => {
      invalidate();
      toast.success("Assignment deleted");
      setDeleting(null);
    },
    onError: () => toast.error("Could not delete this assignment."),
  });

  const strength = (id: string) =>
    (students.data ?? []).filter((s) => s.assignmentId === id).length;

  const openCreate = () => {
    setEditing(null);
    form.reset(emptyAssignment);
    setFormOpen(true);
  };

  const openEdit = (d: Assignment) => {
    setEditing(d);
    form.reset({ ...d });
    setFormOpen(true);
  };

  const columns: Column<Assignment>[] = [
    {
      key: "name",
      header: "Assignment",
      cell: (d) => (
        <div className="min-w-0">
          <p className="truncate text-sm font-medium">{d.name}</p>
          <p className="truncate text-xs text-muted-foreground">{d.description || "—"}</p>
        </div>
      ),
    },
    {
      key: "subjectId",
      header: "Code",
      cell: (d) => (
        <Badge variant="secondary" className="rounded-md font-mono text-xs">
          {d.subjectId}
        </Badge>
      ),
    },
    {
      key: "hod",
      header: "Head of Assignment",
      cell: (d) => <span className="text-sm">{d.headOfAssignment || "—"}</span>,
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
        title="Assignments"
        description="The academic backbone every other module is organised around."
        crumbs={[{ label: "Assignments" }]}
        actions={
          <Button className="rounded-lg" onClick={openCreate}>
            <Plus className="size-4" />
            Add assignment
          </Button>
        }
      />

      <DataTable
        data={assignments.data}
        columns={columns}
        rowKey={(d) => d.id}
        loading={assignments.isLoading}
        error={assignments.error}
        onRetry={() => assignments.refetch()}
        searchPlaceholder="Search assignments"
        searchValue={(d) => `${d.name} ${d.subjectId} ${d.headOfAssignment}`}
        emptyTitle="No assignments yet"
        emptyDescription="Create your first assignment to start adding courses and subjects."
        emptyAction={
          <Button className="rounded-lg" onClick={openCreate}>
            <Plus className="size-4" />
            Add assignment
          </Button>
        }
      />

      <Dialog open={formOpen} onOpenChange={setFormOpen}>
        <DialogContent className="rounded-2xl sm:max-w-lg">
          <DialogHeader>
            <DialogTitle>{editing ? "Edit assignment" : "Add assignment"}</DialogTitle>
            <DialogDescription>
              Assignments drive sections, subjects and timetables.
            </DialogDescription>
          </DialogHeader>
          <Form {...form}>
            <form
              id="assignment-form"
              onSubmit={form.handleSubmit((v) => saveMutation.mutate(v))}
              className="grid gap-4"
            >
              <TextField
                control={form.control}
                name="name"
                label="Assignment name"
                placeholder="Computer Science & Engineering"
              />
              <TextField
                control={form.control}
                name="subjectId"
                label="Assignment subjectId"
                placeholder="CSE"
              />
              <TextField
                control={form.control}
                name="headOfAssignment"
                label="Head of assignment"
                placeholder="Dr. Meera Iyer"
              />
              <TextField
                control={form.control}
                name="description"
                label="Description"
                placeholder="Short summary of the assignment"
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
              form="assignment-form"
              className="rounded-lg"
              disabled={saveMutation.isPending}
            >
              {editing ? "Save changes" : "Add assignment"}
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>

      <ConfirmDialog
        open={Boolean(deleting)}
        onOpenChange={(o) => !o && setDeleting(null)}
        title="Delete this assignment?"
        description={
          <>
            Deleting <strong>{deleting?.name}</strong> affects every linked section, subject and
            timetable entry.
          </>
        }
        confirmLabel="Delete assignment"
        destructive
        onConfirm={() => deleting && deleteMutation.mutate(deleting.id)}
      />
    </>
  );
}
