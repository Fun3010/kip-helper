"""Extract exact verified SU-1S/STM-10 PDF regions; originals stay outside git."""
import argparse
import hashlib
import json
from pathlib import Path
import fitz

SOURCES = {
    'su1s': ('РГАУ.407834.006 РЭ, 2014', 'https://kip-device.ru/f/re_su-1s_201411_a.pdf', '4c8db5f3c569dbab554c256b4905197c503fa0b8202bd9eca5b0d3537d3402db'),
    'stm10': ('АПИ2.840.069 РЭ, скан без даты редакции', 'https://www.analitpribor-smolensk.ru/files/rukovodstva/2015/ctm-10/stm-10_api2_840_069_re.pdf', 'a4b5f9e0cd898dc59fa7ae40980ce6352df0924cf0585fdc40f4a97fc655bf85'),
}
FIGURES = [
    ('su1s-connections', 'su1s', 27, 27, 'Приложение А', (120, 140, 565, 745), 0),
    ('su1s-contacts', 'su1s', 38, 38, 'Приложение Л', (80, 40, 560, 745), 270),
    ('stm10-cable-fixed', 'stm10', 19, 18, 'Рисунок 1.1', (80, 65, 550, 360), 0),
    ('stm10-cable-plug', 'stm10', 19, 18, 'Рисунок 1.2', (80, 380, 550, 685), 0),
]

def main():
    parser = argparse.ArgumentParser(description=__doc__)
    for key in SOURCES:
        parser.add_argument('--' + key, type=Path, required=True)
    parser.add_argument('--output-root', type=Path, default=Path(__file__).resolve().parents[1])
    args = parser.parse_args()
    for key, (_, _, expected) in SOURCES.items():
        actual = hashlib.sha256(getattr(args, key).read_bytes()).hexdigest()
        if actual != expected:
            parser.error(f'{key}: SHA-256 mismatch: {actual}')
    root = args.output_root
    path = root / 'docs/illustration-sources.json'
    previous = path.read_bytes() if path.exists() else b'[]'
    own = {f'assets/illustrations/{item[0]}.png' for item in FIGURES}
    manifest = [item for item in json.loads(previous) if item['asset'] not in own]
    out = root / 'assets/illustrations'
    out.mkdir(parents=True, exist_ok=True)
    for name, key, page, printed, figure, rect, rotation in FIGURES:
        asset = f'assets/illustrations/{name}.png'
        with fitz.open(getattr(args, key)) as doc:
            doc[page - 1].get_pixmap(matrix=fitz.Matrix(2, 2).prerotate(rotation), clip=fitz.Rect(*rect), alpha=False).save(root / asset)
        document, url, source_hash = SOURCES[key]
        manifest.append(dict(asset=asset, document=document, source_url=url, pdf_page=page, printed_page=printed, figure=figure, crop_points=rect, rotation_degrees=rotation, source_sha256=source_hash, asset_sha256=hashlib.sha256((root / asset).read_bytes()).hexdigest(), method='PDF region rendered at 144 dpi; no redrawing'))
    path.parent.mkdir(parents=True, exist_ok=True)
    content = json.dumps(manifest, ensure_ascii=False, indent=2) + '\n'
    if b'\r\n' in previous:
        content = content.replace('\n', '\r\n')
    path.write_bytes(content.encode('utf-8'))

if __name__ == '__main__':
    main()
