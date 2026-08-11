import {
  createContext,
  useCallback,
  useContext,
  useEffect,
  useMemo,
  useState,
  type ReactNode,
} from "react";
import { supabase } from "./supabase";
import type { Admin, Permission } from "./types";
import { User } from "@supabase/supabase-js";

/**
 * Auth layer integrated with Supabase Authentication and Database.
 */

const STORAGE_KEY = "campusly.session";

interface AuthValue {
  admin: Admin | null;
  loading: boolean;
  signInWithEmail: (email: string, password: string, remember: boolean) => Promise<void>;
  signInWithGoogle: () => Promise<void>;
  resetPassword: (email: string) => Promise<void>;
  signOut: () => void;
  can: (permission: Permission) => boolean;
}

const AuthContext = createContext<AuthValue | null>(null);

export function AuthProvider({ children }: { children: ReactNode }) {
  const [admin, setAdmin] = useState<Admin | null>(null);
  const [loading, setLoading] = useState(true);

  // Load session from local storage on mount for fast apparent login
  useEffect(() => {
    try {
      const raw = localStorage.getItem(STORAGE_KEY);
      if (raw) setAdmin(JSON.parse(raw) as Admin);
    } catch {
      /* ignore corrupt session */
    }
  }, []);

  // Listen to Supabase Auth state changes
  useEffect(() => {
    const {
      data: { subscription },
    } = supabase.auth.onAuthStateChange(async (event, session) => {
      const user = session?.user;
      if (user && user.email) {
        try {
          const { data: adminData, error } = await supabase
            .from("admin_profiles")
            .select("*, roles(name)")
            .eq("email", user.email.toLowerCase())
            .single();

          if (adminData && !error) {
            setAdmin(adminData as Admin);
            localStorage.setItem(STORAGE_KEY, JSON.stringify(adminData));
          } else {
            // User authenticated but not found in admins table
            await supabase.auth.signOut();
            setAdmin(null);
            localStorage.removeItem(STORAGE_KEY);
          }
        } catch (error) {
          console.error("Error fetching admin doc:", error);
          setAdmin(null);
          localStorage.removeItem(STORAGE_KEY);
        }
      } else {
        setAdmin(null);
        localStorage.removeItem(STORAGE_KEY);
      }
      setLoading(false);
    });

    return () => {
      subscription.unsubscribe();
    };
  }, []);

  const establish = useCallback(async (user: User) => {
    const email = user.email?.toLowerCase() || "";
    const { data: adminData, error } = await supabase
      .from("admin_profiles")
      .select("*, roles(name)")
      .eq("email", email)
      .single();

    if (!adminData || error) {
      await supabase.auth.signOut();
      throw new Error("This account is not registered as a college admin.");
    }
    setAdmin(adminData as Admin);
    localStorage.setItem(STORAGE_KEY, JSON.stringify(adminData));
  }, []);

  const signInWithEmail = useCallback(
    async (email: string, password: string, remember: boolean) => {
      const { data, error } = await supabase.auth.signInWithPassword({ email, password });
      if (error) throw error;
      if (data.user) {
        await establish(data.user);
      }
    },
    [establish],
  );

  const signInWithGoogle = useCallback(async () => {
    const { error } = await supabase.auth.signInWithOAuth({ provider: "google" });
    if (error) throw error;
    // OAuth redirects, so establish will be handled by onAuthStateChange after redirect
  }, []);

  const resetPassword = useCallback(async (email: string) => {
    const { error } = await supabase.auth.resetPasswordForEmail(email);
    if (error) throw error;
  }, []);

  const signOut = useCallback(async () => {
    await supabase.auth.signOut();
    localStorage.removeItem(STORAGE_KEY);
    setAdmin(null);
  }, []);

  const can = useCallback(
    (permission: Permission) => Boolean(admin?.permissions?.includes(permission)),
    [admin],
  );

  const value = useMemo(
    () => ({ admin, loading, signInWithEmail, signInWithGoogle, resetPassword, signOut, can }),
    [admin, loading, signInWithEmail, signInWithGoogle, resetPassword, signOut, can],
  );

  return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>;
}

export function useAuth() {
  const ctx = useContext(AuthContext);
  if (!ctx) throw new Error("useAuth must be used inside AuthProvider");
  return ctx;
}
