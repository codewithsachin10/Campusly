import { createFileRoute } from '@tanstack/react-router'
import { Card, CardHeader, CardTitle } from '@/components/ui/card'
import { Badge } from '@/components/ui/badge'
import { Search, Filter, History } from 'lucide-react'
import { Input } from '@/components/ui/input'
import { Button } from '@/components/ui/button'
import { useEffect, useState } from 'react'
import { supabase } from '@/lib/supabase'

export const Route = createFileRoute('/_app/admins/audit')({
  component: AdminAuditLogs,
})

function AdminAuditLogs() {
  const [logs, setLogs] = useState<any[]>([])
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    async function fetchLogs() {
      try {
        const { data, error } = await supabase
          .from('admin_audit_logs')
          .select(`
            *,
            admin_profiles:actor_id (full_name)
          `)
          .order('created_at', { ascending: false })
          .limit(50)

        if (error) throw error
        if (data) setLogs(data)
      } catch (error) {
        console.error('Error fetching audit logs:', error)
      } finally {
        setLoading(false)
      }
    }

    fetchLogs()
  }, [])

  return (
    <div className="space-y-6">
      <div className="flex flex-col sm:flex-row gap-4 items-center justify-between">
        <div className="relative w-full sm:max-w-sm">
          <Search className="absolute left-2.5 top-2.5 h-4 w-4 text-muted-foreground" />
          <Input placeholder="Search logs by action or resource..." className="pl-8" />
        </div>
        <div className="flex items-center gap-2 w-full sm:w-auto">
          <Button variant="outline" className="w-full sm:w-auto">
            <Filter className="mr-2 h-4 w-4" />
            Filter
          </Button>
        </div>
      </div>

      <Card>
        <CardHeader className="pb-2 flex flex-row items-center gap-2">
          <History className="h-5 w-5 text-primary" />
          <CardTitle className="text-base">Recent Administrative Actions</CardTitle>
        </CardHeader>
        <div className="relative w-full overflow-auto p-0">
          <table className="w-full caption-bottom text-sm">
            <thead className="[&_tr]:border-b">
              <tr className="border-b bg-muted/20">
                <th className="h-12 px-4 text-left font-medium text-muted-foreground">Timestamp</th>
                <th className="h-12 px-4 text-left font-medium text-muted-foreground">Administrator</th>
                <th className="h-12 px-4 text-left font-medium text-muted-foreground">Action</th>
                <th className="h-12 px-4 text-left font-medium text-muted-foreground">Resource</th>
                <th className="h-12 px-4 text-left font-medium text-muted-foreground">Details</th>
              </tr>
            </thead>
            <tbody className="[&_tr:last-child]:border-0">
              {loading ? (
                <tr>
                  <td colSpan={5} className="h-24 text-center">Loading audit logs...</td>
                </tr>
              ) : logs.length === 0 ? (
                <tr>
                  <td colSpan={5} className="h-24 text-center text-muted-foreground">No audit logs found.</td>
                </tr>
              ) : (
                logs.map((log) => (
                  <tr key={log.id} className="border-b hover:bg-muted/50">
                    <td className="p-4 align-middle whitespace-nowrap text-muted-foreground">
                      {new Date(log.created_at).toLocaleString()}
                    </td>
                    <td className="p-4 align-middle font-medium">
                      {log.admin_profiles?.full_name || 'System / Unknown'}
                    </td>
                    <td className="p-4 align-middle">
                      <Badge variant="outline">{log.action}</Badge>
                    </td>
                    <td className="p-4 align-middle text-muted-foreground">
                      {log.resource_type} ({log.resource_id?.substring(0, 8)}...)
                    </td>
                    <td className="p-4 align-middle text-muted-foreground text-xs">
                      {log.ip_address && <div>IP: {log.ip_address}</div>}
                    </td>
                  </tr>
                ))
              )}
            </tbody>
          </table>
        </div>
      </Card>
    </div>
  )
}
