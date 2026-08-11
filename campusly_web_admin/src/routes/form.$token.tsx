import { createFileRoute, useRouter } from '@tanstack/react-router'
import { useState } from 'react'
import { getFormByTokenFn, submitFormResponseFn } from '../lib/form-actions'
import { Button } from '../components/ui/button'
import { Card } from '../components/ui/card'
import { toast } from 'sonner'

export const Route = createFileRoute('/form/$token')({
  component: PublicFormRenderer,
  loader: async ({ params }) => {
    try {
      return await getFormByTokenFn({ data: params.token })
    } catch (e: any) {
      throw new Error(e.message || "Failed to load form")
    }
  },
  errorComponent: ({ error }) => (
    <div className="min-h-screen flex items-center justify-center bg-slate-50">
      <Card className="p-8 max-w-md w-full text-center shadow-lg border-t-8 border-t-red-500">
        <h2 className="text-2xl font-bold text-slate-800 mb-2">Unavailable</h2>
        <p className="text-slate-600 mb-6">{error.message}</p>
        <Button onClick={() => window.location.reload()}>Try Again</Button>
      </Card>
    </div>
  )
})

function PublicFormRenderer() {
  const form = Route.useLoaderData() as any;
  const { token } = Route.useParams();
  const router = useRouter();

  const [answers, setAnswers] = useState<Record<string, any>>({});
  const [currentSectionIndex, setCurrentSectionIndex] = useState(0);
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [isSubmitted, setIsSubmitted] = useState(false);

  // We are guaranteed at least one version and one section from the server query
  const sections = form.form_versions[0].form_sections || [];
  const currentSection = sections[currentSectionIndex];

  // Helper to get typed values
  const handleChange = (questionId: string, value: any) => {
    setAnswers(prev => ({
      ...prev,
      [questionId]: value
    }));
  }

  const handleNext = () => {
    // Basic client-side validation logic for current section
    const requiredQuestions = currentSection.form_questions.filter((q: any) => q.required);
    for (const q of requiredQuestions) {
      if (answers[q.id] === undefined || answers[q.id] === null || answers[q.id] === '') {
        toast.error(`Please answer all required questions.`);
        return;
      }
    }
    setCurrentSectionIndex(prev => prev + 1);
    window.scrollTo({ top: 0, behavior: 'smooth' });
  }

  const handleBack = () => {
    setCurrentSectionIndex(prev => prev - 1);
    window.scrollTo({ top: 0, behavior: 'smooth' });
  }

  const handleSubmit = async () => {
    // Validate final section
    const requiredQuestions = currentSection.form_questions.filter((q: any) => q.required);
    for (const q of requiredQuestions) {
      if (answers[q.id] === undefined || answers[q.id] === null || answers[q.id] === '') {
        toast.error(`Please answer all required questions.`);
        return;
      }
    }

    setIsSubmitting(true);
    try {
      const payloadAnswers = Object.entries(answers).map(([question_id, value]) => ({
        question_id,
        value
      }));

      await submitFormResponseFn({ data: { token, answers: payloadAnswers } });
      setIsSubmitted(true);
      window.scrollTo({ top: 0, behavior: 'smooth' });
    } catch (e: any) {
      toast.error(e.message || "Failed to submit form");
    } finally {
      setIsSubmitting(false);
    }
  }

  if (isSubmitted) {
    return (
      <div className="min-h-screen bg-blue-50/50 py-12 px-4 flex items-center justify-center">
        <Card className="max-w-2xl w-full p-12 text-center shadow-md border-t-8 border-t-blue-600">
          <div className="w-20 h-20 bg-green-100 text-green-600 rounded-full flex items-center justify-center mx-auto mb-6 text-4xl font-bold">✓</div>
          <h1 className="text-3xl font-bold text-slate-800 mb-4">{form.title}</h1>
          <p className="text-lg text-slate-600 mb-8">Your response has been recorded successfully.</p>
          <div className="text-sm text-slate-400">Powered by Campusly</div>
        </Card>
      </div>
    )
  }

  return (
    <div className="min-h-screen bg-blue-50/50 py-12 px-4">
      <div className="max-w-3xl mx-auto space-y-6">
        
        {/* Form Title & Description (Only show on first section or global) */}
        {currentSectionIndex === 0 && (
          <Card className="p-8 border-t-8 border-t-blue-600 shadow-md">
            <h1 className="text-3xl font-bold text-slate-900 mb-4">{form.title}</h1>
            {form.description && (
              <p className="text-base text-slate-700 whitespace-pre-wrap leading-relaxed">{form.description}</p>
            )}
            {form.settings?.target_department && (
              <div className="mt-6 inline-flex items-center gap-2 px-3 py-1 bg-blue-100 text-blue-700 text-xs font-semibold rounded-full uppercase tracking-wider">
                {form.settings.target_department} Dept Only
              </div>
            )}
          </Card>
        )}

        {/* Section Title (If multiple sections) */}
        {sections.length > 1 && (
          <div className="px-2 pt-4">
            <h2 className="text-xl font-bold text-slate-800">{currentSection.title}</h2>
            {currentSection.description && <p className="text-sm text-slate-500 mt-1">{currentSection.description}</p>}
          </div>
        )}

        {/* Questions for Current Section */}
        {currentSection.form_questions.map((q: any) => {
          if (q.type === 'heading') {
            return (
              <div key={q.id} className="pt-6 pb-2 px-2">
                <h3 className="text-2xl font-semibold text-slate-800">{q.title}</h3>
              </div>
            );
          }
          if (q.type === 'description') {
            return (
              <div key={q.id} className="pb-4 px-2">
                <p className="text-slate-600 whitespace-pre-wrap">{q.title}</p>
              </div>
            );
          }

          return (
            <Card key={q.id} className={`p-6 shadow-sm border ${answers[q.id] === undefined && q.required ? 'border-l-4 border-l-red-500 border-slate-200' : 'border-slate-200'}`}>
              <div className="mb-4">
                <h3 className="text-base font-semibold text-slate-800">
                  {q.title} {q.required && <span className="text-red-500 ml-1">*</span>}
                </h3>
                {q.description && <p className="text-sm text-slate-500 mt-1">{q.description}</p>}
              </div>

              <div className="mt-4">
                {/* Text Inputs */}
                {['short_text', 'student_name', 'roll_number', 'college_email', 'email', 'url', 'phone'].includes(q.type) && (
                  <input 
                    type={['email', 'college_email'].includes(q.type) ? 'email' : q.type === 'url' ? 'url' : 'text'}
                    className="w-full md:w-2/3 p-3 border border-slate-300 rounded-md focus:border-blue-500 focus:ring-1 focus:ring-blue-500 outline-none transition-all"
                    placeholder="Your answer"
                    value={answers[q.id] || ''}
                    onChange={(e) => handleChange(q.id, e.target.value)}
                  />
                )}

                {/* Number */}
                {q.type === 'number' && (
                  <input 
                    type="number"
                    className="w-full md:w-1/3 p-3 border border-slate-300 rounded-md focus:border-blue-500 focus:ring-1 focus:ring-blue-500 outline-none transition-all"
                    placeholder="Your answer"
                    value={answers[q.id] || ''}
                    onChange={(e) => handleChange(q.id, e.target.value !== '' ? Number(e.target.value) : '')}
                  />
                )}

                {/* Long Text */}
                {q.type === 'long_text' && (
                  <textarea 
                    className="w-full p-3 border border-slate-300 rounded-md focus:border-blue-500 focus:ring-1 focus:ring-blue-500 outline-none transition-all resize-y"
                    rows={4}
                    placeholder="Your answer"
                    value={answers[q.id] || ''}
                    onChange={(e) => handleChange(q.id, e.target.value)}
                  />
                )}

                {/* Multiple Choice & Yes/No */}
                {['multiple_choice', 'yes_no'].includes(q.type) && (
                  <div className="space-y-3">
                    {q.form_options?.map((opt: any) => (
                      <label key={opt.id} className="flex items-start gap-3 cursor-pointer group">
                        <div className="mt-0.5">
                          <input 
                            type="radio"
                            name={`q_${q.id}`}
                            value={opt.value}
                            checked={answers[q.id] === opt.value}
                            onChange={(e) => handleChange(q.id, e.target.value)}
                            className="w-4 h-4 text-blue-600 border-slate-300 focus:ring-blue-500 cursor-pointer"
                          />
                        </div>
                        <span className="text-slate-700">{opt.label}</span>
                      </label>
                    ))}
                  </div>
                )}

                {/* Checkboxes */}
                {q.type === 'checkboxes' && (
                  <div className="space-y-3">
                    {q.form_options?.map((opt: any) => {
                      const currentVals = Array.isArray(answers[q.id]) ? answers[q.id] : [];
                      return (
                        <label key={opt.id} className="flex items-start gap-3 cursor-pointer group">
                          <div className="mt-0.5">
                            <input 
                              type="checkbox"
                              value={opt.value}
                              checked={currentVals.includes(opt.value)}
                              onChange={(e) => {
                                if (e.target.checked) {
                                  handleChange(q.id, [...currentVals, opt.value]);
                                } else {
                                  handleChange(q.id, currentVals.filter((v: any) => v !== opt.value));
                                }
                              }}
                              className="w-4 h-4 rounded text-blue-600 border-slate-300 focus:ring-blue-500 cursor-pointer"
                            />
                          </div>
                          <span className="text-slate-700">{opt.label}</span>
                        </label>
                      )
                    })}
                  </div>
                )}

                {/* Dropdown */}
                {q.type === 'dropdown' && (
                  <select 
                    className="w-full md:w-1/2 p-3 border border-slate-300 rounded-md focus:border-blue-500 focus:ring-1 focus:ring-blue-500 outline-none transition-all bg-white"
                    value={answers[q.id] || ''}
                    onChange={(e) => handleChange(q.id, e.target.value)}
                  >
                    <option value="" disabled>Select your answer</option>
                    {q.form_options?.map((opt: any) => (
                      <option key={opt.id} value={opt.value}>{opt.label}</option>
                    ))}
                  </select>
                )}

                {/* Linear Scale */}
                {q.type === 'linear_scale' && (
                  <div className="flex items-center justify-between md:justify-start gap-4">
                    <span className="text-sm font-medium text-slate-500">{q.validation_rules?.min || 1}</span>
                    <div className="flex gap-4 md:gap-8">
                      {Array.from({ length: (q.validation_rules?.max || 5) - (q.validation_rules?.min || 1) + 1 }, (_, i) => (q.validation_rules?.min || 1) + i).map((val) => (
                        <label key={val} className="flex flex-col items-center gap-2 cursor-pointer">
                          <span className="text-sm text-slate-600">{val}</span>
                          <input 
                            type="radio" 
                            name={`q_${q.id}`} 
                            value={val}
                            checked={answers[q.id] === val}
                            onChange={(e) => handleChange(q.id, Number(e.target.value))}
                            className="w-5 h-5 text-blue-600 border-slate-300 focus:ring-blue-500" 
                          />
                        </label>
                      ))}
                    </div>
                    <span className="text-sm font-medium text-slate-500">{q.validation_rules?.max || 5}</span>
                  </div>
                )}
                
                {/* Date / Time */}
                {q.type === 'date' && (
                  <input 
                    type="date"
                    className="w-full md:w-1/3 p-3 border border-slate-300 rounded-md focus:border-blue-500 focus:ring-1 focus:ring-blue-500 outline-none transition-all"
                    value={answers[q.id] || ''}
                    onChange={(e) => handleChange(q.id, e.target.value)}
                  />
                )}
                {q.type === 'time' && (
                  <input 
                    type="time"
                    className="w-full md:w-1/3 p-3 border border-slate-300 rounded-md focus:border-blue-500 focus:ring-1 focus:ring-blue-500 outline-none transition-all"
                    value={answers[q.id] || ''}
                    onChange={(e) => handleChange(q.id, e.target.value)}
                  />
                )}
                {q.type === 'file_upload' && (
                  <input 
                    type="file"
                    className="w-full md:w-2/3 p-3 border border-slate-300 rounded-md text-sm file:mr-4 file:py-2 file:px-4 file:rounded-md file:border-0 file:text-sm file:font-semibold file:bg-blue-50 file:text-blue-700 hover:file:bg-blue-100"
                    onChange={(e) => toast.info('File upload storage not yet implemented in Phase 3')}
                  />
                )}
              </div>
            </Card>
          );
        })}

        {/* Wizard Controls */}
        <div className="flex items-center justify-between pt-6">
          <div className="w-1/3">
            {currentSectionIndex > 0 && (
              <Button variant="outline" onClick={handleBack} disabled={isSubmitting}>
                Back
              </Button>
            )}
          </div>
          
          <div className="w-1/3 text-center text-sm text-slate-400 font-medium">
            {sections.length > 1 && `Page ${currentSectionIndex + 1} of ${sections.length}`}
          </div>
          
          <div className="w-1/3 flex justify-end">
            {currentSectionIndex < sections.length - 1 ? (
              <Button onClick={handleNext} disabled={isSubmitting}>
                Next
              </Button>
            ) : (
              <Button className="bg-blue-600 hover:bg-blue-700 text-white min-w-[120px]" onClick={handleSubmit} disabled={isSubmitting}>
                {isSubmitting ? 'Submitting...' : 'Submit'}
              </Button>
            )}
          </div>
        </div>
        
        <div className="text-center pt-8 pb-4">
          <span className="text-xs font-semibold text-slate-400 uppercase tracking-widest">Campusly Forms</span>
        </div>

      </div>
    </div>
  )
}
