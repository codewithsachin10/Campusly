import { zodResolver } from "@hookform/resolvers/zod";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { createFileRoute } from "@tanstack/react-router";
import { CheckCircle2, Layers, MoreHorizontal, Pencil, Plus, Trash2 } from "lucide-react";
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
import { Checkbox } from "@/components/ui/checkbox";
import {
  FormControl,
  FormField,
  FormItem,
  FormLabel,
  FormDescription,
} from "@/components/ui/form";
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogHeader,
  DialogTitle,
} from "@/components/ui/dialog";
import {
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuItem,
  DropdownMenuTrigger,
} from "@/components/ui/dropdown-menu";
import { api, sessionQueries } from "@/lib/services";
import type { AcademicSession, AcademicBatch } from "@/lib/types";

export const Route = createFileRoute("/_app/sessions")({
  head: () => ({
    meta: [
      { title: "Academic Sessions — Campusly Admin" },
    ],
  }),
  component: SessionsPage,
});

const sessionSchema = z.object({
  name: z.string().trim().min(2, "Session name is required.").max(50),
  is_active: z.boolean().default(false),
  start_date: z.string().trim().min(1, "Start date is required."),
  end_date: z.string().trim().min(1, "End date is required."),
});

type SessionForm = z.input<typeof sessionSchema>;

const emptySession: SessionForm = {
  name: "",
  is_active: false,
  start_date: "",
  end_date: "",
};

