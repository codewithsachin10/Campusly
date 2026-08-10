import { createFileRoute } from "@tanstack/react-router";
import { PageHeader } from "@/components/page-header";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { Textarea } from "@/components/ui/textarea";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { supabase } from "@/lib/supabase";
import { useAuth } from "@/lib/auth";
import { Send, ArrowLeft, Paperclip, CheckCircle } from "lucide-react";
import { useEffect, useState, useRef } from "react";
import { toast } from "sonner";
import { Link } from "@tanstack/react-router";

export const Route = createFileRoute("/_app/support/$ticketId")({
  component: TicketDetailsPage,
});

function TicketDetailsPage() {
  const { ticketId } = Route.useParams();
  const { admin } = useAuth();
  const [ticket, setTicket] = useState<any>(null);
  const [messages, setMessages] = useState<any[]>([]);
  const [notes, setNotes] = useState<any[]>([]);
  const [replyText, setReplyText] = useState("");
  const [noteText, setNoteText] = useState("");
  const [loading, setLoading] = useState(true);
  const messagesEndRef = useRef<HTMLDivElement>(null);

  const fetchData = async () => {
    try {
      const [ticketRes, messagesRes, notesRes] = await Promise.all([
        supabase.from("support_tickets").select("*, students(name, email)").eq("ticket_number", ticketId).single(),
        supabase.from("support_ticket_messages").select("*").eq("ticket_id", ticketId).order("created_at", { ascending: true }),
        supabase.from("support_ticket_internal_notes").select("*, admin:admin_id(name)").eq("ticket_id", ticketId).order("created_at", { ascending: true })
      ]);

      // If the ticket ID passed was the internal UUID, we'd query by id, but usually routes use the friendly ticket_number.
      // We will assume the parameter is the UUID for now to make relations easy.
      
      const realTicketId = ticketRes.data?.id || ticketId;

      const [realTicketRes, realMessagesRes, realNotesRes] = await Promise.all([
        supabase.from("support_tickets").select("*, students(name, email)").eq("id", realTicketId).single(),
        supabase.from("support_ticket_messages").select("*").eq("ticket_id", realTicketId).order("created_at", { ascending: true }),
        supabase.from("support_ticket_internal_notes").select("*").eq("ticket_id", realTicketId).order("created_at", { ascending: true })
      ]);

      setTicket(realTicketRes.data);
      setMessages(realMessagesRes.data || []);
      setNotes(realNotesRes.data || []);
    } catch (e: any) {
      toast.error("Error loading ticket: " + e.message);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchData();
    
    // Simplified realtime setup for MVP
    const channel = supabase
      .channel(`ticket_${ticketId}`)
      .on("postgres_changes", { event: "INSERT", schema: "public", table: "support_ticket_messages" }, () => {
        fetchData();
      })
      .subscribe();

    return () => {
      supabase.removeChannel(channel);
    };
  }, [ticketId]);

  useEffect(() => {
    messagesEndRef.current?.scrollIntoView({ behavior: "smooth" });
  }, [messages]);

  const handleSendReply = async () => {
    if (!replyText.trim() || !ticket || !admin) return;
    try {
      await supabase.from("support_ticket_messages").insert({
        ticket_id: ticket.id,
        sender_id: admin.uid,
        sender_type: "Admin",
        message: replyText.trim()
      });
      setReplyText("");
    } catch (e: any) {
      toast.error("Failed to send reply");
    }
  };

  const handleStatusChange = async (newStatus: string) => {
    if (!ticket) return;
    try {
      await supabase.from("support_tickets").update({ status: newStatus }).eq("id", ticket.id);
      toast.success(`Ticket marked as ${newStatus}`);
      fetchData();
    } catch (e: any) {
      toast.error("Failed to update status");
    }
  };

  if (loading) return <div className="p-8 text-center">Loading ticket details...</div>;
  if (!ticket) return <div className="p-8 text-center text-destructive">Ticket not found</div>;

  return (
    <div className="space-y-6">
      <div className="flex items-center gap-4">
        <Button variant="outline" size="icon" asChild>
          <Link to="/support"><ArrowLeft className="h-4 w-4" /></Link>
        </Button>
        <div className="flex-1">
          <PageHeader 
            title={`Ticket ${ticket.ticket_number || ticket.id.substring(0,8)}`} 
            description={ticket.subject} 
          />
        </div>
        <div className="flex gap-2">
          {ticket.status !== 'Resolved' && ticket.status !== 'Closed' && (
            <Button variant="default" onClick={() => handleStatusChange('Resolved')}>
              <CheckCircle className="mr-2 h-4 w-4" />
              Mark Resolved
            </Button>
          )}
        </div>
      </div>

      <div className="grid gap-6 md:grid-cols-3">
        {/* Chat Area */}
        <div className="md:col-span-2 flex flex-col h-[600px] rounded-md border bg-card">
          <div className="p-4 border-b bg-muted/50 font-medium">Conversation</div>
          
          <div className="flex-1 overflow-y-auto p-4 space-y-4">
            {/* Original Problem */}
            <div className="flex flex-col items-start">
              <div className="text-xs text-muted-foreground mb-1">{ticket.students?.name} • Original Report</div>
              <div className="bg-muted p-3 rounded-lg rounded-tl-none max-w-[80%]">
                {ticket.description}
              </div>
            </div>

            {/* Replies */}
            {messages.map((m) => (
              <div key={m.id} className={`flex flex-col ${m.sender_type === 'Admin' ? 'items-end' : 'items-start'}`}>
                <div className="text-xs text-muted-foreground mb-1">
                  {m.sender_type === 'Admin' ? 'Support Admin' : ticket.students?.name} • {new Date(m.created_at).toLocaleTimeString()}
                </div>
                <div className={`p-3 rounded-lg max-w-[80%] ${m.sender_type === 'Admin' ? 'bg-primary text-primary-foreground rounded-tr-none' : 'bg-muted rounded-tl-none'}`}>
                  {m.message}
                </div>
              </div>
            ))}
            <div ref={messagesEndRef} />
          </div>

          <div className="p-4 border-t bg-background flex gap-2">
            <Button variant="outline" size="icon"><Paperclip className="h-4 w-4" /></Button>
            <Textarea 
              className="min-h-[40px] resize-none" 
              placeholder="Type your reply..." 
              value={replyText}
              onChange={(e) => setReplyText(e.target.value)}
            />
            <Button onClick={handleSendReply} size="icon"><Send className="h-4 w-4" /></Button>
          </div>
        </div>

        {/* Context Panel */}
        <div className="space-y-6">
          <Card>
            <CardHeader><CardTitle className="text-sm">Ticket Information</CardTitle></CardHeader>
            <CardContent className="space-y-4 text-sm">
              <div className="flex justify-between">
                <span className="text-muted-foreground">Status</span>
                <Badge>{ticket.status}</Badge>
              </div>
              <div className="flex justify-between">
                <span className="text-muted-foreground">Priority</span>
                <Badge variant="outline">{ticket.priority}</Badge>
              </div>
              <div className="flex justify-between">
                <span className="text-muted-foreground">Created</span>
                <span>{new Date(ticket.created_at).toLocaleDateString()}</span>
              </div>
            </CardContent>
          </Card>

          <Card>
            <CardHeader><CardTitle className="text-sm">Technical Context</CardTitle></CardHeader>
            <CardContent className="space-y-4 text-sm font-mono">
              <div className="flex justify-between">
                <span className="text-muted-foreground font-sans">App Version</span>
                <span>{ticket.app_version || 'N/A'}</span>
              </div>
              <div className="flex justify-between">
                <span className="text-muted-foreground font-sans">OS</span>
                <span>{ticket.os_version || 'N/A'}</span>
              </div>
              <div className="flex justify-between">
                <span className="text-muted-foreground font-sans">Platform</span>
                <span>{ticket.platform || 'N/A'}</span>
              </div>
              <div className="flex flex-col mt-2 pt-2 border-t">
                <span className="text-muted-foreground font-sans text-xs">Screen</span>
                <span className="mt-1 break-all">{ticket.current_screen || 'N/A'}</span>
              </div>
            </CardContent>
          </Card>
        </div>
      </div>
    </div>
  );
}
