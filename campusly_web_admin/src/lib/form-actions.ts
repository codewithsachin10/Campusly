import { createServerFn } from "@tanstack/react-start";
import { createClient } from '@supabase/supabase-js'

const getSupabaseAdmin = () => {
  const supabaseUrl = process.env.VITE_SUPABASE_URL;
  const supabaseServiceKey = process.env.SUPABASE_SERVICE_ROLE_KEY;
  if (!supabaseUrl || !supabaseServiceKey) throw new Error("Missing env variables");
  return createClient(supabaseUrl, supabaseServiceKey);
};

export const getFormsFn = createServerFn({ method: "GET" }).handler(async () => {
  const supabaseAdmin = getSupabaseAdmin();
  const { data, error } = await supabaseAdmin
    .from("forms")
    .select("*, _count:form_responses(count)")
    .order("created_at", { ascending: false });

  if (error) {
    throw error;
  }
  return data || [];
});

export const getFormFn = createServerFn({ method: "GET" })
  .validator((formId: string) => formId)
  .handler(async ({ data: formId }) => {
  const supabaseAdmin = getSupabaseAdmin();
  const { data, error } = await supabaseAdmin
    .from("forms")
    .select("*, form_versions(*, form_sections(*, form_questions(*, form_options(*))))")
    .eq("id", formId)
    .single();

  if (error) {
    throw error;
  }
  return data;
});

export const createFormFn = createServerFn({ method: "POST" })
  .validator((payload: { title: string; description: string; category: string; created_by: string }) => payload)
  .handler(async ({ data: payload }) => {
  const supabaseAdmin = getSupabaseAdmin();
  const { data: form, error: formError } = await supabaseAdmin
    .from("forms")
    .insert([
      {
        title: payload.title,
        description: payload.description,
        category: payload.category,
        created_by: payload.created_by,
      },
    ])
    .select()
    .single();

  if (formError) throw formError;

  const { data: version, error: versionError } = await supabaseAdmin
    .from("form_versions")
    .insert([
      {
        form_id: form.id,
        version_number: 1,
        created_by: payload.created_by,
      },
    ])
    .select()
    .single();

  if (versionError) throw versionError;

  return { form, version };
});

export const updateFormFn = createServerFn({ method: "POST" })
  .validator((payload: any) => payload)
  .handler(async ({ data: payload }) => {
    const supabaseAdmin = getSupabaseAdmin();
    
    // Update forms
    await supabaseAdmin.from("forms").update({
      title: payload.title,
      description: payload.description,
      settings: payload.settings
    }).eq("id", payload.id);

    const versionId = payload.form_versions[0].id;

    const sections = payload.form_versions[0].form_sections.map((s: any) => ({
      id: s.id,
      form_version_id: versionId,
      title: s.title,
      description: s.description,
      display_order: s.display_order
    }));

    const questions: any[] = [];
    const options: any[] = [];

    payload.form_versions[0].form_sections.forEach((s: any) => {
      s.form_questions.forEach((q: any) => {
        questions.push({
          id: q.id,
          form_version_id: versionId,
          section_id: s.id,
          type: q.type,
          title: q.title,
          description: q.description,
          placeholder: q.placeholder,
          required: q.required,
          display_order: q.display_order,
          settings: q.settings,
          validation_rules: q.validation_rules,
          logic_rules: q.logic_rules
        });

        if (q.form_options) {
          q.form_options.forEach((o: any) => {
            options.push({
              id: o.id,
              question_id: q.id,
              label: o.label,
              value: o.value,
              display_order: o.display_order
            });
          });
        }
      });
    });

    if (sections.length > 0) await supabaseAdmin.from("form_sections").upsert(sections);
    if (questions.length > 0) await supabaseAdmin.from("form_questions").upsert(questions);
    if (options.length > 0) await supabaseAdmin.from("form_options").upsert(options);

    // Delete orphans
    if (options.length > 0 && questions.length > 0) {
      await supabaseAdmin.from("form_options").delete().in('question_id', questions.map(q => q.id)).not('id', 'in', `(${options.map(o => o.id).join(',')})`);
    } else if (questions.length > 0) {
      await supabaseAdmin.from("form_options").delete().in('question_id', questions.map(q => q.id));
    }
    
    if (questions.length > 0) {
      await supabaseAdmin.from("form_questions").delete().eq('form_version_id', versionId).not('id', 'in', `(${questions.map(q => q.id).join(',')})`);
    } else {
      await supabaseAdmin.from("form_questions").delete().eq('form_version_id', versionId);
    }

    if (sections.length > 0) {
      await supabaseAdmin.from("form_sections").delete().eq('form_version_id', versionId).not('id', 'in', `(${sections.map(s => s.id).join(',')})`);
    } else {
      await supabaseAdmin.from("form_sections").delete().eq('form_version_id', versionId);
    }

    return { success: true };
  });

function generateSecureToken() {
  return Math.random().toString(36).substring(2, 15) + Math.random().toString(36).substring(2, 15);
}

export const publishFormFn = createServerFn({ method: "POST" })
  .validator((payload: { form_id: string; form_version_id: string }) => payload)
  .handler(async ({ data: payload }) => {
  const supabaseAdmin = getSupabaseAdmin();
  await supabaseAdmin.from("forms").update({ status: "published", published_at: new Date().toISOString() }).eq("id", payload.form_id);
  await supabaseAdmin.from("form_versions").update({ status: "published", published_at: new Date().toISOString() }).eq("id", payload.form_version_id);

  const { data: existingLink } = await supabaseAdmin.from("form_public_links").select("*").eq("form_id", payload.form_id).single();
  
  if (!existingLink) {
    const token = generateSecureToken();
    await supabaseAdmin.from("form_public_links").insert([{
      form_id: payload.form_id,
      form_version_id: payload.form_version_id,
      public_token: token
    }]);
    return { token };
  }

  return { token: existingLink.public_token };
});

