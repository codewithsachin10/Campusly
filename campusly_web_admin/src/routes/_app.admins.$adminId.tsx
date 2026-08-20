import { createFileRoute } from '@tanstack/react-router'
import { Card, CardContent, CardHeader, CardTitle, CardDescription } from '@/components/ui/card'
import { Badge } from '@/components/ui/badge'
import { Button } from '@/components/ui/button'
import { ShieldCheck, Mail, Phone, Hash, Calendar, Building, PowerOff, UserCog, Send, Loader2 } from 'lucide-react'
import { useEffect, useState } from 'react'
import { supabase } from '@/lib/supabase'
import { toast } from 'sonner'
import { EditAdminModal } from '@/components/admin/edit-admin-modal'
import { resendAdminInvitationFn, approveAdminFn, resendWelcomeEmailFn } from '@/lib/admin-actions'
import { AlertDialog, AlertDialogAction, AlertDialogContent, AlertDialogDescription, AlertDialogFooter, AlertDialogHeader, AlertDialogTitle } from "@/components/ui/alert-dialog"
import { CheckCircle2 } from "lucide-react"

import { AssignRoleModal } from '@/components/admin/assign-role-modal'

export const Route = createFileRoute('/_app/admins/$adminId')({
  component: AdminDetails,
})

function AdminDetails() {
  const { adminId } = Route.useParams()
  const [admin, setAdmin] = useState<any>(null)
  const [loading, setLoading] = useState(true)
  const [isEditModalOpen, setIsEditModalOpen] = useState(false)
  const [isAssignRoleModalOpen, setIsAssignRoleModalOpen] = useState(false)
  const [resending, setResending] = useState(false)
  const [resendingWelcome, setResendingWelcome] = useState(false)
  const [approving, setApproving] = useState(false)
  const [showSuccessAlert, setShowSuccessAlert] = useState(false)
  const [showWelcomeAlert, setShowWelcomeAlert] = useState(false)
  const [showApproveAlert, setShowApproveAlert] = useState(false)

  const fetchAdminDetails = async () => {
    try {
      const { data, error } = await supabase
        .from('admin_profiles')
        .select(`
          *,
          roles (
            id,
            name,
            description
          )
        `)
        .eq('id', adminId)
        .single()

      if (error) throw error
      if (data) setAdmin(data)
    } catch (error) {
      console.error('Error fetching admin details:', error)
    } finally {
      setLoading(false)
    }
  }

  useEffect(() => {
    fetchAdminDetails()
  }, [adminId])

  const handleToggleSuspend = async () => {
    if (!admin) return
    try {
      const newStatus = admin.status === 'Suspended' ? 'Active' : 'Suspended'
      const { error } = await supabase
        .from('admin_profiles')
        .update({ status: newStatus })
        .eq('id', admin.id)
      
      if (error) throw error
      toast.success(`Administrator ${newStatus === 'Active' ? 'restored' : 'suspended'} successfully`)
      fetchAdminDetails()
    } catch (e: any) {
      toast.error(e.message || "Failed to update status")
    }
  }

  const handleResendCredentials = async () => {
    setResending(true)
    try {
      const result = await resendAdminInvitationFn({ data: { adminId: admin.id } })
      setShowSuccessAlert(true)
      if (result.testPassword) {
        toast.info(`Test Credentials in console! Password: ${result.testPassword}`)
        console.log("TEST CREDENTIALS:", result)
      }
      fetchAdminDetails()
    } catch (e: any) {
      toast.error(e.message || "Failed to resend credentials")
    } finally {
      setResending(false)
    }
  }

  const handleResendWelcomeEmail = async () => {
    setResendingWelcome(true)
    try {
      await resendWelcomeEmailFn({ data: { adminId: admin.id } })
      setShowWelcomeAlert(true)
    } catch (e: any) {
      toast.error(e.message || "Failed to resend invitation email")
    } finally {
      setResendingWelcome(false)
    }
  }

  const handleApproveAdmin = async () => {
    setApproving(true)
    try {
      const result = await approveAdminFn({ data: { adminId: admin.id } })
      setShowApproveAlert(true)
      if (result.testPassword) {
        toast.info(`Test Credentials in console! Password: ${result.testPassword}`)
        console.log("TEST CREDENTIALS:", result)
      }
      fetchAdminDetails()
    } catch (e: any) {
      toast.error(e.message || "Failed to approve administrator")
    } finally {
      setApproving(false)
    }
  }

  if (loading) return <div>Loading administrator details...</div>
  if (!admin) return <div>Administrator not found.</div>

  const getStatusColor = (status: string) => {
    switch (status) {
      case 'Active': return 'bg-emerald-500/10 text-emerald-500 border-emerald-500/20'
      case 'Accepted': return 'bg-blue-500/10 text-blue-500 border-blue-500/20'
      case 'Pending_Verification': return 'bg-amber-500/10 text-amber-500 border-amber-500/20'
      case 'Suspended': return 'bg-rose-500/10 text-rose-500 border-rose-500/20'
      case 'Rejected': return 'bg-red-500/10 text-red-500 border-red-500/20'
      case 'Invited': return 'bg-purple-500/10 text-purple-500 border-purple-500/20'
      default: return 'bg-slate-500/10 text-slate-500 border-slate-500/20'
    }
  }

  return (
    <div className="space-y-6 max-w-5xl">
      <div className="flex flex-col sm:flex-row gap-4 items-start sm:items-center justify-between">
        <div className="flex items-center gap-4">
          <div className="flex h-16 w-16 items-center justify-center rounded-full bg-primary/10 text-2xl font-bold text-primary">
            {admin.full_name?.charAt(0)}
          </div>
          <div>
            <h2 className="text-2xl font-semibold tracking-tight">{admin.full_name}</h2>
            <div className="flex items-center gap-2 mt-1">
              <Badge variant="outline" className={getStatusColor(admin.status)}>
                {admin.status}
              </Badge>
              <span className="text-sm text-muted-foreground">ID: {admin.id.substring(0, 8)}...</span>
            </div>
          </div>
        </div>
        
        <div className="flex items-center gap-2">
          <Button variant="outline" className="gap-2" onClick={() => setIsEditModalOpen(true)}>
            <UserCog className="h-4 w-4" />
            Edit Profile
          </Button>
          {admin.status === 'Active' ? (
            <Button variant="destructive" className="gap-2" onClick={handleToggleSuspend}>
              <PowerOff className="h-4 w-4" />
              Suspend Access
            </Button>
          ) : (
            <Button variant="default" className="gap-2 bg-emerald-600 hover:bg-emerald-700" onClick={handleToggleSuspend}>
              <PowerOff className="h-4 w-4" />
              Restore Access
            </Button>
          )}
        </div>
      </div>

      <div className="grid gap-6 md:grid-cols-2">
        <Card>
          <CardHeader>
            <CardTitle className="text-lg">Personal Information</CardTitle>
          </CardHeader>
          <CardContent className="space-y-4">
            <div className="grid grid-cols-2 gap-4">
              <div className="space-y-1">
                <span className="text-sm text-muted-foreground flex items-center gap-1.5"><Mail className="h-3.5 w-3.5"/> Email</span>
                <p className="font-medium">{admin.email}</p>
              </div>
              <div className="space-y-1">
                <span className="text-sm text-muted-foreground flex items-center gap-1.5"><Phone className="h-3.5 w-3.5"/> Phone</span>
                <p className="font-medium">{admin.phone || 'Not provided'}</p>
              </div>
              <div className="space-y-1">
                <span className="text-sm text-muted-foreground flex items-center gap-1.5"><Hash className="h-3.5 w-3.5"/> Employee ID</span>
                <p className="font-medium">{admin.staff_id || 'Not assigned'}</p>
              </div>
              <div className="space-y-1">
                <span className="text-sm text-muted-foreground flex items-center gap-1.5"><Calendar className="h-3.5 w-3.5"/> Joined</span>
                <p className="font-medium">{new Date(admin.created_at).toLocaleDateString()}</p>
              </div>
            </div>
          </CardContent>
        </Card>

        <Card>
          <CardHeader className="flex flex-row items-center justify-between pb-2">
            <CardTitle className="text-lg">Access & Role</CardTitle>
            <Button variant="outline" size="sm" onClick={() => setIsAssignRoleModalOpen(true)}>
              Assign Role
            </Button>
          </CardHeader>
          <CardContent className="space-y-4">
            <div className="rounded-md border p-4 bg-muted/20">
              <div className="flex items-start gap-3">
                <ShieldCheck className="h-5 w-5 text-primary mt-0.5" />
                <div>
                  <h4 className="font-medium">{(admin.roles as any)?.name || 'No Role Assigned'}</h4>
                  <p className="text-sm text-muted-foreground mt-1">
                    {(admin.roles as any)?.description || 'No description available for this role.'}
                  </p>
                </div>
              </div>
            </div>

            <div className="space-y-2">
              <h4 className="text-sm font-medium">Assigned Scopes</h4>
              <div className="flex flex-wrap gap-2">
                <Badge variant="secondary" className="gap-1.5">
                  <Building className="h-3 w-3" />
                  All Departments (Global)
                </Badge>
              </div>
              <p className="text-xs text-muted-foreground mt-2">
                This administrator has global scope across the platform.
              </p>
            </div>
          </CardContent>
        </Card>

        <Card className="md:col-span-2">
          <CardHeader>
            <CardTitle className="text-lg">Verification Timeline</CardTitle>
            <CardDescription>Status and progress of this administrator's account.</CardDescription>
          </CardHeader>
          <CardContent>
            <div className="relative border-l border-muted-foreground/20 ml-3 md:ml-4 space-y-6 pb-2">
              {/* Step 1: Invited */}
              <div className="relative pl-6">
                <div className="absolute -left-1.5 top-1 h-3 w-3 rounded-full border-2 border-background bg-primary"></div>
                <div className="flex flex-col sm:flex-row sm:justify-between sm:items-center">
                  <div>
                    <p className="font-medium text-sm">Administrator Invited</p>
                    <p className="text-xs text-muted-foreground">Account was created and invitation email was sent.</p>
                  </div>
                  <div className="flex flex-col sm:items-end gap-1 mt-2 sm:mt-0">
                    <span className="text-xs text-muted-foreground">{new Date(admin.created_at).toLocaleString()}</span>
                    {admin.status === 'Invited' && (
                      <Button variant="outline" size="sm" onClick={handleResendWelcomeEmail} disabled={resendingWelcome}>
                        {resendingWelcome ? <Loader2 className="mr-2 h-3 w-3 animate-spin" /> : <Send className="mr-2 h-3 w-3" />}
                        Resend Invitation Email
                      </Button>
                    )}
                  </div>
                </div>
              </div>
              
              {/* Step 2: Accepted / Rejected */}
              <div className="relative pl-6">
                <div className={`absolute -left-1.5 top-1 h-3 w-3 rounded-full border-2 border-background ${['Accepted', 'Rejected', 'Pending_Verification', 'Active'].includes(admin.status) ? 'bg-primary' : 'bg-muted-foreground/30'}`}></div>
                <div className="flex flex-col sm:flex-row sm:justify-between sm:items-center">
                  <div>
                    <p className={`font-medium text-sm ${['Accepted', 'Rejected', 'Pending_Verification', 'Active'].includes(admin.status) ? '' : 'text-muted-foreground'}`}>Invitation Response</p>
                    <p className="text-xs text-muted-foreground">
                      {admin.status === 'Accepted' || admin.status === 'Pending_Verification' || admin.status === 'Active' ? 'Administrator accepted the invitation.' : 
                       admin.status === 'Rejected' ? 'Administrator rejected the invitation.' : 
                       'Waiting for administrator to accept or reject the invitation.'}
                    </p>
                  </div>
                  <div className="mt-2 sm:mt-0">
                    {admin.status === 'Accepted' && (
                      <div className="flex flex-col gap-2 items-end">
                        <span className="text-xs text-amber-600 font-medium">Action Required: Approve this account</span>
                        <Button variant="default" size="sm" onClick={handleApproveAdmin} disabled={approving}>
                          {approving ? <Loader2 className="mr-2 h-3 w-3 animate-spin" /> : <ShieldCheck className="mr-2 h-3 w-3" />}
                          Approve Administrator
                        </Button>
                      </div>
                    )}
                    {admin.status === 'Rejected' && <Badge variant="outline" className="bg-red-500/10 text-red-500 border-red-500/20">Rejected</Badge>}
                  </div>
                </div>
              </div>

              {/* Step 3: Verification */}
              <div className="relative pl-6">
                <div className={`absolute -left-1.5 top-1 h-3 w-3 rounded-full border-2 border-background ${admin.status === 'Active' ? 'bg-primary' : 'bg-muted-foreground/30'}`}></div>
                <div className="flex flex-col sm:flex-row sm:justify-between sm:items-center">
                  <div>
                    <p className={`font-medium text-sm ${admin.status === 'Active' ? '' : 'text-muted-foreground'}`}>Account Verification</p>
                    <p className="text-xs text-muted-foreground">
                      {admin.status === 'Active' ? 'Administrator successfully verified their email and OTP.' : 
                       admin.status === 'Pending_Verification' ? 'Credentials sent. Waiting for administrator to login and verify.' :
                       'Locked until administrator is approved.'}
                    </p>
                  </div>
                  <div className="mt-2 sm:mt-0">
                    {admin.status === 'Pending_Verification' && (
                      <Button variant="outline" size="sm" onClick={handleResendCredentials} disabled={resending}>
                        {resending ? <Loader2 className="mr-2 h-3 w-3 animate-spin" /> : <Send className="mr-2 h-3 w-3" />}
                        Resend Credentials Email
                      </Button>
                    )}
                    {admin.status === 'Active' && <Badge variant="outline" className="bg-emerald-500/10 text-emerald-500 border-emerald-500/20">Verified</Badge>}
                  </div>
                </div>
              </div>
            </div>
          </CardContent>
        </Card>
      </div>

      <EditAdminModal
        open={isEditModalOpen}
        onOpenChange={setIsEditModalOpen}
        admin={admin}
        onSuccess={fetchAdminDetails}
      />

      <AssignRoleModal
        open={isAssignRoleModalOpen}
        onOpenChange={setIsAssignRoleModalOpen}
        admin={admin}
        onSuccess={fetchAdminDetails}
      />

      <AlertDialog open={showSuccessAlert} onOpenChange={setShowSuccessAlert}>
        <AlertDialogContent className="sm:max-w-md">
          <AlertDialogHeader>
            <AlertDialogTitle className="flex items-center gap-2">
              <CheckCircle2 className="h-5 w-5 text-emerald-500" />
              Credentials Sent Successfully
            </AlertDialogTitle>
            <AlertDialogDescription>
              The credentials email has been successfully sent to <span className="font-medium text-foreground">{admin.email}</span>.
            </AlertDialogDescription>
          </AlertDialogHeader>
          <AlertDialogFooter>
            <AlertDialogAction onClick={() => setShowSuccessAlert(false)}>
              Acknowledge
            </AlertDialogAction>
          </AlertDialogFooter>
        </AlertDialogContent>
      </AlertDialog>

      <AlertDialog open={showWelcomeAlert} onOpenChange={setShowWelcomeAlert}>
        <AlertDialogContent className="sm:max-w-md">
          <AlertDialogHeader>
            <AlertDialogTitle className="flex items-center gap-2">
              <CheckCircle2 className="h-5 w-5 text-emerald-500" />
              Invitation Sent Successfully
            </AlertDialogTitle>
            <AlertDialogDescription>
              The invitation email has been successfully resent to <span className="font-medium text-foreground">{admin.email}</span>.
            </AlertDialogDescription>
          </AlertDialogHeader>
          <AlertDialogFooter>
            <AlertDialogAction onClick={() => setShowWelcomeAlert(false)}>
              Acknowledge
            </AlertDialogAction>
          </AlertDialogFooter>
        </AlertDialogContent>
      </AlertDialog>

      <AlertDialog open={showApproveAlert} onOpenChange={setShowApproveAlert}>
        <AlertDialogContent className="sm:max-w-md">
          <AlertDialogHeader>
            <AlertDialogTitle className="flex items-center gap-2">
              <CheckCircle2 className="h-5 w-5 text-emerald-500" />
              Administrator Approved
            </AlertDialogTitle>
            <AlertDialogDescription>
              The administrator has been successfully approved and the login credentials email has been dispatched to <span className="font-medium text-foreground">{admin.email}</span>.
            </AlertDialogDescription>
          </AlertDialogHeader>
          <AlertDialogFooter>
            <AlertDialogAction onClick={() => setShowApproveAlert(false)}>
              Acknowledge
            </AlertDialogAction>
          </AlertDialogFooter>
        </AlertDialogContent>
      </AlertDialog>
    </div>
  )
}
