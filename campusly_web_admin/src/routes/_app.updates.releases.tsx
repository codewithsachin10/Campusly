import { createFileRoute, Link } from '@tanstack/react-router'
import { AppSidebar } from '@/components/layout/app-sidebar'
import {
  Breadcrumb,
  BreadcrumbItem,
  BreadcrumbLink,
  BreadcrumbList,
  BreadcrumbPage,
  BreadcrumbSeparator,
} from '@/components/ui/breadcrumb'
import { Separator } from '@/components/ui/separator'
import {
  SidebarInset,
  SidebarProvider,
  SidebarTrigger,
} from '@/components/ui/sidebar'
import { supabase } from '@/lib/supabase'
import { Card, CardContent, CardDescription, CardHeader, CardTitle, CardFooter } from '@/components/ui/card'
import { Button } from '@/components/ui/button'
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query'
import { FileArchive, CheckCircle2, XCircle, AlertTriangle, RotateCcw, Download, PauseCircle } from 'lucide-react'
import { toast } from 'sonner'

export const Route = createFileRoute('/_app/updates/releases')({
  component: ReleaseHistoryPage,
})

type AppRelease = {
  id: string
  platform: string
  version: string
  build_number: number
  release_title: string
  release_notes: string
  update_type: 'OPTIONAL' | 'RECOMMENDED' | 'MANDATORY'
  minimum_supported_build: number
  minimum_supported_version: string
  apk_url: string
  apk_size: number
  apk_sha256: string
  status: 'DRAFT' | 'READY' | 'PUBLISHED' | 'PAUSED' | 'ROLLED_BACK' | 'ARCHIVED'
  rollout_percentage: number
  is_published: boolean
  published_at: string
  created_at: string
}

