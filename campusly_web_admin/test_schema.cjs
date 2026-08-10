const { createClient } = require('@supabase/supabase-js');
const supabase = createClient(
  'https://jvrxoyswzjuhsofqnqym.supabase.co',
  'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imp2cnhveXN3emp1aHNvZnFucXltIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODU5MjU3NDMsImV4cCI6MjEwMTUwMTc0M30.ulsZel_C1qz2BvTxgSoZNiuDBPNC-a8UP42_aAYXvqc'
);
async function run() {
  const { data, error } = await supabase.from('timetable_change_events').insert({
    timetable_id: '123e4567-e89b-12d3-a456-426614174000',
    timetable_entry_id: '123e4567-e89b-12d3-a456-426614174001',
    change_type: 'VENUE_CHANGED',
    old_data: {},
    new_data: {},
    affected_student_count: 0,
    created_by: '123e4567-e89b-12d3-a456-426614174002',
    notification_status: 'PROCESSING'
  }).select();
  console.log(error);
}
run();
