"""Render verified PDF regions without redrawing engineering content.

Coordinates are PDF points, page numbers are one-based. Originals are untouched.
Run with PyMuPDF installed (optionally in tmp/pdf-tools).
"""
from pathlib import Path
import hashlib
import json
import sys

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / 'tmp/pdf-tools'))
import pymupdf

items = [
    ('iva8-thumbnail', '2020-13560-11 ОТ ИВА-8.pdf', 2, (100, 190, 235, 300)),
    ('sokrat-thumbnail', 'Sokrat-RZ-N3_E32-SM.090.00.00.000-RE.pdf', 3, (435, 58, 634, 276)),
    ('iva8-overview', '2020-13560-11 ОТ ИВА-8.pdf', 2, (65, 185, 554, 391)),
    ('sokrat-overview', 'Sokrat-RZ-N3_E32-SM.090.00.00.000-RE.pdf', 3, (431, 53, 791, 546)),
    ('sokrat-controls', 'Sokrat-RZ-N3_E32-SM.090.00.00.000-RE.pdf', 31, (431, 128, 791, 544)),
    ('sokrat-current-loop', 'Sokrat-RZ-N3_E32-SM.090.00.00.000-RE.pdf', 22, (54, 52, 413, 356)),
]
out = ROOT / 'assets/illustrations'
out.mkdir(parents=True, exist_ok=True)
manifest = []
for name, filename, page, region in items:
    candidates = list((ROOT / 'docs/Оборудование').rglob(filename))
    if len(candidates) != 1:
        raise ValueError(f'Expected one source for {filename}: {candidates}')
    source = candidates[0]
    with pymupdf.open(source) as doc:
        doc[page - 1].get_pixmap(matrix=pymupdf.Matrix(3, 3),
                               clip=pymupdf.Rect(*region), alpha=False).save(out / (name + '.png'))
    manifest.append(dict(asset=f'assets/illustrations/{name}.png', document=filename, document_path=source.relative_to(ROOT).as_posix(),
                         pdf_page=page, crop_points=region,
                         source_sha256=hashlib.sha256(source.read_bytes()).hexdigest(),
                         method='PDF region rendered at 216 dpi; no redrawing'))
(ROOT / 'docs/illustration-sources.json').write_text(
    json.dumps(manifest, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
