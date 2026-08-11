import { Outlet, createFileRoute, useNavigate, Link } from "@tanstack/react-router";
import { Loader2, ShieldAlert, KeyRound } from "lucide-react";
import { useEffect } from "react";
import { AppSidebar } from "@/components/layout/app-sidebar";
import { Topbar } from "@/components/layout/topbar";
import { SidebarInset, SidebarProvider } from "@/components/ui/sidebar";
import { useAuth } from "@/lib/auth";

export const Route = createFileRoute("/_app")({
  component: AppLayout,
});

function AppLayout() {
  const { admin, loading } = useAuth();
  const navigate = useNavigate();

  useEffect(() => {
    if (!loading && !admin) navigate({ to: "/", replace: true });
  }, [admin, loading, navigate]);

  if (loading || !admin) {
    return (
      <div className="flex min-h-screen items-center justify-center bg-background">
        <Loader2 className="size-5 animate-spin text-muted-foreground" />
      </div>
    );
  }

  // --- GATE: OTP Verification ---
  if ((admin as any).status === 'Pending_Verification') {
    return (
      <div className="flex min-h-screen items-center justify-center bg-zinc-50 p-4">
        <div className="w-full max-w-md rounded-2xl bg-white p-8 shadow-xl border border-zinc-100 text-center">
          <div className="mx-auto flex size-12 items-center justify-center rounded-full bg-blue-100 text-blue-600 mb-4">
            <KeyRound className="size-6" />
          </div>
          <h2 className="text-xl font-bold text-zinc-900 mb-2">Verify your email</h2>
          <p className="text-sm text-zinc-500 mb-6">
            We sent a 6-digit verification code to your email. Please verify your account to continue.
          </p>
          <Link 
            to="/verify-otp" 
            className="inline-flex h-10 w-full items-center justify-center rounded-lg bg-blue-600 px-4 py-2 text-sm font-medium text-white hover:bg-blue-700 transition-colors"
          >
            Enter Verification Code
          </Link>
        </div>
      </div>
    )
  }

  // --- GATE: Pending Role Assignment ---
  if ((admin as any).status === 'Pending_Role') {
    return (
      <div className="flex min-h-screen items-center justify-center bg-zinc-50 p-4">
        <div className="w-full max-w-md rounded-2xl bg-white p-8 shadow-xl border border-zinc-100 text-center">
          <div className="mx-auto flex size-12 items-center justify-center rounded-full bg-amber-100 text-amber-600 mb-4">
            <ShieldAlert className="size-6" />
          </div>
          <h2 className="text-xl font-bold text-zinc-900 mb-2">Waiting for Role Assignment</h2>
          <p className="text-sm text-zinc-500 mb-6">
            Your account has been verified, but a Super Admin needs to assign your role before you can access the dashboard.
          </p>
          <button onClick={() => window.location.reload()} className="text-sm font-medium text-blue-600 hover:underline">
            Check again
          </button>
        </div>
      </div>
    )
  }

  return (
    <SidebarProvider>
      <div className="flex min-h-screen w-full bg-background">
        <AppSidebar />
        <SidebarInset className="bg-background">
          <Topbar />
          <main className="flex-1 px-4 py-6 sm:px-8 sm:py-8">
            <div className="mx-auto w-full max-w-[1400px] space-y-8">
              <Outlet />
            </div>
          </main>
        </SidebarInset>
      </div>
    </SidebarProvider>
  );
}
