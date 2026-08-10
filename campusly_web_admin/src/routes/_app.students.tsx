import { zodResolver } from "@hookform/resolvers/zod";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { createFileRoute } from "@tanstack/react-router";
import { Download, Eye, MoreHorizontal, Pencil, Plus, Trash2, Upload } from "lucide-react";
import { useRef, useState } from "react";
import { useForm } from "react-hook-form";
import { toast } from "sonner";
import { z } from "zod";
import { DataTable, type Column } from "@/components/data-table";
import { ConfirmDialog } from "@/components/confirm-dialog";
import { PageHeader } from "@/components/page-header";
import { Avatar, AvatarFallback } from "@/components/ui/avatar";
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
import { Form, SelectField, TextField } from "@/components/form-fields";
import { FormControl, FormField, FormItem, FormLabel, FormMessage } from "@/components/ui/form";
import { Input } from "@/components/ui/input";
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select";
import {
  Sheet,
  SheetContent,
  SheetDescription,
  SheetHeader,
  SheetTitle,
} from "@/components/ui/sheet";
import { api, departmentQueries, studentQueries } from "@/lib/services";
import type { Student } from "@/lib/types";

export const Route = createFileRoute("/_app/students")({
  head: () => ({
    meta: [
      { title: "Students — Campusly Admin" },
      {
        name: "description",
        content: "Manage student records, enrolment, sections and status across departments.",
      },
      { property: "og:title", content: "Students — Campusly Admin" },
      {
        property: "og:description",
        content: "Manage student records, enrolment, sections and status across departments.",
      },
    ],
  }),
  component: StudentsPage,
});

const studentSchema = z.object({
  studentId: z.string().trim().min(3, "Student ID is required.").max(24),
  rollNumber: z.string().trim().min(2, "Roll number is required.").max(24),
  name: z.string().trim().min(2, "Name is required.").max(80),
  email: z.string().trim().email("Enter a valid email.").max(120),
  phone: z.string().trim().min(6, "Phone is required.").max(20),
  departmentId: z.string().min(1, "Select a department."),
  courseId: z.string().min(1, "Select a course."),
  academicYear: z.string().min(1, "Select an academic year."),
  semester: z.coerce.number().int().min(1).max(8),
  section: z.string().trim().min(1, "Section is required.").max(4),
  address: z.string().trim().max(160).optional().default(""),
  guardian: z.string().trim().max(80).optional().default(""),
  status: z.enum(["active", "inactive"]),
});

type StudentForm = z.input<typeof studentSchema>;

const emptyStudent: StudentForm = {
  studentId: "",
  rollNumber: "",
  name: "",
  email: "",
  phone: "",
  departmentId: "",
  courseId: "B.Tech",
  academicYear: "2026-2027",
  semester: 1,
  section: "A",
  address: "",
  guardian: "",
  status: "active",
};

