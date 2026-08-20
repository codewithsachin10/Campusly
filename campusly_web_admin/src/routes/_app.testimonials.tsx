import { createFileRoute } from "@tanstack/react-router";
import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import { testimonialsQueries, api } from "@/lib/services";
import { Plus, Search, MoreHorizontal, Trash2, Edit } from "lucide-react";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from "@/components/ui/table";
import { Switch } from "@/components/ui/switch";
import { Dialog, DialogContent, DialogHeader, DialogTitle, DialogTrigger } from "@/components/ui/dialog";
import { useState } from "react";
import { toast } from "sonner";
import { PageHeader } from "@/components/page-header";

export const Route = createFileRoute("/_app/testimonials")({
  component: TestimonialsAdminPage,
});

function TestimonialsAdminPage() {
  const queryClient = useQueryClient();
  const { data: testimonials = [], isLoading } = useQuery(testimonialsQueries.adminList());
  const [isAddOpen, setIsAddOpen] = useState(false);

  const togglePublish = useMutation({
    mutationFn: ({ id, is_published }: { id: string; is_published: boolean }) => api.testimonials.update(id, { is_published }),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["testimonials", "admin"] });
      toast.success("Testimonial visibility updated");
    },
  });

  const deleteTestimonial = useMutation({
    mutationFn: api.testimonials.delete,
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["testimonials", "admin"] });
      toast.success("Testimonial deleted");
    },
  });

  return (
    <>
      <PageHeader
        title="Testimonials"
        description="Manage student testimonials shown on the app download page."
        crumbs={[{ label: "Testimonials" }]}
      >
        <Dialog open={isAddOpen} onOpenChange={setIsAddOpen}>
          <DialogTrigger asChild>
            <Button className="rounded-xl">
              <Plus className="mr-2 size-4" /> Add Testimonial
            </Button>
          </DialogTrigger>
          <DialogContent className="rounded-2xl sm:max-w-md">
            <DialogHeader>
              <DialogTitle>Add Testimonial</DialogTitle>
            </DialogHeader>
            <AddTestimonialForm onSuccess={() => setIsAddOpen(false)} />
          </DialogContent>
        </Dialog>
      </PageHeader>

      <div className="surface">
        <div className="p-4 border-b border-border flex items-center justify-between">
          <div className="relative w-64">
            <Search className="absolute left-3 top-1/2 -translate-y-1/2 size-4 text-muted-foreground" />
            <Input className="pl-9 bg-muted/50 rounded-xl border-transparent" placeholder="Search testimonials..." />
          </div>
        </div>

        <Table>
          <TableHeader>
            <TableRow className="hover:bg-transparent">
              <TableHead>Author</TableHead>
              <TableHead>Role / Course</TableHead>
              <TableHead>Content</TableHead>
              <TableHead className="w-[100px] text-center">Published</TableHead>
              <TableHead className="w-[50px]"></TableHead>
            </TableRow>
          </TableHeader>
          <TableBody>
            {isLoading ? (
              <TableRow>
                <TableCell colSpan={5} className="text-center py-8 text-muted-foreground">Loading testimonials...</TableCell>
              </TableRow>
            ) : testimonials.length === 0 ? (
              <TableRow>
                <TableCell colSpan={5} className="text-center py-8 text-muted-foreground">No testimonials found. Add one to get started.</TableCell>
              </TableRow>
            ) : (
              testimonials.map((t: any) => (
                <TableRow key={t.id}>
                  <TableCell className="font-medium">{t.author_name}</TableCell>
                  <TableCell className="text-muted-foreground">{t.author_role}</TableCell>
                  <TableCell className="max-w-xs truncate text-muted-foreground" title={t.content}>
                    {t.content}
                  </TableCell>
                  <TableCell className="text-center">
                    <Switch 
                      checked={t.is_published}
                      onCheckedChange={(c) => togglePublish.mutate({ id: t.id, is_published: c })}
                    />
                  </TableCell>
                  <TableCell>
                    <Button variant="ghost" size="icon" className="text-red-500 hover:text-red-600 hover:bg-red-50" onClick={() => {
                      if (confirm("Are you sure you want to delete this testimonial?")) {
                        deleteTestimonial.mutate(t.id);
                      }
                    }}>
                      <Trash2 className="size-4" />
                    </Button>
                  </TableCell>
                </TableRow>
              ))
            )}
          </TableBody>
        </Table>
      </div>
    </>
  );
}

function AddTestimonialForm({ onSuccess }: { onSuccess: () => void }) {
  const queryClient = useQueryClient();
  const [formData, setFormData] = useState({
    author_name: "",
    author_role: "",
    content: "",
    rating: 5,
    is_published: true
  });

  const createTestimonial = useMutation({
    mutationFn: api.testimonials.create,
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["testimonials", "admin"] });
      toast.success("Testimonial added");
      onSuccess();
    },
  });

  return (
    <form className="space-y-4 pt-4" onSubmit={(e) => {
      e.preventDefault();
      createTestimonial.mutate(formData);
    }}>
      <div className="space-y-2">
        <label className="text-sm font-medium">Author Name</label>
        <Input 
          required 
          placeholder="e.g. Rahul Sharma" 
          value={formData.author_name} 
          onChange={e => setFormData({ ...formData, author_name: e.target.value })} 
        />
      </div>
      <div className="space-y-2">
        <label className="text-sm font-medium">Course / Role</label>
        <Input 
          required 
          placeholder="e.g. 3rd Year, Computer Science" 
          value={formData.author_role} 
          onChange={e => setFormData({ ...formData, author_role: e.target.value })} 
        />
      </div>
      <div className="space-y-2">
        <label className="text-sm font-medium">Testimonial Content</label>
        <textarea 
          required 
          className="w-full flex min-h-[80px] rounded-md border border-input bg-background px-3 py-2 text-sm ring-offset-background placeholder:text-muted-foreground focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2 disabled:cursor-not-allowed disabled:opacity-50"
          placeholder="This app is amazing..."
          value={formData.content} 
          onChange={e => setFormData({ ...formData, content: e.target.value })} 
        />
      </div>
      <div className="flex items-center justify-between pt-2">
        <label className="text-sm font-medium">Publish immediately</label>
        <Switch 
          checked={formData.is_published}
          onCheckedChange={c => setFormData({ ...formData, is_published: c })}
        />
      </div>
      <Button type="submit" className="w-full mt-4" disabled={createTestimonial.isPending}>
        {createTestimonial.isPending ? "Adding..." : "Save Testimonial"}
      </Button>
    </form>
  );
}
