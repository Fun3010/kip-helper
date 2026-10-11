"""Render Rosemount 8600D figures from the verified manufacturer manual, revision BD, October 2016."""
import argparse
import hashlib
import json
from pathlib import Path
import fitz

SOURCE_SHA = '1ec893f8b586b4ec4a25a5f14b0b44e1f13ad36e11d46f80609e666fc5b80fd7'
SOURCE_URL = 'https://mirkip.ru/wp-content/uploads/rukovodstvo-po-ekspluataczii-rashodomer-vihrevoj-8600d-ru-ru-5220322.pdf'
FIGURES = [
    ('rosemount8600d-placement', '3-4', 33, 25, (150, 215, 543, 595)),
    ('rosemount8600d-analog', '3-14', 46, 38, (69, 185, 543, 405)),
    ('rosemount8600d-pulse', '3-15', 46, 38, (69, 437, 543, 663)),
]

def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--source', type=Path, required=True)
    parser.add_argument('--output-root', type=Path, default=Path(__file__).resolve().parents[1])
    args = parser.parse_args()
    actual = hashlib.sha256(args.source.read_bytes()).hexdigest()
    if actual != SOURCE_SHA:
        parser.error(f'SHA-256 mismatch: {actual}')
    root = args.output_root
    manifest_path = root / 'docs/illustration-sources.json'
    previous = manifest_path.read_bytes() if manifest_path.exists() else b'[]'
    own = {f'assets/illustrations/{name}.png' for name, *_ in FIGURES}
    manifest = [item for item in json.loads(previous) if item['asset'] not in own]
    (root / 'assets/illustrations').mkdir(parents=True, exist_ok=True)
    with fitz.open(args.source) as doc:
        for name, figure, page, printed, rect in FIGURES:
            asset = f'assets/illustrations/{name}.png'
            doc[page - 1].get_pixmap(matrix=fitz.Matrix(3, 3), clip=fitz.Rect(*rect), alpha=False).save(root / asset)
            manifest.append(dict(asset=asset, document='Rosemount 8600D, 00809-0107-4860, BD, 10/2016', source_url=SOURCE_URL, pdf_page=page, printed_page=printed, figure=figure, crop_points=rect, source_sha256=SOURCE_SHA, asset_sha256=hashlib.sha256((root / asset).read_bytes()).hexdigest(), method='PDF region rendered at 216 dpi; no redrawing'))
    manifest_path.parent.mkdir(parents=True, exist_ok=True)
    content = json.dumps(manifest, ensure_ascii=False, indent=2) + '\n'
    if b'\r\n' in previous:
        content = content.replace('\n', '\r\n')
    manifest_path.write_bytes(content.encode('utf-8'))

if __name__ == '__main__':
    main()
