import { createFileRoute, Link } from "@tanstack/react-router";
import { PageHeader } from "@/components/page-header";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Card, CardContent, CardFooter, CardHeader, CardTitle } from "@/components/ui/card";
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

  const getStatusBorderColor = (s: string) => {
    switch (s) {
      case "Open": return "border-l-rose-500";
      case "In Progress": return "border-l-amber-500";
      case "Waiting for Student": return "border-l-blue-500";
      case "Resolved":
      case "Closed": return "border-l-emerald-500";
      default: return "border-l-border";
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

          {loading ? (
            <div className="flex justify-center p-12 bg-card rounded-md border">
              <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-primary"></div>
            </div>
          ) : tickets.length === 0 ? (
            <div className="p-12 text-center text-muted-foreground bg-card rounded-md border">
              No tickets found.
            </div>
          ) : (
            <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
              {tickets.map((t) => (
                <Card key={t.id} className={`border-l-4 ${getStatusBorderColor(t.status)}`}>
                  <CardHeader className="pb-3">
                    <div className="flex justify-between items-start gap-2">
                      <CardTitle className="text-base font-semibold line-clamp-1" title={t.subject}>
                        {t.subject}
                      </CardTitle>
                      <Badge variant={getStatusColor(t.status) as any} className="shrink-0">{t.status}</Badge>
                    </div>
                    <div className="text-sm text-muted-foreground flex items-center justify-between mt-1">
                      <span className="font-mono text-xs">{t.ticket_number}</span>
                      <span>{new Date(t.created_at).toLocaleDateString()}</span>
                    </div>
                  </CardHeader>
                  <CardContent className="pb-4">
                    <div className="space-y-3 text-sm">
                      <div className="flex justify-between items-center">
                        <span className="text-muted-foreground">Student:</span>
                        <span className="font-medium truncate max-w-[150px]">{t.students?.name || "Unknown"}</span>
                      </div>
                      <div className="flex justify-between items-center">
                        <span className="text-muted-foreground">Priority:</span>
                        <Badge variant={getPriorityColor(t.priority) as any} className="h-5">{t.priority}</Badge>
                      </div>
                    </div>
                  </CardContent>
                  <CardFooter className="pt-0 justify-end">
                    <Button variant="outline" size="sm" asChild>
                      <Link to="/support/$ticketId" params={{ ticketId: t.ticket_number }}>View Details</Link>
                    </Button>
                  </CardFooter>
                </Card>
              ))}
            </div>
          )}
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
