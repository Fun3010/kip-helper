"""Render original OPTIFLEX 1300C figures from the supplied RU 08/2005 manual.

Requires PyMuPDF (verified with 1.26.6). Original PDFs are not added to git.
"""
import argparse
import hashlib
import json
from pathlib import Path

import fitz

SOURCE_SHA = 'c50821cdf7d9a868bc3543ce02b10857731e90f4948299afc68d490ecb407463'
SOURCE_DOCUMENT = 'KROHNE_OPTIFLEX_1300C_руководство_по_монтажу_и_эксплуатации_2005.pdf'
DOCUMENT_TITLE = 'OPTIFLEX 1300C, KROHNE 7.02534.11.00 RU, 08/2005'
FIGURES = [
    ('optiflex1300c-nozzle', '2.2.1.4, unnumbered nozzle illustration', 14, 14, (130, 385, 425, 535)),
    ('optiflex1300c-hart-ptp', '3.3.2, unnumbered point-to-point diagram', 35, 35, (56, 575, 543, 783)),
]


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--source', type=Path, required=True)
    parser.add_argument('--output-root', type=Path, default=Path(__file__).resolve().parents[1])
    args = parser.parse_args()
    actual = hashlib.sha256(args.source.read_bytes()).hexdigest()
    if actual != SOURCE_SHA:
        parser.error(f'SHA-256 mismatch: {actual}')
    with fitz.open(args.source) as doc:
        if len(doc) != 97:
            parser.error(f'Expected 97 PDF pages, got {len(doc)}')
        root = args.output_root
        manifest_path = root / 'docs/illustration-sources.json'
        previous = manifest_path.read_bytes() if manifest_path.exists() else b'[]'
        own = {f'assets/illustrations/{name}.png' for name, *_ in FIGURES}
        manifest = [item for item in json.loads(previous) if item['asset'] not in own]
        (root / 'assets/illustrations').mkdir(parents=True, exist_ok=True)
        for name, figure, page, printed, rect in FIGURES:
            asset = f'assets/illustrations/{name}.png'
            doc[page - 1].get_pixmap(matrix=fitz.Matrix(3, 3), clip=fitz.Rect(*rect), alpha=False).save(root / asset)
            manifest.append(dict(asset=asset, document=DOCUMENT_TITLE, document_path=SOURCE_DOCUMENT, pdf_page=page, printed_page=printed, figure=figure, crop_points=rect, source_sha256=SOURCE_SHA, asset_sha256=hashlib.sha256((root / asset).read_bytes()).hexdigest(), method='PDF region rendered at 216 dpi; no redrawing'))
        manifest_path.parent.mkdir(parents=True, exist_ok=True)
        content = json.dumps(manifest, ensure_ascii=False, indent=2) + '\n'
        if b'\r\n' in previous:
            content = content.replace('\n', '\r\n')
        manifest_path.write_bytes(content.encode('utf-8'))


if __name__ == '__main__':
    main()
