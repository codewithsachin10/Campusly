import { zodResolver } from "@hookform/resolvers/zod";
import { createFileRoute, useNavigate } from "@tanstack/react-router";
import {
  Eye,
  EyeOff,
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
import { WarpStarField } from "@/components/ui/warp-star-field";

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

// A modern, geometric mark for the Campusly brand
function CampuslyMark({ className }: { className?: string }) {
  return (
    <svg viewBox="0 0 24 24" fill="none" className={className} aria-hidden>
      <path
        d="M12 2L2 7L12 12L22 7L12 2Z"
        stroke="currentColor"
        strokeWidth="2"
        strokeLinecap="round"
        strokeLinejoin="round"
        className="text-[#76cefa]"
      />
      <path
        d="M2 17L12 22L22 17"
        stroke="currentColor"
        strokeWidth="2"
        strokeLinecap="round"
        strokeLinejoin="round"
        className="text-white"
      />
      <path
        d="M2 12L12 17L22 12"
        stroke="currentColor"
        strokeWidth="2"
        strokeLinecap="round"
        strokeLinejoin="round"
        className="text-white/60"
      />
    </svg>
  );
}

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
    // Force dark mode on this specific page for the cinematic effect
    document.documentElement.classList.add("dark");
    return () => document.documentElement.classList.remove("dark");
  }, []);

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
    } catch (e) {
      setError(getFriendlyErrorMessage(e instanceof Error ? e.message : "Google sign-in failed."));
      setGoogleLoading(false);
    }
  };

  return (
    <main className="relative flex min-h-screen flex-col items-center justify-center overflow-hidden bg-black px-4 py-12 sm:px-6 lg:px-8">
      
      <WarpStarField />

      {/* Subtle central radial gradient to ensure form readability over the brightest stars */}
      <div className="pointer-events-none absolute inset-0 bg-[radial-gradient(circle_at_center,rgba(0,0,0,0)_0%,rgba(0,0,0,0.6)_100%)]" />

      <div className="relative z-10 w-full max-w-md flex flex-col items-center">
        
        {/* Branding Hierarchy */}
        <motion.div
          initial={{ opacity: 0, y: -20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.8, ease: "easeOut" }}
          className="mb-8 flex flex-col items-center text-center"
        >
          <div className="mb-4 flex size-14 items-center justify-center rounded-2xl bg-white/5 border border-white/10 backdrop-blur-md shadow-2xl">
            <CampuslyMark className="size-8" />
          </div>
          <h1 className="text-2xl font-bold tracking-widest text-white uppercase mb-2">Campusly</h1>
          <h2 className="text-xl font-medium tracking-tight text-white mb-1">Your campus, connected.</h2>
          <p className="text-sm text-zinc-400 max-w-[280px]">
            Manage your campus from one powerful admin console.
          </p>
        </motion.div>

        {/* Translucent Authentication Panel */}
        <AnimatePresence mode="wait">
          {!successState ? (
            <motion.div
              key="login-form"
              initial={{ opacity: 0, scale: 0.95 }}
              animate={{ opacity: 1, scale: 1 }}
              exit={{ opacity: 0, scale: 0.95 }}
              transition={{ duration: 0.5, ease: [0.22, 1, 0.36, 1], delay: 0.2 }}
              className="w-full rounded-[24px] border border-white/10 p-8 shadow-2xl backdrop-blur-xl"
              style={{ backgroundColor: "rgba(10, 10, 15, 0.78)" }}
            >
              <div className="mb-6 text-center">
                <h3 className="text-2xl font-semibold tracking-tight text-white">Welcome back</h3>
                <p className="mt-1.5 text-sm text-zinc-400">Sign in to your Campusly Admin Console</p>
              </div>

              <Button
                type="button"
                variant="outline"
                className="h-12 w-full rounded-xl border-white/10 bg-white/5 text-white hover:bg-white/10 transition-colors"
                disabled={googleLoading || form.formState.isSubmitting}
                onClick={handleGoogleSignIn}
              >
                {googleLoading ? <Loader2 className="mr-2 size-4 animate-spin" /> : <GoogleMark className="mr-2 size-4" />}
                Continue with Google
              </Button>

              <div className="my-6 flex items-center gap-4">
                <span className="h-px flex-1 bg-white/10" />
                <span className="text-xs font-medium uppercase tracking-wider text-zinc-500">
                  Or continue with email
                </span>
                <span className="h-px flex-1 bg-white/10" />
              </div>

              <Form {...form}>
                <form onSubmit={form.handleSubmit(onSubmit)} className="space-y-4">
                  <FormField
                    control={form.control}
                    name="email"
                    render={({ field }) => (
                      <FormItem>
                        <FormLabel className="text-zinc-300">Work email</FormLabel>
                        <FormControl>
                          <Input
                            type="email"
                            autoComplete="email"
                            placeholder="you@college.edu.in"
                            className="h-12 rounded-xl border-white/10 bg-white/5 text-white placeholder:text-zinc-600 focus-visible:ring-[#76cefa]/50"
                            disabled={form.formState.isSubmitting}
                            {...field}
                          />
                        </FormControl>
                        <FormMessage className="text-red-400" />
                      </FormItem>
                    )}
                  />
                  <FormField
                    control={form.control}
                    name="password"
                    render={({ field }) => (
                      <FormItem>
                        <FormLabel className="text-zinc-300">Password</FormLabel>
                        <FormControl>
                          <div className="relative">
                            <Input
                              type={showPassword ? "text" : "password"}
                              autoComplete="current-password"
                              placeholder="•••••••••••••••••"
                              className="h-12 rounded-xl border-white/10 bg-white/5 text-white placeholder:text-zinc-600 focus-visible:ring-[#76cefa]/50 pr-10"
                              disabled={form.formState.isSubmitting}
                              {...field}
                            />
                            <button
                              type="button"
                              onClick={() => setShowPassword(!showPassword)}
                              className="absolute right-3 top-1/2 -translate-y-1/2 text-zinc-500 hover:text-white transition-colors"
                              tabIndex={-1}
                            >
                              {showPassword ? <EyeOff className="size-4" /> : <Eye className="size-4" />}
                            </button>
                          </div>
                        </FormControl>
                        <FormMessage className="text-red-400" />
                      </FormItem>
                    )}
                  />

                  <div className="flex items-center justify-between pt-2 pb-2">
                    <FormField
                      control={form.control}
                      name="remember"
                      render={({ field }) => (
                        <FormItem className="flex flex-row items-center gap-2 space-y-0">
                          <FormControl>
                            <Checkbox 
                              checked={field.value} 
                              onCheckedChange={field.onChange} 
                              disabled={form.formState.isSubmitting} 
                              className="border-white/20 data-[state=checked]:bg-[#76cefa] data-[state=checked]:text-black"
                            />
                          </FormControl>
                          <FormLabel className="text-sm font-normal text-zinc-400 cursor-pointer hover:text-zinc-300">
                            Keep me signed in
                          </FormLabel>
                        </FormItem>
                      )}
                    />
                    <button
                      type="button"
                      className="text-sm font-medium text-[#76cefa] hover:text-white transition-colors hover:underline"
                      onClick={() => setForgotOpen(true)}
                    >
                      Forgot password?
                    </button>
                  </div>

                  {error && (
                    <motion.div
                      initial={{ opacity: 0, y: -5 }}
                      animate={{ opacity: 1, y: 0 }}
                      className="flex items-start gap-3 rounded-xl border border-red-500/20 bg-red-500/10 p-4 text-sm text-red-200"
                    >
                      <TriangleAlert className="mt-0.5 size-4 shrink-0 text-red-400" />
                      <div className="flex flex-col gap-1">
                        <span className="font-semibold text-red-100">Access Denied</span>
                        <span className="text-red-200/90">{error}</span>
                      </div>
                    </motion.div>
                  )}

                  <Button
                    type="submit"
                    className="h-12 w-full rounded-xl bg-white text-black hover:bg-zinc-200 text-base font-medium transition-all"
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

              <div className="mt-6 flex flex-col items-center justify-center gap-1.5 text-center text-xs text-zinc-500">
                <div className="flex items-center gap-1.5 font-medium text-zinc-400">
                  <Lock className="size-3.5" />
                  Protected admin environment
                </div>
                <span>Access is restricted to authorized Campusly administrators.</span>
              </div>
            </motion.div>
          ) : (
            <motion.div
              key="success-state"
              initial={{ opacity: 0, scale: 0.95 }}
              animate={{ opacity: 1, scale: 1 }}
              className="flex flex-col items-center justify-center text-center w-full rounded-[24px] border border-white/10 p-12 shadow-2xl backdrop-blur-xl"
              style={{ backgroundColor: "rgba(10, 10, 15, 0.78)" }}
            >
              <div className="flex size-16 items-center justify-center rounded-full bg-green-500/20 text-green-400 mb-6 border border-green-500/20">
                <CheckCircle2 className="size-8" />
              </div>
              <h2 className="text-2xl font-semibold tracking-tight text-white">Authentication successful</h2>
              <p className="mt-3 text-sm text-zinc-400 flex items-center gap-2 justify-center">
                <Loader2 className="size-3.5 animate-spin text-[#76cefa]" /> Loading your campus...
              </p>
            </motion.div>
          )}
        </AnimatePresence>
      </div>

      <Dialog open={forgotOpen} onOpenChange={setForgotOpen}>
        <DialogContent className="rounded-2xl sm:max-w-md bg-zinc-950 border-white/10 text-white">
          <DialogHeader>
            <DialogTitle>Reset your password</DialogTitle>
            <DialogDescription className="text-zinc-400">
              We'll email you a secure link to set a new password.
            </DialogDescription>
          </DialogHeader>
          <div className="space-y-4 pt-4">
            <Input
              type="email"
              value={resetEmail}
              onChange={(e) => setResetEmail(e.target.value)}
              placeholder="you@college.edu.in"
              className="h-12 rounded-xl border-white/10 bg-white/5 text-white"
            />
            <Button
              className="h-12 w-full rounded-xl bg-white text-black hover:bg-zinc-200"
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
