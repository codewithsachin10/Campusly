import { zodResolver } from "@hookform/resolvers/zod";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { createFileRoute, useNavigate, Link } from "@tanstack/react-router";
import { Plus, MoreHorizontal, Pencil, Trash2, CalendarRange, Clock, Send } from "lucide-react";
import { useState, useEffect } from "react";
import { useForm } from "react-hook-form";
import { toast } from "sonner";
import { z } from "zod";
import type { Column } from "@/components/data-table";
import { DataTable } from "@/components/data-table";
import { ConfirmDialog } from "@/components/confirm-dialog";
import { Form, TextField, SelectField } from "@/components/form-fields";
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
import { api, departmentQueries } from "@/lib/services";

export const Route = createFileRoute("/_app/exam-schedule/")({
  head: () => ({
    meta: [
      { title: "Exam Schedules — Campusly Admin" },
    ],
  }),
  component: ExamSchedulesPage,
});

const schema = z.object({
  name: z.string().trim().min(2, "Name is required (e.g. 3rd Sem CAT-1)").max(80),
  department_id: z.string().trim().min(1, "Department is required"),
  academic_year: z.string().trim().min(1, "Year is required"),
  semester: z.string().min(1, "Semester is required"),
  exam_type: z.enum(["CAT-1", "CAT-2", "SEMESTER"]),
});

type FormInput = z.input<typeof schema>;

const emptyForm: FormInput = {
  name: "",
  department_id: "",
  academic_year: "",
  semester: "",
  exam_type: "CAT-1",
};

