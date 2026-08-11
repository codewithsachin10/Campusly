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
