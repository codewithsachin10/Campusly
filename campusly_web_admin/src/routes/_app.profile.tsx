import { zodResolver } from "@hookform/resolvers/zod";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { createFileRoute } from "@tanstack/react-router";
import { Building2, Loader2, Mail, Save, ShieldCheck } from "lucide-react";
import { useEffect } from "react";
import { useForm } from "react-hook-form";
import { toast } from "sonner";
import { z } from "zod";
import { Form, TextField } from "@/components/form-fields";
import { PageHeader } from "@/components/page-header";
import { Avatar, AvatarFallback } from "@/components/ui/avatar";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { api, collegeQueries } from "@/lib/services";
import { useAuth } from "@/lib/auth";

export const Route = createFileRoute("/_app/profile")({
  head: () => ({
    meta: [
      { title: "Profile — Campusly Admin" },
      {
        name: "description",
        content:
          "Review your admin account and keep the college's contact and affiliation details up to date.",
      },
      { property: "og:title", content: "Profile — Campusly Admin" },
      {
        property: "og:description",
        content:
          "Review your admin account and keep the college's contact and affiliation details up to date.",
      },
    ],
  }),
  component: ProfilePage,
});

const collegeSchema = z.object({
  name: z.string().trim().min(3, "College name is required.").max(120),
  shortName: z.string().trim().min(2, "Short name is required.").max(12),
  email: z.string().trim().email("Enter a valid email address."),
  phone: z.string().trim().min(6, "Enter a valid phone number.").max(24),
  website: z.string().trim().url("Enter a valid URL, e.g. https://campusly.edu"),
  affiliation: z.string().trim().max(120),
  established: z
    .string()
    .trim()
    .regex(/^\d{4}$/, "Enter a 4-digit year."),
  address: z.string().trim().min(6, "Address is required.").max(200),
});
type CollegeForm = z.input<typeof collegeSchema>;

const roleLabels: Record<string, string> = {
  super_admin: "Super Admin",
  admin: "Admin",
  faculty: "Faculty",
  readonly_admin: "Read-only Admin",
};

function ProfilePage() {
  const { admin } = useAuth();
  const qc = useQueryClient();
  const college = useQuery(collegeQueries.get());

  const form = useForm<CollegeForm>({
    resolver: zodResolver(collegeSchema),
    defaultValues: {
      name: "",
      shortName: "",
      email: "",
      phone: "",
      website: "",
      affiliation: "",
      established: "",
      address: "",
    },
  });

  useEffect(() => {
    if (college.data) form.reset(college.data);
  }, [college.data, form]);

  const update = useMutation({
    mutationFn: (values: CollegeForm) => api.college.update(collegeSchema.parse(values)),
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ["college"] });
      toast.success("College details updated");
    },
    onError: () => toast.error("Could not save the college details."),
  });

  const initials = (admin?.name ?? "A")
    .split(" ")
    .map((p) => p[0])
    .slice(0, 2)
    .join("");

  return (
    <>
      <PageHeader
        title="Profile"
        description="Your admin account and the college record shown across Campusly."
        crumbs={[{ label: "Profile" }]}
      />

      <div className="grid gap-6 lg:grid-cols-[320px_1fr]">
        <div className="surface space-y-5 p-6">
          <div className="flex items-center gap-4">
            <Avatar className="size-14">
              <AvatarFallback className="bg-primary/10 text-base font-medium text-primary">
                {initials}
              </AvatarFallback>
            </Avatar>
            <div className="min-w-0">
              <p className="truncate font-medium">{admin?.name}</p>
              <p className="truncate text-sm text-muted-foreground">{admin?.email}</p>
            </div>
          </div>

          <div className="space-y-3 text-sm">
            <div className="flex items-center justify-between gap-3">
              <span className="text-muted-foreground">Role</span>
              <Badge variant="secondary" className="rounded-md">
                {roleLabels[admin?.role ?? ""] ?? admin?.role}
              </Badge>
            </div>
            <div className="flex items-center justify-between gap-3">
              <span className="text-muted-foreground">College ID</span>
              <span className="font-medium">{admin?.collegeId}</span>
            </div>
            <div className="flex items-center justify-between gap-3">
              <span className="text-muted-foreground">Member since</span>
              <span className="font-medium">
                {admin ? new Date(admin.createdAt).toLocaleDateString() : "—"}
              </span>
            </div>
          </div>

          <div className="space-y-2 border-t pt-4">
            <p className="flex items-center gap-2 text-sm font-medium">
              <ShieldCheck className="size-4 text-primary" /> Permissions
            </p>
            <div className="flex flex-wrap gap-1.5">
              {admin?.permissions.map((p) => (
                <Badge key={p} variant="outline" className="rounded-md capitalize">
                  {p}
                </Badge>
              ))}
            </div>
          </div>

          <div className="space-y-1 border-t pt-4 text-sm text-muted-foreground">
            <p className="flex items-center gap-2">
              <Mail className="size-4" /> Sign-in email is managed by your identity provider.
            </p>
          </div>
        </div>

        <div className="surface p-6">
          <div className="flex items-center gap-2">
            <Building2 className="size-4 text-primary" />
            <h2 className="font-medium">College information</h2>
          </div>
          <p className="mt-1 text-sm text-muted-foreground">
            These details appear on exported timetables, reports and notices.
          </p>

          {college.isPending ? (
            <div className="flex h-64 items-center justify-center">
              <Loader2 className="size-5 animate-spin text-muted-foreground" />
            </div>
          ) : (
            <Form {...form}>
              <form
                onSubmit={form.handleSubmit((v) => update.mutate(v))}
                className="mt-6 space-y-5"
              >
                <div className="grid gap-5 sm:grid-cols-2">
                  <TextField control={form.control} name="name" label="College name" />
                  <TextField control={form.control} name="shortName" label="Short name" />
                  <TextField control={form.control} name="email" label="Official email" />
                  <TextField control={form.control} name="phone" label="Phone" />
                  <TextField control={form.control} name="website" label="Website" />
                  <TextField control={form.control} name="established" label="Established" />
                  <TextField control={form.control} name="affiliation" label="Affiliation" />
                </div>
                <TextField control={form.control} name="address" label="Address" textarea />
                <div className="flex justify-end gap-2">
                  <Button
                    type="button"
                    variant="ghost"
                    className="rounded-lg"
                    disabled={!form.formState.isDirty}
                    onClick={() => college.data && form.reset(college.data)}
                  >
                    Discard
                  </Button>
                  <Button type="submit" className="rounded-lg" disabled={update.isPending}>
                    {update.isPending ? (
                      <Loader2 className="size-4 animate-spin" />
                    ) : (
                      <Save className="size-4" />
                    )}
                    Save changes
                  </Button>
                </div>
              </form>
            </Form>
          )}
        </div>
      </div>
    </>
  );
}
