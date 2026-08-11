import { createFileRoute } from '@tanstack/react-router'
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card'
import { processInvitationResponseFn } from '@/lib/admin-actions'
import { useEffect, useState } from 'react'
import { CheckCircle2, XCircle, Loader2 } from 'lucide-react'

// Define the search params expected for this route
type InviteSearch = {
  token: string
  action: 'accept' | 'reject'
}

export const Route = createFileRoute('/invite/response')({
  component: InviteResponse,
  validateSearch: (search: Record<string, unknown>): InviteSearch => {
    return {
      token: (search.token as string) || '',
      action: (search.action === 'accept' || search.action === 'reject') ? search.action : 'reject',
    }
  },
})

function InviteResponse() {
  const { token, action } = Route.useSearch()
  const [status, setStatus] = useState<'loading' | 'success' | 'error'>('loading')
  const [message, setMessage] = useState('Processing your response...')

  useEffect(() => {
    async function processResponse() {
      if (!token) {
        setStatus('error')
        setMessage('Missing or invalid invitation token.')
        return
      }

      try {
        const result = await processInvitationResponseFn({ data: { token, action } })
        setStatus('success')
        if (result.status === 'Accepted') {
          setMessage('Thank you! You have accepted the invitation. Your administrator has been notified and will approve your account shortly.')
        } else {
          setMessage('You have successfully rejected the invitation. Your administrator has been notified.')
        }
      } catch (error: any) {
        setStatus('error')
        setMessage(error.message || 'An error occurred while processing your response.')
      }
    }

    processResponse()
  }, [token, action])

  return (
    <div className="min-h-screen flex items-center justify-center bg-muted/40 p-4">
      <Card className="w-full max-w-md shadow-xl border-border/50">
        <CardHeader className="text-center space-y-4">
          <div className="flex justify-center">
            {status === 'loading' && <Loader2 className="h-12 w-12 text-primary animate-spin" />}
            {status === 'success' && action === 'accept' && <CheckCircle2 className="h-12 w-12 text-emerald-500" />}
            {status === 'success' && action === 'reject' && <CheckCircle2 className="h-12 w-12 text-muted-foreground" />}
            {status === 'error' && <XCircle className="h-12 w-12 text-destructive" />}
          </div>
          <CardTitle className="text-2xl font-bold">
            {status === 'loading' ? 'Processing...' : status === 'error' ? 'Error' : 'Response Recorded'}
          </CardTitle>
          <CardDescription className="text-base text-foreground/80">
            {message}
          </CardDescription>
        </CardHeader>
        <CardContent className="text-center text-sm text-muted-foreground">
          {status !== 'loading' && (
            <p>You may now safely close this window.</p>
          )}
        </CardContent>
      </Card>
    </div>
  )
}
