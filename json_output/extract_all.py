import pypdf
import os

pdf_dir = '/Users/sachingopalakrishnan/Downloads/ALL CURRICULUM OF REC'
out_dir = os.path.join(pdf_dir, 'json_output', 'txt')
os.makedirs(out_dir, exist_ok=True)

pdfs = [f for f in sorted(os.listdir(pdf_dir)) if f.endswith('.pdf')]
for pdf_file in pdfs:
    pdf_path = os.path.join(pdf_dir, pdf_file)
    print(f"Processing: {pdf_file}")
    try:
        reader = pypdf.PdfReader(pdf_path)
        print(f"  Pages: {len(reader.pages)}")
        text = ""
        for i in range(min(25, len(reader.pages))):
            page_text = reader.pages[i].extract_text()
            if page_text:
                text += f"\n--- PAGE {i+1} ---\n"
                text += page_text
        base = os.path.splitext(pdf_file)[0]
        out_path = os.path.join(out_dir, base + '.txt')
        with open(out_path, 'w', encoding='utf-8') as f:
            f.write(text)
        print(f"  Text length: {len(text)} chars")
    except Exception as e:
        print(f"  ERROR: {e}")

print("\nDone extracting all PDFs!")
