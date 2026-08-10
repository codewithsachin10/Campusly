import { zodResolver } from "@hookform/resolvers/zod";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { createFileRoute } from "@tanstack/react-router";
import { Copy, Download, GripVertical, Loader2, Plus, RotateCcw, Save, Trash2 } from "lucide-react";
import { AnimatePresence, motion } from "motion/react";
import { useEffect, useMemo, useState } from "react";
import { useForm } from "react-hook-form";
import { toast } from "sonner";
import { z } from "zod";
import { Form, SelectField, TextField } from "@/components/form-fields";
import { PageHeader } from "@/components/page-header";
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs";
import { CustomTimetablesList } from "@/components/custom-timetables-list";
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
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select";
import { api, timetableQueries } from "@/lib/services";
import type { TimetableSlot, Weekday } from "@/lib/types";
import { cn } from "@/lib/utils";
import { supabase } from "@/lib/supabase";

export const Route = createFileRoute("/_app/timetable")({
  head: () => ({
    meta: [
      { title: "Timetable Editor — Campusly Admin" },
      {
        name: "description",
        content:
          "Build weekly class timetables by dragging periods, duplicating days and exporting a print-ready PDF.",
      },
      { property: "og:title", content: "Timetable Editor — Campusly Admin" },
      {
        property: "og:description",
        content:
          "Build weekly class timetables by dragging periods, duplicating days and exporting a print-ready PDF.",
      },
    ],
  }),
  component: TimetablePage,
});

const DAYS: Weekday[] = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"];

const slotSchema = z.object({
  subject: z.string().trim().min(2, "Subject is required.").max(60),
  faculty: z.string().trim().min(2, "Faculty is required.").max(60),
  room: z.string().trim().min(1, "Room is required.").max(20),
  type: z.enum(["lecture", "lab", "tutorial"]),
});
type SlotForm = z.input<typeof slotSchema>;

const typeStyles: Record<TimetableSlot["type"], string> = {
  lecture: "border-primary/25 bg-primary/8",
  lab: "border-emerald-500/30 bg-emerald-500/10",
  tutorial: "border-amber-500/30 bg-amber-500/10",
};

const newId = () => `tt_${Math.random().toString(36).slice(2, 9)}`;

