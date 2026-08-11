import { createFileRoute, Outlet, Link, useRouterState } from '@tanstack/react-router'
import { PageHeader } from '@/components/page-header'

export const Route = createFileRoute('/_app/admins')({
  component: AdminsLayout,
})

function AdminsLayout() {
  const pathname = useRouterState({ select: (r) => r.location.pathname });

  const tabs = [
    { name: 'Overview', href: '/admins' },
    { name: 'Administrators', href: '/admins/list' },
    { name: 'Roles & Permissions', href: '/admins/roles' },
    { name: 'Activity Logs', href: '/admins/audit' },
    { name: 'Security', href: '/admins/security' },
  ];

  return (
    <div className="space-y-6">
      <PageHeader 
        title="Admin Management" 
        description="Manage administrators, roles, permissions and access to Campusly."
        crumbs={[{ label: "People" }, { label: "Admins", to: "/admins" }]}
      />

      <div className="border-b">
        <nav className="-mb-px flex space-x-8" aria-label="Tabs">
          {tabs.map((tab) => {
            const isActive = pathname === tab.href || (tab.href === '/admins' && pathname === '/admins/');
            return (
              <Link
                key={tab.name}
                to={tab.href}
                className={`
                  whitespace-nowrap border-b-2 py-4 px-1 text-sm font-medium
                  ${isActive 
                    ? 'border-primary text-primary' 
                    : 'border-transparent text-muted-foreground hover:border-muted-foreground/30 hover:text-foreground'
                  }
                `}
              >
                {tab.name}
              </Link>
            )
          })}
        </nav>
      </div>

      <div className="pt-4">
        <Outlet />
      </div>
    </div>
  )
}
