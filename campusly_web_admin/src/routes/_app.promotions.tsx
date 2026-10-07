import { createFileRoute } from "@tanstack/react-router";
import { PageHeader } from "@/components/page-header";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import { api, departmentQueries, studentQueries } from "@/lib/services";
import { useState, useMemo, useRef } from "react";
import { toast } from "sonner";
import { Users, Upload, ArrowRight, UserCheck, CheckCircle2, ChevronRight, FileSpreadsheet } from "lucide-react";

export const Route = createFileRoute("/_app/promotions")({
  component: BatchPromotionsPage,
});

function BatchPromotionsPage() {
  const qc = useQueryClient();
  const { data: departments = [] } = useQuery(departmentQueries.list());
  const { data: students = [], isLoading: loadingStudents } = useQuery(studentQueries.list());

  // Filters for targeting
  const [targetDeptId, setTargetDeptId] = useState<string>("all");
  const [targetYear, setTargetYear] = useState<string>("all");
  const [targetSemester, setTargetSemester] = useState<string>("all");

  // Filter students based on selection
  const targetedStudents = useMemo(() => {
    return students.filter(s => 
      (targetDeptId === "all" || s.departmentId === targetDeptId) &&
      (targetYear === "all" || s.academicYear === targetYear) &&
      (targetSemester === "all" || (s.semester != null && s.semester.toString() === targetSemester))
    );
  }, [students, targetDeptId, targetYear, targetSemester]);

  // Unique years and semesters to populate the filter dropdowns
  const availableYears = useMemo(() => Array.from(new Set(students.map(s => s.academicYear))).filter(Boolean).sort(), [students]);
  const availableSemesters = useMemo(() => Array.from(new Set(students.map(s => s.semester != null ? s.semester.toString() : null))).filter(Boolean).sort(), [students]);

  // Promotion Form State
  const [nextYear, setNextYear] = useState("");
  const [nextSemester, setNextSemester] = useState("");
  const [defaultSection, setDefaultSection] = useState("");
  const [isPromoting, setIsPromoting] = useState(false);

  // CSV Section Mapping State
  const fileInputRef = useRef<HTMLInputElement>(null);
  const [csvMappings, setCsvMappings] = useState<{rollNumber: string, section: string}[] | null>(null);

  const handleFileUpload = (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (!file) return;

    const reader = new FileReader();
    reader.onload = (event) => {
      const text = event.target?.result as string;
      const rows = text.split('\n');
      const mappings = [];
      for (let i = 1; i < rows.length; i++) {
        const row = rows[i].split(',');
        if (row.length >= 2) {
          mappings.push({ rollNumber: row[0].trim(), section: row[1].trim() });
        }
      }
      setCsvMappings(mappings);
      toast.success(`Loaded section mappings for ${mappings.length} students`);
    };
    reader.readAsText(file);
  };

  const promoteMutation = useMutation({
    mutationFn: async () => {
      const studentIds = targetedStudents.map(s => s.id);
      
      // Step 1: Promote Year & Semester
      if (nextYear || nextSemester || defaultSection) {
        await api.students.promoteBatch(
          studentIds, 
          nextYear || targetYear, // fallback to current if not provided
          nextSemester ? parseInt(nextSemester) : parseInt(targetSemester),
          defaultSection || undefined
        );
      }

      // Step 2: Apply CSV Section Mappings if uploaded
      if (csvMappings && csvMappings.length > 0) {
        const updates: { id: string, section: string }[] = [];
        for (const mapping of csvMappings) {
          const student = targetedStudents.find(s => s.rollNumber === mapping.rollNumber);
          if (student) {
            updates.push({ id: student.id, section: mapping.section });
          }
        }
        if (updates.length > 0) {
          await api.students.updateSectionBulk(updates);
        }
      }
    },
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ["students"] });
      toast.success("Batch successfully promoted!");
      setNextYear("");
      setNextSemester("");
      setDefaultSection("");
      setCsvMappings(null);
      setIsPromoting(false);
    },
    onError: (err) => {
      console.error(err);
      toast.error("An error occurred during promotion.");
      setIsPromoting(false);
    }
  });

  return (
    <div className="space-y-6">
      <PageHeader
        title="Batch Promotion & Rollouts"
        description="Transition entire batches to the next semester or academic year, and shuffle class sections."
        crumbs={[{ label: "Academics" }, { label: "Batch Promotions" }]}
      />

      <div className="grid lg:grid-cols-3 gap-6">
        
        {/* Step 1: Select Target Group */}
        <div className="lg:col-span-1 space-y-4">
          <div className="bg-white border rounded-xl p-5 shadow-sm">
            <div className="flex items-center gap-3 mb-4 text-primary">
              <div className="w-8 h-8 rounded-full bg-primary/10 flex items-center justify-center font-bold">1</div>
              <h3 className="font-semibold text-lg text-foreground">Select Target Group</h3>
            </div>
            
            <div className="space-y-4">
              <div className="space-y-1.5">
                <label className="text-sm font-medium text-muted-foreground">Department</label>
                <Select value={targetDeptId} onValueChange={setTargetDeptId}>
                  <SelectTrigger className="w-full bg-muted/30"><SelectValue placeholder="All Departments" /></SelectTrigger>
                  <SelectContent>
                    <SelectItem value="all">All Departments</SelectItem>
                    {departments.map((d: any) => <SelectItem key={d.id} value={d.id}>{d.name}</SelectItem>)}
                  </SelectContent>
                </Select>
              </div>

              <div className="space-y-1.5">
                <label className="text-sm font-medium text-muted-foreground">Current Academic Year</label>
                <Select value={targetYear} onValueChange={setTargetYear}>
                  <SelectTrigger className="w-full bg-muted/30"><SelectValue placeholder="All Years" /></SelectTrigger>
                  <SelectContent>
                    <SelectItem value="all">All Years</SelectItem>
                    {availableYears.map(y => <SelectItem key={y} value={y}>{y}</SelectItem>)}
                  </SelectContent>
                </Select>
              </div>

              <div className="space-y-1.5">
                <label className="text-sm font-medium text-muted-foreground">Current Semester</label>
                <Select value={targetSemester} onValueChange={setTargetSemester}>
                  <SelectTrigger className="w-full bg-muted/30"><SelectValue placeholder="All Semesters" /></SelectTrigger>
                  <SelectContent>
                    <SelectItem value="all">All Semesters</SelectItem>
                    {availableSemesters.map(s => <SelectItem key={s} value={s}>Semester {s}</SelectItem>)}
                  </SelectContent>
                </Select>
              </div>
            </div>

            <div className="mt-6 p-4 bg-primary/5 rounded-lg border border-primary/20 flex items-center justify-between">
              <div className="flex items-center gap-3 text-primary">
                <Users className="w-5 h-5" />
                <span className="font-semibold">Students Selected:</span>
              </div>
              <span className="text-xl font-bold">{loadingStudents ? "..." : targetedStudents.length}</span>
            </div>
          </div>
        </div>

        {/* Step 2 & 3: Configure & Apply */}
        <div className="lg:col-span-2 space-y-4">
          <div className="bg-white border rounded-xl p-5 shadow-sm relative overflow-hidden">
            
            {/* Disabled Overlay if no students selected */}
            {targetedStudents.length === 0 && (
              <div className="absolute inset-0 bg-white/60 backdrop-blur-[1px] z-10 flex items-center justify-center">
                <div className="bg-white border shadow-lg rounded-xl px-6 py-3 text-sm font-medium flex items-center gap-2">
                  <UserCheck className="w-4 h-4 text-primary" />
                  Select a target group first
                </div>
              </div>
            )}

            <div className="flex items-center gap-3 mb-6 text-primary">
              <div className="w-8 h-8 rounded-full bg-primary/10 flex items-center justify-center font-bold">2</div>
              <h3 className="font-semibold text-lg text-foreground">Configure Promotion</h3>
            </div>

            <div className="grid sm:grid-cols-2 gap-8">
              {/* Promotion Details */}
              <div className="space-y-4">
                <h4 className="font-medium flex items-center gap-2 border-b pb-2">
                  <ArrowRight className="w-4 h-4 text-muted-foreground" /> Next Semester Details
                </h4>
                <div className="space-y-1.5">
                  <label className="text-sm font-medium text-muted-foreground">Promote to Academic Year</label>
                  <Input 
                    placeholder={`e.g. ${targetYear !== "all" ? targetYear : "3rd Year"}`}
                    value={nextYear}
                    onChange={e => setNextYear(e.target.value)}
                  />
                </div>
                <div className="space-y-1.5">
                  <label className="text-sm font-medium text-muted-foreground">Promote to Semester</label>
                  <Input 
                    type="number"
                    placeholder={`e.g. ${targetSemester !== "all" ? parseInt(targetSemester) + 1 : "4"}`}
                    value={nextSemester}
                    onChange={e => setNextSemester(e.target.value)}
                  />
                </div>
              </div>

              {/* Section Details */}
              <div className="space-y-4">
                <h4 className="font-medium flex items-center gap-2 border-b pb-2">
                  <Users className="w-4 h-4 text-muted-foreground" /> Section Shuffling
                </h4>
                
                <div className="space-y-3">
                  <div className="space-y-1.5">
                    <label className="text-sm font-medium text-muted-foreground">Assign Default Section (Optional)</label>
                    <Input 
                      placeholder="e.g. A"
                      value={defaultSection}
                      onChange={e => setDefaultSection(e.target.value)}
                    />
                  </div>
                  
                  <div className="relative my-4 flex items-center">
                    <div className="flex-grow border-t border-muted"></div>
                    <span className="flex-shrink-0 mx-4 text-muted-foreground text-xs uppercase font-medium">Or Shuffle via CSV</span>
                    <div className="flex-grow border-t border-muted"></div>
                  </div>

                  <div className="p-4 border border-dashed rounded-xl bg-muted/20 hover:bg-muted/40 transition-colors text-center">
                    <input 
                      type="file" 
                      accept=".csv" 
                      className="hidden" 
                      ref={fileInputRef} 
                      onChange={handleFileUpload}
                    />
                    {csvMappings ? (
                      <div className="flex flex-col items-center gap-2">
                        <CheckCircle2 className="w-6 h-6 text-green-500" />
                        <span className="text-sm font-medium text-green-600">{csvMappings.length} mappings loaded</span>
                        <Button variant="ghost" size="sm" className="h-6 text-xs text-muted-foreground" onClick={() => setCsvMappings(null)}>Remove</Button>
                      </div>
                    ) : (
                      <div className="flex flex-col items-center gap-2 cursor-pointer" onClick={() => fileInputRef.current?.click()}>
                        <FileSpreadsheet className="w-6 h-6 text-primary" />
                        <span className="text-sm font-medium text-primary">Upload CSV (RollNo, Section)</span>
                      </div>
                    )}
                  </div>
                </div>
              </div>
            </div>
            
            {/* Action Bar */}
            <div className="mt-8 pt-6 border-t flex justify-end">
              <Button 
                size="lg" 
                className="rounded-xl px-8"
                disabled={isPromoting}
                onClick={() => {
                  if (confirm(`Are you sure you want to promote ${targetedStudents.length} students?`)) {
                    setIsPromoting(true);
                    promoteMutation.mutate();
                  }
                }}
              >
                {isPromoting ? "Promoting..." : "Apply Batch Promotion"}
                <ChevronRight className="w-4 h-4 ml-2" />
              </Button>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}