function SessionsPage() {
  const qc = useQueryClient();
  const sessions = useQuery(sessionQueries.list());

  const [formOpen, setFormOpen] = useState(false);
  const [editing, setEditing] = useState<AcademicSession | null>(null);
  const [deleting, setDeleting] = useState<AcademicSession | null>(null);
  const [managingBatches, setManagingBatches] = useState<AcademicSession | null>(null);

  const form = useForm<SessionForm>({
    resolver: zodResolver(sessionSchema),
    defaultValues: emptySession,
  });

  const invalidate = () => qc.invalidateQueries({ queryKey: ["sessions"] });

  const saveMutation = useMutation({
    mutationFn: async (values: SessionForm) => {
      const parsed = sessionSchema.parse(values);
      return editing ? api.sessions.update(editing.id, parsed) : api.sessions.create(parsed);
    },
    onSuccess: () => {
      invalidate();
      toast.success(editing ? "Session updated" : "Session created");
      setFormOpen(false);
      setEditing(null);
    },
    onError: () => toast.error("Could not save this session."),
  });

  const deleteMutation = useMutation({
    mutationFn: (id: string) => api.sessions.delete(id),
    onSuccess: () => {
      invalidate();
      toast.success("Session deleted");
      setDeleting(null);
    },
    onError: () => toast.error("Could not delete this session."),
  });

  const openCreate = () => {
    setEditing(null);
    form.reset(emptySession);
    setFormOpen(true);
  };

  const openEdit = (s: AcademicSession) => {
    setEditing(s);
    form.reset({
      name: s.name,
      is_active: s.is_active,
      start_date: s.start_date || "",
      end_date: s.end_date || "",
    });
    setFormOpen(true);
  };

  const columns: Column<AcademicSession>[] = [
    {
      key: "name",
      header: "Session Name",
      cell: (s) => (
        <div className="flex items-center gap-2">
          <span className="font-semibold text-foreground/80">{s.name}</span>
          {s.is_active && (
            <Badge variant="default" className="bg-emerald-500 hover:bg-emerald-600">
              <CheckCircle2 className="mr-1 size-3" /> Active
            </Badge>
          )}
        </div>
      ),
    },
    {
      key: "dates",
      header: "Duration",
      cell: (s) => (
        <span className="text-sm tabular-nums text-muted-foreground">
          {s.start_date} to {s.end_date}
        </span>
      ),
    },
    {
      key: "actions",
      header: "",
      className: "w-48 text-right",
      cell: (s) => (
        <div className="flex items-center justify-end gap-2">
          <Button
            variant="outline"
            size="sm"
            onClick={() => setManagingBatches(s)}
            className="h-8 gap-1 rounded-lg"
          >
            <Layers className="size-3.5" />
            <span className="hidden sm:inline">Batches</span>
          </Button>
          <DropdownMenu>
            <DropdownMenuTrigger asChild>
              <Button variant="ghost" size="icon" className="size-8 rounded-lg">
                <MoreHorizontal className="size-4" />
              </Button>
            </DropdownMenuTrigger>
            <DropdownMenuContent align="end" className="w-36">
              <DropdownMenuItem onClick={() => openEdit(s)}>
                <Pencil className="mr-2 size-4" /> Edit
              </DropdownMenuItem>
              <DropdownMenuItem
                className="text-destructive focus:text-destructive"
                onClick={() => setDeleting(s)}
              >
                <Trash2 className="mr-2 size-4" /> Delete
              </DropdownMenuItem>
            </DropdownMenuContent>
          </DropdownMenu>
        </div>
      ),
    },
  ];

  return (
    <>
      <PageHeader
        title="Academic Sessions"
        description="Manage academic sessions, dates, and automatic batch progression mapping."
        crumbs={[{ label: "Sessions" }]}
        actions={
          <Button onClick={openCreate} className="gap-2 rounded-lg">
            <Plus className="size-4" />
            New Session
          </Button>
        }
      />

      <DataTable
        data={sessions.data}
        columns={columns}
        rowKey={(s) => s.id}
        loading={sessions.isLoading}
        error={sessions.error}
        onRetry={() => sessions.refetch()}
        searchPlaceholder="Search sessions"
        searchValue={(s) => s.name}
        emptyTitle="No sessions yet"
        emptyDescription="Create your first academic session to begin."
        emptyAction={
          <Button className="rounded-lg" onClick={openCreate}>
            <Plus className="size-4" />
            Add session
          </Button>
        }
      />

      <Dialog open={formOpen} onOpenChange={setFormOpen}>
        <DialogContent className="rounded-2xl sm:max-w-lg">
          <DialogHeader>
            <DialogTitle>{editing ? "Edit Session" : "New Session"}</DialogTitle>
            <DialogDescription>
              Configure the academic session details. Only one session can be active at a time.
            </DialogDescription>
          </DialogHeader>
          <Form {...form}>
            <form
              onSubmit={form.handleSubmit((v) => saveMutation.mutate(v))}
              className="grid gap-4"
            >
              <TextField
                control={form.control}
                name="name"
                label="Session Name"
                placeholder="e.g. 2026-2027 ODD"
              />
              <div className="grid grid-cols-2 gap-4">
                <TextField
                  control={form.control}
                  name="start_date"
                  label="Start Date"
                  type="date"
                />
                <TextField
                  control={form.control}
                  name="end_date"
                  label="End Date"
                  type="date"
                />
              </div>
              
              <FormField
                control={form.control}
                name="is_active"
                render={({ field }) => (
                  <FormItem className="flex flex-row items-start space-x-3 space-y-0 rounded-md border p-4">
                    <FormControl>
                      <Checkbox
                        checked={field.value}
                        onCheckedChange={field.onChange}
                      />
                    </FormControl>
                    <div className="space-y-1 leading-none">
                      <FormLabel>Set as Active Session</FormLabel>
                      <FormDescription>
                        This will automatically deactivate any currently active session.
                      </FormDescription>
                    </div>
                  </FormItem>
                )}
              />

              <div className="mt-4 flex justify-end gap-2">
                <Button type="button" variant="ghost" onClick={() => setFormOpen(false)} className="rounded-lg">
                  Cancel
                </Button>
                <Button type="submit" disabled={saveMutation.isPending} className="rounded-lg">
                  {saveMutation.isPending ? "Saving..." : "Save session"}
                </Button>
              </div>
            </form>
          </Form>
        </DialogContent>
      </Dialog>

      <ConfirmDialog
        open={!!deleting}
        onOpenChange={(open) => !open && setDeleting(null)}
        title="Delete Session"
        description={`Are you sure you want to delete "${deleting?.name}"? This will also remove all batch mappings for this session. This action cannot be undone.`}
        confirmText="Delete"
        destructive
        onConfirm={() => deleting && deleteMutation.mutate(deleting.id)}
        loading={deleteMutation.isPending}
      />

      {managingBatches && (
        <ManageBatchesDialog 
          session={managingBatches} 
          open={!!managingBatches} 
          onOpenChange={(open) => !open && setManagingBatches(null)} 
        />
      )}
    </>
  );
}

