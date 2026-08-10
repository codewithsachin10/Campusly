import { useState, useRef } from "react";
import { createFileRoute, useNavigate, Link } from "@tanstack/react-router";
import { useQuery } from "@tanstack/react-query";
import { Loader2, Upload, CheckCircle2, ArrowLeft, FolderUp, AlertTriangle } from "lucide-react";
import { toast } from "sonner";
import { PageHeader } from "@/components/page-header";
import { Button } from "@/components/ui/button";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Progress } from "@/components/ui/progress";
import { Badge } from "@/components/ui/badge";
import { api, departmentQueries } from "@/lib/services";
import { extractCurriculumFromPDF } from "@/lib/ai";

export const Route = createFileRoute("/_app/curriculum/batch-import")({
  head: () => ({
    meta: [{ title: "Batch Import Curriculum — Campusly Admin" }],
  }),
  component: CurriculumBatchImport,
});

function CurriculumBatchImport() {
  const navigate = useNavigate();
  const fileInputRef = useRef<HTMLInputElement>(null);
  
  const [step, setStep] = useState<"upload" | "processing" | "complete">("upload");
  const [files, setFiles] = useState<File[]>([]);
  const [currentFileIndex, setCurrentFileIndex] = useState(0);
  const [results, setResults] = useState<{ fileName: string; status: 'success' | 'error'; deptMatched?: string; error?: string }[]>([]);
  
  const departments = useQuery(departmentQueries.list());
  
  const handleFileUpload = (e: React.ChangeEvent<HTMLInputElement>) => {
    const selectedFiles = Array.from(e.target.files || []).filter(f => 
      f.type === "application/pdf" || f.type === "application/json" || f.name.endsWith(".json")
    );
    if (selectedFiles.length === 0) {
      toast.error("No valid PDF or JSON files selected");
      return;
    }
    setFiles(selectedFiles);
    startBatchProcess(selectedFiles);
  };

  const startBatchProcess = async (filesToProcess: File[]) => {
    setStep("processing");
    const newResults: typeof results = [];
    
    for (let i = 0; i < filesToProcess.length; i++) {
      setCurrentFileIndex(i);
      const file = filesToProcess[i];
      
      try {
        let result: any;
        
        if (file.name.endsWith(".json") || file.type === "application/json") {
          const textData = await readFileAsText(file);
          result = JSON.parse(textData);
        } else {
          const base64Data = await readFileAsBase64(file);
          result = await extractCurriculumFromPDF(base64Data);
        }
        
        // Auto-match department
        let deptId = "";
        let deptCode = "";
        if (departments.data) {
           const deptMatch = departments.data.find(d => 
             result.regulation.name.toUpperCase().includes(d.code.toUpperCase()) || 
             file.name.toUpperCase().includes(d.code.toUpperCase())
           );
           if (deptMatch) {
             deptId = deptMatch.id;
             deptCode = deptMatch.code;
           }
        }
        
        if (!deptId) {
          throw new Error("Could not automatically match to a department based on content or filename.");
        }

        // Import immediately
        const regRes = await api.curriculum.createRegulation({
          department_id: deptId,
          name: result.regulation.name,
          regulation_year: result.regulation.regulation_year,
          batch: result.regulation.batch,
          effective_academic_year: result.regulation.effective_academic_year,
          status: "active"
        });
        
        for (const sem of result.semesters) {
          const semRes = await api.curriculum.createSemester({
            regulation_id: regRes.id,
            semester_number: sem.semester_number
          });
          
          for (const sub of sem.subjects) {
            const subRes = await api.curriculum.createSubject({
              semester_id: semRes.id,
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
        
        newResults.push({ fileName: file.name, status: 'success', deptMatched: deptCode });
      } catch (err: any) {
        newResults.push({ fileName: file.name, status: 'error', error: err.message });
      }
      setResults([...newResults]);
    }
    
    setStep("complete");
    toast.success("Batch processing complete");
  };

  const readFileAsText = (file: File): Promise<string> => {
    return new Promise((resolve, reject) => {
      const reader = new FileReader();
      reader.onloadend = () => {
        resolve(reader.result as string);
      };
      reader.onerror = reject;
      reader.readAsText(file);
    });
  };

  const readFileAsBase64 = (file: File): Promise<string> => {
    return new Promise((resolve, reject) => {
      const reader = new FileReader();
      reader.onloadend = () => {
        resolve((reader.result as string).split(',')[1]);
      };
      reader.onerror = reject;
      reader.readAsDataURL(file);
    });
  };

  return (
    <div className="space-y-6 max-w-5xl mx-auto">
      <PageHeader 
        title="Batch Import Curriculum" 
        description="Upload multiple department curriculum PDFs at once. The AI will automatically map and import them."
        actions={
          <Button variant="outline" onClick={() => navigate({ to: "/curriculum" })}>
            <ArrowLeft className="size-4 mr-2" /> Back
          </Button>
        }
      />
      
      {step === "upload" && (
        <Card className="border-dashed border-2 bg-muted/5">
          <CardContent className="pt-6">
            <div className="flex flex-col items-center justify-center py-20 text-center space-y-4">
              <div className="p-4 bg-primary/10 rounded-full">
                <FolderUp className="size-10 text-primary" />
              </div>
              <div className="space-y-1">
                <h3 className="text-xl font-semibold">Upload Multiple PDFs</h3>
                <p className="text-muted-foreground text-sm max-w-sm mx-auto">
                  Select all your curriculum PDF files. Name them with the department code (e.g. CSE.pdf, AERO.pdf) for best automatic matching.
                </p>
              </div>
              {/* Note: 'multiple' allows selecting multiple files */}
              <input 
                type="file" 
                accept="application/pdf,application/json,.json" 
                multiple
                className="hidden" 
                ref={fileInputRef}
                onChange={handleFileUpload}
              />
              <Button onClick={() => fileInputRef.current?.click()} size="lg" className="mt-4">
                <Upload className="size-4 mr-2" /> Select Files
              </Button>
            </div>
          </CardContent>
        </Card>
      )}

      {step === "processing" && (
        <Card>
          <CardContent className="pt-10 space-y-8">
            <div className="flex flex-col items-center justify-center text-center space-y-4">
              <Loader2 className="size-10 text-primary animate-spin" />
              <div>
                <h3 className="text-xl font-semibold">Processing Curriculums...</h3>
                <p className="text-muted-foreground text-sm">
                  Analyzing file {currentFileIndex + 1} of {files.length} ({files[currentFileIndex]?.name})
                </p>
              </div>
            </div>
            
            <div className="space-y-2 max-w-xl mx-auto w-full">
              <Progress value={((currentFileIndex) / files.length) * 100} className="h-2" />
              <div className="flex justify-between text-xs text-muted-foreground">
                <span>{currentFileIndex} completed</span>
                <span>{files.length} total</span>
              </div>
            </div>
          </CardContent>
        </Card>
      )}

      {(step === "complete" || results.length > 0) && (
        <div className="space-y-6">
          {step === "complete" && (
            <div className="flex items-center gap-3 p-4 bg-emerald-500/10 border border-emerald-500/20 rounded-xl">
              <CheckCircle2 className="size-6 text-emerald-600" />
              <div>
                <h3 className="font-medium text-emerald-800">Batch Import Finished</h3>
                <p className="text-sm text-emerald-600/80">Processed {files.length} files.</p>
              </div>
            </div>
          )}

          <Card>
            <CardHeader>
              <CardTitle>Results</CardTitle>
            </CardHeader>
            <CardContent>
              <div className="space-y-3">
                {results.map((res, i) => (
                  <div key={i} className="flex items-start justify-between p-3 border rounded-lg">
                    <div className="flex items-center gap-3">
                      {res.status === 'success' ? (
                        <CheckCircle2 className="size-5 text-emerald-500 shrink-0" />
                      ) : (
                        <AlertTriangle className="size-5 text-destructive shrink-0" />
                      )}
                      <div>
                        <p className="font-medium text-sm">{res.fileName}</p>
                        {res.status === 'error' && (
                          <p className="text-xs text-destructive mt-0.5">{res.error}</p>
                        )}
                      </div>
                    </div>
                    {res.status === 'success' && res.deptMatched && (
                      <Badge variant="secondary">Matched: {res.deptMatched}</Badge>
                    )}
                    {res.status === 'success' && !res.deptMatched && (
                      <Badge className="bg-emerald-500">Success</Badge>
                    )}
                  </div>
                ))}
              </div>
              
              {step === "complete" && (
                <div className="mt-6 flex justify-end">
                  <Button asChild>
                    <Link to="/curriculum">View All Regulations</Link>
                  </Button>
                </div>
              )}
            </CardContent>
          </Card>
        </div>
      )}
    </div>
  );
}