function ExamSchedulesPage() {
  const qc = useQueryClient();
  const navigate = useNavigate();

  const schedules = useQuery({
    queryKey: ["examSchedules"],
    queryFn: () => api.examSchedules.list(),
  });
  
  const departments = useQuery(departmentQueries.list());
  const deptOptions = (departments.data || []).map(d => ({ value: d.id, label: d.name }));

  const [formOpen, setFormOpen] = useState(false);
  const [editing, setEditing] = useState<any>(null);
  const [deleting, setDeleting] = useState<any>(null);

  const form = useForm<FormInput>({
    resolver: zodResolver(schema),
    defaultValues: emptyForm,
  });

  const selectedYear = form.watch("academic_year");

  const getSemesterOptions = (year: string) => {
    switch (year) {
      case "1st Year": return [{ value: "1", label: "Semester 1" }, { value: "2", label: "Semester 2" }];
      case "2nd Year": return [{ value: "3", label: "Semester 3" }, { value: "4", label: "Semester 4" }];
      case "3rd Year": return [{ value: "5", label: "Semester 5" }, { value: "6", label: "Semester 6" }];
      case "4th Year": return [{ value: "7", label: "Semester 7" }, { value: "8", label: "Semester 8" }];
      default: return [];
    }
  };

  const selectedDept = form.watch("department_id");
  const selectedExamType = form.watch("exam_type");
  const selectedSemester = form.watch("semester");

  useEffect(() => {
    // Only auto-generate if we are not editing an existing schedule
    if (!editing && selectedDept && selectedYear && selectedSemester && selectedExamType) {
      const deptName = departments.data?.find((d) => d.id === selectedDept)?.name || selectedDept;
      const shortDeptName = deptName.replace("B.Tech. ", "").trim();
      const generatedName = `${shortDeptName} - ${selectedYear} (Sem ${selectedSemester}) - ${selectedExamType}`;
      
      // We don't want to completely overwrite if the user already started typing a custom name,
      // but to keep it simple and match "automatically give me or suggest me", 
      // we can use form.setValue. We can optionally check if form.getFieldState("name").isDirty
      if (!form.getFieldState("name").isDirty) {
        form.setValue("name", generatedName, { shouldValidate: true });
      }
    }
  }, [selectedDept, selectedYear, selectedSemester, selectedExamType, departments.data, editing, form]);

  const saveMutation = useMutation({
    mutationFn: async (values: FormInput) => {
      const parsed = schema.parse(values);
      const payload = {
        ...parsed,
        semester: parseInt(parsed.semester),
      };
      return editing ? api.examSchedules.update(editing.id, payload) : api.examSchedules.create(payload);
    },
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ["examSchedules"] });
      toast.success(editing ? "Schedule updated" : "Schedule created");
      setFormOpen(false);
      setEditing(null);
    },
    onError: () => toast.error("Could not save schedule."),
  });

  const deleteMutation = useMutation({
    mutationFn: (id: string) => api.examSchedules.delete(id),
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ["examSchedules"] });
      toast.success("Schedule deleted");
      setDeleting(null);
    },
    onError: () => toast.error("Could not delete schedule."),
  });

  const openCreate = () => {
    setEditing(null);
    form.reset(emptyForm);
    setFormOpen(true);
  };

  const openEdit = (d: any) => {
    setEditing(d);
    form.reset({ ...d, semester: d.semester.toString() });
    setFormOpen(true);
  };

  const columns: Column<any>[] = [
    {
      key: "name",
      header: "Exam Schedule",
      cell: (d) => (
        <div className="min-w-0">
          <Link to={`/exam-schedule/${d.id}`} className="hover:underline font-medium text-sm text-primary">
            {d.name}
          </Link>
          <p className="truncate text-xs text-muted-foreground">
             {d.academic_year} • Semester {d.semester}
          </p>
        </div>
      ),
    },
    {
      key: "type",
      header: "Type",
      cell: (d) => (
        <Badge variant="outline" className="rounded-md font-mono text-xs">
          {d.exam_type}
        </Badge>
      ),
    },
    {
      key: "department",
      header: "Department",
      cell: (d) => {
        const dept = (departments.data || []).find(x => x.id === d.department_id);
        return <span className="text-sm">{dept?.name || d.department_id}</span>;
      }
    },
    {
      key: "status",
      header: "Status",
      cell: (d) => {
        if (d.status === 'published') return <Badge className="bg-emerald-500">Timetable Published</Badge>;
        if (d.status === 'venues_published') return <Badge className="bg-indigo-500">Venues Sent</Badge>;
        return <Badge variant="secondary">Draft</Badge>;
      }
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
            <DropdownMenuItem asChild>
              <Link to={`/exam-schedule/${d.id}`}>
                <CalendarRange className="mr-2 size-4" />
                Manage Timetable
              </Link>
            </DropdownMenuItem>
            <DropdownMenuItem onClick={() => openEdit(d)}>
              <Pencil className="mr-2 size-4" />
              Edit Settings
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
        title="Exam Schedules"
        description="Manage internal assessments (CAT-1, CAT-2) and semester exams efficiently."
        crumbs={[{ label: "Exam Schedule" }]}
        actions={
          <Button className="rounded-lg" onClick={openCreate}>
            <Plus className="size-4 mr-2" />
            Create Schedule
          </Button>
        }
      />

      <DataTable
        data={schedules.data}
        columns={columns}
        rowKey={(d) => d.id}
        loading={schedules.isLoading}
        error={schedules.error}
        onRetry={() => schedules.refetch()}
        searchPlaceholder="Search exams"
        searchValue={(d) => `${d.name} ${d.exam_type}`}
        emptyTitle="No exam schedules yet"
        emptyDescription="Create your first exam schedule to set up timetables and venues."
        emptyAction={
          <Button className="rounded-lg" onClick={openCreate}>
            <Plus className="size-4 mr-2" />
            Create Schedule
          </Button>
        }
      />

      <Dialog open={formOpen} onOpenChange={setFormOpen}>
        <DialogContent className="rounded-2xl sm:max-w-lg">
          <DialogHeader>
            <DialogTitle>{editing ? "Edit Schedule" : "Create Schedule"}</DialogTitle>
            <DialogDescription>
              Define the target batch for this exam schedule.
            </DialogDescription>
          </DialogHeader>
          <Form {...form}>
            <form
              id="schedule-form"
              onSubmit={form.handleSubmit((v) => saveMutation.mutate(v))}
              className="grid gap-4"
            >
              <TextField
                control={form.control}
                name="name"
                label="Schedule Name"
                placeholder="e.g. BTech 3rd Sem CAT-1"
              />
              <div className="grid grid-cols-2 gap-4">
                <SelectField
                  control={form.control}
                  name="department_id"
                  label="Department"
                  options={deptOptions}
                />
                <SelectField
                  control={form.control}
                  name="exam_type"
                  label="Exam Type"
                  options={[
                    { value: "CAT-1", label: "CAT-1 (Internal)" },
                    { value: "CAT-2", label: "CAT-2 (Internal)" },
                    { value: "SEMESTER", label: "Semester Exam" }
                  ]}
                />
              </div>
              <div className="grid grid-cols-2 gap-4">
                <SelectField
                  control={form.control}
                  name="academic_year"
                  label="Academic Year"
                  options={[
                    { value: "1st Year", label: "1st Year" },
                    { value: "2nd Year", label: "2nd Year" },
                    { value: "3rd Year", label: "3rd Year" },
                    { value: "4th Year", label: "4th Year" },
                  ]}
                />
                <SelectField
                  control={form.control}
                  name="semester"
                  label="Semester"
                  options={getSemesterOptions(selectedYear)}
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
              form="schedule-form"
              className="rounded-lg"
              disabled={saveMutation.isPending}
            >
              {editing ? "Save Changes" : "Create Schedule"}
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>

      <ConfirmDialog
        open={Boolean(deleting)}
        onOpenChange={(o) => !o && setDeleting(null)}
        title="Delete this schedule?"
        description={
          <>
            Deleting <strong>{deleting?.name}</strong> will also permanently delete all its timetables and venue allocations.
          </>
        }
        confirmLabel="Delete schedule"
        destructive
        onConfirm={() => deleting && deleteMutation.mutate(deleting.id)}
      />
    </>
  );
}
