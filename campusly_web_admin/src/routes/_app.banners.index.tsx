import { createFileRoute } from '@tanstack/react-router'
import { useState } from 'react'
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query'
import { api, promoBannersQueries, departmentQueries } from '@/lib/services'
import { supabase } from '@/lib/supabase'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Switch } from '@/components/ui/switch'
import { Dialog, DialogContent, DialogHeader, DialogTitle, DialogFooter } from '@/components/ui/dialog'
import { Label } from '@/components/ui/label'
import { Plus, Edit2, Trash2, GripVertical, Check, ChevronsUpDown, BarChart3, UploadCloud } from 'lucide-react'
import * as LucideIcons from 'lucide-react'
import { Command, CommandEmpty, CommandGroup, CommandInput, CommandItem, CommandList } from '@/components/ui/command'
import { Popover, PopoverContent, PopoverTrigger } from '@/components/ui/popover'
import { cn } from '@/lib/utils'
import { toast } from 'sonner'
import { Card } from '@/components/ui/card'

export const Route = createFileRoute('/_app/banners/')({
  component: BannersPage,
})

const ICONS = [
  'Rocket', 'Code', 'Sparkles', 'Star', 'Megaphone', 'Calendar', 
  'Zap', 'Trophy', 'PartyPopper', 'Heart', 'Image', 'Info', 
  'Bell', 'Gift', 'Flag', 'Flame', 'Music', 'Video'
];

