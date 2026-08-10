import { createFileRoute, useNavigate } from '@tanstack/react-router'
import { useState } from 'react'
import { PageHeader } from '@/components/page-header'
import { supabase } from '@/lib/supabase'
import { Card, CardContent, CardDescription, CardHeader, CardTitle, CardFooter } from '@/components/ui/card'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { Textarea } from '@/components/ui/textarea'
import { RadioGroup, RadioGroupItem } from '@/components/ui/radio-group'
import { Upload } from 'lucide-react'
import { toast } from 'sonner'
import { useQueryClient } from '@tanstack/react-query'

export const Route = createFileRoute('/_app/updates/create')({
  component: CreateReleasePage,
})

function CreateReleasePage() {
  const queryClient = useQueryClient()
  const navigate = useNavigate()
  const [uploading, setUploading] = useState(false)
  
  const [formData, setFormData] = useState({
    version: '',
    build_number: '',
    release_title: '',
    release_notes: '',
    update_type: 'RECOMMENDED',
    minimum_supported_build: '',
    minimum_supported_version: '',
  })
  
  const [apkFile, setApkFile] = useState<File | null>(null)

  // SHA-256 Hash Generator
  const calculateSHA256 = async (file: File): Promise<string> => {
    const arrayBuffer = await file.arrayBuffer()
    const hashBuffer = await crypto.subtle.digest('SHA-256', arrayBuffer)
    const hashArray = Array.from(new Uint8Array(hashBuffer))
    return hashArray.map(b => b.toString(16).padStart(2, '0')).join('')
  }

  const handlePublish = async (e: React.FormEvent) => {
    e.preventDefault()
    if (!apkFile) {
      toast.error('Please select an APK file to upload.')
      return
    }
    
    setUploading(true)
    const toastId = toast.loading('Calculating secure hash...')

    try {
      // 1. Calculate Hash & Size
      const hash = await calculateSHA256(apkFile)
      const apkSize = apkFile.size
      
      toast.loading(`Hash: ${hash.substring(0, 8)}... Uploading APK...`, { id: toastId })

      // 2. Upload to Storage
      const fileName = `Campusly_v${formData.version}_b${formData.build_number}_${Date.now()}.apk`
      const { error: uploadError } = await supabase.storage
        .from('releases')
        .upload(fileName, apkFile, {
          cacheControl: '3600',
          upsert: false
        })

      if (uploadError) throw uploadError

      const { data: publicUrlData } = supabase.storage
        .from('releases')
        .getPublicUrl(fileName)

      toast.loading('Saving release metadata...', { id: toastId })

      // 3. Insert DB Record
      const { error: dbError } = await supabase
        .from('app_releases')
        .insert({
          platform: 'android',
          version: formData.version,
          build_number: parseInt(formData.build_number),
          release_title: formData.release_title || `Campusly ${formData.version} is here`,
          release_notes: formData.release_notes,
          update_type: formData.update_type,
          minimum_supported_build: parseInt(formData.minimum_supported_build),
          minimum_supported_version: formData.minimum_supported_version,
          apk_url: publicUrlData.publicUrl,
          apk_size: apkSize,
          apk_sha256: hash,
          package_name: 'com.sachindigisolutions.campusly',
          status: 'PUBLISHED',
          is_published: true,
          published_at: new Date().toISOString()
        })

      if (dbError) throw dbError

      toast.success('Update published successfully!', { id: toastId })
      queryClient.invalidateQueries({ queryKey: ['updateStats', 'appReleases'] })
      navigate({ to: '/updates/releases' })
      
    } catch (error: any) {
      console.error(error)
      toast.error(`Publish failed: ${error.message || 'Unknown error'}`, { id: toastId })
    } finally {
      setUploading(false)
    }
  }

  return (
    <>
      <PageHeader
        title="Create New Release"
        description="Upload a signed Android APK and configure how students will receive this update."
        crumbs={[
          { label: "App Updates", to: "/updates" },
          { label: "Create Release" },
        ]}
      />
      
      <div className="mx-auto max-w-3xl space-y-8">

            <Card>
              <form onSubmit={handlePublish}>
                <CardHeader>
                  <CardTitle>Release Details</CardTitle>
                  <CardDescription>
                    Provide version numbers and release notes for the student app.
                  </CardDescription>
                </CardHeader>
                <CardContent className="space-y-6">
                  <div className="grid grid-cols-2 gap-4">
                    <div className="space-y-2">
                      <Label htmlFor="version">Version Name</Label>
                      <Input 
                        id="version" 
                        required 
                        placeholder="e.g., 2.2.0" 
                        value={formData.version}
                        onChange={e => setFormData({...formData, version: e.target.value})}
                      />
                    </div>
                    <div className="space-y-2">
                      <Label htmlFor="build_number">Build Number</Label>
                      <Input 
                        id="build_number" 
                        type="number" 
                        required 
                        placeholder="e.g., 22" 
                        value={formData.build_number}
                        onChange={e => setFormData({...formData, build_number: e.target.value})}
                      />
                    </div>
                  </div>

                  <div className="space-y-2">
                    <Label htmlFor="release_title">Release Title (Optional)</Label>
                    <Input 
                      id="release_title" 
                      placeholder="e.g., Campusly 2.2.0 is here!" 
                      value={formData.release_title}
                      onChange={e => setFormData({...formData, release_title: e.target.value})}
                    />
                  </div>

                  <div className="space-y-2">
                    <Label htmlFor="release_notes">Detailed Release Notes</Label>
                    <Textarea 
                      id="release_notes" 
                      rows={5}
                      required
                      placeholder="What's New... Bug Fixes... Performance Improvements..."
                      value={formData.release_notes}
                      onChange={e => setFormData({...formData, release_notes: e.target.value})}
                    />
                  </div>

                  <div className="space-y-2">
                    <Label htmlFor="apkFile">Android APK File</Label>
                    <div className="border-2 border-dashed rounded-lg p-6 flex flex-col items-center justify-center text-center bg-muted/10 hover:bg-muted/30 transition-colors">
                      <Upload className="h-8 w-8 text-muted-foreground mb-4" />
                      <Input 
                        id="apkFile" 
                        type="file" 
                        accept=".apk"
                        className="hidden"
                        onChange={e => {
                          if (e.target.files && e.target.files[0]) {
                            setApkFile(e.target.files[0])
                          }
                        }}
                      />
                      <Label htmlFor="apkFile" className="cursor-pointer">
                        <span className="text-primary font-medium hover:underline">Click to browse</span> or drag and drop
                      </Label>
                      <p className="text-xs text-muted-foreground mt-2">
                        {apkFile ? apkFile.name : 'Must be a signed production .apk file'}
                      </p>
                    </div>
                  </div>

                  <Separator />

                  <div className="space-y-4">
                    <h3 className="text-lg font-medium">Update Type</h3>
                    <RadioGroup 
                      value={formData.update_type} 
                      onValueChange={(v) => setFormData({...formData, update_type: v})}
                      className="gap-4"
                    >
                      <div className="flex items-start space-x-3 bg-muted/20 p-4 rounded-lg border">
                        <RadioGroupItem value="OPTIONAL" id="optional" className="mt-1" />
                        <div className="grid gap-1.5 leading-none">
                          <Label htmlFor="optional" className="font-semibold cursor-pointer">OPTIONAL</Label>
                          <p className="text-sm text-muted-foreground">
                            Student can continue using Campusly without updating.
                          </p>
                        </div>
                      </div>
                      
                      <div className="flex items-start space-x-3 bg-primary/5 p-4 rounded-lg border border-primary/20">
                        <RadioGroupItem value="RECOMMENDED" id="recommended" className="mt-1" />
                        <div className="grid gap-1.5 leading-none">
                          <Label htmlFor="recommended" className="font-semibold text-primary cursor-pointer">RECOMMENDED</Label>
                          <p className="text-sm text-muted-foreground">
                            Student is strongly encouraged to update, but can dismiss it.
                          </p>
                        </div>
                      </div>

                      <div className="flex items-start space-x-3 bg-destructive/5 p-4 rounded-lg border border-destructive/20">
                        <RadioGroupItem value="MANDATORY" id="mandatory" className="mt-1" />
                        <div className="grid gap-1.5 leading-none">
                          <Label htmlFor="mandatory" className="font-semibold text-destructive cursor-pointer">MANDATORY</Label>
                          <p className="text-sm text-muted-foreground">
                            Current version will be blocked until updated.
                          </p>
                        </div>
                      </div>
                    </RadioGroup>
                  </div>

                  <Separator />

                  <div className="space-y-4">
                    <h3 className="text-lg font-medium">Minimum Supported Compatibility</h3>
                    <div className="grid grid-cols-2 gap-4">
                      <div className="space-y-2">
                        <Label htmlFor="minVersion">Minimum Supported Version</Label>
                        <Input 
                          id="minVersion" 
                          required 
                          placeholder="e.g. 2.0.0" 
                          value={formData.minimum_supported_version}
                          onChange={e => setFormData({...formData, minimum_supported_version: e.target.value})}
                        />
                      </div>
                      <div className="space-y-2">
                        <Label htmlFor="minBuild">Minimum Supported Build</Label>
                        <Input 
                          id="minBuild" 
                          type="number" 
                          required 
                          placeholder="e.g. 20" 
                          value={formData.minimum_supported_build}
                          onChange={e => setFormData({...formData, minimum_supported_build: e.target.value})}
                        />
                      </div>
                    </div>
                    <p className="text-xs text-muted-foreground">
                      Any student running a build lower than this number will be forced to update immediately, even if the release is not marked mandatory.
                    </p>
                  </div>

                </CardContent>
                <CardFooter className="bg-muted/20 border-t pt-6 flex justify-end gap-2">
                  <Button type="button" variant="outline" onClick={() => navigate({ to: '/updates/releases' })}>
                    Cancel
                  </Button>
                  <Button type="submit" disabled={uploading}>
                    {uploading ? (
                      <>
                        <div className="animate-spin rounded-full h-4 w-4 border-b-2 border-white mr-2"></div>
                        Publishing...
                      </>
                    ) : (
                      <>
                        <Upload className="mr-2 h-4 w-4" /> Publish Release
                      </>
                    )}
                  </Button>
                </CardFooter>
              </form>
            </Card>
      </div>
    </>
  )
}
