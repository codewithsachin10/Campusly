const { createClient } = require('@supabase/supabase-js');
const supabase = createClient(
  'https://jvrxoyswzjuhsofqnqym.supabase.co',
  'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imp2cnhveXN3emp1aHNvZnFucXltIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODU5MjU3NDMsImV4cCI6MjEwMTUwMTc0M30.ulsZel_C1qz2BvTxgSoZNiuDBPNC-a8UP42_aAYXvqc'
);
async function run() {
  const { data, error } = await supabase.rpc('get_publication', { publication_name: 'supabase_realtime' });
  console.log(data, error);
}
run();