function TimetablePage() {
  const qc = useQueryClient();
  const sectionsQuery = useQuery(timetableQueries.sections());
  const periodsQuery = useQuery(timetableQueries.periods());

  const [sectionKey, setSectionKey] = useState("CAMPUS-CSBS-B1");
  const slotsQuery = useQuery(timetableQueries.list(sectionKey));

  const [draft, setDraft] = useState<TimetableSlot[]>([]);
  const [dirty, setDirty] = useState(false);
  const [dragging, setDragging] = useState<string | null>(null);
  const [dragOver, setDragOver] = useState<string | null>(null);

  const [editing, setEditing] = useState<{
    slot?: TimetableSlot | undefined;
    day: Weekday;
    period: number;
  } | null>(null);
  const [duplicateOpen, setDuplicateOpen] = useState(false);
  const [dupFrom, setDupFrom] = useState<Weekday>("Monday");
  const [dupTo, setDupTo] = useState<Weekday>("Tuesday");

  const periods = periodsQuery.data ?? [];
  const sections = sectionsQuery.data ?? [];
  const sectionLabel = sections.find((s) => s.key === sectionKey)?.label ?? sectionKey;

  useEffect(() => {
    if (slotsQuery.data) {
      setDraft(slotsQuery.data);
      setDirty(false);
    }
  }, [slotsQuery.data]);

  const byCell = useMemo(() => {
    const map = new Map<string, TimetableSlot>();
    draft.forEach((s) => map.set(`${s.day}|${s.period}`, s));
    return map;
  }, [draft]);

  const form = useForm<SlotForm>({
    resolver: zodResolver(slotSchema),
    defaultValues: { subject: "", faculty: "", room: "", type: "lecture" },
  });

  const computeDiffs = () => {
    const original = slotsQuery.data || [];
    const changes: any[] = [];
    
    for (const oldP of original) {
      const newP = draft.find(p => p.day === oldP.day && p.period === oldP.period);
      if (newP) {
        if (oldP.room !== newP.room) {
          changes.push({ type: 'VENUE_CHANGED', subject_name: oldP.subject, old_data: oldP, new_data: newP });
        } else if (oldP.faculty !== newP.faculty) {
          changes.push({ type: 'FACULTY_CHANGED', subject_name: oldP.subject, old_data: oldP, new_data: newP });
        }
      }
    }
    return changes;
  };

  const save = useMutation({
    mutationFn: async () => {
      const changes = computeDiffs();
      await api.timetable.save(draft, sectionKey);
      
      for (const diff of changes) {
        let title = "🚨 Class Alert";
        let body = `Changes made to ${diff.subject_name}`;
        
        if (diff.type === 'VENUE_CHANGED') {
          title = "🚨 Class Venue Changed";
          body = `${diff.subject_name} (${sectionLabel}) has moved from ${diff.old_data.room} to ${diff.new_data.room}.`;
        } else if (diff.type === 'FACULTY_CHANGED') {
          title = "🚨 Faculty Changed";
          body = `${diff.subject_name} (${sectionLabel}) faculty changed to ${diff.new_data.faculty}.`;
        }

        try {
          await supabase.from('notifications').insert({
            title: title,
            body: body,
            priority: 'high',
            target: 'System Auto-Alert'
          });
        } catch (e) {
          console.error("Failed to broadcast change", e);
        }
      }
    },
    onSuccess: () => {
      setDirty(false);
      qc.invalidateQueries({ queryKey: ["timetable", sectionKey] });
      toast.success("Timetable published", { description: sectionLabel });
    },
    onError: () => toast.error("Could not save the timetable."),
  });

  function openCell(day: Weekday, period: number) {
    const slot = byCell.get(`${day}|${period}`);
    setEditing({ slot, day, period });
    form.reset(
      slot
        ? { subject: slot.subject, faculty: slot.faculty, room: slot.room, type: slot.type }
        : { subject: "", faculty: "", room: "", type: "lecture" },
    );
  }

  function submitSlot(values: SlotForm) {
    if (!editing) return;
    const parsed = slotSchema.parse(values);
    setDraft((prev) => {
      if (editing.slot) {
        return prev.map((s) => (s.id === editing.slot!.id ? { ...s, ...parsed } : s));
      }
      return [
        ...prev,
        { id: newId(), sectionKey, day: editing.day, period: editing.period, ...parsed },
      ];
    });
    setDirty(true);
    setEditing(null);
    toast.success(editing.slot ? "Class updated" : "Class added");
  }

  function removeSlot(id: string) {
    setDraft((prev) => prev.filter((s) => s.id !== id));
    setDirty(true);
    setEditing(null);
    toast.success("Class removed");
  }

  function duplicateSlot(slot: TimetableSlot) {
    const target = periods.find((p) => !byCell.has(`${slot.day}|${p.index}`));
    if (!target) {
      toast.error("No free period left on this day to duplicate into.");
      return;
    }
    setDraft((prev) => [...prev, { ...slot, id: newId(), period: target.index }]);
    setDirty(true);
    setEditing(null);
    toast.success(`Duplicated to period ${target.index}`);
  }

  function duplicateDay() {
    if (dupFrom === dupTo) {
      toast.error("Pick two different days.");
      return;
    }
    const source = draft.filter((s) => s.day === dupFrom);
    if (source.length === 0) {
      toast.error(`${dupFrom} has no classes to copy.`);
      return;
    }
    setDraft((prev) => [
      ...prev.filter((s) => s.day !== dupTo),
      ...source.map((s) => ({ ...s, id: newId(), day: dupTo })),
    ]);
    setDirty(true);
    setDuplicateOpen(false);
    toast.success(`${dupFrom} copied to ${dupTo}`, { description: `${source.length} classes` });
  }

  /* ------------------------------ drag & drop ----------------------------- */

  function onDrop(day: Weekday, period: number) {
    const id = dragging;
    setDragging(null);
    setDragOver(null);
    if (!id) return;
    const moving = draft.find((s) => s.id === id);
    if (!moving || (moving.day === day && moving.period === period)) return;
    const occupant = byCell.get(`${day}|${period}`);
    setDraft((prev) =>
      prev.map((s) => {
        if (s.id === moving.id) return { ...s, day, period };
        if (occupant && s.id === occupant.id)
          return { ...s, day: moving.day, period: moving.period };
        return s;
      }),
    );
    setDirty(true);
    toast.success(occupant ? "Classes swapped" : "Class moved");
  }

  /* -------------------------------- export -------------------------------- */

  async function exportPdf() {
    const [{ jsPDF }, autoTableMod] = await Promise.all([
      import("jspdf"),
      import("jspdf-autotable"),
    ]);
    const autoTable = autoTableMod.default;
    const doc = new jsPDF({ orientation: "landscape", unit: "pt", format: "a4" });

    doc.setFontSize(16);
    doc.text("Campusly Institute of Technology", 40, 40);
    doc.setFontSize(11);
    doc.text(`Weekly Timetable — ${sectionLabel}`, 40, 60);
    doc.setFontSize(9);
    doc.setTextColor(120);
    doc.text(`Generated ${new Date().toLocaleDateString()}`, 40, 76);

    const head = [["Period", ...DAYS]];
    const body = periods.map((p) => [
      `${p.index}\n${p.label}`,
      ...DAYS.map((day) => {
        const s = byCell.get(`${day}|${p.index}`);
        return s ? `${s.subject}\n${s.faculty}\n${s.room}` : "—";
      }),
    ]);

    autoTable(doc, {
      head,
      body,
      startY: 92,
      styles: {
        fontSize: 8,
        cellPadding: 6,
        valign: "middle",
        lineWidth: 0.5,
        lineColor: [225, 228, 235],
      },
      headStyles: { fillColor: [37, 99, 235], textColor: 255, fontStyle: "bold" },
      columnStyles: { 0: { cellWidth: 78, fontStyle: "bold" } },
      alternateRowStyles: { fillColor: [248, 250, 252] },
    });

    doc.save(`timetable-${sectionKey.toLowerCase()}.pdf`);
    toast.success("PDF exported");
  }

  const loading = slotsQuery.isPending || periodsQuery.isPending;

  return (
    <>
      <PageHeader
        title="Timetable Management"
        description="Manage the regular weekly schedule and custom shareable timetables."
        crumbs={[{ label: "Timetable" }]}
      />

      <Tabs defaultValue="weekly" className="space-y-6">
        <TabsList>
          <TabsTrigger value="weekly">Weekly Schedule</TabsTrigger>
          <TabsTrigger value="custom">Custom Timetables</TabsTrigger>
        </TabsList>

        <TabsContent value="weekly" className="space-y-6">
          <div className="flex flex-wrap items-center justify-between gap-3">
            <div className="flex items-center gap-3">
              <Select value={sectionKey} onValueChange={setSectionKey}>
                <SelectTrigger className="h-10 w-64 rounded-lg">
                  <SelectValue placeholder="Select section" />
                </SelectTrigger>
                <SelectContent>
                  {sections.map((s) => (
                    <SelectItem key={s.key} value={s.key}>
                      {s.label}
                    </SelectItem>
                  ))}
                </SelectContent>
              </Select>
              {dirty && (
                <Badge variant="secondary" className="rounded-md">
                  Unsaved changes
                </Badge>
              )}
            </div>
            
            <div className="flex flex-wrap items-center gap-2">
              <Button variant="outline" className="rounded-lg" onClick={() => setDuplicateOpen(true)}>
                <Copy className="size-4 mr-2" /> Duplicate day
              </Button>
              <Button variant="outline" className="rounded-lg" onClick={exportPdf}>
                <Download className="size-4 mr-2" /> Export PDF
              </Button>
              <Button
                variant="ghost"
                className="rounded-lg"
                disabled={!dirty}
                onClick={() => {
                  setDraft(slotsQuery.data ?? []);
                  setDirty(false);
                  toast.success("Changes reverted");
                }}
              >
                <RotateCcw className="size-4 mr-2" /> Reset
              </Button>
              <Button
                className="rounded-lg"
                disabled={!dirty || save.isPending}
                onClick={() => save.mutate()}
              >
                {save.isPending ? (
                  <Loader2 className="size-4 mr-2 animate-spin" />
                ) : (
                  <Save className="size-4 mr-2" />
                )}
                Save
              </Button>
            </div>
          </div>

          <div className="flex items-center justify-end gap-3 text-xs text-muted-foreground">
            <span className="flex items-center gap-1.5">
              <span className="size-2.5 rounded-sm border border-primary/25 bg-primary/20" /> Lecture
            </span>
            <span className="flex items-center gap-1.5">
              <span className="size-2.5 rounded-sm border border-emerald-500/30 bg-emerald-500/25" />{" "}
              Lab
            </span>
            <span className="flex items-center gap-1.5">
              <span className="size-2.5 rounded-sm border border-amber-500/30 bg-amber-500/25" />{" "}
              Tutorial
            </span>
          </div>

      <div className="surface overflow-x-auto p-3">
        {loading ? (
          <div className="flex h-72 items-center justify-center">
            <Loader2 className="size-5 animate-spin text-muted-foreground" />
          </div>
        ) : (
          <div className="min-w-[900px]">
            <div
              className="grid"
              style={{ gridTemplateColumns: `120px repeat(${DAYS.length}, minmax(0,1fr))` }}
            >
              <div className="px-2 pb-2 text-xs font-medium text-muted-foreground">Period</div>
              {DAYS.map((day) => (
                <div key={day} className="px-2 pb-2 text-xs font-medium text-muted-foreground">
                  {day}
                </div>
              ))}

              {periods.map((p) => (
                <RowFragment key={p.index}>
                  <div className="px-2 py-2">
                    <p className="text-sm font-medium">P{p.index}</p>
                    <p className="text-[11px] text-muted-foreground">{p.label}</p>
                  </div>
                  {DAYS.map((day) => {
                    const cellKey = `${day}|${p.index}`;
                    const slot = byCell.get(cellKey);
                    return (
                      <div
                        key={cellKey}
                        onDragOver={(e) => {
                          e.preventDefault();
                          setDragOver(cellKey);
                        }}
                        onDragLeave={() => setDragOver((c) => (c === cellKey ? null : c))}
                        onDrop={() => onDrop(day, p.index)}
                        className={cn(
                          "m-1 min-h-[86px] rounded-xl border border-dashed border-border/70 p-1 transition-colors",
                          dragOver === cellKey && "border-primary bg-primary/5",
                        )}
                      >
                        <AnimatePresence mode="popLayout" initial={false}>
                          {slot ? (
                            <motion.button
                              key={slot.id}
                              layout
                              initial={{ opacity: 0, scale: 0.96 }}
                              animate={{ opacity: 1, scale: 1 }}
                              exit={{ opacity: 0, scale: 0.96 }}
                              transition={{ duration: 0.15 }}
                              draggable
                              onDragStart={() => setDragging(slot.id)}
                              onDragEnd={() => {
                                setDragging(null);
                                setDragOver(null);
                              }}
                              onClick={() => openCell(day, p.index)}
                              className={cn(
                                "group h-full w-full cursor-grab rounded-lg border p-2 text-left active:cursor-grabbing",
                                typeStyles[slot.type],
                                dragging === slot.id && "opacity-40",
                              )}
                            >
                              <div className="flex items-start justify-between gap-1">
                                <p className="text-[13px] font-medium leading-tight">
                                  {slot.subject}
                                </p>
                                <GripVertical className="size-3.5 shrink-0 text-muted-foreground opacity-0 transition-opacity group-hover:opacity-100" />
                              </div>
                              <p className="mt-1 truncate text-[11px] text-muted-foreground">
                                {slot.faculty}
                              </p>
                              <p className="text-[11px] text-muted-foreground">{slot.room}</p>
                            </motion.button>
                          ) : (
                            <button
                              key="empty"
                              onClick={() => openCell(day, p.index)}
                              className="flex h-full min-h-[78px] w-full items-center justify-center rounded-lg text-muted-foreground/50 transition-colors hover:bg-muted/60 hover:text-muted-foreground"
                            >
                              <Plus className="size-4" />
                            </button>
                          )}
                        </AnimatePresence>
                      </div>
                    );
                  })}
                </RowFragment>
              ))}
            </div>
          </div>
        )}
      </div>

        </TabsContent>
        <TabsContent value="custom">
          <CustomTimetablesList />
        </TabsContent>
      </Tabs>

      <Dialog open={!!editing} onOpenChange={(open) => !open && setEditing(null)}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle>{editing?.slot ? "Edit Class" : "Add Class"}</DialogTitle>
            <DialogDescription>
              {editing?.day}, Period {editing?.period}
            </DialogDescription>
          </DialogHeader>
          <Form {...form}>
            <form onSubmit={form.handleSubmit(submitSlot)} className="flex flex-col gap-4">
              <TextField control={form.control} name="subject" label="Subject" autoFocus />
              <div className="grid grid-cols-2 gap-4">
                <TextField control={form.control} name="faculty" label="Faculty" />
                <TextField control={form.control} name="room" label="Room" />
              </div>
              <SelectField
                control={form.control}
                name="type"
                label="Type"
                options={[
                  { label: "Lecture", value: "lecture" },
                  { label: "Lab", value: "lab" },
                  { label: "Tutorial", value: "tutorial" },
                ]}
              />
              <DialogFooter className="mt-4 flex-col gap-2 sm:flex-row sm:justify-between sm:space-x-0">
                <div className="flex w-full justify-start">
                  {editing?.slot && (
                    <Button
                      type="button"
                      variant="destructive"
                      className="rounded-lg"
                      onClick={() => removeSlot(editing.slot!.id)}
                    >
                      <Trash2 className="size-4 mr-2" />
                      Remove
                    </Button>
                  )}
                </div>
                <div className="flex flex-col-reverse gap-2 sm:flex-row">
                  <Button
                    type="button"
                    variant="outline"
                    className="rounded-lg"
                    onClick={() => setEditing(null)}
                  >
                    Cancel
                  </Button>
                  <Button type="submit" className="rounded-lg">
                    Save
                  </Button>
                </div>
              </DialogFooter>
            </form>
          </Form>
        </DialogContent>
      </Dialog>

      <Dialog open={duplicateOpen} onOpenChange={setDuplicateOpen}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle>Duplicate Day</DialogTitle>
            <DialogDescription>Copy all classes from one day to another.</DialogDescription>
          </DialogHeader>
          <div className="grid grid-cols-2 gap-4 py-4">
            <div className="space-y-2">
              <label className="text-sm font-medium">Copy from</label>
              <Select value={dupFrom} onValueChange={(v) => setDupFrom(v as Weekday)}>
                <SelectTrigger>
                  <SelectValue />
                </SelectTrigger>
                <SelectContent>
                  {DAYS.map((d) => (
                    <SelectItem key={d} value={d}>
                      {d}
                    </SelectItem>
                  ))}
                </SelectContent>
              </Select>
            </div>
            <div className="space-y-2">
              <label className="text-sm font-medium">To</label>
              <Select value={dupTo} onValueChange={(v) => setDupTo(v as Weekday)}>
                <SelectTrigger>
                  <SelectValue />
                </SelectTrigger>
                <SelectContent>
                  {DAYS.map((d) => (
                    <SelectItem key={d} value={d}>
                      {d}
                    </SelectItem>
                  ))}
                </SelectContent>
              </Select>
            </div>
          </div>
          <DialogFooter>
            <Button
              variant="outline"
              className="rounded-lg"
              onClick={() => setDuplicateOpen(false)}
            >
              Cancel
            </Button>
            <Button className="rounded-lg" onClick={duplicateDay}>
              Duplicate
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>
    </>
  );
}

function RowFragment({ children }: { children: React.ReactNode }) {
  return <>{children}</>;
}
