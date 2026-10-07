import { zodResolver } from "@hookform/resolvers/zod";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { createFileRoute, useNavigate } from "@tanstack/react-router";
import { ArrowLeft, Save, Bell, MapPin, Clock, Calendar, Plus, Trash2, RotateCcw } from "lucide-react";
import { useState, useEffect } from "react";
import { useForm } from "react-hook-form";
import { toast } from "sonner";
import { z } from "zod";
import { PageHeader } from "@/components/page-header";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { api } from "@/lib/services";
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs";
import { format } from "date-fns";

export const Route = createFileRoute("/_app/exam-schedule/$id")({
  head: () => ({
    meta: [{ title: "Exam Timetable Editor — Campusly Admin" }],
  }),
  component: ExamScheduleEditorPage,
});

function ExamScheduleEditorPage() {
  const { id } = Route.useParams();
  const qc = useQueryClient();
  const navigate = useNavigate();

  const scheduleQuery = useQuery({
    queryKey: ["examScheduleDetail", id],
    queryFn: () => api.examSchedules.get(id),
  });

  const schedule = scheduleQuery.data;

  const papersQuery = useQuery({
    queryKey: ["examPapers", id],
    queryFn: () => api.examPapers.listBySchedule(id),
  });

  const subjectsQuery = useQuery({
    queryKey: ["scheduleSubjects", schedule?.department_id, schedule?.semester],
    queryFn: () => api.curriculum.getSubjectsForExamSchedule(schedule!.department_id, schedule!.semester),
    enabled: !!schedule?.department_id && !!schedule?.semester,
  });

  const [papers, setPapers] = useState<any[]>([]);
  const [isDirty, setIsDirty] = useState(false);

  useEffect(() => {
    if (papersQuery.data && !isDirty) {
      setPapers(papersQuery.data);
    }
  }, [papersQuery.data, isDirty]);

  const handleSave = () => {
    // Error handling validation
    if (papers.length === 0) {
      toast.error("Please add at least one paper.");
      return;
    }
    for (const p of papers) {
      if (!p.subject || !p.exam_date || !p.start_time || !p.end_time) {
        toast.error("Please fill all fields (Subject, Date, Start & End Time) for all papers.");
        return;
      }
      if (p.start_time >= p.end_time) {
        toast.error("End time must be after start time.");
        return;
      }
    }
    saveMutation.mutate();
  };

  const saveMutation = useMutation({
    mutationFn: () => api.examPapers.saveAll(id, papers),
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ["examPapers", id] });
      setIsDirty(false);
      // Removed toast to make autosave quiet, but we can keep a subtle indicator if needed.
    },
  });

  // Autosave effect
  useEffect(() => {
    if (!isDirty) return;
    
    // Check if papers are valid for autosave silently
    const isValid = papers.length > 0 && papers.every(p => 
      p.subject && p.exam_date && p.start_time && p.end_time && p.start_time < p.end_time
    );

    if (isValid) {
      const timeoutId = setTimeout(() => {
        saveMutation.mutate();
      }, 1500); // 1.5 second debounce
      return () => clearTimeout(timeoutId);
    }
  }, [papers, isDirty]);


  const statusMutation = useMutation({
    mutationFn: (newStatus: string) => api.examSchedules.update(id, { status: newStatus }),
    onSuccess: (_, newStatus) => {
      qc.invalidateQueries({ queryKey: ["examScheduleDetail", id] });
      qc.invalidateQueries({ queryKey: ["examSchedules"] });
      if (newStatus === "published" && schedule.status === "draft") {
        toast.success("Timetable published!");
      } else if (newStatus === "venues_published") {
        toast.success("Venues published!");
      } else if (newStatus === "draft") {
        toast.success("Reverted to draft.");
      } else if (newStatus === "published" && schedule.status === "venues_published") {
        toast.success("Venues unpublished.");
      }
    }
  });

  const addPaper = () => {
    setPapers([...papers, { id: `temp_${Date.now()}`, subject: "", exam_date: "", start_time: "09:00", end_time: "12:00", venue: "" }]);
    setIsDirty(true);
  };

  const removePaper = (pid: string) => {
    setPapers(papers.filter(p => p.id !== pid));
    setIsDirty(true);
  };

  const updatePaper = (pid: string, field: string, value: string) => {
    setPapers(papers.map(p => p.id === pid ? { ...p, [field]: value } : p));
    setIsDirty(true);
  };

  const handleSlotSelect = (pid: string, slot: string) => {
    setPapers(papers.map(p => {
      if (p.id === pid) {
        if (slot === "1") return { ...p, start_time: "09:00", end_time: "11:15" };
        if (slot === "2") return { ...p, start_time: "12:45", end_time: "15:00" };
      }
      return p;
    }));
    setIsDirty(true);
  };

  if (scheduleQuery.isLoading) return <div className="p-8">Loading...</div>;
  if (!schedule) return <div className="p-8 text-destructive">Schedule not found.</div>;

  return (
    <div className="space-y-6">
      <PageHeader
        title={schedule.name}
        description={`${schedule.academic_year} • Semester ${schedule.semester} • Type: ${schedule.exam_type}`}
        crumbs={[{ label: "Exam Schedules", to: "/exam-schedule" }, { label: "Editor" }]}
        actions={
          <div className="flex gap-2">
            {schedule.status === "draft" && (
              <Button variant="outline" className="text-emerald-600 border-emerald-200 bg-emerald-50 hover:bg-emerald-100" onClick={() => statusMutation.mutate("published")}>
                <Bell className="size-4 mr-2" /> Notify Timetable
              </Button>
            )}
            {schedule.status === "published" && (
              <Button variant="outline" className="text-indigo-600 border-indigo-200 bg-indigo-50 hover:bg-indigo-100" onClick={() => statusMutation.mutate("venues_published")}>
                <MapPin className="size-4 mr-2" /> Notify Venues
              </Button>
            )}
            <Button variant="default" onClick={handleSave} disabled={!isDirty || saveMutation.isPending}>
              <Save className="size-4 mr-2" /> {saveMutation.isPending ? "Autosaving..." : (isDirty ? "Unsaved Changes" : "Saved")}
            </Button>
            <Button variant="outline" onClick={() => navigate({ to: "/exam-schedule" })}>
              <ArrowLeft className="size-4 mr-2" /> Back
            </Button>
          </div>
        }
      />

      <Tabs defaultValue="timetable" className="space-y-6">
        <TabsList>
          <TabsTrigger value="timetable">
            <Calendar className="size-4 mr-2" /> Timetable Setup
          </TabsTrigger>
          <TabsTrigger value="venues">
            <MapPin className="size-4 mr-2" /> Venue Allocation
          </TabsTrigger>
        </TabsList>
        
        <TabsContent value="timetable" className="space-y-4">
          <div className="bg-white rounded-xl border shadow-sm p-6">
            <div className="flex justify-between items-center mb-6">
              <div>
                <h3 className="font-semibold text-lg">Exam Papers & Dates</h3>
                <p className="text-sm text-muted-foreground">Setup the subjects, dates, and times. Publish this early so students can prepare.</p>
              </div>
              <Button variant="secondary" onClick={addPaper}>
                <Plus className="size-4 mr-2" /> Add Paper
              </Button>
            </div>
            
            {papers.length === 0 ? (
              <div className="text-center p-12 border-2 border-dashed rounded-lg bg-muted/20">
                <p className="text-muted-foreground mb-4">No papers added yet.</p>
                <Button variant="outline" onClick={addPaper}>Add First Paper</Button>
              </div>
            ) : (
              <div className="space-y-4">
                {papers.map((p, idx) => (
                  <div key={p.id} className="flex flex-wrap md:flex-nowrap gap-4 items-end p-4 border rounded-lg bg-muted/10 relative group">
                    <div className="w-full md:w-1/3 space-y-1">
                      <label className="text-xs font-medium text-muted-foreground">Subject</label>
                      <select
                        className="flex h-9 w-full rounded-md border border-input bg-transparent px-3 py-1 text-sm shadow-sm transition-colors focus-visible:outline-none focus-visible:ring-1 focus-visible:ring-ring"
                        value={p.subject}
                        onChange={(e) => updatePaper(p.id, "subject", e.target.value)}
                      >
                        <option value="" disabled>Select Subject</option>
                        {(subjectsQuery.data || []).map((sub: any) => (
                          <option key={sub.id} value={sub.name}>{sub.name} ({sub.code})</option>
                        ))}
                      </select>
                    </div>
                    <div className="w-full md:w-1/4 space-y-1">
                      <label className="text-xs font-medium text-muted-foreground">Date</label>
                      <Input 
                        type="date" 
                        value={p.exam_date} 
                        onChange={(e) => updatePaper(p.id, "exam_date", e.target.value)} 
                      />
                    </div>
                    {schedule?.exam_type?.startsWith("CAT") && (
                      <div className="w-full md:w-32 space-y-1">
                        <label className="text-xs font-medium text-muted-foreground text-amber-600">Fast Fill Slot</label>
                        <select
                          className="flex h-9 w-full rounded-md border border-amber-200 bg-amber-50 px-3 py-1 text-sm shadow-sm transition-colors focus-visible:outline-none focus-visible:ring-1 focus-visible:ring-ring text-amber-900"
                          value=""
                          onChange={(e) => handleSlotSelect(p.id, e.target.value)}
                        >
                          <option value="" disabled>Select</option>
                          <option value="1">Slot I (9:00 - 11:15)</option>
                          <option value="2">Slot II (12:45 - 3:00)</option>
                        </select>
                      </div>
                    )}
                    <div className="w-full md:w-1/6 space-y-1">
                      <label className="text-xs font-medium text-muted-foreground">Start Time</label>
                      <Input 
                        type="time" 
                        value={p.start_time} 
                        onChange={(e) => updatePaper(p.id, "start_time", e.target.value)} 
                      />
                    </div>
                    <div className="w-full md:w-1/6 space-y-1">
                      <label className="text-xs font-medium text-muted-foreground">End Time</label>
                      <Input 
                        type="time" 
                        value={p.end_time} 
                        onChange={(e) => updatePaper(p.id, "end_time", e.target.value)} 
                      />
                    </div>
                    <Button variant="ghost" size="icon" className="text-destructive hover:bg-destructive/10 shrink-0" onClick={() => removePaper(p.id)}>
                      <Trash2 className="size-4" />
                    </Button>
                  </div>
                ))}
              </div>
            )}
          </div>
        </TabsContent>

        <TabsContent value="venues" className="space-y-4">
          <div className="bg-white rounded-xl border shadow-sm p-6">
            <div className="mb-6">
              <h3 className="font-semibold text-lg">Venue Allocations</h3>
              <p className="text-sm text-muted-foreground">Assign rooms/halls to each exam paper. You can do this a day before the exam.</p>
            </div>
            
            {papers.length === 0 ? (
              <div className="text-center p-8 text-muted-foreground">Please add papers in the Timetable tab first.</div>
            ) : (
              <div className="grid gap-4">
                {papers.map((p, idx) => (
                  <div key={p.id} className="flex items-center justify-between p-4 border rounded-lg">
                    <div>
                      <div className="font-semibold">{p.subject || "Unnamed Subject"}</div>
                      <div className="text-sm text-muted-foreground flex items-center gap-2 mt-1">
                        <Calendar className="size-3" /> {p.exam_date ? format(new Date(p.exam_date), "PP") : "No date"}
                        <Clock className="size-3 ml-2" /> {p.start_time} - {p.end_time}
                      </div>
                    </div>
                    <div className="w-64">
                      <label className="text-xs font-medium text-muted-foreground mb-1 block">Venue / Room</label>
                      <Input 
                        placeholder="e.g. Block A, Room 101" 
                        value={p.venue || ""} 
                        onChange={(e) => updatePaper(p.id, "venue", e.target.value)} 
                      />
                    </div>
                  </div>
                ))}
              </div>
            )}
          </div>
        </TabsContent>
      </Tabs>
    </div>
  );
}
