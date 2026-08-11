import { createClient } from '@supabase/supabase-js';

const supabaseUrl = process.env.VITE_SUPABASE_URL;
const supabaseServiceKey = process.env.SUPABASE_SERVICE_ROLE_KEY;
const supabase = createClient(supabaseUrl, supabaseServiceKey);

async function test() {
  const { data, error } = await supabase.from("forms").select("*, _count:form_responses(count)").order("created_at", { ascending: false });
  console.log(error ? error : `Found ${data.length} forms.`);
}
test();
