import { createClient } from "@supabase/supabase-js";
import * as dotenv from "dotenv";
dotenv.config();

const supabase = createClient(
  process.env.VITE_SUPABASE_URL!,
  process.env.VITE_SUPABASE_ANON_KEY!
);

async function check() {
  const { data, error } = await supabase.from("departments").select("*").limit(1);
  if (error) {
    console.error("Error fetching departments:", error);
  } else {
    console.log("Departments data:", data);
  }

  const { data: d2, error: e2 } = await supabase.from("sections").select("*").limit(1);
  if (e2) {
    console.error("Error fetching sections:", e2);
  } else {
    console.log("Sections data:", d2);
  }
}

check();
