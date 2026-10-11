"""Render Metran-150 wiring from the verified manufacturer manual, version 4.23."""
import argparse
import hashlib
import json
from pathlib import Path
import fitz

SOURCE_SHA = '8fdaa068e0441171c30ea1fe8671e0c9c06c0589ddc1d36fd4e3dee6c949e721'
SOURCE_URL = 'https://metran.ru/upload/iblock/794/0iy0f9l4wu0yx9eykbyaxat1j9ddpqh0.pdf'
FIGURES = [
    ('metran150-current-0-5', 'Г.1', (135, 155, 515, 365)),
    ('metran150-current-4-20', 'Г.2', (135, 412, 515, 625)),
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
    own = {f'assets/illustrations/{name}.png' for name, _, _ in FIGURES}
    manifest = [item for item in json.loads(previous) if item['asset'] not in own]
    (root / 'assets/illustrations').mkdir(parents=True, exist_ok=True)
    with fitz.open(args.source) as doc:
        for name, figure, rect in FIGURES:
            asset = f'assets/illustrations/{name}.png'
            doc[88].get_pixmap(matrix=fitz.Matrix(3, 3), clip=fitz.Rect(*rect), alpha=False).save(root / asset)
            manifest.append(dict(asset=asset, document='Метран-150, СПГК.5225.000.00 РЭ, версия 4.23', source_url=SOURCE_URL, pdf_page=89, printed_page=89, figure=figure, crop_points=rect, source_sha256=SOURCE_SHA, asset_sha256=hashlib.sha256((root / asset).read_bytes()).hexdigest(), method='PDF region rendered at 216 dpi; no redrawing'))
    manifest_path.parent.mkdir(parents=True, exist_ok=True)
    content = json.dumps(manifest, ensure_ascii=False, indent=2) + '\n'
    if b'\r\n' in previous:
        content = content.replace('\n', '\r\n')
    manifest_path.write_bytes(content.encode('utf-8'))

if __name__ == '__main__':
    main()
