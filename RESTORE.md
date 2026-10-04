# Restore source snapshot

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
