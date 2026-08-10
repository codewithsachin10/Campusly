import { zodResolver } from "@hookform/resolvers/zod";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { createFileRoute } from "@tanstack/react-router";
import { MoreHorizontal, Pencil, Plus, Trash2 } from "lucide-react";
import { useEffect, useState } from "react";
import { useForm } from "react-hook-form";
import { toast } from "sonner";
import { z } from "zod";
import { ConfirmDialog } from "@/components/confirm-dialog";
import { DataTable, type Column } from "@/components/data-table";
import { Form, SelectField, TextField } from "@/components/form-fields";
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
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select";
import { api, departmentQueries, facultyQueries } from "@/lib/services";
import type { Faculty } from "@/lib/types";

export const Route = createFileRoute("/_app/faculty")({
  head: () => ({
    meta: [
      { title: "Faculty — Campusly Admin" },
      {
        name: "description",
        content: "Manage teaching staff, designations, departments and assigned subjects.",
      },
      { property: "og:title", content: "Faculty — Campusly Admin" },
      {
        property: "og:description",
        content: "Manage teaching staff, designations, departments and assigned subjects.",
      },
    ],
  }),
  component: FacultyPage,
});

const facultySchema = z.object({
  facultyId: z.string().trim().min(2, "Faculty ID is required.").max(24),
  name: z.string().trim().min(2, "Name is required.").max(80),
  email: z.string().trim().email("Enter a valid email.").max(120),
  departmentId: z.string().min(1, "Select a department."),
  designation: z.string().min(1, "Select a designation."),
  phone: z.string().trim().max(20).optional().or(z.literal("")),
  subjectsText: z.string().trim().max(200).optional().default(""),
  status: z.enum(["active", "inactive"]),
});

type FacultyForm = z.input<typeof facultySchema>;

const designations = ["Professor", "Associate Professor", "Assistant Professor", "Lecturer"];

const emptyFaculty: FacultyForm = {
  facultyId: "",
  name: "",
  email: "",
  departmentId: "",
  designation: "Assistant Professor",
  phone: "",
  subjectsText: "",
  status: "active",
};

