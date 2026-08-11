import { createFileRoute } from '@tanstack/react-router'
import { Link } from '@tanstack/react-router'
import { getFormFn } from '../lib/form-actions'
import { Card, CardContent, CardHeader, CardTitle, CardDescription } from '../components/ui/card'
import { Button } from '../components/ui/button'
import { ArrowLeft, Download, Users, FileText, CheckCircle2 } from 'lucide-react'

export const Route = createFileRoute('/_app/forms/responses/$formId')({
  component: FormResponsesComponent,
  loader: async ({ params }) => {
    return await getFormFn({ data: params.formId })
  },
})

function FormResponsesComponent() {
  const form = Route.useLoaderData()

  // In a real implementation, we would also fetch the actual responses
  // using a getResponsesFn(formId) API call, and use Recharts or Chart.js
  // to display visual analytics. For now, we mock the UI structure.

  return (
    <div className="p-6 space-y-6 max-w-7xl mx-auto">
      <div className="flex items-center gap-4">
        <Button variant="ghost" size="icon" asChild>
          <Link to="/forms"><ArrowLeft size={18} /></Link>
        </Button>
        <div className="flex-1">
          <h1 className="text-2xl font-bold tracking-tight text-slate-900 dark:text-white">Responses: {form.title}</h1>
          <p className="text-sm text-slate-500 mt-1">Analytics and submissions overview</p>
        </div>
        <Button className="gap-2" variant="outline">
          <Download size={16} /> Export CSV
        </Button>
      </div>

      <div className="grid grid-cols-1 md:grid-cols-4 gap-4">
        <Card>
          <CardHeader className="pb-2">
            <CardTitle className="text-sm font-medium text-slate-500">Total Responses</CardTitle>
          </CardHeader>
          <CardContent>
            <div className="text-3xl font-bold">142</div>
          </CardContent>
        </Card>
        <Card>
          <CardHeader className="pb-2">
            <CardTitle className="text-sm font-medium text-slate-500">Completion Rate</CardTitle>
          </CardHeader>
          <CardContent>
            <div className="text-3xl font-bold">89%</div>
          </CardContent>
        </Card>
        <Card>
          <CardHeader className="pb-2">
            <CardTitle className="text-sm font-medium text-slate-500">Avg Time</CardTitle>
          </CardHeader>
          <CardContent>
            <div className="text-3xl font-bold">2m 14s</div>
          </CardContent>
        </Card>
        <Card>
          <CardHeader className="pb-2">
            <CardTitle className="text-sm font-medium text-slate-500">Status</CardTitle>
          </CardHeader>
          <CardContent>
            <div className="text-xl font-bold text-green-600 capitalize">{form.status}</div>
          </CardContent>
        </Card>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        <Card className="lg:col-span-2">
          <CardHeader>
            <CardTitle>Recent Responses</CardTitle>
            <CardDescription>Latest submissions from students</CardDescription>
          </CardHeader>
          <CardContent>
            <div className="rounded-md border border-slate-200 dark:border-slate-800">
              <table className="w-full text-sm text-left">
                <thead className="text-xs text-slate-500 bg-slate-50 dark:bg-slate-900/50 border-b border-slate-200 dark:border-slate-800">
                  <tr>
                    <th className="px-4 py-3 font-medium">Student</th>
                    <th className="px-4 py-3 font-medium">Department</th>
                    <th className="px-4 py-3 font-medium">Submitted At</th>
                    <th className="px-4 py-3 font-medium text-right">Action</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-slate-200 dark:divide-slate-800">
                  {[1, 2, 3, 4, 5].map(i => (
                    <tr key={i} className="hover:bg-slate-50 dark:hover:bg-slate-900/50">
                      <td className="px-4 py-3 font-medium text-slate-900 dark:text-slate-100">Student Name {i}</td>
                      <td className="px-4 py-3 text-slate-500">CSE - 2nd Year</td>
                      <td className="px-4 py-3 text-slate-500">2 mins ago</td>
                      <td className="px-4 py-3 text-right">
                        <Button variant="ghost" size="sm" className="h-8 text-blue-600">View</Button>
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          </CardContent>
        </Card>

        <Card>
          <CardHeader>
            <CardTitle>Question Analytics</CardTitle>
            <CardDescription>Breakdown by question</CardDescription>
          </CardHeader>
          <CardContent className="space-y-6">
            <div>
              <h4 className="text-sm font-medium mb-3">What is your department?</h4>
              <div className="space-y-2">
                <div className="space-y-1">
                  <div className="flex justify-between text-xs text-slate-500">
                    <span>CSE</span>
                    <span>65% (92)</span>
                  </div>
                  <div className="h-2 bg-slate-100 dark:bg-slate-800 rounded-full overflow-hidden">
                    <div className="h-full bg-blue-500 w-[65%]" />
                  </div>
                </div>
                <div className="space-y-1">
                  <div className="flex justify-between text-xs text-slate-500">
                    <span>ECE</span>
                    <span>20% (28)</span>
                  </div>
                  <div className="h-2 bg-slate-100 dark:bg-slate-800 rounded-full overflow-hidden">
                    <div className="h-full bg-blue-500 w-[20%]" />
                  </div>
                </div>
                <div className="space-y-1">
                  <div className="flex justify-between text-xs text-slate-500">
                    <span>MECH</span>
                    <span>15% (22)</span>
                  </div>
                  <div className="h-2 bg-slate-100 dark:bg-slate-800 rounded-full overflow-hidden">
                    <div className="h-full bg-blue-500 w-[15%]" />
                  </div>
                </div>
              </div>
            </div>
          </CardContent>
        </Card>
      </div>
    </div>
  )
}
