# Stage 3 — Materials and card generation

Date: 2026-10-21.

## Implemented

- Card prompt generation uses the legacy prompt field key when a rule has no explicit prompt-field array; skips rows with missing required fields.
- Choice questions fall back to a correct answer derived from the configured answer field when no explicit correct option was rendered.
- Distractors are drawn from nonempty corresponding fields of other rows, deduplicated; choice questions with fewer than four options are skipped rather than displayed incomplete.
- Added CSV/TSV parser regression tests for missing columns, uneven rows, unclosed quotes, escaped quotes and multiline cells.
- Added archive preflight checks before extraction: no absolute/traversal/backslash/colon paths or symbolic links; at most 1,000 entries, 20 MB per entry and 100 MB total uncompressed bytes; requires a root manifest.
- Added archive preflight tests for missing manifest and normal archive.

## Scope and remaining risks

- This stage's tests are primarily unit tests; UI import/export/edit flows are not covered by automated end-to-end tests yet.
- ZIP archive limits rely on entry metadata. They do not yet enforce a separate streaming output limit or post-extraction cleanup on every failure.
- Import/export image round-trip, large real-world archives, and hostile ZIP fixtures need further tests before untrusted public package sharing.
- A four-choice question requires enough distinct distractors in the source dataset. Insufficient rows are excluded; the authoring UI should communicate this.
- App Store readiness is **not** established by this stage.

## Latest verification (2026-10-21)

- PASS: 21 unit tests and 3 UI tests on iPhone 16 Pro Max simulator, iOS 18.6, including opening Materials from the home screen.
- PASS: archive preflight regression with 1,001 entries rejected.
- PASS: manifest decoding now enforces a 2 MB limit and removes temporary extraction folder on error.
- NOT RUN: interactive CSV/TSV and .botai file picker workflows, actual .botai export/import round-trip with images, hostile path traversal fixture and device-level manual verification.
- **Stage 3 remains OPEN** until those workflows are covered. Passing automated tests alone is insufficient.

## ZIP import hardening follow-up

- Shared ZIP entry safety preflight is now used for both .botai packages (root manifest required) and generic ZIP archives containing CSV/TSV plus media (manifest optional).
- Generic ZIP importer cleans its temporary directory if extraction or CSV parsing fails.
- Regression test verifies a normal CSV ZIP passes manifest-optional validation but fails .botai validation.
- 2026-10-21 full simulator suite: **22 unit tests and 3 UI tests passed**, result bundle `/tmp/botai_release_audit_derived/Logs/Test/Test-BOTAI-2026.10.21_15-56-11-+0300.xcresult`.

## Image reference validation (2026-10-21)

- The package manifest now validates unique field keys, row keys, and that image field paths stay under `media/` without traversal or absolute paths.
- Added positive and negative regression tests for image path references.
- Full iPhone 16 Pro Max simulator suite: **24 unit tests and 3 UI tests passed**, `Test-BOTAI-2026.10.21_16-02-02-+0300.xcresult`.
- Still needed: export/import round-trip using real image bytes and end-to-end file picker checks; stage remains open.

## Export/import image bytes regression (2026-10-21)

- Added a real ZIP round-trip test: create a material with an image media reference, export it as .botai, import the archive, and compare the extracted image bytes exactly to the original bytes.
- Verified manifest metadata, question sets, image field type, and row data survive export/import.
- Simulator suite: **25 unit tests and 3 UI tests passed**, `Test-BOTAI-2026.10.21_16-05-15-+0300.xcresult`.
- Still needed: system document-picker UI workflow, malformed archive fixtures, and repository-level imported media persistence.

## Import source UI smoke (2026-10-21)

- Added accessible labels for the library add button and the CSV/TSV and BOTAI import source actions.
- New simulator UI test confirms the user can navigate from home to materials and access both import options.
- The initial attempt to assert a localized system file picker UI was unreliable; **picker presentation and file selection are not yet covered**. This is explicitly outstanding.
- Full simulator suite: **25 unit tests and 4 UI tests passed**, `/tmp/botai_stage3_sources.log`.

## Imported media persistence (2026-10-21)

- Package import now rejects missing referenced image files rather than silently leaving broken image references.
- Package import validates the manifest again before copying files and tolerates repeated references to the same destination filename.
- Added integration regression importing a two-row package with shared source media into MaterialRepository, verifying persisted row references and comparing both resolved image files with source bytes.
- Unit test rerun: **26 passed** (`Test-BOTAI-2026.10.21_16-14-31-+0300.xcresult`). UI suite: **4 passed** in preceding run. The preceding combined run reported a simulator test-runner bootstrap crash, so unit tests were rerun separately.
- Remaining: corrupted archive regression, document-picker selection, and failure cleanup coverage.

## Failed import cleanup (2026-10-21)

- Failed package import now removes the newly created material media directory, preventing orphaned copied files.
- Added regression for a valid manifest with missing image bytes: import rejects the package, SQLite material count stays unchanged, and the extracted temporary root is removed.
- Simulator unit suite: **27 tests passed**, `Test-BOTAI-2026.10.21_16-16-16-+0300.xcresult`. Previous UI suite: 4 passed.
- Remaining: malformed ZIP archive regression and complete system document-picker selection.

## Corrupt archive regression (2026-10-21)

- Added tests that reject a non-ZIP file named `.botai` and a truncated ZIP archive.
- All **29 unit tests passed** on the iPhone 16 Pro Max simulator, `Test-BOTAI-2026.10.21_16-18-06-+0300.xcresult`. The four UI smoke tests passed in the preceding run.
- Remaining Stage 3 item: full system document-picker file selection and preview/import UI coverage.

## Import preview cancellation cleanup (2026-10-21)

- Closing the BOTAI import preview now removes the temporary extracted package directory; successful import already removes it in MaterialStore.
- Simulator build and all 29 unit tests passed (`Test-BOTAI-2026.10.21_16-19-14-+0300.xcresult`).
- End-to-end selection through the native iOS document picker remains unverified.
