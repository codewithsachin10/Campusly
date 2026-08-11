const { createClient } = require('@supabase/supabase-js');
const crypto = require('crypto');

async function seed() {
  const supabaseUrl = process.env.VITE_SUPABASE_URL;
  const supabaseServiceKey = process.env.SUPABASE_SERVICE_ROLE_KEY;

  if (!supabaseUrl || !supabaseServiceKey) {
    console.error("Missing env variables in .env");
    return;
  }

  const supabase = createClient(supabaseUrl, supabaseServiceKey);
  
  const formId = crypto.randomUUID();
  const formVersionId = crypto.randomUUID();
  
  // 1. Create Form
  console.log("Creating form...");
  await supabase.from("forms").insert([{
    id: formId,
    title: "Help Us Make Campusly Better!",
    description: "Your feedback helps us improve Campusly and build features you actually need. Takes less than 2 minutes. 💙",
    status: "published",
    created_at: new Date().toISOString(),
    published_at: new Date().toISOString()
  }]);

  // 2. Create Version
  console.log("Creating form version...");
  await supabase.from("form_versions").insert([{
    id: formVersionId,
    form_id: formId,
    version_number: 1,
    status: "published",
    created_at: new Date().toISOString(),
    published_at: new Date().toISOString()
  }]);

  // 3. Create Sections
  const section1Id = crypto.randomUUID();
  const section2Id = crypto.randomUUID();
  
  console.log("Creating sections...");
  await supabase.from("form_sections").insert([
    { id: section1Id, form_version_id: formVersionId, title: "Help Us Make Campusly Better!", display_order: 1 },
    { id: section2Id, form_version_id: formVersionId, title: "secction 2", display_order: 2 }
  ]);

  // Helper for options
  const createOptions = (questionId, labels) => {
    return labels.map((l, i) => ({
      id: crypto.randomUUID(),
      question_id: questionId,
      label: l,
      value: l,
      display_order: i + 1
    }));
  };

  // 4. Create Questions
  console.log("Creating questions...");
  const questions = [];
  const options = [];
  let displayOrder = 1;

  const addQ = (sectionId, type, title, req, extraRules = {}, opts = []) => {
    const qId = crypto.randomUUID();
    questions.push({
      id: qId,
      form_version_id: formVersionId,
      section_id: sectionId,
      type: type,
      title: title,
      required: req,
      display_order: displayOrder++,
      validation_rules: extraRules
    });
    if (opts.length > 0) {
      options.push(...createOptions(qId, opts));
    }
  };

  // Section 1 Questions
  addQ(section1Id, 'linear_scale', 'How would you rate Campusly overall?', true, { min: 1, max: 5 });
  addQ(section1Id, 'multiple_choice', 'How easy is Campusly to use?', true, {}, ['Very easy', 'Easy', 'Okay', 'Difficult']);
  addQ(section1Id, 'multiple_choice', 'Which Campusly feature do you use the most?', true, {}, ['Timetable', 'Curriculum', 'Attendance', 'Notifications', 'Forms', 'Other']);
  addQ(section1Id, 'short_text', 'What do you like most about Campusly?', false);
  addQ(section1Id, 'checkboxes', 'What should we improve?', true, {}, ['Design/UI', 'Performance', 'Timetable', 'Notifications', 'Curriculum', 'Attendance', 'Other']);
  addQ(section1Id, 'multiple_choice', 'What new feature would you like to see?', true, {}, ['AI features', 'Assignment tracker', 'Smart reminders', 'Campus navigation', 'Events & clubs', 'Attendance improvements', 'Other']);
  addQ(section1Id, 'multiple_choice', 'How should important college alerts be shown?', true, {}, ['Normal notification', 'Full-screen alert', 'Vibration + notification', 'Full-screen + vibration']);
  addQ(section1Id, 'checkboxes', 'What would you like to customize in Campusly?', true, {}, ['Home screen', 'Theme', 'Timetable', 'Notifications', 'Dashboard', 'Nothing / Keep it simple']);
  addQ(section1Id, 'short_text', 'If you could change one thing in Campusly, what would it be?', false);
  addQ(section1Id, 'linear_scale', 'Would you recommend Campusly to your friends?', true, { min: 0, max: 10 });
  
  // Section 2 Questions
  addQ(section2Id, 'email', 'enter your mail id', true);
  addQ(section2Id, 'description', 'Final message\n\n🎉 Thank you!\n\nYour feedback will help shape the future of Campusly. 🚀', false);

  await supabase.from("form_questions").insert(questions);
  if (options.length > 0) {
    await supabase.from("form_options").insert(options);
  }

  // 5. Create Public Link
  console.log("Creating public link...");
  const token = Math.random().toString(36).substring(2, 15) + Math.random().toString(36).substring(2, 15);
  await supabase.from("form_public_links").insert([{
    form_id: formId,
    form_version_id: formVersionId,
    public_token: token,
    active: true
  }]);

  console.log(`Success! Form Created.`);
  console.log(`Deep Link: http://localhost:5173/form/${token}`);
}

seed().catch(console.error);
