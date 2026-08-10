import { zodResolver } from "@hookform/resolvers/zod";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { createFileRoute } from "@tanstack/react-router";
import { Check, Eye, EyeOff, KeyRound, Loader2, Monitor, Moon, Save, Sun } from "lucide-react";
import { useState } from "react";
import { useForm } from "react-hook-form";
import { toast } from "sonner";
import { z } from "zod";
import { Form, SelectField } from "@/components/form-fields";
import { PageHeader } from "@/components/page-header";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Switch } from "@/components/ui/switch";
import { api, settingsQueries } from "@/lib/services";
import { useTheme, type ThemePreference } from "@/lib/theme";
import type { AppSettings } from "@/lib/types";
import { cn } from "@/lib/utils";

export const Route = createFileRoute("/_app/settings")({
  head: () => ({
    meta: [
      { title: "Settings — Campusly Admin" },
      {
        name: "description",
        content:
          "Set academic defaults, appearance theme, notification channels and change your admin password.",
      },
      { property: "og:title", content: "Settings — Campusly Admin" },
      {
        property: "og:description",
        content:
          "Set academic defaults, appearance theme, notification channels and change your admin password.",
      },
    ],
  }),
  component: SettingsPage,
});

/* -------------------------------- schemas -------------------------------- */

const preferencesSchema = z.object({
  academicYear: z
    .string()
    .trim()
    .regex(/^\d{4}-\d{2}$/, "Use the format 2025-26."),
  weekStart: z.enum(["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]),
  periodsPerDay: z.number().min(4).max(10),
});
type PreferencesForm = z.input<typeof preferencesSchema>;

const passwordSchema = z
  .object({
    currentPassword: z.string().min(1, "Enter your current password."),
    newPassword: z
      .string()
      .min(8, "Use at least 8 characters.")
      .regex(/[A-Z]/, "Add at least one uppercase letter.")
      .regex(/[a-z]/, "Add at least one lowercase letter.")
      .regex(/\d/, "Add at least one number.")
      .regex(/[^A-Za-z0-9]/, "Add at least one symbol."),
    confirmPassword: z.string(),
  })
  .refine((v) => v.newPassword === v.confirmPassword, {
    message: "Passwords do not match.",
    path: ["confirmPassword"],
  });
type PasswordForm = z.infer<typeof passwordSchema>;

const themeOptions: { value: ThemePreference; label: string; icon: typeof Sun }[] = [
  { value: "light", label: "Light", icon: Sun },
  { value: "dark", label: "Dark", icon: Moon },
  { value: "system", label: "System", icon: Monitor },
];

const toggles: { key: keyof AppSettings; label: string; description: string }[] = [
  {
    key: "emailNotifications",
    label: "Email notifications",
    description: "Receive admin alerts and approvals by email.",
  },
  {
    key: "pushNotifications",
    label: "Push notifications",
    description: "Browser push for urgent college-wide notices.",
  },
  {
    key: "weeklyDigest",
    label: "Weekly digest",
    description: "A Monday summary of attendance, exams and events.",
  },
  {
    key: "twoFactor",
    label: "Two-factor authentication",
    description: "Ask for a one-time code on every new sign-in.",
  },
];

function SettingsPage() {
  const qc = useQueryClient();
  const settings = useQuery(settingsQueries.get());
  const { preference, setPreference } = useTheme();

  const form = useForm<PreferencesForm>({
    resolver: zodResolver(preferencesSchema),
    defaultValues: { academicYear: "2025-26", weekStart: "Monday", periodsPerDay: 6 },
    ...(settings.data
      ? {
          values: {
            academicYear: settings.data.academicYear,
            weekStart: settings.data.weekStart,
            periodsPerDay: settings.data.periodsPerDay,
          },
        }
      : {}),
  });

  const savePreferences = useMutation({
    mutationFn: (values: PreferencesForm) => api.settings.update(preferencesSchema.parse(values)),
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ["settings"] });
      toast.success("Preferences saved");
    },
    onError: () => toast.error("Could not save preferences."),
  });

  const saveToggle = useMutation({
    mutationFn: (patch: Partial<AppSettings>) => api.settings.update(patch),
    onSuccess: () => qc.invalidateQueries({ queryKey: ["settings"] }),
    onError: () => toast.error("Could not update that setting."),
  });

  return (
    <>
      <PageHeader
        title="Settings"
        description="Academic defaults, appearance, notifications and account security."
        crumbs={[{ label: "Settings" }]}
      />

      {/* Appearance */}
      <section className="surface p-6">
        <h2 className="font-medium">Appearance</h2>
        <p className="mt-1 text-sm text-muted-foreground">
          Choose how Campusly Admin looks on this device.
        </p>
        <div className="mt-5 grid gap-3 sm:grid-cols-3">
          {themeOptions.map(({ value, label, icon: Icon }) => {
            const active = preference === value;
            return (
              <button
                key={value}
                type="button"
                onClick={() => {
                  setPreference(value);
                  toast.success(`${label} theme applied`);
                }}
                className={cn(
                  "flex items-center gap-3 rounded-xl border p-4 text-left transition-colors",
                  active ? "border-primary bg-primary/5" : "border-border hover:bg-muted/60",
                )}
              >
                <span
                  className={cn(
                    "flex size-9 items-center justify-center rounded-lg",
                    active ? "bg-primary/10 text-primary" : "bg-muted text-muted-foreground",
                  )}
                >
                  <Icon className="size-4" />
                </span>
                <span className="flex-1">
                  <span className="block text-sm font-medium">{label}</span>
                  <span className="block text-xs text-muted-foreground">
                    {value === "system" ? "Follow OS setting" : `Always ${label.toLowerCase()}`}
                  </span>
                </span>
                {active && <Check className="size-4 text-primary" />}
              </button>
            );
          })}
        </div>
      </section>

      {/* Academic preferences */}
      <section className="surface p-6">
        <h2 className="font-medium">Academic defaults</h2>
        <p className="mt-1 text-sm text-muted-foreground">
          Used when creating timetables, exams and attendance records.
        </p>
        {settings.isPending ? (
          <div className="flex h-40 items-center justify-center">
            <Loader2 className="size-5 animate-spin text-muted-foreground" />
          </div>
        ) : (
          <Form {...form}>
            <form
              onSubmit={form.handleSubmit((v) => savePreferences.mutate(v))}
              className="mt-5 space-y-5"
            >
              <div className="grid gap-5 sm:grid-cols-3">
                <SelectField
                  control={form.control}
                  name="academicYear"
                  label="Academic year"
                  options={["2024-25", "2025-26", "2026-27"]}
                />
                <SelectField
                  control={form.control}
                  name="weekStart"
                  label="Week starts on"
                  options={["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]}
                />
                <SelectField
                  control={form.control}
                  name="periodsPerDay"
                  label="Periods per day"
                  numeric
                  options={[4, 5, 6, 7, 8]}
                />
              </div>
              <div className="flex justify-end">
                <Button type="submit" className="rounded-lg" disabled={savePreferences.isPending}>
                  {savePreferences.isPending ? (
                    <Loader2 className="size-4 animate-spin" />
                  ) : (
                    <Save className="size-4" />
                  )}
                  Save preferences
                </Button>
              </div>
            </form>
          </Form>
        )}
      </section>

      {/* Notifications & security toggles */}
      <section className="surface divide-y p-2">
        {toggles.map(({ key, label, description }) => (
          <div key={key} className="flex items-center justify-between gap-6 px-4 py-4">
            <div className="space-y-0.5">
              <p className="text-sm font-medium">{label}</p>
              <p className="text-sm text-muted-foreground">{description}</p>
            </div>
            <Switch
              checked={Boolean(settings.data?.[key])}
              disabled={settings.isPending}
              onCheckedChange={(checked) => {
                saveToggle.mutate({ [key]: checked } as Partial<AppSettings>);
                toast.success(`${label} ${checked ? "enabled" : "disabled"}`);
              }}
            />
          </div>
        ))}
      </section>

      <PasswordSection />
    </>
  );
}

/* ---------------------------- password section ---------------------------- */

function strengthOf(value: string) {
  const checks = [
    value.length >= 8,
    /[A-Z]/.test(value),
    /[a-z]/.test(value),
    /\d/.test(value),
    /[^A-Za-z0-9]/.test(value),
  ];
  return checks.filter(Boolean).length;
}

const strengthLabels = ["Very weak", "Weak", "Fair", "Good", "Strong"];

function PasswordSection() {
  const [show, setShow] = useState(false);
  const {
    register,
    handleSubmit,
    reset,
    watch,
    formState: { errors, isSubmitting },
  } = useForm<PasswordForm>({
    resolver: zodResolver(passwordSchema),
    defaultValues: { currentPassword: "", newPassword: "", confirmPassword: "" },
  });

  const newPassword = watch("newPassword") ?? "";
  const score = strengthOf(newPassword);

  async function onSubmit(values: PasswordForm) {
    try {
      await api.settings.changePassword(values.currentPassword, values.newPassword);
      reset();
      toast.success("Password changed", {
        description: "Use your new password the next time you sign in.",
      });
    } catch (error) {
      toast.error(error instanceof Error ? error.message : "Could not change your password.");
    }
  }

  return (
    <section className="surface p-6">
      <div className="flex items-center gap-2">
        <KeyRound className="size-4 text-primary" />
        <h2 className="font-medium">Change password</h2>
      </div>
      <p className="mt-1 text-sm text-muted-foreground">
        You'll be asked for your current password. Passwords are never shown in plain text after
        saving.
      </p>

      <form onSubmit={handleSubmit(onSubmit)} className="mt-6 max-w-xl space-y-5">
        <div className="space-y-2">
          <Label htmlFor="currentPassword">Current password</Label>
          <Input
            id="currentPassword"
            type="password"
            autoComplete="current-password"
            className="h-10 rounded-lg"
            {...register("currentPassword")}
          />
          {errors.currentPassword && (
            <p className="text-sm text-destructive">{errors.currentPassword.message}</p>
          )}
        </div>

        <div className="space-y-2">
          <Label htmlFor="newPassword">New password</Label>
          <div className="relative">
            <Input
              id="newPassword"
              type={show ? "text" : "password"}
              autoComplete="new-password"
              className="h-10 rounded-lg pr-10"
              {...register("newPassword")}
            />
            <button
              type="button"
              onClick={() => setShow((s) => !s)}
              aria-label={show ? "Hide password" : "Show password"}
              className="absolute right-3 top-1/2 -translate-y-1/2 text-muted-foreground hover:text-foreground"
            >
              {show ? <EyeOff className="size-4" /> : <Eye className="size-4" />}
            </button>
          </div>
          <div className="flex items-center gap-2">
            <div className="flex h-1.5 flex-1 gap-1">
              {[0, 1, 2, 3, 4].map((i) => (
                <span
                  key={i}
                  className={cn(
                    "flex-1 rounded-full transition-colors",
                    i < score
                      ? score <= 2
                        ? "bg-destructive"
                        : score === 3
                          ? "bg-amber-500"
                          : "bg-emerald-500"
                      : "bg-muted",
                  )}
                />
              ))}
            </div>
            <span className="w-20 text-right text-xs text-muted-foreground">
              {newPassword ? strengthLabels[Math.max(score - 1, 0)] : ""}
            </span>
          </div>
          {errors.newPassword && (
            <p className="text-sm text-destructive">{errors.newPassword.message}</p>
          )}
        </div>

        <div className="space-y-2">
          <Label htmlFor="confirmPassword">Confirm new password</Label>
          <Input
            id="confirmPassword"
            type="password"
            autoComplete="new-password"
            className="h-10 rounded-lg"
            {...register("confirmPassword")}
          />
          {errors.confirmPassword && (
            <p className="text-sm text-destructive">{errors.confirmPassword.message}</p>
          )}
        </div>

        <div className="flex justify-end gap-2">
          <Button type="button" variant="ghost" className="rounded-lg" onClick={() => reset()}>
            Clear
          </Button>
          <Button type="submit" className="rounded-lg" disabled={isSubmitting}>
            {isSubmitting ? (
              <Loader2 className="size-4 animate-spin" />
            ) : (
              <KeyRound className="size-4" />
            )}
            Update password
          </Button>
        </div>
      </form>
    </section>
  );
}
