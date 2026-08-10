const { createClient } = require('@supabase/supabase-js');
const supabase = createClient(
  'https://jvrxoyswzjuhsofqnqym.supabase.co',
  'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imp2cnhveXN3emp1aHNvZnFucXltIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODU5MjU3NDMsImV4cCI6MjEwMTUwMTc0M30.ulsZel_C1qz2BvTxgSoZNiuDBPNC-a8UP42_aAYXvqc'
);
async function run() {
  const { data, error } = await supabase.from('notifications').insert({
    title: '🚨 Class Venue Changed',
    body: 'Mathematics (CAMPUS-CSBS-B1) has moved from 101 to 102.',
    priority: 'high',
    target: 'System Auto-Alert'
  }).select();
  console.log(error || data);
}
run();
