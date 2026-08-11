import { useState, useEffect } from "react"
import { Dialog, DialogContent, DialogHeader, DialogTitle, DialogDescription, DialogFooter } from "@/components/ui/dialog"
import { Button } from "@/components/ui/button"
import { Input } from "@/components/ui/input"
import { Label } from "@/components/ui/label"
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select"
import { supabase } from "@/lib/supabase"
import { toast } from "sonner"
import { Loader2, ShieldCheck, Mail, Building, MapPin } from "lucide-react"
import { createAdminFn } from "@/lib/admin-actions"
import { Badge } from "@/components/ui/badge"
import { AlertDialog, AlertDialogAction, AlertDialogContent, AlertDialogDescription, AlertDialogFooter, AlertDialogHeader, AlertDialogTitle } from "@/components/ui/alert-dialog"
import { CheckCircle2 } from "lucide-react"

interface AddAdminModalProps {
  open: boolean
  onOpenChange: (open: boolean) => void
  onSuccess: () => void
}

export function AddAdminModal({ open, onOpenChange, onSuccess }: AddAdminModalProps) {
  const [step, setStep] = useState(1)
  const [loading, setLoading] = useState(false)
  const [roles, setRoles] = useState<any[]>([])
  const [showSuccessAlert, setShowSuccessAlert] = useState(false)
  const [sentEmail, setSentEmail] = useState("")
  
  // Form State - Step 1
  const [fullName, setFullName] = useState("")
  const [email, setEmail] = useState("")
  const [staffId, setStaffId] = useState("")
  const [phone, setPhone] = useState("")
  const [department, setDepartment] = useState("")
  const [designation, setDesignation] = useState("")
  
  // Form State - Step 2
  const [roleId, setRoleId] = useState("")

  useEffect(() => {
    if (open) {
      const draft = localStorage.getItem('adminDraft')
      if (draft) {
        try {
          const parsed = JSON.parse(draft)
          setStep(parsed.step || 1)
          setFullName(parsed.fullName || "")
          setEmail(parsed.email || "")
          setStaffId(parsed.staffId || "")
          setPhone(parsed.phone || "")
          setDepartment(parsed.department || "")
          setDesignation(parsed.designation || "")
          setRoleId(parsed.roleId || "")
        } catch (e) {
          // ignore
        }
      } else {
        setStep(1)
        setFullName("")
        setEmail("")
        setStaffId("")
        setPhone("")
        setDepartment("")
        setDesignation("")
        setRoleId("")
      }
      fetchRoles()
    }
  }, [open])

  const handleSaveDraft = () => {
    localStorage.setItem('adminDraft', JSON.stringify({
      step, fullName, email, staffId, phone, department, designation, roleId
    }))
    toast.success("Saved as draft")
    onOpenChange(false)
  }

  async function fetchRoles() {
    try {
      const { data, error } = await supabase.from('roles').select('id, name, role_permissions(permissions(action))')
      if (error) throw error
      if (data) setRoles(data)
    } catch (err: any) {
      toast.error("Failed to load roles: " + err.message)
    }
  }

  const validateStep1 = () => {
    if (!fullName.trim() || !email.trim() || !staffId.trim() || !department.trim() || !designation.trim()) {
      toast.error("Please fill in all required fields")
      return false
    }
    // Basic email format validation
    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/
    if (!emailRegex.test(email.trim())) {
      toast.error("Please enter a valid email address")
      return false
    }
    return true
  }

  const handleNext = () => {
    if (step === 1 && validateStep1()) setStep(2)
    else if (step === 2) {
      if (!roleId) return toast.error("Please select a role")
      setStep(3)
    }
  }

  const handleSubmit = async () => {
    setLoading(true)
    try {
      const result = await createAdminFn({
        data: {
          fullName,
          email,
          staffId,
          department,
          designation,
          roleId
        }
      })
      
      toast.success("Administrator invited successfully!")
      localStorage.removeItem('adminDraft')
      
      setSentEmail(email) // store for alert dialog
      
      if (result.testPassword) {
        console.log("TEST CREDENTIALS:", { password: result.testPassword, otp: result.testOtp })
        toast.info(`Test Credentials in console! Password: ${result.testPassword}`)
      }
      
      onSuccess()
      onOpenChange(false) // Close main dialog
      setShowSuccessAlert(true) // Open success alert
    } catch (err: any) {
      console.error(err)
      toast.error(err.message || "Failed to add administrator")
    } finally {
      setLoading(false)
    }
  }

  const selectedRoleData = roles.find(r => r.id === roleId)

  return (
    <>
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent className="sm:max-w-[550px]">
        <DialogHeader>
          <DialogTitle>Add Administrator</DialogTitle>
          <DialogDescription>
            {step === 1 && "Step 1: Enter basic details"}
            {step === 2 && "Step 2: Assign a role"}
            {step === 3 && "Step 3: Review and send invitation"}
          </DialogDescription>
        </DialogHeader>

        <div className="py-4 max-h-[60vh] overflow-y-auto px-1">
          {step === 1 && (
            <div className="grid grid-cols-2 gap-4">
              <div className="grid gap-2">
                <Label>Full Name <span className="text-destructive">*</span></Label>
                <Input placeholder="e.g. Arun Kumar" value={fullName} onChange={e => setFullName(e.target.value)} />
              </div>
              <div className="grid gap-2">
                <Label>Email Address <span className="text-destructive">*</span></Label>
                <Input type="email" placeholder="arun@college.edu.in" value={email} onChange={e => setEmail(e.target.value)} />
              </div>
              <div className="grid gap-2">
                <Label>Staff ID <span className="text-destructive">*</span></Label>
                <Input placeholder="e.g. REC12345" value={staffId} onChange={e => setStaffId(e.target.value)} />
              </div>
              <div className="grid gap-2">
                <Label>Phone Number</Label>
                <Input placeholder="+91 9876543210" value={phone} onChange={e => setPhone(e.target.value)} />
              </div>
              <div className="grid gap-2">
                <Label>Department <span className="text-destructive">*</span></Label>
                <Input placeholder="e.g. CSE" value={department} onChange={e => setDepartment(e.target.value)} />
              </div>
              <div className="grid gap-2">
                <Label>Designation <span className="text-destructive">*</span></Label>
                <Input placeholder="e.g. Assistant Professor" value={designation} onChange={e => setDesignation(e.target.value)} />
              </div>
            </div>
          )}

          {step === 2 && (
            <div className="grid gap-4">
              <div className="bg-amber-500/10 text-amber-600 p-3 rounded-md text-sm border border-amber-500/20">
                <strong>Tip:</strong> For most admins, we recommend the <strong>Department Admin</strong> role rather than giving everyone Super Admin access.
              </div>
              <div className="grid gap-2">
                <Label>Assign Role <span className="text-destructive">*</span></Label>
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
          )}

          {step === 3 && (
            <div className="space-y-4">
              <div className="bg-muted p-4 rounded-lg border space-y-3">
                <h4 className="font-semibold text-sm uppercase tracking-wider text-muted-foreground mb-2">Administrator Summary</h4>
                
                <div className="grid grid-cols-2 gap-4 text-sm">
                  <div><span className="text-muted-foreground block text-xs">Name</span><span className="font-medium">{fullName}</span></div>
                  <div><span className="text-muted-foreground block text-xs">Email</span><span className="font-medium">{email}</span></div>
                  <div><span className="text-muted-foreground block text-xs">Department</span><span>{department}</span></div>
                  <div><span className="text-muted-foreground block text-xs">Role</span><Badge variant="outline" className="bg-primary/10 text-primary border-primary/20">{selectedRoleData?.name}</Badge></div>
                </div>

                <div className="pt-3 mt-3 border-t">
                  <span className="text-muted-foreground block text-xs mb-1">Key Permissions</span>
                  <div className="flex flex-wrap gap-1">
                    {selectedRoleData?.role_permissions?.slice(0, 5).map((rp: any, i: number) => (
                      <Badge key={i} variant="secondary" className="text-[10px]">{rp.permissions?.action}</Badge>
                    ))}
                    {(selectedRoleData?.role_permissions?.length || 0) > 5 && (
                      <Badge variant="secondary" className="text-[10px]">+ more</Badge>
                    )}
                  </div>
                </div>
              </div>
              <p className="text-xs text-muted-foreground text-center">
                Clicking the button below will send an invitation to {email} to join.
              </p>
            </div>
          )}
        </div>

        <DialogFooter className="flex w-full justify-between sm:justify-between items-center mt-4">
          <div className="flex items-center gap-4">
            <div className="flex gap-1">
              {[1, 2, 3].map(i => (
                <div key={i} className={`h-2 w-8 rounded-full ${step >= i ? 'bg-primary' : 'bg-muted'}`} />
              ))}
            </div>
            <Button variant="ghost" size="sm" onClick={handleSaveDraft} className="text-xs h-8 text-muted-foreground hover:text-foreground">Save Draft</Button>
          </div>
          <div className="flex gap-2">
            {step > 1 && <Button variant="outline" onClick={() => setStep(s => s - 1)} disabled={loading}>Back</Button>}
            {step < 3 ? (
              <Button onClick={handleNext}>Next</Button>
            ) : (
              <Button onClick={handleSubmit} disabled={loading}>
                {loading && <Loader2 className="mr-2 h-4 w-4 animate-spin" />}
                Create & Send Invitation
              </Button>
            )}
          </div>
        </DialogFooter>
      </DialogContent>
    </Dialog>
    
    <AlertDialog open={showSuccessAlert} onOpenChange={setShowSuccessAlert}>
      <AlertDialogContent className="sm:max-w-md">
        <AlertDialogHeader>
          <AlertDialogTitle className="flex items-center gap-2">
            <CheckCircle2 className="h-5 w-5 text-emerald-500" />
            Email Sent Successfully
          </AlertDialogTitle>
          <AlertDialogDescription>
            The invitation email has been successfully sent to <span className="font-medium text-foreground">{sentEmail}</span>.
          </AlertDialogDescription>
        </AlertDialogHeader>
        <AlertDialogFooter>
          <AlertDialogAction onClick={() => setShowSuccessAlert(false)}>
            Done
          </AlertDialogAction>
        </AlertDialogFooter>
      </AlertDialogContent>
    </AlertDialog>
    </>
  )
}
