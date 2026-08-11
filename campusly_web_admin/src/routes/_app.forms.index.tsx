import { createFileRoute } from '@tanstack/react-router'
import { Link, useRouter } from '@tanstack/react-router'
import { Card, CardContent, CardHeader, CardTitle, CardDescription } from '../components/ui/card'
import { Button } from '../components/ui/button'
import { Plus, Settings, Eye, BarChart, Trash2, Link as LinkIcon, QrCode, Play, Pause, PowerOff, Smartphone } from 'lucide-react'
import { getFormsFn, createFormFn, deleteFormFn, toggleFormStatusFn } from '../lib/form-actions'
import { useAuth } from '../lib/auth'
import { useState } from 'react'

export const Route = createFileRoute('/_app/forms/')({
  component: FormsDashboardComponent,
  loader: async () => {
    return await getFormsFn()
  },
})

function FormsDashboardComponent() {
  const forms = Route.useLoaderData()
  const { admin } = useAuth()
  const router = useRouter()
  
  const [qrModalOpen, setQrModalOpen] = useState(false)
  const [currentQrUrl, setCurrentQrUrl] = useState('')

  const handleCreateForm = async () => {
    if (!admin) return
    try {
      const { form } = await createFormFn({ data: {
        title: 'New Form',
        description: 'Form Description',
        category: 'General',
        created_by: admin.id,
      }})
      window.location.href = `/forms/builder/${form.id}`
    } catch (e) {
      console.error(e)
      alert("Failed to create form")
    }
  }

  const handleDelete = async (id: string) => {
    if (!confirm('Are you sure you want to delete this form?')) return
    try {
      await deleteFormFn({ data: id })
      router.invalidate()
    } catch (e) {
      console.error(e)
      alert("Failed to delete form")
    }
  }

  const handleToggleStatus = async (id: string, currentStatus: string) => {
    const newStatus = currentStatus === 'disabled' ? 'published' : (currentStatus === 'published' ? 'disabled' : 'published')
    try {
      await toggleFormStatusFn({ data: { form_id: id, status: newStatus } })
      router.invalidate()
    } catch (e) {
      console.error(e)
      alert("Failed to update status")
    }
  }

  const handleCopyLink = (token?: string) => {
    if (!token) {
      alert("This form needs to be published first to generate a link.")
      return
    }
    const url = `${window.location.origin}/form/${token}`
    navigator.clipboard.writeText(url)
    alert("Web Link copied to clipboard!")
  }

  const handleCopyDeepLink = (token?: string) => {
    if (!token) {
      alert("This form needs to be published first to generate a link.")
      return
    }
    const url = `campusly://form/${token}`
    navigator.clipboard.writeText(url)
    alert("App Deep Link (campusly://) copied to clipboard!")
  }

  const handleShowQr = (token?: string) => {
    if (!token) {
      alert("This form needs to be published first to generate a QR code.")
      return
    }
    const url = `${window.location.origin}/form/${token}`
    setCurrentQrUrl(url)
    setQrModalOpen(true)
  }

  return (
    <div className="p-6 space-y-6 max-w-7xl mx-auto">
      <div className="flex justify-between items-center">
        <div>
          <h1 className="text-3xl font-bold tracking-tight text-slate-900 dark:text-white">Forms Platform</h1>
          <p className="text-sm text-slate-500 mt-1">Manage and build Campusly dynamic forms</p>
        </div>
        <Button onClick={handleCreateForm} className="gap-2">
          <Plus size={16} /> Create Form
        </Button>
      </div>

      {forms.length === 0 ? (
        <div className="text-center py-20 bg-slate-50 dark:bg-slate-900 rounded-lg border border-dashed border-slate-300 dark:border-slate-800">
          <h2 className="text-xl font-medium text-slate-700 dark:text-slate-300">No forms yet</h2>
          <p className="text-slate-500 mt-2 mb-6">Create your first form to start collecting responses.</p>
          <Button onClick={handleCreateForm}>Get Started</Button>
        </div>
      ) : (
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
          {forms.map((f: any) => {
            const token = f.form_public_links?.[0]?.public_token;
            const borderLeftColor = f.status === 'published' ? 'border-l-green-500' :
                                    f.status === 'disabled' ? 'border-l-red-500' :
                                    'border-l-yellow-500';
            return (
              <Card key={f.id} className={`group overflow-hidden transition-all hover:shadow-md border-slate-200 dark:border-slate-800 flex flex-col border-l-4 ${borderLeftColor}`}>
                <CardHeader className="pb-4">
                  <div className="flex justify-between items-start">
                    <div className="space-y-1">
                      <CardTitle className="text-lg line-clamp-1">{f.title}</CardTitle>
                      <CardDescription className="line-clamp-2">{f.description || 'No description'}</CardDescription>
                    </div>
                    <div className={`text-xs px-2 py-1 rounded capitalize font-medium ${
                      f.status === 'published' ? 'bg-green-100 text-green-700 dark:bg-green-900/30 dark:text-green-400' :
                      f.status === 'disabled' ? 'bg-red-100 text-red-700 dark:bg-red-900/30 dark:text-red-400' :
                      'bg-yellow-100 text-yellow-700 dark:bg-yellow-900/30 dark:text-yellow-400'
                    }`}>
                      {f.status || 'draft'}
                    </div>
                  </div>
                </CardHeader>
                <CardContent className="flex-grow flex flex-col">
                  <div className="flex items-center text-sm text-slate-500 mb-6 flex-grow">
                    <span className="font-medium text-slate-700 dark:text-slate-300">
                      {f._count?.count || f.form_responses?.[0]?.count || 0}
                    </span>
                    <span className="ml-1">Responses</span>
                  </div>
                  
                  <div className="grid grid-cols-3 gap-2 mb-3">
                    <Button variant="outline" size="sm" asChild className="w-full text-xs gap-1">
                      <Link to={`/forms/builder/${f.id}`}>
                        <Settings size={14} /> Edit
                      </Link>
                    </Button>
                    <Button variant="outline" size="sm" asChild className="w-full text-xs gap-1">
                      <Link to={`/forms/responses/${f.id}`}>
                        <BarChart size={14} /> Results
                      </Link>
                    </Button>
                    <Button variant="outline" size="sm" className="w-full text-xs gap-1" asChild>
                      {token ? (
                        <a href={`/form/${token}`} target="_blank" rel="noreferrer">
                          <Eye size={14} /> View
                        </a>
                      ) : (
                        <span className="opacity-50 cursor-not-allowed">
                           <Eye size={14} /> View
                        </span>
                      )}
                    </Button>
                  </div>

                  <div className="flex justify-between items-center border-t border-slate-100 dark:border-slate-800 pt-3 mt-2">
                    <div className="flex space-x-1">
                      <Button variant="ghost" size="icon" className="h-8 w-8 text-slate-500 hover:text-blue-600" onClick={() => handleCopyLink(token)} title="Copy Web Link">
                        <LinkIcon size={14} />
                      </Button>
                      <Button variant="ghost" size="icon" className="h-8 w-8 text-slate-500 hover:text-blue-600" onClick={() => handleCopyDeepLink(token)} title="Copy App Deep Link">
                        <Smartphone size={14} />
                      </Button>
                      <Button variant="ghost" size="icon" className="h-8 w-8 text-slate-500 hover:text-blue-600" onClick={() => handleShowQr(token)} title="Show QR Code">
                        <QrCode size={14} />
                      </Button>
                      <Button variant="ghost" size="icon" className={`h-8 w-8 ${f.status === 'published' ? 'text-red-500 hover:bg-red-50' : 'text-green-600 hover:bg-green-50'}`} onClick={() => handleToggleStatus(f.id, f.status || 'draft')} title={f.status === 'published' ? 'Disable Form' : 'Publish Form'}>
                        {f.status === 'published' ? <PowerOff size={14} /> : <Play size={14} />}
                      </Button>
                    </div>
                    <Button variant="ghost" size="icon" className="h-8 w-8 text-slate-400 hover:text-red-600 hover:bg-red-50" onClick={() => handleDelete(f.id)} title="Delete Form">
                      <Trash2 size={14} />
                    </Button>
                  </div>
                </CardContent>
              </Card>
            )
          })}
        </div>
      )}

      {/* QR Code Modal */}
      {qrModalOpen && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/50" onClick={() => setQrModalOpen(false)}>
          <div className="bg-white dark:bg-slate-900 p-6 rounded-lg shadow-xl max-w-sm w-full mx-4 flex flex-col items-center space-y-4" onClick={e => e.stopPropagation()}>
            <h3 className="text-lg font-semibold text-slate-900 dark:text-white">Form QR Code</h3>
            <div className="bg-white p-2 rounded-lg border">
              <img src={`https://api.qrserver.com/v1/create-qr-code/?size=200x200&data=${encodeURIComponent(currentQrUrl)}`} alt="QR Code" className="w-48 h-48" />
            </div>
            <p className="text-sm text-slate-500 text-center break-all">{currentQrUrl}</p>
            <div className="flex w-full space-x-3 pt-4 border-t">
              <Button variant="outline" className="flex-1" onClick={() => setQrModalOpen(false)}>Close</Button>
              <Button className="flex-1" asChild>
                <a href={currentQrUrl} target="_blank" rel="noreferrer">Open Link</a>
              </Button>
            </div>
          </div>
        </div>
      )}
    </div>
  )
}
