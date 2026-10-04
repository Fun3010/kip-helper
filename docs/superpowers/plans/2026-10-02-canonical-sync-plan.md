# KIP Helper Canonical Synchronization Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the stale GitHub 1.0.0+1 tree with the validated KIP Helper 1.2.1+4 source snapshot while preserving history, preventing secret leakage, and producing a freshly verified canonical baseline.

**Architecture:** The migration is deliberately non-destructive. The old `main` state is preserved by a dedicated archive ref, the Notion source ZIP is checksum-validated before any import, and the canonical snapshot is imported on `chore/canonical-sync-1.2.1`. Verification is performed against the imported tree before merge; Notion is updated only after the resulting canonical commit is known.

**Tech Stack:** Flutter 3.41.6, Dart 3.11.4, Android Gradle Plugin 8.11.1, Kotlin 2.2.20, Gradle 8.14, Java 17 target, Git/GitHub, Python or shell for archive/hash verification.

**Spec:** `docs/superpowers/specs/2026-10-02-canonical-sync-design.md`

## Global Constraints

- Canonical application version is `1.2.1+4`.
- Canonical release application ID/namespace is `ru.kiphelper.app`.
- Debug identity must remain distinct as `ru.kiphelper.app.dev` when present.
- Expected source archive is `kip-helper-source-2026-10-02.zip`.
- Expected source archive size is `2180721` bytes.
- Expected SHA-256 is `6b9d84ecfc74270f0e358215b7b843fb09541583b36b6374e6f6eb8c0c3a05e1`.
- `SOURCE_MANIFEST.json` and `RESTORE.md` must exist in the snapshot.
- Do not commit keystores, passwords, `android/key.properties`, SDK-local paths, APK files, or original private technical PDFs/photos.
- Missing release signing configuration must never silently fall back to debug signing.
- Do not invent or reconstruct source from Notion prose if the archive cannot be read.
- Do not add product features while performing this migration.

## Review Focus

1. A valid-looking ZIP with the wrong SHA must stop before repository mutation.
2. A manifest entry with a changed/missing file must stop the import rather than be silently accepted.
3. A stale 1.0.0-only file absent from the canonical manifest must not survive accidentally.
4. A missing permanent signing config must cause release signing/build validation to fail safely, not produce a debug-signed release.
5. Secret/private evidence files must remain absent from Git history and migration commits.

---

### Task 1: Preserve the pre-sync GitHub state

**Files:**
- No product files modified.
- Create Git ref: `archive/pre-sync-main-2026-10-02`.

**Interfaces:**
- Consumes: GitHub `main` at `9884419110cc122c72fab363f754d00866a8f7b1`.
- Produces: immutable recovery point for the stale 1.0.0+1 repository state.

- [ ] **Step 1: Verify the current main SHA**

Run through GitHub API:
`GET /repos/Fun3010/kip-helper/branches/main`

Expected: head SHA = `9884419110cc122c72fab363f754d00866a8f7b1`.

- [ ] **Step 2: Create preservation branch**

Create:
`archive/pre-sync-main-2026-10-02` from exact SHA `9884419110cc122c72fab363f754d00866a8f7b1`.

Expected: branch exists and points to the exact pre-sync SHA.

- [ ] **Step 3: Re-read the preservation ref**

Expected: no commit divergence from the original pre-sync SHA.

---

### Task 2: Acquire and validate the canonical source snapshot

**Files:**
- Scratch only: `/mnt/data/kip-helper-source-2026-10-02.zip`
- Scratch only: extracted validation directory.

**Interfaces:**
- Consumes: Notion attachment from page `3ed2c52e-be21-81b0-9b75-dfad3c9d0aed`.
- Produces: verified extracted source tree eligible for import.

- [ ] **Step 1: Materialize the exact ZIP bytes**

Acquire the Notion attachment without editing it.

Expected filename: `kip-helper-source-2026-10-02.zip`.

- [ ] **Step 2: Verify byte size**

Run:
`stat -c %s /mnt/data/kip-helper-source-2026-10-02.zip`

Expected:
`2180721`

- [ ] **Step 3: Verify archive SHA-256**

Run:
`sha256sum /mnt/data/kip-helper-source-2026-10-02.zip`

Expected:
`6b9d84ecfc74270f0e358215b7b843fb09541583b36b6374e6f6eb8c0c3a05e1`

- [ ] **Step 4: Verify ZIP integrity**

