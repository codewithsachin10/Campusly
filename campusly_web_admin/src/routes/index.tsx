import { zodResolver } from "@hookform/resolvers/zod";
import { createFileRoute, useNavigate } from "@tanstack/react-router";
import { GraduationCap, Loader2, TriangleAlert } from "lucide-react";
import { motion } from "motion/react";
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

export const Route = createFileRoute("/")({
  head: () => ({
    meta: [
      { title: "Sign in — Campusly Admin" },
      {
        name: "description",
        content: "Secure admin sign-in for the Campusly college management console.",
      },
      { property: "og:title", content: "Sign in — Campusly Admin" },
      {
        property: "og:description",
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

  useEffect(() => {
    if (!loading && admin) navigate({ to: "/dashboard", replace: true });
  }, [admin, loading, navigate]);

  const form = useForm<z.infer<typeof schema>>({
    resolver: zodResolver(schema),
    defaultValues: { email: "", password: "", remember: true },
  });

  const onSubmit = async (values: z.infer<typeof schema>) => {
    setError(null);
    try {
      await signInWithEmail(values.email, values.password, values.remember);
      toast.success("Welcome back to Campusly Admin");
      navigate({ to: "/dashboard", replace: true });
    } catch (e) {
      setError(e instanceof Error ? e.message : "Unable to sign in.");
    }
  };

  return (
    <main className="flex min-h-screen items-center justify-center bg-background px-4 py-12">
      <motion.div
        initial={{ opacity: 0, y: 12 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ duration: 0.4, ease: [0.22, 1, 0.36, 1] }}
        className="w-full max-w-[420px]"
      >
        <div className="mb-8 flex flex-col items-center gap-3 text-center">
          <span className="flex size-12 items-center justify-center rounded-2xl bg-primary text-primary-foreground">
            <GraduationCap className="size-6" />
          </span>
          <div className="space-y-1">
            <h1 className="text-2xl font-semibold tracking-tight">Campusly Admin</h1>
            <p className="text-sm text-muted-foreground">Sign in to manage your college.</p>
          </div>
        </div>

        <div className="surface p-6 sm:p-8">
          <Button
            variant="outline"
            className="h-11 w-full rounded-xl"
            disabled={googleLoading}
            onClick={async () => {
              setGoogleLoading(true);
              setError(null);
              try {
                await signInWithGoogle();
                navigate({ to: "/dashboard", replace: true });
              } catch {
                setError("Google sign-in failed. Please try again.");
              } finally {
                setGoogleLoading(false);
              }
            }}
          >
            {googleLoading ? <Loader2 className="size-4 animate-spin" /> : <GoogleMark />}
            Continue with Google
          </Button>

          <div className="my-6 flex items-center gap-3">
            <span className="h-px flex-1 bg-border" />
            <span className="text-xs text-muted-foreground">or sign in with email</span>
            <span className="h-px flex-1 bg-border" />
          </div>

          <Form {...form}>
            <form onSubmit={form.handleSubmit(onSubmit)} className="space-y-4">
              <FormField
                control={form.control}
                name="email"
                render={({ field }) => (
                  <FormItem>
                    <FormLabel>Email</FormLabel>
                    <FormControl>
                      <Input
                        type="email"
                        autoComplete="email"
                        placeholder="you@college.edu"
                        className="h-11 rounded-xl"
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
                    <FormLabel>Password</FormLabel>
                    <FormControl>
                      <Input
                        type="password"
                        autoComplete="current-password"
                        placeholder="••••••••"
                        className="h-11 rounded-xl"
                        {...field}
                      />
                    </FormControl>
                    <FormMessage />
                  </FormItem>
                )}
              />

              <div className="flex items-center justify-between">
                <FormField
                  control={form.control}
                  name="remember"
                  render={({ field }) => (
                    <FormItem className="flex flex-row items-center gap-2 space-y-0">
                      <FormControl>
                        <Checkbox checked={field.value} onCheckedChange={field.onChange} />
                      </FormControl>
                      <FormLabel className="text-sm font-normal text-muted-foreground">
                        Remember me
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
                <div className="flex items-start gap-2 rounded-xl border border-destructive/30 bg-destructive/5 p-3 text-sm text-destructive">
                  <TriangleAlert className="mt-0.5 size-4 shrink-0" />
                  <span>{error}</span>
                </div>
              )}

              <Button
                type="submit"
                className="h-11 w-full rounded-xl"
                disabled={form.formState.isSubmitting}
              >
                {form.formState.isSubmitting && <Loader2 className="size-4 animate-spin" />}
                Sign in
              </Button>
            </form>
          </Form>
        </div>

        <p className="mt-6 text-center text-xs text-muted-foreground">
          Access is restricted to accounts listed in your college's admin directory.
        </p>
      </motion.div>

      <Dialog open={forgotOpen} onOpenChange={setForgotOpen}>
        <DialogContent className="rounded-2xl sm:max-w-md">
          <DialogHeader>
            <DialogTitle>Reset your password</DialogTitle>
            <DialogDescription>
              We'll email you a secure link to set a new password.
            </DialogDescription>
          </DialogHeader>
          <div className="space-y-4">
            <Input
              type="email"
              value={resetEmail}
              onChange={(e) => setResetEmail(e.target.value)}
              placeholder="you@college.edu"
              className="h-11 rounded-xl"
            />
            <Button
              className="h-11 w-full rounded-xl"
              disabled={resetting}
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
              {resetting && <Loader2 className="size-4 animate-spin" />}
              Send reset link
            </Button>
          </div>
        </DialogContent>
      </Dialog>
    </main>
  );
}

function GoogleMark() {
  return (
    <svg viewBox="0 0 24 24" className="size-4" aria-hidden>
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
