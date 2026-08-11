import { createClient } from '@supabase/supabase-js';
import crypto from 'crypto';

const supabaseUrl = process.env.VITE_SUPABASE_URL;
const supabaseServiceKey = process.env.SUPABASE_SERVICE_ROLE_KEY;
const supabase = createClient(supabaseUrl, supabaseServiceKey);

async function testSubmit() {
  // Replace this with the token you get when running node seed_feedback_form.cjs
  const linkToken = "4s8kugskk5eq7gdpta783";
  const { data: link } = await supabase.from('form_public_links').select('*').eq('public_token', linkToken).single();
  
  if (!link) {
    console.error("Link not found");
    return;
  }

  // Get questions
  const { data: form } = await supabase.from('forms').select('*, form_versions(*, form_sections(*, form_questions(*)))').eq('id', link.form_id).single();
  const questions = form.form_versions[0].form_sections.flatMap(s => s.form_questions);
  
  // Submit mock response
  const { data: response, error: respError } = await supabase.from('form_responses').insert([{
    form_id: link.form_id,
    form_version_id: link.form_version_id,
    status: 'submitted',
    submitted_at: new Date().toISOString()
  }]).select().single();

  if (respError) throw respError;

  const answersToInsert = questions.map(q => {
    let ans = { response_id: response.id, question_id: q.id };
    if (q.type === 'linear_scale') ans.answer_number = 4;
    else if (q.type === 'multiple_choice' && q.title.includes('rate Campusly')) ans.answer_number = 4;
    else if (q.type === 'multiple_choice') ans.answer_text = 'Timetable';
    else if (q.type === 'checkboxes') ans.answer_json = ['Design/UI', 'Performance'];
    else if (q.type === 'short_text') ans.answer_text = 'It is very fast';
    else if (q.type === 'email') ans.answer_text = 'test@example.com';
    return ans;
  }).filter(a => a.answer_text || a.answer_number !== undefined || a.answer_json);

  const { error: ansError } = await supabase.from('form_response_answers').insert(answersToInsert);
  
  console.log(ansError ? ansError : 'Successfully submitted mock response!');
}
testSubmit();
