import os
import re
import json

TXT_DIR = "/Users/sachingopalakrishnan/CAMPUSLY(TimeTable App) /json_output/txt"
JSON_DIR = "/Users/sachingopalakrishnan/CAMPUSLY(TimeTable App) /json_output"

ROMAN_MAP = {"I": 1, "II": 2, "III": 3, "IV": 4, "V": 5, "VI": 6, "VII": 7, "VIII": 8}
CAT_TYPE_MAP = {
    "HS": "Humanities and Social Sciences",
    "HSMC": "Humanities and Social Sciences",
    "BS": "Basic Sciences",
    "ES": "Engineering Sciences",
    "PC": "Professional Core",
    "PE": "Professional Elective",
    "OE": "Open Elective",
    "EEC": "Employability Enhancement Course",
    "MC": "Mandatory Course",
    "MS": "Management Sciences"
}

def clean_text(raw_text):
    text = raw_text.replace('\xa0', ' ').replace('–', '-').replace('—', '-').replace('‟', "'").replace('„', "'")
    return text

def parse_semester_block(text, sem_num):
    # Matches codes like HS23112, MA23115, EE23131, CB23131, Open Elective I
    code_pattern = re.compile(
        r'\b([A-Z]{2}\s*\d{5}|[A-Z]{2}\s*\d{2}[A-Z]\d{2}|[A-Z]{2}\s*\d{3,4}[A-Z0-9]*|Open Elective[^\n]*|Professional Elective[^\n]*|Soft Skills[^\n]*|Project Phase[^\n]*|Project Work[^\n]*|Industry Internship[^\n]*|Internship[^\n]*|Value Added Program[^\n]*)\b',
        re.IGNORECASE
    )
    
    matches = list(code_pattern.finditer(text))
    subjects = []
    seen_codes = set()
    
    for i, match in enumerate(matches):
        start = match.start()
        end = matches[i+1].start() if i+1 < len(matches) else len(text)
        block = text[start:end].strip()
        
        code = match.group(1).strip()
        if len(code) > 25: 
            code = code[:25].strip()
            
        code_nospace = code.replace(' ', '')
        if code_nospace in seen_codes:
            continue
        
        # Stop processing block if it hits TOTAL (sometimes TOTAL gets bundled in the last subject)
        block = re.split(r'\bTOTAL\b', block, flags=re.IGNORECASE)[0].strip()
        
        # Because we split exactly at the subject code, the list number for the NEXT subject (e.g. "4. ")
        # ends up at the very end of our current block. We must strip it so it isn't parsed as credits!
        block = re.sub(r'\s*\d+\.\s*$', '', block).strip()
        
        # Find L T P C
        nums = re.findall(r'\b\d+\b', block)
        if not nums:
            continue
            
        credits = int(nums[-1])
        if credits > 10: # Sanity check to avoid TOTAL rows
            continue
            
        if len(nums) >= 4:
            l, t, p = nums[-4], nums[-3], nums[-2]
        elif len(nums) == 3:
            l, t, p = nums[-3], nums[-2], "0"
        else:
            l, t, p = "3", "0", "0"
            
        ltp = f"{l}-{t}-{p}"
        
        cat_match = re.search(r'\b(HS|BS|ES|PC|PE|OE|EEC|MC|HSMC|MS)\b', block)
        category = cat_match.group(1) if cat_match else "PC"
        
        # Extract name
        name = block.replace(code, '', 1)
        if cat_match:
            name = name.replace(cat_match.group(0), '', 1)
            
        # Strip everything down to single spaces
        name = re.sub(r'\s+', ' ', name).strip()
        
        # Aggressive trailing number stripping
        name = re.sub(r'([\s\.,-]*\d+)+[\s\.,-]*$', '', name).strip()
        
        # Remove noisy headers
        name = re.sub(r'\b(CONTACT\s+PERIODS\s+L\s+T\s+P\s+C|L\s+T\s+P\s+C|PERIODS|CREDIT[S]?|Sl\.No\.|COURSE CODE|COURSE TITLE|CATEGORY|THEORY COURSES|LAB ORIENTED THEORY COURSES|LABORATORY COURSES|MANDATORY COURSES|EMPLOYABILITY ENHANCEMENT COURSES|NON-CREDIT COURSES)\b', '', name, flags=re.IGNORECASE)
        
        # After removing headers, we might have exposed trailing numbers again!
        name = re.sub(r'([\s\.,-]*\d+)+[\s\.,-]*$', '', name).strip()
        
        name = re.sub(r'^[-\.\s\|]+', '', name)
        name = re.sub(r'[-\.\s\|]+$', '', name)
        name = re.sub(r'\s+', ' ', name).strip()
        
        if len(name) < 2:
            name = code
            
        try:
            p_val = int(p)
            l_val = int(l)
            theory_lab = "Lab Integrated / Embedded" if (p_val > 0 and l_val > 0) else ("Laboratory" if p_val > 0 else "Theory")
        except:
            theory_lab = "Theory"
            
        detected_sem = sem_num
        code_digit_match = re.search(r'^[A-Z]{2}\s*23([1-8])', code_nospace, re.IGNORECASE)
        if code_digit_match:
            detected_sem = int(code_digit_match.group(1))
            
        subjects.append({
            "subject": {
                "subject_code": code_nospace,
                "name": name,
                "credits": credits,
                "course_type": CAT_TYPE_MAP.get(category, "Professional Core"),
                "l_t_p": ltp,
                "theory_lab": theory_lab,
                "category": category
            },
            "sem": detected_sem
        })
        seen_codes.add(code_nospace)
        
    return subjects