export const getFormByTokenFn = createServerFn({ method: "GET" })
  .validator((token: string) => token)
  .handler(async ({ data: token }) => {
    const supabaseAdmin = getSupabaseAdmin();
    const { data: link, error: linkError } = await supabaseAdmin
      .from("form_public_links")
      .select("*")
      .eq("public_token", token)
      .eq("active", true)
      .single();

    if (linkError || !link) {
      throw new Error("Form link is invalid or inactive");
    }

    const { data: form, error: formError } = await supabaseAdmin
      .from("forms")
      .select("*, form_versions(*, form_sections(*, form_questions(*, form_options(*))))")
      .eq("id", link.form_id)
      .single();

    if (formError || !form) throw new Error("Form not found");

    const publishedVersion = form.form_versions.find((v: any) => v.id === link.form_version_id && v.status === "published");
    if (!publishedVersion) throw new Error("Form version is no longer published");

    form.form_versions = [publishedVersion];

    if (form.settings?.start_date && new Date(form.settings.start_date) > new Date()) {
      throw new Error("This form is not yet accepting responses");
    }
    if (form.settings?.end_date && new Date(form.settings.end_date) < new Date()) {
      throw new Error("This form is no longer accepting responses");
    }

    return form;
  });

export const submitFormResponseFn = createServerFn({ method: "POST" })
  .validator((payload: { token: string; answers: any[], userId?: string }) => payload)
  .handler(async ({ data: payload }) => {
    const supabaseAdmin = getSupabaseAdmin();

    const { data: link, error: linkError } = await supabaseAdmin
      .from("form_public_links")
      .select("*")
      .eq("public_token", payload.token)
      .eq("active", true)
      .single();

    if (linkError || !link) {
      throw new Error("Form link is invalid or inactive");
    }

    const { data: response, error: respError } = await supabaseAdmin
      .from("form_responses")
      .insert([{
        form_id: link.form_id,
        form_version_id: link.form_version_id,
        user_id: payload.userId || null,
        status: "submitted",
        submitted_at: new Date().toISOString()
      }])
      .select()
      .single();

    if (respError) throw respError;

    const answersToInsert = payload.answers.map(ans => ({
      response_id: response.id,
      question_id: ans.question_id,
      answer_text: typeof ans.value === 'string' ? ans.value : null,
      answer_number: typeof ans.value === 'number' ? ans.value : null,
      answer_boolean: typeof ans.value === 'boolean' ? ans.value : null,
      answer_json: typeof ans.value === 'object' ? ans.value : null,
    }));

    if (answersToInsert.length > 0) {
      const { error: ansError } = await supabaseAdmin
        .from("form_response_answers")
        .insert(answersToInsert);

      if (ansError) {
        await supabaseAdmin.from("form_responses").delete().eq("id", response.id);
        throw ansError;
      }
    }


    return { success: true, responseId: response.id };
  });

export const getFormResponsesAnalyticsFn = createServerFn({ method: "GET" })
  .validator((formId: string) => formId)
  .handler(async ({ data: formId }) => {
    const supabaseAdmin = getSupabaseAdmin();
    
    // Fetch form details and questions
    const { data: form, error: formError } = await supabaseAdmin
      .from("forms")
      .select("*, form_versions(*, form_sections(*, form_questions(*, form_options(*))))")
      .eq("id", formId)
      .single();

    if (formError || !form) throw new Error("Form not found");

    // Fetch responses
    const { data: responses, error: respError } = await supabaseAdmin
      .from("form_responses")
      .select("*")
      .eq("form_id", formId)
      .order("submitted_at", { ascending: false });
      
    if (respError) throw respError;

    // Fetch all answers for these responses
    const responseIds = responses.map((r: any) => r.id);
    let answers = [];
    if (responseIds.length > 0) {
      const { data: ansData, error: ansError } = await supabaseAdmin
        .from("form_response_answers")
        .select("*")
        .in("response_id", responseIds);
      if (!ansError && ansData) {
        answers = ansData;
      }
    }

    const sections = form.form_versions[0]?.form_sections || [];
    const questions = sections.flatMap((s: any) => s.form_questions);

    // Aggregate Analytics
    const analytics: Record<string, any> = {};
    
    questions.forEach((q: any) => {
      if (['multiple_choice', 'dropdown', 'checkboxes', 'linear_scale', 'yes_no'].includes(q.type)) {
        analytics[q.id] = { question: q, stats: {} };
        const qAnswers = answers.filter((a: any) => a.question_id === q.id);
        
        qAnswers.forEach((ans: any) => {
          let value = null;
          if (ans.answer_text) value = ans.answer_text;
          else if (ans.answer_number !== null) value = ans.answer_number.toString();
          else if (ans.answer_boolean !== null) value = ans.answer_boolean ? 'Yes' : 'No';
          else if (ans.answer_json) value = ans.answer_json; // Array for checkboxes
          
          if (Array.isArray(value)) {
            value.forEach(v => {
              const valStr = String(v);
              analytics[q.id].stats[valStr] = (analytics[q.id].stats[valStr] || 0) + 1;
            });
          } else if (value !== null) {
            const valStr = String(value);
            analytics[q.id].stats[valStr] = (analytics[q.id].stats[valStr] || 0) + 1;
          }
        });
      }
    });

    return {
      form,
      responses,
      totalResponses: responses.length,
      analytics
    };
  });
