import { createFileRoute } from '@tanstack/react-router'
import { useState, useEffect } from 'react'
import { Card, CardContent, CardHeader, CardTitle, CardDescription } from '../components/ui/card'
import { Button } from '../components/ui/button'
import { supabase } from '../lib/supabase'

export const Route = createFileRoute('/form/$token')({
  component: PublicFormRendererComponent,
  loader: async ({ params }) => {
    // 1. Resolve token
    const { data: link, error: linkError } = await supabase
      .from("form_public_links")
      .select("*")
      .eq("public_token", params.token)
      .eq("is_active", true)
      .single()

    if (linkError || !link) {
      throw new Error("Invalid or expired form link.")
    }

    // 2. Fetch Form Data
    const { data: form, error: formError } = await supabase
      .from("forms")
      .select("*, form_versions(*, form_sections(*, form_questions(*, form_options(*))))")
      .eq("id", link.form_id)
      .eq("form_versions.id", link.form_version_id)
      .single()

    if (formError || !form) {
      throw new Error("Form not found.")
    }

    return form
  },
  errorComponent: ({ error }) => {
    return (
      <div className="min-h-screen bg-slate-50 flex items-center justify-center p-4">
        <Card className="max-w-md w-full">
          <CardHeader>
            <CardTitle className="text-red-600">Error Loading Form</CardTitle>
            <CardDescription>{error.message}</CardDescription>
          </CardHeader>
        </Card>
      </div>
    )
  }
})

function PublicFormRendererComponent() {
  const form = Route.useLoaderData()
  const [answers, setAnswers] = useState<Record<string, any>>({})
  const [isSubmitting, setIsSubmitting] = useState(false)
  const [isSuccess, setIsSuccess] = useState(false)
  const version = form.form_versions[0]
  const sections = version.form_sections.sort((a: any, b: any) => a.order_index - b.order_index)

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault()
    setIsSubmitting(true)

    try {
      // Create response
      const { data: response, error: responseError } = await supabase
        .from('form_responses')
        .insert({
          form_id: form.id,
          form_version_id: version.id,
          status: 'completed'
          // student_id is null for completely public forms, or we would check auth here
        })
        .select()
        .single()

      if (responseError) throw responseError

      // Insert answers
      const answerInserts = Object.entries(answers).map(([questionId, value]) => {
        let text_value = null
        let json_value = null
        if (typeof value === 'string') text_value = value
        else if (Array.isArray(value)) json_value = value

        return {
          response_id: response.id,
          question_id: questionId,
          text_value,
          json_value
        }
      })

      if (answerInserts.length > 0) {
        const { error: answersError } = await supabase.from('form_response_answers').insert(answerInserts)
        if (answersError) throw answersError
      }

      setIsSuccess(true)
    } catch (e: any) {
      alert("Failed to submit form: " + e.message)
    } finally {
      setIsSubmitting(false)
    }
  }

  if (isSuccess) {
    return (
      <div className="min-h-screen bg-slate-50 flex items-center justify-center p-4">
        <Card className="max-w-md w-full text-center py-8">
          <CardHeader>
            <div className="w-16 h-16 bg-green-100 text-green-600 rounded-full flex items-center justify-center mx-auto mb-4">
              <svg className="w-8 h-8" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M5 13l4 4L19 7" />
              </svg>
            </div>
            <CardTitle>Response Submitted!</CardTitle>
            <CardDescription>Thank you for filling out {form.title}.</CardDescription>
          </CardHeader>
        </Card>
      </div>
    )
  }

  return (
    <div className="min-h-screen bg-slate-100 py-12 px-4 sm:px-6 lg:px-8">
      <div className="max-w-3xl mx-auto space-y-6">
        <Card className="border-t-4 border-t-blue-600">
          <CardHeader>
            <CardTitle className="text-3xl">{form.title}</CardTitle>
            {form.description && <CardDescription className="text-base mt-2">{form.description}</CardDescription>}
          </CardHeader>
        </Card>

        <form onSubmit={handleSubmit} className="space-y-6">
          {sections.map((section: any) => (
            <Card key={section.id}>
              <CardHeader>
                <CardTitle className="text-xl">{section.title}</CardTitle>
                {section.description && <CardDescription>{section.description}</CardDescription>}
              </CardHeader>
              <CardContent className="space-y-8">
                {section.form_questions.sort((a: any, b: any) => a.order_index - b.order_index).map((question: any) => (
                  <div key={question.id} className="space-y-3">
                    <label className="block text-base font-medium text-slate-900">
                      {question.question_text}
                      {question.is_required && <span className="text-red-500 ml-1">*</span>}
                    </label>
                    {question.help_text && <p className="text-sm text-slate-500">{question.help_text}</p>}
                    
                    {question.question_type === 'short_text' && (
                      <input 
                        type="text" 
                        required={question.is_required}
                        className="mt-1 block w-full rounded-md border-slate-300 shadow-sm focus:border-blue-500 focus:ring-blue-500 p-2 border"
                        value={answers[question.id] || ''}
                        onChange={(e) => setAnswers(prev => ({ ...prev, [question.id]: e.target.value }))}
                      />
                    )}
                    
                    {question.question_type === 'multiple_choice' && (
                      <div className="space-y-2">
                        {question.form_options.sort((a: any, b: any) => a.order_index - b.order_index).map((opt: any) => (
                          <label key={opt.id} className="flex items-center">
                            <input 
                              type="radio" 
                              name={question.id} 
                              required={question.is_required}
                              value={opt.id}
                              checked={answers[question.id] === opt.id}
                              onChange={() => setAnswers(prev => ({ ...prev, [question.id]: opt.id }))}
                              className="h-4 w-4 text-blue-600 focus:ring-blue-500 border-gray-300"
                            />
                            <span className="ml-2 text-slate-700">{opt.option_text}</span>
                          </label>
                        ))}
                      </div>
                    )}
                  </div>
                ))}
              </CardContent>
            </Card>
          ))}

          <div className="flex justify-between items-center bg-white p-4 rounded-lg border border-slate-200 shadow-sm">
            <p className="text-sm text-slate-500">Never submit passwords through forms.</p>
            <Button type="submit" disabled={isSubmitting}>
              {isSubmitting ? 'Submitting...' : 'Submit Response'}
            </Button>
          </div>
        </form>
      </div>
    </div>
  )
}
