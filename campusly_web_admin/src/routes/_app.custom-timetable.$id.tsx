import { zodResolver } from "@hookform/resolvers/zod";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { createFileRoute, useNavigate } from "@tanstack/react-router";
import { Save, Trash2, Download, Plus, ArrowLeft, Edit2 } from "lucide-react";
import { QRCodeSVG } from "qrcode.react";
import { useState, useRef, useEffect } from "react";
import { useForm } from "react-hook-form";
import { toast } from "sonner";
import { z } from "zod";
import { PageHeader } from "@/components/page-header";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { Form, TextField, SelectField } from "@/components/form-fields";
import {
  Dialog,
  DialogContent,
  DialogHeader,
  DialogTitle,
  DialogFooter,
  DialogDescription,
} from "@/components/ui/dialog";
import { api, customTimetableQueries, facultyQueries } from "@/lib/services";
import { supabase } from "@/lib/supabase";
import type { CustomTimetablePeriod, Weekday } from "@/lib/types";

export const Route = createFileRoute("/_app/custom-timetable/$id")({
  head: () => ({
    meta: [{ title: "Timetable Editor — Campusly Admin" }],
  }),
  component: CustomTimetableEditorPage,
});

function SubjectMappingCard({ timetableId, facultyOptions }: { timetableId: string, facultyOptions: any[] }) {
  const qc = useQueryClient();
  const query = useQuery(customTimetableQueries.mappedSubjects(timetableId));
  const addMutation = useMutation({
    mutationFn: (payload: any) => api.customTimetables.addMappedSubject(payload),
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ["customTimetableSubjects", timetableId] });
      setSubject("");
      setFaculty("");
    }
  });
  const removeMutation = useMutation({
    mutationFn: (id: string) => api.customTimetables.removeMappedSubject(id),
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ["customTimetableSubjects", timetableId] });
    }
  });

  const [subject, setSubject] = useState("");
  const [faculty, setFaculty] = useState("");

  return (
    <div className="rounded-xl border bg-card p-6 flex flex-col gap-4">
      <h3 className="font-semibold text-center">Subjects & Teachers</h3>
      <div className="space-y-2 max-h-[250px] overflow-y-auto">
        {query.data?.map((s: any, index: number) => (
          <div key={s.id || index} className="flex items-center justify-between p-2 rounded-lg bg-muted text-sm">
            <div className="truncate pr-2">
              <p className="font-medium truncate">{s.subject}</p>
              <p className="text-muted-foreground text-xs truncate">{s.faculty}</p>
            </div>
            <Button variant="ghost" size="icon" className="text-destructive h-8 w-8 shrink-0" onClick={() => removeMutation.mutate(s.id)}>
              <Trash2 className="size-4" />
            </Button>
          </div>
        ))}
        {query.data?.length === 0 && (
          <div className="text-sm text-center text-muted-foreground p-4">No subjects mapped yet.</div>
        )}
      </div>
      <div className="pt-4 border-t flex flex-col gap-2">
        <input className="flex h-9 w-full rounded-md border border-input bg-transparent px-3 py-1 text-sm shadow-sm" placeholder="Subject Name" value={subject} onChange={e => setSubject(e.target.value)} />
        <select className="flex h-9 w-full rounded-md border border-input bg-transparent px-3 py-1 text-sm shadow-sm capitalize" value={faculty} onChange={e => setFaculty(e.target.value)}>
          <option value="">Select Faculty...</option>
          {facultyOptions.map(f => (
             <option key={f.value} value={f.value}>{f.label}</option>
          ))}
        </select>
        <Button size="sm" onClick={() => addMutation.mutate({ timetable_id: timetableId, subject, faculty })} disabled={!subject || !faculty || addMutation.isPending}>Add Mapping</Button>
      </div>
    </div>
  );
}

const DAYS: Weekday[] = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"];

