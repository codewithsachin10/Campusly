import { createFileRoute, Link } from "@tanstack/react-router";
import { PageHeader } from "@/components/page-header";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from "@/components/ui/table";
import { StatCard } from "@/components/stat-card";
import { supabase } from "@/lib/supabase";
import { LifeBuoy, AlertCircle, Clock, CheckCircle2 } from "lucide-react";
import { useEffect, useState } from "react";
import { toast } from "sonner";
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs";

export const Route = createFileRoute("/_app/support/")({
  component: SupportPage,
});

function SupportPage() {
  const [tickets, setTickets] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);

  const fetchTickets = async () => {
    try {
      const { data, error } = await supabase
        .from("support_tickets")
        .select(`
          *,
          students ( name, email )
        `)
        .order("created_at", { ascending: false });

      if (error) throw error;
      setTickets(data || []);
    } catch (e: any) {
      toast.error("Failed to load tickets: " + e.message);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchTickets();

    // Subscribe to realtime ticket changes
    const channel = supabase
      .channel("support_tickets_changes")
      .on("postgres_changes", { event: "*", schema: "public", table: "support_tickets" }, (payload) => {
        fetchTickets();
      })
      .subscribe();

    return () => {
      supabase.removeChannel(channel);
    };
  }, []);

  const openTickets = tickets.filter(t => t.status === 'Open' || t.status === 'In Progress').length;
  const criticalTickets = tickets.filter(t => t.priority === 'Critical').length;
  const resolvedTickets = tickets.filter(t => t.status === 'Resolved' || t.status === 'Closed').length;

  const getPriorityColor = (p: string) => {
    switch (p) {
      case "Critical": return "destructive";
      case "High": return "warning";
      case "Medium": return "secondary";
      default: return "outline";
    }
  };

  const getStatusColor = (s: string) => {
    switch (s) {
      case "Open": return "default";
      case "In Progress": return "secondary";
      case "Waiting for Student": return "warning";
      case "Resolved": return "success";
      default: return "outline";
    }
  };

  return (
    <div className="space-y-6">
      <PageHeader 
        title="Support Center" 
        description="Manage student tickets, bug reports, and FAQs." 
      />

      {/* Metrics Overview */}
      <div className="grid gap-4 md:grid-cols-2 lg:grid-cols-4">
        <StatCard
          label="Open Tickets"
          value={openTickets}
          icon={LifeBuoy}
          hint="Awaiting response"
        />
        <StatCard
          label="Critical Issues"
          value={criticalTickets}
          icon={AlertCircle}
          hint="Needs immediate attention"
        />
        <StatCard
          label="Resolved"
          value={resolvedTickets}
          icon={CheckCircle2}
          hint="Total resolved"
        />
        <StatCard
          label="Avg Response Time"
          value={14}
          icon={Clock}
          hint="Minutes (Last 24h)"
        />
      </div>

      <Tabs defaultValue="tickets" className="space-y-4">
        <TabsList>
          <TabsTrigger value="tickets">Tickets</TabsTrigger>
          <TabsTrigger value="faqs">Knowledge Base</TabsTrigger>
          <TabsTrigger value="categories">Categories</TabsTrigger>
        </TabsList>

        <TabsContent value="tickets" className="space-y-4">
          <div className="flex items-center justify-between mt-4">
            <h2 className="text-xl font-semibold tracking-tight">Recent Tickets</h2>
            <div className="flex gap-2">
              <Input placeholder="Search tickets..." className="w-[250px]" />
              <Button variant="outline">Filter</Button>
            </div>
          </div>

          <div className="rounded-md border bg-card">
            <Table>
              <TableHeader>
                <TableRow>
                  <TableHead>Ticket ID</TableHead>
                  <TableHead>Student</TableHead>
                  <TableHead>Subject</TableHead>
                  <TableHead>Priority</TableHead>
                  <TableHead>Status</TableHead>
                  <TableHead>Date</TableHead>
                  <TableHead className="text-right">Action</TableHead>
                </TableRow>
              </TableHeader>
              <TableBody>
                {loading ? (
                  <TableRow>
                    <TableCell colSpan={7} className="h-24 text-center">Loading tickets...</TableCell>
                  </TableRow>
                ) : tickets.length === 0 ? (
                  <TableRow>
                    <TableCell colSpan={7} className="h-24 text-center text-muted-foreground">
                      No tickets found.
                    </TableCell>
                  </TableRow>
                ) : (
                  tickets.map((t) => (
                    <TableRow key={t.id}>
                      <TableCell className="font-medium text-xs font-mono">{t.ticket_number}</TableCell>
                      <TableCell>{t.students?.name || "Unknown"}</TableCell>
                      <TableCell className="max-w-[200px] truncate">{t.subject}</TableCell>
                      <TableCell>
                        <Badge variant={getPriorityColor(t.priority) as any}>{t.priority}</Badge>
                      </TableCell>
                      <TableCell>
                        <Badge variant={getStatusColor(t.status) as any}>{t.status}</Badge>
                      </TableCell>
                      <TableCell className="text-muted-foreground">{new Date(t.created_at).toLocaleDateString()}</TableCell>
                      <TableCell className="text-right">
                        <Button variant="ghost" size="sm" asChild>
                          <Link to="/support/$ticketId" params={{ ticketId: t.ticket_number }}>View</Link>
                        </Button>
                      </TableCell>
                    </TableRow>
                  ))
                )}
              </TableBody>
            </Table>
          </div>
        </TabsContent>

        <TabsContent value="faqs">
          <div className="rounded-md border bg-card p-8 text-center text-muted-foreground">
            FAQ Management coming soon.
          </div>
        </TabsContent>

        <TabsContent value="categories">
          <div className="rounded-md border bg-card p-8 text-center text-muted-foreground">
            Support Categories coming soon.
          </div>
        </TabsContent>
      </Tabs>
    </div>
  );
}
