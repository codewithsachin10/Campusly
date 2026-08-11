import { useState, useEffect } from "react"
import { Dialog, DialogContent, DialogHeader, DialogTitle, DialogDescription, DialogFooter } from "@/components/ui/dialog"
import { Button } from "@/components/ui/button"
import { Input } from "@/components/ui/input"
import { Label } from "@/components/ui/label"
import { toast } from "sonner"
import { Loader2 } from "lucide-react"
import { updateAdminProfileFn } from "@/lib/admin-actions"

interface EditAdminModalProps {
  open: boolean
  onOpenChange: (open: boolean) => void
  admin: any
  onSuccess: () => void
}

export function EditAdminModal({ open, onOpenChange, admin, onSuccess }: EditAdminModalProps) {
  const [loading, setLoading] = useState(false)
  
  // Form State
  const [fullName, setFullName] = useState("")
  const [phone, setPhone] = useState("")
  const [staffId, setStaffId] = useState("")
  const [department, setDepartment] = useState("")
  const [designation, setDesignation] = useState("")

  useEffect(() => {
    if (open && admin) {
      setFullName(admin.full_name || "")
      setPhone(admin.phone || "")
      setStaffId(admin.staff_id || "")
      setDepartment(admin.department || "")
      setDesignation(admin.designation || "")
    }
  }, [open, admin])

  const validate = () => {
    if (!fullName.trim() || !staffId.trim() || !department.trim() || !designation.trim()) {
      toast.error("Please fill in all required fields")
      return false
    }
    return true
  }

  const handleSubmit = async () => {
    if (!validate()) return

    setLoading(true)
    try {
      await updateAdminProfileFn({
        data: {
          adminId: admin.id,
          fullName,
          phone,
          staffId,
          department,
          designation
        }
      })
      
      toast.success("Administrator profile updated successfully!")
      onSuccess()
      onOpenChange(false)
    } catch (err: any) {
      console.error(err)
      toast.error(err.message || "Failed to update administrator profile")
    } finally {
      setLoading(false)
    }
  }

  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent className="sm:max-w-[500px]">
        <DialogHeader>
          <DialogTitle>Edit Administrator Profile</DialogTitle>
          <DialogDescription>
            Update personal details and identification information.
          </DialogDescription>
        </DialogHeader>

        <div className="py-4">
          <div className="grid grid-cols-2 gap-4">
            <div className="grid gap-2">
              <Label>Full Name <span className="text-destructive">*</span></Label>
              <Input placeholder="e.g. Arun Kumar" value={fullName} onChange={e => setFullName(e.target.value)} />
            </div>
            <div className="grid gap-2">
              <Label>Phone Number</Label>
              <Input placeholder="+91 9876543210" value={phone} onChange={e => setPhone(e.target.value)} />
            </div>
            <div className="grid gap-2">
              <Label>Staff ID <span className="text-destructive">*</span></Label>
              <Input placeholder="e.g. REC12345" value={staffId} onChange={e => setStaffId(e.target.value)} />
            </div>
            <div className="grid gap-2">
              <Label>Department <span className="text-destructive">*</span></Label>
              <Input placeholder="e.g. CSE" value={department} onChange={e => setDepartment(e.target.value)} />
            </div>
            <div className="grid gap-2 col-span-2">
              <Label>Designation <span className="text-destructive">*</span></Label>
              <Input placeholder="e.g. Assistant Professor" value={designation} onChange={e => setDesignation(e.target.value)} />
            </div>
          </div>
        </div>

        <DialogFooter>
          <Button variant="outline" onClick={() => onOpenChange(false)} disabled={loading}>
            Cancel
          </Button>
          <Button onClick={handleSubmit} disabled={loading}>
            {loading && <Loader2 className="mr-2 h-4 w-4 animate-spin" />}
            Save Changes
          </Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  )
}
