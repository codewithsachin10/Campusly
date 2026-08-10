const { createClient } = require('@supabase/supabase-js');
const supabase = createClient(
  'https://jvrxoyswzjuhsofqnqym.supabase.co',
  'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imp2cnhveXN3emp1aHNvZnFucXltIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODU5MjU3NDMsImV4cCI6MjEwMTUwMTc0M30.ulsZel_C1qz2BvTxgSoZNiuDBPNC-a8UP42_aAYXvqc'
);
async function run() {
  const { data, error } = await supabase.functions.invoke('notify-class-change', {
    body: {
      timetable_id: 'test',
      period_id: 'test',
      old_data: { room: '101' },
      new_data: { room: '102' },
      change_type: 'VENUE_CHANGED',
      subject_name: 'Test Subject'
    }
  });
  console.log(data, error);
}
run();