function StudentsPage() {
  const qc = useQueryClient();
  const students = useQuery(studentQueries.list());
  const departments = useQuery(departmentQueries.list());

  const [formOpen, setFormOpen] = useState(false);
  const [editing, setEditing] = useState<Student | null>(null);
  const [viewing, setViewing] = useState<Student | null>(null);
  const [deleting, setDeleting] = useState<Student | null>(null);
  const [deptFilter, setDeptFilter] = useState("all");
  const [statusFilter, setStatusFilter] = useState("all");
  const fileRef = useRef<HTMLInputElement>(null);

  const form = useForm<StudentForm>({
    resolver: zodResolver(studentSchema),
    defaultValues: emptyStudent,
  });

  const invalidate = () => qc.invalidateQueries({ queryKey: ["students"] });

  const saveMutation = useMutation({
    mutationFn: async (values: StudentForm) => {
      const parsed = studentSchema.parse(values);
      return editing
        ? api.students.update(editing.id, parsed)
        : api.students.create(parsed as Omit<Student, "id">);
    },
    onSuccess: () => {
      invalidate();
      toast.success(editing ? "Student updated" : "Student added");
      setFormOpen(false);
      setEditing(null);
    },
    onError: () => toast.error("Could not save this student."),
  });

  const deleteMutation = useMutation({
    mutationFn: (id: string) => api.students.remove(id),
    onSuccess: () => {
      invalidate();
      toast.success("Student deleted");
      setDeleting(null);
    },
    onError: () => toast.error("Could not delete this student."),
  });

  const deptName = (id: string) => departments.data?.find((d) => d.id === id)?.code ?? "—";

  const rows = (students.data ?? []).filter(
    (s) =>
      (deptFilter === "all" || s.departmentId === deptFilter) &&
      (statusFilter === "all" || s.status === statusFilter),
  );

  const openCreate = () => {
    setEditing(null);
    form.reset({ ...emptyStudent, departmentId: departments.data?.[0]?.id ?? "" });
    setFormOpen(true);
  };

  const openEdit = (student: Student) => {
    setEditing(student);
    form.reset({ ...student });
    setFormOpen(true);
  };

  const exportCsv = () => {
    const header = [
      "Student ID",
      "Roll Number",
      "Name",
      "Email",
      "Phone",
      "Department",
      "Course",
      "Year",
      "Semester",
      "Section",
      "Status",
    ];
    const body = rows.map((s) =>
      [
        s.studentId,
        s.rollNumber,
        s.name,
        s.email,
        s.phone,
        deptName(s.departmentId),
        s.courseId,
        s.academicYear,
        s.semester,
        s.section,
        s.status,
      ]
        .map((v) => `"${String(v).replace(/"/g, '""')}"`)
        .join(","),
    );
    const blob = new Blob([[header.join(","), ...body].join("\n")], { type: "text/csv" });
    const url = URL.createObjectURL(blob);
    const a = document.createElement("a");
    a.href = url;
    a.download = "campusly-students.csv";
    a.click();
    URL.revokeObjectURL(url);
    toast.success(`Exported ${rows.length} students`);
  };

  const columns: Column<Student>[] = [
    {
      key: "name",
      header: "Student",
      cell: (s) => (
        <div className="flex items-center gap-3">
          <Avatar className="size-8">
            <AvatarFallback className="bg-primary/10 text-xs font-semibold text-primary">
              {s.name
                .split(" ")
                .map((p) => p[0])
                .slice(0, 2)
                .join("")}
            </AvatarFallback>
          </Avatar>
          <div className="min-w-0">
            <p className="truncate text-sm font-medium">{s.name}</p>
            <p className="truncate text-xs text-muted-foreground">{s.email}</p>
          </div>
        </div>
      ),
    },
    {
      key: "roll",
      header: "Roll No.",
      cell: (s) => <span className="text-sm tabular-nums">{s.rollNumber}</span>,
    },
    {
      key: "dept",
      header: "Department",
      cell: (s) => <span className="text-sm">{deptName(s.departmentId)}</span>,
    },
    { key: "course", header: "Course", cell: (s) => <span className="text-sm">{s.courseId}</span> },
    {
      key: "class",
      header: "Sem / Section",
      cell: (s) => (
        <span className="text-sm tabular-nums">
          Sem {s.semester} • {s.section}
        </span>
      ),
    },
    {
      key: "status",
      header: "Status",
      cell: (s) => (
        <Badge
          variant={s.status === "active" ? "secondary" : "outline"}
          className="rounded-md capitalize"
        >
          {s.status}
        </Badge>
      ),
    },
    {
      key: "actions",
      header: "",
      className: "w-12 text-right",
      cell: (s) => (
        <DropdownMenu>
          <DropdownMenuTrigger asChild>
            <Button variant="ghost" size="icon" className="size-8 rounded-lg">
              <MoreHorizontal className="size-4" />
            </Button>
          </DropdownMenuTrigger>
          <DropdownMenuContent align="end">
            <DropdownMenuItem onClick={() => setViewing(s)}>
              <Eye className="mr-2 size-4" />
              View profile
            </DropdownMenuItem>
            <DropdownMenuItem onClick={() => openEdit(s)}>
              <Pencil className="mr-2 size-4" />
              Edit
            </DropdownMenuItem>
            <DropdownMenuItem
              className="text-destructive focus:text-destructive"
              onClick={() => setDeleting(s)}
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
        title="Students"
        description="Every enrolled student across departments, courses and sections."
        crumbs={[{ label: "Students" }]}
        actions={
          <>
            <input
              ref={fileRef}
              type="file"
              accept=".csv"
              className="hidden"
              onChange={(e) => {
                const file = e.target.files?.[0];
                if (file)
                  toast.success("CSV received", { description: `${file.name} queued for import.` });
                e.target.value = "";
              }}
            />
            <Button
              variant="outline"
              className="rounded-lg"
              onClick={() => fileRef.current?.click()}
            >
              <Upload className="size-4" />
              Import CSV
            </Button>
            <Button variant="outline" className="rounded-lg" onClick={exportCsv}>
              <Download className="size-4" />
              Export CSV
            </Button>
            <Button className="rounded-lg" onClick={openCreate}>
              <Plus className="size-4" />
              Add student
            </Button>
          </>
        }
      />

      <DataTable
        data={rows}
        columns={columns}
        rowKey={(s) => s.id}
        loading={students.isLoading || departments.isLoading}
        error={students.error}
        onRetry={() => students.refetch()}
        searchPlaceholder="Search by name, roll no. or email"
        searchValue={(s) => `${s.name} ${s.rollNumber} ${s.email} ${s.studentId}`}
        emptyTitle="No students yet"
        emptyDescription="Add your first student or import a CSV to get started."
        emptyAction={
          <Button className="rounded-lg" onClick={openCreate}>
            <Plus className="size-4" />
            Add student
          </Button>
        }
        filters={
          <>
            <Select value={deptFilter} onValueChange={setDeptFilter}>
              <SelectTrigger className="h-9 w-[190px] rounded-lg">
                <SelectValue placeholder="Department" />
              </SelectTrigger>
              <SelectContent>
                <SelectItem value="all">All departments</SelectItem>
                {departments.data?.map((d) => (
                  <SelectItem key={d.id} value={d.id}>
                    {d.code}
                  </SelectItem>
                ))}
              </SelectContent>
            </Select>
            <Select value={statusFilter} onValueChange={setStatusFilter}>
              <SelectTrigger className="h-9 w-[150px] rounded-lg">
                <SelectValue placeholder="Status" />
              </SelectTrigger>
              <SelectContent>
                <SelectItem value="all">All statuses</SelectItem>
                <SelectItem value="active">Active</SelectItem>
                <SelectItem value="inactive">Inactive</SelectItem>
              </SelectContent>
            </Select>
          </>
        }
      />

      <Dialog open={formOpen} onOpenChange={setFormOpen}>
        <DialogContent className="max-h-[88vh] overflow-y-auto rounded-2xl sm:max-w-2xl">
          <DialogHeader>
            <DialogTitle>{editing ? "Edit student" : "Add student"}</DialogTitle>
            <DialogDescription>
              Records sync to the student mobile app as soon as they're saved.
            </DialogDescription>
          </DialogHeader>
          <Form {...form}>
            <form
              id="student-form"
              onSubmit={form.handleSubmit((v) => saveMutation.mutate(v))}
              className="grid gap-4 sm:grid-cols-2"
            >
              <TextField
                control={form.control}
                name="name"
                label="Full name"
                placeholder="Aarav Sharma"
              />
              <TextField
                control={form.control}
                name="email"
                label="Email"
                placeholder="aarav@campusly.edu"
              />
              <TextField
                control={form.control}
                name="studentId"
                label="Student ID"
                placeholder="CMP260001"
              />
              <TextField
                control={form.control}
                name="rollNumber"
                label="Roll number"
                placeholder="CSE-101"
              />
              <TextField
                control={form.control}
                name="phone"
                label="Phone"
                placeholder="+91 90000 00000"
              />
              <FormField
                control={form.control}
                name="departmentId"
                render={({ field }) => (
                  <FormItem>
                    <FormLabel>Department</FormLabel>
                    <Select value={field.value} onValueChange={field.onChange}>
                      <FormControl>
                        <SelectTrigger className="h-10 rounded-lg">
                          <SelectValue placeholder="Select" />
                        </SelectTrigger>
                      </FormControl>
                      <SelectContent>
                        {departments.data?.map((d) => (
                          <SelectItem key={d.id} value={d.id}>
                            {d.name}
                          </SelectItem>
                        ))}
                      </SelectContent>
                    </Select>
                    <FormMessage />
                  </FormItem>
                )}
              />
              <SelectField
                control={form.control}
                name="courseId"
                label="Course"
                options={["B.Tech", "MBA", "MCA"]}
              />
              <SelectField
                control={form.control}
                name="academicYear"
                label="Academic year"
                options={["2026-2027", "2027-2028"]}
              />
              <SelectField
                control={form.control}
                name="semester"
                label="Semester"
                options={[1, 2, 3, 4, 5, 6, 7, 8]}
                numeric
              />
              <TextField control={form.control} name="section" label="Section" placeholder="A" />
              <TextField
                control={form.control}
                name="guardian"
                label="Guardian"
                placeholder="Parent / guardian name"
              />
              <SelectField
                control={form.control}
                name="status"
                label="Status"
                options={["active", "inactive"]}
              />
              <div className="sm:col-span-2">
                <TextField
                  control={form.control}
                  name="address"
                  label="Address"
                  placeholder="Residential address"
                />
              </div>
            </form>
          </Form>
          <DialogFooter>
            <Button variant="outline" className="rounded-lg" onClick={() => setFormOpen(false)}>
              Cancel
            </Button>
            <Button
              type="submit"
              form="student-form"
              className="rounded-lg"
              disabled={saveMutation.isPending}
            >
              {editing ? "Save changes" : "Add student"}
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>

      <Sheet open={Boolean(viewing)} onOpenChange={(o) => !o && setViewing(null)}>
        <SheetContent className="w-full sm:max-w-md">
          <SheetHeader>
            <SheetTitle>{viewing?.name}</SheetTitle>
            <SheetDescription>{viewing?.email}</SheetDescription>
          </SheetHeader>
          {viewing && (
            <dl className="grid gap-4 px-4 pb-6 sm:grid-cols-2">
              {[
                ["Student ID", viewing.studentId],
                ["Roll number", viewing.rollNumber],
                ["Department", deptName(viewing.departmentId)],
                ["Course", viewing.courseId],
                ["Academic year", viewing.academicYear],
                ["Semester", `Sem ${viewing.semester}`],
                ["Section", viewing.section],
                ["Phone", viewing.phone],
                ["Guardian", viewing.guardian || "—"],
                ["Status", viewing.status],
              ].map(([k, v]) => (
                <div key={k as string} className="space-y-0.5">
                  <dt className="text-xs uppercase tracking-wide text-muted-foreground">{k}</dt>
                  <dd className="text-sm font-medium capitalize">{v}</dd>
                </div>
              ))}
              <div className="space-y-0.5 sm:col-span-2">
                <dt className="text-xs uppercase tracking-wide text-muted-foreground">Address</dt>
                <dd className="text-sm font-medium">{viewing.address || "—"}</dd>
              </div>
            </dl>
          )}
        </SheetContent>
      </Sheet>

      <ConfirmDialog
        open={Boolean(deleting)}
        onOpenChange={(o) => !o && setDeleting(null)}
        title="Delete this student?"
        description={
          <>
            This removes <strong>{deleting?.name}</strong> and their records from the college. This
            action can't be undone.
          </>
        }
        confirmLabel="Delete student"
        destructive
        onConfirm={() => deleting && deleteMutation.mutate(deleting.id)}
      />
    </>
  );
}
