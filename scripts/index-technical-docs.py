"""Index supplied PDFs; keep originals untouched. Requires pypdf and PyMuPDF.

Run: python scripts/index-technical-docs.py
Local dependencies can be installed in tmp/pdf-tools.
"""
from pathlib import Path
import hashlib
import json
import logging
import sys

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / 'tmp/pdf-tools'))
from pypdf import PdfReader
import pymupdf

logging.getLogger('pypdf').setLevel(logging.ERROR)

out = ROOT / 'tmp/pdfs'
out.mkdir(parents=True, exist_ok=True)
records = []
for source in sorted((ROOT / 'docs/Оборудование').rglob('*.pdf')):
    reader = PdfReader(source)
    pages = [page.extract_text() or '' for page in reader.pages]
    (out / (source.stem + '.txt')).write_text(
        '\n\n'.join(f'=== PDF PAGE {i + 1} ===\n{text}' for i, text in enumerate(pages)),
        encoding='utf-8',
    )
    record = dict(file=source.name, path=source.relative_to(ROOT).as_posix(), pages=len(pages),
                  sha256=hashlib.sha256(source.read_bytes()).hexdigest(),
                  text_characters=sum(map(len, pages)),
                  needs_ocr=not any(text.strip() for text in pages))
    records.append(record)
    with pymupdf.open(source) as doc:
        doc[0].get_pixmap(matrix=pymupdf.Matrix(1, 1)).save(out / (source.stem + '.png'))
    print(json.dumps(record, ensure_ascii=True))
(out / 'inventory.json').write_text(json.dumps(records, ensure_ascii=False, indent=2), encoding='utf-8')
