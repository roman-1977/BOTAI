# Session mode/settings acceptance matrix — 2026-10-22

All scenarios are mandatory for MVP; this is a verification plan, not evidence of passing tests.

## Dimensions
- Scope: all subjects mixed; one subject; one topic; user daily-goal quick start.
- Format: mixed (reveal/pair/single-choice/multiple-choice), cards only (reveal/pair), tests only (single/multiple choice).
- Strategy: automatic (due first, then new, then not-yet-due reinforcement), all (source order). Review is a priority within automatic strategy, not a separate launch mode.
- Data: populated, no eligible format, no due items, some due items, duplicate references across topics, offline, resumed session.

## Expected invariants
1. Fresh session picker defaults to mixed format and automatic strategy; reopening resets temporary overrides.
2. Changing format filters out ineligible kinds; zero eligible questions disables the launch row; no empty session is created.
3. Absence of due questions must never block starting a session with eligible new or reinforcement questions. No separate review-only quick start.
4. All includes all eligible questions in source order. Automatic prioritizes due (weakest first), then new, then not-yet-due; equal-priority questions retain source order. Full teacher-guided adaptive policy remains pending.
5. Topic scope must not leak questions from other topics; subject scope contains only that subject's topics; all-subject scope covers the catalog.
6. An existing session resumes with its original ordered questions, answers and format; no new picker setting changes an in-progress session.
7. Multiple-choice requires exact correct set; single-choice one correct answer; reveal/pair record answers once, including relaunch after answering.
8. A question reused across topics must not be falsely attributed to one topic in aggregate sync.
9. Repeat each essential scenario with airplane-mode/offline storage and after app relaunch.

## Coverage audit (as of start)
- Existing UI: fresh picker, advanced-settings reset, two-question resume, chemistry two-answer persistence, importer.
- Existing unit: card generation, local learning persistence, attribution and sync queue.
- Missing automated matrix: format x strategy x scope with due/no-due, all four answer UIs, disabled empty-state rows, resumed mixed-format session.
- Gate: RC-01/03/04/06 remain PARTIAL/OPEN until missing scenarios are implemented and executed.

## Implementation and regression checkpoint — 2026-10-22

- Shared pure `StudyQuestionSelection.select` now powers both the session launcher and daily planner, with consistent mixed/cards/tests filtering, automatic/all ordering, duplicate-ID elimination, due-weak → new → not-yet-due priorities, and stable ties. The former duplicate filtering paths were consolidated.
- New deterministic Swift Testing cases cover all three formats, empty input, repeated IDs, both strategies, due-weak/new/future priorities, stable ties, and no-due fallback.
- **139/139 unit PASS and 16/16 standard UI PASS**, complete simulator command exit 0 (`/tmp/botai_selection_full_20261022.log`, iPhone 16e simulator `33176212-1247-4722-B8F4-4E53438502E4`). Separately seeded chemistry UI was **not rerun** after this change.
- **Remaining matrix gaps:** explicit subject/topic/all × format × strategy UI scenarios, disabled zero-eligible rows, per-format persisted answers, and account/offline/reconnect coverage. These are not implicitly closed by the green suite.

### Empty-catalog UI checkpoint — 2026-10-22

- Added `LaunchSmokeTests.testEmptyCatalogLaunchCannotCreateSessionAcrossFormats`: an empty library disables the mixed quick-start row before and after opening advanced settings, and closing the picker does not create a resumable session. **Focused UI PASS** (`/tmp/botai_empty_catalog_ui_20261022.log`, exit 0).
- This is **not** exhaustive format-by-format empty-state coverage; it verifies the empty catalog and settings disclosure only. Subject/topic populated UI paths and format-specific disabled rows remain open.
