import { useState, useEffect } from "react"
import { Dialog, DialogContent, DialogHeader, DialogTitle, DialogDescription, DialogFooter } from "@/components/ui/dialog"
import { Button } from "@/components/ui/button"
import { Input } from "@/components/ui/input"
import { Label } from "@/components/ui/label"
import { Textarea } from "@/components/ui/textarea"
import { Checkbox } from "@/components/ui/checkbox"
import { supabase } from "@/lib/supabase"
import { toast } from "sonner"
import { Loader2 } from "lucide-react"

interface CreateRoleModalProps {
  open: boolean
  onOpenChange: (open: boolean) => void
  onSuccess: () => void
}

export function CreateRoleModal({ open, onOpenChange, onSuccess }: CreateRoleModalProps) {
  const [loading, setLoading] = useState(false)
  const [permissions, setPermissions] = useState<any[]>([])
  
  // Form State
  const [name, setName] = useState("")
  const [description, setDescription] = useState("")
  const [selectedPermissions, setSelectedPermissions] = useState<string[]>([])

  useEffect(() => {
    if (open) {
      setName("")
      setDescription("")
      setSelectedPermissions([])
      fetchPermissions()
    }
  }, [open])

  async function fetchPermissions() {
    try {
      const { data, error } = await supabase.from('permissions').select('id, module, action, description').order('module')
      if (error) throw error
      if (data) setPermissions(data)
    } catch (err: any) {
      toast.error("Failed to load permissions: " + err.message)
    }
  }

  // Group permissions by module
  const groupedPermissions = permissions.reduce((acc, curr) => {
    if (!acc[curr.module]) acc[curr.module] = []
    acc[curr.module].push(curr)
    return acc
  }, {} as Record<string, any[]>)

  const togglePermission = (id: string) => {
    setSelectedPermissions(prev => 
      prev.includes(id) ? prev.filter(p => p !== id) : [...prev, id]
    )
  }

  const handleSubmit = async () => {
    if (!name.trim()) {
      toast.error("Role Name is required")
      return
    }

    setLoading(true)
    try {
      // 1. Create Role
      const { data: newRole, error: roleError } = await supabase.from('roles').insert({
        name,
        description,
        is_system_role: false
      }).select().single()

      if (roleError) {
        if (roleError.code === '23505') throw new Error('A role with this name already exists.')
        throw roleError
      }

      // 2. Assign Permissions
      if (selectedPermissions.length > 0 && newRole) {
        const rolePermissions = selectedPermissions.map(permId => ({
          role_id: newRole.id,
          permission_id: permId
        }))

        const { error: permError } = await supabase.from('role_permissions').insert(rolePermissions)
        if (permError) throw permError
      }

      toast.success("Custom role created successfully!")
      onSuccess()
      onOpenChange(false)
    } catch (err: any) {
      console.error(err)
      toast.error(err.message || "Failed to create role")
    } finally {
      setLoading(false)
    }
  }

  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent className="sm:max-w-[600px] max-h-[85vh] flex flex-col">
        <DialogHeader>
          <DialogTitle>Create Custom Role</DialogTitle>
          <DialogDescription>
            Define a new role and configure its specific access permissions.
          </DialogDescription>
        </DialogHeader>

        <div className="grid gap-4 py-4 overflow-y-auto pr-2">
          <div className="grid gap-2">
            <Label htmlFor="roleName">Role Name <span className="text-destructive">*</span></Label>
            <Input 
              id="roleName" 
              placeholder="e.g. Content Moderator" 
              value={name}
              onChange={e => setName(e.target.value)}
            />
          </div>
          <div className="grid gap-2">
            <Label htmlFor="roleDescription">Description</Label>
            <Textarea 
              id="roleDescription" 
              placeholder="Briefly describe what this role can do..." 
              value={description}
              onChange={e => setDescription(e.target.value)}
            />
          </div>

          <div className="mt-4">
            <Label className="text-base">Permissions</Label>
            <p className="text-sm text-muted-foreground mb-4">Select the specific actions this role is allowed to perform.</p>
            
            <div className="space-y-6">
              {Object.entries(groupedPermissions).map(([moduleName, perms]) => (
                <div key={moduleName} className="space-y-3">
                  <h4 className="font-medium text-sm text-primary uppercase tracking-wider">{moduleName}</h4>
                  <div className="grid gap-3 sm:grid-cols-2">
                    {perms.map(p => (
                      <div key={p.id} className="flex flex-row items-start space-x-3 space-y-0 rounded-md border p-3">
                        <Checkbox 
                          id={p.id} 
                          checked={selectedPermissions.includes(p.id)}
                          onCheckedChange={() => togglePermission(p.id)}
                        />
                        <div className="space-y-1 leading-none">
                          <Label htmlFor={p.id} className="font-medium cursor-pointer">
                            {p.action}
                          </Label>
                          <p className="text-xs text-muted-foreground">
                            {p.description}
                          </p>
                        </div>
                      </div>
                    ))}
                  </div>
                </div>
              ))}
            </div>
          </div>
        </div>

        <DialogFooter className="mt-2">
          <Button variant="outline" onClick={() => onOpenChange(false)} disabled={loading}>Cancel</Button>
          <Button onClick={handleSubmit} disabled={loading}>
            {loading && <Loader2 className="mr-2 h-4 w-4 animate-spin" />}
            Create Role
          </Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  )
}
