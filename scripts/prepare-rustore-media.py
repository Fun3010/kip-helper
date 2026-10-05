"""Package reviewed UI screenshots and render the existing Android vector icon."""
from pathlib import Path
import shutil
import sys
import xml.etree.ElementTree as ET

root = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(root / 'tmp/pdf-tools'))
import pymupdf

out = root / 'dist/rustore'
out.mkdir(parents=True, exist_ok=True)
android = '{http://schemas.android.com/apk/res/android}'
vector = ET.parse(root / 'android/app/src/main/res/mipmap-anydpi/ic_kip.xml').getroot()
svg = ET.Element('svg', xmlns='http://www.w3.org/2000/svg', width='512', height='512',
                 viewBox='0 0 108 108')
for path in vector:
    fill = path.get(android + 'fillColor', '#000000')
    if fill == '#00000000':
        fill = 'none'
    attrs = {'d': path.get(android + 'pathData'), 'fill': fill}
    for source, target in [('strokeColor', 'stroke'), ('strokeWidth', 'stroke-width'),
                           ('strokeLineCap', 'stroke-linecap')]:
        value = path.get(android + source)
        if value is not None:
            attrs[target] = value
    ET.SubElement(svg, 'path', attrs)
with pymupdf.open(stream=ET.tostring(svg), filetype='svg') as source:
    with pymupdf.open('pdf', source.convert_to_pdf()) as pdf:
        pdf[0].get_pixmap(alpha=False).save(out / 'icon-512.png')
for index, name in enumerate(['library', 'library-dark', 'calculators'], 1):
    shutil.copyfile(root / f'build/qa/{name}.png', out / f'{index:02}-{name}.png')
shutil.copyfile(root / 'docs/store-listing.md', out / 'store-listing.md')
print('RuStore media prepared in dist/rustore; no private signing files copied.')
