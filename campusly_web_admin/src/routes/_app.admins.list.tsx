import { createFileRoute } from '@tanstack/react-router'
import { Card } from '@/components/ui/card'
import { Button } from '@/components/ui/button'
import { Plus, Search, Filter, MoreHorizontal, ShieldCheck, Mail, Clock } from 'lucide-react'
import { Input } from '@/components/ui/input'
import { Badge } from '@/components/ui/badge'
import { useEffect, useState } from 'react'
import { supabase } from '@/lib/supabase'
import { useRouter } from '@tanstack/react-router'
import { toast } from 'sonner'
import { AddAdminModal } from '@/components/admin/add-admin-modal'
import { 
  DropdownMenu, 
  DropdownMenuContent, 
  DropdownMenuItem, 
  DropdownMenuLabel, 
  DropdownMenuSeparator, 
  DropdownMenuTrigger 
} from '@/components/ui/dropdown-menu'
import { resendAdminInvitationFn, resendWelcomeEmailFn } from '@/lib/admin-actions'
import { AlertDialog, AlertDialogAction, AlertDialogContent, AlertDialogDescription, AlertDialogFooter, AlertDialogHeader, AlertDialogTitle } from "@/components/ui/alert-dialog"
import { CheckCircle2, Loader2 } from "lucide-react"

export const Route = createFileRoute('/_app/admins/list')({
  component: AdminsList,
})

