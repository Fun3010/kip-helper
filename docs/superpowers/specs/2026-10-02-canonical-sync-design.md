# KIP Helper Canonical Synchronization Design

**Date:** 2026-10-02

## Goal

Make the actual KIP Helper 1.2.1+4 source snapshot from 2026-10-02 the single canonical Git source without losing the existing GitHub history or leaking signing secrets and local technical materials.

## Current verified state

- GitHub repository: `Fun3010/kip-helper`.
- Default branch: `main`.
- GitHub `main` currently points to commit `9884419110cc122c72fab363f754d00866a8f7b1` and contains the old 1.0.0+1 application.
- The current GitHub tree uses `com.example.kip_helper`, debug release signing, one monolithic `lib/main.dart`, and only the template widget test.
- The current working snapshot recorded in Notion is KIP Helper 1.2.1+4 with package `ru.kiphelper.app`, permanent release signing, a modular Flutter/Dart architecture, and a recorded 155-test regression baseline from 1.2.0.
- Canonical source archive: `kip-helper-source-2026-10-02.zip`.
- Expected archive size: 2,180,721 bytes.
- Expected archive SHA-256: `6b9d84ecfc74270f0e358215b7b843fb09541583b36b6374e6f6eb8c0c3a05e1`.
- The archive contains 190 project files plus `RESTORE.md` and `SOURCE_MANIFEST.json`.
- The archive intentionally excludes Git history, APK files, SDK-local paths, original technical PDFs/photos, keystore material, passwords, and other secrets.

## Source-of-truth model

1. **GitHub** becomes the canonical source for application code, tests, build scripts, non-secret configuration, documentation, and machine-readable content manifests.
2. **Notion** remains project memory: decisions, audit notes, roadmap, validation history, and human-readable handover material.
3. **Private evidence storage** remains the home for original manuals, source photographs, release keystore backups, passwords, and other material that must not be committed to the public repository.
4. Generated APK files are release artifacts, not source-of-truth files.

## Synchronization strategy

### 1. Preserve the existing Git state

Before replacing code, create an immutable preservation reference from the existing `main` state, named `archive/pre-sync-main-2026-10-02`.

The synchronization must never force-push over the only copy of the old Git history.

### 2. Validate the source snapshot

The 1.2.1 archive is accepted for import only if:

- ZIP SHA-256 matches the expected value above.
- `SOURCE_MANIFEST.json` exists.
- Every archived file listed by the manifest matches its recorded checksum.
- `pubspec.yaml` reports version `1.2.1+4`.
- Android release application ID/namespace is `ru.kiphelper.app`.
- Debug application ID remains distinct, `ru.kiphelper.app.dev`, if that variant is present in the snapshot.
- No keystore, `key.properties`, password, SDK-local path file, APK, or original private technical document is imported.

If any of these conditions fail, the synchronization stops rather than silently reconstructing or guessing missing source.

### 3. Import into an isolated synchronization branch

Use branch `chore/canonical-sync-1.2.1`.

Replace obsolete source files with the archive contents while retaining Git history through an ordinary commit. Files present only in the stale 1.0.0 tree and absent from the canonical archive are removed unless they are intentionally preserved documentation.

### 4. Repository hygiene

During import:

- remove accidental temporary source copies such as `lib/main.dart.tmp` unless the canonical manifest explicitly contains and justifies them;
- retain `pubspec.lock`;
- keep signing secrets ignored;
- ensure local SDK files remain ignored;
- add/update README so it describes 1.2.1 rather than 1.0.0;
- document how a new machine restores dependencies and verifies the project;
- do not commit original manuals/photos merely because they exist locally.

### 5. Verification gate

The synchronization is not considered complete until the imported snapshot is freshly verified.

Required checks, in order:

1. `dart format --output=none --set-exit-if-changed lib test`
2. `flutter analyze`
3. `flutter test`
4. `flutter build apk --debug`
5. release configuration audit:
   - release package = `ru.kiphelper.app`
   - release build refuses to fall back to debug signing when the private signing configuration is absent
6. if permanent signing material is available in the execution environment, build and verify the release APK with `apksigner verify`; otherwise record this as an external verification step rather than weakening signing rules.

No previous test result is used as proof of current success.

## Safety rules

- Never upload the release keystore or passwords to GitHub, Notion comments, chat, CI logs, or build artifacts.
- Do not infer missing application code from the Notion prose if the canonical archive cannot be read.
- Do not mix equipment variants or revisions while resolving content conflicts.
- Do not mark the RuStore distribution step complete until the current alpha can actually be installed from RuStore by the intended tester account.

## Completion criteria

Synchronization is complete only when all of the following are true:

- the preserved pre-sync Git reference exists;
- branch `chore/canonical-sync-1.2.1` contains exactly the validated canonical source snapshot plus explicitly reviewed synchronization documentation;
- version/package/signing configuration matches the documented 1.2.1 identity;
- format, analyzer, tests, and debug Android build have fresh passing evidence;
- no secret material is present in the Git tree;
- the branch diff against old `main` has been reviewed;
- the synchronization is merged by normal Git history, not by destructive replacement of repository history;
- Notion is updated to identify the resulting Git commit as the canonical source revision.

## Work explicitly deferred until after synchronization

The following are intentionally not mixed into this migration:

- new instruments or technical content;
- favorites/recent items UX;
- offline full-PDF search;
- training/RPO module;
- cloud services, registration, or backend;
- AI-assisted search;
- broad UI redesign.

After the canonical baseline is established, the project is re-audited and a new roadmap is produced from the actual synchronized code rather than the stale repository or archive description.
