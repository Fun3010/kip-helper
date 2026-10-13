# Project Completion Implementation Plan

> **For agentic workers:** Use superpowers:subagent-driven-development task-by-task.

**Goal:** Complete the remaining five-stage roadmap without building an APK.
**Architecture:** Preserve the existing catalogue and calculation domain. Add independent notes, procedures, and imported-document modules; integrate through GuidePage and HomePage.
**Tech Stack:** Flutter/Dart, shared_preferences; PDF dependencies verified against primary documentation.
**Spec:** docs/superpowers/specs/2026-10-13-project-completion-design.md

## Global Constraints

- No APK builds, local Flutter commands, flutter pub get, or release-signing guard.
- Flutter analyze/test and dependency resolution run only in GitHub Actions.
- Preserve Russian UI, 320 px support, both themes, and composed text scaling.
- Never invent instrument instructions, terminals, source locators or technical illustrations.
- Original PDFs stay outside public git; extracted figures retain exact provenance.
- Implementers do not spawn agents or publish remote changes. Controller publishes CI revisions.

## Review Focus

- Persistence failure must preserve visible user data and expose retry.
- Corrupt stored state and stale identifiers must not prevent opening the app.
- Large text and keyboard must not hide essential actions on narrow screens.
- Wrong-model PDF/procedure association must not imply manufacturer verification.
- Scan PDFs must remain viewable even when text search cannot find content.

### Task 1: Remaining instrument cards

**Files:** Create lib/data/optiflex1300c.dart and lib/data/micro_motion.dart; add scripts/extract-*-illustrations.py, assets/illustrations/*, docs/*source-verification*.md, test/remaining_guides_test.dart. Modify lib/data/guides.dart and docs/illustration-sources.json.
**Interfaces:** Produce InstrumentGuide constants consumed by guides list, using existing evidence and illustration model.
- [ ] Read full supplied manuals in ../completion_sources, verify model/revision/hash/page locators, visually inspect chosen figures.
- [ ] Add tests for correct registration, model boundaries, source resolution, evidence, assets and figure search; controller runs CI.
- [ ] Add source-backed cards and at least two useful original illustrations per model, with reproducible SHA-guarded extraction.
- [ ] Verify extraction, format with standalone Dart, report source limitations and commit only task files.

### Task 2: Persistent personal notes

**Files:** Create lib/services/guide_notes.dart, lib/features/notes/guide_notes_page.dart, test/guide_notes_test.dart, test/guide_notes_ui_test.dart; modify lib/features/guides/guide_page.dart.
**Interfaces:** GuideNotesPage(guideId, guideTitle); internal injectable persistence/controller for tests.
- [ ] Test save/reload, per-guide isolation, corruption, failed write/retry and dirty exit.
- [ ] Add editor opened by an accessible app-bar action, explicit Save, state/error labels, clear confirmation and exit protection. Limit text to 20000 characters and persist exact text.
- [ ] Verify UI at 320 px with 2.25 scale, keyboard and both themes. Controller runs CI; commit task files.

### Task 3: Source-backed step-by-step workflows

**Files:** Create lib/models/guide_procedure.dart, lib/data/guide_procedures.dart, lib/features/guides/procedure_page.dart, test/guide_procedures_test.dart; modify GuidePage.
**Interfaces:** A procedure identifies its guide, exact variant, prerequisites, steps with action/expected result/evidence and source references. Registry consumed by GuidePage.
- [ ] Select explicit supported workflows from verified P0 sources; cover connect, calibrate/configure, diagnose across supported variants.
- [ ] Test registry/evidence integrity, model selection before steps, forward/back/reset behavior and narrow large-text UI.
- [ ] Implement self-contained procedure viewer, model scope and prerequisites before start; no claim that tapping completion verifies the physical instrument.
- [ ] Controller runs CI; commit source notes and task files.

### Task 4: Offline imported PDF library

**Files:** Create lib/features/manuals/*, lib/services/manual_library.dart, lib/models/local_manual.dart, test/manual_library_test.dart, test/manual_library_ui_test.dart. Modify app.dart, GuidePage, pubspec.yaml/lock and relevant platform configuration.
**Interfaces:** ManualLibraryPage optional guideId/guideTitle, persistent private file store and injectable service; PdfManualPage opens copied file at one-based initialPage and supports search.
- [ ] Verify/pin PDF viewer, file selector and private-directory dependencies from current primary docs; dependencies resolved in CI only.
- [ ] Test import/cancel, duplicate, rejected non-PDF, corruption/missing-file recovery, title and guide metadata, confirmed removal and page-boundary validation using fakes.
- [ ] Implement file-size limit 100 MiB, atomic import/metadata storage, system picker, per-guide and full library entry, page navigation, PDF text search and explicit scan limitation.
- [ ] Test responsive controls at 320 px / 2.25 scale and persistence without native viewer mocks pretending to verify rendering. Record native acceptance pending; controller runs CI.

### Task 5: NSХ table and integration

**Files:** Create lib/features/calculators/rtd_table.dart and test/rtd_table_test.dart; modify app.dart and lib/domain/calculations.dart only if needed; update README.md, roadmap, test plan and journal.
**Interfaces:** Reuse existing RTD domain functions; no second set of coefficients.
- [ ] Test reference points, correct family bounds, comma input, invalid/zero step, row cap of 501 and endpoint behavior.
- [ ] Add table tool with type/start/end/step controls, clear units and readable rows at large scale.
- [ ] Reconcile all entry points, update documentation with exact completed features and remaining device/APK checks.
- [ ] Run full CI (format/analyze/tests), independent whole-branch review, fix findings, merge authorized work, verify main CI and skipped APK steps.
