import { createFileRoute, Link, useRouter } from '@tanstack/react-router'
import { useState } from 'react'
import { Button } from '../components/ui/button'
import { getFormFn, updateFormFn, publishFormFn } from '../lib/form-actions'
import { Save, Eye, Send, ArrowLeft, Settings2, GripVertical, Trash2, PlusCircle, Check, HelpCircle, ChevronDown, AlignLeft, Type, CheckSquare, List, ListOrdered, Calendar, Clock, Hash, Mail, Phone, Link2, Upload, User, GraduationCap, Building, Tag, Video, Image as ImageIcon, Minus, Palette, GitBranch, LayoutTemplate, Plus } from 'lucide-react'
import { Card } from '../components/ui/card'
import { DragDropContext, Droppable, Draggable } from '@hello-pangea/dnd'
import { toast } from 'sonner'

export const Route = createFileRoute('/_app/forms/builder/$formId')({
  component: FormBuilderComponent,
  loader: async ({ params }) => {
    return await getFormFn({ data: params.formId })
  },
})

const QUESTION_CATEGORIES = [
  {
    title: 'Basic',
    items: [
      { id: 'short_text', label: 'Short Answer', icon: Type },
      { id: 'long_text', label: 'Paragraph', icon: AlignLeft },
      { id: 'multiple_choice', label: 'Multiple Choice', icon: Check },
      { id: 'checkboxes', label: 'Checkboxes', icon: CheckSquare },
      { id: 'dropdown', label: 'Dropdown', icon: ChevronDown },
      { id: 'yes_no', label: 'Yes/No', icon: HelpCircle },
    ]
  },
  {
    title: 'Advanced',
    items: [
      { id: 'linear_scale', label: 'Linear Scale', icon: ListOrdered },
      { id: 'number_rating', label: 'Rating', icon: PlusCircle },
      { id: 'date', label: 'Date', icon: Calendar },
      { id: 'time', label: 'Time', icon: Clock },
      { id: 'date_time', label: 'Date + Time', icon: Calendar },
      { id: 'number', label: 'Number', icon: Hash },
      { id: 'email', label: 'Email', icon: Mail },
      { id: 'phone', label: 'Phone Number', icon: Phone },
      { id: 'url', label: 'URL', icon: Link2 },
      { id: 'file_upload', label: 'File Upload', icon: Upload },
    ]
  },
  {
    title: 'Campus-Specific',
    items: [
      { id: 'student_name', label: 'Student Name', icon: User },
      { id: 'roll_number', label: 'Roll Number', icon: Hash },
      { id: 'college_email', label: 'College Email', icon: GraduationCap },
      { id: 'department', label: 'Department', icon: Building },
      { id: 'year', label: 'Year', icon: Tag },
      { id: 'semester', label: 'Semester', icon: Tag },
      { id: 'section', label: 'Section', icon: Tag },
      { id: 'subject', label: 'Course / Subject', icon: HelpCircle },
      { id: 'faculty', label: 'Faculty', icon: User },
      { id: 'attendance_input', label: 'Attendance', icon: HelpCircle },
    ]
  },
  {
    title: 'Layout Elements',
    items: [
      { id: 'heading', label: 'Heading', icon: Type },
      { id: 'description', label: 'Description', icon: AlignLeft },
      { id: 'image_upload', label: 'Image', icon: ImageIcon },
      { id: 'video', label: 'Video', icon: Video },
    ]
  }
];

