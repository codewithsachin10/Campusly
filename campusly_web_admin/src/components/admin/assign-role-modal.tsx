import { useState, useEffect } from "react"
import { Dialog, DialogContent, DialogHeader, DialogTitle, DialogDescription, DialogFooter } from "@/components/ui/dialog"
import { Button } from "@/components/ui/button"
import { Label } from "@/components/ui/label"
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select"
import { toast } from "sonner"
import { Loader2 } from "lucide-react"
import { supabase } from "@/lib/supabase"
import { updateAdminRoleFn } from "@/lib/admin-actions"

interface AssignRoleModalProps {
  open: boolean
  onOpenChange: (open: boolean) => void
  admin: any
  onSuccess: () => void
}

export function AssignRoleModal({ open, onOpenChange, admin, onSuccess }: AssignRoleModalProps) {
  const [loading, setLoading] = useState(false)
  const [roles, setRoles] = useState<any[]>([])
  const [roleId, setRoleId] = useState("")

  useEffect(() => {
    if (open) {
      fetchRoles()
      if (admin?.role_id) {
        setRoleId(admin.role_id)
      }
    }
  }, [open, admin])

  async function fetchRoles() {
    try {
      const { data, error } = await supabase.from('roles').select('id, name')
      if (error) throw error
      if (data) setRoles(data)
    } catch (err: any) {
      toast.error("Failed to load roles: " + err.message)
    }
  }

  const handleSubmit = async () => {
    if (!roleId) return toast.error("Please select a role")

    setLoading(true)
    try {
      await updateAdminRoleFn({
        data: {
          adminId: admin.id,
          roleId: roleId
        }
      })
      
      toast.success("Administrator role updated successfully!")
      onSuccess()
      onOpenChange(false)
    } catch (err: any) {
      console.error(err)
      toast.error(err.message || "Failed to update role")
    } finally {
      setLoading(false)
    }
  }

  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent className="sm:max-w-[425px]">
        <DialogHeader>
          <DialogTitle>Assign Role</DialogTitle>
          <DialogDescription>
            Change the access level and permissions for {admin?.full_name}.
          </DialogDescription>
        </DialogHeader>

        <div className="py-4">
          <div className="grid gap-2">
            <Label>Select Role <span className="text-destructive">*</span></Label>
            <Select value={roleId} onValueChange={setRoleId}>
              <SelectTrigger>
                <SelectValue placeholder="Select a role" />
              </SelectTrigger>
              <SelectContent>
                {roles.map(r => (
                  <SelectItem key={r.id} value={r.id}>{r.name}</SelectItem>
                ))}
              </SelectContent>
            </Select>
          </div>
        </div>

        <DialogFooter>
          <Button variant="outline" onClick={() => onOpenChange(false)} disabled={loading}>
            Cancel
          </Button>
          <Button onClick={handleSubmit} disabled={loading}>
            {loading && <Loader2 className="mr-2 h-4 w-4 animate-spin" />}
            Save Role
          </Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  )
}