const periodSchema = z.object({
  start_time: z.string().trim().min(4, "Required (e.g. 09:00 AM)"),
  end_time: z.string().trim().min(4, "Required (e.g. 10:00 AM)"),
  subject: z.string().trim().min(2, "Subject is required.").max(60),
  faculty: z.string().trim().min(2, "Faculty is required.").max(60),
  room: z.string().trim().min(1, "Room is required.").max(20),
  color_label: z.string().optional(),
  color_hex: z.string().optional(),
});
type PeriodForm = z.input<typeof periodSchema>;

function CustomTimetableEditorPage() {
  const { id } = Route.useParams();
  const qc = useQueryClient();
  const navigate = useNavigate();

  const ttQuery = useQuery(customTimetableQueries.detail(id));
  const periodsQuery = useQuery(customTimetableQueries.periods(id));
  const facultyQuery = useQuery(facultyQueries.list());
  const mappedSubjectsQuery = useQuery(customTimetableQueries.mappedSubjects(id));

  const facultyOptions = (facultyQuery.data || []).map(f => ({
    value: f.name,
    label: f.name
  }));

  const mappedSubjectOptions = (mappedSubjectsQuery.data || []).map((s: any) => ({
    value: s.subject,
    label: s.subject
  }));

  const [draft, setDraft] = useState<CustomTimetablePeriod[]>([]);
  const [editDetailsOpen, setEditDetailsOpen] = useState(false);
  const [dirty, setDirty] = useState(false);
  const [editing, setEditing] = useState<{ period?: CustomTimetablePeriod; day: Weekday } | null>(null);
  
  const [diffs, setDiffs] = useState<any[]>([]);
  const [showConfirmModal, setShowConfirmModal] = useState(false);
  const membersQuery = useQuery(customTimetableQueries.members(id));
  const affectedCount = membersQuery.data?.length || 0;

  // Initialize draft when query loads
  useEffect(() => {
    if (periodsQuery.data && !dirty) {
      setDraft(periodsQuery.data);
    }
  }, [periodsQuery.data, dirty]);

  const tt = ttQuery.data;

  const saveMutation = useMutation({
    mutationFn: () => api.customTimetables.savePeriods(id, draft),
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ["customTimetablePeriods", id] });
      setDirty(false);
      toast.success("Timetable saved");
    },
    onError: () => toast.error("Could not save timetable"),
  });

  const computeDiffs = () => {
    const original = periodsQuery.data || [];
    const changes: any[] = [];
    
    // Check for modifications and cancellations
    for (const oldP of original) {
      const newP = draft.find(p => p.id === oldP.id);
      if (!newP) {
        changes.push({ period_id: oldP.id, type: 'CANCELLED', subject_name: oldP.subject, old_data: oldP, new_data: null });
      } else {
        if (oldP.room !== newP.room) {
          changes.push({ period_id: oldP.id, type: 'VENUE_CHANGED', subject_name: oldP.subject, old_data: oldP, new_data: newP });
        } else if (oldP.start_time !== newP.start_time || oldP.end_time !== newP.end_time) {
          changes.push({ period_id: oldP.id, type: 'TIME_CHANGED', subject_name: oldP.subject, old_data: oldP, new_data: newP });
        } else if (oldP.faculty !== newP.faculty) {
          changes.push({ period_id: oldP.id, type: 'FACULTY_CHANGED', subject_name: oldP.subject, old_data: oldP, new_data: newP });
        }
      }
    }
    return changes;
  };

  const handleSaveClick = () => {
    const changes = computeDiffs();
    if (changes.length > 0) {
      setDiffs(changes);
      setShowConfirmModal(true);
    } else {
      saveMutation.mutate();
    }
  };

  const handleConfirmSave = async (notify: boolean) => {
    saveMutation.mutate();
    setShowConfirmModal(false);

    if (notify) {
      for (const diff of diffs) {
        try {
          await supabase.functions.invoke('notify-class-change', {
            body: {
              timetable_id: id,
              period_id: diff.period_id,
              old_data: diff.old_data,
              new_data: diff.new_data,
              change_type: diff.type,
              subject_name: diff.subject_name
            }
          });
        } catch (e) {
          console.error('Failed to notify', e);
        }
      }
      toast.success("Notifications scheduled");
    }
  };

  const form = useForm<PeriodForm>({
    resolver: zodResolver(periodSchema),
    defaultValues: { start_time: "", end_time: "", subject: "", faculty: "", room: "", color_label: "Lecture", color_hex: "#3525CD" },
  });

  const subjectValue = form.watch("subject");
  useEffect(() => {
    const mapped = mappedSubjectsQuery.data?.find((s: any) => s.subject === subjectValue);
    if (mapped) {
      form.setValue("faculty", mapped.faculty);
    }
  }, [subjectValue, mappedSubjectsQuery.data, form]);

  const qrRef = useRef<SVGSVGElement>(null);

  const downloadQR = () => {
    if (!qrRef.current) return;
    const svgData = new XMLSerializer().serializeToString(qrRef.current);
    const canvas = document.createElement("canvas");
    const ctx = canvas.getContext("2d");
    const img = new Image();
    img.onload = () => {
      canvas.width = img.width;
      canvas.height = img.height;
      ctx?.drawImage(img, 0, 0);
      const pngFile = canvas.toDataURL("image/png");
      const a = document.createElement("a");
      a.download = `timetable-qr-${tt?.join_code}.png`;
      a.href = pngFile;
      a.click();
    };
    img.src = "data:image/svg+xml;base64," + btoa(svgData);
  };

  if (!tt) return <div className="p-8">Loading...</div>;

  return (
    <div className="space-y-6">
      <PageHeader
        title={tt.name}
        description={`Join Code: ${tt.join_code} • Status: ${tt.status}`}
        crumbs={[{ label: "Timetables", to: "/custom-timetables" }, { label: "Editor" }]}
        actions={
          <div className="flex gap-2">
            <Button variant="outline" onClick={() => setEditDetailsOpen(true)}>
              <Edit2 className="size-4 mr-2" /> Edit Details
            </Button>
            <Button variant="outline" onClick={() => navigate({ to: "/timetable", search: { tab: "custom" } })}>
              <ArrowLeft className="size-4 mr-2" /> Back
            </Button>
            <Button onClick={handleSaveClick} disabled={!dirty || saveMutation.isPending}>
              <Save className="size-4 mr-2" />
              {saveMutation.isPending ? "Saving..." : "Save Changes"}
            </Button>
          </div>
        }
      />

      <div className="grid lg:grid-cols-4 gap-6">
        <div className="lg:col-span-3 space-y-6">
          <div className="rounded-xl border bg-card overflow-x-auto p-4">
            <div className="min-w-[800px] flex gap-4">
              {DAYS.map((day) => {
                const dayPeriods = draft.filter((p) => p.day === day).sort((a, b) => a.start_time.localeCompare(b.start_time));
                return (
                  <div key={day} className="flex-1 space-y-4">
                    <div className="font-semibold text-center py-2 border-b">{day}</div>
                    <div className="space-y-2">
                      {dayPeriods.map((p) => (
                        <div key={p.id} className="relative group rounded-lg border p-3 bg-background hover:border-primary/50 cursor-pointer" onClick={() => {
                          setEditing({ day, period: p });
                          form.reset({ start_time: p.start_time, end_time: p.end_time, subject: p.subject, faculty: p.faculty, room: p.room, color_label: p.color_label || "Lecture" });
                        }}>
                          <div className="text-xs font-mono text-muted-foreground mb-1">{p.start_time} - {p.end_time}</div>
                          <div className="font-medium text-sm truncate">{p.subject}</div>
                          <div className="text-xs text-muted-foreground truncate">{p.room} • {p.faculty}</div>
                          <div className="absolute top-2 right-2 flex gap-1 opacity-0 group-hover:opacity-100">
                            <button
                              type="button"
                              className="p-1 text-muted-foreground hover:bg-secondary rounded"
                              onClick={(e) => {
                                e.stopPropagation();
                                setEditing({ day, period: p });
                                const colorLabelFull = p.color_label || "Lecture|#3525CD";
                                const parts = colorLabelFull.split("|");
                                form.reset({ start_time: p.start_time, end_time: p.end_time, subject: p.subject, faculty: p.faculty, room: p.room, color_label: parts[0], color_hex: parts.length > 1 ? parts[1] : "#3525CD" });
                              }}
                            >
                              <Edit2 className="size-3" />
                            </button>
                            <button
                              type="button"
                              className="p-1 text-destructive hover:bg-destructive/10 rounded"
                              onClick={(e) => {
                                e.stopPropagation();
                                setDraft((d) => d.filter((item) => item.id !== p.id));
                                setDirty(true);
                              }}
                            >
                              <Trash2 className="size-3" />
                            </button>
                          </div>
                        </div>
                      ))}
                      <Button variant="outline" size="sm" className="w-full border-dashed" onClick={() => {
                        setEditing({ day });
                        form.reset({ start_time: "", end_time: "", subject: "", faculty: "", room: "", color_label: "Lecture", color_hex: "#3525CD" });
                      }}>
                        <Plus className="size-3 mr-2" /> Add
                      </Button>
                    </div>
                  </div>
                );
              })}
            </div>
          </div>
        </div>

        <div className="space-y-6">
          <SubjectMappingCard timetableId={id} facultyOptions={facultyOptions} />
          <div className="rounded-xl border bg-card p-6 flex flex-col items-center gap-4 text-center">
            <h3 className="font-semibold">Share Timetable</h3>
            <div className="bg-white p-4 rounded-xl shadow-sm">
              <QRCodeSVG 
                value={`campusly://timetable/join?code=${tt.join_code}`} 
                size={180} 
                ref={qrRef}
                includeMargin={true}
              />
            </div>
            <div className="text-2xl font-mono tracking-widest font-bold py-2 px-4 bg-muted rounded-lg">
              {tt.join_code}
            </div>
            <Button variant="secondary" className="w-full" onClick={downloadQR}>
              <Download className="size-4 mr-2" /> Download QR
            </Button>
          </div>
        </div>
      </div>

      <Dialog open={!!editing} onOpenChange={(o) => !o && setEditing(null)}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle>{editing?.period ? "Edit Period" : "Add Period"} - {editing?.day}</DialogTitle>
          </DialogHeader>
          <Form {...form}>
            <form
              onSubmit={form.handleSubmit((values) => {
                const parsed = periodSchema.parse(values);
                const finalColorLabel = `${parsed.color_label || "Lecture"}|${parsed.color_hex || "#3525CD"}`;
                const periodData = {
                  start_time: parsed.start_time,
                  end_time: parsed.end_time,
                  subject: parsed.subject,
                  faculty: parsed.faculty,
                  room: parsed.room,
                  color_label: finalColorLabel,
                };
                if (editing?.period) {
                  setDraft((d) => d.map((p) => p.id === editing.period!.id ? { ...p, ...periodData } : p));
                } else {
                  setDraft((d) => [...d, {
                    id: `temp_${Date.now()}`,
                    timetable_id: id,
                    day: editing!.day,
                    ...periodData
                  }]);
                }
                setDirty(true);
                setEditing(null);
              })}
              className="space-y-4"
            >
              <div className="grid grid-cols-2 gap-4">
                <TextField control={form.control} name="start_time" label="Start Time" type="time" placeholder="09:00 AM" />
                <TextField control={form.control} name="end_time" label="End Time" type="time" placeholder="10:00 AM" />
              </div>
              <div className="grid grid-cols-4 gap-4">
                <div className="col-span-2">
                  <SelectField control={form.control} name="subject" label="Subject" options={mappedSubjectOptions} />
                </div>
                <SelectField control={form.control} name="color_label" label="Type" options={[{label: "Lecture", value: "Lecture"}, {label: "Lab", value: "Lab"}, {label: "Tutorial", value: "Tutorial"}, {label: "Seminar", value: "Seminar"}, {label: "Custom", value: "Custom"}]} />
                <div className="flex flex-col gap-2 mt-[6px]">
                  <label className="text-sm font-medium leading-none peer-disabled:cursor-not-allowed peer-disabled:opacity-70">Color</label>
                  <input
                    type="color"
                    className="h-10 w-full rounded-md border border-input cursor-pointer p-1"
                    {...form.register("color_hex")}
                  />
                </div>
              </div>
              <div className="grid grid-cols-2 gap-4">
                <SelectField control={form.control} name="faculty" label="Faculty" options={facultyOptions} />
                <TextField control={form.control} name="room" label="Room" />
              </div>
              <Button type="submit" className="w-full">Save Period</Button>
            </form>
          </Form>
        </DialogContent>
      </Dialog>
      <Dialog open={showConfirmModal} onOpenChange={setShowConfirmModal}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle>Confirm Timetable Changes</DialogTitle>
            <DialogDescription>
              You have made changes that will affect <strong>{affectedCount} student{affectedCount !== 1 ? 's' : ''}</strong>.
            </DialogDescription>
          </DialogHeader>
          <div className="space-y-4 max-h-[300px] overflow-y-auto">
            {diffs.map((diff, i) => (
              <div key={i} className="p-3 border rounded-lg text-sm bg-muted/30">
                <div className="font-semibold">{diff.subject_name}</div>
                <div className="text-muted-foreground">{diff.type.replace('_', ' ')}</div>
                <div className="mt-1 flex gap-2">
                  {diff.old_data?.room && <span className="line-through opacity-70">{diff.old_data.room}</span>}
                  {diff.new_data?.room && <span>➔ {diff.new_data.room}</span>}
                </div>
              </div>
            ))}
          </div>
          <DialogFooter className="mt-4 flex sm:justify-between">
            <Button variant="ghost" onClick={() => setShowConfirmModal(false)}>Cancel</Button>
            <div className="flex gap-2">
              <Button variant="outline" onClick={() => handleConfirmSave(false)}>Save Without Notification</Button>
              <Button onClick={() => handleConfirmSave(true)}>Save & Notify</Button>
            </div>
          </DialogFooter>
        </DialogContent>
      </Dialog>
      <Dialog open={editDetailsOpen} onOpenChange={setEditDetailsOpen}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle>Edit Timetable Details</DialogTitle>
          </DialogHeader>
          <form
            onSubmit={(e) => {
              e.preventDefault();
              const fd = new FormData(e.currentTarget);
              api.customTimetables.update(id, {
                name: fd.get("name"),
                department: fd.get("department") || null,
                academic_year: fd.get("academic_year") || null,
                description: fd.get("description") || null,
              }).then(() => {
                qc.invalidateQueries({ queryKey: ["customTimetableDetail", id] });
                qc.invalidateQueries({ queryKey: ["customTimetables"] });
                setEditDetailsOpen(false);
                toast.success("Details updated");
              }).catch(() => toast.error("Failed to update"));
            }}
            className="space-y-4"
          >
            <div className="space-y-2">
              <label className="text-sm font-medium">Timetable Name</label>
              <input required name="name" defaultValue={tt.name} className="flex h-10 w-full rounded-md border border-input bg-transparent px-3 py-2 text-sm" />
            </div>
            <div className="grid grid-cols-2 gap-4">
              <div className="space-y-2">
                <label className="text-sm font-medium">Department (Optional)</label>
                <input name="department" defaultValue={tt.department || ""} placeholder="e.g. CSBS" className="flex h-10 w-full rounded-md border border-input bg-transparent px-3 py-2 text-sm" />
              </div>
              <div className="space-y-2">
                <label className="text-sm font-medium">Year (Optional)</label>
                <input name="academic_year" defaultValue={tt.academic_year || ""} placeholder="e.g. 3rd Year" className="flex h-10 w-full rounded-md border border-input bg-transparent px-3 py-2 text-sm" />
              </div>
            </div>
            <div className="space-y-2">
              <label className="text-sm font-medium">Description (Optional)</label>
              <input name="description" defaultValue={tt.description || ""} className="flex h-10 w-full rounded-md border border-input bg-transparent px-3 py-2 text-sm" />
            </div>
            <DialogFooter>
              <Button type="button" variant="outline" onClick={() => setEditDetailsOpen(false)}>Cancel</Button>
              <Button type="submit">Save Changes</Button>
            </DialogFooter>
          </form>
        </DialogContent>
      </Dialog>
    </div>
  );
}
