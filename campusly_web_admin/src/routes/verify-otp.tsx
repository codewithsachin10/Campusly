import { createFileRoute, useNavigate } from '@tanstack/react-router'
import { useState } from 'react'
import { Button } from '@/components/ui/button'
import { supabase } from '@/lib/supabase'
import { toast } from 'sonner'
import { Loader2, KeyRound } from 'lucide-react'
import { useAuth } from '@/lib/auth'

export const Route = createFileRoute('/verify-otp')({
  component: VerifyOtpPage,
})

function VerifyOtpPage() {
  const [otp, setOtp] = useState('')
  const [loading, setLoading] = useState(false)
  const navigate = useNavigate()
  const { admin } = useAuth()

  const handleVerify = async (e: React.FormEvent) => {
    e.preventDefault()
    if (otp.length !== 6) return toast.error("OTP must be 6 digits")
    
    if (!admin?.id) {
      return toast.error("You must be logged in to verify OTP.")
    }

    setLoading(true)
    try {
      // Check if OTP matches
      const { data, error } = await supabase
        .from('admin_profiles')
        .select('otp_code, otp_expires_at')
        .eq('id', admin.id)
        .single()

      if (error) throw new Error("Could not verify OTP. " + error.message)

      if (data?.otp_code !== otp) {
        throw new Error("Invalid OTP code.")
      }

      if (new Date(data?.otp_expires_at) < new Date()) {
        throw new Error("OTP has expired. Please request a new one.")
      }

      // Valid OTP, update status
      const { error: updateError } = await supabase
        .from('admin_profiles')
        .update({ 
          status: 'Active', // or Pending_Role if we want manual role assignment
          otp_code: null,
          otp_expires_at: null
        })
        .eq('id', admin.id)

      if (updateError) throw new Error("Failed to update status. " + updateError.message)

      toast.success("Email verified successfully!")
      window.location.href = "/dashboard" // hard reload to re-fetch auth context
    } catch (err: any) {
      toast.error(err.message)
    } finally {
      setLoading(false)
    }
  }

  return (
    <div className="flex min-h-screen items-center justify-center bg-zinc-50 p-4">
      <div className="w-full max-w-md rounded-2xl bg-white p-8 shadow-xl border border-zinc-100 text-center">
        <div className="mx-auto flex size-12 items-center justify-center rounded-full bg-blue-100 text-blue-600 mb-4">
          <KeyRound className="size-6" />
        </div>
        <h2 className="text-xl font-bold text-zinc-900 mb-2">Verify your email</h2>
        <p className="text-sm text-zinc-500 mb-6">
          Enter the 6-digit verification code sent to your email.
        </p>

        <form onSubmit={handleVerify} className="space-y-4">
          <div>
            <input
              type="text"
              maxLength={6}
              className="w-full h-14 text-center text-2xl tracking-[0.5em] font-mono border-2 border-zinc-200 rounded-xl focus:border-blue-500 focus:ring-0 outline-none transition-colors"
              placeholder="••••••"
              value={otp}
              onChange={(e) => setOtp(e.target.value.replace(/[^0-9]/g, ''))}
              autoFocus
            />
          </div>
          <Button 
            type="submit" 
            className="w-full h-12 rounded-xl bg-blue-600 hover:bg-blue-700 text-white font-medium"
            disabled={loading || otp.length !== 6}
          >
            {loading ? <Loader2 className="mr-2 h-4 w-4 animate-spin" /> : null}
            Verify & Continue
          </Button>
        </form>
      </div>
    </div>
  )
}
