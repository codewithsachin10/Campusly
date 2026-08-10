import { useState, useMemo } from "react";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { Link, useNavigate } from "@tanstack/react-router";
import { Plus, Trash2, Edit2, Copy, Play, Users, Search, CheckCircle2 } from "lucide-react";
import { toast } from "sonner";
import { QRCodeSVG } from "qrcode.react";

import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { Card, CardHeader, CardTitle, CardDescription, CardContent, CardFooter } from "@/components/ui/card";
import { Input } from "@/components/ui/input";
import { api, customTimetableQueries } from "@/lib/services";
import { TimetableMembersDialog } from "./timetable-members-dialog";

export function CustomTimetablesList() {
  const qc = useQueryClient();
  const navigate = useNavigate();
  const timetables = useQuery(customTimetableQueries.list());
  
  const [viewingMembers, setViewingMembers] = useState<{id: string, name: string} | null>(null);
  const [searchQuery, setSearchQuery] = useState("");

  const invalidate = () => qc.invalidateQueries({ queryKey: ["customTimetables"] });

  const deleteMutation = useMutation({
    mutationFn: (id: string) => api.customTimetables.remove(id),
    onSuccess: () => {
      invalidate();
      toast.success("Timetable deleted");
    },
    onError: () => toast.error("Could not delete timetable"),
  });

  const updateStatusMutation = useMutation({
    mutationFn: ({ id, status }: { id: string; status: "draft" | "published" | "archived" }) =>
      api.customTimetables.update(id, { status }),
    onSuccess: () => {
      invalidate();
      toast.success("Timetable status updated");
    },
    onError: () => toast.error("Could not update status"),
  });

  const handleCreate = async () => {
    try {
      const name = prompt("Enter a name for the new custom timetable:");
      if (!name) return;
      const joinCode = Math.random().toString(36).substring(2, 8).toUpperCase();
      const newTt = await api.customTimetables.create({
        name,
        join_code: joinCode,
        status: "draft",
      });
      navigate({ to: "/custom-timetable/$id", params: { id: newTt.id } });
    } catch (e) {
      toast.error("Failed to create timetable");
    }
  };

  const filteredTimetables = useMemo(() => {
    if (!timetables.data) return [];
    if (!searchQuery.trim()) return timetables.data;
    
    const lowerQuery = searchQuery.toLowerCase();
    return timetables.data.filter(t => 
      t.name.toLowerCase().includes(lowerQuery) || 
      t.department?.toLowerCase().includes(lowerQuery) ||
      t.join_code.toLowerCase().includes(lowerQuery)
    );
  }, [timetables.data, searchQuery]);

  return (
    <div className="space-y-6">
      <div className="flex flex-col sm:flex-row items-start sm:items-center justify-between gap-4">
        <div>
          <h2 className="text-lg font-semibold">Custom Timetables</h2>
          <p className="text-sm text-muted-foreground">Manage and share custom class timetables.</p>
        </div>
        <div className="flex items-center gap-2 w-full sm:w-auto">
          <div className="relative w-full sm:w-64">
            <Search className="absolute left-2.5 top-2.5 h-4 w-4 text-muted-foreground" />
            <Input
              type="search"
              placeholder="Search timetables..."
              className="pl-8"
              value={searchQuery}
              onChange={(e) => setSearchQuery(e.target.value)}
            />
          </div>
          <Button className="rounded-lg shrink-0" onClick={handleCreate}>
            <Plus className="size-4 mr-2" />
            Create Timetable
          </Button>
        </div>
      </div>

      {timetables.isLoading ? (
        <div className="flex items-center justify-center p-12">
          <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-primary"></div>
        </div>
      ) : filteredTimetables.length === 0 ? (
        <div className="text-center py-12 border rounded-xl border-dashed">
          <p className="text-muted-foreground">No custom timetables found.</p>
          <Button variant="link" onClick={handleCreate}>Create your first one</Button>
        </div>
      ) : (
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
          {filteredTimetables.map((row) => (
            <Card key={row.id} className="flex flex-col overflow-hidden transition-all hover:shadow-md border-border/50 bg-card">
              <CardHeader className="pb-3 bg-muted/20 border-b">
                <div className="flex justify-between items-start gap-4">
                  <div className="space-y-1 overflow-hidden">
                    <CardTitle className="text-lg truncate" title={row.name}>{row.name}</CardTitle>
                    <CardDescription className="flex flex-col gap-1">
                      <span className="truncate">{row.department || "Any Dept"} • {row.academic_year || "Any Year"}</span>
                      {row.description && <span className="truncate text-xs opacity-75">{row.description}</span>}
                    </CardDescription>
                  </div>
                  <div>
                    {row.status === "published" ? (
                      <Badge variant="default" className="bg-emerald-500 hover:bg-emerald-600 shrink-0 shadow-sm">Published</Badge>
                    ) : row.status === "archived" ? (
                      <Badge variant="secondary" className="shrink-0 shadow-sm">Archived</Badge>
                    ) : (
                      <Badge variant="outline" className="bg-amber-500/10 text-amber-600 border-amber-500/30 shrink-0 shadow-sm">Draft</Badge>
                    )}
                  </div>
                </div>
              </CardHeader>
              
              <CardContent className="pt-6 pb-4 flex-grow">
                <div className="flex flex-col items-center gap-4">
                  {/* QR Code Section */}
                  <div className="bg-white p-3 rounded-2xl border shadow-sm flex items-center justify-center aspect-square h-[140px] w-[140px]">
                    <QRCodeSVG 
                      value={`campusly://timetable/join?code=${row.join_code}`} 
                      size={110} 
                      level="H" 
                      includeMargin={false} 
                    />
                  </div>
                  
                  {/* Join Code Section */}
                  <div className="text-center space-y-2 w-full mt-2">
                    <p className="text-xs font-semibold text-muted-foreground uppercase tracking-wider">Join Code</p>
                    <div className="flex items-center justify-center gap-1.5">
                      <Badge variant="outline" className="text-xl font-mono px-4 py-1.5 bg-primary/5 border-primary/20 text-primary shadow-sm">
                        {row.join_code}
                      </Badge>
                      <Button
                        variant="ghost"
                        size="icon"
                        className="h-8 w-8 text-muted-foreground hover:text-primary hover:bg-primary/10 rounded-full"
                        title="Copy code"
                        onClick={() => {
                          navigator.clipboard.writeText(row.join_code);
                          toast.success("Join code copied to clipboard!");
                        }}
                      >
                        <Copy className="size-4" />
                      </Button>
                    </div>
                  </div>
                </div>
              </CardContent>
              
              <CardFooter className="bg-muted/10 border-t p-3 flex flex-wrap gap-2 justify-between items-center">
                <div className="flex gap-2">
                  {row.status === "draft" ? (
                    <Button
                      variant="outline"
                      size="sm"
                      className="bg-background shadow-sm hover:bg-primary hover:text-primary-foreground transition-colors"
                      onClick={() => updateStatusMutation.mutate({ id: row.id, status: "published" })}
                    >
                      <Play className="size-3.5 mr-1.5" /> Publish
                    </Button>
                  ) : row.status === "published" ? (
                    <Button
                      variant="outline"
                      size="sm"
                      className="bg-background shadow-sm text-amber-600 hover:text-amber-700 hover:bg-amber-50 transition-colors"
                      onClick={() => updateStatusMutation.mutate({ id: row.id, status: "draft" })}
                    >
                      <CheckCircle2 className="size-3.5 mr-1.5" /> Unpublish
                    </Button>
                  ) : null}
                  
                  <Button
                    variant="outline"
                    size="sm"
                    className="bg-background shadow-sm hover:bg-primary/10 transition-colors"
                    onClick={() => setViewingMembers({ id: row.id, name: row.name })}
                  >
                    <Users className="size-3.5 mr-1.5" /> Students
                  </Button>
                </div>
                
                <div className="flex gap-1 bg-background rounded-md border shadow-sm p-0.5">
                  <Button
                    variant="ghost"
                    size="icon"
                    asChild
                    className="h-7 w-7 text-muted-foreground hover:text-primary hover:bg-primary/10 rounded-sm"
                    title="Edit Timetable"
                  >
                    <Link to="/custom-timetable/$id" params={{ id: row.id }}>
                      <Edit2 className="size-3.5" />
                    </Link>
                  </Button>
                  <Button
                    variant="ghost"
                    size="icon"
                    onClick={() => {
                      if (window.confirm("Are you sure you want to delete this timetable?")) {
                        deleteMutation.mutate(row.id);
                      }
                    }}
                    className="h-7 w-7 text-muted-foreground hover:text-destructive hover:bg-destructive/10 rounded-sm"
                    title="Delete Timetable"
                  >
                    <Trash2 className="size-3.5" />
                  </Button>
                </div>
              </CardFooter>
            </Card>
          ))}
        </div>
      )}
      
      <TimetableMembersDialog
        timetableId={viewingMembers?.id || null}
        timetableName={viewingMembers?.name || ""}
        onClose={() => setViewingMembers(null)}
      />
    </div>
  );
}