Run:
`unzip -t /mnt/data/kip-helper-source-2026-10-02.zip`

Expected: no corrupt entries.

- [ ] **Step 5: Extract to a clean scratch directory**

Extract without merging into an existing tree.

Expected: `SOURCE_MANIFEST.json`, `RESTORE.md`, `pubspec.yaml`, `lib/`, `test/`, and `android/` exist.

- [ ] **Step 6: Validate manifest coverage**

Run a checksum validator over every file listed in `SOURCE_MANIFEST.json`.

Expected: every listed path exists and its SHA-256 matches; no manifest mismatch is accepted.

- [ ] **Step 7: Verify canonical identity**

Inspect `pubspec.yaml` and Android Gradle configuration.

Expected:
- version = `1.2.1+4`
- release application ID/namespace = `ru.kiphelper.app`
- debug ID = `ru.kiphelper.app.dev` when defined.

- [ ] **Step 8: Scan forbidden material**

Search extracted tree for:
- `*.jks`, `*.keystore`
- `key.properties`
- likely password/secret files
- `local.properties`
- `*.apk`
- original technical PDF/photo evidence directories not explicitly intended as app assets.

Expected: none of the prohibited release-secret/private-evidence files are eligible for Git import.

---

### Task 3: Import the validated 1.2.1+4 tree

**Files:**
- Replace stale product tree with validated snapshot contents.
- Preserve:
  - `docs/superpowers/specs/2026-10-02-canonical-sync-design.md`
  - `docs/superpowers/plans/2026-10-02-canonical-sync-plan.md`

**Interfaces:**
- Consumes: validated extracted source from Task 2.
- Produces: synchronization branch whose product tree matches the canonical snapshot.

- [ ] **Step 1: Record current synchronization branch head**

Branch:
`chore/canonical-sync-1.2.1`

Expected: design spec commit remains reachable.

- [ ] **Step 2: Replace stale source deterministically**

Remove tracked files that are absent from the canonical snapshot, then copy the validated snapshot into the repository while retaining the Superpowers migration documents.

Expected: obsolete files such as stale temporary source copies survive only if explicitly present in the canonical manifest.

- [ ] **Step 3: Check for accidental stale 1.0.0 identity**

Search repository for:
- `version: 1.0.0+1`
- `com.example.kip_helper`
- release debug-signing fallback markers from the stale tree.

Expected: none remain in active canonical build configuration.

- [ ] **Step 4: Commit canonical import**

Commit message:
`chore: restore canonical KIP Helper 1.2.1 source`

Expected: one reviewable import commit containing the canonical tree transition.

---

### Task 4: Repository hygiene and signing safety

**Files:**
- Modify as needed: `.gitignore`
- Modify as needed: `README.md`
- Inspect: Android signing configuration and restore documentation.

**Interfaces:**
- Consumes: imported canonical tree.
- Produces: repository that can be cloned/restored without secrets and describes the current version truthfully.

- [ ] **Step 1: Audit ignore rules**

Ensure ignore rules cover at minimum:
- `android/key.properties`
- release keystore files
- `local.properties`
- build outputs
- APK artifacts
- private scratch/config directories.

Expected: release secrets/local SDK paths cannot be added casually.

- [ ] **Step 2: Verify release-signing failure mode**

With release key configuration intentionally absent, inspect/run the project-defined release guard.

Expected: release cannot silently fall back to debug signing.

- [ ] **Step 3: Update README only where stale**

README must identify:
- KIP Helper
- current version `1.2.1+4`
- package `ru.kiphelper.app`
- restore/test commands
- the fact that signing secrets and original technical evidence are external to Git.

Expected: no claim that cannot be verified from the imported tree or recorded project state.

- [ ] **Step 4: Secret scan the Git diff**

Search added/changed files for obvious credentials, private keys, password values, and keystore blobs.

Expected: zero secret material in the synchronization diff.

- [ ] **Step 5: Commit hygiene changes if any**

Commit message:
`docs: align repository metadata with canonical release`

Expected: commit is limited to hygiene/documentation/signing-safety changes.

---

### Task 5: Fresh Flutter baseline verification

**Files:**
- No product changes unless a verified migration defect is found and separately ruled.

**Interfaces:**
- Consumes: canonical imported branch.
- Produces: fresh evidence that the repository is reproducible enough to become canonical.

- [ ] **Step 1: Confirm toolchain**

Run:
`flutter --version`
`dart --version`
`java -version`

