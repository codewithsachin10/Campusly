import { zodResolver } from "@hookform/resolvers/zod";
import { createFileRoute, useNavigate } from "@tanstack/react-router";
import {
  Eye,
  EyeOff,
  GraduationCap,
  Loader2,
  Lock,
  TriangleAlert,
  CheckCircle2,
} from "lucide-react";
import { motion, AnimatePresence } from "motion/react";
import { useEffect, useState } from "react";
import { useForm } from "react-hook-form";
import { toast } from "sonner";
import { z } from "zod";

import { Button } from "@/components/ui/button";
import { Checkbox } from "@/components/ui/checkbox";
import {
  Form,
  FormControl,
  FormField,
  FormItem,
  FormLabel,
  FormMessage,
} from "@/components/ui/form";
import { Input } from "@/components/ui/input";
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogHeader,
  DialogTitle,
} from "@/components/ui/dialog";
import { useAuth } from "@/lib/auth";
import { RippleGrid } from "@/components/ui/ripple-grid";

export const Route = createFileRoute("/")({
  head: () => ({
    meta: [
      { title: "Sign in — Campusly Admin" },
      {
        name: "description",
        content: "Secure admin sign-in for the Campusly college management console.",
      },
    ],
  }),
  component: LoginPage,
});

const schema = z.object({
  email: z.string().trim().email("Enter a valid email address."),
  password: z.string().min(6, "Password must be at least 6 characters."),
  remember: z.boolean(),
});

