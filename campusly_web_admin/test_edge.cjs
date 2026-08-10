const { createClient } = require('@supabase/supabase-js');
const supabaseUrl = 'https://jvrxoyswzjuhsofqnqym.supabase.co';
const supabaseKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imp2cnhveXN3emp1aHNvZnFucXltIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODU5MjU3NDMsImV4cCI6MjEwMTUwMTc0M30.ulsZel_C1qz2BvTxgSoZNiuDBPNC-a8UP42_aAYXvqc';
const supabase = createClient(supabaseUrl, supabaseKey);

async function run() {
  // First, we need to sign in to get a valid JWT. The user might have a generic test account.
  // Or we can just use the admin token if we know it. But we don't know the password.
  // Let's just make a raw POST request with fetch, omitting the auth token, and see if it fails at the auth check.
  // Wait, if we omit auth, it returns 401. We need the 500 error!
  
  // To get the 500 error, we need a valid JWT. We can create a temporary user.
  const { data: authData, error: authError } = await supabase.auth.signUp({
    email: 'test' + Math.random() + '@example.com',
    password: 'password123'
  });
  
  if (authError) {
    console.log('Auth error:', authError);
    return;
  }
  
  const token = authData.session.access_token;
  
  const response = await fetch(supabaseUrl + '/functions/v1/notify-class-change', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer ' + token
    },
    body: JSON.stringify({
      timetable_id: 'a2344d9d-0553-4c40-a0e8-5446c73175af', // from screenshot
      period_id: 'test_period_123',
      old_data: { room: '101' },
      new_data: { room: '102' },
      change_type: 'VENUE_CHANGED',
      subject_name: 'Test'
    })
  });
  
  const result = await response.text();
  console.log('Status:', response.status);
  console.log('Result:', result);
}
run();
