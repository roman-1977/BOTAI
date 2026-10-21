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
