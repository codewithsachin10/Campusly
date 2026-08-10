import { useQuery } from "@tanstack/react-query";
import { Users, Mail, Loader2 } from "lucide-react";
import { customTimetableQueries } from "@/lib/services";
import {
  Dialog,
  DialogContent,
  DialogHeader,
  DialogTitle,
  DialogDescription,
} from "@/components/ui/dialog";
import { Avatar, AvatarFallback, AvatarImage } from "@/components/ui/avatar";

interface TimetableMembersDialogProps {
  timetableId: string | null;
  timetableName?: string;
  onClose: () => void;
}

export function TimetableMembersDialog({
  timetableId,
  timetableName,
  onClose,
}: TimetableMembersDialogProps) {
  const { data: members, isLoading } = useQuery({
    ...customTimetableQueries.members(timetableId || ""),
    enabled: !!timetableId,
  });

  return (
    <Dialog open={!!timetableId} onOpenChange={(open) => !open && onClose()}>
      <DialogContent className="sm:max-w-md">
        <DialogHeader>
          <DialogTitle>Joined Students</DialogTitle>
          <DialogDescription>
            Students who have joined the timetable "{timetableName}".
          </DialogDescription>
        </DialogHeader>

        <div className="py-4">
          {isLoading ? (
            <div className="flex justify-center p-4">
              <Loader2 className="size-6 animate-spin text-muted-foreground" />
            </div>
          ) : !members || members.length === 0 ? (
            <div className="text-center p-6 border rounded-lg bg-muted/50 border-dashed">
              <Users className="size-8 mx-auto text-muted-foreground mb-2 opacity-20" />
              <p className="text-sm text-muted-foreground">No students have joined this timetable yet.</p>
            </div>
          ) : (
            <div className="space-y-4 max-h-[300px] overflow-y-auto pr-2">
              {members.map((student: any) => (
                <div key={student.id} className="flex items-center gap-3 p-2 rounded-lg border bg-card">
                  <Avatar className="size-10 border">
                    <AvatarImage src={student.avatarUrl} alt={student.name} />
                    <AvatarFallback>{student.name?.substring(0, 2).toUpperCase()}</AvatarFallback>
                  </Avatar>
                  <div className="flex-1 overflow-hidden">
                    <p className="text-sm font-medium truncate">{student.name}</p>
                    <p className="text-xs text-muted-foreground flex items-center truncate">
                      <Mail className="size-3 mr-1 inline" />
                      {student.email}
                    </p>
                  </div>
                </div>
              ))}
            </div>
          )}
        </div>
      </DialogContent>
    </Dialog>
  );
}
