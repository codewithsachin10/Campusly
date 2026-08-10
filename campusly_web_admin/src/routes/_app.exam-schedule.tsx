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
import { api, examQueries, studentQueries } from "@/lib/services";
import type { Exam } from "@/lib/types";

export const Route = createFileRoute("/_app/exam-schedule")({
  head: () => ({
    meta: [
      { title: "Exams — Campusly Admin" },
      {
        name: "type",
        content: "Create and manage academic exams, subjectIds and heads of exam.",
      },
      { property: "og:title", content: "Exams — Campusly Admin" },
      {
        property: "og:type",
        content: "Create and manage academic exams, subjectIds and heads of exam.",
      },
    ],
  }),
  component: ExamsPage,
});

const examSchema = z.object({
  name: z.string().trim().min(2, "Exam name is required.").max(80),
  subjectId: z.string().trim().min(2, "Code is required.").max(10),
  type: z.string().trim().max(200).optional().default(""),
  headOfExam: z.string().trim().max(80).optional().default(""),
});

type ExamForm = z.input<typeof examSchema>;

const emptyExam: ExamForm = {
  name: "",
  subjectId: "",
  type: "",
  headOfExam: "",
};

function ExamsPage() {
  const qc = useQueryClient();
  const exams = useQuery(examQueries.list());
  const students = useQuery(studentQueries.list());

  const [formOpen, setFormOpen] = useState(false);
  const [editing, setEditing] = useState<Exam | null>(null);
  const [deleting, setDeleting] = useState<Exam | null>(null);

  const form = useForm<ExamForm>({
    resolver: zodResolver(examSchema),
    defaultValues: emptyExam,
  });

  const invalidate = () => qc.invalidateQueries({ queryKey: ["exams"] });

  const saveMutation = useMutation({
    mutationFn: async (values: ExamForm) => {
      const parsed = examSchema.parse(values);
      return editing ? api.exams.update(editing.id, parsed) : api.exams.create(parsed);
    },
    onSuccess: () => {
      invalidate();
      toast.success(editing ? "Exam updated" : "Exam created");
      setFormOpen(false);
      setEditing(null);
    },
    onError: () => toast.error("Could not save this exam."),
  });

  const deleteMutation = useMutation({
    mutationFn: (id: string) => api.exams.remove(id),
    onSuccess: () => {
      invalidate();
      toast.success("Exam deleted");
      setDeleting(null);
    },
    onError: () => toast.error("Could not delete this exam."),
  });

  const strength = (id: string) =>
    (students.data ?? []).filter((s) => s.examId === id).length;

  const openCreate = () => {
    setEditing(null);
    form.reset(emptyExam);
    setFormOpen(true);
  };

  const openEdit = (d: Exam) => {
    setEditing(d);
    form.reset({ ...d });
    setFormOpen(true);
  };

  const columns: Column<Exam>[] = [
    {
      key: "name",
      header: "Exam",
      cell: (d) => (
        <div className="min-w-0">
          <p className="truncate text-sm font-medium">{d.name}</p>
          <p className="truncate text-xs text-muted-foreground">{d.type || "—"}</p>
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
      header: "Head of Exam",
      cell: (d) => <span className="text-sm">{d.headOfExam || "—"}</span>,
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
        title="Exams"
        description="The academic backbone every other module is organised around."
        crumbs={[{ label: "Exams" }]}
        actions={
          <Button className="rounded-lg" onClick={openCreate}>
            <Plus className="size-4" />
            Add exam
          </Button>
        }
      />

      <DataTable
        data={exams.data}
        columns={columns}
        rowKey={(d) => d.id}
        loading={exams.isLoading}
        error={exams.error}
        onRetry={() => exams.refetch()}
        searchPlaceholder="Search exams"
        searchValue={(d) => `${d.name} ${d.subjectId} ${d.headOfExam}`}
        emptyTitle="No exams yet"
        emptyDescription="Create your first exam to start adding courses and subjects."
        emptyAction={
          <Button className="rounded-lg" onClick={openCreate}>
            <Plus className="size-4" />
            Add exam
          </Button>
        }
      />

      <Dialog open={formOpen} onOpenChange={setFormOpen}>
        <DialogContent className="rounded-2xl sm:max-w-lg">
          <DialogHeader>
            <DialogTitle>{editing ? "Edit exam" : "Add exam"}</DialogTitle>
            <DialogDescription>
              Exams drive sections, subjects and timetables.
            </DialogDescription>
          </DialogHeader>
          <Form {...form}>
            <form
              id="exam-form"
              onSubmit={form.handleSubmit((v) => saveMutation.mutate(v))}
              className="grid gap-4"
            >
              <TextField
                control={form.control}
                name="name"
                label="Exam name"
                placeholder="Computer Science & Engineering"
              />
              <TextField
                control={form.control}
                name="subjectId"
                label="Exam subjectId"
                placeholder="CSE"
              />
              <TextField
                control={form.control}
                name="headOfExam"
                label="Head of exam"
                placeholder="Dr. Meera Iyer"
              />
              <TextField
                control={form.control}
                name="type"
                label="Description"
                placeholder="Short summary of the exam"
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
              form="exam-form"
              className="rounded-lg"
              disabled={saveMutation.isPending}
            >
              {editing ? "Save changes" : "Add exam"}
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>

      <ConfirmDialog
        open={Boolean(deleting)}
        onOpenChange={(o) => !o && setDeleting(null)}
        title="Delete this exam?"
        description={
          <>
            Deleting <strong>{deleting?.name}</strong> affects every linked section, subject and
            timetable entry.
          </>
        }
        confirmLabel="Delete exam"
        destructive
        onConfirm={() => deleting && deleteMutation.mutate(deleting.id)}
      />
    </>
  );
}