function LoginPage() {
  const { admin, loading, signInWithEmail, signInWithGoogle, resetPassword } = useAuth();
  const navigate = useNavigate();
  const [error, setError] = useState<string | null>(null);
  const [googleLoading, setGoogleLoading] = useState(false);
  const [forgotOpen, setForgotOpen] = useState(false);
  const [resetEmail, setResetEmail] = useState("");
  const [resetting, setResetting] = useState(false);
  const [showPassword, setShowPassword] = useState(false);
  const [successState, setSuccessState] = useState(false);

  useEffect(() => {
    if (!loading && admin) navigate({ to: "/dashboard", replace: true });
  }, [admin, loading, navigate]);

  const form = useForm<z.infer<typeof schema>>({
    resolver: zodResolver(schema),
    defaultValues: { email: "", password: "", remember: true },
  });

  const getFriendlyErrorMessage = (rawError: string) => {
    const err = rawError.toLowerCase();
    if (err.includes("invalid login credentials") || err.includes("wrong password")) {
      return "Incorrect password. Check your password and try again.";
    }
    if (err.includes("not authorized") || err.includes("admin")) {
      return "Your account isn't authorized to access the Campusly Admin Console.";
    }
    if (err.includes("network") || err.includes("fetch")) {
      return "Couldn't connect. Check your internet connection and try again.";
    }
    return "Something went wrong. Campusly couldn't verify your account right now.";
  };

  const onSubmit = async (values: z.infer<typeof schema>) => {
    setError(null);
    try {
      await signInWithEmail(values.email, values.password, values.remember);
      setSuccessState(true);
      setTimeout(() => {
        navigate({ to: "/dashboard", replace: true });
      }, 1500);
    } catch (e) {
      setError(getFriendlyErrorMessage(e instanceof Error ? e.message : "Unable to sign in."));
    }
  };

  const handleGoogleSignIn = async () => {
    setGoogleLoading(true);
    setError(null);
    try {
      await signInWithGoogle();
      // Note: Google sign-in redirects automatically in most Supabase setups,
      // so this might not fully execute depending on the OAuth flow.
    } catch (e) {
      setError(getFriendlyErrorMessage(e instanceof Error ? e.message : "Google sign-in failed."));
      setGoogleLoading(false);
    }
  };

  return (
    <main className="flex min-h-screen flex-col lg:grid lg:grid-cols-2 bg-background">
      {/* Left Panel - Branding & Animation */}
      <div className="relative hidden lg:flex flex-col justify-between overflow-hidden bg-zinc-950 px-12 py-16 text-white">
        <div className="absolute inset-0 opacity-20 pointer-events-auto">
          <RippleGrid
            size={24}
            cellSize={40}
            cellColor="transparent"
            borderColor="rgba(255,255,255,0.1)"
            pulseColor="rgba(255,255,255,0.4)"
            pulseDuration={600}
            rippleDelay={80}
          />
        </div>
        
        {/* Gradient Overlay for text readability */}
        <div className="absolute inset-0 bg-gradient-to-b from-zinc-950/50 via-transparent to-zinc-950/80 pointer-events-none" />

        <div className="relative z-10">
          <motion.div
            initial={{ opacity: 0, y: 10 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.6 }}
            className="flex items-center gap-3"
          >
            <div className="flex size-10 items-center justify-center rounded-xl bg-white text-zinc-950">
              <GraduationCap className="size-6" />
            </div>
            <span className="text-xl font-bold tracking-tight">Campusly</span>
          </motion.div>
          <motion.h1
            initial={{ opacity: 0, y: 10 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.6, delay: 0.1 }}
            className="mt-12 text-4xl font-semibold leading-tight tracking-tight lg:text-5xl"
          >
            Your campus, <br />
            <span className="text-zinc-400">connected.</span>
          </motion.h1>
          <motion.p
            initial={{ opacity: 0, y: 10 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.6, delay: 0.2 }}
            className="mt-6 max-w-md text-lg text-zinc-400"
          >
            Everything your college needs to manage students, timetables, and faculty in one secure place.
          </motion.p>
        </div>

        <div className="relative z-10 flex flex-col gap-6">
          <motion.div
            initial={{ opacity: 0, x: -20 }}
            animate={{ opacity: 1, x: 0 }}
            transition={{ duration: 0.8, delay: 0.4 }}
            className="flex max-w-sm flex-col gap-4 rounded-2xl border border-white/10 bg-white/5 p-6 backdrop-blur-md"
          >
            <div className="flex items-center justify-between">
              <span className="text-sm font-medium text-zinc-300">Live Campus Overview</span>
              <span className="flex size-2 rounded-full bg-green-500 shadow-[0_0_8px_rgba(34,197,94,0.6)]" />
            </div>
            <div className="grid grid-cols-2 gap-4">
              <div>
                <p className="text-2xl font-semibold">1,248</p>
                <p className="text-xs text-zinc-500">Active Students</p>
              </div>
              <div>
                <p className="text-2xl font-semibold">42</p>
                <p className="text-xs text-zinc-500">Departments</p>
              </div>
            </div>
          </motion.div>

          <motion.div
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            transition={{ duration: 0.8, delay: 0.6 }}
            className="flex items-center gap-4 text-sm font-medium text-zinc-500"
          >
            <div className="flex items-center gap-2">
              <Lock className="size-4" /> Secure Admin
            </div>
            <div className="size-1 rounded-full bg-zinc-700" />
            <div>SSO Enabled</div>
          </motion.div>
        </div>
      </div>

      {/* Right Panel - Authentication */}
      <div className="flex flex-1 flex-col items-center justify-center px-4 py-12 sm:px-6 lg:px-8">
        <AnimatePresence mode="wait">
          {!successState ? (
            <motion.div
              key="login-form"
              initial={{ opacity: 0, scale: 0.96 }}
              animate={{ opacity: 1, scale: 1 }}
              exit={{ opacity: 0, scale: 0.96 }}
              transition={{ duration: 0.4, ease: [0.22, 1, 0.36, 1] }}
              className="w-full max-w-[420px]"
            >
              <div className="mb-8 flex flex-col items-center gap-3 text-center lg:hidden">
                <span className="flex size-12 items-center justify-center rounded-2xl bg-primary text-primary-foreground">
                  <GraduationCap className="size-6" />
                </span>
                <h1 className="text-2xl font-semibold tracking-tight">Campusly Admin</h1>
              </div>

              <div className="mb-8 text-center lg:text-left">
                <h2 className="text-3xl font-semibold tracking-tight text-foreground">Welcome back</h2>
                <p className="mt-2 text-sm text-muted-foreground">Sign in to your console</p>
              </div>

              <Button
                type="button"
                variant="outline"
                className="h-12 w-full rounded-xl bg-background hover:bg-muted/50 transition-colors"
                disabled={googleLoading || form.formState.isSubmitting}
                onClick={handleGoogleSignIn}
              >
                {googleLoading ? <Loader2 className="mr-2 size-4 animate-spin" /> : <GoogleMark className="mr-2 size-4" />}
                Continue with Google
              </Button>

              <div className="my-8 flex items-center gap-4">
                <span className="h-px flex-1 bg-border" />
                <span className="text-xs font-medium uppercase tracking-wider text-muted-foreground">
                  Or continue with email
                </span>
                <span className="h-px flex-1 bg-border" />
              </div>

              <Form {...form}>
                <form onSubmit={form.handleSubmit(onSubmit)} className="space-y-5">
                  <FormField
                    control={form.control}
                    name="email"
                    render={({ field }) => (
                      <FormItem>
                        <FormLabel className="text-foreground">Work email</FormLabel>
                        <FormControl>
                          <Input
                            type="email"
                            autoComplete="email"
                            placeholder="you@college.edu"
                            className="h-12 rounded-xl bg-background"
                            disabled={form.formState.isSubmitting}
                            {...field}
                          />
                        </FormControl>
                        <FormMessage />
                      </FormItem>
                    )}
                  />
                  <FormField
                    control={form.control}
                    name="password"
                    render={({ field }) => (
                      <FormItem>
                        <FormLabel className="text-foreground">Password</FormLabel>
                        <FormControl>
                          <div className="relative">
                            <Input
                              type={showPassword ? "text" : "password"}
                              autoComplete="current-password"
                              placeholder="••••••••"
                              className="h-12 rounded-xl bg-background pr-10"
                              disabled={form.formState.isSubmitting}
                              {...field}
                            />
                            <button
                              type="button"
                              onClick={() => setShowPassword(!showPassword)}
                              className="absolute right-3 top-1/2 -translate-y-1/2 text-muted-foreground hover:text-foreground transition-colors"
                              tabIndex={-1}
                            >
                              {showPassword ? <EyeOff className="size-4" /> : <Eye className="size-4" />}
                            </button>
                          </div>
                        </FormControl>
                        <FormMessage />
                      </FormItem>
                    )}
                  />

                  <div className="flex items-center justify-between pt-1">
                    <FormField
                      control={form.control}
                      name="remember"
                      render={({ field }) => (
                        <FormItem className="flex flex-row items-center gap-2 space-y-0">
                          <FormControl>
                            <Checkbox checked={field.value} onCheckedChange={field.onChange} disabled={form.formState.isSubmitting} />
                          </FormControl>
                          <FormLabel className="text-sm font-normal text-muted-foreground cursor-pointer">
                            Keep me signed in
                          </FormLabel>
                        </FormItem>
                      )}
                    />
                    <button
                      type="button"
                      className="text-sm font-medium text-primary hover:underline"
                      onClick={() => setForgotOpen(true)}
                    >
                      Forgot password?
                    </button>
                  </div>

                  {error && (
                    <motion.div
                      initial={{ opacity: 0, y: -10 }}
                      animate={{ opacity: 1, y: 0 }}
                      className="flex items-start gap-3 rounded-xl border border-destructive/20 bg-destructive/5 p-4 text-sm text-destructive"
                    >
                      <TriangleAlert className="mt-0.5 size-4 shrink-0" />
                      <div className="flex flex-col gap-1">
                        <span className="font-semibold">Access Denied</span>
                        <span className="text-destructive/90">{error}</span>
                      </div>
                    </motion.div>
                  )}

                  <Button
                    type="submit"
                    className="h-12 w-full rounded-xl text-base font-medium shadow-sm transition-all"
                    disabled={form.formState.isSubmitting || googleLoading}
                  >
                    {form.formState.isSubmitting ? (
                      <>
                        <Loader2 className="mr-2 size-4 animate-spin" />
                        Signing in...
                      </>
                    ) : (
                      "Sign in"
                    )}
                  </Button>
                </form>
              </Form>

              <div className="mt-8 flex items-center justify-center gap-2 rounded-xl bg-muted/40 px-4 py-3 text-xs font-medium text-muted-foreground">
                <Lock className="size-3.5" />
                Protected admin environment. Access is restricted.
              </div>
            </motion.div>
          ) : (
            <motion.div
              key="success-state"
              initial={{ opacity: 0, scale: 0.96 }}
              animate={{ opacity: 1, scale: 1 }}
              className="flex flex-col items-center justify-center text-center w-full max-w-[420px]"
            >
              <div className="flex size-16 items-center justify-center rounded-full bg-green-500/10 text-green-600 mb-6">
                <CheckCircle2 className="size-8" />
              </div>
              <h2 className="text-2xl font-semibold tracking-tight text-foreground">Authentication successful</h2>
              <p className="mt-2 text-sm text-muted-foreground flex items-center gap-2 justify-center">
                <Loader2 className="size-3.5 animate-spin" /> Loading your campus...
              </p>
            </motion.div>
          )}
        </AnimatePresence>

        {/* Footer */}
        <div className="fixed bottom-6 flex w-full max-w-[420px] items-center justify-between px-4 text-xs text-muted-foreground lg:absolute lg:right-8 lg:w-auto lg:px-0">
          <div className="hidden lg:block">Campusly Admin v1.0.0</div>
          <div className="flex w-full justify-center gap-4 lg:w-auto lg:justify-end">
            <a href="#" className="hover:text-foreground transition-colors">Support</a>
            <span>&middot;</span>
            <a href="#" className="hover:text-foreground transition-colors">Privacy</a>
            <span>&middot;</span>
            <a href="#" className="hover:text-foreground transition-colors">Terms</a>
          </div>
        </div>
      </div>

      <Dialog open={forgotOpen} onOpenChange={setForgotOpen}>
        <DialogContent className="rounded-2xl sm:max-w-md">
          <DialogHeader>
            <DialogTitle>Reset your password</DialogTitle>
            <DialogDescription>
              We'll email you a secure link to set a new password.
            </DialogDescription>
          </DialogHeader>
          <div className="space-y-4 pt-4">
            <Input
              type="email"
              value={resetEmail}
              onChange={(e) => setResetEmail(e.target.value)}
              placeholder="you@college.edu"
              className="h-12 rounded-xl"
            />
            <Button
              className="h-12 w-full rounded-xl"
              disabled={resetting || !resetEmail}
              onClick={async () => {
                setResetting(true);
                try {
                  await resetPassword(resetEmail);
                  toast.success("Reset link sent", {
                    description: `Check ${resetEmail} for instructions.`,
                  });
                  setForgotOpen(false);
                  setResetEmail("");
                } catch (e) {
                  toast.error(e instanceof Error ? e.message : "Could not send reset link.");
                } finally {
                  setResetting(false);
                }
              }}
            >
              {resetting && <Loader2 className="mr-2 size-4 animate-spin" />}
              Send reset link
            </Button>
          </div>
        </DialogContent>
      </Dialog>
    </main>
  );
}

function GoogleMark({ className }: { className?: string }) {
  return (
    <svg viewBox="0 0 24 24" className={className} aria-hidden>
      <path
        fill="#4285F4"
        d="M23.5 12.3c0-.9-.1-1.6-.2-2.3H12v4.5h6.5a5.6 5.6 0 0 1-2.4 3.6v3h3.9c2.3-2.1 3.5-5.2 3.5-8.8Z"
      />
      <path
        fill="#34A853"
        d="M12 24c3.2 0 5.9-1.1 7.9-2.9l-3.9-3c-1 .7-2.3 1.1-4 1.1-3 0-5.6-2-6.6-4.8H1.4v3C3.4 21.3 7.4 24 12 24Z"
      />
      <path fill="#FBBC05" d="M5.4 14.4a7.2 7.2 0 0 1 0-4.6v-3H1.4a12 12 0 0 0 0 10.6l4-3Z" />
      <path
        fill="#EA4335"
        d="M12 4.8c1.7 0 3.3.6 4.5 1.8l3.4-3.4C17.9 1.2 15.2 0 12 0 7.4 0 3.4 2.7 1.4 6.8l4 3C6.4 6.9 9 4.8 12 4.8Z"
      />
    </svg>
  );
}
