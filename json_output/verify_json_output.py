import os
import json

JSON_DIR = "/Users/sachingopalakrishnan/Downloads/ALL CURRICULUM OF REC/json_output"

valid_files = 0
total_files = 0

for fname in sorted(os.listdir(JSON_DIR)):
    if fname.endswith('.json'):
        total_files += 1
        fpath = os.path.join(JSON_DIR, fname)
        with open(fpath, 'r', encoding='utf-8') as f:
            data = json.load(f)

        # Validate schema keys
        assert "regulation" in data, f"Missing regulation in {fname}"
        assert "semesters" in data, f"Missing semesters in {fname}"
        
        reg = data["regulation"]
        assert "name" in reg and "regulation_year" in reg and "batch" in reg and "effective_academic_year" in reg, f"Invalid regulation keys in {fname}"
        
        sems = data["semesters"]
        assert len(sems) == 8, f"Semesters count not 8 in {fname}: got {len(sems)}"
        
        total_subs = 0
        for s in sems:
            assert "semester_number" in s and "subjects" in s, f"Invalid semester structure in {fname}"
            for sub in s["subjects"]:
                assert "subject_code" in sub, f"Missing subject_code in {fname}"
                assert "name" in sub, f"Missing name in {fname}"
                assert "credits" in sub, f"Missing credits in {fname}"
                assert "course_type" in sub, f"Missing course_type in {fname}"
                assert "l_t_p" in sub, f"Missing l_t_p in {fname}"
                assert "theory_lab" in sub, f"Missing theory_lab in {fname}"
                assert "category" in sub, f"Missing category in {fname}"
                total_subs += 1

        print(f"✅ {fname:<65} | Reg: {reg['name']} | Total Subjects: {total_subs}")
        valid_files += 1

print(f"\nSuccessfully verified {valid_files}/{total_files} JSON files.")
