import { createFileRoute } from '@tanstack/react-router'
import { Link } from '@tanstack/react-router'
import { Card, CardContent, CardHeader, CardTitle, CardDescription } from '../components/ui/card'
import { Button } from '../components/ui/button'
import { Plus, Settings, Eye, BarChart, MoreVertical } from 'lucide-react'
import { getFormsFn, createFormFn } from '../lib/form-actions'
import { useAuth } from '../lib/auth'

export const Route = createFileRoute('/_app/forms/')({
  component: FormsDashboardComponent,
  loader: async () => {
    return await getFormsFn()
  },
})

function FormsDashboardComponent() {
  const forms = Route.useLoaderData()
  const { admin } = useAuth()

  const handleCreateForm = async () => {
    if (!admin) return
    try {
      const { form } = await createFormFn({ data: {
        title: 'New Form',
        description: 'Form Description',
        category: 'General',
        created_by: admin.id,
      }})
      // Redirect to builder
      window.location.href = `/forms/builder/${form.id}`
    } catch (e) {
      console.error(e)
      alert("Failed to create form")
    }
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
          {forms.map((f: any) => (
            <Card key={f.id} className="group overflow-hidden transition-all hover:shadow-md border-slate-200 dark:border-slate-800">
              <CardHeader className="pb-4">
                <div className="flex justify-between items-start">
                  <div className="space-y-1">
                    <CardTitle className="text-lg line-clamp-1">{f.title}</CardTitle>
                    <CardDescription className="line-clamp-2">{f.description || 'No description'}</CardDescription>
                  </div>
                  <div className="bg-slate-100 dark:bg-slate-800 text-slate-600 dark:text-slate-300 text-xs px-2 py-1 rounded capitalize font-medium">
                    {f.status}
                  </div>
                </div>
              </CardHeader>
              <CardContent>
                <div className="flex items-center text-sm text-slate-500 mb-6">
                  <span className="font-medium text-slate-700 dark:text-slate-300">
                    {f._count?.count || f.form_responses?.[0]?.count || 0}
                  </span>
                  <span className="ml-1">Responses</span>
                </div>
                
                <div className="grid grid-cols-3 gap-2">
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
                  <Button variant="outline" size="sm" className="w-full text-xs gap-1" onClick={() => alert("Preview clicked")}>
                    <Eye size={14} /> View
                  </Button>
                </div>
              </CardContent>
            </Card>
          ))}
        </div>
      )}
    </div>
  )
}
