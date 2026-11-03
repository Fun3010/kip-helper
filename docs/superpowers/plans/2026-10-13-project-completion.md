# Project Completion Implementation Plan

> **For agentic workers:** Use superpowers:subagent-driven-development task-by-task.

**Goal:** Complete the remaining five-stage roadmap and deliver the final Android APK, as authorized on 2026-11-03.
**Architecture:** Preserve the existing catalogue and calculation domain. Add independent notes, procedures, and imported-document modules; integrate through GuidePage and HomePage.
**Tech Stack:** Flutter/Dart, shared_preferences; PDF dependencies verified against primary documentation.
**Spec:** docs/superpowers/specs/2026-10-13-project-completion-design.md

## Evidence checkpoint — 2026-11-03

The owner also requires Windows x64 delivery and continuation from another
computer using GitHub, Notion and private Drive. Current product code is
`81ee1371e9feef4c56a14ab586e2e1ba820dfcb0`, now pushed. Local full suite:
319 passed, 0 skipped, 0 failed; full analysis clean; format checked 56 files
with 0 changes. [CI #74 / run 41611316221 / job 125833623960](https://github.com/Fun3010/kip-helper/actions/runs/41611316221/job/125833623960)
completed successfully: `Flutter tests: total=319, passed=319, skipped=0, failed=0`;
formatting and static analysis passed. Signing/APK steps were skipped for the PR event.
Previous GitHub CI #73
on `72a0b3d` passed formatting, analysis and all 318 tests
(318 passed, 0 skipped, 0 failed):
[run 41607948116 / job 125822375822](https://github.com/Fun3010/kip-helper/actions/runs/41607948116/job/125822375822).
Signing/APK steps were skipped for the PR event, not accepted as a release.
Draft PR [#12](https://github.com/Fun3010/kip-helper/pull/12) remains unmerged;
main CI is pending. Windows native on `72a0b3d` passed 2/2 and the ordinary
`lib/main.dart` build exists. Its later production smoke test found R16
(normal WM_CLOSE crashes with 0xC000041D) and R17 (garbled window title).
Both are fixed in `81ee137`: native A/B reproduced baseline 72 close failure,
then the experimental fix overlay exited 0 on normal WM_CLOSE with exact
«КИП Помощник» title. Independent static review passed. Official 81ee137 Windows native passed **2/2 in 43 seconds**.
Official `81ee137` release was explicitly built from `lib/main.dart` and
packaged immutably. The process responds, native title is exactly «КИП Помощник»,
and WM_CLOSE sent only to `FLUTTER_RUNNER_WIN32_WINDOW` exits 0. All 9 bundled
CRT file hashes match the installed VS 2019 x64 Redist. ZIP: 21,970,227 bytes;
SHA-256 `F2A0D7B01EF765B1CBB93229A30AA0A30EF1CBAD5611F7D3C904977D9035AD6C`.
Private Drive upload and authenticated download verified the exact ZIP SHA-256 and all 53 manifest file hashes.
The earlier 2/2 result did not cover ordinary main-app close. Earlier Android native PDF scenarios passed
on `7379ba3`; actual system-picker import passed after R13 (`103372b`).
R14 focused PDF labels and R15 import-title collapse with IME are fixed in
`72a0b3d` with product-theme widget regressions. Android native R10/R14/R15
validation passed on private emulator-5556, API 33, 320 dp, system font 225%
and default app font: actual Google Latin IME, focused PDF labels/search/page
navigation, real DocumentsUI import-title editing/cancel/add, and broken-PDF
error/retry/scroll/back. Android process-restart checks also passed: deleting
only the QA source PDF then force-stop/relaunch retained the library and
renderable private copy; an explicitly saved ИВА-8 note retained its exact
text after force-stop/relaunch at normal font. This is not native save-and-exit.
Screenshots: `build/qa/layout72-*.png`. The delivered Android debug APK remains
`72a0b3d`; the Windows-only guard/title change and regression in 81ee137 do not
invalidate its observed Android scenarios. Build the eventual signed release
from current source when the original key is restored. Official Windows bundle
normal-close/title smoke passed; full save-and-exit and another-PC checks remain open.

Checked items below describe demonstrated implementation or the stated test
scope, not completion of the whole release. Historical source reports are not
a new reading of absent manuals. Current results and open gates are recorded in
`docs/release-review-2026-11-03.md`, `docs/release-delivery-2026-11-03.md`,
`docs/test-plan.md` and `HANDOFF.md`.

## Global Constraints

- The 2026-11-03 user request authorizes local dependency resolution, Flutter analysis/tests, Android builds and emulator validation.
- Preserve the original release identity and certificate. Never generate a replacement release key or bypass the release-signing guard. A release update requires the owner's original key.
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
  Historical reports `docs/optiflex1300c-source-verification-2026-10-13.md` and
  `docs/micro-motion-source-verification-2026-10-13.md` record full text extraction,
  model/edition/hash/page checks and selected-page/figure visual inspection.
  Original PDFs are currently absent; a fresh full-source read/extraction replay
  is not proven by the current checkout.
- [x] Add tests for correct registration, model boundaries, source resolution, evidence, assets and figure search. Included in the 305-test checkpoint; final CI is tracked under Task 5.
- [x] Add source-backed cards and at least two useful original illustrations per model, with SHA-guarded extraction scripts.
- [x] Commit cards, extraction scripts and source-limit reports. Current four PNG hashes match the provenance manifest; byte-identical extraction and wrong-source refusal are historical report evidence, not a fresh replay with missing PDFs.

### Task 2: Persistent personal notes

**Files:** Create lib/services/guide_notes.dart, lib/features/notes/guide_notes_page.dart, test/guide_notes_test.dart, test/guide_notes_ui_test.dart; modify lib/features/guides/guide_page.dart.
**Interfaces:** GuideNotesPage(guideId, guideTitle); internal injectable persistence/controller for tests.
- [x] Test save/reload, per-guide isolation, corruption, failed write/retry and dirty exit; included in the 305-test checkpoint. Native fresh-adapter read is distinct from application restart.
- [x] Add editor opened by the labelled app-bar overflow action, explicit Save, state/error labels, clear confirmation and exit protection. Limit text to 20000 Unicode graphemes and persist exact text.
- [x] Verify widget UI at 320 px with 2.25 scale, simulated keyboard insets and both themes; commit task files. Real IME remains a separate gate; PR CI #73 passed.

### Task 3: Source-backed step-by-step workflows

**Files:** Create lib/models/guide_procedure.dart, lib/data/guide_procedures.dart, lib/features/guides/procedure_page.dart, test/guide_procedures_test.dart; modify GuidePage.
**Interfaces:** A procedure identifies its guide, exact variant, prerequisites, steps with action/expected result/evidence and source references. Registry consumed by GuidePage.
- [x] Select five explicit workflows from verified P0 paragraphs: СОКРАТ travel configuration/code identification, СУ-1С contact/relay comparison and SIPART preparation by actuator type. Boundaries are in `docs/procedure-source-notes.md`; no unsupported full SIPART button sequence is claimed.
- [x] Test registry/evidence integrity, model selection before steps, forward/back/reset behavior and narrow large-text UI; included in the 305-test checkpoint.
- [x] Implement self-contained procedure viewer, model scope and prerequisites before start; no claim that tapping completion verifies the physical instrument.
- [x] Commit source notes and task files. Final CI is tracked under Task 5.

### Task 4: Offline imported PDF library

**Files:** Create lib/features/manuals/*, lib/services/manual_library.dart, lib/models/local_manual.dart, test/manual_library_test.dart, test/manual_library_ui_test.dart. Modify app.dart, GuidePage, pubspec.yaml/lock and relevant platform configuration.
**Interfaces:** ManualLibraryPage optional guideId/guideTitle, persistent private file store and injectable service; PdfManualPage opens copied file at one-based initialPage and supports search.
- [x] Verify/pin PDF viewer, file selector and private-directory dependencies against primary documentation and installed package APIs; resolve locally under the 2026-11-03 authorization. Final CI resolution is tracked under Task 5.
- [x] Test injected-picker import/cancel, duplicate, rejected non-PDF, corruption/missing-file recovery, title and guide metadata, confirmed removal and page-boundary validation; included in the 305-test checkpoint. This does not exercise a system picker.
- [x] Implement file-size limit 100 MiB, atomic import/metadata storage, system picker, per-guide and full library entry, page navigation, PDF text search and explicit scan limitation.
- [x] Test widget controls at 320 px / 2.25 scale and fresh-service persistence, without claiming native rendering from mocks; include the final narrow error-panel regression.
- [x] Add R05 failure/retry and final-row reachability regressions; add R13 confirm/cancel lifecycle tests, R14 focused PDF-label visibility with the product theme and R15 four large-text/IME title-editor cases. Included in the 318-test PR CI result.
- [x] Verify Android R10/R14/R15 on `72a0b3d`, private emulator-5556/API 33 at 320 dp/system font 225%: actual IME keeps PDF labels visible, search finds Acceptance once on page 2/2 and numeric input navigates to 1/2; real DocumentsUI title editing/cancel leaves the library unchanged and repeated add creates an entry without a controller crash. The 16-byte broken PDF shows an error, retry repeats it, scrolling exposes both buttons and lower Back returns to the library.
- [x] Verify Android persistence on `72a0b3d`: delete the owned `/sdcard/Download/kip-qa.pdf`, verify absence, force-stop/relaunch and render private kip-qa Firstpage at 1/2 from the retained library. Explicitly save ИВА-8 note `QA72-persist-20261103`, force-stop/relaunch and read exactly the same text with 21/20000 and Saved at normal font. This does not test native save-and-exit. The historical failed-to-start narrow rerun remains a failed attempt, superseded only for the observed scenarios above.

### Task 5: NSХ table and integration

**Files:** Create lib/features/calculators/rtd_table.dart and test/rtd_table_test.dart; modify app.dart and lib/domain/calculations.dart only if needed; update README.md, roadmap, test plan and journal.
**Interfaces:** Reuse existing RTD domain functions; no second set of coefficients.
- [x] Test independent Pt/П/М reference points, family bounds, comma input, invalid/zero step, row cap of 501, endpoint behavior and distinct fine-grid labels; included in the 305-test checkpoint.
- [x] Add table tool with type/start/end/step controls, clear units and readable rows at large scale, sharing the existing RTD domain.
- [x] Reconcile entry points and update README, roadmap, test plan and journal with implemented features and open device/APK checks. New results must be added with their actual commit and scope.
- [x] Run PR CI (format/analyze/tests) and independent whole-project/focused reviews. CI #73 on 72a0b3d passed all 318 tests with no skips/failures, formatting and analysis. Current 81ee137 passed 319 local tests, formatting and full analysis; CI #74 also passed 319/319 with 0 skips/failures, formatting and static analysis. PR signing/APK steps were skipped.
- [x] Fix R16/R17 in 81ee137: restore normal native close ordering with failure-veto recovery and Unicode title escapes. A/B normal-main close passed (baseline crash versus fix exit 0 and correct title); single-lifecycle regression and independent static review passed.
- [x] Complete CI #74 (319/319, 0 skipped/failed, formatting/static analysis passed; PR signing/APK skipped) and official 81ee137 Windows native (2/2 in 43 seconds).
- [x] Verify official 81ee137 production main release and immutable bundle: responsive process, exact native title, WM_CLOSE only to FlutterRunner exits 0; all 9 CRT hashes match installed VS 2019 x64 Redist.
- [x] Complete Drive upload/download SHA-256 verification for the official Windows ZIP (21,970,227 bytes, F2A0D7B01EF765B1CBB93229A30AA0A30EF1CBAD5611F7D3C904977D9035AD6C).
- [ ] Merge authorized work and verify main CI. PR #12 remains draft.
  The pull-request event skipped signing/APK steps by workflow design; this is
  not evidence of an Android release.

### Task 6: Final Android delivery (2026-11-03)

**Files:** pubspec.yaml, android local build configuration, docs/release-delivery-2026-11-03.md (the actual delivery report), README.md, PROJECT_JOURNAL.md; APK and checksums in ignored dist/.
- [x] Verify current 81ee137 code with local full-suite 319 tests, formatting, full analysis and independent review. CI #74 and official Windows normal-close/title bundle checks also passed; original-signature delivery and the remaining device/input/save-and-exit checks stay open.
- [x] Increase version to 1.3.0+5 and preserve release application ID ru.kiphelper.app and the release-signing guard; debug uses the separate .dev ID.
- [x] Build and inspect the ordinary debug APK, install and exercise native PDF import/render/search and persistence in an available emulator.
  The `lib/main.dart` build for `72a0b3d` passed actual DocumentsUI, IME,
  R10/R14/R15, private-copy rendering after source deletion and force-stop,
  and explicitly saved note readback after force-stop. This covers the stated
  emulator scenarios, not physical-phone acceptance or original-signature release.
- [ ] Build release only when original signing files are restored. Verify APK package/version/ABIs/certificate and produce a SHA-256 checksum.
  Required original certificate SHA-256:
  `10bb36a1b9b994a859b45517623666d6323e997e2e1c73cb273e9a1939b8cd7c`.
  Encrypted original backup is preserved; its former password is missing.
  Do not substitute a new key or relax the guard.
- [ ] Document actual checks and remaining physical-device/store acceptance. Deliver the local APK; public store publication requires separate authorization.
  Existing debug delivery and its limitations are documented; it does not satisfy
  the final signed APK requirement. Physical-phone checks remain separately stated
  when no phone is available.

### Task 7: Windows and cross-device delivery (2026-11-03 scope)

- [x] Build Windows x64 release from `lib/main.dart` and package Flutter/data/PDFium/plugins/VC Runtime, instructions, license and hashes.
- [x] Pass ordinary production Windows startup/close smoke checks on the official 81ee137 package: responsive process, exact «КИП Помощник» title, WM_CLOSE only to FLUTTER_RUNNER_WIN32_WINDOW exits 0. Official native also passed 2/2 in 43 seconds. Drive ZIP and all 53 manifest hashes were verified by authenticated download; another PC and full save-and-exit are separate checks.
- [x] Repeat Windows native acceptance on `81ee137`: 2/2 passed in 43 seconds (previous `72a0b3d` also passed 2/2). Widget tests also cover Tab traversal and Enter/Space zoom/reset through framework key events in both themes.
- [ ] Finish native Windows input/exit acceptance: physical keyboard zoom/reset, real X/Alt+F4, complete save-and-exit and readback after application restart. Current native tests prove cancellation and normal Save, not the whole exit flow.
- [ ] Verify the complete Windows package on the notebook/target system; current-machine startup does not establish that result.
- [x] Publish the working Git branch, Notion handoff and available source/build/material archives to private Drive, with links and explicit verification limits in `docs/cross-device-storage.md`.
- [ ] Complete restoration of external project materials and signing access: 17 historical PDFs, 13 JPG and the original signing-backup password remain unavailable. Preserve those gaps in every handoff.
- [x] Download all three cloud APK parts and verify each SHA-256; reconstruct the exact ZIP and APK through Windows PowerShell. The 72a0b3d transfer receipt and cloud-roundtrip report record success; metadata remains private.
