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