function ManageBatchesDialog({ 
  session, 
  open, 
  onOpenChange 
}: { 
  session: AcademicSession; 
  open: boolean; 
  onOpenChange: (open: boolean) => void;
}) {
  const qc = useQueryClient();
  const batchesQuery = useQuery(sessionQueries.batches(session.id));
  
  const saveMutation = useMutation({
    mutationFn: (values: Omit<AcademicBatch, "id" | "created_at">) => api.sessions.saveBatches(session.id, [values]),
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ["sessions", session.id, "batches"] });
      toast.success("Batch mapped successfully");
    },
    onError: () => toast.error("Could not save batch mapping."),
  });
  
  const deleteMutation = useMutation({
    mutationFn: (id: string) => api.sessions.deleteBatch(id),
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ["sessions", session.id, "batches"] });
      toast.success("Batch removed from session");
    },
    onError: () => toast.error("Could not remove batch."),
  });

  const [formValues, setFormValues] = useState({
    admission_year: new Date().getFullYear(),
    current_year: 1,
    current_semester: 1,
  });

  const handleSaveNew = () => {
    saveMutation.mutate({
      session_id: session.id,
      admission_year: formValues.admission_year,
      current_year: formValues.current_year,
      current_semester: formValues.current_semester,
      promotion_date: session.start_date,
    });
  };

  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent className="rounded-2xl sm:max-w-2xl">
        <DialogHeader>
          <DialogTitle>Batch Mapping: {session.name}</DialogTitle>
          <DialogDescription>
            Map admission years to their active semester for this session.
          </DialogDescription>
        </DialogHeader>

        <div className="space-y-4 py-2">
          {/* Add New Batch Row */}
          <div className="flex items-end gap-3 rounded-lg bg-muted/50 p-4 border">
            <div className="flex-1 space-y-1.5">
              <label className="text-xs font-medium">Admission Year (Batch)</label>
              <input 
                type="number" 
                className="flex h-10 w-full rounded-lg border border-input bg-background px-3 py-2 text-sm shadow-sm transition-colors focus-visible:outline-none focus-visible:ring-1 focus-visible:ring-ring"
                value={formValues.admission_year}
                onChange={e => setFormValues(v => ({ ...v, admission_year: parseInt(e.target.value) || 2024 }))}
              />
            </div>
            <div className="flex-1 space-y-1.5">
              <label className="text-xs font-medium">Current Year</label>
              <select
                className="flex h-10 w-full rounded-lg border border-input bg-background px-3 py-2 text-sm shadow-sm transition-colors focus-visible:outline-none focus-visible:ring-1 focus-visible:ring-ring"
                value={formValues.current_year}
                onChange={e => setFormValues(v => ({ ...v, current_year: parseInt(e.target.value) }))}
              >
                <option value={1}>1st Year</option>
                <option value={2}>2nd Year</option>
                <option value={3}>3rd Year</option>
                <option value={4}>4th Year</option>
              </select>
            </div>
            <div className="flex-1 space-y-1.5">
              <label className="text-xs font-medium">Active Semester</label>
              <select
                className="flex h-10 w-full rounded-lg border border-input bg-background px-3 py-2 text-sm shadow-sm transition-colors focus-visible:outline-none focus-visible:ring-1 focus-visible:ring-ring"
                value={formValues.current_semester}
                onChange={e => setFormValues(v => ({ ...v, current_semester: parseInt(e.target.value) }))}
              >
                {[1, 2, 3, 4, 5, 6, 7, 8].map(s => (
                  <option key={s} value={s}>Semester {s}</option>
                ))}
              </select>
            </div>
            <Button onClick={handleSaveNew} disabled={saveMutation.isPending} size="sm" className="h-10 rounded-lg">
              <Plus className="mr-1 size-4" /> Add
            </Button>
          </div>

          {/* List existing batches */}
          <div className="rounded-lg border overflow-hidden">
            <div className="grid grid-cols-4 items-center bg-muted p-3 text-xs font-medium text-muted-foreground">
              <div>Admission Year</div>
              <div>Current Year</div>
              <div>Active Semester</div>
              <div className="text-right">Actions</div>
            </div>
            <div className="divide-y max-h-[300px] overflow-y-auto">
              {batchesQuery.isLoading ? (
                <div className="p-4 text-center text-sm text-muted-foreground">Loading mappings...</div>
              ) : batchesQuery.data?.length === 0 ? (
                <div className="p-4 text-center text-sm text-muted-foreground">No batches mapped to this session yet.</div>
              ) : (
                batchesQuery.data?.map(batch => (
                  <div key={batch.id} className="grid grid-cols-4 items-center p-3 text-sm hover:bg-muted/50 transition-colors">
                    <div className="font-medium text-foreground">{batch.admission_year}</div>
                    <div>{batch.current_year}{['st', 'nd', 'rd', 'th'][Math.min((batch.current_year-1), 3)] || 'th'} Year</div>
                    <div>
                      <Badge variant="secondary" className="rounded-md">Semester {batch.current_semester}</Badge>
                    </div>
                    <div className="text-right">
                      <Button 
                        variant="ghost" 
                        size="icon" 
                        className="size-8 rounded-lg text-destructive hover:text-destructive hover:bg-destructive/10"
                        onClick={() => deleteMutation.mutate(batch.id)}
                        disabled={deleteMutation.isPending}
                      >
                        <Trash2 className="size-4" />
                      </Button>
                    </div>
                  </div>
                ))
              )}
            </div>
          </div>
        </div>
      </DialogContent>
    </Dialog>
  );
}
