import { createFileRoute } from '@tanstack/react-router'
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card'
import { Badge } from '@/components/ui/badge'
import { Button } from '@/components/ui/button'
import { Plus, Shield, Settings2 } from 'lucide-react'
import { useEffect, useState } from 'react'
import { supabase } from '@/lib/supabase'
import { CreateRoleModal } from '@/components/admin/create-role-modal'

export const Route = createFileRoute('/_app/admins/roles')({
  component: AdminRoles,
})

function AdminRoles() {
  const [roles, setRoles] = useState<any[]>([])
  const [loading, setLoading] = useState(true)
  const [modalOpen, setModalOpen] = useState(false)

  async function fetchRoles() {
    setLoading(true)
    try {
      const { data, error } = await supabase
        .from('roles')
        .select(`
          id,
          name,
          description,
          is_system_role,
          role_permissions (
            permissions (
              module,
              action
            )
          )
        `)
        .order('created_at', { ascending: true })

      if (error) throw error
      if (data) setRoles(data)
    } catch (error) {
      console.error('Error fetching roles:', error)
    } finally {
      setLoading(false)
    }
  }

  useEffect(() => {
    fetchRoles()
  }, [])

  return (
    <div className="space-y-6">
      <div className="flex justify-between items-center">
        <div>
          <h3 className="text-lg font-medium">Roles & Permissions</h3>
          <p className="text-sm text-muted-foreground">Define roles and their granular access permissions.</p>
        </div>
        <Button className="gap-2" onClick={() => setModalOpen(true)}>
          <Plus className="h-4 w-4" />
          Create Custom Role
        </Button>
      </div>

      <CreateRoleModal 
        open={modalOpen} 
        onOpenChange={setModalOpen} 
        onSuccess={fetchRoles} 
      />

      <div className="grid gap-6 md:grid-cols-2 lg:grid-cols-3">
        {loading ? (
          <p className="text-sm text-muted-foreground">Loading roles...</p>
        ) : (
          roles.map((role) => (
            <Card key={role.id} className="flex flex-col">
              <CardHeader className="pb-3">
                <div className="flex justify-between items-start">
                  <div className="flex items-center gap-2">
                    <Shield className="h-5 w-5 text-primary" />
                    <CardTitle className="text-base">{role.name}</CardTitle>
                  </div>
                  {role.is_system_role && (
                    <Badge variant="secondary" className="text-xs">System Default</Badge>
                  )}
                </div>
                <CardDescription className="line-clamp-2 mt-1">
                  {role.description}
                </CardDescription>
              </CardHeader>
              <CardContent className="flex-1">
                <div className="space-y-4">
                  <div>
                    <p className="text-sm font-medium mb-2">Key Permissions:</p>
                    <div className="flex flex-wrap gap-1.5">
                      {role.role_permissions?.slice(0, 5).map((rp: any, idx: number) => (
                        <Badge key={idx} variant="outline" className="bg-muted/50 font-normal">
                          {rp.permissions?.action}
                        </Badge>
                      ))}
                      {(role.role_permissions?.length || 0) > 5 && (
                        <Badge variant="outline" className="bg-muted/50 font-normal">
                          +{(role.role_permissions?.length || 0) - 5} more
                        </Badge>
                      )}
                      {(role.role_permissions?.length || 0) === 0 && (
                        <span className="text-sm text-muted-foreground">No specific permissions set.</span>
                      )}
                    </div>
                  </div>
                </div>
              </CardContent>
              <div className="p-4 pt-0 mt-auto">
                <Button variant="outline" className="w-full gap-2">
                  <Settings2 className="h-4 w-4" />
                  Manage Role
                </Button>
              </div>
            </Card>
          ))
        )}
      </div>
    </div>
  )
}
