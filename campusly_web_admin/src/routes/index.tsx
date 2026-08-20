import { zodResolver } from "@hookform/resolvers/zod";
import { createFileRoute, useNavigate, Link } from "@tanstack/react-router";
import {
  Eye,
  EyeOff,
  Loader2,
  Lock,
  TriangleAlert,
  CheckCircle2,
  Settings2,
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
import {
  Popover,
  PopoverContent,
  PopoverTrigger,
} from "@/components/ui/popover";
import { Slider } from "@/components/ui/slider";

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

function CampuslyMark({ className }: { className?: string }) {
  return (
    <svg viewBox="0 0 24 24" fill="none" className={className} aria-hidden>
      <path
        d="M12 2L2 7L12 12L22 7L12 2Z"
        stroke="currentColor"
        strokeWidth="2"
        strokeLinecap="round"
        strokeLinejoin="round"
        className="text-blue-600"
      />
      <path
        d="M2 17L12 22L22 17"
        stroke="currentColor"
        strokeWidth="2"
        strokeLinecap="round"
        strokeLinejoin="round"
        className="text-zinc-900"
      />
      <path
        d="M2 12L12 17L22 12"
        stroke="currentColor"
        strokeWidth="2"
        strokeLinecap="round"
        strokeLinejoin="round"
        className="text-zinc-400"
      />
    </svg>
  );
}

function buildConicGradient(count: number, color: string) {
  if (count <= 0) return "none";
  const segment = 360 / count;
  const stops = [];
  for (let i = 0; i < count; i++) {
    const start = i * segment;
    const end = start + (segment * 0.7); 
    stops.push(`transparent ${start}deg, ${color} ${end}deg, transparent ${end}deg`);
  }
  return `conic-gradient(from 0deg, ${stops.join(", ")})`;
}

const SHINE_COLORS = [
  { name: "Black", value: "#18181b" },
  { name: "Blue", value: "#2563eb" },
  { name: "Purple", value: "#9333ea" },
  { name: "Emerald", value: "#059669" },
  { name: "Rose", value: "#e11d48" },
];

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

  // Customizer State
  const [warpSpeed, setWarpSpeed] = useState(1);
  const [loginBorderCount, setLoginBorderCount] = useState(2);
  const [loginBorderColor, setLoginBorderColor] = useState("#18181b");

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
    <main className="relative flex min-h-screen flex-col items-center justify-center overflow-hidden bg-white px-4 py-12 sm:px-6 lg:px-8">
      
      <WarpStarField speedMultiplier={warpSpeed} />

      <div className="pointer-events-none absolute inset-0 bg-[radial-gradient(circle_at_center,rgba(255,255,255,0)_0%,rgba(255,255,255,0.6)_100%)]" />

      <div className="relative z-10 w-full max-w-md flex flex-col items-center">
        
        <motion.div
          initial={{ opacity: 0, y: -20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.8, ease: "easeOut" }}
          className="mb-8 flex flex-col items-center text-center"
        >
          <div className="mb-4 flex size-14 items-center justify-center rounded-2xl bg-white/50 border border-zinc-200 backdrop-blur-md shadow-sm">
            <CampuslyMark className="size-8" />
          </div>
          <h1 className="text-2xl font-bold tracking-widest text-zinc-900 uppercase mb-2">Campusly</h1>
          <h2 className="text-xl font-medium tracking-tight text-zinc-800 mb-1">Your campus, connected.</h2>
          <p className="text-sm text-zinc-500 max-w-[280px]">
            Manage your campus from one powerful admin console.
          </p>
        </motion.div>

        <AnimatePresence mode="wait">
          {!successState ? (
            <motion.div
              key="login-form"
              initial={{ opacity: 0, scale: 0.95 }}
              animate={{ opacity: 1, scale: 1 }}
              exit={{ opacity: 0, scale: 0.95 }}
              transition={{ duration: 0.5, ease: [0.22, 1, 0.36, 1], delay: 0.2 }}
              className="relative w-full overflow-hidden rounded-[24px] shadow-[0_0_24px_rgba(0,0,0,0.15)] p-[2px]"
            >
              <div className="absolute inset-0 bg-zinc-200/50" />
              {/* Spinning Conic Gradient Border - Login Container */}
              <motion.div
                animate={{ rotate: 360 }}
                transition={{ repeat: Infinity, duration: 4, ease: "linear" }}
                className="absolute inset-[-100%] z-0"
                style={{
                  background: buildConicGradient(loginBorderCount, loginBorderColor),
                }}
              />
              
              {/* Inner Translucent Panel */}
              <div 
                className="relative z-10 h-full w-full rounded-[22px] p-8 backdrop-blur-3xl"
                style={{ backgroundColor: "rgba(255, 255, 255, 0.92)" }}
              >
                <div className="mb-6 text-center">
                  <h3 className="text-2xl font-semibold tracking-tight text-zinc-900">Welcome back</h3>
                  <p className="mt-1.5 text-sm text-zinc-500">Sign in to your Campusly Admin Console</p>
                </div>

                <Button
                  type="button"
                  variant="outline"
                  className="h-12 w-full rounded-xl border-zinc-200 bg-white text-zinc-900 hover:bg-zinc-50 transition-colors relative z-20"
                  disabled={googleLoading || form.formState.isSubmitting}
                  onClick={handleGoogleSignIn}
                >
                  {googleLoading ? <Loader2 className="mr-2 size-4 animate-spin" /> : <GoogleMark className="mr-2 size-4" />}
                  Continue with Google
                </Button>

                <div className="my-6 flex items-center gap-4 relative z-20">
                  <span className="h-px flex-1 bg-zinc-200" />
                  <span className="text-xs font-medium uppercase tracking-wider text-zinc-400">
                    Or continue with email
                  </span>
                  <span className="h-px flex-1 bg-zinc-200" />
                </div>

                <Form {...form}>
                  <form onSubmit={form.handleSubmit(onSubmit)} className="space-y-4 relative z-20">
                    <FormField
                      control={form.control}
                      name="email"
                      render={({ field }) => (
                        <FormItem>
                          <FormLabel className="text-zinc-700">Work email</FormLabel>
                          <FormControl>
                            <Input
                              type="email"
                              autoComplete="email"
                              placeholder="you@college.edu.in"
                              className="h-12 rounded-xl border-zinc-200 bg-white/50 text-zinc-900 placeholder:text-zinc-400 focus-visible:ring-blue-500/50"
                              disabled={form.formState.isSubmitting}
                              {...field}
                            />
                          </FormControl>
                          <FormMessage className="text-red-500" />
                        </FormItem>
                      )}
                    />
                    <FormField
                      control={form.control}
                      name="password"
                      render={({ field }) => (
                        <FormItem>
                          <FormLabel className="text-zinc-700">Password</FormLabel>
                          <FormControl>
                            <div className="relative">
                              <Input
                                type={showPassword ? "text" : "password"}
                                autoComplete="current-password"
                                placeholder="•••••••••••••••••"
                                className="h-12 rounded-xl border-zinc-200 bg-white/50 text-zinc-900 placeholder:text-zinc-400 focus-visible:ring-blue-500/50 pr-10"
                                disabled={form.formState.isSubmitting}
                                {...field}
                              />
                              <button
                                type="button"
                                onClick={() => setShowPassword(!showPassword)}
                                className="absolute right-3 top-1/2 -translate-y-1/2 text-zinc-400 hover:text-zinc-600 transition-colors"
                                tabIndex={-1}
                              >
                                {showPassword ? <EyeOff className="size-4" /> : <Eye className="size-4" />}
                              </button>
                            </div>
                          </FormControl>
                          <FormMessage className="text-red-500" />
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
                                className="border-zinc-300 data-[state=checked]:bg-blue-600 data-[state=checked]:text-white z-20"
                              />
                            </FormControl>
                            <FormLabel className="text-sm font-normal text-zinc-500 cursor-pointer hover:text-zinc-700 z-20 relative">
                              Keep me signed in
                            </FormLabel>
                          </FormItem>
                        )}
                      />
                      <button
                        type="button"
                        className="text-sm font-medium text-blue-600 hover:text-blue-700 transition-colors hover:underline z-20 relative"
                        onClick={() => setForgotOpen(true)}
                      >
                        Forgot password?
                      </button>
                    </div>

                    {error && (
                      <motion.div
                        initial={{ opacity: 0, y: -5 }}
                        animate={{ opacity: 1, y: 0 }}
                        className="flex items-start gap-3 rounded-xl border border-red-500/20 bg-red-50 p-4 text-sm text-red-600 relative z-20"
                      >
                        <TriangleAlert className="mt-0.5 size-4 shrink-0 text-red-500" />
                        <div className="flex flex-col gap-1">
                          <span className="font-semibold text-red-700">Access Denied</span>
                          <span className="text-red-600/90">{error}</span>
                        </div>
                      </motion.div>
                    )}

                    <Button
                      type="submit"
                      className="h-12 w-full rounded-xl bg-zinc-900 text-white hover:bg-zinc-800 text-base font-medium transition-all relative z-20 shadow-lg shadow-zinc-900/20"
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

                <div className="mt-6 flex flex-col items-center justify-center gap-1.5 text-center text-xs text-zinc-500 relative z-20">
                  <div className="flex items-center gap-1.5 font-medium text-zinc-600">
                    <Lock className="size-3.5" />
                    Protected admin environment
                  </div>
                  <span>Access is restricted to authorized Campusly administrators.</span>
                  
                  <div className="mt-4 pt-4 border-t border-zinc-200 w-full text-center">
                    <span className="text-zinc-500 mr-2">Are you a student?</span>
                    <Link to="/download" className="text-blue-600 font-medium hover:underline hover:text-blue-700">
                      Download the App
                    </Link>
                  </div>
                </div>
              </div>
            </motion.div>
          ) : (
            <motion.div
              key="success-state"
              initial={{ opacity: 0, scale: 0.95 }}
              animate={{ opacity: 1, scale: 1 }}
              className="relative w-full overflow-hidden rounded-[24px] shadow-[0_0_24px_rgba(0,0,0,0.15)] p-[2px]"
            >
              <div className="absolute inset-0 bg-zinc-200/50" />
              <motion.div
                animate={{ rotate: 360 }}
                transition={{ repeat: Infinity, duration: 4, ease: "linear" }}
                className="absolute inset-[-100%] z-0"
                style={{
                  background: buildConicGradient(loginBorderCount, loginBorderColor),
                }}
              />
              <div 
                className="relative z-10 flex flex-col items-center justify-center text-center h-full w-full rounded-[22px] p-12 backdrop-blur-3xl"
                style={{ backgroundColor: "rgba(255, 255, 255, 0.92)" }}
              >
                <div className="flex size-16 items-center justify-center rounded-full bg-green-50 text-green-600 mb-6 border border-green-100 relative z-20">
                  <CheckCircle2 className="size-8" />
                </div>
                <h2 className="text-2xl font-semibold tracking-tight text-zinc-900 relative z-20">Authentication successful</h2>
                <p className="mt-3 text-sm text-zinc-500 flex items-center gap-2 justify-center relative z-20">
                  <Loader2 className="size-3.5 animate-spin text-blue-600" /> Loading your campus...
                </p>
              </div>
            </motion.div>
          )}
        </AnimatePresence>
      </div>

      <Dialog open={forgotOpen} onOpenChange={setForgotOpen}>
        <DialogContent className="rounded-2xl sm:max-w-md bg-white border-zinc-200 text-zinc-900">
          <DialogHeader>
            <DialogTitle>Reset your password</DialogTitle>
            <DialogDescription className="text-zinc-500">
              We'll email you a secure link to set a new password.
            </DialogDescription>
          </DialogHeader>
          <div className="space-y-4 pt-4">
            <Input
              type="email"
              value={resetEmail}
              onChange={(e) => setResetEmail(e.target.value)}
              placeholder="you@college.edu.in"
              className="h-12 rounded-xl border-zinc-200 bg-white text-zinc-900"
            />
            <Button
              className="h-12 w-full rounded-xl bg-zinc-900 text-white hover:bg-zinc-800"
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

      {/* Floating Settings Customizer Button */}
      <div className="fixed bottom-6 right-6 z-50">
        <Popover>
          <PopoverTrigger asChild>
            <Button 
              size="icon" 
              className="h-12 w-12 rounded-full bg-zinc-900 text-white shadow-xl hover:bg-zinc-800 transition-transform hover:scale-105"
            >
              <Settings2 className="size-5" />
            </Button>
          </PopoverTrigger>
          <PopoverContent 
            align="end" 
            sideOffset={16} 
            className="w-80 rounded-2xl border-zinc-200 bg-white p-6 shadow-2xl"
          >
            <div className="space-y-6">
              <div>
                <h4 className="font-semibold text-zinc-900 mb-1">Customize Experience</h4>
                <p className="text-xs text-zinc-500">Tweak the cinematic login effects.</p>
              </div>
              
              <div className="space-y-4">
                <div className="space-y-2">
                  <div className="flex justify-between items-center">
                    <label className="text-sm font-medium text-zinc-700">Warp Speed</label>
                    <span className="text-xs font-semibold text-zinc-500">{warpSpeed.toFixed(1)}x</span>
                  </div>
                  <Slider 
                    value={[warpSpeed]} 
                    onValueChange={([val]) => setWarpSpeed(val)} 
                    max={5} 
                    min={0.1} 
                    step={0.1} 
                  />
                </div>

                <div className="h-px bg-zinc-100" />

                <div className="space-y-3">
                  <h5 className="text-sm font-semibold text-zinc-800">Login Card Border</h5>
                  <div className="flex justify-between items-center">
                    <label className="text-xs text-zinc-600">Beams Count</label>
                    <span className="text-xs font-semibold text-zinc-500">{loginBorderCount}</span>
                  </div>
                  <Slider 
                    value={[loginBorderCount]} 
                    onValueChange={([val]) => setLoginBorderCount(val)} 
                    max={10} 
                    min={0} 
                    step={1} 
                  />
                  <div className="flex justify-between items-center pt-1">
                    <label className="text-xs text-zinc-600">Shine Color</label>
                  </div>
                  <div className="flex gap-2 flex-wrap">
                    {SHINE_COLORS.map(c => (
                      <button
                        key={c.name}
                        onClick={() => setLoginBorderColor(c.value)}
                        className={`size-6 rounded-full border-2 transition-all ${loginBorderColor === c.value ? "border-zinc-900 scale-110" : "border-transparent hover:scale-105"}`}
                        style={{ backgroundColor: c.value }}
                        title={c.name}
                      />
                    ))}
                  </div>
                </div>

              </div>
            </div>
          </PopoverContent>
        </Popover>
      </div>
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
