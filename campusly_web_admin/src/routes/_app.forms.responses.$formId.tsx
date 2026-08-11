import { createFileRoute } from '@tanstack/react-router'
import { Link } from '@tanstack/react-router'
import { getFormResponsesAnalyticsFn } from '../lib/form-actions'
import { Card, CardContent, CardHeader, CardTitle, CardDescription } from '../components/ui/card'
import { Button } from '../components/ui/button'
import { ArrowLeft, Download, Users, FileText, CheckCircle2 } from 'lucide-react'
import { formatDistanceToNow } from 'date-fns'

export const Route = createFileRoute('/_app/forms/responses/$formId')({
  component: FormResponsesComponent,
  loader: async ({ params }) => {
    return await getFormResponsesAnalyticsFn({ data: params.formId })
  },
})

function FormResponsesComponent() {
  const { form, responses, totalResponses, analytics } = Route.useLoaderData() as any;

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

      <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
        <Card>
          <CardHeader className="pb-2">
            <CardTitle className="text-sm font-medium text-slate-500">Total Responses</CardTitle>
          </CardHeader>
          <CardContent>
            <div className="text-3xl font-bold">{totalResponses}</div>
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
                    <th className="px-4 py-3 font-medium">Respondent ID</th>
                    <th className="px-4 py-3 font-medium">Status</th>
                    <th className="px-4 py-3 font-medium">Submitted At</th>
                    <th className="px-4 py-3 font-medium text-right">Action</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-slate-200 dark:divide-slate-800">
                  {responses.length === 0 ? (
                    <tr>
                      <td colSpan={4} className="px-4 py-8 text-center text-slate-500">
                        No responses yet.
                      </td>
                    </tr>
                  ) : responses.map((r: any) => (
                    <tr key={r.id} className="hover:bg-slate-50 dark:hover:bg-slate-900/50">
                      <td className="px-4 py-3 font-medium text-slate-900 dark:text-slate-100">
                        {r.user_id ? 'Authenticated Student' : 'Anonymous'}
                      </td>
                      <td className="px-4 py-3 text-slate-500 capitalize">{r.status}</td>
                      <td className="px-4 py-3 text-slate-500">
                        {r.submitted_at ? formatDistanceToNow(new Date(r.submitted_at), { addSuffix: true }) : 'Unknown'}
                      </td>
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
            {Object.keys(analytics).length === 0 ? (
              <p className="text-slate-500 text-sm">No analytics available.</p>
            ) : Object.keys(analytics).map(qId => {
              const item = analytics[qId];
              const q = item.question;
              const stats = item.stats;
              const totalAnswers = Object.values(stats).reduce((a: any, b: any) => a + b, 0) as number;

              return (
                <div key={q.id}>
                  <h4 className="text-sm font-medium mb-3">{q.title}</h4>
                  {totalAnswers === 0 ? (
                    <p className="text-xs text-slate-400">No data</p>
                  ) : (
                    <div className="space-y-2">
                      {Object.keys(stats).map(key => {
                        const count = stats[key] as number;
                        const pct = Math.round((count / totalAnswers) * 100);
                        return (
                          <div key={key} className="space-y-1">
                            <div className="flex justify-between text-xs text-slate-500">
                              <span className="truncate max-w-[200px]">{key}</span>
                              <span>{pct}% ({count})</span>
                            </div>
                            <div className="h-2 bg-slate-100 dark:bg-slate-800 rounded-full overflow-hidden">
                              <div className="h-full bg-blue-500" style={{ width: `${pct}%` }} />
                            </div>
                          </div>
                        )
                      })}
                    </div>
                  )}
                </div>
              );
            })}
          </CardContent>
        </Card>
      </div>
    </div>
  )
}
