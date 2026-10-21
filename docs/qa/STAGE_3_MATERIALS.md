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
