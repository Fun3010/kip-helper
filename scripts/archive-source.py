"""Create a restorable source snapshot without credentials or build caches."""
from pathlib import Path
import hashlib
import json
import subprocess
import zipfile

root = Path(__file__).resolve().parents[1]
names = subprocess.check_output(
    ['git', 'ls-files', '-z', '--cached', '--others', '--exclude-standard'], cwd=root
).decode('utf-8').split('\0')
# Flutter ignores the wrapper binaries, but they are needed for restoration.
names += ['android/gradlew', 'android/gradlew.bat', 'android/gradle/wrapper/gradle-wrapper.jar']
files = []
for name in sorted(set(names)):
    p = root / name
    if not name or not p.is_file():
        continue
    if any(part in {'.git', '.private', '.dart_tool', 'build', 'tmp', 'dist', '.gradle', 'ephemeral'} for part in p.relative_to(root).parts):
        continue
    if p.name in {'key.properties', 'local.properties', 'keystore.properties'} or p.name.startswith('.env') or p.suffix in {'.jks', '.keystore', '.p12', '.pfx'}:
        continue
    if name.startswith('docs/') and p.suffix.lower() not in {'.md', '.json', '.csv', '.txt', '.pem'}:
        continue
    files.append(p)

out = root / 'dist/notion'
out.mkdir(parents=True, exist_ok=True)
archive = out / 'kip-helper-source-2026-10-02.zip'
manifest = {p.relative_to(root).as_posix(): hashlib.sha256(p.read_bytes()).hexdigest() for p in files}
restore = '''# Restore source snapshot

Snapshot of working files on 2026-10-02, including uncommitted changes.
Flutter 3.41.6 / Dart 3.11.4. Install Flutter and Android SDK, then:

    flutter pub get
    flutter analyze
    flutter test
    flutter run

For an APK without release credentials: flutter build apk --debug
For store updates restore the ORIGINAL release key and android/key.properties
from the owner's separate secure backup. Never generate a replacement key for
an existing store app. Release intentionally fails without signing credentials.

Includes code, platform projects, tests, bundled assets, scripts and text docs.
Excludes signing secrets, SDK paths, caches, Git history, APK, original PDFs and
equipment photos. Documentation extraction scripts require those PDFs separately.
SOURCE_MANIFEST.json records SHA-256 for every included project file.
'''
with zipfile.ZipFile(archive, 'w', zipfile.ZIP_DEFLATED) as z:
    for p in files:
        z.write(p, p.relative_to(root).as_posix())
    z.writestr('SOURCE_MANIFEST.json', json.dumps(manifest, ensure_ascii=False, indent=2))
    z.writestr('RESTORE.md', restore)
with zipfile.ZipFile(archive) as z:
    assert z.testzip() is None
    for name, digest in manifest.items():
        assert hashlib.sha256(z.read(name)).hexdigest() == digest, name
    for required in ['lib/main.dart', 'pubspec.yaml', 'pubspec.lock', 'android/gradle/wrapper/gradle-wrapper.jar']:
        assert required in manifest, required
result = dict(path=str(archive), files=len(files), bytes=archive.stat().st_size,
              sha256=hashlib.sha256(archive.read_bytes()).hexdigest())
(out / 'archive-info.json').write_text(json.dumps(result, indent=2), encoding='utf-8')
print(json.dumps(result))
