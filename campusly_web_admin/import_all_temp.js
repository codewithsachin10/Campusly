import { createClient } from '@supabase/supabase-js';
import fs from 'fs';
import path from 'path';

const SUPABASE_URL = 'https://jvrxoyswzjuhsofqnqym.supabase.co';
const SUPABASE_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imp2cnhveXN3emp1aHNvZnFucXltIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc4NTkyNTc0MywiZXhwIjoyMTAxNTAxNzQzfQ.nDsObF4X4hqhCVoI_1NuhATzRp9b7lO5cn7LNSouxqc';

const supabase = createClient(SUPABASE_URL, SUPABASE_KEY);

const JSON_DIR = '/Users/sachingopalakrishnan/CAMPUSLY(TimeTable App) /json_output/';

const FILE_MAPPING = {
  "B.Tech IT - R 2023 Curriculum & Syllabus.json": "IT",
  "BE EEE Curriculum and Syllabus R2023.json": "EEE",
  "CSBS R2023 Curriculum and Syllabus Updated - From 2024-2028 Batch.json": "CSBS",
  "R2023 (2026-2030 batch) Final.json": "ECE",
  "R2023 CSD Syllabus.json": "CSD",
  "R2023 Mech -For 2023 Batch (16.7.26).json": "MECH",
  "R2023-Aero-Curriculum_and_Syllabus.json": "AERO",
  "R2023-BME-Curriculum_and_Syllabus.json": "BME",
  "R2023-BT-Curriculum_and_Syllabus.json": "BT",
  "R2023-CSE-CS-Curriculum_and_Syllabus.json": "CYS",
  "R2023-CSE-Curriculum_and_SyllabusB2026.json": "CSE",
  "R2023-Chem-Curriculum_and_Syllabus.json": "CHEM",
  "R2023-Civil-Curriculum_and_Syllabus.json": "CIVIL",
  "R2023-FT-Curriculum_and_Syllabus.json": "FT",
  "R2023-RA-Curriculum_and_Syllabus.json": "RA",
  "R2023_B.E_AUTO_Curricullum_Syllabus.json": "AUTO",
  "R2023_B.Tech_Artificial Intelligence and Machine Learning_UG(2026).json": "AIML",
  "Revised BTech AI&DS R2023 Curr and Syll - Batch 26.json": "AIDS"
};

async function run() {
  console.log("Starting bulk import...");
  
  // Clear old data first so we don't duplicate
  console.log("Clearing old curriculum data...");
  const { error: clearError } = await supabase.from('academic_regulations').delete().neq('id', '00000000-0000-0000-0000-000000000000');
  if (clearError) {
    console.error("Failed to clear old data:", clearError);
    return;
  }
  
  // Get all departments
  const { data: departments, error: deptError } = await supabase.from('departments').select('id, code');
  if (deptError) throw deptError;
  
  const deptMap = {};
  departments.forEach(d => { deptMap[d.code] = d.id; });
  
  const files = fs.readdirSync(JSON_DIR);
  
  for (const file of files) {
    if (!file.endsWith('.json')) continue;
    
    const deptCode = FILE_MAPPING[file];
    if (!deptCode) {
      console.log(`Skipping ${file} (No mapped department code)`);
      continue;
    }
    
    const deptId = deptMap[deptCode];
    if (!deptId) {
      console.log(`Skipping ${file} (Department ID not found for code ${deptCode})`);
      continue;
    }
    
    console.log(`Processing ${file} for department ${deptCode}...`);
    const filePath = path.join(JSON_DIR, file);
    const content = fs.readFileSync(filePath, 'utf-8');
    let data;
    try {
      data = JSON.parse(content);
    } catch(e) {
      console.error(`Failed to parse ${file}`);
      continue;
    }
    
    // 1. Insert Regulation
    const { data: reg, error: regError } = await supabase
      .from('academic_regulations')
      .insert({
        department_id: deptId,
        name: data.regulation.name,
        regulation_year: Number(data.regulation.regulation_year) || 2023,
        batch: data.regulation.batch || "2024-2028",
        effective_academic_year: data.regulation.effective_academic_year || "2024-2025",
        status: 'active'
      })
      .select('id')
      .single();
      
    if (regError) {
      console.error(`Error inserting regulation for ${file}:`, regError);
      continue;
    }
    
    const regId = reg.id;
    
    // 2. Insert Semesters & Subjects
    for (const sem of data.semesters) {
      const { data: semesterRow, error: semError } = await supabase
        .from('academic_semesters')
        .insert({
          regulation_id: regId,
          semester_number: Number(sem.semester_number)
        })
        .select('id')
        .single();
        
      if (semError) {
        console.error(`Error inserting semester ${sem.semester_number} for ${file}:`, semError);
        continue;
      }
      
      const semId = semesterRow.id;
      
      // Filter out duplicate subject_codes within the same semester
      const seenCodes = new Set();
      const subjectsToInsert = [];
      
      for (const sub of (sem.subjects || [])) {
        if (!sub.subject_code || seenCodes.has(sub.subject_code)) continue;
        seenCodes.add(sub.subject_code);
        
        subjectsToInsert.push({
          semester_id: semId,
          subject_code: sub.subject_code,
          name: sub.name,
          credits: Number(sub.credits) || 0,
          course_type: sub.course_type || "Theory",
          l_t_p: sub.l_t_p || "0-0-0",
          theory_lab: sub.theory_lab || "Theory",
          category: sub.category || "PC"
        });
      }
      
      if (subjectsToInsert.length > 0) {
        const { error: subError } = await supabase
          .from('curriculum_subjects')
          .insert(subjectsToInsert);
          
        if (subError) {
          console.error(`Error inserting subjects for semester ${sem.semester_number} in ${file}:`, subError);
        }
      }
    }
    console.log(`Successfully imported ${file}`);
  }
  
  console.log("All done!");
}

run().catch(console.error);