function ReleaseHistoryPage() {
  const queryClient = useQueryClient()

  const { data: releases, isLoading } = useQuery({
    queryKey: ['appReleases'],
    queryFn: async () => {
      const { data, error } = await supabase
        .from('app_releases')
        .select('*')
        .order('build_number', { ascending: false })
      
      if (error) throw error
      return data as AppRelease[]
    }
  })

  const updateStatusMutation = useMutation({
    mutationFn: async ({ id, status, is_published }: { id: string, status: string, is_published: boolean }) => {
      const { error } = await supabase
        .from('app_releases')
        .update({ status, is_published })
        .eq('id', id)
      if (error) throw error
    },
    onSuccess: (_, variables) => {
      toast.success(`Release marked as ${variables.status}.`)
      queryClient.invalidateQueries({ queryKey: ['appReleases'] })
    },
    onError: (error) => {
      toast.error(`Failed to update status: ${error.message}`)
    }
  })

  return (
    <SidebarProvider>
      <AppSidebar />
      <SidebarInset>
        <header className="flex h-16 shrink-0 items-center gap-2 border-b bg-background px-4">
          <SidebarTrigger className="-ml-1" />
          <Separator orientation="vertical" className="mr-2 h-4" />
          <Breadcrumb>
            <BreadcrumbList>
              <BreadcrumbItem className="hidden md:block">
                <BreadcrumbLink href="#">Campusly App</BreadcrumbLink>
              </BreadcrumbItem>
              <BreadcrumbSeparator className="hidden md:block" />
              <BreadcrumbItem>
                <BreadcrumbLink href="/updates">App Updates</BreadcrumbLink>
              </BreadcrumbItem>
              <BreadcrumbSeparator className="hidden md:block" />
              <BreadcrumbItem>
                <BreadcrumbPage>Release History</BreadcrumbPage>
              </BreadcrumbItem>
            </BreadcrumbList>
          </Breadcrumb>
        </header>

        <main className="flex-1 overflow-auto p-8">
          <div className="mx-auto max-w-5xl space-y-8">
            <div className="flex justify-between items-end">
              <div>
                <h1 className="text-3xl font-bold tracking-tight">Release History</h1>
                <p className="text-muted-foreground mt-2">
                  View past releases, manage rollouts, and rollback if necessary.
                </p>
              </div>
              <Button asChild>
                <Link to="/updates/create">Create New Release</Link>
              </Button>
            </div>

            {isLoading ? (
              <div className="flex justify-center p-12">
                <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-primary"></div>
              </div>
            ) : releases?.length === 0 ? (
              <Card>
                <CardContent className="flex flex-col items-center justify-center py-12 text-center">
                  <div className="rounded-full bg-primary/10 p-4 mb-4">
                    <FileArchive className="h-8 w-8 text-primary" />
                  </div>
                  <h3 className="text-xl font-semibold">No releases yet</h3>
                  <p className="text-muted-foreground mt-2 max-w-sm">
                    You haven't published any app updates yet. Click "Create New Release" to upload your first APK.
                  </p>
                </CardContent>
              </Card>
            ) : (
              <div className="grid gap-4">
                {releases?.map((release) => (
                  <Card key={release.id} className={release.status === 'ROLLED_BACK' || release.status === 'ARCHIVED' ? 'opacity-70' : ''}>
                    <CardHeader className="pb-3">
                      <div className="flex items-start justify-between">
                        <div>
                          <CardTitle className="text-xl flex items-center gap-2">
                            {release.release_title || `Campusly v${release.version}`} 
                            <span className="text-sm font-normal text-muted-foreground">(Build {release.build_number})</span>
                          </CardTitle>
                          <CardDescription className="mt-1">
                            Published on {new Date(release.published_at || release.created_at).toLocaleDateString()}
                          </CardDescription>
                        </div>
                        <div className="flex flex-col items-end gap-2">
                          {release.status === 'PUBLISHED' && (
                            <span className="inline-flex items-center gap-1.5 rounded-full bg-emerald-500/10 px-2.5 py-0.5 text-xs font-semibold text-emerald-600 dark:text-emerald-400">
                              <CheckCircle2 className="h-3.5 w-3.5" /> Published (Rollout: {release.rollout_percentage}%)
                            </span>
                          )}
                          {release.status === 'PAUSED' && (
                            <span className="inline-flex items-center gap-1.5 rounded-full bg-amber-500/10 px-2.5 py-0.5 text-xs font-semibold text-amber-600 dark:text-amber-400">
                              <PauseCircle className="h-3.5 w-3.5" /> Paused
                            </span>
                          )}
                          {release.status === 'ROLLED_BACK' && (
                            <span className="inline-flex items-center gap-1.5 rounded-full bg-red-500/10 px-2.5 py-0.5 text-xs font-semibold text-red-600 dark:text-red-400">
                              <XCircle className="h-3.5 w-3.5" /> Rolled Back
                            </span>
                          )}
                          {release.status === 'ARCHIVED' && (
                            <span className="inline-flex items-center gap-1.5 rounded-full bg-slate-500/10 px-2.5 py-0.5 text-xs font-semibold text-slate-600 dark:text-slate-400">
                              <FileArchive className="h-3.5 w-3.5" /> Archived
                            </span>
                          )}
                          
                          {/* Update Type Badge */}
                          <span className={`inline-flex items-center gap-1.5 rounded-full px-2.5 py-0.5 text-xs font-semibold ${
                            release.update_type === 'MANDATORY' ? 'bg-destructive/10 text-destructive' :
                            release.update_type === 'RECOMMENDED' ? 'bg-primary/10 text-primary' :
                            'bg-muted text-muted-foreground'
                          }`}>
                            {release.update_type === 'MANDATORY' && <AlertTriangle className="h-3 w-3" />}
                            {release.update_type}
                          </span>
                        </div>
                      </div>
                    </CardHeader>
                    <CardContent>
                      <div className="text-sm">
                        <p className="font-semibold mb-1">Release Notes:</p>
                        <p className="text-muted-foreground whitespace-pre-wrap">{release.release_notes || 'No release notes provided.'}</p>
                      </div>
                      <div className="mt-4 grid grid-cols-2 lg:grid-cols-4 gap-4 text-xs bg-muted/50 p-3 rounded-md">
                        <div className="col-span-2">
                          <span className="text-muted-foreground font-medium">SHA-256 Hash</span>
                          <p className="font-mono mt-0.5 truncate" title={release.apk_sha256}>{release.apk_sha256}</p>
                        </div>
                        <div>
                          <span className="text-muted-foreground font-medium">Min Supported Build</span>
                          <p className="mt-0.5">{release.minimum_supported_build} (v{release.minimum_supported_version})</p>
                        </div>
                        <div>
                          <span className="text-muted-foreground font-medium">Size</span>
                          <p className="mt-0.5">{(release.apk_size / (1024 * 1024)).toFixed(2)} MB</p>
                        </div>
                      </div>
                    </CardContent>
                    <CardFooter className="flex flex-wrap gap-2 justify-between bg-muted/20 pt-4 border-t">
                      <Button variant="outline" size="sm" asChild>
                        <a href={release.apk_url} target="_blank" rel="noreferrer">
                          <Download className="h-4 w-4 mr-2" /> Download APK
                        </a>
                      </Button>
                      
                      <div className="flex gap-2">
                        {release.status === 'PUBLISHED' && (
                          <>
                            <Button 
                              variant="secondary" 
                              size="sm"
                              onClick={() => {
                                if (confirm('Are you sure you want to pause this release? New users will not be prompted to update.')) {
                                  updateStatusMutation.mutate({ id: release.id, status: 'PAUSED', is_published: false })
                                }
                              }}
                              disabled={updateStatusMutation.isPending}
                            >
                              <PauseCircle className="h-4 w-4 mr-2" /> Pause Release
                            </Button>
                            <Button 
                              variant="destructive" 
                              size="sm"
                              onClick={() => {
                                if (confirm('Rollback this release? Students will fall back to the previous stable version. This DOES NOT automatically downgrade installed apps.')) {
                                  updateStatusMutation.mutate({ id: release.id, status: 'ROLLED_BACK', is_published: false })
                                }
                              }}
                              disabled={updateStatusMutation.isPending}
                            >
                              <RotateCcw className="h-4 w-4 mr-2" /> Rollback
                            </Button>
                          </>
                        )}
                        {release.status === 'PAUSED' && (
                          <Button 
                            variant="default" 
                            size="sm"
                            onClick={() => {
                              updateStatusMutation.mutate({ id: release.id, status: 'PUBLISHED', is_published: true })
                            }}
                            disabled={updateStatusMutation.isPending}
                          >
                            <CheckCircle2 className="h-4 w-4 mr-2" /> Resume Release
                          </Button>
                        )}
                        {(release.status === 'ROLLED_BACK' || release.status === 'PAUSED') && (
                          <Button 
                            variant="outline" 
                            size="sm"
                            onClick={() => {
                              updateStatusMutation.mutate({ id: release.id, status: 'ARCHIVED', is_published: false })
                            }}
                            disabled={updateStatusMutation.isPending}
                          >
                            <FileArchive className="h-4 w-4 mr-2" /> Archive
                          </Button>
                        )}
                      </div>
                    </CardFooter>
                  </Card>
                ))}
              </div>
            )}
          </div>
        </main>
      </SidebarInset>
    </SidebarProvider>
  )
}
