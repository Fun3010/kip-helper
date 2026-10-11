"""Render Metran-100 wiring from the verified manufacturer manual, version 2.4, 2007."""
import argparse
import hashlib
import json
from pathlib import Path
import fitz

SOURCE_SHA = '6e95bc02be72e6fd45bf192039a1223dcc1d872970889c7a2919a0bee28bcfc5'
SOURCE_URL = 'https://xn--90ahjlpcccjdm.xn--p1ai/wp-content/uploads/2021/05/Metran-100-RE-Rukovodstvo-po-ekspluatatsii.pdf'
FIGURES = [
    ('metran100-current-0-5-0-20', 'В.1', 87, 88, (48, 109, 370, 259)),
    ('metran100-current-4-20', 'В.2', 87, 88, (48, 275, 370, 396)),
    ('metran100-hart-mp2-mp3', 'В.4', 88, 89, (35, 68, 385, 235)),
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
            manifest.append(dict(asset=asset, document='Метран-100, СПГК.5070.000.00-01 РЭ, версия 2.4, 2007', source_url=SOURCE_URL, pdf_page=page, printed_page=printed, figure=figure, crop_points=rect, source_sha256=SOURCE_SHA, asset_sha256=hashlib.sha256((root / asset).read_bytes()).hexdigest(), method='PDF region rendered at 216 dpi; no redrawing'))
    manifest_path.parent.mkdir(parents=True, exist_ok=True)
    content = json.dumps(manifest, ensure_ascii=False, indent=2) + '\n'
    if b'\r\n' in previous:
        content = content.replace('\n', '\r\n')
    manifest_path.write_bytes(content.encode('utf-8'))

if __name__ == '__main__':
    main()