function FormBuilderComponent() {
  const initialForm = Route.useLoaderData() as any;
  const router = useRouter()

  const [form, setForm] = useState(() => {
    const f = JSON.parse(JSON.stringify(initialForm));
    if (!f.settings) f.settings = {};
    if (!f.form_versions || f.form_versions.length === 0) {
      f.form_versions = [{ id: crypto.randomUUID(), form_sections: [] }];
    }
    if (!f.form_versions[0].form_sections || f.form_versions[0].form_sections.length === 0) {
      f.form_versions[0].form_sections = [{ id: crypto.randomUUID(), title: "", description: "", display_order: 1, form_questions: [] }];
    }
    f.form_versions[0].form_sections.forEach((sec: any) => {
      sec.form_questions = sec.form_questions || [];
      sec.form_questions.forEach((q: any) => {
        if (!q.form_options) q.form_options = [];
        if (!q.validation_rules) q.validation_rules = {};
        if (!q.logic_rules) q.logic_rules = {};
      });
    });
    return f;
  })

  // History stack for Undo/Redo
  const [history, setHistory] = useState<any[]>([JSON.parse(JSON.stringify(form))]);
  const [historyIndex, setHistoryIndex] = useState(0);

  const [selectedQuestionId, setSelectedQuestionId] = useState<string | null>(null)
  const [isPreview, setIsPreview] = useState(false)
  const [isSaving, setIsSaving] = useState(false)
  const [activeTab, setActiveTab] = useState('questions'); // 'questions', 'logic', 'design', 'settings'

  const sections = form.form_versions[0].form_sections;
  const allQuestions = sections.flatMap((s: any) => s.form_questions);
  const selectedQuestion = allQuestions.find((q: any) => q.id === selectedQuestionId);

  // Custom setter that saves to history stack
  const updateFormState = (newForm: any) => {
    setForm(newForm);
    const newHistory = history.slice(0, historyIndex + 1);
    newHistory.push(JSON.parse(JSON.stringify(newForm)));
    setHistory(newHistory);
    setHistoryIndex(newHistory.length - 1);
  }

  const handleUndo = () => {
    if (historyIndex > 0) {
      setHistoryIndex(historyIndex - 1);
      setForm(JSON.parse(JSON.stringify(history[historyIndex - 1])));
    }
  }

  const handleRedo = () => {
    if (historyIndex < history.length - 1) {
      setHistoryIndex(historyIndex + 1);
      setForm(JSON.parse(JSON.stringify(history[historyIndex + 1])));
    }
  }

  const handleDragEnd = (result: any) => {
    if (!result.destination) return;
    const sourceSectionId = result.source.droppableId;
    const destSectionId = result.destination.droppableId;
    
    const newForm = { ...form };
    const sourceSection = newForm.form_versions[0].form_sections.find((s:any) => s.id === sourceSectionId);
    const destSection = newForm.form_versions[0].form_sections.find((s:any) => s.id === destSectionId);
    
    const [movedItem] = sourceSection.form_questions.splice(result.source.index, 1);
    movedItem.section_id = destSectionId;
    destSection.form_questions.splice(result.destination.index, 0, movedItem);
    
    // Update orders
    sourceSection.form_questions.forEach((q:any, idx:number) => q.display_order = idx + 1);
    if (sourceSectionId !== destSectionId) {
      destSection.form_questions.forEach((q:any, idx:number) => q.display_order = idx + 1);
    }
    
    updateFormState(newForm);
  }

  const addQuestion = (typeId: string, label: string) => {
    const isChoice = ['multiple_choice', 'checkboxes', 'dropdown'].includes(typeId);
    
    const newQ = {
      id: crypto.randomUUID(),
      type: typeId,
      title: `New ${label}`,
      description: '',
      required: false,
      display_order: 999, // Will be reordered
      form_options: isChoice 
        ? [{ id: crypto.randomUUID(), label: 'Option 1', value: 'Option 1', display_order: 1 }] 
        : [],
      settings: {},
      validation_rules: typeId === 'linear_scale' ? { min: 1, max: 5 } : {},
      logic_rules: {}
    };

    let targetSectionIndex = sections.length - 1;
    if (selectedQuestionId) {
      const idx = sections.findIndex((s:any) => s.form_questions.some((q:any) => q.id === selectedQuestionId));
      if (idx !== -1) targetSectionIndex = idx;
    }

    const newForm = { ...form };
    newForm.form_versions[0].form_sections[targetSectionIndex].form_questions.push(newQ);
    newForm.form_versions[0].form_sections[targetSectionIndex].form_questions.forEach((q:any, idx:number) => q.display_order = idx + 1);
    updateFormState(newForm);
    setSelectedQuestionId(newQ.id);
  }

  const updateQuestion = (id: string, updates: any) => {
    const newForm = { ...form };
    for (const section of newForm.form_versions[0].form_sections) {
      const qIndex = section.form_questions.findIndex((q: any) => q.id === id);
      if (qIndex !== -1) {
        section.form_questions[qIndex] = { ...section.form_questions[qIndex], ...updates };
        updateFormState(newForm);
        break;
      }
    }
  }

  const deleteQuestion = (id: string) => {
    const newForm = { ...form };
    for (const section of newForm.form_versions[0].form_sections) {
      section.form_questions = section.form_questions.filter((q: any) => q.id !== id);
    }
    updateFormState(newForm);
    if (selectedQuestionId === id) setSelectedQuestionId(null);
  }

  const addSection = () => {
    const newForm = { ...form };
    const displayOrder = newForm.form_versions[0].form_sections.length + 1;
    newForm.form_versions[0].form_sections.push({
      id: crypto.randomUUID(),
      title: `Section ${displayOrder}`,
      description: "",
      display_order: displayOrder,
      form_questions: []
    });
    updateFormState(newForm);
  }

  const updateSection = (id: string, updates: any) => {
    const newForm = { ...form };
    const sIndex = newForm.form_versions[0].form_sections.findIndex((s: any) => s.id === id);
    if (sIndex !== -1) {
      newForm.form_versions[0].form_sections[sIndex] = { ...newForm.form_versions[0].form_sections[sIndex], ...updates };
      updateFormState(newForm);
    }
  }

  const deleteSection = (id: string) => {
    if (form.form_versions[0].form_sections.length <= 1) return;
    const newForm = { ...form };
    newForm.form_versions[0].form_sections = newForm.form_versions[0].form_sections.filter((s: any) => s.id !== id);
    updateFormState(newForm);
  }

  const addOption = (questionId: string) => {
    const newForm = { ...form };
    for (const section of newForm.form_versions[0].form_sections) {
      const q = section.form_questions.find((q: any) => q.id === questionId);
      if (q) {
        const order = q.form_options.length + 1;
        q.form_options.push({ id: crypto.randomUUID(), label: `Option ${order}`, value: `Option ${order}`, display_order: order });
        updateFormState(newForm);
        break;
      }
    }
  }

  const updateOption = (questionId: string, optionId: string, text: string) => {
    const newForm = { ...form };
    for (const section of newForm.form_versions[0].form_sections) {
      const q = section.form_questions.find((q: any) => q.id === questionId);
      if (q) {
        const o = q.form_options.find((o: any) => o.id === optionId);
        if (o) {
          o.label = text;
          o.value = text;
          setForm(newForm);
        }
        break;
      }
    }
  }

  const flushOptionToHistory = () => {
    updateFormState({...form});
  }

  const removeOption = (questionId: string, optionId: string) => {
    const newForm = { ...form };
    for (const section of newForm.form_versions[0].form_sections) {
      const q = section.form_questions.find((q: any) => q.id === questionId);
      if (q) {
        q.form_options = q.form_options.filter((o: any) => o.id !== optionId);
        updateFormState(newForm);
        break;
      }
    }
  }

  const handleSave = async () => {
    setIsSaving(true);
    try {
      await updateFormFn({ data: form });
      toast.success("Draft saved successfully!");
      router.invalidate();
    } catch (e: any) {
      toast.error(e.message || "Failed to save draft");
    } finally {
      setIsSaving(false);
    }
  }

  const handlePublish = async () => {
    try {
      if (allQuestions.length === 0) {
        toast.error("Cannot publish a form without questions.");
        return;
      }
      await handleSave();
      await publishFormFn({ data: { form_id: form.id, form_version_id: form.form_versions[0].id } });
      toast.success("Form Published successfully!");
      router.invalidate();
    } catch(e: any) {
      toast.error(e.message || "Failed to publish form");
    }
  }

  return (
    <div className="h-[calc(100vh-4rem)] flex flex-col bg-slate-50 dark:bg-slate-950">
      {/* Header */}
      <header className="relative h-14 border-b border-slate-200 dark:border-slate-800 bg-white dark:bg-slate-900 flex items-center justify-between px-4 shrink-0">
        <div className="flex items-center gap-4 w-1/3">
          <Button variant="ghost" size="icon" asChild>
            <Link to="/forms"><ArrowLeft size={18} /></Link>
          </Button>
          <div>
            <h1 className="font-semibold text-sm line-clamp-1 max-w-[200px]">{form.title}</h1>
            <p className="text-xs text-slate-500">Draft mode</p>
          </div>
        </div>

        <div className="absolute left-1/2 -translate-x-1/2 hidden md:flex items-center p-1 bg-slate-100 dark:bg-slate-800 rounded-lg shadow-sm border border-slate-200 dark:border-slate-700">
          <Button variant={activeTab === 'questions' ? 'default' : 'ghost'} size="sm" onClick={() => setActiveTab('questions')} className="gap-2 h-8 px-4 rounded-md text-xs"><LayoutTemplate size={14}/> Questions</Button>
          <Button variant={activeTab === 'logic' ? 'default' : 'ghost'} size="sm" onClick={() => setActiveTab('logic')} className="gap-2 h-8 px-4 rounded-md text-xs"><GitBranch size={14}/> Logic</Button>
          <Button variant={activeTab === 'design' ? 'default' : 'ghost'} size="sm" onClick={() => setActiveTab('design')} className="gap-2 h-8 px-4 rounded-md text-xs"><Palette size={14}/> Design</Button>
          <Button variant={activeTab === 'settings' ? 'default' : 'ghost'} size="sm" onClick={() => setActiveTab('settings')} className="gap-2 h-8 px-4 rounded-md text-xs"><Settings2 size={14}/> Settings</Button>
        </div>

        <div className="flex items-center justify-end gap-2 w-1/3">
          <div className="flex bg-slate-100 rounded mr-2">
            <Button variant="ghost" size="sm" onClick={handleUndo} disabled={historyIndex === 0}>Undo</Button>
            <Button variant="ghost" size="sm" onClick={handleRedo} disabled={historyIndex === history.length - 1}>Redo</Button>
          </div>
          <Button variant="outline" size="sm" className="gap-2" onClick={() => setIsPreview(!isPreview)}>
            {isPreview ? 'Close Preview' : <><Eye size={14} /> Preview</>}
          </Button>
          <Button variant="outline" size="sm" className="gap-2" onClick={handleSave} disabled={isSaving}>
            <Save size={14} /> {isSaving ? "Saving..." : "Save Draft"}
          </Button>
          <Button size="sm" className="gap-2 bg-blue-600 hover:bg-blue-700 text-white" onClick={handlePublish} disabled={isSaving}>
            <Send size={14} /> Publish
          </Button>
        </div>
      </header>

      <div className="flex-1 flex overflow-hidden">
        {/* Left Panel: Elements (Hidden in Preview) */}
        {!isPreview && activeTab === 'questions' && (
          <aside className="w-72 border-r border-slate-200 dark:border-slate-800 bg-white dark:bg-slate-900 overflow-y-auto">
            <div className="p-4 border-b border-slate-100 dark:border-slate-800 flex items-center justify-between">
              <div>
                <h2 className="text-sm font-bold text-slate-800 dark:text-slate-200">Form Elements</h2>
                <p className="text-xs text-slate-500 mt-1">Click to add</p>
              </div>
              <Button size="sm" variant="outline" onClick={addSection} className="text-xs gap-1">
                <Plus size={14}/> Section
              </Button>
            </div>
            
            <div className="p-4 space-y-6">
              {QUESTION_CATEGORIES.map(category => (
                <div key={category.title}>
                  <h3 className="text-xs font-semibold text-slate-400 uppercase tracking-wider mb-3">{category.title}</h3>
                  <div className="grid grid-cols-2 gap-2">
                    {category.items.map(item => {
                      const Icon = item.icon;
                      return (
                        <button 
                          key={item.id} 
                          onClick={() => addQuestion(item.id, item.label)}
                          className="flex flex-col items-center justify-center p-3 rounded-lg border border-slate-200 dark:border-slate-800 bg-slate-50 dark:bg-slate-950 hover:border-blue-300 hover:bg-blue-50 dark:hover:bg-slate-800 transition-colors text-xs font-medium text-slate-700 dark:text-slate-300"
                        >
                          <Icon size={16} className="mb-2 text-slate-400" />
                          <span className="text-center leading-tight">{item.label}</span>
                        </button>
                      )
                    })}
                  </div>
                </div>
              ))}
            </div>
          </aside>
        )}

        {/* Center Panel: Canvas */}
        <main className="flex-1 overflow-y-auto p-8 bg-slate-50 dark:bg-slate-950" onClick={() => !isPreview && setSelectedQuestionId(null)}>
          <div className="max-w-3xl mx-auto space-y-4 pb-32" onClick={e => e.stopPropagation()}>
            
            {activeTab === 'questions' && (
              <>
                {/* Form Header */}
                <Card className={`p-8 border-t-8 border-t-blue-600 shadow-sm transition-colors ${!isPreview ? 'cursor-pointer hover:border-slate-300' : ''}`} onClick={() => !isPreview && setSelectedQuestionId(null)}>
                  {!isPreview ? (
                    <>
                      <input 
                        type="text" 
                        className="w-full text-3xl font-bold bg-transparent border-none focus:outline-none focus:ring-0 mb-3 placeholder:text-slate-300" 
                        value={form.title} 
                        onChange={e => setForm({...form, title: e.target.value})} 
                        onBlur={() => updateFormState({...form})}
                        placeholder="Form Title"
                      />
                      <textarea 
                        className="w-full text-base text-slate-600 dark:text-slate-400 bg-transparent border-none focus:outline-none focus:ring-0 resize-none placeholder:text-slate-300" 
                        value={form.description || ''} 
                        rows={2}
                        onChange={e => setForm({...form, description: e.target.value})} 
                        onBlur={() => updateFormState({...form})}
                        placeholder="Form description"
                      />
                    </>
                  ) : (
                    <>
                      <h1 className="text-3xl font-bold mb-3">{form.title}</h1>
                      <p className="text-base text-slate-600">{form.description}</p>
                    </>
                  )}
                </Card>

                {isPreview ? (
                  // PREVIEW MODE RENDERING (renders all sections as one for now)
                  <div className="space-y-4">
                    {sections.map((section: any, sIdx: number) => (
                      <div key={section.id} className="space-y-4">
                        {sections.length > 1 && (
                          <div className="border-t-2 border-blue-200 pt-6 mt-8">
                            <h2 className="text-2xl font-bold text-slate-800">{section.title}</h2>
                            {section.description && <p className="text-slate-500 mt-1">{section.description}</p>}
                          </div>
                        )}
                        {section.form_questions.map((q: any) => (
                          <Card key={q.id} className="p-6 shadow-sm border border-slate-200">
                            {['heading', 'description'].includes(q.type) ? (
                              <div className="py-2">
                                {q.type === 'heading' && <h2 className="text-2xl font-semibold">{q.title}</h2>}
                                {q.type === 'description' && <p className="text-slate-600">{q.title}</p>}
                              </div>
                            ) : (
                              <>
                                <h3 className="text-lg font-medium mb-4">
                                  {q.title} {q.required && <span className="text-red-500">*</span>}
                                </h3>
                                {q.description && <p className="text-sm text-slate-500 mb-4">{q.description}</p>}
                                
                                {(q.type === 'short_text' || q.type === 'student_name' || q.type === 'roll_number' || q.type === 'college_email' || q.type === 'phone' || q.type === 'email' || q.type === 'number' || q.type === 'url') && <input type="text" className="w-full p-2 border rounded" placeholder="Your answer" disabled />}
                                {q.type === 'long_text' && <textarea className="w-full p-2 border rounded" rows={3} placeholder="Your answer" disabled />}
                                {(q.type === 'multiple_choice' || q.type === 'yes_no') && (
                                  <div className="space-y-2">
                                    {q.form_options?.map((o: any) => (
                                      <label key={o.id} className="flex items-center gap-2">
                                        <input type="radio" disabled /> {o.label}
                                      </label>
                                    ))}
                                  </div>
                                )}
                                {q.type === 'checkboxes' && (
                                  <div className="space-y-2">
                                    {q.form_options?.map((o: any) => (
                                      <label key={o.id} className="flex items-center gap-2">
                                        <input type="checkbox" disabled /> {o.label}
                                      </label>
                                    ))}
                                  </div>
                                )}
                                {q.type === 'dropdown' && (
                                  <select className="w-full p-2 border rounded bg-white" disabled>
                                    <option>Select an option</option>
                                    {q.form_options?.map((o: any) => <option key={o.id}>{o.label}</option>)}
                                  </select>
                                )}
                                {q.type === 'file_upload' && <input type="file" className="w-full p-2 border border-dashed rounded" disabled />}
                                {q.type === 'date' && <input type="date" className="w-full p-2 border rounded max-w-[200px]" disabled />}
                                {q.type === 'time' && <input type="time" className="w-full p-2 border rounded max-w-[200px]" disabled />}
                                {q.type === 'linear_scale' && (
                                  <div className="flex items-center justify-between max-w-sm">
                                    <span className="text-sm text-slate-500">1</span>
                                    {[1, 2, 3, 4, 5].map(v => (
                                      <label key={v} className="flex flex-col items-center gap-1">
                                        <span className="text-xs text-slate-400">{v}</span>
                                        <input type="radio" disabled />
                                      </label>
                                    ))}
                                    <span className="text-sm text-slate-500">5</span>
                                  </div>
                                )}
                              </>
                            )}
                          </Card>
                        ))}
                      </div>
                    ))}
                  </div>
                ) : (
                  // BUILDER MODE RENDERING (Multiple Sections via DragDropContext)
                  <DragDropContext onDragEnd={handleDragEnd}>
                    <div className="space-y-12">
                      {sections.map((section: any, sIdx: number) => (
                        <div key={section.id} className="space-y-4">
                          
                          {/* Section Header */}
                          <div className="relative group/section">
                            <Card className="p-6 border border-blue-200 bg-blue-50/50 shadow-sm transition-colors">
                              <div className="flex justify-between items-start">
                                <div className="flex-1">
                                  <div className="flex items-center gap-2 mb-2 text-xs font-bold text-blue-600 uppercase tracking-wider">
                                    Section {sIdx + 1} of {sections.length}
                                  </div>
                                  <input 
                                    type="text" 
                                    className="w-full text-2xl font-bold bg-transparent border-none focus:outline-none placeholder:text-slate-400" 
                                    value={section.title} 
                                    onChange={e => updateSection(section.id, { title: e.target.value })}
                                    placeholder="Section Title"
                                  />
                                  <input 
                                    type="text" 
                                    className="w-full text-sm text-slate-600 bg-transparent border-none focus:outline-none placeholder:text-slate-400 mt-2" 
                                    value={section.description || ''} 
                                    onChange={e => updateSection(section.id, { description: e.target.value })}
                                    placeholder="Section Description (optional)"
                                  />
                                </div>
                                {sections.length > 1 && (
                                  <Button variant="ghost" size="icon" onClick={(e) => { e.stopPropagation(); deleteSection(section.id); }} className="text-slate-400 hover:text-red-500"><Trash2 size={16} /></Button>
                                )}
                              </div>
                            </Card>
                          </div>

                          <Droppable droppableId={section.id}>
                            {(provided) => (
                              <div {...provided.droppableProps} ref={provided.innerRef} className="space-y-4 min-h-[50px] p-2 bg-slate-100 rounded-lg border border-dashed border-slate-300">
                                {section.form_questions.length === 0 && (
                                  <div className="text-center py-4 text-sm text-slate-400">Drag questions here</div>
                                )}
                                {section.form_questions.map((q: any, index: number) => (
                                  <Draggable key={q.id} draggableId={q.id} index={index}>
                                    {(provided) => (
                                      <div 
                                        ref={provided.innerRef} 
                                        {...provided.draggableProps} 
                                        className="relative"
                                      >
                                        <Card 
                                          className={`flex items-start p-6 group cursor-pointer transition-all duration-200 ${
                                            selectedQuestionId === q.id ? 'border-blue-500 ring-1 ring-blue-500 shadow-md' : 'shadow-sm hover:border-slate-300 border-slate-200'
                                          }`}
                                          onClick={() => setSelectedQuestionId(q.id)}
                                        >
                                          <div {...provided.dragHandleProps} className="pt-2 px-1 text-slate-400 cursor-grab opacity-50 group-hover:opacity-100 hover:text-slate-700 absolute left-2 top-1/2 -translate-y-1/2">
                                            <GripVertical size={16} />
                                          </div>
                                          <div className="flex-1 pl-6">
                                            <input 
                                              type="text" 
                                              className="w-full text-lg font-medium bg-transparent border-none focus:outline-none focus:ring-0 mb-2 placeholder:text-slate-300" 
                                              value={q.title} 
                                              onChange={e => updateQuestion(q.id, { title: e.target.value })}
                                              placeholder="Question title"
                                            />
                                            
                                            {selectedQuestionId === q.id && !['section', 'heading'].includes(q.type) && (
                                              <input 
                                                type="text" 
                                                className="w-full text-sm text-slate-500 bg-transparent border-none focus:outline-none mb-4 placeholder:text-slate-300" 
                                                value={q.description || ''} 
                                                onChange={e => updateQuestion(q.id, { description: e.target.value })}
                                                placeholder="Description (optional)"
                                              />
                                            )}
                                            
                                            {/* Input Previews */}
                                            <div className="mb-4">
                                              {(q.type === 'short_text' || q.type === 'student_name' || q.type === 'roll_number' || q.type === 'college_email' || q.type === 'phone' || q.type === 'email' || q.type === 'number' || q.type === 'url') && <div className="p-2 border-b border-slate-200 dark:border-slate-700 text-sm text-slate-400 w-1/2">Short answer text</div>}
                                              {q.type === 'long_text' && <div className="p-2 border border-slate-200 dark:border-slate-700 rounded text-sm text-slate-400 h-20 w-3/4">Long answer text</div>}
                                              
                                              {(q.type === 'multiple_choice' || q.type === 'dropdown' || q.type === 'checkboxes' || q.type === 'yes_no') && (
                                                <div className="space-y-2">
                                                  {q.form_options.map((opt: any) => (
                                                    <div key={opt.id} className="flex items-center gap-2 group/opt">
                                                      <div className={`w-4 h-4 border border-slate-300 ${(q.type === 'multiple_choice' || q.type === 'yes_no') ? 'rounded-full' : 'rounded'}`} />
                                                      <input 
                                                        type="text" 
                                                        value={opt.label} 
                                                        onChange={e => updateOption(q.id, opt.id, e.target.value)}
                                                        onBlur={flushOptionToHistory}
                                                        className="text-sm bg-transparent border-b border-transparent hover:border-slate-300 focus:border-blue-500 focus:outline-none px-1 py-0.5 w-full max-w-sm"
                                                      />
                                                      <button onClick={(e) => { e.stopPropagation(); removeOption(q.id, opt.id); }} className="opacity-0 group-hover/opt:opacity-100 text-slate-400 hover:text-red-500 transition-opacity">
                                                        <Trash2 size={14} />
                                                      </button>
                                                    </div>
                                                  ))}
                                                  {q.type !== 'yes_no' && (
                                                    <button onClick={(e) => { e.stopPropagation(); addOption(q.id); }} className="text-xs text-blue-600 font-medium mt-2 flex items-center gap-1">
                                                      + Add Option
                                                    </button>
                                                  )}
                                                </div>
                                              )}
                                              {q.type === 'file_upload' && <div className="p-6 border-2 border-dashed border-slate-300 rounded-lg text-center text-sm text-slate-500 max-w-md mx-auto">Click to upload file</div>}
                                              {q.type === 'date' && <div className="p-2 border border-slate-200 rounded text-sm text-slate-400 w-40 flex justify-between items-center">MM/DD/YYYY <Calendar size={14}/></div>}
                                              {q.type === 'time' && <div className="p-2 border border-slate-200 rounded text-sm text-slate-400 w-32 flex justify-between items-center">HH:MM <Clock size={14}/></div>}
                                              {q.type === 'linear_scale' && (
                                                <div className="flex items-center justify-between max-w-sm p-4 bg-slate-50 rounded border border-slate-100">
                                                  <span className="text-sm font-medium">1</span>
                                                  <div className="h-2 w-full bg-slate-200 mx-4 rounded"></div>
                                                  <span className="text-sm font-medium">5</span>
                                                </div>
                                              )}
                                            </div>

                                            {/* Toolbar */}
                                            {selectedQuestionId === q.id && (
                                              <div className="flex justify-end items-center gap-4 pt-4 border-t border-slate-100 dark:border-slate-800">
                                                <label className="flex items-center gap-2 text-xs font-medium text-slate-600 cursor-pointer">
                                                  Required 
                                                  <input 
                                                    type="checkbox" 
                                                    checked={q.required} 
                                                    onChange={e => updateQuestion(q.id, { required: e.target.checked })}
                                                    className="rounded border-slate-300 text-blue-600 focus:ring-blue-600 h-4 w-4" 
                                                  />
                                                </label>
                                                <div className="w-px h-6 bg-slate-200" />
                                                <Button variant="ghost" size="icon" onClick={(e) => { e.stopPropagation(); deleteQuestion(q.id); }} className="text-slate-400 hover:text-red-500 h-8 w-8"><Trash2 size={16} /></Button>
                                              </div>
                                            )}
                                          </div>
                                        </Card>
                                      </div>
                                    )}
                                  </Draggable>
                                ))}
                                {provided.placeholder}
                              </div>
                            )}
                          </Droppable>
                        </div>
                      ))}
                    </div>
                  </DragDropContext>
                )}
              </>
            )}

            {activeTab === 'logic' && (
              <div className="py-12 flex flex-col items-center justify-center text-center max-w-lg mx-auto">
                <div className="w-16 h-16 bg-blue-100 text-blue-600 rounded-full flex items-center justify-center mb-6">
                  <GitBranch size={32} />
                </div>
                <h2 className="text-2xl font-bold text-slate-800 mb-2">Visual Logic Editor</h2>
                <p className="text-slate-500 mb-8">Create branching rules based on user responses to guide them through specific sections of the form.</p>
                
                <Card className="w-full text-left p-6 shadow-sm border border-slate-200">
                  <h3 className="font-semibold text-slate-800 border-b border-slate-100 pb-4 mb-4">Logic Flow (Phase 2 Feature)</h3>
                  {sections.map((section: any, sIdx: number) => (
                    <div key={section.id} className="mb-4 last:mb-0">
                      <div className="flex justify-between items-center p-3 bg-slate-50 rounded border border-slate-100">
                        <span className="text-sm font-medium">After Section {sIdx + 1} ({section.title || 'Untitled'})</span>
                        <select className="text-sm p-1.5 rounded border border-slate-200 text-slate-600">
                          <option>Continue to next section</option>
                          <option>Submit Form</option>
                        </select>
                      </div>
                    </div>
                  ))}
                  <Button className="w-full mt-4" variant="outline">Add Question-Level Branching Rule</Button>
                </Card>
              </div>
            )}

            {activeTab === 'design' && (
              <div className="py-12 flex flex-col items-center justify-center text-center max-w-lg mx-auto">
                <div className="w-16 h-16 bg-pink-100 text-pink-600 rounded-full flex items-center justify-center mb-6">
                  <Palette size={32} />
                </div>
                <h2 className="text-2xl font-bold text-slate-800 mb-2">Design & Theming</h2>
                <p className="text-slate-500 mb-8">Customize the look and feel of your Campusly form.</p>
                
                <div className="grid grid-cols-2 gap-4 w-full">
                  <Card className="p-4 border-2 border-blue-500 bg-blue-50 cursor-pointer">
                    <div className="h-16 bg-blue-600 rounded mb-2"></div>
                    <div className="h-2 w-1/2 bg-blue-200 rounded mb-1"></div>
                    <div className="h-2 w-3/4 bg-blue-100 rounded"></div>
                    <p className="text-xs font-bold mt-3 text-blue-700">Campusly Blue</p>
                  </Card>
                  <Card className="p-4 border-2 border-transparent hover:border-slate-300 cursor-pointer shadow-sm">
                    <div className="h-16 bg-slate-900 rounded mb-2"></div>
                    <div className="h-2 w-1/2 bg-slate-200 rounded mb-1"></div>
                    <div className="h-2 w-3/4 bg-slate-100 rounded"></div>
                    <p className="text-xs font-bold mt-3 text-slate-700">Dark Mode</p>
                  </Card>
                </div>
              </div>
            )}

            {activeTab === 'settings' && (
              <div className="py-6 max-w-2xl mx-auto space-y-6">
                <Card className="p-6">
                  <h3 className="text-lg font-bold text-slate-800 mb-4 border-b pb-2">Audience Targeting</h3>
                  <div className="space-y-4 text-sm">
                    <label className="flex flex-col gap-1">
                      <span className="text-slate-700 font-medium">Target Department</span>
                      <select 
                        className="p-2 rounded-lg border border-slate-200 bg-white"
                        value={form.settings?.target_department || ''}
                        onChange={e => updateFormState({...form, settings: {...form.settings, target_department: e.target.value}})}
                      >
                        <option value="">All Departments</option>
                        <option value="CSE">Computer Science</option>
                        <option value="ECE">Electronics</option>
                        <option value="MECH">Mechanical</option>
                      </select>
                    </label>
                  </div>
                </Card>
                <Card className="p-6">
                  <h3 className="text-lg font-bold text-slate-800 mb-4 border-b pb-2">Availability</h3>
                  <div className="grid grid-cols-2 gap-4 text-sm">
                    <label className="flex flex-col gap-1">
                      <span className="text-slate-700 font-medium">Start Date</span>
                      <input 
                        type="datetime-local" 
                        className="p-2 rounded-lg border border-slate-200 bg-white" 
                        value={form.settings?.start_date || ''}
                        onChange={e => updateFormState({...form, settings: {...form.settings, start_date: e.target.value}})}
                      />
                    </label>
                    <label className="flex flex-col gap-1">
                      <span className="text-slate-700 font-medium">End Date</span>
                      <input 
                        type="datetime-local" 
                        className="p-2 rounded-lg border border-slate-200 bg-white"
                        value={form.settings?.end_date || ''}
                        onChange={e => updateFormState({...form, settings: {...form.settings, end_date: e.target.value}})}
                      />
                    </label>
                  </div>
                </Card>
              </div>
            )}
            
          </div>
        </main>

        {/* Right Panel: Properties (Hidden in Preview) */}
        {!isPreview && activeTab === 'questions' && (
          <aside className="w-80 border-l border-slate-200 dark:border-slate-800 bg-white dark:bg-slate-900 overflow-y-auto">
            {selectedQuestion ? (
              <>
                <div className="p-4 border-b border-slate-200 dark:border-slate-800 bg-slate-50/50">
                  <h2 className="text-sm font-bold text-slate-800 flex items-center gap-2">Question Settings</h2>
                  <p className="text-xs text-slate-500 mt-1 capitalize">{selectedQuestion.type.replace(/_/g, ' ')}</p>
                </div>
                <div className="p-4 space-y-8">
                  
                  {/* Validation Rules Section */}
                  <div className="space-y-4">
                    <h3 className="text-xs font-bold text-slate-400 uppercase tracking-wider">Validation</h3>
                    
                    {['short_text', 'long_text'].includes(selectedQuestion.type) && (
                      <div className="space-y-3">
                        <label className="flex flex-col gap-1 text-sm text-slate-700">
                          Min Characters
                          <input 
                            type="number" 
                            value={selectedQuestion.validation_rules?.min_length || ''} 
                            onChange={e => updateQuestion(selectedQuestion.id, { validation_rules: { ...selectedQuestion.validation_rules, min_length: parseInt(e.target.value) } })}
                            className="p-2 rounded border border-slate-200 focus:border-blue-500 focus:ring-1 focus:ring-blue-500" 
                            placeholder="e.g. 10"
                          />
                        </label>
                        <label className="flex flex-col gap-1 text-sm text-slate-700">
                          Max Characters
                          <input 
                            type="number" 
                            value={selectedQuestion.validation_rules?.max_length || ''} 
                            onChange={e => updateQuestion(selectedQuestion.id, { validation_rules: { ...selectedQuestion.validation_rules, max_length: parseInt(e.target.value) } })}
                            className="p-2 rounded border border-slate-200 focus:border-blue-500 focus:ring-1 focus:ring-blue-500" 
                            placeholder="e.g. 500"
                          />
                        </label>
                        <label className="flex flex-col gap-1 text-sm text-slate-700">
                          Regex Pattern
                          <input 
                            type="text" 
                            value={selectedQuestion.validation_rules?.regex || ''} 
                            onChange={e => updateQuestion(selectedQuestion.id, { validation_rules: { ...selectedQuestion.validation_rules, regex: e.target.value } })}
                            className="p-2 rounded border border-slate-200 font-mono text-xs focus:border-blue-500 focus:ring-1 focus:ring-blue-500" 
                            placeholder="^[a-zA-Z]+$"
                          />
                        </label>
                      </div>
                    )}

                    {['number', 'roll_number'].includes(selectedQuestion.type) && (
                      <div className="grid grid-cols-2 gap-2">
                        <label className="flex flex-col gap-1 text-sm text-slate-700">
                          Min Value
                          <input 
                            type="number" 
                            value={selectedQuestion.validation_rules?.min || ''} 
                            onChange={e => updateQuestion(selectedQuestion.id, { validation_rules: { ...selectedQuestion.validation_rules, min: parseInt(e.target.value) } })}
                            className="p-2 rounded border border-slate-200 focus:border-blue-500 focus:ring-1 focus:ring-blue-500" 
                          />
                        </label>
                        <label className="flex flex-col gap-1 text-sm text-slate-700">
                          Max Value
                          <input 
                            type="number" 
                            value={selectedQuestion.validation_rules?.max || ''} 
                            onChange={e => updateQuestion(selectedQuestion.id, { validation_rules: { ...selectedQuestion.validation_rules, max: parseInt(e.target.value) } })}
                            className="p-2 rounded border border-slate-200 focus:border-blue-500 focus:ring-1 focus:ring-blue-500" 
                          />
                        </label>
                      </div>
                    )}

                    {selectedQuestion.type === 'file_upload' && (
                      <div className="space-y-3">
                        <label className="flex flex-col gap-1 text-sm text-slate-700">
                          Max File Size (MB)
                          <input 
                            type="number" 
                            value={selectedQuestion.validation_rules?.max_size_mb || 10} 
                            onChange={e => updateQuestion(selectedQuestion.id, { validation_rules: { ...selectedQuestion.validation_rules, max_size_mb: parseInt(e.target.value) } })}
                            className="p-2 rounded border border-slate-200 focus:border-blue-500" 
                          />
                        </label>
                        <label className="flex flex-col gap-1 text-sm text-slate-700">
                          Allowed Types
                          <input 
                            type="text" 
                            value={selectedQuestion.validation_rules?.allowed_types || 'pdf, docx, png, jpg'} 
                            onChange={e => updateQuestion(selectedQuestion.id, { validation_rules: { ...selectedQuestion.validation_rules, allowed_types: e.target.value } })}
                            className="p-2 rounded border border-slate-200 focus:border-blue-500" 
                            placeholder="pdf, docx, png, jpg"
                          />
                        </label>
                      </div>
                    )}

                    {selectedQuestion.type === 'linear_scale' && (
                      <div className="grid grid-cols-2 gap-2">
                        <label className="flex flex-col gap-1 text-sm text-slate-700">
                          Scale Start
                          <select 
                            value={selectedQuestion.validation_rules?.min || 1} 
                            onChange={e => updateQuestion(selectedQuestion.id, { validation_rules: { ...selectedQuestion.validation_rules, min: parseInt(e.target.value) } })}
                            className="p-2 rounded border border-slate-200 focus:border-blue-500"
                          >
                            <option value={0}>0</option>
                            <option value={1}>1</option>
                          </select>
                        </label>
                        <label className="flex flex-col gap-1 text-sm text-slate-700">
                          Scale End
                          <select 
                            value={selectedQuestion.validation_rules?.max || 5} 
                            onChange={e => updateQuestion(selectedQuestion.id, { validation_rules: { ...selectedQuestion.validation_rules, max: parseInt(e.target.value) } })}
                            className="p-2 rounded border border-slate-200 focus:border-blue-500"
                          >
                            <option value={2}>2</option>
                            <option value={3}>3</option>
                            <option value={4}>4</option>
                            <option value={5}>5</option>
                            <option value={6}>6</option>
                            <option value={7}>7</option>
                            <option value={8}>8</option>
                            <option value={9}>9</option>
                            <option value={10}>10</option>
                          </select>
                        </label>
                      </div>
                    )}
                    
                    {Object.keys(selectedQuestion.validation_rules || {}).length === 0 && !['short_text', 'long_text', 'number', 'roll_number', 'file_upload', 'linear_scale'].includes(selectedQuestion.type) && (
                      <p className="text-xs text-slate-400 italic">No advanced validation available for this type.</p>
                    )}
                  </div>
                </div>
              </>
            ) : (
              <div className="p-8 text-center text-slate-400 flex flex-col items-center justify-center h-full">
                <Settings2 size={48} className="mb-4 opacity-20" />
                <p>Select a question to edit properties</p>
              </div>
            )}
          </aside>
        )}
      </div>
    </div>
  )
}
