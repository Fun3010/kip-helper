"""Render verified Siemens figures; source PDFs remain outside the repository."""
from pathlib import Path
import argparse
import hashlib
import json

import fitz

ROOT = Path(__file__).resolve().parents[1]
COMPACT_URL = 'https://cache.industry.siemens.com/dl/files/665/109972665/att_1291485/v1/A5E03436620en_PS2_COI_en-US.pdf'
FULL_URL = 'https://cache.industry.siemens.com/dl/files/419/109782419/att_1034214/v1/A5E00074631-AFen_PS2HART_OI_en-US.pdf'
SOURCES = {
    'compact': ('A5E03436620en_PS2_COI_en-US.pdf',
                '6c44ebfbdb021d1d12e87cd1dfbb70638a61e40adf9b7868cd93ac1efe4b712b', COMPACT_URL),
    'full': ('A5E00074631-AFen_PS2HART_OI_en-US.pdf',
             '8b864ad7f10416a93aa38d6f88ec3fc66838376b33b37af0ac07cc547b66c18f', FULL_URL),
}
FIGURES = [
    ('sipart-controls', 'full', 28, '3-6', (125, 155, 480, 379)),
    ('sipart-pneumatic-standard', 'compact', 47, '4-12', (138, 440, 282, 578)),
    ('sipart-pneumatic-flameproof', 'compact', 48, '4-13', (125, 160, 292, 323)),
]


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--compact', type=Path, required=True)
    parser.add_argument('--full', type=Path, required=True)
    parser.add_argument('--output-root', type=Path, default=ROOT)
    args = parser.parse_args()
    paths = {'compact': args.compact, 'full': args.full}
    # Verify every input before creating or overwriting any output.
    for kind, path in paths.items():
        actual = hashlib.sha256(path.read_bytes()).hexdigest()
        if actual != SOURCES[kind][1]:
            raise ValueError(f'{kind}: source SHA-256 mismatch: {actual}')
    output = args.output_root / 'assets/illustrations'
    manifest_path = args.output_root / 'docs/illustration-sources.json'
    existing = manifest_path.read_bytes() if manifest_path.exists() else b'[]'
    manifest = json.loads(existing)
    names = {f'assets/illustrations/{name}.png' for name, *_ in FIGURES}
    manifest = [entry for entry in manifest if entry['asset'] not in names]
    output.mkdir(parents=True, exist_ok=True)
    for name, kind, page, figure, region in FIGURES:
        target = output / f'{name}.png'
        with fitz.open(paths[kind]) as document:
            document[page - 1].get_pixmap(
                matrix=fitz.Matrix(3, 3), clip=fitz.Rect(region), alpha=False,
            ).save(target)
        filename, source_hash, url = SOURCES[kind]
        manifest.append({
            'asset': f'assets/illustrations/{name}.png',
            'document': filename,
            'source_url': url,
            'pdf_page': page,
            'printed_page': page,
            'figure': figure,
            'crop_points': region,
            'source_sha256': source_hash,
            'asset_sha256': hashlib.sha256(target.read_bytes()).hexdigest(),
            'method': 'PDF region rendered at 216 dpi; no redrawing',
        })
    manifest_path.parent.mkdir(parents=True, exist_ok=True)
    newline = '\r\n' if b'\r\n' in existing else '\n'
    text = json.dumps(manifest, ensure_ascii=False, indent=2) + '\n'
    manifest_path.write_bytes(text.replace('\n', newline).encode('utf-8'))


if __name__ == '__main__':
    main()
