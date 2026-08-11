import { createFileRoute } from '@tanstack/react-router'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { StatCard } from '@/components/stat-card'
import { Users, UserCheck, UserPlus, UserX, ShieldAlert } from 'lucide-react'
import { useEffect, useState } from 'react'
import { supabase } from '@/lib/supabase'

export const Route = createFileRoute('/_app/admins/')({
  component: AdminsOverview,
})

function AdminsOverview() {
  const [stats, setStats] = useState({
    total: 0,
    active: 0,
    pending: 0,
    suspended: 0,
    superAdmins: 0,
  })
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    async function fetchStats() {
      try {
        const { data: admins, error } = await supabase
          .from('admin_profiles')
          .select(`
            id,
            status,
            roles (
              name
            )
          `)

        if (error) throw error

        if (admins) {
          setStats({
            total: admins.length,
            active: admins.filter(a => a.status === 'Active').length,
            pending: admins.filter(a => a.status === 'Pending').length,
            suspended: admins.filter(a => a.status === 'Suspended').length,
            superAdmins: admins.filter(a => (a.roles as any)?.name === 'Super Admin').length,
          })
        }
      } catch (error) {
        console.error('Error fetching admin stats:', error)
      } finally {
        setLoading(false)
      }
    }

    fetchStats()
  }, [])

  return (
    <div className="space-y-6">
      <div className="grid gap-4 md:grid-cols-2 lg:grid-cols-5">
        <StatCard
          label="Total Admins"
          value={loading ? "..." : stats.total}
          icon={Users}
        />
        <StatCard
          label="Active"
          value={loading ? "..." : stats.active}
          icon={UserCheck}
        />
        <StatCard
          label="Pending Invitations"
          value={loading ? "..." : stats.pending}
          icon={UserPlus}
        />
        <StatCard
          label="Suspended"
          value={loading ? "..." : stats.suspended}
          icon={UserX}
        />
        <StatCard
          label="Super Admins"
          value={loading ? "..." : stats.superAdmins}
          icon={ShieldAlert}
        />
      </div>

      <div className="grid gap-4 md:grid-cols-2">
        <Card>
          <CardHeader>
            <CardTitle>Administration System</CardTitle>
          </CardHeader>
          <CardContent className="text-sm text-muted-foreground">
            <p className="mb-4">
              Welcome to the Campusly Admin Management System. This module allows authorized super administrators to securely manage who has access to the platform.
            </p>
            <ul className="list-disc pl-5 space-y-2">
              <li><strong>Administrators:</strong> View and manage individual staff access.</li>
              <li><strong>Roles & Permissions:</strong> Define granular access control rules.</li>
              <li><strong>Activity Logs:</strong> Immutable audit trail of every administrative action.</li>
              <li><strong>Security:</strong> Monitor active sessions and multi-factor authentication requirements.</li>
            </ul>
          </CardContent>
        </Card>
      </div>
    </div>
  )
}