function AdminsList() {
  const [admins, setAdmins] = useState<any[]>([])
  const [loading, setLoading] = useState(true)
  const [search, setSearch] = useState('')
  const [modalOpen, setModalOpen] = useState(false)
  const [resendingId, setResendingId] = useState<string | null>(null)
  const [showSuccessAlert, setShowSuccessAlert] = useState(false)
  const [sentEmail, setSentEmail] = useState("")
  const router = useRouter()

  async function fetchAdmins() {
    setLoading(true)
    try {
      const { data, error } = await supabase
        .from('admin_profiles')
        .select(`
          id,
          full_name,
          email,
          status,
          designation,
          last_active_at,
          roles (
            name
          )
        `)
        .order('created_at', { ascending: false })

      if (error) throw error
      if (data) setAdmins(data)
    } catch (error) {
      console.error('Error fetching admins:', error)
    } finally {
      setLoading(false)
    }
  }

  useEffect(() => {
    fetchAdmins()
  }, [])

  const getStatusColor = (status: string) => {
    switch (status) {
      case 'Active': return 'bg-emerald-500/10 text-emerald-500 border-emerald-500/20'
      case 'Pending': return 'bg-amber-500/10 text-amber-500 border-amber-500/20'
      case 'Suspended': return 'bg-rose-500/10 text-rose-500 border-rose-500/20'
      default: return 'bg-slate-500/10 text-slate-500 border-slate-500/20'
    }
  }

  const handleToggleSuspend = async (admin: any) => {
    try {
      const newStatus = admin.status === 'Suspended' ? 'Active' : 'Suspended'
      const { error } = await supabase
        .from('admin_profiles')
        .update({ status: newStatus })
        .eq('id', admin.id)
      
      if (error) throw error
      toast.success(`Administrator ${newStatus === 'Active' ? 'restored' : 'suspended'} successfully`)
      fetchAdmins()
    } catch (e: any) {
      toast.error(e.message || "Failed to update status")
    }
  }

  const handleResendInvitation = async (admin: any) => {
    setResendingId(admin.id)
    try {
      if (admin.status === 'Invited') {
        await resendWelcomeEmailFn({ data: { adminId: admin.id } })
        setSentEmail(admin.email)
        setShowSuccessAlert(true)
      } else if (admin.status === 'Pending_Verification') {
        const result = await resendAdminInvitationFn({ data: { adminId: admin.id } })
        setSentEmail(admin.email)
        setShowSuccessAlert(true)
        if (result.testPassword) {
          toast.info(`Test Credentials in console! Password: ${result.testPassword}`)
          console.log("TEST CREDENTIALS:", result)
        }
      }
    } catch (e: any) {
      toast.error(e.message || "Failed to resend email")
    } finally {
      setResendingId(null)
    }
  }

  const filteredAdmins = admins.filter(a => 
    a.full_name?.toLowerCase().includes(search.toLowerCase()) ||
    a.email?.toLowerCase().includes(search.toLowerCase())
  )

  return (
    <div className="space-y-6">
      <div className="flex flex-col sm:flex-row gap-4 items-center justify-between">
        <div className="relative w-full sm:max-w-sm">
          <Search className="absolute left-2.5 top-2.5 h-4 w-4 text-muted-foreground" />
          <Input 
            placeholder="Search administrators..." 
            className="pl-8"
            value={search}
            onChange={(e) => setSearch(e.target.value)}
          />
        </div>
        <div className="flex items-center gap-2 w-full sm:w-auto">
          <Button variant="outline" className="w-full sm:w-auto">
            <Filter className="mr-2 h-4 w-4" />
            Filter
          </Button>
          <Button className="w-full sm:w-auto gap-2" onClick={() => setModalOpen(true)}>
            <Plus className="h-4 w-4" />
            Add Administrator
          </Button>
        </div>
      </div>

      <AddAdminModal 
        open={modalOpen} 
        onOpenChange={setModalOpen} 
        onSuccess={fetchAdmins} 
      />

      <Card>
        <div className="relative w-full overflow-auto">
          <table className="w-full caption-bottom text-sm">
            <thead className="[&_tr]:border-b">
              <tr className="border-b transition-colors hover:bg-muted/50 data-[state=selected]:bg-muted">
                <th className="h-12 px-4 text-left align-middle font-medium text-muted-foreground">Administrator</th>
                <th className="h-12 px-4 text-left align-middle font-medium text-muted-foreground">Role</th>
                <th className="h-12 px-4 text-left align-middle font-medium text-muted-foreground">Designation</th>
                <th className="h-12 px-4 text-left align-middle font-medium text-muted-foreground">Status</th>
                <th className="h-12 px-4 text-left align-middle font-medium text-muted-foreground">Last Active</th>
                <th className="h-12 px-4 text-right align-middle font-medium text-muted-foreground">Actions</th>
              </tr>
            </thead>
            <tbody className="[&_tr:last-child]:border-0">
              {loading ? (
                <tr>
                  <td colSpan={6} className="h-24 text-center">Loading administrators...</td>
                </tr>
              ) : filteredAdmins.length === 0 ? (
                <tr>
                  <td colSpan={6} className="h-24 text-center text-muted-foreground">No administrators found.</td>
                </tr>
              ) : (
                filteredAdmins.map((admin) => (
                  <tr key={admin.id} className="border-b transition-colors hover:bg-muted/50 data-[state=selected]:bg-muted">
                    <td className="p-4 align-middle">
                      <div className="flex items-center gap-3">
                        <div className="flex h-9 w-9 items-center justify-center rounded-full bg-primary/10">
                          <span className="text-sm font-medium text-primary">
                            {admin.full_name?.charAt(0) || 'A'}
                          </span>
                        </div>
                        <div className="flex flex-col">
                          <span className="font-medium">{admin.full_name}</span>
                          <span className="text-xs text-muted-foreground flex items-center gap-1">
                            <Mail className="h-3 w-3" /> {admin.email}
                          </span>
                        </div>
                      </div>
                    </td>
                    <td className="p-4 align-middle">
                      <div className="flex items-center gap-2 text-sm">
                        <ShieldCheck className="h-4 w-4 text-primary" />
                        {(admin.roles as any)?.name || 'Custom Role'}
                      </div>
                    </td>
                    <td className="p-4 align-middle text-muted-foreground">
                      {admin.designation || '—'}
                    </td>
                    <td className="p-4 align-middle">
                      <Badge variant="outline" className={getStatusColor(admin.status)}>
                        {admin.status}
                      </Badge>
                    </td>
                    <td className="p-4 align-middle text-muted-foreground text-xs">
                      {admin.last_active_at ? (
                        <div className="flex items-center gap-1">
                          <Clock className="h-3 w-3" />
                          {new Date(admin.last_active_at).toLocaleDateString()}
                        </div>
                      ) : 'Never'}
                    </td>
                    <td className="p-4 align-middle text-right">
                      <DropdownMenu>
                        <DropdownMenuTrigger asChild>
                          <Button variant="ghost" size="icon">
                            <MoreHorizontal className="h-4 w-4" />
                            <span className="sr-only">Open menu</span>
                          </Button>
                        </DropdownMenuTrigger>
                        <DropdownMenuContent align="end">
                          <DropdownMenuLabel>Actions</DropdownMenuLabel>
                          <DropdownMenuItem onClick={() => router.navigate({ to: '/admins/$adminId', params: { adminId: admin.id } })}>
                            View Profile
                          </DropdownMenuItem>
                          <DropdownMenuItem onClick={() => router.navigate({ to: '/admins/$adminId', params: { adminId: admin.id } })}>
                            Edit Details
                          </DropdownMenuItem>
                          <DropdownMenuSeparator />
                          <DropdownMenuItem onClick={() => toast.info('Please use View Profile to modify roles.')}>
                            Assign Role
                          </DropdownMenuItem>
                          {(admin.status === 'Pending_Verification' || admin.status === 'Invited') && (
                            <>
                              <DropdownMenuSeparator />
                              <DropdownMenuItem 
                                onClick={(e) => {
                                  e.preventDefault() // prevent dropdown from closing immediately if we want, or just let it close
                                  handleResendInvitation(admin)
                                }}
                                disabled={resendingId === admin.id}
                              >
                                {resendingId === admin.id ? (
                                  <><Loader2 className="mr-2 h-4 w-4 animate-spin" /> Resending...</>
                                ) : admin.status === 'Invited' ? (
                                  'Resend Invitation'
                                ) : (
                                  'Resend Credentials'
                                )}
                              </DropdownMenuItem>
                            </>
                          )}
                          <DropdownMenuSeparator />
                          <DropdownMenuItem 
                            className={admin.status === 'Suspended' ? "text-emerald-600" : "text-destructive"}
                            onClick={() => handleToggleSuspend(admin)}
                          >
                            {admin.status === 'Suspended' ? 'Restore Admin' : 'Suspend Admin'}
                          </DropdownMenuItem>
                        </DropdownMenuContent>
                      </DropdownMenu>
                    </td>
                  </tr>
                ))
              )}
            </tbody>
          </table>
        </div>
      </Card>

      <AlertDialog open={showSuccessAlert} onOpenChange={setShowSuccessAlert}>
        <AlertDialogContent className="sm:max-w-md">
          <AlertDialogHeader>
            <AlertDialogTitle className="flex items-center gap-2">
              <CheckCircle2 className="h-5 w-5 text-emerald-500" />
              Email Sent Successfully
            </AlertDialogTitle>
            <AlertDialogDescription>
              The email has been successfully resent to <span className="font-medium text-foreground">{sentEmail}</span>.
            </AlertDialogDescription>
          </AlertDialogHeader>
          <AlertDialogFooter>
            <AlertDialogAction onClick={() => setShowSuccessAlert(false)}>
              Done
            </AlertDialogAction>
          </AlertDialogFooter>
        </AlertDialogContent>
      </AlertDialog>
    </div>
  )
}