function FacultyPage() {
  const qc = useQueryClient();
  const facultyQuery = useQuery(facultyQueries.list());
  const departments = useQuery(departmentQueries.list());

  const [formOpen, setFormOpen] = useState(false);
  const [editing, setEditing] = useState<Faculty | null>(null);
  const [deleting, setDeleting] = useState<Faculty | null>(null);
  const [deptFilter, setDeptFilter] = useState("all");

  const form = useForm<FacultyForm>({
    resolver: zodResolver(facultySchema),
    defaultValues: emptyFaculty,
  });

  const nameValue = form.watch("name");

  useEffect(() => {
    if (!editing && formOpen && nameValue) {
      const cleanName = nameValue
        .toLowerCase()
        .replace(/^(dr|mr|mrs|ms)\.?\s*/g, "")
        .replace(/[^a-z0-9]/g, "");
      
      if (cleanName) {
        form.setValue("email", `${cleanName}@faculty.campusly.edu`, {
          shouldValidate: true,
        });
      }
    }
  }, [nameValue, editing, formOpen, form]);

  const invalidate = () => qc.invalidateQueries({ queryKey: ["faculty"] });

  const saveMutation = useMutation({
    mutationFn: async (values: FacultyForm) => {
      const { subjectsText, phone, ...rest } = facultySchema.parse(values);
      const payload = {
        ...rest,
        ...(phone ? { phone } : { phone: "+91 0000000000" }),
        subjects: subjectsText
          .split(",")
          .map((s) => s.trim())
          .filter(Boolean),
      };
      return editing ? api.faculty.update(editing.id, payload as any) : api.faculty.create(payload as any);
    },
    onSuccess: () => {
      invalidate();
      toast.success(editing ? "Faculty updated" : "Faculty added");
      setFormOpen(false);
      setEditing(null);
    },
    onError: (err: any) => {
      console.error(err);
      toast.error(`Could not save: ${err?.message || "Unknown error"}`);
    },
  });

  const deleteMutation = useMutation({
    mutationFn: (id: string) => api.faculty.remove(id),
    onSuccess: () => {
      invalidate();
      toast.success("Faculty removed");
      setDeleting(null);
    },
    onError: () => toast.error("Could not remove this faculty member."),
  });

  const deptName = (id: string) => departments.data?.find((d) => d.id === id)?.code ?? "—";
  const rows = (facultyQuery.data ?? []).filter(
    (f) => deptFilter === "all" || f.departmentId === deptFilter,
  );

  const openCreate = () => {
    setEditing(null);
    let nextId = "FAC001";
    if (facultyQuery.data && facultyQuery.data.length > 0) {
      const ids = facultyQuery.data.map((f) => parseInt(f.facultyId.replace(/\D/g, "")) || 0);
      const maxId = Math.max(...ids);
      nextId = `FAC${String(maxId + 1).padStart(3, "0")}`;
    }
    form.reset({ ...emptyFaculty, facultyId: nextId, departmentId: departments.data?.[0]?.id ?? "" });
    setFormOpen(true);
  };

  const openEdit = (f: Faculty) => {
    setEditing(f);
    form.reset({ ...f, subjectsText: f.subjects?.join(", ") || "" });
    setFormOpen(true);
  };

  const columns: Column<Faculty>[] = [
    {
      key: "name",
      header: "Faculty",
      cell: (f) => (
        <div className="flex items-center gap-3">
          <Avatar className="size-8">
            <AvatarFallback className="bg-primary/10 text-xs font-semibold text-primary">
              {f.name
                .replace("Dr. ", "")
                .split(" ")
                .map((p) => p[0])
                .slice(0, 2)
                .join("")}
            </AvatarFallback>
          </Avatar>
          <div className="min-w-0">
            <p className="truncate text-sm font-medium">{f.name}</p>
            <p className="truncate text-xs text-muted-foreground">{f.email}</p>
          </div>
        </div>
      ),
    },
    {
      key: "id",
      header: "Faculty ID",
      cell: (f) => <span className="text-sm tabular-nums">{f.facultyId}</span>,
    },
    {
      key: "dept",
      header: "Department",
      cell: (f) => <span className="text-sm">{deptName(f.departmentId)}</span>,
    },
    {
      key: "desig",
      header: "Designation",
      cell: (f) => <span className="text-sm">{f.designation}</span>,
    },
    {
      key: "subjects",
      header: "Subjects",
      cell: (f) => (
        <span className="text-sm text-muted-foreground">{f.subjects?.join(", ") || "—"}</span>
      ),
    },
    {
      key: "status",
      header: "Status",
      cell: (f) => (
        <Badge
          variant={f.status === "active" ? "secondary" : "outline"}
          className="rounded-md capitalize"
        >
          {f.status}
        </Badge>
      ),
    },
    {
      key: "actions",
      header: "",
      className: "w-12 text-right",
      cell: (f) => (
        <DropdownMenu>
          <DropdownMenuTrigger asChild>
            <Button variant="ghost" size="icon" className="size-8 rounded-lg">
              <MoreHorizontal className="size-4" />
            </Button>
          </DropdownMenuTrigger>
          <DropdownMenuContent align="end">
            <DropdownMenuItem onClick={() => openEdit(f)}>
              <Pencil className="mr-2 size-4" />
              Edit
            </DropdownMenuItem>
            <DropdownMenuItem
              className="text-destructive focus:text-destructive"
              onClick={() => setDeleting(f)}
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
        title="Faculty"
        description="Teaching staff, designations and subject allocations."
        crumbs={[{ label: "Faculty" }]}
        actions={
          <Button className="rounded-lg" onClick={openCreate}>
            <Plus className="size-4" />
            Add faculty
          </Button>
        }
      />

      <DataTable
        data={rows}
        columns={columns}
        rowKey={(f) => f.id}
        loading={facultyQuery.isLoading || departments.isLoading}
        error={facultyQuery.error}
        onRetry={() => facultyQuery.refetch()}
        searchPlaceholder="Search by name, ID or email"
        searchValue={(f) => `${f.name} ${f.facultyId} ${f.email}`}
        emptyTitle="No faculty yet"
        emptyDescription="Add teaching staff to assign them to subjects and timetables."
        emptyAction={
          <Button className="rounded-lg" onClick={openCreate}>
            <Plus className="size-4" />
            Add faculty
          </Button>
        }
        filters={
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
        }
      />

      <Dialog open={formOpen} onOpenChange={setFormOpen}>
        <DialogContent className="max-h-[88vh] overflow-y-auto rounded-2xl sm:max-w-2xl">
          <DialogHeader>
            <DialogTitle>{editing ? "Edit faculty" : "Add faculty"}</DialogTitle>
            <DialogDescription>
              Staff details are visible to students in the mobile app.
            </DialogDescription>
          </DialogHeader>
          <Form {...form}>
            <form
              id="faculty-form"
              onSubmit={form.handleSubmit((v) => saveMutation.mutate(v))}
              className="grid gap-4 sm:grid-cols-2"
            >
              <TextField
                control={form.control}
                name="name"
                label="Full name"
                placeholder="Dr. Meera Iyer"
              />
              <TextField
                control={form.control}
                name="email"
                label="Email"
                placeholder="meera@faculty.campusly.edu"
              />
              <TextField
                control={form.control}
                name="facultyId"
                label="Faculty ID"
                placeholder="FAC001"
              />
              <TextField
                control={form.control}
                name="phone"
                label="Phone (Optional)"
                placeholder="+91 80000 00000"
              />
              <SelectField
                control={form.control}
                name="departmentId"
                label="Department"
                options={(departments.data ?? []).map((d) => ({ value: d.id, label: d.name }))}
              />
              <SelectField
                control={form.control}
                name="designation"
                label="Designation"
                options={designations}
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
                  name="subjectsText"
                  label="Subjects"
                  placeholder="Data Structures, Algorithms"
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
              form="faculty-form"
              className="rounded-lg"
              disabled={saveMutation.isPending}
            >
              {editing ? "Save changes" : "Add faculty"}
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>

      <ConfirmDialog
        open={Boolean(deleting)}
        onOpenChange={(o) => !o && setDeleting(null)}
        title="Remove this faculty member?"
        description={
          <>
            This removes <strong>{deleting?.name}</strong> from timetables and subject allocations.
          </>
        }
        confirmLabel="Remove faculty"
        destructive
        onConfirm={() => deleting && deleteMutation.mutate(deleting.id)}
      />
    </>
  );
}