function BannersPage() {
  const queryClient = useQueryClient()
  const { data: banners, isLoading } = useQuery(promoBannersQueries.list())
  const { data: departments } = useQuery(departmentQueries.list())
  const [isDialogOpen, setIsDialogOpen] = useState(false)
  const [editingBanner, setEditingBanner] = useState<any>(null)
  
  const [openIconPopover, setOpenIconPopover] = useState(false)
  const [isUploading, setIsUploading] = useState(false)
  const [formData, setFormData] = useState({
    category: '',
    title: '',
    icon_name: '',
    gradient_start: '#6366F1',
    gradient_end: '#D946EF',
    target_link: '',
    is_active: true,
    display_order: 0,
    target_departments: [] as string[],
    target_batches: '',
    start_date: '',
    end_date: '',
    image_url: '',
    cta_text: ''
  })

  const createMutation = useMutation({
    mutationFn: (data: any) => api.promoBanners.create(data),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['promo_banners'] })
      setIsDialogOpen(false)
      toast.success('Banner created')
    }
  })

  const updateMutation = useMutation({
    mutationFn: ({ id, data }: { id: string, data: any }) => api.promoBanners.update(id, data),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['promo_banners'] })
      setIsDialogOpen(false)
      toast.success('Banner updated')
    }
  })

  const deleteMutation = useMutation({
    mutationFn: (id: string) => api.promoBanners.delete(id),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['promo_banners'] })
      toast.success('Banner deleted')
    }
  })

  const toggleDepartment = (id: string) => {
    setFormData(prev => ({
      ...prev,
      target_departments: prev.target_departments.includes(id) 
        ? prev.target_departments.filter(d => d !== id)
        : [...prev.target_departments, id]
    }));
  };

  const handleFileUpload = async (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0]
    if (!file) return
    setIsUploading(true)
    
    try {
      const fileExt = file.name.split('.').pop()
      const fileName = `${Math.random().toString(36).substring(2)}.${fileExt}`
      const filePath = `${fileName}`
      
      const { error: uploadError } = await supabase.storage
        .from('promo_banners')
        .upload(filePath, file)
        
      if (uploadError) throw uploadError
      
      const { data } = supabase.storage.from('promo_banners').getPublicUrl(filePath)
      
      setFormData(prev => ({ ...prev, image_url: data.publicUrl }))
      toast.success('Image uploaded successfully')
    } catch(err: any) {
      toast.error('Upload failed: ' + err.message)
    } finally {
      setIsUploading(false)
    }
  }

  const handleEdit = (banner: any) => {
    setEditingBanner(banner)
    setFormData({
      category: banner.category,
      title: banner.title,
      icon_name: banner.icon_name,
      gradient_start: banner.gradient_start,
      gradient_end: banner.gradient_end,
      target_link: banner.target_link || '',
      is_active: banner.is_active,
      display_order: banner.display_order,
      target_departments: banner.target_departments || [],
      target_batches: banner.target_batches?.join(', ') || '',
      start_date: banner.start_date ? new Date(banner.start_date).toISOString().slice(0, 16) : '',
      end_date: banner.end_date ? new Date(banner.end_date).toISOString().slice(0, 16) : '',
      image_url: banner.image_url || '',
      cta_text: banner.cta_text || ''
    })
    setIsDialogOpen(true)
  }

  const handleCreate = () => {
    setEditingBanner(null)
    setFormData({
      category: '',
      title: '',
      icon_name: 'Rocket',
      gradient_start: '#6366F1',
      gradient_end: '#D946EF',
      target_link: '',
      is_active: true,
      display_order: (banners?.length || 0),
      target_departments: [],
      target_batches: '',
      start_date: '',
      end_date: '',
      image_url: '',
      cta_text: ''
    })
    setIsDialogOpen(true)
  }

  const handleSave = () => {
    if (!formData.title || !formData.category) {
      toast.error('Please fill required fields (Title and Category)')
      return
    }
    
    const payload: any = { 
      category: formData.category,
      title: formData.title,
      icon_name: formData.icon_name,
      gradient_start: formData.gradient_start,
      gradient_end: formData.gradient_end,
      target_link: formData.target_link,
      is_active: formData.is_active,
      display_order: formData.display_order,
      image_url: formData.image_url,
      cta_text: formData.cta_text
    };
    
    payload.target_batches = formData.target_batches.split(',').map(s => s.trim()).filter(s => s);
    if (payload.target_batches.length === 0) payload.target_batches = null;
    
    payload.target_departments = formData.target_departments;
    if (payload.target_departments.length === 0) payload.target_departments = null;
    
    payload.start_date = formData.start_date ? new Date(formData.start_date).toISOString() : null;
    payload.end_date = formData.end_date ? new Date(formData.end_date).toISOString() : null;
    payload.image_url = formData.image_url ? formData.image_url : null;
    payload.cta_text = formData.cta_text ? formData.cta_text : null;

    if (editingBanner) {
      updateMutation.mutate({ id: editingBanner.id, data: payload })
    } else {
      createMutation.mutate(payload)
    }
  }

  const handleDelete = (id: string) => {
    if (confirm('Are you sure you want to delete this banner?')) {
      deleteMutation.mutate(id)
    }
  }

  const handleToggleActive = (id: string, current: boolean) => {
    updateMutation.mutate({ id, data: { is_active: !current } })
  }

  const renderIcon = (name: string) => {
    const Icon = (LucideIcons as any)[name];
    return Icon ? <Icon className="w-6 h-6 text-white" /> : <LucideIcons.Image className="w-6 h-6 text-white" />;
  }

  return (
    <div className="p-8 max-w-5xl mx-auto">
      <div className="flex items-center justify-between mb-8">
        <div>
          <h1 className="text-3xl font-bold tracking-tight">Promo Banners</h1>
          <p className="text-muted-foreground mt-1">Manage the promotional banners shown in the student app</p>
        </div>
        <Button onClick={handleCreate} className="gap-2">
          <Plus className="w-4 h-4" /> Add Banner
        </Button>
      </div>

      {isLoading ? (
        <div className="text-center py-10">Loading banners...</div>
      ) : (
        <div className="space-y-4">
          {banners?.map((banner: any, index: number) => (
            <Card key={banner.id} className="p-4 flex items-center justify-between shadow-sm">
              <div className="flex items-center gap-6 flex-1">
                <GripVertical className="text-muted-foreground cursor-grab opacity-50" />
                
                {/* Banner Preview */}
                <div 
                  className="w-[300px] h-24 rounded-xl p-4 flex items-center gap-4 relative overflow-hidden"
                  style={banner.image_url ? {
                    backgroundImage: `url(${banner.image_url})`,
                    backgroundSize: 'cover',
                    backgroundPosition: 'center',
                  } : {
                    background: `linear-gradient(to bottom right, ${banner.gradient_start}, ${banner.gradient_end})`
                  }}
                >
                  <div className="absolute inset-0 bg-black/40 z-0"></div>
                  {(!banner.image_url) && (
                    <div className="absolute right-0 bottom-[-10px] w-16 h-16 rounded-lg bg-white/10 border border-white/20" />
                  )}
                  {(!banner.image_url) && (
                    <div className="w-12 h-12 rounded-xl bg-white/20 border border-white/30 flex items-center justify-center z-10">
                      {renderIcon(banner.icon_name)}
                    </div>
                  )}
                  <div className="z-10 flex-1 overflow-hidden">
                    <p className="text-[10px] font-bold text-white/90 tracking-widest uppercase truncate">{banner.category}</p>
                    <p className="text-sm font-black text-white leading-tight mt-1 line-clamp-1">{banner.title}</p>
                    {banner.cta_text && (
                      <span className="inline-block mt-1 bg-white text-black text-[10px] font-bold px-2 py-0.5 rounded-full">
                        {banner.cta_text}
                      </span>
                    )}
                  </div>
                </div>

                <div className="flex flex-col gap-1 ml-4 flex-1">
                  <span className="text-sm font-medium">{banner.title}</span>
                  <span className="text-xs text-muted-foreground">URL: {banner.target_link || 'None'}</span>
                </div>
              </div>

              <div className="flex items-center gap-6 ml-6">
                <div className="flex flex-col items-center justify-center opacity-80">
                  <div className="flex items-center gap-1 text-xs font-bold text-muted-foreground uppercase tracking-wider">
                    <BarChart3 className="w-3 h-3" /> Clicks
                  </div>
                  <span className="text-xl font-black">{banner.clicks || 0}</span>
                </div>
                <div className="w-px h-10 bg-border"></div>
                <div className="flex items-center gap-4">
                  <div className="flex items-center space-x-2">
                    <Switch 
                      checked={banner.is_active}
                      onCheckedChange={() => handleToggleActive(banner.id, banner.is_active)}
                    />
                    <Label className="text-xs text-muted-foreground">Active</Label>
                  </div>
                  <Button variant="ghost" size="icon" onClick={() => handleEdit(banner)}>
                    <Edit2 className="h-4 w-4" />
                  </Button>
                  <Button variant="ghost" size="icon" onClick={() => handleDelete(banner.id)} className="text-red-500 hover:text-red-600">
                    <Trash2 className="h-4 w-4" />
                  </Button>
                </div>
              </div>
            </Card>
          ))}
          {banners?.length === 0 && (
             <div className="text-center py-10 text-muted-foreground">No banners found. Create one above.</div>
          )}
        </div>
      )}

      <Dialog open={isDialogOpen} onOpenChange={setIsDialogOpen}>
        <DialogContent className="max-w-md h-[80vh] flex flex-col p-0">
          <DialogHeader className="p-6 pb-2">
            <DialogTitle>{editingBanner ? 'Edit Banner' : 'Create Banner'}</DialogTitle>
          </DialogHeader>
          <div className="flex-1 overflow-y-auto px-6 py-4">
            <div className="grid gap-4">
              <div className="space-y-2">
                <Label>Category (e.g. EVENTS, HACKATHON)</Label>
                <Input 
                  value={formData.category}
                  onChange={e => setFormData({...formData, category: e.target.value})}
                  placeholder="EVENTS"
                />
              </div>
              <div className="space-y-2">
                <Label>Title</Label>
                <Input 
                  value={formData.title}
                  onChange={e => setFormData({...formData, title: e.target.value})}
                  placeholder="Campus Tech Fest 2024"
                />
              </div>
              
              <div className="space-y-2">
                <Label>Call to Action (CTA) Text</Label>
                <Input 
                  value={formData.cta_text}
                  onChange={e => setFormData({...formData, cta_text: e.target.value})}
                  placeholder="Register Now ->"
                />
              </div>

              <div className="space-y-2">
                <Label>Custom Background Image (Overrides Gradient)</Label>
                <div className="flex items-center gap-4">
                  <Button variant="outline" className="relative cursor-pointer" disabled={isUploading}>
                    {isUploading ? 'Uploading...' : <><UploadCloud className="w-4 h-4 mr-2" /> Upload Image</>}
                    <input 
                      type="file" 
                      className="absolute inset-0 opacity-0 cursor-pointer" 
                      accept="image/*"
                      onChange={handleFileUpload}
                      disabled={isUploading}
                    />
                  </Button>
                  {formData.image_url && (
                    <Button variant="ghost" className="text-red-500" onClick={() => setFormData({...formData, image_url: ''})}>
                      Remove Image
                    </Button>
                  )}
                </div>
                {formData.image_url && (
                  <div className="mt-2 rounded-md overflow-hidden h-24 bg-muted">
                    <img src={formData.image_url} alt="Preview" className="w-full h-full object-cover" />
                  </div>
                )}
              </div>

              {!formData.image_url && (
                <>
                  <div className="space-y-2">
                    <Label>Icon</Label>
                    <Popover open={openIconPopover} onOpenChange={setOpenIconPopover}>
                      <PopoverTrigger asChild>
                        <Button
                          variant="outline"
                          role="combobox"
                          aria-expanded={openIconPopover}
                          className="w-full justify-between"
                        >
                          {formData.icon_name || "Select icon..."}
                          <ChevronsUpDown className="ml-2 h-4 w-4 shrink-0 opacity-50" />
                        </Button>
                      </PopoverTrigger>
                      <PopoverContent className="w-[300px] p-0" align="start">
                        <Command>
                          <CommandInput placeholder="Search icon..." />
                          <CommandList>
                            <CommandEmpty>No icon found.</CommandEmpty>
                            <CommandGroup>
                              {ICONS.map((icon) => (
                                <CommandItem
                                  key={icon}
                                  value={icon}
                                  onSelect={(currentValue) => {
                                    setFormData({ ...formData, icon_name: icon })
                                    setOpenIconPopover(false)
                                  }}
                                >
                                  <Check
                                    className={cn(
                                      "mr-2 h-4 w-4",
                                      formData.icon_name === icon ? "opacity-100" : "opacity-0"
                                    )}
                                  />
                                  <div className="flex items-center gap-2">
                                    {renderIcon(icon)}
                                    <span className="text-black dark:text-white">{icon}</span>
                                  </div>
                                </CommandItem>
                              ))}
                            </CommandGroup>
                          </CommandList>
                        </Command>
                      </PopoverContent>
                    </Popover>
                  </div>

                  <div className="grid grid-cols-2 gap-4">
                    <div className="space-y-2">
                      <Label>Gradient Start</Label>
                      <div className="flex gap-2">
                        <Input 
                          type="color"
                          className="w-12 h-10 p-1"
                          value={formData.gradient_start}
                          onChange={e => setFormData({...formData, gradient_start: e.target.value})}
                        />
                        <Input 
                          value={formData.gradient_start}
                          onChange={e => setFormData({...formData, gradient_start: e.target.value})}
                        />
                      </div>
                    </div>
                    <div className="space-y-2">
                      <Label>Gradient End</Label>
                      <div className="flex gap-2">
                        <Input 
                          type="color"
                          className="w-12 h-10 p-1"
                          value={formData.gradient_end}
                          onChange={e => setFormData({...formData, gradient_end: e.target.value})}
                        />
                        <Input 
                          value={formData.gradient_end}
                          onChange={e => setFormData({...formData, gradient_end: e.target.value})}
                        />
                      </div>
                    </div>
                  </div>
                </>
              )}

              <div className="grid grid-cols-2 gap-4">
                <div className="space-y-2">
                  <Label>Start Date (Optional)</Label>
                  <Input 
                    type="datetime-local"
                    value={formData.start_date}
                    onChange={e => setFormData({...formData, start_date: e.target.value})}
                  />
                </div>
                <div className="space-y-2">
                  <Label>End Date (Optional)</Label>
                  <Input 
                    type="datetime-local"
                    value={formData.end_date}
                    onChange={e => setFormData({...formData, end_date: e.target.value})}
                  />
                </div>
              </div>

              <div className="space-y-2">
                <Label>Target Batches (Comma-separated years)</Label>
                <Input 
                  value={formData.target_batches}
                  onChange={e => setFormData({...formData, target_batches: e.target.value})}
                  placeholder="2024, 2025 (Leave empty for all)"
                />
              </div>

              <div className="space-y-2">
                <Label>Target Departments (Leave empty for all)</Label>
                <div className="border rounded-md p-3 max-h-32 overflow-y-auto space-y-2 bg-background">
                  {departments?.map((dept: any) => (
                    <div key={dept.id} className="flex items-center space-x-2">
                      <Switch 
                        checked={formData.target_departments.includes(dept.id)}
                        onCheckedChange={() => toggleDepartment(dept.id)}
                      />
                      <Label className="text-sm font-normal cursor-pointer" onClick={() => toggleDepartment(dept.id)}>
                        {dept.name}
                      </Label>
                    </div>
                  ))}
                </div>
              </div>

              <div className="space-y-2">
                <Label>Target URL or Route (Optional)</Label>
                <Input 
                  value={formData.target_link}
                  onChange={e => setFormData({...formData, target_link: e.target.value})}
                  placeholder="/events"
                />
              </div>
              
              <div className="flex items-center space-x-2 pt-2">
                <Switch 
                  checked={formData.is_active}
                  onCheckedChange={c => setFormData({...formData, is_active: c})}
                />
                <Label>Active (Visible in app)</Label>
              </div>
            </div>
          </div>
          <DialogFooter className="p-6 pt-2 border-t mt-auto">
            <Button onClick={handleSave} disabled={createMutation.isPending || updateMutation.isPending} className="w-full sm:w-auto">
              {editingBanner ? 'Save Changes' : 'Create Banner'}
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>
    </div>
  )
}
