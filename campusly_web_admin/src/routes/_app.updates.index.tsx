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
import { useQuery } from '@tanstack/react-query'
import { Smartphone, Users, FileArchive, CheckCircle2 } from 'lucide-react'

export const Route = createFileRoute('/_app/updates/')({
  component: UpdatesOverviewPage,
})

function UpdatesOverviewPage() {
  const { data: stats, isLoading } = useQuery({
    queryKey: ['updateStats'],
    queryFn: async () => {
      // Fetch latest release
      const { data: latestRelease } = await supabase
        .from('app_releases')
        .select('*')
        .eq('status', 'PUBLISHED')
        .order('build_number', { ascending: false })
        .limit(1)
        .maybeSingle()

      // In a real app we'd fetch active users and adoption rate from analytics table or Supabase RPC
      // For now, we mock the user distribution based on the spec
      
      return {
        latestRelease,
        totalUsers: 1250,
        usersOnLatest: 1104,
        usersRequiringUpdate: 146,
        adoptionRate: 88.4,
      }
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
                <BreadcrumbPage>App Updates</BreadcrumbPage>
              </BreadcrumbItem>
              <BreadcrumbSeparator className="hidden md:block" />
              <BreadcrumbItem>
                <BreadcrumbPage>Overview</BreadcrumbPage>
              </BreadcrumbItem>
            </BreadcrumbList>
          </Breadcrumb>
        </header>

        <main className="flex-1 overflow-auto p-8">
          <div className="mx-auto max-w-5xl space-y-8">
            <div className="flex justify-between items-end">
              <div>
                <h1 className="text-3xl font-bold tracking-tight">Campusly App Updates</h1>
                <p className="text-muted-foreground mt-2">
                  Manage releases, track adoption, and enforce mandatory updates.
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
            ) : (
              <div className="grid gap-4 md:grid-cols-2 lg:grid-cols-4">
                <Card>
                  <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
                    <CardTitle className="text-sm font-medium">
                      Production Version
                    </CardTitle>
                    <CheckCircle2 className="h-4 w-4 text-emerald-500" />
                  </CardHeader>
                  <CardContent>
                    <div className="text-2xl font-bold">
                      {stats?.latestRelease?.version || 'None'}
                    </div>
                    <p className="text-xs text-muted-foreground mt-1">
                      Build {stats?.latestRelease?.build_number || 0}
                    </p>
                  </CardContent>
                </Card>

                <Card>
                  <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
                    <CardTitle className="text-sm font-medium">
                      Minimum Supported
                    </CardTitle>
                    <Smartphone className="h-4 w-4 text-muted-foreground" />
                  </CardHeader>
                  <CardContent>
                    <div className="text-2xl font-bold">
                      {stats?.latestRelease?.minimum_supported_version || 'None'}
                    </div>
                    <p className="text-xs text-muted-foreground mt-1">
                      Build {stats?.latestRelease?.minimum_supported_build || 0}
                    </p>
                  </CardContent>
                </Card>

                <Card>
                  <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
                    <CardTitle className="text-sm font-medium">
                      Total Active Users
                    </CardTitle>
                    <Users className="h-4 w-4 text-muted-foreground" />
                  </CardHeader>
                  <CardContent>
                    <div className="text-2xl font-bold">
                      {stats?.totalUsers.toLocaleString()}
                    </div>
                    <p className="text-xs text-muted-foreground mt-1">
                      Last 30 days
                    </p>
                  </CardContent>
                </Card>

                <Card>
                  <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
                    <CardTitle className="text-sm font-medium">
                      Adoption Rate
                    </CardTitle>
                    <FileArchive className="h-4 w-4 text-muted-foreground" />
                  </CardHeader>
                  <CardContent>
                    <div className="text-2xl font-bold">
                      {stats?.adoptionRate}%
                    </div>
                    <p className="text-xs text-muted-foreground mt-1">
                      {stats?.usersOnLatest} users on latest
                    </p>
                  </CardContent>
                </Card>
              </div>
            )}

            <Card className="mt-8">
              <CardHeader>
                <CardTitle>Update Distribution</CardTitle>
                <CardDescription>
                  Distribution of users across different app versions
                </CardDescription>
              </CardHeader>
              <CardContent>
                <div className="space-y-4">
                  <div className="flex items-center">
                    <div className="w-[100px] text-sm font-medium">
                      {stats?.latestRelease?.version || 'Latest'}
                    </div>
                    <div className="flex-1 ml-4">
                      <div className="h-4 w-full bg-muted rounded-full overflow-hidden">
                        <div 
                          className="h-full bg-emerald-500" 
                          style={{ width: `${stats?.adoptionRate || 0}%` }}
                        />
                      </div>
                    </div>
                    <div className="w-[100px] text-right text-sm text-muted-foreground">
                      {stats?.adoptionRate || 0}%
                    </div>
                  </div>
                  
                  <div className="flex items-center">
                    <div className="w-[100px] text-sm font-medium text-muted-foreground">
                      Older
                    </div>
                    <div className="flex-1 ml-4">
                      <div className="h-4 w-full bg-muted rounded-full overflow-hidden">
                        <div 
                          className="h-full bg-amber-500" 
                          style={{ width: `${100 - (stats?.adoptionRate || 100)}%` }}
                        />
                      </div>
                    </div>
                    <div className="w-[100px] text-right text-sm text-muted-foreground">
                      {100 - (stats?.adoptionRate || 100)}%
                    </div>
                  </div>
                </div>
              </CardContent>
            </Card>

          </div>
        </main>
      </SidebarInset>
    </SidebarProvider>
  )
}
