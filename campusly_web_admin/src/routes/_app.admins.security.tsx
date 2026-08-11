import { createFileRoute } from '@tanstack/react-router'
import { Card, CardContent, CardDescription, CardHeader, CardTitle, CardFooter } from '@/components/ui/card'
import { Switch } from '@/components/ui/switch'
import { Label } from '@/components/ui/label'
import { Button } from '@/components/ui/button'
import { ShieldAlert, Key, Smartphone, AlertTriangle } from 'lucide-react'

export const Route = createFileRoute('/_app/admins/security')({
  component: AdminSecurity,
})

function AdminSecurity() {
  return (
    <div className="space-y-6 max-w-4xl">
      <div className="grid gap-6">
        <Card>
          <CardHeader>
            <div className="flex items-center gap-2">
              <ShieldAlert className="h-5 w-5 text-primary" />
              <CardTitle>Authentication Security</CardTitle>
            </div>
            <CardDescription>
              Manage global security policies for all administrative accounts.
            </CardDescription>
          </CardHeader>
          <CardContent className="space-y-6">
            <div className="flex items-center justify-between space-x-2">
              <div className="flex flex-col space-y-1">
                <Label htmlFor="mfa-enforcement" className="text-base">Enforce Multi-Factor Authentication (MFA)</Label>
                <span className="text-sm text-muted-foreground">
                  Require all administrators to set up 2FA before accessing the dashboard.
                </span>
              </div>
              <Switch id="mfa-enforcement" defaultChecked />
            </div>

            <div className="flex items-center justify-between space-x-2">
              <div className="flex flex-col space-y-1">
                <Label htmlFor="session-timeout" className="text-base">Idle Session Timeout</Label>
                <span className="text-sm text-muted-foreground">
                  Automatically log out administrators after 30 minutes of inactivity.
                </span>
              </div>
              <Switch id="session-timeout" defaultChecked />
            </div>
          </CardContent>
        </Card>

        <Card>
          <CardHeader>
            <div className="flex items-center gap-2">
              <Key className="h-5 w-5 text-primary" />
              <CardTitle>Active Sessions & Devices</CardTitle>
            </div>
            <CardDescription>
              Monitor active sessions across the platform and revoke access if necessary.
            </CardDescription>
          </CardHeader>
          <CardContent>
            <div className="rounded-md border p-4 bg-muted/20">
              <div className="flex items-center justify-between">
                <div className="flex items-center gap-3">
                  <Smartphone className="h-6 w-6 text-muted-foreground" />
                  <div>
                    <p className="font-medium">Current Session (Mac OS / Chrome)</p>
                    <p className="text-sm text-muted-foreground">IP: 192.168.1.1 • Active right now</p>
                  </div>
                </div>
              </div>
            </div>
          </CardContent>
          <CardFooter className="bg-muted/10 border-t p-4 flex justify-between">
            <p className="text-sm text-muted-foreground">
              Revoking all sessions will immediately sign out every active administrator.
            </p>
            <Button variant="destructive" className="gap-2">
              <AlertTriangle className="h-4 w-4" />
              Revoke All Sessions
            </Button>
          </CardFooter>
        </Card>
      </div>
    </div>
  )
}