def parse_file(filename):
    filepath = os.path.join(TXT_DIR, filename)
    with open(filepath, 'r', encoding='utf-8') as f:
        text = clean_text(f.read())

    dept_name = filename.replace('.txt', '')
    prog_match = re.search(r'(B\.E\.|B\.Tech\.)\s+([A-Z\s\(\)&,-]+)', text[:2500], re.IGNORECASE)
    if prog_match:
        extracted = f"{prog_match.group(1)} {prog_match.group(2).strip()}"
        extracted = re.sub(r'\s+', ' ', extracted).strip()
        extracted = re.sub(r'(Regulation|Total|Credits|Page).*$', '', extracted, flags=re.IGNORECASE).strip()
        if 5 < len(extracted) < 80:
            dept_name = extracted

    reg_year = 2023
    reg_match = re.search(r'Regulation[s]?\s*[:–-]?\s*(20\d\d)', text[:3000], re.IGNORECASE)
    if reg_match:
        reg_year = int(reg_match.group(1))

    batch = "2024-2028"
    if "2026" in filename:
        batch = "2026-2030"

    regulation_info = {
        "name": dept_name,
        "regulation_year": reg_year,
        "batch": batch,
        "effective_academic_year": f"{reg_year}-{reg_year+1}"
    }

    # Split text into semesters
    semesters_out = []
    # Regex to find SEMESTER I, SEMESTER II, etc.
    sem_splits = list(re.finditer(r'^\s*SEMESTER\s*[-–]?\s*([I|V|X]+|\d+)\b', text, re.IGNORECASE | re.MULTILINE))
    
    # If no standard SEMESTER headers, fallback to basic search
    if not sem_splits:
        sem_splits = list(re.finditer(r'\bSEMESTER\s*([I|V|X]+|\d+)\b', text, re.IGNORECASE))
        
    for i, match in enumerate(sem_splits):
        sem_str = match.group(1).upper()
        sem_num = ROMAN_MAP.get(sem_str)
        if not sem_num and sem_str.isdigit():
            sem_num = int(sem_str)
            
        if not sem_num or not (1 <= sem_num <= 8):
            continue
            
        start = match.end()
        end = sem_splits[i+1].start() if i+1 < len(sem_splits) else len(text)
        
        sem_block = text[start:end]
        
        # Stop semester block if it hits LIST OF ELECTIVES or similar
        end_match = re.search(r'(PROFESSIONAL ELECTIVES|LIST OF PROFESSIONAL ELECTIVES|SUMMARY OF CREDITS|CREDIT DISTRIBUTION|SUMMARY OF ALL COURSES)', sem_block, re.IGNORECASE)
        if end_match:
            sem_block = sem_block[:end_match.start()]
            
        subjects_with_sem = parse_semester_block(sem_block, sem_num)
        
        for item in subjects_with_sem:
            sub = item["subject"]
            target_sem = item["sem"]
            
            existing_sem = next((s for s in semesters_out if s["semester_number"] == target_sem), None)
            if existing_sem:
                if not any(s["subject_code"] == sub["subject_code"] for s in existing_sem["subjects"]):
                    existing_sem["subjects"].append(sub)
            else:
                semesters_out.append({
                    "semester_number": target_sem,
                    "subjects": [sub]
                })

    # Sort semesters
    semesters_out.sort(key=lambda x: x["semester_number"])

    return {
        "regulation": regulation_info,
        "semesters": semesters_out
    }

if __name__ == "__main__":
    if not os.path.exists(JSON_DIR):
        os.makedirs(JSON_DIR)
        
    for fname in sorted(os.listdir(TXT_DIR)):
        if fname.endswith('.txt'):
            out_name = fname.replace('.txt', '.json')
            out_path = os.path.join(JSON_DIR, out_name)
            data = parse_file(fname)
            with open(out_path, 'w', encoding='utf-8') as out_f:
                json.dump(data, out_f, indent=2, ensure_ascii=False)
            counts = [len(s['subjects']) for s in data['semesters']]
            print(f"{out_name[:45]:<45} | Total: {sum(counts):<3} | Sems: {counts}")
