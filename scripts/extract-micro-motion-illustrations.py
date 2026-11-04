"""Render original Micro Motion 1700/2700 installation figures, Rev CA 01/2012.

Requires PyMuPDF (verified with 1.26.6). This is not the 1000/2000 PN20001715 manual.
"""
import argparse
import hashlib
import json
from pathlib import Path

import fitz

SOURCE_SHA = '786bf06f67ec4e2e6194926709ba59fc2b60b043071c155125f3cb2cc8603335'
SOURCE_DOCUMENT = 'Micro_motion.pdf'
DOCUMENT_TITLE = 'Micro Motion 1700/2700, installation MMI-20021325, Rev CA, 01/2012'
FIGURES = [
    ('micro-motion-model-code', '1-7 and tables 1-2/1-3', 10, 6, (141, 182, 534, 601)),
    ('micro-motion-sensor-4-wire', '3-7, aluminum housing, 4-wire remote installation', 25, 21, (167, 94, 535, 500)),
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
        if len(doc) != 117:
            parser.error(f'Expected 117 PDF pages, got {len(doc)}')
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
