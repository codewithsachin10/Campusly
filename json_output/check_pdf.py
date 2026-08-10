import subprocess, os, importlib

# Check if we have any PDF reading capability
for mod in ['pypdf', 'PyPDF2', 'fitz', 'pdfplumber', 'pdfminer', 'pdfminer.high_level', 'Quartz', 'objc']:
    try:
        importlib.import_module(mod)
        print(f"{mod} available")
    except:
        print(f"{mod} NOT available")

print("Done checking")
