import { useState, useRef } from "react";
import { createFileRoute, useNavigate } from "@tanstack/react-router";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { Loader2, Upload, FileText, CheckCircle2, ArrowLeft, Trash2, Plus, Edit2 } from "lucide-react";
import { toast } from "sonner";
import { PageHeader } from "@/components/page-header";
import { Button } from "@/components/ui/button";
import { Card, CardContent } from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";
import { Input } from "@/components/ui/input";
import { api, departmentQueries } from "@/lib/services";
import { extractCurriculumFromPDF } from "@/lib/ai";
import { Accordion, AccordionContent, AccordionItem, AccordionTrigger } from "@/components/ui/accordion";

export const Route = createFileRoute("/_app/curriculum/import")({
  head: () => ({
    meta: [
      { title: "Import Curriculum — Campusly Admin" },
    ],
  }),
  component: CurriculumImportWizard,
});

function CurriculumImportWizard() {
  const navigate = useNavigate();
  const fileInputRef = useRef<HTMLInputElement>(null);
  
  const [step, setStep] = useState<"upload" | "processing" | "review" | "importing">("upload");
  const [file, setFile] = useState<File | null>(null);
  const [extractedData, setExtractedData] = useState<any>(null);
  
  const departments = useQuery(departmentQueries.list());
  
  const handleFileUpload = (e: React.ChangeEvent<HTMLInputElement>) => {
    const selectedFile = e.target.files?.[0];
    if (!selectedFile) return;
    if (selectedFile.type !== "application/pdf" && selectedFile.type !== "application/json" && !selectedFile.name.endsWith(".json")) {
      toast.error("Please upload a PDF or JSON file");
      return;
    }
    setFile(selectedFile);
    processFile(selectedFile);
  };

  const processFile = async (inputFile: File) => {
    setStep("processing");
    try {
      if (inputFile.name.endsWith(".json") || inputFile.type === "application/json") {
        const reader = new FileReader();
        reader.onloadend = () => {
          try {
            const result = JSON.parse(reader.result as string);
            
            // Try to match department if present in departments list
            let deptId = "";
            if (departments.data) {
               const deptCodeMatch = departments.data.find(d => 
                 result.regulation.name.toUpperCase().includes(d.code.toUpperCase()) ||
                 inputFile.name.toUpperCase().includes(d.code.toUpperCase())
               );
               if (deptCodeMatch) deptId = deptCodeMatch.id;
            }
            
            result.regulation.department_id = deptId;
            setExtractedData(result);
            setStep("review");
            toast.success("JSON Loaded successfully!");
          } catch (err: any) {
            toast.error("Invalid JSON file");
            setStep("upload");
            setFile(null);
          }
        };
        reader.readAsText(inputFile);
      } else {
        const reader = new FileReader();
        reader.onloadend = async () => {
          const base64Data = (reader.result as string).split(',')[1];
          try {
            const result = await extractCurriculumFromPDF(base64Data);
            
            // Try to match department if present in departments list
            let deptId = "";
            if (departments.data) {
               const deptCodeMatch = departments.data.find(d => 
                 result.regulation.name.toUpperCase().includes(d.code.toUpperCase())
               );
               if (deptCodeMatch) deptId = deptCodeMatch.id;
            }
            
            result.regulation.department_id = deptId;
            
            setExtractedData(result);
            setStep("review");
            toast.success("Extraction complete!");
          } catch (err: any) {
            toast.error("AI Extraction failed: " + err.message);
            setStep("upload");
            setFile(null);
          }
        };
        reader.readAsDataURL(inputFile);
      }
    } catch (error) {
      toast.error("Failed to read file");
      setStep("upload");
    }
  };

  const handleImport = async () => {
    if (!extractedData.regulation.department_id) {
      toast.error("Please select a Department for this regulation before importing.");
      return;
    }
    setStep("importing");
    
    try {
      // 1. Create Regulation
      const regRes = await api.curriculum.createRegulation({
        department_id: extractedData.regulation.department_id,
        name: extractedData.regulation.name,
        regulation_year: extractedData.regulation.regulation_year,
        batch: extractedData.regulation.batch,
        effective_academic_year: extractedData.regulation.effective_academic_year,
        status: "active"
      });
      
      const regulationId = regRes.id;
      
      // 2. Iterate Semesters
      for (const sem of extractedData.semesters) {
        const semRes = await api.curriculum.createSemester({
          regulation_id: regulationId,
          semester_number: sem.semester_number
        });
        
        const semesterId = semRes.id;
        
        // 3. Iterate Subjects
        for (const sub of sem.subjects) {
          const subRes = await api.curriculum.createSubject({
            semester_id: semesterId,
            subject_code: sub.subject_code,
            name: sub.name,
            credits: sub.credits || 0,
            course_type: sub.course_type,
            l_t_p: sub.l_t_p,
            theory_lab: sub.theory_lab,
            category: sub.category
          });
        }
      }
      
      toast.success("Curriculum imported successfully!");
      navigate({ to: "/curriculum" });
    } catch (err: any) {
      toast.error("Failed to import curriculum: " + err.message);
      setStep("review");
    }
  };

  return (
    <div className="space-y-6 max-w-5xl mx-auto">
      <PageHeader 
        title="Import Academic Curriculum" 
        description="Upload an official regulation PDF and let AI extract the semesters and subjects."
        actions={
          <Button variant="outline" onClick={() => navigate({ to: "/curriculum" })}>
            <ArrowLeft className="size-4 mr-2" /> Cancel
          </Button>
        }
      />
      
      {step === "upload" && (
        <Card className="border-dashed border-2 bg-muted/5">
          <CardContent className="pt-6">
            <div className="flex flex-col items-center justify-center py-20 text-center space-y-4">
              <div className="p-4 bg-primary/10 rounded-full">
                <FileText className="size-10 text-primary" />
              </div>
              <div className="space-y-1">
                <h3 className="text-xl font-semibold">Upload Regulation PDF</h3>
                <p className="text-muted-foreground text-sm max-w-sm mx-auto">
                  Upload the official curriculum PDF. The AI will automatically extract semesters, subjects, credits, and course types.
                </p>
              </div>
              <input 
                type="file" 
                accept="application/pdf,application/json,.json" 
                className="hidden" 
                ref={fileInputRef}
                onChange={handleFileUpload}
              />
              <Button onClick={() => fileInputRef.current?.click()} size="lg" className="mt-4">
                <Upload className="size-4 mr-2" /> Select PDF File
              </Button>
            </div>
          </CardContent>
        </Card>
      )}

      {step === "processing" && (
        <Card>
          <CardContent className="pt-6">
            <div className="flex flex-col items-center justify-center py-20 text-center space-y-6">
              <Loader2 className="size-12 text-primary animate-spin" />
              <div className="space-y-1">
                <h3 className="text-xl font-semibold">AI is analyzing the curriculum...</h3>
                <p className="text-muted-foreground text-sm max-w-sm mx-auto">
                  This takes about 10-20 seconds. The AI is reading the tables and extracting every subject across all semesters.
                </p>
              </div>
            </div>
          </CardContent>
        </Card>
      )}

      {step === "importing" && (
        <Card>
          <CardContent className="pt-6">
            <div className="flex flex-col items-center justify-center py-20 text-center space-y-6">
              <Loader2 className="size-12 text-primary animate-spin" />
              <div className="space-y-1">
                <h3 className="text-xl font-semibold">Importing to Database...</h3>
                <p className="text-muted-foreground text-sm max-w-sm mx-auto">
                  Creating semesters, subjects, and mapping metadata.
                </p>
              </div>
            </div>
          </CardContent>
        </Card>
      )}

      {step === "review" && extractedData && (
        <div className="space-y-6 animate-in fade-in slide-in-from-bottom-4">
          <div className="flex items-center justify-between p-4 bg-emerald-500/10 border border-emerald-500/20 rounded-xl">
            <div className="flex items-center gap-3">
              <CheckCircle2 className="size-6 text-emerald-600" />
              <div>
                <h3 className="font-medium text-emerald-800">Extraction Successful</h3>
                <p className="text-sm text-emerald-600/80">Please review the extracted data before importing to the database.</p>
              </div>
            </div>
            <Button onClick={handleImport} className="bg-emerald-600 hover:bg-emerald-700 text-white">
              Approve & Import
            </Button>
          </div>

          <Card>
            <CardContent className="pt-6 space-y-4">
              <h3 className="text-lg font-semibold border-b pb-2">Regulation Details</h3>
              <div className="grid grid-cols-2 md:grid-cols-3 gap-4">
                <div className="space-y-1.5">
                  <label className="text-xs font-medium text-muted-foreground">Department</label>
                  <select 
                    className="flex h-9 w-full rounded-md border border-input bg-transparent px-3 py-1 text-sm shadow-sm transition-colors focus-visible:outline-none focus-visible:ring-1 focus-visible:ring-ring"
                    value={extractedData.regulation.department_id}
                    onChange={(e) => setExtractedData({...extractedData, regulation: {...extractedData.regulation, department_id: e.target.value}})}
                  >
                    <option value="">Select Department...</option>
                    {departments.data?.map(d => (
                      <option key={d.id} value={d.id}>{d.name} ({d.code})</option>
                    ))}
                  </select>
                </div>
                <div className="space-y-1.5">
                  <label className="text-xs font-medium text-muted-foreground">Regulation Name</label>
                  <Input 
                    value={extractedData.regulation.name} 
                    onChange={(e) => setExtractedData({...extractedData, regulation: {...extractedData.regulation, name: e.target.value}})} 
                  />
                </div>
                <div className="space-y-1.5">
                  <label className="text-xs font-medium text-muted-foreground">Batch</label>
                  <Input 
                    value={extractedData.regulation.batch} 
                    onChange={(e) => setExtractedData({...extractedData, regulation: {...extractedData.regulation, batch: e.target.value}})} 
                  />
                </div>
              </div>
            </CardContent>
          </Card>

          <h3 className="text-lg font-semibold mt-8 mb-2">Semesters & Subjects</h3>
          <Accordion type="multiple" defaultValue={["sem_1", "sem_2", "sem_3", "sem_4", "sem_5", "sem_6", "sem_7", "sem_8"]} className="w-full space-y-4">
            {extractedData.semesters.map((sem: any, semIndex: number) => (
              <AccordionItem key={`sem_${sem.semester_number}`} value={`sem_${sem.semester_number}`} className="border bg-card rounded-xl overflow-hidden shadow-sm px-1">
                <AccordionTrigger className="px-4 py-3 hover:no-underline hover:bg-muted/50 transition-colors">
                  <div className="flex items-center gap-4">
                    <span className="font-semibold text-lg">Semester {sem.semester_number}</span>
                    <Badge variant="secondary">{sem.subjects.length} Subjects</Badge>
                  </div>
                </AccordionTrigger>
                <AccordionContent className="px-4 pb-4">
                  <div className="overflow-x-auto rounded-md border">
                    <table className="w-full text-sm text-left">
                      <thead className="text-xs text-muted-foreground bg-muted/50 uppercase border-b">
                        <tr>
                          <th className="px-4 py-2 font-medium">Code</th>
                          <th className="px-4 py-2 font-medium">Name</th>
                          <th className="px-4 py-2 font-medium w-24">Credits</th>
                          <th className="px-4 py-2 font-medium">Type</th>
                          <th className="px-4 py-2 font-medium">L-T-P</th>
                          <th className="px-4 py-2 font-medium w-12">Actions</th>
                        </tr>
                      </thead>
                      <tbody>
                        {sem.subjects.map((sub: any, subIndex: number) => (
                          <tr key={subIndex} className="border-b last:border-0 hover:bg-muted/20">
                            <td className="px-4 py-2 font-mono">{sub.subject_code}</td>
                            <td className="px-4 py-2 font-medium">{sub.name}</td>
                            <td className="px-4 py-2">{sub.credits}</td>
                            <td className="px-4 py-2">
                              {sub.course_type && <Badge variant="outline" className="mr-1">{sub.course_type}</Badge>}
                              {sub.theory_lab && <Badge variant="secondary">{sub.theory_lab}</Badge>}
                            </td>
                            <td className="px-4 py-2 text-muted-foreground">{sub.l_t_p || "-"}</td>
                            <td className="px-4 py-2">
                              <Button 
                                variant="ghost" 
                                size="icon" 
                                className="h-6 w-6 text-destructive hover:bg-destructive/10"
                                onClick={() => {
                                  const newData = {...extractedData};
                                  newData.semesters[semIndex].subjects.splice(subIndex, 1);
                                  setExtractedData(newData);
                                }}
                              >
                                <Trash2 className="size-3" />
                              </Button>
                            </td>
                          </tr>
                        ))}
                      </tbody>
                    </table>
                  </div>
                </AccordionContent>
              </AccordionItem>
            ))}
          </Accordion>
        </div>
      )}
    </div>
  );
}