Expected target environment:
- Flutter 3.41.6
- Dart 3.11.4
- Java compatible with the recorded Android setup.

Any version drift is recorded explicitly.

- [ ] **Step 2: Restore dependencies**

Run:
`flutter pub get`

Expected: exit 0.

- [ ] **Step 3: Format verification**

Run:
`dart format --output=none --set-exit-if-changed lib test`

Expected: exit 0.

- [ ] **Step 4: Static analysis**

Run:
`flutter analyze`

Expected: exit 0 with no analyzer errors.

- [ ] **Step 5: Full tests**

Run:
`flutter test`

Expected: exit 0. Record the actual test count; do not assume the historical 155 count.

- [ ] **Step 6: Debug Android build**

Run:
`flutter build apk --debug`

Expected: exit 0 and a debug APK produced.

- [ ] **Step 7: Release signing guard verification**

Attempt the project-defined release build without restoring private signing secrets.

Expected: safe refusal if the permanent signing configuration is absent. A debug-signed release is a failure.

- [ ] **Step 8: Optional signed-release verification**

Only if permanent signing material is available in a secure execution environment:
`flutter build apk --release`
then
`apksigner verify <release-apk>`

Expected: both exit 0.

If signing material is not available, record this verification as external/pending; do not weaken the project.

---

### Task 6: Review the canonical diff and prepare integration

**Files:**
- Entire branch diff against `main`.

**Interfaces:**
- Consumes: verified sync branch.
- Produces: reviewed branch ready for normal GitHub integration.

- [ ] **Step 1: Diff old main against sync branch**

Review:
- source structure
- version/package identity
- tests
- assets
- Android configuration
- scripts
- deleted stale files
- migration docs.

Expected: every material change is explainable as canonical snapshot import or explicit repository hygiene.

- [ ] **Step 2: Re-run secret scan on the complete branch**

Expected: zero signing secrets/private evidence.

- [ ] **Step 3: Re-run the full completion verification**

Run fresh:
`dart format --output=none --set-exit-if-changed lib test && flutter analyze && flutter test && flutter build apk --debug`

Expected: all commands exit 0 in the same final branch state.

- [ ] **Step 4: Create a GitHub pull request**

Base: `main`
Head: `chore/canonical-sync-1.2.1`

Title:
`Restore canonical KIP Helper 1.2.1 source`

PR body must include:
- preserved old-main branch name
- source ZIP SHA-256
- actual test count from Task 5
- analyzer/build results
- signing verification status
- known external verification items.

Expected: PR is reviewable and does not merge automatically.

---

### Task 7: Establish the canonical revision and re-audit roadmap

**Files:**
- Notion project archive/overview/roadmap pages after integration.
- No unrelated product changes.

**Interfaces:**
- Consumes: merged canonical Git commit.
- Produces: one consistent project state across GitHub and Notion plus a prioritized post-sync roadmap.

- [ ] **Step 1: Merge only after explicit integration approval**

Use ordinary Git history; no force-push.

Expected: `main` contains the reviewed canonical source and the pre-sync archive ref remains intact.

- [ ] **Step 2: Tag the baseline**

Create:
`v1.2.1+4-baseline`

Expected: tag points to the canonical synchronized commit.

- [ ] **Step 3: Update Notion canonical source record**

Record:
- canonical GitHub commit SHA
- branch/tag
- archive SHA-256
- fresh analyzer/test/build evidence
- signed-release verification status
- RuStore verification status.

Expected: Notion no longer describes its ZIP as the only recoverable current source.

- [ ] **Step 4: Re-audit from synchronized source**

Inspect actual:
- architecture/file boundaries
- test coverage
- release scripts
- CI presence/absence
- source/evidence manifests
- device-card schema
- search/filter state
- favorites/recent state
- technical-document ingestion scripts.

Expected: post-sync audit is based on source code, not the historical Notion description.

- [ ] **Step 5: Produce the next roadmap**

Prioritize only after re-audit. Initial candidate order to validate:
1. CI/reproducible release gates.
2. Four exemplar fully sourced device cards: SIPART, SOKRAT, SU-1S, STM-10.
3. Favorites/recent/persistent quick access.
4. New devices from the verified-document backlog.
5. Offline manual indexing.
6. Training/RPO as a separate revision-controlled content domain.
7. Advanced field tools.
8. Source-grounded intelligent search only after provenance quality is high.

Expected: roadmap distinguishes verified fact, technical debt, feature work, and external/manual checks.
